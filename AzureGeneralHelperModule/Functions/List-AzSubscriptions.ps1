Function List-AzSubscriptions {
<#
	.SYNOPSIS
		Lists Azure subscriptions

	.DESCRIPTION
		Lists Azure subscriptions or if one is specified, all the details.

	.EXAMPLE
		List-AzSubscriptions

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs to screen

	.NOTES
		Version:			0.1
		Author:				Lars Panzerbjørn
		Creation Date:		2023.10.06
		Purpose/Change:     Initial script development
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

        IF($AzSubscription){
            Get-AzSubscription -SubscriptionName $AzSubscription | Select-Object -ExpandProperty Name | Sort-Object
        }
        ELSE{
            Get-AzSubscription | Select-Object -ExpandProperty Name | Sort-Object
        }
    }

	END{
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}