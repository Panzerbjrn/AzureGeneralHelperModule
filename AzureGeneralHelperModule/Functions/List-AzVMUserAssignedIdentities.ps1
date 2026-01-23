function List-AzVMUserAssignedIdentities {
    <#
    .SYNOPSIS
        Lists user-assigned managed identities on an Azure Virtual Machine.

    .DESCRIPTION
        This function retrieves and displays all user-assigned managed identities
        that are associated with an Azure Virtual Machine.

    .PARAMETER VMName
        The name of the Virtual Machine.

    .PARAMETER ResourceGroupName
        The name of the Resource Group containing the Virtual Machine.

    .PARAMETER AzSubscription
        Optional. The Azure subscription to target. If not specified, uses the current context.

    .EXAMPLE
        List-AzVMUserAssignedIdentities -VMName "MyVM" -ResourceGroupName "MyResourceGroup"

    .EXAMPLE
        List-AzVMUserAssignedIdentities -VMName "MyVM" -ResourceGroupName "MyRG" -AzSubscription "Production"

    .INPUTS
        Input is from command line or called from a script.

    .OUTPUTS
        Outputs user-assigned identity information to the pipeline.

    .NOTES
        Author:             Lars Panzerbjørn
        Creation Date:      2026.01.23
    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Name of the Virtual Machine')]
        [Alias('VM')]
        [string]$VMName,

        [Parameter(
            Mandatory,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Which Azure resource group would you like to target?')]
        [Alias('AzRG')]
        [string]$ResourceGroupName,

        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Which Azure subscription would you like to target?')]
        [Alias('AzSub')]
        [string]$AzSubscription
    )

    begin {
        Write-Verbose "Beginning $($MyInvocation.Mycommand)"

        # Check if Az.Compute module is available
        if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
            throw "Az.Compute module is not installed. Please install it using: Install-Module -Name Az.Compute"
        }

        # Import the module if not already loaded
        if (-not (Get-Module -Name Az.Compute)) {
            Import-Module Az.Compute
        }
    }

    process {
        Write-Verbose "Processing $($MyInvocation.Mycommand)"

        try {
            # Set subscription context if specified
            if ($AzSubscription) {
                Write-Verbose "Setting Azure context to subscription: $AzSubscription"
                Set-AzContext -Subscription $AzSubscription | Out-Null
            }

            # Get the VM
            Write-Verbose "Retrieving Virtual Machine: $VMName from Resource Group: $ResourceGroupName"
            $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop

            Write-Host "`nVirtual Machine: $($VM.Name)" -ForegroundColor Cyan
            Write-Host "Resource Group: $($VM.ResourceGroupName)" -ForegroundColor Cyan
            Write-Host "Location: $($VM.Location)`n" -ForegroundColor Cyan

            $identityInfo = @()

            # Check identity type
            if ($VM.Identity) {
                $identityType = $VM.Identity.Type
                Write-Host "Identity Type: $identityType" -ForegroundColor Yellow

                # Check for user-assigned identities
                if ($VM.Identity.UserAssignedIdentities -and $VM.Identity.UserAssignedIdentities.Count -gt 0) {
                    Write-Host "`nUser-Assigned Identities ($($VM.Identity.UserAssignedIdentities.Count)):" -ForegroundColor Green

                    foreach ($identity in $VM.Identity.UserAssignedIdentities.GetEnumerator()) {
                        $identityId = $identity.Key
                        $identityProperties = $identity.Value

                        # Parse identity resource ID
                        $idParts = $identityId -split '/'
                        $identitySubscriptionId = $idParts[2]
                        $identityRg = $idParts[4]
                        $identityName = $idParts[8]

                        Write-Host "  Identity Name: $identityName" -ForegroundColor Yellow
                        Write-Host "  Resource Group: $identityRg" -ForegroundColor Yellow
                        Write-Host "  Principal ID: $($identityProperties.PrincipalId)" -ForegroundColor Yellow
                        Write-Host "  Client ID: $($identityProperties.ClientId)" -ForegroundColor Yellow
                        Write-Host "  Resource ID: $identityId`n" -ForegroundColor Gray

                        # Add to collection
                        $identityInfo += [PSCustomObject]@{
                            VMName              = $VM.Name
                            IdentityName        = $identityName
                            ResourceGroup       = $identityRg
                            PrincipalId         = $identityProperties.PrincipalId
                            ClientId            = $identityProperties.ClientId
                            SubscriptionId      = $identitySubscriptionId
                            ResourceId          = $identityId
                        }
                    }

                    # Display summary table
                    Write-Host "Summary - User-Assigned Identities:" -ForegroundColor Cyan
                    $identityInfo | Format-Table -Property IdentityName, ResourceGroup, PrincipalId, ClientId -AutoSize

                    return $identityInfo
                }
                else {
                    Write-Host "`nNo user-assigned identities found on this VM." -ForegroundColor Yellow
                    if ($identityType -eq "SystemAssigned") {
                        Write-Host "This VM has a System-Assigned identity only." -ForegroundColor Yellow
                    }
                    return $null
                }
            }
            else {
                Write-Host "`nNo managed identities found on this VM." -ForegroundColor Yellow
                return $null
            }
        }
        catch {
            Write-Error "Error retrieving VM identities: $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    }
}
