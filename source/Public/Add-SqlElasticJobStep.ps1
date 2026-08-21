<#
    .SYNOPSIS
        Adds a step to an Azure SQL Elastic Job.

    .DESCRIPTION
        Adds a T-SQL step to an existing job. The command is idempotent: when a
        step with the same name already exists on the job it is returned
        unchanged rather than causing an error. Use Set-SqlElasticJobStep to
        change an existing step.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER JobName
        The job the step is added to.

    .PARAMETER Name
        The name of the step to add.

    .PARAMETER TargetGroupName
        The target group the step runs against.

    .PARAMETER CommandText
        The T-SQL executed by the step.

    .PARAMETER CredentialName
        The job credential used to connect to the targets.

    .PARAMETER StepId
        The position of the step within the job.

    .PARAMETER TimeoutSeconds
        How long the step may run before it is cancelled.

    .PARAMETER RetryAttempts
        How many times a failed step is retried.

    .PARAMETER InitialRetryIntervalSeconds
        The delay before the first retry.

    .PARAMETER MaximumRetryIntervalSeconds
        The ceiling for the retry delay.

    .PARAMETER RetryIntervalBackoffMultiplier
        The multiplier applied to the retry delay after each failure.

    .PARAMETER OutputDatabaseObject
        The database the step's query results are written to, matching Azure's
        WithOutputDb parameter set. Required together with -OutputTableName;
        get it with Get-AzSqlDatabase.

    .PARAMETER OutputTableName
        The table in -OutputDatabaseObject that receives the step's query
        results. Required when -OutputDatabaseObject is used.

    .PARAMETER OutputCredentialName
        The job credential used to connect to the output database. Defaults to
        -CredentialName when omitted.

    .PARAMETER OutputSchemaName
        The schema of -OutputTableName in the output database. Defaults to
        'dbo' when omitted.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel

    .EXAMPLE
        Add-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex' -Name 'rebuild-indexes' -TargetGroupName 'all-databases' -CredentialName 'jobuser' -CommandText 'EXEC dbo.usp_RebuildIndexes'

    .EXAMPLE
        $outputDatabase = Get-AzSqlDatabase -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -DatabaseName 'reporting'
        Add-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-report' -Name 'collect-counts' -TargetGroupName 'all-databases' -CredentialName 'jobuser' -CommandText 'SELECT $(job_execution_id) AS JobExecutionId, COUNT(*) AS RowCount FROM dbo.Orders' -OutputDatabaseObject $outputDatabase -OutputTableName 'OrderCounts'

        Writes each target's query result into the 'OrderCounts' table of the
        'reporting' database. Selecting $(job_execution_id) AS JobExecutionId
        lets Get-SqlElasticJobExecutionOutput filter the output table for a
        specific run - Azure's own system-managed output column does not
        correlate to the JobExecutionId Start-SqlElasticJob returns.
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/Add-SqlElasticJobStep.ps1
#>
function Add-SqlElasticJobStep {
    # CredentialName/OutputCredentialName name existing job credentials; neither carries a secret.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'CredentialName', Justification = 'The parameter is the name of a job credential, not a password.')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'OutputCredentialName', Justification = 'The parameter is the name of a job credential, not a password.')]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Default')]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ServerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $AgentName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $JobName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('StepName')]
        [System.String]
        $Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CommandText,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CredentialName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $StepId,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $TimeoutSeconds,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(0, [System.Int32]::MaxValue)]
        [System.Int32]
        $RetryAttempts,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $InitialRetryIntervalSeconds,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [System.Int32]
        $MaximumRetryIntervalSeconds,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(1.0, [System.Double]::MaxValue)]
        [System.Double]
        $RetryIntervalBackoffMultiplier,

        [Parameter(Mandatory, ParameterSetName = 'WithOutputDb', ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [Microsoft.Azure.Commands.Sql.Database.Model.AzureSqlDatabaseModel]
        $OutputDatabaseObject,

        [Parameter(Mandatory, ParameterSetName = 'WithOutputDb', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputTableName,

        [Parameter(ParameterSetName = 'WithOutputDb', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputCredentialName,

        [Parameter(ParameterSetName = 'WithOutputDb', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutputSchemaName
    )

    process {
        $null = Assert-AzContext

        $existingStep = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobStep -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $JobName -Name $Name }

        if ($null -ne $existingStep) {
            Write-PSFMessage -Level Output -Message ('Elastic Job step ''{0}'' already exists on job ''{1}''.' -f $Name, $JobName) -Tag 'idempotent'

            return $existingStep
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $JobName, $Name), 'Add Elastic Job step')) {
            return
        }

        $stepParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            JobName           = $JobName
            Name              = $Name
            TargetGroupName   = $TargetGroupName
            CommandText       = $CommandText
        }

        $optionalParameters = @(
            'CredentialName'
            'StepId'
            'TimeoutSeconds'
            'RetryAttempts'
            'InitialRetryIntervalSeconds'
            'MaximumRetryIntervalSeconds'
            'RetryIntervalBackoffMultiplier'
            'OutputDatabaseObject'
            'OutputTableName'
            'OutputCredentialName'
            'OutputSchemaName'
        )

        $stepParameters = Add-OptionalParameter -Parameter $stepParameters -BoundParameter $PSBoundParameters -Name $optionalParameters

        Write-PSFMessage -Level Output -Message ('Adding step ''{0}'' to Elastic Job ''{1}'' against target group ''{2}''.' -f $Name, $JobName, $TargetGroupName) -Tag 'step', 'create'

        $step = Add-AzSqlElasticJobStep @stepParameters -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Added step ''{0}'' to Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'create'

        return $step
    }
}
