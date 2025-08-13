Function List-AzComputeResourceSku {
<#
	.SYNOPSIS
		Lists Azusre Compute Resource Skus

	.DESCRIPTION
		Lists Azure Compute Resource Skus. Will ask for region if none is specified.

	.EXAMPLE
		List-AzComputeResourceSku

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

    IF((!$AzLocation) -and ($Ask)){
        $Menu = @{}
        $Items =  Get-AzLocation | select DisplayName | Sort -Property DisplayName
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].DisplayName)"
            $Menu.Add($i,($Items[$i-1].DisplayName))
            }

        [int]$ans = Read-Host 'Enter selection'
        $AzLocation = $Menu.Item($ans)
    }

    IF($AzLocation){
        $Skus = Get-AzComputeResourceSku -Location $AzLocation
    }
    ELSE{
        $Skus = Get-AzComputeResourceSku
    }

    IF($AzResourceType){
        $Skus | Where-Object { $_.ResourceType -match $AzResourceType }
    }
    ELSE{
        $Skus
    }
}