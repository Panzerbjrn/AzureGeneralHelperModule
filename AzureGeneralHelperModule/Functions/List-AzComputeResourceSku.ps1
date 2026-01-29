function List-AzComputeResourceSku {
<#
	.SYNOPSIS
		Lists Azure Compute Resource Skus

	.DESCRIPTION
		Lists Azure Compute Resource Skus. Will ask for region if none is specified.

	.PARAMETER AzLocation
		Optional. The Azure region/location to filter by.

	.PARAMETER AzResourceType
		Optional. The type of resource SKU to filter by. Valid values: availabilitySets, disks, hostGroups/hosts, snapshots, virtualMachines.

	.PARAMETER Ask
		Optional. If specified, prompts the user to select a region interactively.

	.EXAMPLE
		List-AzComputeResourceSku

	.EXAMPLE
		List-AzComputeResourceSku -AzLocation "westeurope"

	.EXAMPLE
		List-AzComputeResourceSku -Ask -AzResourceType "virtualMachines"

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs to screen

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.01.29
#>
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which region do you want information about?')]
		[Alias('Location','AzRegion','Region')]
		[string]$AzLocation,

		[Parameter(ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Type of resource Sku do you want information about?')]
		[Alias('Type')]
        [ValidateSet("availabilitySets","disks","hostGroups/hosts","snapshots","virtualMachines")]
		[string]$AzResourceType,

        [switch]$Ask
	)

    Write-Verbose "Processing $($MyInvocation.Mycommand)"

    if ((!$AzLocation) -and ($Ask)) {
        $Menu = @{}
        $Items =  Get-AzLocation | Select-Object DisplayName | Sort-Object -Property DisplayName
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].DisplayName)"
            $Menu.Add($i,($Items[$i-1].DisplayName))
        }

        [int]$ans = Read-Host 'Enter selection'
        $AzLocation = $Menu.Item($ans)
    }

    if ($AzLocation) {
        $Skus = Get-AzComputeResourceSku -Location $AzLocation
    }
    else {
        $Skus = Get-AzComputeResourceSku
    }

    if ($AzResourceType) {
        $Skus | Where-Object { $_.ResourceType -match $AzResourceType }
    }
    else {
        $Skus
    }
}