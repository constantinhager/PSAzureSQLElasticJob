<#
    .SYNOPSIS
        Determines whether an error record represents a missing Azure resource.

    .DESCRIPTION
        Az.Sql surfaces "does not exist" through several exception types and error
        codes depending on the resource and API version. This helper centralises that
        classification so the distinction between "absent" and "I am not allowed to
        look" is made in exactly one place.

        The checks run strongest first. A permission, authentication, quota or
        throttling signal wins outright, because ARM sometimes reports those with
        not-found wording. An HTTP status settles the question when one is exposed.
        Only when neither is available does the free-text message matter.

    .PARAMETER ErrorRecord
        The error record to classify.

    .OUTPUTS
        System.Boolean

    .EXAMPLE
        Test-AzResourceNotFoundError -ErrorRecord $_
#>
function Test-AzResourceNotFoundError {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    <#
        Anything that positively identifies a permission, authentication, quota or
        throttling failure is never "absent", whatever else the message says. ARM
        phrases some of those as "... was not found or you do not have access",
        which would otherwise match the not-found wording below.
    #>
    $deniedPattern = 'AuthorizationFailed|AuthenticationFailed|Forbidden|Unauthorized|' +
    'TooManyRequests|too many requests|RequestThrottled|QuotaExceeded|' +
    'do(es)? not have (access|authorization)|is not authorized|insufficient privileges'

    $notFoundMessagePattern = 'ResourceNotFound|ResourceGroupNotFound|' +
    'does not exist|could not be found|was not found|cannot be found'

    if ($ErrorRecord.FullyQualifiedErrorId -match $deniedPattern) {
        return $false
    }

    $statusCode = $null
    $exception = $ErrorRecord.Exception

    while ($null -ne $exception) {
        if ($exception.Message -match $deniedPattern) {
            return $false
        }

        if ($null -eq $statusCode) {
            $statusCode = $exception.PSObject.Properties['Response'].Value.StatusCode
        }

        $exception = $exception.InnerException
    }

    # Az wraps the REST layer, so when a status is exposed it settles the question
    # on its own and the free-text fallbacks below are not consulted.
    if ($null -ne $statusCode) {
        return ($statusCode -eq 'NotFound' -or $statusCode -eq 404)
    }

    if ($ErrorRecord.FullyQualifiedErrorId -match 'NotFound') {
        return $true
    }

    $exception = $ErrorRecord.Exception

    while ($null -ne $exception) {
        if ($exception.Message -match $notFoundMessagePattern) {
            return $true
        }

        $exception = $exception.InnerException
    }

    return $false
}
