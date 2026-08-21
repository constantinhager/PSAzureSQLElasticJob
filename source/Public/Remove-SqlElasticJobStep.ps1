<#
    .SYNOPSIS
        Removes a step from an Azure SQL Elastic Job.

    .DESCRIPTION
        Removes a step from a job. Removing a non-existent step is a no-op unless
        -Strict is supplied.

    .PARAMETER ResourceGroupName
        The resource group containing the logical SQL server.

    .PARAMETER ServerName
        The logical SQL server hosting the Elastic Job agent.

    .PARAMETER AgentName
        The Elastic Job agent that owns the job.

    .PARAMETER JobName
        The job that owns the step.

    .PARAMETER Name
        The name of the step to remove.

    .PARAMETER Strict
        Throw when the step does not exist instead of returning silently.

    .PARAMETER PassThru
        Return the removed step object.

    .PARAMETER EnableException
        Whether a failure raises a terminating exception. Defaults to $true so a
        failed operation cannot pass unnoticed. Pass $false to get a warning and
        no output instead, which suits pipeline processing.

    .OUTPUTS
        Microsoft.Azure.Commands.Sql.ElasticJobs.Model.AzureSqlElasticJobStepModel

    .EXAMPLE
        Remove-SqlElasticJobStep -ResourceGroupName 'rg-jobs' -ServerName 'sql-jobs' -AgentName 'agent01' -JobName 'nightly-reindex' -Name 'rebuild-indexes'
    .LINK
        https://github.com/constantinhager/PSAzureSQLElasticJob/blob/main/source/Public/Remove-SqlElasticJobStep.ps1
#>
function Remove-SqlElasticJobStep
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Strict,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter()]
        [System.Boolean]
        $EnableException = $true
    )

    process
    {
        $null = Assert-AzContext

        $existingStep = Get-AzResourceIfPresent -ScriptBlock { Get-AzSqlElasticJobStep -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $JobName -Name $Name }

        if ($null -eq $existingStep)
        {
            $message = "Elastic Job step '{0}' was not found on job '{1}' in resource group '{2}'." -f
                $Name, $JobName, $ResourceGroupName

            if ($Strict.IsPresent)
            {
                Stop-PSFFunction -Message $message -EnableException $EnableException -Category ObjectNotFound -Tag 'strict'

                return
            }

            Write-PSFMessage -Level Output -Message ('{0} Nothing to remove.' -f $message) -Tag 'idempotent'

            return
        }

        if (-not $PSCmdlet.ShouldProcess(('{0}/{1}' -f $JobName, $Name), 'Remove Elastic Job step'))
        {
            return
        }

        Write-PSFMessage -Level Output -Message ('Removing step ''{0}'' from Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'remove'

        $null = Remove-AzSqlElasticJobStep -ResourceGroupName $ResourceGroupName -ServerName $ServerName -AgentName $AgentName -JobName $JobName -Name $Name -ErrorAction Stop

        Write-PSFMessage -Level Output -Message ('Removed step ''{0}'' from Elastic Job ''{1}''.' -f $Name, $JobName) -Tag 'step', 'remove'

        if ($PassThru.IsPresent)
        {
            return $existingStep
        }
    }
}
