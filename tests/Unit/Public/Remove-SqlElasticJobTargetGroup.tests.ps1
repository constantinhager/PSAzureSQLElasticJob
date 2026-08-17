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

Describe 'Remove-SqlElasticJobTargetGroup' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        Mock -CommandName Remove-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName

        $script:targetGroupParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
            Name              = 'all-databases'
        }
    }

    Context 'When the target group exists' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ TargetGroupName = 'all-databases' }
            }
        }

        It 'Should remove the target group' {
            Remove-SqlElasticJobTargetGroup @script:targetGroupParameters -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 1 -Exactly
        }

        It 'Should pass -Force through to Azure when supplied' {
            Remove-SqlElasticJobTargetGroup @script:targetGroupParameters -Force -Confirm:$false

            Should -Invoke -CommandName Remove-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
                $Force -eq $true
            }
        }

        It 'Should remove nothing when -WhatIf is used' {
            Remove-SqlElasticJobTargetGroup @script:targetGroupParameters -WhatIf

            Should -Invoke -CommandName Remove-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }

    Context 'When the target group does not exist' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }
        }

        It 'Should be a no-op by default' {
            { Remove-SqlElasticJobTargetGroup @script:targetGroupParameters -Confirm:$false } | Should -Not -Throw

            Should -Invoke -CommandName Remove-AzSqlElasticJobTargetGroup -ModuleName $script:moduleName -Times 0 -Exactly
        }

        It 'Should throw when -Strict is used' {
            { Remove-SqlElasticJobTargetGroup @script:targetGroupParameters -Strict -Confirm:$false } |
                Should -Throw -ExpectedMessage '*was not found*'
        }
    }
}
