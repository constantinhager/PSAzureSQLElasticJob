<#
    .SYNOPSIS
        Bracket-escapes a SQL identifier for safe interpolation into T-SQL.

    .DESCRIPTION
        Statements such as CREATE USER and ALTER ROLE cannot parameterize the
        principal or role name, so callers that build T-SQL through string
        interpolation have to escape it themselves. This doubles any ']' in the
        identifier and wraps it in brackets, the standard T-SQL quoted-identifier
        escaping rule, so a crafted name cannot break out of the brackets.

        This does not replace validating the identifier against an allow-list
        pattern first; it is a second, independent layer of defense.

    .PARAMETER Name
        The identifier to escape.

    .OUTPUTS
        System.String

    .EXAMPLE
        Format-SqlBracketedIdentifier -Name 'id-jobs'

        Returns '[id-jobs]'.
#>
function Format-SqlBracketedIdentifier {
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    return '[{0}]' -f ($Name -replace '\]', ']]')
}
