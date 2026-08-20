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

Describe 'Grant-SqlElasticJobTargetDatabaseAccess' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Get-AzAccessToken -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Token = 'fake-token' }
        }

        Mock -CommandName Connect-DbaInstance -ModuleName $script:moduleName -MockWith {
            $SqlInstance
        }

        Mock -CommandName Disconnect-DbaInstance -ModuleName $script:moduleName -MockWith { }

        $script:baseParameters = @{
            TargetServerName   = 'sql-prod'
            TargetDatabaseName = 'AppDb'
            IdentityName       = 'id-jobs'
        }
    }

    Context 'When the user and role membership do not exist yet' {
        BeforeAll {
            Mock -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should create the database user and add it to db_owner by default' {
            $result = Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false

            $result.UserCreated | Should -BeTrue
            $result.RoleMembershipGranted | Should -BeTrue
            $result.RoleName | Should -Be 'db_owner'

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Query -like 'CREATE USER *FROM EXTERNAL PROVIDER*'
            }

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Query -like 'ALTER ROLE *ADD MEMBER*'
            }
        }

        It 'Should append the Azure SQL FQDN to a short server name' {
            $null = Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false

            Should -Invoke -CommandName Connect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                "$SqlInstance" -eq 'sql-prod.database.windows.net'
            }
        }

        It 'Should honour a custom role name' {
            $result = Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -RoleName 'db_datareader' -Confirm:$false

            $result.RoleName | Should -Be 'db_datareader'

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Query -like '*ALTER ROLE [[]db_datareader[]] ADD MEMBER*'
            }
        }

        It 'Should reject an identity name that is not a safe SQL identifier' {
            { Grant-SqlElasticJobTargetDatabaseAccess -TargetServerName 'sql-prod' -TargetDatabaseName 'AppDb' -IdentityName "id]; DROP TABLE Users; --" -Confirm:$false } |
            Should -Throw

            Should -Invoke -CommandName Connect-DbaInstance -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should disconnect the SQL connection even on success' {
            $null = Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false

            Should -Invoke -CommandName Disconnect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should create nothing when -WhatIf is used' {
            Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -WhatIf

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 0 -Exactly -ParameterFilter {
                $Query -like 'CREATE USER*' -or $Query -like 'ALTER ROLE*'
            }
        }
    }

    Context 'When the user and role membership already exist' {
        BeforeAll {
            Mock -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ name = 'id-jobs' }
            }
        }

        It 'Should report nothing created' {
            $result = Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false

            $result.UserCreated | Should -BeFalse
            $result.RoleMembershipGranted | Should -BeFalse

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 0 -Exactly -ParameterFilter {
                $Query -like 'CREATE USER*' -or $Query -like 'ALTER ROLE*'
            }
        }
    }

    Context 'When creating the database user fails' {
        BeforeAll {
            Mock -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -MockWith {
                if ($Query -like 'CREATE USER*') {
                    throw 'Login failed.'
                }

                $null
            }
        }

        It 'Should stop without granting role membership' {
            { Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Login failed*'

            Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 0 -Exactly -ParameterFilter {
                $Query -like 'ALTER ROLE*'
            }
        }

        It 'Should still disconnect the SQL connection' {
            { Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false } | Should -Throw

            Should -Invoke -CommandName Disconnect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly
        }
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before contacting Azure SQL' {
            { Grant-SqlElasticJobTargetDatabaseAccess @script:baseParameters -Confirm:$false } |
            Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Connect-DbaInstance -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
