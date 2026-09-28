function Add-AzVMUserAssignedIdentity {
    <#
    .SYNOPSIS
        Adds a user-assigned managed identity to an Azure Virtual Machine.

    .DESCRIPTION
        This function adds a user-assigned managed identity to an Azure Virtual Machine.
        The identity must already exist before adding it to the VM.

    .PARAMETER VMName
        The name of the Virtual Machine.

    .PARAMETER ResourceGroupName
        The name of the Resource Group containing the Virtual Machine.

    .PARAMETER IdentityName
        The name of the user-assigned managed identity to add.

    .PARAMETER IdentityResourceGroup
        The name of the Resource Group containing the managed identity.
        If not specified, uses the VM's resource group.

    .PARAMETER IdentityResourceId
        Alternative parameter: The full resource ID of the user-assigned managed identity.
        Use this instead of IdentityName if you have the full resource ID.

    .PARAMETER AzSubscription
        Optional. The Azure subscription to target. If not specified, uses the current context.

    .EXAMPLE
        Add-AzVMUserAssignedIdentity -VMName "MyVM" -ResourceGroupName "MyResourceGroup" -IdentityName "MyIdentity"

    .EXAMPLE
        Add-AzVMUserAssignedIdentity -VMName "MyVM" -ResourceGroupName "MyRG" -IdentityName "MyIdentity" -IdentityResourceGroup "IdentityRG"

    .EXAMPLE
        Add-AzVMUserAssignedIdentity -VMName "MyVM" -ResourceGroupName "MyRG" -IdentityResourceId "/subscriptions/.../resourceGroups/.../providers/Microsoft.ManagedIdentity/userAssignedIdentities/MyIdentity"

    .INPUTS
        Input is from command line or called from a script.

    .OUTPUTS
        Outputs the updated VM object to the pipeline.

    .NOTES
        Author:             Lars Panzerbjørn
        Creation Date:      2026.01.23
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
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
            Mandatory,
            ParameterSetName = 'ByName',
            HelpMessage = 'Name of the user-assigned managed identity')]
        [string]$IdentityName,

        [Parameter(
            ParameterSetName = 'ByName',
            HelpMessage = 'Resource group containing the managed identity')]
        [string]$IdentityResourceGroup,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByResourceId',
            HelpMessage = 'Full resource ID of the user-assigned managed identity')]
        [string]$IdentityResourceId,

        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Which Azure subscription would you like to target?')]
        [Alias('AzSub')]
        [string]$AzSubscription
    )

    BEGIN{
        Write-Verbose "Beginning $($MyInvocation.Mycommand)"

        # Check if Az.Compute module is available
        IF(-not (Get-Module -ListAvailable -Name Az.Compute)) {
            throw "Az.Compute module is not installed. Please install it using: Install-Module -Name Az.Compute"
        }

        # Check if Az.ManagedServiceIdentity module is available
        IF(-not (Get-Module -ListAvailable -Name Az.ManagedServiceIdentity)) {
            throw "Az.ManagedServiceIdentity module is not installed. Please install it using: Install-Module -Name Az.ManagedServiceIdentity"
        }

        # Import the modules if not already loaded
        IF(-not (Get-Module -Name Az.Compute)) {
            Import-Module Az.Compute
        }
        IF(-not (Get-Module -Name Az.ManagedServiceIdentity)) {
            Import-Module Az.ManagedServiceIdentity
        }
    }

    PROCESS{
        Write-Verbose "Processing $($MyInvocation.Mycommand)"

        TRY{
            # Set subscription context if specified
            IF($AzSubscription) {
                Write-Verbose "Setting Azure context to subscription: $AzSubscription"
                Set-AzContext -Subscription $AzSubscription | Out-Null
            }

            # Get the VM
            Write-Verbose "Retrieving Virtual Machine: $VMName from Resource Group: $ResourceGroupName"
            $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop

            Write-Host "`nVirtual Machine: $($VM.Name)" -ForegroundColor Cyan
            Write-Host "Resource Group: $($VM.ResourceGroupName)" -ForegroundColor Cyan
            Write-Host "Location: $($VM.Location)" -ForegroundColor Cyan

            # Determine the identity resource ID
            IF($PSCmdlet.ParameterSetName -eq 'ByName') {
                # If IdentityResourceGroup is not specified, use VM's resource group
                IF(-not $IdentityResourceGroup) {
                    $IdentityResourceGroup = $ResourceGroupName
                    Write-Verbose "Using VM's resource group for identity: $IdentityResourceGroup"
                }

                # Get the user-assigned identity
                Write-Verbose "Retrieving managed identity: $IdentityName from Resource Group: $IdentityResourceGroup"
                $Identity = Get-AzUserAssignedIdentity -ResourceGroupName $IdentityResourceGroup -Name $IdentityName -ErrorAction Stop
                $IdentityResourceId = $Identity.Id
            }
            else {
                # Validate the provided resource ID
                Write-Verbose "Using provided identity resource ID: $IdentityResourceId"
            }

            Write-Host "`nAdding user-assigned identity..." -ForegroundColor Yellow
            Write-Host "Identity Resource ID: $IdentityResourceId" -ForegroundColor Gray

            # Check if identity is already assigned
            IF($VM.Identity -and $VM.Identity.UserAssignedIdentities) {
                IF($VM.Identity.UserAssignedIdentities.ContainsKey($IdentityResourceId)) {
                    Write-Host "`nThis identity is already assigned to the VM." -ForegroundColor Yellow
                    return $VM
                }
            }

            # Update the VM with the new identity
            IF(-not $VM.Identity) {
                # No identity exists, create UserAssigned identity type
                Write-Verbose "VM has no identity, creating UserAssigned identity type"
                $VM = Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -IdentityType UserAssigned -IdentityId $IdentityResourceId -ErrorAction Stop
            }
            ELSEIF($VM.Identity.Type -eq "SystemAssigned") {
                # VM has system-assigned identity, change to SystemAssigned,UserAssigned
                Write-Verbose "VM has SystemAssigned identity, changing to SystemAssigned,UserAssigned"
                $VM = Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -IdentityType "SystemAssigned,UserAssigned" -IdentityId $IdentityResourceId -ErrorAction Stop
            }
            else {
                # VM already has user-assigned identities, add to the collection
                Write-Verbose "Adding identity to existing user-assigned identities"
                $VM = Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM -IdentityType UserAssigned -IdentityId $IdentityResourceId -ErrorAction Stop
            }

            Write-Host "`nSuccessfully added user-assigned identity to VM: $VMName" -ForegroundColor Green

            # Get updated VM to display current identities
            $UpdatedVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

            IF($UpdatedVM.Identity -and $UpdatedVM.Identity.UserAssignedIdentities) {
                Write-Host "`nCurrent User-Assigned Identities ($($UpdatedVM.Identity.UserAssignedIdentities.Count)):" -ForegroundColor Cyan
                foreach ($identity in $UpdatedVM.Identity.UserAssignedIdentities.GetEnumerator()) {
                    $identityId = $identity.Key
                    $idParts = $identityId -split '/'
                    $identityName = $idParts[8]
                    Write-Host "  - $identityName" -ForegroundColor Yellow
                    Write-Host "    Principal ID: $($identity.Value.PrincipalId)" -ForegroundColor Gray
                    Write-Host "    Client ID: $($identity.Value.ClientId)" -ForegroundColor Gray
                }
            }

            return $UpdatedVM
        }
        CATCH{
            Write-Error "Error adding user-assigned identity to VM: $($_.Exception.Message)"
            throw
        }
    }

    END{
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    }
}
