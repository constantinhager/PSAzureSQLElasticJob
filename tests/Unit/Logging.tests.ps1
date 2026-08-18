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

Describe 'Module logging' {
    BeforeAll {
        Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ Subscription = [PSCustomObject]@{ Id = 'sub-1' } }
        }

        $script:agentParameters = @{
            ResourceGroupName = 'rg'
            ServerName        = 'srv'
            AgentName         = 'agent01'
        }
    }

    Context 'When a create operation runs' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                throw 'The requested resource could not be found.'
            }

            Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should log the intent and the completion under the create tag' {
            $null = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'log-probe-agent'

            $logged = Get-PSFMessage -Tag 'create' |
            Where-Object -FilterScript { $_.Message -like '*log-probe-agent*' }

            $logged | Should -Not -BeNullOrEmpty
            ($logged.Message -join ' ') | Should -BeLike '*Creating Elastic Job agent*'
            ($logged.Message -join ' ') | Should -BeLike '*Created Elastic Job agent*'
        }

        It 'Should attribute the message to the calling command' {
            $null = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'log-attribution-agent'

            $logged = Get-PSFMessage -Tag 'create' |
            Where-Object -FilterScript { $_.Message -like '*log-attribution-agent*' } |
            Select-Object -First 1

            $logged.FunctionName | Should -Be 'New-SqlElasticJobAgent'
        }
    }

    Context 'When an idempotent call makes no change' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'existing-probe-agent' }
            }

            Mock -CommandName New-AzSqlElasticJobAgent -ModuleName $script:moduleName
        }

        It 'Should log that the resource already exists rather than a creation' {
            $null = New-SqlElasticJobAgent -ResourceGroupName 'rg' -ServerName 'srv' -DatabaseName 'jobdb' -Name 'existing-probe-agent'

            $idempotent = Get-PSFMessage -Tag 'idempotent' |
            Where-Object -FilterScript { $_.Message -like '*existing-probe-agent*' }

            $idempotent | Should -Not -BeNullOrEmpty

            $created = Get-PSFMessage -Tag 'create' |
            Where-Object -FilterScript { $_.Message -like '*existing-probe-agent*' }

            $created | Should -BeNullOrEmpty
        }
    }

    Context 'When a lookup runs' {
        BeforeAll {
            Mock -CommandName Get-AzSqlElasticJobAgent -ModuleName $script:moduleName -MockWith {
                [PSCustomObject]@{ AgentName = 'agent01' }
            }
        }

        It 'Should trace the lookup at a deeper level than ordinary operations' {
            $null = Get-SqlElasticJobAgent @script:agentParameters -Name 'agent01'

            $logged = Get-PSFMessage -Tag 'lookup' |
            Where-Object -FilterScript { $_.Message -like '*Looking up Elastic Job agent*' } |
            Select-Object -Last 1

            $logged | Should -Not -BeNullOrEmpty
            $logged.Level | Should -Be 'VeryVerbose'
        }
    }

    It 'Should use Output for ordinary module messages' {
        $sourcePath = Join-Path $PSScriptRoot '..' '..' 'source'
        $verboseMessages = Get-ChildItem -Path $sourcePath -Filter '*.ps1' -Recurse |
        Select-String -Pattern 'Write-PSFMessage\s+-Level\s+Verbose'

        $verboseMessages | Should -BeNullOrEmpty
    }
}
