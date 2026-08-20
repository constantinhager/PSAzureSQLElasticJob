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

Describe 'PSAzureSQLElasticJob.Format.ps1xml' {
    It 'Should register a table view for <TypeName>' -ForEach @(
        @{ TypeName = 'PSAzureSQLElasticJob.EnvironmentResult' }
        @{ TypeName = 'PSAzureSQLElasticJob.EnvironmentStatus' }
        @{ TypeName = 'PSAzureSQLElasticJob.TargetDatabaseAccessResult' }
    ) {
        Get-FormatData -TypeName $TypeName | Should -Not -BeNullOrEmpty
    }

    It 'Should render <TypeName> as a table instead of the default list view' -ForEach @(
        @{
            TypeName      = 'PSAzureSQLElasticJob.EnvironmentResult'
            ExpectedValue = 'sql-jobs'
            Properties    = @{
                ResourceGroupName = 'rg-jobs'
                ServerName        = 'sql-jobs'
                DatabaseName      = 'jobdb'
                AgentName         = 'agent01'
                CreatedServer     = $false
                CreatedDatabase   = $false
                CreatedAgent      = $false
                AssignedIdentity  = $false
            }
        }
        @{
            TypeName      = 'PSAzureSQLElasticJob.EnvironmentStatus'
            ExpectedValue = 'sql-jobs'
            Properties    = @{
                ResourceGroupName = 'rg-jobs'
                ServerName        = 'sql-jobs'
                DatabaseName      = 'jobdb'
                AgentName         = 'agent01'
                ServerExists      = $true
                DatabaseExists    = $true
                AgentExists       = $false
                IsComplete        = $false
            }
        }
        @{
            TypeName      = 'PSAzureSQLElasticJob.TargetDatabaseAccessResult'
            ExpectedValue = 'sql-app'
            Properties    = @{
                TargetServerName      = 'sql-app'
                TargetDatabaseName    = 'AppDb'
                IdentityName          = 'id-jobs'
                RoleName              = 'db_owner'
                UserCreated           = $true
                RoleMembershipGranted = $true
            }
        }
    ) {
        $object = [PSCustomObject]($Properties + @{ PSTypeName = $TypeName })

        $rendered = $object | Out-String

        $rendered | Should -Match ([regex]::Escape($ExpectedValue))
        $rendered.TrimEnd() -split "`r?`n" | Select-Object -First 1 | Should -Not -Match ':'
    }
}

Describe 'PSAzureSQLElasticJob.ElasticJobStep format view' {
    BeforeAll {
        $script:step = [PSCustomObject]@{
            PSTypeName      = 'Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel'
            JobName         = 'nightly-report'
            StepName        = 'collect-counts-with-output'
            StepId          = 1
            TargetGroupName = 'all-databases'
            CredentialName  = $null
            Output          = [PSCustomObject]@{
                ServerName   = 'sql-reporting'
                DatabaseName = 'reporting'
                SchemaName   = 'dbo'
                TableName    = 'OrderCounts'
            }
            CommandText     = 'SELECT $(job_execution_id) AS JobExecutionId, COUNT(*) AS RowCount FROM dbo.Orders WHERE Status = ''Open'''
        }
    }

    It 'Should register a table view for the step model' {
        Get-FormatData -TypeName 'Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel' | Should -Not -BeNullOrEmpty
    }

    It 'Should render as a single line, truncating a long CommandText instead of wrapping it' {
        $rendered = $script:step | Out-String -Width 200
        $dataLine = ($rendered.TrimEnd() -split "`r?`n") | Select-Object -Last 1

        $dataLine | Should -Match ([regex]::Escape('collect-counts-with-output'))
        $dataLine | Should -Match ([regex]::Escape('...'))
        $dataLine | Should -Not -Match ([regex]::Escape('RowCount FROM dbo.Orders'))
    }

    It 'Should render the output table as schema.table instead of the raw type name' {
        $rendered = $script:step | Out-String -Width 200

        $rendered | Should -Match ([regex]::Escape('dbo.OrderCounts'))
        $rendered | Should -Not -Match 'AzureSqlElasticJobStepOutputModel'
    }
}
