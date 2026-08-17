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

Describe 'Get-AzResourceIfPresent' {
    It 'Should return the value produced by the lookup' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Get-AzResourceIfPresent -ScriptBlock { 'a-resource' }

            $result | Should -Be 'a-resource'
        }
    }

    It 'Should return null when the lookup reports the resource is missing' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Get-AzResourceIfPresent -ScriptBlock { throw 'Server does not exist.' }

            $result | Should -BeNullOrEmpty
        }
    }

    It 'Should rethrow an authorization failure instead of reporting absence' {
        InModuleScope -ModuleName $script:moduleName {
            {
                Get-AzResourceIfPresent -ScriptBlock {
                    throw 'The client does not have authorization to perform action.'
                }
            } | Should -Throw -ExpectedMessage '*authorization*'
        }
    }
}
