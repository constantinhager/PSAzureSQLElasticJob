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

Describe 'Module configuration' {
    It 'Should register the provisioning service objective with a usable default' {
        Get-PSFConfigValue -FullName 'PSAzureSQLElasticJob.Provisioning.ServiceObjective' | Should -Be 'S1'
    }

    It 'Should register the provisioning server version with a usable default' {
        Get-PSFConfigValue -FullName 'PSAzureSQLElasticJob.Provisioning.ServerVersion' | Should -Be '12.0'
    }

    It 'Should describe every setting it registers' {
        $settings = Get-PSFConfig -Module 'PSAzureSQLElasticJob'

        $settings | Should -Not -BeNullOrEmpty
        $settings.Where({ [System.String]::IsNullOrWhiteSpace($_.Description) }) | Should -BeNullOrEmpty
    }
}
