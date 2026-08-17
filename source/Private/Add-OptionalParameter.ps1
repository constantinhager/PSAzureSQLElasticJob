<#
    .SYNOPSIS
        Copies explicitly supplied parameters into a splatting hashtable.

    .DESCRIPTION
        Az.Sql distinguishes "not supplied" from "supplied with a falsy value".
        Set-AzSqlElasticJob, for example, only changes a job's enablement when
        the Enable parameter was actually bound, so passing Enable = $false is a
        meaningful instruction while omitting it means "leave it alone".

        This helper forwards only the parameters the caller actually supplied,
        preserving that distinction for switches as well as for values. It exists
        as a separate function because the behaviour cannot be observed through a
        Pester mock - neither ParameterFilter nor MockWith populates
        $PSBoundParameters - so it has to be testable on its own.

    .PARAMETER Parameter
        The splatting hashtable to add to.

    .PARAMETER BoundParameter
        The calling function's $PSBoundParameters.

    .PARAMETER Name
        The parameter names to forward when present.

    .OUTPUTS
        System.Collections.Hashtable

    .EXAMPLE
        $splat = Add-OptionalParameter -Parameter $splat -BoundParameter $PSBoundParameters -Name 'Description', 'Enable'
#>
function Add-OptionalParameter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Collections.Hashtable]
        $Parameter,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]
        $BoundParameter,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name
    )

    foreach ($parameterName in $Name)
    {
        if ($BoundParameter.ContainsKey($parameterName))
        {
            $Parameter[$parameterName] = $BoundParameter[$parameterName]
        }
    }

    return $Parameter
}
