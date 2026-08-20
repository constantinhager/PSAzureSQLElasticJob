<#
    .SYNOPSIS
        Gets the output rows a job step wrote to its output table for one execution.

    .DESCRIPTION
        Elastic Job steps configured with an output table (-OutputDatabaseObject/
        -OutputTableName on Add-SqlElasticJobStep) write their query results there,
        tagged per execution. The only reliable way to correlate those rows back
        to a specific run is the execution's ID - the same value
        Start-SqlElasticJob returns as JobExecutionId - which Azure records in an
        'internal_execution_id' column, whether the table was auto-created by the
        job step or created ahead of time following Microsoft's documented schema.

        Connects using an Azure AD access token obtained from the caller's
        signed-in Az context, so no separate SQL credential is needed.

    .PARAMETER OutputServerName
        The Azure SQL server hosting the output database. A short name has
        '.database.windows.net' appended automatically; a fully qualified name
        is used as supplied.

    .PARAMETER OutputDatabaseName
        The database containing the output table.

    .PARAMETER OutputTableName
        The output table configured on the job step.

    .PARAMETER OutputSchemaName
        The schema of the output table. Defaults to 'dbo'.

    .PARAMETER JobExecutionId
        The execution to retrieve output for, as returned by Start-SqlElasticJob.

    .PARAMETER ExecutionIdColumnName
        The output table column that stores the execution ID. Defaults to
        'internal_execution_id', the column Elastic Jobs itself expects.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true.
        Pass $false to get a warning and no output instead.

    .OUTPUTS
        System.Object

    .EXAMPLE
        $execution = Start-SqlElasticJob -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -Name 'nightly-report' -Wait
        Get-SqlElasticJobExecutionOutput -OutputServerName 'sql-reporting' -OutputDatabaseName 'reporting' -OutputTableName 'OrderCounts' -JobExecutionId $execution.JobExecutionId

        Retrieves the rows the job's most recent execution wrote to the output table.
#>
function Get-SqlElasticJobExecutionOutput {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputServerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputDatabaseName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputTableName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputSchemaName = 'dbo',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $JobExecutionId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExecutionIdColumnName = 'internal_execution_id',

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process {
        $null = Assert-AzContext

        $serverFqdn = if ($OutputServerName -like '*.*') { $OutputServerName } else { '{0}.database.windows.net' -f $OutputServerName }

        try {
            $accessToken = Get-AzAccessToken -ResourceUrl 'https://database.windows.net/' -ErrorAction Stop
        } catch {
            $message = ('Failed to acquire an Azure AD access token for Azure SQL: {0}' -f $_.Exception.Message)
            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'step', 'output'
            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

            return
        }

        try {
            $sqlConnection = Connect-DbaInstance -SqlInstance $serverFqdn -AccessToken $accessToken -Database $OutputDatabaseName -ErrorAction Stop
        } catch {
            $message = ('Failed to connect to ''{0}''/''{1}'': {2}' -f $serverFqdn, $OutputDatabaseName, $_.Exception.Message)
            Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'step', 'output'
            Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

            return
        }

        try {
            $bracketedSchemaName = Format-SqlBracketedIdentifier -Name $OutputSchemaName
            $bracketedTableName = Format-SqlBracketedIdentifier -Name $OutputTableName
            $bracketedColumnName = Format-SqlBracketedIdentifier -Name $ExecutionIdColumnName

            $query = 'SELECT * FROM {0}.{1} WHERE {2} = @ExecutionId;' -f $bracketedSchemaName, $bracketedTableName, $bracketedColumnName

            Write-PSFMessage -Level VeryVerbose -Message ('Looking up output for execution ''{0}'' in ''{1}''.''{2}''.''{3}''.' -f $JobExecutionId, $OutputDatabaseName, $bracketedSchemaName, $OutputTableName) -Tag 'step', 'output', 'lookup'

            try {
                Invoke-DbaQuery -SqlInstance $sqlConnection -Database $OutputDatabaseName -Query $query -SqlParameter @{ ExecutionId = $JobExecutionId } -EnableException
            } catch {
                $message = ('Failed to retrieve output for execution ''{0}'' from ''{1}''/''{2}'': {3}' -f $JobExecutionId, $OutputServerName, $OutputDatabaseName, $_.Exception.Message)
                Write-PSFMessage -Level Error -Message $message -ErrorRecord $_ -Tag 'step', 'output'
                Stop-PSFFunction -Message $message -EnableException $EnableException -ErrorRecord $_

                return
            }
        } finally {
            $null = Disconnect-DbaInstance -InputObject $sqlConnection -ErrorAction SilentlyContinue
        }
    }
}
