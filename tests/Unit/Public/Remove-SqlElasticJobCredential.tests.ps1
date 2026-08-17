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

Describe 'Remove-SqlElasticJobCredential' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJobCredential -ModuleName $script:moduleName

        $script:credentialParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'jobuser'
        }
    }

    Context 'When the credential exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ CredentialName = 'jobuser' }
            }
        }

        It 'Should remove the credential' {
            Remove-SqlElasticJobCredential @script:credentialParameters -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should remove nothing when -WhatIf is used' {
            Remove-SqlElasticJobCredential @script:credentialParameters -WhatIf

            Should -Invoke -CommandName Remove-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should return the removed credential with -PassThru' {
            $result = Remove-SqlElasticJobCredential @script:credentialParameters -PassThru -Confirm:$false

            $result.CredentialName | Should -Be 'jobuser'
        }
    }

    Context 'When the credential does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should be a no-op by default' {
            { Remove-SqlElasticJobCredential @script:credentialParameters -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Remove-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should throw when -Strict is used' {
            { Remove-SqlElasticJobCredential @script:credentialParameters -Strict -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }
}
