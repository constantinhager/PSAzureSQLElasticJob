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

Describe 'New-SqlElasticJobTargetGroup' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName New-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ TargetGroupName = 'all-databases'; Created = $true }
        }

        $script:targetGroupParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'all-databases'
        }
    }

    Context 'When the target group already exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ TargetGroupName = 'all-databases'; Created = $false }
            }
        }

        It 'Should return the existing target group without creating one' {
            $result = New-SqlElasticJobTargetGroup @script:targetGroupParameters

            $result.Created | Should -BeFalse

            Should -Invoke -CommandName New-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the target group does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should create the target group' {
            $result = New-SqlElasticJobTargetGroup @script:targetGroupParameters

            $result.Created | Should -BeTrue

            Should -Invoke -CommandName New-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should create nothing when -WhatIf is used' {
            New-SqlElasticJobTargetGroup @script:targetGroupParameters -WhatIf

            Should -Invoke -CommandName New-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
