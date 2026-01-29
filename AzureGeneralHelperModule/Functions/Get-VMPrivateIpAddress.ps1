function Get-VMPrivateIpAddress {
    <#
    .SYNOPSIS
        Gets the private IP address of an Azure Virtual Machine.

    .DESCRIPTION
        This function retrieves the primary private IP address of an Azure Virtual Machine
        by querying the VM's network interface configuration.

    .PARAMETER VMName
        The name of the Virtual Machine.

    .EXAMPLE
        Get-VMPrivateIpAddress -VMName "MyVM"

        Returns the private IP address of the VM named "MyVM".

    .EXAMPLE
        "VM1", "VM2" | Get-VMPrivateIpAddress

        Gets private IP addresses for multiple VMs using pipeline input.

    .INPUTS
        System.String

    .OUTPUTS
        System.String
        Returns the private IP address as a string.

    .NOTES
        Author:             Lars Panzerbjørn
        Creation Date:      2026.01.29
    #>

    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Name of the Virtual Machine')]
        [Alias('VM')]
        [string]$VMName
    )

    begin {
        Write-Verbose "Beginning $($MyInvocation.Mycommand)"
    }

    process {
        Write-Verbose "Processing $($MyInvocation.Mycommand)"

        try {
            Write-Verbose "Retrieving Virtual Machine: $VMName"
            $VM = Get-AzVM -Name $VMName -ErrorAction Stop

            Write-Verbose "Getting network interface for VM: $VMName"
            $NIC = $VM | Get-AzNetworkInterface

            Write-Verbose "Extracting IP configuration"
            $IPConfig = $NIC.IpConfigurations | Select-Object -First 1

            return $IPConfig.PrivateIpAddress
        }
        catch {
            Write-Error "Error retrieving private IP address for VM '$VMName': $($_.Exception.Message)"
            throw
        }
    }

    end {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    }
}