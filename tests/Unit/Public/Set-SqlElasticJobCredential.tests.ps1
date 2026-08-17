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

Describe 'Set-SqlElasticJobCredential' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Set-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ CredentialName = 'jobuser' }
        }

        $script:credential = [System.Management.Automation.PSCredential]::new(
            'jobuser',
            (ConvertTo-SecureString -String 'not-a-real-password' -AsPlainText -Force))

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

        It 'Should rotate the credential' {
            $null = Set-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential

            Should -Invoke -CommandName Set-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should pass the supplied credential through to Azure' {
            $null = Set-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential

            Should -Invoke -CommandName Set-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Credential.UserName -eq 'jobuser'
            }
        }

        It 'Should change nothing when -WhatIf is used' {
            Set-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential -WhatIf

            Should -Invoke -CommandName Set-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the credential does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should throw rather than silently create a credential' {
            { Set-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential } |
                Should -Throw -ExpectedMessage '*was not found*'

            Should -Invoke -CommandName Set-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
