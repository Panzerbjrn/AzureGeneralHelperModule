function Get-NsgAssociatedVnets {
    <#
    .SYNOPSIS
        Gets all VNETs associated with an Azure Network Security Group.

    .DESCRIPTION
        This function takes an Azure NSG and returns information about all VNETs
        that have subnets or network interfaces associated with the NSG.

    .PARAMETER NsgName
        The name of the Network Security Group.

    .PARAMETER ResourceGroupName
        The name of the Resource Group containing the NSG.

    .PARAMETER Nsg
        An existing NSG object (from Get-AzNetworkSecurityGroup).

    .EXAMPLE
        Get-NsgAssociatedVnets -NsgName "MyNSG" -ResourceGroupName "MyResourceGroup"

    .EXAMPLE
        $nsg = Get-AzNetworkSecurityGroup -Name "MyNSG" -ResourceGroupName "MyResourceGroup"
        Get-NsgAssociatedVnets -Nsg $nsg
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$NsgName,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$ResourceGroupName,

        [Parameter(Mandatory, ParameterSetName = 'ByObject', ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup]$Nsg
    )

    begin {
        # Check if Az.Network module is available
        if (-not (Get-Module -ListAvailable -Name Az.Network)) {
            throw "Az.Network module is not installed. Please install it using: Install-Module -Name Az.Network"
        }

        # Import the module if not already loaded
        if (-not (Get-Module -Name Az.Network)) {
            Import-Module Az.Network
        }
    }

    process {
        try {
            # Get the NSG object if not provided
            if ($PSCmdlet.ParameterSetName -eq 'ByName') {
                Write-Verbose "Retrieving NSG: $NsgName from Resource Group: $ResourceGroupName"
                $Nsg = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
            }

            Write-Host "`nNSG: $($Nsg.Name)" -ForegroundColor Cyan
            Write-Host "Resource Group: $($Nsg.ResourceGroupName)" -ForegroundColor Cyan
            Write-Host "Location: $($Nsg.Location)`n" -ForegroundColor Cyan

            $vnetInfo = @()

            # Check subnets associated with the NSG
            if ($Nsg.Subnets -and $Nsg.Subnets.Count -gt 0) {
                Write-Host "Associated Subnets ($($Nsg.Subnets.Count)):" -ForegroundColor Green

                foreach ($subnetRef in $Nsg.Subnets) {
                    # Parse the subnet resource ID to extract VNET and subscription info
                    $subnetId = $subnetRef.Id
                    $idParts = $subnetId -split '/'

                    # Extract subscription, resource group, VNET, and subnet name
                    $subscriptionId = $idParts[2]
                    $subnetRg = $idParts[4]
                    $vnetName = $idParts[8]
                    $subnetName = $idParts[10]

                    Write-Host "  - Subnet: $subnetName" -ForegroundColor Yellow
                    Write-Host "    VNET: $vnetName" -ForegroundColor Yellow
                    Write-Host "    Resource Group: $subnetRg" -ForegroundColor Yellow
                    Write-Host "    Subscription: $subscriptionId`n" -ForegroundColor Yellow

                    # Add to collection
                    $vnetInfo += [PSCustomObject]@{
                        Type              = 'Subnet'
                        VNetName          = $vnetName
                        SubnetName        = $subnetName
                        ResourceGroup     = $subnetRg
                        SubscriptionId    = $subscriptionId
                        ResourceId        = $subnetId
                    }
                }
            } else {
                Write-Host "No subnets are associated with this NSG.`n" -ForegroundColor Yellow
            }

            # Check network interfaces associated with the NSG
            if ($Nsg.NetworkInterfaces -and $Nsg.NetworkInterfaces.Count -gt 0) {
                Write-Host "Associated Network Interfaces ($($Nsg.NetworkInterfaces.Count)):" -ForegroundColor Green

                foreach ($nicRef in $Nsg.NetworkInterfaces) {
                    $nicId = $nicRef.Id
                    $idParts = $nicId -split '/'

                    $subscriptionId = $idParts[2]
                    $nicRg = $idParts[4]
                    $nicName = $idParts[8]

                    Write-Host "  - NIC: $nicName (Resource Group: $nicRg)`n" -ForegroundColor Yellow

                    # Optionally, get the NIC details to find its VNET
                    try {
                        $nic = Get-AzNetworkInterface -ResourceGroupName $nicRg -Name $nicName -ErrorAction Stop

                        foreach ($ipConfig in $nic.IpConfigurations) {
                            if ($ipConfig.Subnet) {
                                $subnetId = $ipConfig.Subnet.Id
                                $subnetIdParts = $subnetId -split '/'
                                $vnetName = $subnetIdParts[8]
                                $subnetName = $subnetIdParts[10]

                                Write-Host "    Connected to Subnet: $subnetName" -ForegroundColor Magenta
                                Write-Host "    VNET: $vnetName`n" -ForegroundColor Magenta

                                $vnetInfo += [PSCustomObject]@{
                                    Type              = 'NetworkInterface'
                                    VNetName          = $vnetName
                                    SubnetName        = $subnetName
                                    NICName           = $nicName
                                    ResourceGroup     = $nicRg
                                    SubscriptionId    = $subscriptionId
                                    ResourceId        = $nicId
                                }
                            }
                        }
                    } catch {
                        Write-Warning "Could not retrieve details for NIC: $nicName - $($_.Exception.Message)"
                    }
                }
            } else {
                Write-Host "No network interfaces are directly associated with this NSG.`n" -ForegroundColor Yellow
            }

            # Return the collection of VNET associations
            if ($vnetInfo.Count -gt 0) {
                Write-Host "`nSummary - Unique VNETs:" -ForegroundColor Cyan
                $uniqueVnets = $vnetInfo | Select-Object -Property VNetName, ResourceGroup -Unique
                $uniqueVnets | Format-Table -AutoSize

                return $vnetInfo
            } else {
                Write-Host "No VNET associations found for this NSG." -ForegroundColor Red
                return $null
            }

        } catch {
            Write-Error "Error retrieving NSG associations: $($_.Exception.Message)"
            throw
        }
    }
}

# Example usage (uncomment to test):
# Get-NsgAssociatedVnets -NsgName "MyNSG" -ResourceGroupName "MyResourceGroup"
# Or pipe an NSG object:
# Get-AzNetworkSecurityGroup -Name "MyNSG" -ResourceGroupName "MyRG" | Get-NsgAssociatedVnets
