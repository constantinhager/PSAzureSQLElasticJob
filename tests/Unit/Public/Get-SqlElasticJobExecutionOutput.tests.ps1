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

Describe 'Get-SqlElasticJobExecutionOutput' {
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

        Mock -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -MockWith {
            [PSCustomObject]@{ RowCount = 42 }
        }

        $script:jobExecutionId = [System.Guid]::NewGuid()

        $script:baseParameters = @{
            OutputServerName   = 'sql-reporting'
            OutputDatabaseName = 'reporting'
            OutputTableName    = 'OrderCounts'
            JobExecutionId     = $script:jobExecutionId
        }
    }

    It 'Should append the Azure SQL FQDN to a short server name' {
        $null = Get-SqlElasticJobExecutionOutput @script:baseParameters

        Should -Invoke -CommandName Connect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            "$SqlInstance" -eq 'sql-reporting.database.windows.net'
        }
    }

    It 'Should query the default dbo schema and filter by the execution ID' {
        $null = Get-SqlElasticJobExecutionOutput @script:baseParameters

        Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $Query -like '*[[]dbo[]].[[]OrderCounts[]]*internal_execution_id*' -and $SqlParameter[0]['ExecutionId'] -eq $script:jobExecutionId
        }
    }

    It 'Should honour a custom schema and execution ID column name' {
        $null = Get-SqlElasticJobExecutionOutput @script:baseParameters -OutputSchemaName 'custom' -ExecutionIdColumnName 'run_id'

        Should -Invoke -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -Times 1 -Exactly -ParameterFilter {
            $Query -like '*[[]custom[]].[[]OrderCounts[]]*run_id*'
        }
    }

    It 'Should return the rows Invoke-DbaQuery produces' {
        $result = Get-SqlElasticJobExecutionOutput @script:baseParameters

        $result.RowCount | Should -Be 42
    }

    It 'Should disconnect the SQL connection even on success' {
        $null = Get-SqlElasticJobExecutionOutput @script:baseParameters

        Should -Invoke -CommandName Disconnect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly
    }

    Context 'When the query fails' {
        BeforeAll {
            Mock -CommandName Invoke-DbaQuery -ModuleName $script:moduleName -MockWith {
                throw 'Invalid object name.'
            }
        }

        It 'Should throw' {
            { Get-SqlElasticJobExecutionOutput @script:baseParameters } | Should -Throw -ExpectedMessage '*Invalid object name*'
        }

        It 'Should still disconnect the SQL connection' {
            { Get-SqlElasticJobExecutionOutput @script:baseParameters } | Should -Throw

            Should -Invoke -CommandName Disconnect-DbaInstance -ModuleName $script:moduleName -Times 1 -Exactly
        }
    }

    Context 'When the caller is not signed in' {
        BeforeAll {
            Mock -CommandName Get-AzContext -ModuleName $script:moduleName -MockWith { $null }
        }

        It 'Should throw before contacting Azure SQL' {
            { Get-SqlElasticJobExecutionOutput @script:baseParameters } |
            Should -Throw -ExpectedMessage '*Connect-AzAccount*'

            Should -Invoke -CommandName Connect-DbaInstance -ModuleName $script:moduleName -Times 0 -Exactly
        }
    }
}
