@{
    <#
        This is only required if you need to use the method PowerShellGet & PSDepend
        It is not required for PSResourceGet or ModuleFast (and will be ignored).
        See Resolve-Dependency.psd1 on how to enable methods.
    #>
    #PSDependOptions             = @{
    #    AddToPath  = $true
    #    Target     = 'output\RequiredModules'
    #    Parameters = @{
    #        Repository = 'PSGallery'
    #    }
    #}

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    # Pinned to 5.x: Sampler's QA template and build tasks are not Pester 6 compatible.
    Pester                      = '[5.7.1, 6.0.0)'
    ModuleBuilder               = 'latest'
    ChangelogManagement         = 'latest'
    Sampler                     = 'latest'
    'Sampler.GitHubTasks'       = 'latest'
    'Az.Accounts'               = 'latest'
    'Az.Sql'                    = 'latest'
    'Az.ManagedServiceIdentity' = 'latest'
    'Az.Resources'              = 'latest'
    dbatools                    = 'latest'
    dbatools.library            = 'latest'
    PSFramework                 = 'latest'


}
