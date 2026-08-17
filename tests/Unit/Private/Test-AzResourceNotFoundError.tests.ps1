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
}
