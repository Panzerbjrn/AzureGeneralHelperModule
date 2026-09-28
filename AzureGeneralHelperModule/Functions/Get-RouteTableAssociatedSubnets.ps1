function Get-RouteTableAssociatedSubnets {
    <#
    .SYNOPSIS
        Gets all subnets associated with an Azure Route Table.

    .DESCRIPTION
        This function takes an Azure Route Table and returns information about all subnets
        that are associated with the Route Table, including their VNet and resource group details.

    .PARAMETER RouteTableName
        The name of the Route Table.

    .PARAMETER ResourceGroupName
        The name of the Resource Group containing the Route Table.

    .PARAMETER RouteTable
        An existing Route Table object (from Get-AzRouteTable).

    .PARAMETER AzSubscription
        Optional. The Azure subscription to target. If not specified, uses the current context.

    .EXAMPLE
        Get-RouteTableAssociatedSubnets -RouteTableName "MyRouteTable" -ResourceGroupName "MyResourceGroup"

    .EXAMPLE
        $rt = Get-AzRouteTable -Name "MyRouteTable" -ResourceGroupName "MyResourceGroup"
        Get-RouteTableAssociatedSubnets -RouteTable $rt

    .EXAMPLE
        Get-AzRouteTable -Name "MyRouteTable" -ResourceGroupName "MyRG" | Get-RouteTableAssociatedSubnets

    .INPUTS
        Input is from command line or called from a script.

    .OUTPUTS
        Outputs subnet association information to the pipeline.

    .NOTES
        Author:             Lars Panzerbjørn
        Creation Date:      2026.01.21
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$RouteTableName,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$ResourceGroupName,

        [Parameter(Mandatory, ParameterSetName = 'ByObject', ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Network.Models.PSRouteTable]$RouteTable,

        [Parameter(
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'Which Azure subscription would you like to target?')]
        [Alias('AzSub')]
        [string]$AzSubscription
    )

    BEGIN{
        Write-Verbose "Beginning $($MyInvocation.Mycommand)"

        # Check if Az.Network module is available
        IF(-not (Get-Module -ListAvailable -Name Az.Network)) {
            throw "Az.Network module is not installed. Please install it using: Install-Module -Name Az.Network"
        }

        # Import the module if not already loaded
        IF(-not (Get-Module -Name Az.Network)) {
            Import-Module Az.Network
        }
    }

    PROCESS{
        Write-Verbose "Processing $($MyInvocation.Mycommand)"

        TRY{
            # Set subscription context if specified
            IF($AzSubscription) {
                Write-Verbose "Setting Azure context to subscription: $AzSubscription"
                $Subscription = Get-AzSubscription -SubscriptionName $AzSubscription
                Set-AzContext -SubscriptionId $Subscription.Id | Out-Null
            }

            # Get the Route Table object if not provided
            IF($PSCmdlet.ParameterSetName -eq 'ByName') {
                Write-Verbose "Retrieving Route Table: $RouteTableName from Resource Group: $ResourceGroupName"
                $RouteTable = Get-AzRouteTable -Name $RouteTableName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
            }

            Write-Host "`nRoute Table: $($RouteTable.Name)" -ForegroundColor Cyan
            Write-Host "Resource Group: $($RouteTable.ResourceGroupName)" -ForegroundColor Cyan
            Write-Host "Location: $($RouteTable.Location)" -ForegroundColor Cyan
            Write-Host "Disable BGP Route Propagation: $($RouteTable.DisableBgpRoutePropagation)`n" -ForegroundColor Cyan

            $subnetInfo = @()

            # Check subnets associated with the Route Table
            IF($RouteTable.Subnets -and $RouteTable.Subnets.Count -gt 0) {
                Write-Host "Associated Subnets ($($RouteTable.Subnets.Count)):" -ForegroundColor Green

                foreach ($subnetRef in $RouteTable.Subnets) {
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
                    $subnetInfo += [PSCustomObject]@{
                        RouteTableName    = $RouteTable.Name
                        VNetName          = $vnetName
                        SubnetName        = $subnetName
                        ResourceGroup     = $subnetRg
                        SubscriptionId    = $subscriptionId
                        ResourceId        = $subnetId
                    }
                }
            }
            else {
                Write-Host "No subnets are associated with this Route Table.`n" -ForegroundColor Yellow
            }

            # Display route summary
            IF($RouteTable.Routes -and $RouteTable.Routes.Count -gt 0) {
                Write-Host "Routes in this Route Table ($($RouteTable.Routes.Count)):" -ForegroundColor Green
                foreach ($route in $RouteTable.Routes) {
                    Write-Host "  - $($route.Name): $($route.AddressPrefix) -> $($route.NextHopType)" -ForegroundColor Magenta
                    IF($route.NextHopIpAddress) {
                        Write-Host "    Next Hop IP: $($route.NextHopIpAddress)" -ForegroundColor Magenta
                    }
                }
                Write-Host ""
            }

            # Return the collection of subnet associations
            IF($subnetInfo.Count -gt 0) {
                Write-Host "Summary - Associated Subnets:" -ForegroundColor Cyan
                $subnetInfo | Format-Table -Property VNetName, SubnetName, ResourceGroup -AutoSize

                return $subnetInfo
            }
            else {
                Write-Host "No subnet associations found for this Route Table." -ForegroundColor Red
                return $null
            }

        }
        CATCH{
            Write-Error "Error retrieving Route Table associations: $($_.Exception.Message)"
            throw
        }
    }

    END{
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    }
}

# Example usage (uncomment to test):
# Get-RouteTableAssociatedSubnets -RouteTableName "MyRouteTable" -ResourceGroupName "MyResourceGroup"
# Or pipe a Route Table object:
# Get-AzRouteTable -Name "MyRouteTable" -ResourceGroupName "MyRG" | Get-RouteTableAssociatedSubnets
