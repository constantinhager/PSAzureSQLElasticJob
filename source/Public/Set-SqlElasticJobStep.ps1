<#
    .SYNOPSIS
        Updates a step of an Azure SQL Elastic Job.

    .DESCRIPTION
        Updates an existing job step. The command fails with a clear error when
        the step does not exist, rather than silently creating one. Only the
        parameters you supply are sent to Azure; everything else is left as it is.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER JobName
        The job that owns the step.

    .PARAMETER Name
        The name of the step to update.

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

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel

    .EXAMPLE
        Set-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex' -Name 'rebuild-indexes' -TimeoutSeconds 7200
#>
function Set-SqlElasticJobStep
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TargetGroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
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

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process
    {
        $null = Assert-AzContext

        $existingStep = Get-SqlElasticJobStep -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $JobName -Name $Name

        if ($null -eq $existingStep)
        {
            Stop-PSFFunction -Message ('Elastic Job step ''{0}'' was not found on job ''{1}'' in resource group ''{2}''.' -f
                $Name, $JobName, $ResourceGroupName) -EnableException $EnableException -Category ObjectNotFound

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $JobName, $Name), 'Update Elastic Job step'))
        {
            return
        }

        $stepParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            AgentName         = $AgentName
            JobName           = $JobName
            Name              = $Name
        }

        $optionalParameters = @(
            'TargetGroupName'
            'CommandText'
            'CredentialName'
            'StepId'
            'TimeoutSeconds'
            'RetryAttempts'
            'InitialRetryIntervalSeconds'
            'MaximumRetryIntervalSeconds'
            'RetryIntervalBackoffMultiplier'
        )

        $stepParameters = Add-OptionalParameter -Parameter $stepParameters -BoundParameter $PSBoundParameters -Name $optionalParameters

        Write-PSFMessage -Level Verbose -Message ('Updating step ''{0}'' on Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'update'

        $step = Set-AzSqlElasticJobStep @stepParameters

        Write-PSFMessage -Level Verbose -Message ('Updated step ''{0}'' on Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'update'

        return $step
    }
}
