function List-AzResourceGroups {
<#
	.SYNOPSIS
		Lists Azure Resourcegroups in the current Azure context

	.DESCRIPTION
		Lists Azure Resourcegroups in the current Azure context

	.EXAMPLE
		List-AzResourceGroups

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs to screen

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2023.10.06
#>
	[CmdletBinding()]
	param
	(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure subscription would you like to target?')]
		[Alias('AzSub')]
		[string]$AzSubscription
	)

	BEGIN{
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"
	}

	PROCESS{
		Write-Verbose "Processing $($MyInvocation.Mycommand)"

        IF($AzSubscription) {
            Set-AzContext -Subscription $AzSubscription | Out-null
        }

		IF(!$AzResourceGroup) {
        	Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName | Sort-Object
		}
    }

	END{
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}
