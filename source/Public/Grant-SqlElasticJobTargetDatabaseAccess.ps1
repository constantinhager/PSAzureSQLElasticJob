<#
    .SYNOPSIS
        Grants a user-assigned managed identity access to an Azure SQL Database target.

    .DESCRIPTION
        Creates a contained database user for the managed identity in the target
        database (CREATE USER ... FROM EXTERNAL PROVIDER) and adds it to a
        database role, by default db_owner. This is the access an Elastic Job
        agent's managed identity needs to run job steps against a target
        database.

        Only a contained database user is created; no server-level login is
        required for a single Azure SQL Database (unlike SQL Managed Instance or
        classic SQL authentication).

        The command is idempotent: an existing user or existing role membership
        is left as it is and reported as already present. Both steps are
        confirmed once as a single grant operation, and one summary object is
        returned describing what was created.

        Connects using an Azure AD access token obtained from the caller's
        signed-in Az context, so no separate SQL credential is needed.

    .PARAMETER TargetServerName
        The target Azure SQL server. A short name has '.database.windows.net'
        appended automatically; a fully qualified name is used as supplied.

    .PARAMETER TargetDatabaseName
        The target database to grant access in.

    .PARAMETER IdentityName
        The name of the user-assigned managed identity, used as the database
        principal name.

    .PARAMETER RoleName
        The database role to add the identity to. Defaults to 'db_owner'.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed grant cannot pass unnoticed. Pass $false to get a warning and no
        output instead.

    .OUTPUTS
        PSCustomObject describing the target and what was granted. Typed as
        PSAzureSQLElasticJob.TargetDatabaseAccessResult, which has a custom
        table format view showing a compact summary.

    .EXAMPLE
        Grant-SqlElasticJobTargetDatabaseAccess -TargetServerName 'sql-prod' -TargetDatabaseName 'AppDb' -IdentityName 'id-jobs'

        Creates the contained user for 'id-jobs' in 'AppDb' and adds it to db_owner.

    .EXAMPLE
        Grant-SqlElasticJobTargetDatabaseAccess -TargetServerName 'sql-prod' -TargetDatabaseName 'AppDb' -IdentityName 'id-jobs' -RoleName 'db_datareader'

        Grants read-only access instead of db_owner.
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/Grant-SqlElasticJobTargetDatabaseAccess.ps1
#>
function Grant-SqlElasticJobTargetDatabaseAccess {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetServerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetDatabaseName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_\-]{0,127}$')]
        [System.String]
        $IdentityName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_\-]{0,127}$')]
        [System.String]
        $RoleName = 'db_owner',

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process {
        $null = Assert-AzContext

        $serverFqdn = if ($TargetServerName -like '*.*') { $TargetServerName } else { '{0}.database.windows.net' -f $TargetServerName }

        try {
            $accessToken = Get-AzAccessToken -ResourceUrl 'https://database.windows.net/' -ErrorAction Stop
        } catch {
            $message = ('Failed to acquire an Azure AD access token for Azure SQL: {0}' -f $_.Exception.Message)
            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

            return
        }

        try {
            $sqlConnection = Connect-DbaInstance -SqlInstance $serverFqdn -AccessToken $accessToken -Database $TargetDatabaseName -ErrorAction Stop
        } catch {
            $message = ('Failed to connect to ''{0}''/''{1}'': {2}' -f $serverFqdn, $TargetDatabaseName, $_.Exception.Message)
            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

            return
        }

        try {
            $userCreated = $false
            $roleMembershipGranted = $false

            $escapedIdentityName = $IdentityName -replace "'", "''"
            $escapedRoleName = $RoleName -replace "'", "''"
            $bracketedIdentityName = Format-SqlBracketedIdentifier -Name $IdentityName
            $bracketedRoleName = Format-SqlBracketedIdentifier -Name $RoleName

            try {
                $existingUser = Invoke-DbaQuery -SqlInstance $sqlConnection -Database $TargetDatabaseName -Query ("SELECT name FROM sys.database_principals WHERE name = N'{0}';" -f $escapedIdentityName) -EnableException
            } catch {
                $message = ('Failed to look up database user ''{0}'' in ''{1}''/''{2}'': {3}' -f $IdentityName, $TargetServerName, $TargetDatabaseName, $_.Exception.Message)
                Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
                Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                return
            }

            $userExists = $null -ne $existingUser

            $membershipQuery = 'SELECT 1 FROM sys.database_role_members drm ' +
            'JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id ' +
            'JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id ' +
            ("WHERE r.name = N'{0}' AND m.name = N'{1}';" -f $escapedRoleName, $escapedIdentityName)

            try {
                $existingMembership = Invoke-DbaQuery -SqlInstance $sqlConnection -Database $TargetDatabaseName -Query $membershipQuery -EnableException
            } catch {
                $message = ('Failed to look up role membership for ''{0}'' in ''{1}''/''{2}'': {3}' -f $IdentityName, $TargetServerName, $TargetDatabaseName, $_.Exception.Message)
                Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
                Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                return
            }

            $roleMembershipExists = $null -ne $existingMembership

            if ($userExists -and $roleMembershipExists) {
                Write-PSFMessage -Level Output -Message ('Database user ''{0}'' already has access to ''{1}''/''{2}'' as a member of ''{3}''. No changes were made.' -f $IdentityName, $TargetServerName, $TargetDatabaseName, $RoleName) -Tag 'idempotent'
            } else {
                $actions = @()

                if (-not $userExists) {
                    $actions += ('create database user ''{0}''' -f $IdentityName)
                }

                if (-not $roleMembershipExists) {
                    $actions += ('add it to role ''{0}''' -f $RoleName)
                }

                if ($PSCmdlet.ShouldProcess(('{0}/{1}' -f $TargetDatabaseName, $IdentityName), ('Grant database access: {0}' -f ($actions -join ' and ')))) {
                    if ($userExists) {
                        Write-PSFMessage -Level Output -Message ('Database user ''{0}'' already exists in ''{1}''/''{2}''.' -f $IdentityName, $TargetServerName, $TargetDatabaseName) -Tag 'idempotent'
                    } else {
                        Write-PSFMessage -Level Output -Message ('Creating database user ''{0}'' in ''{1}''/''{2}''.' -f $IdentityName, $TargetServerName, $TargetDatabaseName) -Tag 'target', 'identity', 'create'

                        try {
                            $null = Invoke-DbaQuery -SqlInstance $sqlConnection -Database $TargetDatabaseName -Query ('CREATE USER {0} FROM EXTERNAL PROVIDER;' -f $bracketedIdentityName) -EnableException
                        } catch {
                            $message = ('Failed to create database user ''{0}'' in ''{1}''/''{2}'': {3}' -f $IdentityName, $TargetServerName, $TargetDatabaseName, $_.Exception.Message)
                            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
                            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                            return
                        }

                        Write-PSFMessage -Level Output -Message ('Created database user ''{0}'' in ''{1}''/''{2}''.' -f $IdentityName, $TargetServerName, $TargetDatabaseName) -Tag 'target', 'identity', 'create'

                        $userCreated = $true
                    }

                    if ($roleMembershipExists) {
                        Write-PSFMessage -Level Output -Message ('Database user ''{0}'' is already a member of role ''{1}''.' -f $IdentityName, $RoleName) -Tag 'idempotent'
                    } else {
                        Write-PSFMessage -Level Output -Message ('Adding database user ''{0}'' to role ''{1}'' in ''{2}''/''{3}''.' -f $IdentityName, $RoleName, $TargetServerName, $TargetDatabaseName) -Tag 'target', 'identity', 'create'

                        try {
                            $null = Invoke-DbaQuery -SqlInstance $sqlConnection -Database $TargetDatabaseName -Query ('ALTER ROLE {0} ADD MEMBER {1};' -f $bracketedRoleName, $bracketedIdentityName) -EnableException
                        } catch {
                            $message = ('Failed to add database user ''{0}'' to role ''{1}'' in ''{2}''/''{3}'': {4}' -f $IdentityName, $RoleName, $TargetServerName, $TargetDatabaseName, $_.Exception.Message)
                            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'target', 'identity'
                            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                            return
                        }

                        Write-PSFMessage -Level Output -Message ('Added database user ''{0}'' to role ''{1}''.' -f $IdentityName, $RoleName) -Tag 'target', 'identity', 'create'

                        $roleMembershipGranted = $true
                    }

                    $grantedActions = @()

                    if ($userCreated) {
                        $grantedActions += 'user'
                    }

                    if ($roleMembershipGranted) {
                        $grantedActions += 'role membership'
                    }

                    Write-PSFMessage -Level Output -Message ('Database access for ''{0}'' on ''{1}''/''{2}'' is ready. Created: {3}.' -f $IdentityName, $TargetServerName, $TargetDatabaseName, ($grantedActions -join ', ')) -Tag 'target', 'identity', 'create'
                }
            }

            [PSCustomObject]@{
                PSTypeName            = 'PSAzureSQLElasticJob.TargetDatabaseAccessResult'
                TargetServerName      = $TargetServerName
                TargetDatabaseName    = $TargetDatabaseName
                IdentityName          = $IdentityName
                RoleName              = $RoleName
                UserCreated           = $userCreated
                RoleMembershipGranted = $roleMembershipGranted
            }
        } finally {
            $null = Disconnect-DbaInstance -InputObject $sqlConnection -ErrorAction SilentlyContinue
        }
    }
}
