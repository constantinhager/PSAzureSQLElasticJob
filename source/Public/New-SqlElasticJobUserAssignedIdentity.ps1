<#
    .SYNOPSIS
        Creates a user-assigned managed identity, for use with an Elastic Job agent.

    .DESCRIPTION
        Creates a user-assigned managed identity in the given resource group. The
        command is idempotent: when an identity with the same name already exists
        in that resource group it is returned unchanged instead of causing an
        error.

        Use New-SqlElasticJobEnvironment with -UseUserAssignedManagedIdentity and
        -CreateUserAssignedManagedIdentity to create the identity and assign it to
        an Elastic Job agent in one call, or call this command on its own to
        provision the identity ahead of time.

    .PARAMETER ResourceGroupName
        The resource group the identity belongs to.

    .PARAMETER Name
        The name of the user-assigned managed identity to use or create.

    .PARAMETER Location
        The Azure region for a new identity. Required only when the identity does
        not yet exist.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed provisioning run cannot pass unnoticed. Pass $false to get a
        warning and no output instead.

    .OUTPUTS
        Microsoft.Azure.PowerShell.Cmdlets.ManagedServiceIdentity.Models.IIdentity

    .EXAMPLE
        New-SqlElasticJobUserAssignedIdentity -ResourceGroupName 'rg-jobs' -Name 'id-jobs' -Location 'westeurope'
#>
function New-SqlElasticJobUserAssignedIdentity
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('IdentityName')]
        [System.String]
        $Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Location,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process
    {
        $null = Assert-AzContext

        $identity = Get-AzResourceIfPresent -ScriptBlock {
            Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $Name
        }

        if ($null -ne $identity)
        {
            Write-PSFMessage -Level Output -Message ('User-assigned managed identity ''{0}'' already exists in resource group ''{1}''.' -f $Name, $ResourceGroupName) -Tag 'idempotent'

            return $identity
        }

        if (-not $PSBoundParameters.ContainsKey('Location'))
        {
            Stop-PSFFunction -Message ('User-assigned managed identity ''{0}'' does not exist and no -Location was supplied.' -f $Name) -EnableException $EnableException -Category InvalidArgument

            return
        }

        if (-not $PSCmdlet.ShouldProcess($Name, ("Create user-assigned managed identity in '{0}'" -f $Location)))
        {
            return
        }

        Write-PSFMessage -Level Output -Message ('Creating user-assigned managed identity ''{0}'' in ''{1}''.' -f $Name, $Location) -Tag 'identity', 'create'

        try
        {
            $identity = New-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName -Name $Name -Location $Location -ErrorAction Stop
        }
        catch
        {
            $message = ('Failed to create user-assigned managed identity ''{0}'': {1}' -f $Name, $_.Exception.Message)
            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'identity', 'create'
            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

            return
        }

        if ([System.String]::IsNullOrEmpty($identity.Id))
        {
            $message = ('User-assigned managed identity ''{0}'' was not created; Azure returned no resource ID. Check that the ''Microsoft.ManagedIdentity'' resource provider is registered on the subscription.' -f $Name)
            Write-PSFMessage -Level Error -Message $message -Tag 'identity', 'create'
            Stop-PSFFunction -Message $message -EnableException $EnableException

            return
        }

        Write-PSFMessage -Level Output -Message ('Created user-assigned managed identity ''{0}''.' -f $Name) -Tag 'identity', 'create'

        return $identity
    }
}
