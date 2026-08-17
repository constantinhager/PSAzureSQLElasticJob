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

Describe 'Add-OptionalParameter' {
    It 'Should forward a supplied value' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Add-OptionalParameter -Parameter @{} -BoundParameter @{ Description = 'hello' } -Name 'Description'

            $result['Description'] | Should -Be 'hello'
        }
    }

    It 'Should not add a parameter that was not supplied' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Add-OptionalParameter -Parameter @{} -BoundParameter @{} -Name 'Description'

            $result.ContainsKey('Description') | Should -BeFalse
        }
    }

    It 'Should forward a switch that was explicitly set to false' {
        InModuleScope -ModuleName $script:moduleName {
            $bound = @{ Enable = [System.Management.Automation.SwitchParameter]$false }

            $result = Add-OptionalParameter -Parameter @{} -BoundParameter $bound -Name 'Enable'

            $result.ContainsKey('Enable') | Should -BeTrue
            [System.Boolean]$result['Enable'] | Should -BeFalse
        }
    }

    It 'Should distinguish a false switch from an omitted switch' {
        InModuleScope -ModuleName $script:moduleName {
            $withFalse = Add-OptionalParameter -Parameter @{} -BoundParameter @{ Enable = [System.Management.Automation.SwitchParameter]$false } -Name 'Enable'
            $withNone = Add-OptionalParameter -Parameter @{} -BoundParameter @{} -Name 'Enable'

            $withFalse.ContainsKey('Enable') | Should -BeTrue
            $withNone.ContainsKey('Enable') | Should -BeFalse
        }
    }

    It 'Should forward a value that is legitimately zero' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Add-OptionalParameter -Parameter @{} -BoundParameter @{ RetryAttempts = 0 } -Name 'RetryAttempts'

            $result.ContainsKey('RetryAttempts') | Should -BeTrue
            $result['RetryAttempts'] | Should -Be 0
        }
    }

    It 'Should forward several parameters and ignore the absent ones' {
        InModuleScope -ModuleName $script:moduleName {
            $bound = @{ Description = 'hello'; IntervalCount = 3 }

            $result = Add-OptionalParameter -Parameter @{} -BoundParameter $bound -Name 'Description', 'IntervalType', 'IntervalCount'

            $result.Keys | Should -HaveCount 2
            $result['Description'] | Should -Be 'hello'
            $result['IntervalCount'] | Should -Be 3
            $result.ContainsKey('IntervalType') | Should -BeFalse
        }
    }

    It 'Should preserve entries that are already in the target hashtable' {
        InModuleScope -ModuleName $script:moduleName {
            $result = Add-OptionalParameter -Parameter @{ Name = 'existing' } -BoundParameter @{ Description = 'hello' } -Name 'Description'

            $result['Name'] | Should -Be 'existing'
            $result['Description'] | Should -Be 'hello'
        }
    }
}
