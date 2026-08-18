BeforeAll {
    $script:moduleName = 'PSAzureSQLElasticJob'

    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue

    Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
    Import-Module -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module -Name $script:moduleName -Force -ErrorAction SilentlyContinue
}

Describe 'Test-AzResourceNotFoundError' {
    It 'Should classify a ResourceNotFound error id as not found' {
        InModuleScope -ModuleName $script:moduleName {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('boom'),
                'ResourceNotFound,Microsoft.Azure.Commands.Sql',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $null)

            Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeTrue
        }
    }

    It 'Should classify a "does not exist" message as not found' {
        InModuleScope -ModuleName $script:moduleName {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Database 'jobdb' does not exist."),
                'SomeOtherId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null)

            Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeTrue
        }
    }

    It 'Should find a not-found signal in an inner exception' {
        InModuleScope -ModuleName $script:moduleName {
            $inner = [System.Exception]::new('The requested resource could not be found.')
            $outer = [System.Exception]::new('Operation failed.', $inner)

            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $outer,
                'SomeOtherId',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null)

            Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeTrue
        }
    }

    It 'Should not classify an authorization failure as not found' {
        InModuleScope -ModuleName $script:moduleName {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('The client does not have authorization to perform action.'),
                'AuthorizationFailed',
                [System.Management.Automation.ErrorCategory]::PermissionDenied,
                $null)

            Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeFalse
        }
    }

    It 'Should not classify a throttling failure as not found' {
        InModuleScope -ModuleName $script:moduleName {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Too many requests. Please retry later.'),
                'TooManyRequests',
                [System.Management.Automation.ErrorCategory]::LimitsExceeded,
                $null)

            Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeFalse
        }
    }

    Context 'When the message mixes absence and permission wording' {
        # ARM reports some permission failures as "not found or no access". Reading
        # those as absence would send provisioning off to create a resource that is
        # already there but invisible to the caller.

        It 'Should not classify "not found or you do not have access" as not found' {
            InModuleScope -ModuleName $script:moduleName {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("The subscription 'x' was not found or you do not have access to it."),
                    'SomeOtherId',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null)

                Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeFalse
            }
        }

        It 'Should let a permission signal in the error id win over not-found wording' {
            InModuleScope -ModuleName $script:moduleName {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('The resource does not exist.'),
                    'AuthorizationFailed,Microsoft.Azure.Commands.Sql',
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null)

                Test-AzResourceNotFoundError -ErrorRecord $errorRecord | Should -BeFalse
            }
        }
    }

    Context 'When the exception exposes an HTTP status' {
        BeforeAll {
            # Built in the test scope and passed in, because a function defined
            # here is not visible inside InModuleScope.
            function New-StatusErrorRecord {
                param
                (
                    [Parameter(Mandatory)]
                    $StatusCode,

                    [Parameter()]
                    [System.String]
                    $Message = 'The operation failed.'
                )

                $exception = [System.Exception]::new($Message)

                $exception | Add-Member -NotePropertyName 'Response' -NotePropertyValue ([PSCustomObject]@{
                        StatusCode = $StatusCode
                    })

                [System.Management.Automation.ErrorRecord]::new(
                    $exception,
                    'SomeOtherId',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null)
            }
        }

        It 'Should classify a 404 as not found' {
            $errorRecord = New-StatusErrorRecord -StatusCode 404

            InModuleScope -ModuleName $script:moduleName -Parameters @{ ErrorRecord = $errorRecord } {
                param ($ErrorRecord)

                Test-AzResourceNotFoundError -ErrorRecord $ErrorRecord | Should -BeTrue
            }
        }

        It 'Should not classify a 403 as not found even when the message says it does not exist' {
            $errorRecord = New-StatusErrorRecord -StatusCode 403 -Message 'The server does not exist.'

            InModuleScope -ModuleName $script:moduleName -Parameters @{ ErrorRecord = $errorRecord } {
                param ($ErrorRecord)

                Test-AzResourceNotFoundError -ErrorRecord $ErrorRecord | Should -BeFalse
            }
        }

        It 'Should not classify a 429 as not found' {
            $errorRecord = New-StatusErrorRecord -StatusCode 429

            InModuleScope -ModuleName $script:moduleName -Parameters @{ ErrorRecord = $errorRecord } {
                param ($ErrorRecord)

                Test-AzResourceNotFoundError -ErrorRecord $ErrorRecord | Should -BeFalse
            }
        }

        It 'Should not classify a 500 as not found' {
            $errorRecord = New-StatusErrorRecord -StatusCode 500

            InModuleScope -ModuleName $script:moduleName -Parameters @{ ErrorRecord = $errorRecord } {
                param ($ErrorRecord)

                Test-AzResourceNotFoundError -ErrorRecord $ErrorRecord | Should -BeFalse
            }
        }
    }
}
