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

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel

    .EXAMPLE
        Add-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex' -Name 'rebuild-indexes' -TargetGroupName 'all-databases' -CredentialName 'jobuser' -CommandText 'EXEC dbo.usp_RebuildIndexes'
#>
function Add-SqlElasticJobStep
{
    # CredentialName names an existing job credential; it never carries a secret.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'CredentialName', Justification = 'The parameter is the name of a job credential, not a password.')]
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
        $RetryIntervalBackoffMultiplier
    )

    process
    {
        $null = Assert-AzContext

        $existingStep = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobStep -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $JobName -Name $Name }

        if ($null -ne $existingStep)
        {
            Write-PSFMessage -Level Output -Message ('Elastic Job step ''{0}'' already exists on job ''{1}''.' -f $Name, $JobName) -Tag 'idempotent'

            return $existingStep
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $JobName, $Name), 'Add Elastic Job step'))
        {
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
        )

        $stepParameters = Add-OptionalParameter -Parameter $stepParameters -BoundParameter $PSBoundParameters -Name $optionalParameters

        Write-PSFMessage -Level Output -Message ('Adding step ''{0}'' to Elastic Job ''{1}'' against target group ''{2}''.' -f $Name, $JobName, $TargetGroupName) -Tag 'step', 'create'

        $step = Add-AzSqlElasticJobStep @stepParameters -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Added step ''{0}'' to Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'create'

        return $step
    }
}
