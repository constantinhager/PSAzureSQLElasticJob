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
            TypeName   = 'PSAzureSQLElasticJob.EnvironmentResult'
            Properties = @{
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
            TypeName   = 'PSAzureSQLElasticJob.EnvironmentStatus'
            Properties = @{
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
            TypeName   = 'PSAzureSQLElasticJob.TargetDatabaseAccessResult'
            Properties = @{
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

        $rendered | Should -Match ([regex]::Escape(($Properties.Keys | Select-Object -First 1)))
        $rendered.TrimEnd() -split "`r?`n" | Select-Object -First 1 | Should -Not -Match ':'
    }
}
