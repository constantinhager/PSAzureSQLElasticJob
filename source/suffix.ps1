<#
    Runs on module import. ModuleBuilder appends this file to the built .psm1,
    so it is the only place in the module where code executes at load time.

    -Initialize registers each setting once per session and deliberately does not
    overwrite a value the user has already changed.
#>

Set-PSFConfig -Module 'PSAzureSQLElasticJob' -Name 'Provisioning.ServiceObjective' -Value 'S1' -Initialize -Validation 'string' -Description 'Service objective used for a job database this module creates. Elastic Jobs requires S0 or higher; S1 is the tier Microsoft recommends.'

Set-PSFConfig -Module 'PSAzureSQLElasticJob' -Name 'Provisioning.ServerVersion' -Value '12.0' -Initialize -Validation 'string' -Description 'Version used for a logical SQL server this module creates.'
