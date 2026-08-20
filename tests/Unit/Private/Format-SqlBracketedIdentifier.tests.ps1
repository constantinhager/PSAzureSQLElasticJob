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

Describe 'Format-SqlBracketedIdentifier' {
    It 'Should bracket a plain identifier' {
        InModuleScope -ModuleName $script:moduleName {
            Format-SqlBracketedIdentifier -Name 'id-jobs' | Should -Be '[id-jobs]'
        }
    }

    It 'Should double an embedded closing bracket to prevent breaking out of the identifier' {
        InModuleScope -ModuleName $script:moduleName {
            Format-SqlBracketedIdentifier -Name 'id]; DROP TABLE Users; --' | Should -Be '[id]]; DROP TABLE Users; --]'
        }
    }
}
