<#
    .SYNOPSIS
        Determines whether an error record represents a missing Azure resource.

    .DESCRIPTION
        Az.Sql surfaces "does not exist" through several exception types and error
        codes depending on the resource and API version. This helper centralises that
        classification so the distinction between "absent" and "I am not allowed to
        look" is made in exactly one place.

    .PARAMETER ErrorRecord
        The error record to classify.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-AzResourceNotFoundError -ErrorRecord $_
#>
function Test-AzResourceNotFoundError
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    $notFoundIdentifiers = @(
        'ResourceNotFound'
        'ResourceGroupNotFound'
        'NotFound'
    )

    if ($ErrorRecord.FullyQualifiedErrorId -and
        ($notFoundIdentifiers | Where-Object -FilterScript { $ErrorRecord.FullyQualifiedErrorId -match $_ }))
    {
        return $true
    }

    $exception = $ErrorRecord.Exception

    while ($null -ne $exception)
    {
        # Az wraps the REST layer, so the HTTP status is the most reliable signal.
        $statusCode = $exception.PSObject.Properties['Response'].Value.StatusCode

        if ($statusCode -eq 'NotFound' -or $statusCode -eq 404)
        {
            return $true
        }

        if ($exception.Message -match 'ResourceNotFound|does not exist|could not be found|was not found')
        {
            return $true
        }

        $exception = $exception.InnerException
    }

    return $false
}
