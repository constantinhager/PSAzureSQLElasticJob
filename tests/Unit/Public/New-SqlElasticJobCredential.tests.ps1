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

Describe 'New-SqlElasticJobCredential' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName New-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ CredentialName = 'jobuser'; Created = $true }
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

    Context 'When the credential already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ CredentialName = 'jobuser'; Created = $false }
            }
        }

        It 'Should return the existing credential without creating one' {
            $result = New-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential

            $result.Created | Should -BeFalse

            Should -Invoke -CommandName New-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should not overwrite the stored password' {
            $otherCredential = [System.Management.Automation.PSCredential]::new(
                'jobuser',
                (ConvertTo-SecureString -String 'a-different-password' -AsPlainText -Force))

            $null = New-SqlElasticJobCredential @script:credentialParameters -Credential $otherCredential

            Should -Invoke -CommandName New-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the credential does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobCredential -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should create the credential' {
            $result = New-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential

            $result.Created | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should create nothing when -WhatIf is used' {
            New-SqlElasticJobCredential @script:credentialParameters -Credential $script:credential -WhatIf

            Should -Invoke -CommandName New-AzSqlElasticJobCredential -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
