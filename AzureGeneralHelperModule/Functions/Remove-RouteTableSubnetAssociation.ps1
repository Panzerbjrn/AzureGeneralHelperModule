Function Remove-RouteTableSubnetAssociation {
<#
	.SYNOPSIS
		Removes the Route Table association from a subnet in an Azure Virtual Network.

	.DESCRIPTION
		This function disassociates a Route Table from a specified subnet within a Virtual Network.
		After running this function, the subnet will no longer have a Route Table attached to it
		and will use the default Azure routing.

	.PARAMETER VirtualNetworkName
		The name of the Virtual Network containing the subnet.

	.PARAMETER SubnetName
		The name of the subnet to remove the Route Table association from.

	.PARAMETER ResourceGroupName
		The name of the Resource Group containing the Virtual Network.

	.PARAMETER AzSubscription
		Optional. The Azure subscription to target. If not specified, uses the current context.

	.PARAMETER Force
		Optional. If specified, skips the confirmation prompt.

	.EXAMPLE
		Remove-RouteTableSubnetAssociation -VirtualNetworkName "MyVNet" -SubnetName "MySubnet" -ResourceGroupName "MyResourceGroup"

		Removes the Route Table association from MySubnet in MyVNet after confirmation.

	.EXAMPLE
		Remove-RouteTableSubnetAssociation -VirtualNetworkName "MyVNet" -SubnetName "MySubnet" -ResourceGroupName "MyResourceGroup" -Force

		Removes the Route Table association from MySubnet in MyVNet without confirmation.

	.EXAMPLE
		Remove-RouteTableSubnetAssociation -VirtualNetworkName "MyVNet" -SubnetName "MySubnet" -ResourceGroupName "MyResourceGroup" -AzSubscription "MySubscription"

		Removes the Route Table association from MySubnet in a specific subscription.

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs the updated subnet configuration to the pipeline.

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.01.21
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param
	(
		[Parameter(
			Mandatory,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True,
			HelpMessage = 'Name of the virtual network containing the subnet')]
		[string]$VirtualNetworkName,

		[Parameter(
			Mandatory,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True,
			HelpMessage = 'Name of the subnet to remove the Route Table association from')]
		[string]$SubnetName,

		[Parameter(
			Mandatory,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True,
			HelpMessage = 'Resource group name containing the virtual network')]
		[string]$ResourceGroupName,

		[Parameter(
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True,
			HelpMessage = 'Which Azure subscription would you like to target?')]
		[Alias('AzSub')]
		[string]$AzSubscription,

		[Parameter(
			HelpMessage = 'Skip confirmation prompt')]
		[switch]$Force
	)

	BEGIN {
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"

		# Check if Az.Network module is available
		if (-not (Get-Module -ListAvailable -Name Az.Network)) {
			throw "Az.Network module is not installed. Please install it using: Install-Module -Name Az.Network"
		}

		# Import the module if not already loaded
		if (-not (Get-Module -Name Az.Network)) {
			Import-Module Az.Network
		}
	}

	PROCESS {
		Write-Verbose "Processing $($MyInvocation.Mycommand)"

		try {
			# Set subscription context if specified
			IF ($AzSubscription) {
				Write-Verbose "Setting Azure context to subscription: $AzSubscription"
				$Subscription = Get-AzSubscription -SubscriptionName $AzSubscription
				Set-AzContext -SubscriptionId $Subscription.Id | Out-Null
			}

			# Get the virtual network
			Write-Verbose "Getting virtual network: $VirtualNetworkName in resource group: $ResourceGroupName"
			$VNet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -ErrorAction Stop

			# Get the subnet
			Write-Verbose "Getting subnet: $SubnetName"
			$Subnet = $VNet.Subnets | Where-Object { $_.Name -eq $SubnetName }

			if (-not $Subnet) {
				throw "Subnet '$SubnetName' not found in virtual network '$VirtualNetworkName'"
			}

			# Check if the subnet has a Route Table associated
			if (-not $Subnet.RouteTable) {
				Write-Host "`nSubnet '$SubnetName' does not have a Route Table associated." -ForegroundColor Yellow
				return $null
			}

			# Get current Route Table details for display
			$CurrentRouteTableId = $Subnet.RouteTable.Id
			$RouteTableIdParts = $CurrentRouteTableId -split '/'
			$CurrentRouteTableName = $RouteTableIdParts[-1]
			$CurrentRouteTableRg = $RouteTableIdParts[4]

			Write-Host "`nCurrent Route Table Association:" -ForegroundColor Cyan
			Write-Host "  Virtual Network: $VirtualNetworkName" -ForegroundColor Yellow
			Write-Host "  Subnet: $SubnetName" -ForegroundColor Yellow
			Write-Host "  Route Table: $CurrentRouteTableName" -ForegroundColor Yellow
			Write-Host "  Route Table Resource Group: $CurrentRouteTableRg`n" -ForegroundColor Yellow

			# Confirm the action
			$ConfirmMessage = "Remove Route Table '$CurrentRouteTableName' from subnet '$SubnetName' in VNet '$VirtualNetworkName'?"

			if ($Force -or $PSCmdlet.ShouldProcess($SubnetName, "Remove Route Table association")) {
				Write-Verbose "Removing Route Table association from subnet: $SubnetName"

				# Remove the Route Table association
				$Subnet.RouteTable = $null

				# Update the virtual network
				Write-Verbose "Updating virtual network configuration"
				$UpdatedVNet = Set-AzVirtualNetwork -VirtualNetwork $VNet -ErrorAction Stop

				# Get the updated subnet to confirm
				$UpdatedSubnet = $UpdatedVNet.Subnets | Where-Object { $_.Name -eq $SubnetName }

				Write-Host "Successfully removed Route Table association from subnet '$SubnetName'." -ForegroundColor Green

				# Return the updated subnet information
				$Result = [PSCustomObject]@{
					VirtualNetworkName      = $VirtualNetworkName
					SubnetName              = $SubnetName
					ResourceGroupName       = $ResourceGroupName
					PreviousRouteTable      = $CurrentRouteTableName
					CurrentRouteTable       = if ($UpdatedSubnet.RouteTable) { $UpdatedSubnet.RouteTable.Id } else { $null }
					Status                  = 'Route Table Removed'
				}

				return $Result
			}
			else {
				Write-Host "Operation cancelled by user." -ForegroundColor Yellow
			}
		}
		catch {
			Write-Error "Error removing Route Table association: $($_.Exception.Message)"
			throw
		}
	}

	END {
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}

# Example usage (uncomment to test):
# Remove-RouteTableSubnetAssociation -VirtualNetworkName "MyVNet" -SubnetName "MySubnet" -ResourceGroupName "MyResourceGroup"
# Remove-RouteTableSubnetAssociation -VirtualNetworkName "MyVNet" -SubnetName "MySubnet" -ResourceGroupName "MyResourceGroup" -Force
