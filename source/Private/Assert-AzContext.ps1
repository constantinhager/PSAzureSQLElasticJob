<#
    .SYNOPSIS
        Ensures an authenticated Azure context is available.

    .DESCRIPTION
        PSAzureSQLElasticJob never authenticates on its own. It reuses the Azure
        context the caller established with Connect-AzAccount. This helper turns a
        missing or incomplete context into one clear, actionable terminating error
        instead of letting an Az.Sql cmdlet fail later with an obscure message.

        This is internal plumbing and throws rather than calling Stop-PSFFunction.
        The public commands own the -EnableException contract; a precondition
        assert has to interrupt its caller unconditionally to be worth anything.

    .PARAMETER SubscriptionId
        Optional subscription to validate the current context against. When
        supplied and the current context targets a different subscription, a
        terminating error is thrown.

    .OUTPUTS
        Microsoft.Azure.Commands.Profile.Models.Core.PSAzureContext

    .EXAMPLE
        Assert-AzContext

        Throws when the caller is not signed in; otherwise returns the context.
#>
function Assert-AzContext {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SubscriptionId
    )

    $context = Get-AzContext -ErrorAction SilentlyContinue

    if ($null -eq $context -or $null -eq $context.Subscription) {
        throw 'No Azure context found. Run Connect-AzAccount before using PSAzureSQLElasticJob.'
    }

    if ($PSBoundParameters.ContainsKey('SubscriptionId') -and
        $context.Subscription.Id -ne $SubscriptionId) {
        throw ("The current Azure context targets subscription '{0}' but '{1}' was requested. " +
            'Run Set-AzContext -Subscription {1} first.') -f $context.Subscription.Id, $SubscriptionId
    }

    Write-PSFMessage -Level Output -Message ('Using Azure context for subscription ''{0}''.' -f $context.Subscription.Id) -Tag 'context'

    return $context
}
