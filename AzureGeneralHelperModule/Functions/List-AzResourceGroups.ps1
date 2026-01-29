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

	begin {
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"
	}

	process {
		Write-Verbose "Processing $($MyInvocation.Mycommand)"

        if ($AzSubscription) {
            Set-AzContext -Subscription $AzSubscription | Out-null
        }

		if (!$AzResourceGroup) {
        	Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName | Sort-Object
		}
    }

	end {
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}