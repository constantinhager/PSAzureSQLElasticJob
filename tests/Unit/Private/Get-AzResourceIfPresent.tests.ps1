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

Describe 'Get-AzResourceIfPresent' {
    It 'Should return the value produced by the lookup' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Get-AzResourceIfPresent -ScriptBlock { 'a-resource' }

            $result | Should -Be 'a-resource'
        }
    }

    It 'Should return null when the lookup reports the resource is missing' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Get-AzResourceIfPresent -ScriptBlock { throw 'Server does not exist.' }

            $result | Should -BeNullOrEmpty
        }
    }

    It 'Should report that provisioning may create a missing resource' {
        $helperPath = Join-Path $PSScriptRoot '..' '..' '..' 'source' 'Private' 'Get-AzResourceIfPresent.ps1'
        $helperContent = Get-Content -LiteralPath $helperPath -Raw
        $message = 'Resource is absent. Provisioning will create it when needed.'

        ([regex]::Matches($helperContent, [regex]::Escape($message))).Count | Should -Be 2
    }

    It 'Should rethrow an authorization failure instead of reporting absence' {
        InModuleScope -ModuleName $script:moduleName {
            {
                Get-AzResourceIfPresent -ScriptBlock {
                    throw 'The client does not have authorization to perform action.'
                }
            } | Should -Throw -ExpectedMessage '*authorization*'
        }
    }

    Context 'When the lookup fails without throwing' {
        # Regression guard: a non-terminating error used to be discarded, so an
        # unreadable resource was reported as absent and the caller would try to
        # create something that already existed.

        It 'Should rethrow a non-terminating authorization failure' {
            InModuleScope -ModuleName $script:moduleName {
                {
                    Get-AzResourceIfPresent -ScriptBlock {
                        Write-Error -Message 'The client does not have authorization to perform action.'
                    }
                } | Should -Throw -ExpectedMessage '*authorization*'
            }
        }

        It 'Should rethrow a non-terminating throttling failure' {
            InModuleScope -ModuleName $script:moduleName {
                {
                    Get-AzResourceIfPresent -ScriptBlock {
                        Write-Error -Message 'Too many requests. Please retry later.'
                    }
                } | Should -Throw -ExpectedMessage '*Too many requests*'
            }
        }

        It 'Should still report a non-terminating not-found error as absent' {
            InModuleScope -ModuleName $script:moduleName {
                $result = Get-AzResourceIfPresent -ScriptBlock {
                    Write-Error -Message 'Server does not exist.'
                }

                $result | Should -BeNullOrEmpty
            }
        }
    }

    It 'Should return every object when the lookup yields a collection' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Get-AzResourceIfPresent -ScriptBlock { 'first'; 'second' }

            $result | Should -HaveCount 2
        }
    }
}
