<#
    .SYNOPSIS
        Ensures an Azure resource provider is registered on the current subscription.

    .DESCRIPTION
        A resource type cannot be used until its resource provider namespace is
        registered on the subscription, a one-time subscription-level setup step
        that is easy to forget. This helper registers the given namespace when it
        is not already registered and waits for registration to complete.

        This is internal plumbing and throws rather than calling Stop-PSFFunction.
        Its callers are public commands that own the -EnableException decision.

    .PARAMETER ProviderNamespace
        The resource provider namespace to ensure is registered, for example
        'Microsoft.ManagedIdentity'.

    .PARAMETER TimeoutSeconds
        How long to wait for registration to finish after requesting it. Defaults
        to 300 seconds.

    .PARAMETER PollIntervalSeconds
        How long to wait between registration state checks. Defaults to 10 seconds.

    .EXAMPLE
        Assert-AzResourceProviderRegistered -ProviderNamespace 'Microsoft.ManagedIdentity'
#>
function Assert-AzResourceProviderRegistered {
    [CmdletBinding()]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ProviderNamespace,

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $TimeoutSeconds = 300,

        [Parameter()]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $PollIntervalSeconds = 10
    )

    $provider = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop | Select-Object -First 1

    if ($provider.RegistrationState -eq 'Registered') {
        return
    }

    Write-PSFMessage -Level Output -Message ('Registering Azure resource provider ''{0}''.' -f $ProviderNamespace) -Tag 'provider', 'register'

    $null = Register-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop

    $waited = 0

    while ($waited -lt $TimeoutSeconds) {
        Start-Sleep -Seconds $PollIntervalSeconds
        $waited += $PollIntervalSeconds

        $provider = Get-AzResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop | Select-Object -First 1

        if ($provider.RegistrationState -eq 'Registered') {
            Write-PSFMessage -Level Output -Message ('Azure resource provider ''{0}'' is registered.' -f $ProviderNamespace) -Tag 'provider', 'register'

            return
        }
    }

    throw ('Azure resource provider ''{0}'' did not finish registering within {1} seconds.' -f $ProviderNamespace, $TimeoutSeconds)
}
