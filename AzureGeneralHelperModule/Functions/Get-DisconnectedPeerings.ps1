Function Get-DisconnectedPeerings {
<#
	.SYNOPSIS
		Gets disconnected virtual network peerings

	.DESCRIPTION
		Retrieves virtual network peerings that are in a disconnected state from a specified virtual network.

	.EXAMPLE
		Get-DisconnectedPeerings -VirtualNetworkName "AZ-EU-NORTH-VNET01" -ResourceGroupName "cic-network-ew2-ns-core-rg-01"

		Gets all disconnected peerings from the specified virtual network.

	.EXAMPLE
		Get-DisconnectedPeerings -VirtualNetworkName "MyVNet" -ResourceGroupName "MyRG" -AzSubscription "MySubscription"

		Gets all disconnected peerings from the specified virtual network in a specific subscription.

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs disconnected peering information to screen

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.01.19
#>
	[CmdletBinding()]
	param
	(
		[Parameter(
			Mandatory,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Name of the virtual network to check for disconnected peerings')]
		[string]$VirtualNetworkName,

		[Parameter(
			Mandatory,
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Resource group name containing the virtual network')]
		[string]$ResourceGroupName,

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
			Write-Verbose "Setting Azure context to subscription: $AzSubscription"
			$Subscription = Get-AzSubscription -SubscriptionName $AzSubscription
			Set-AzContext -SubscriptionId $Subscription.Id | Out-Null
		}

		Write-Verbose "Getting virtual network: $VirtualNetworkName in resource group: $ResourceGroupName"
		$VNet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName

		Write-Verbose "Filtering for disconnected peerings"
		$DisconnectedPeerings = $VNet.VirtualNetworkPeerings | Where-Object { $_.PeeringState -eq "Disconnected" } | Select-Object Name, PeeringState, RemoteVirtualNetwork

		IF($DisconnectedPeerings){
			Write-Verbose "Found $($DisconnectedPeerings.Count) disconnected peering(s)"
			$DisconnectedPeerings
		}
		ELSE{
			Write-Verbose "No disconnected peerings found"
		}
	}

	END{
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}
