function List-AzKeyVaults {
<#
	.SYNOPSIS
		Lists Azure Key Vaults

	.DESCRIPTION
		Lists Azure Key Vaults, either for all contexts or the active context. Or user can be asked which context to use.

	.PARAMETER AzSubscription
		Optional. The Azure subscription to target.

	.PARAMETER Ask
		Optional. If specified, prompts the user to select a subscription interactively.

	.PARAMETER All
		Optional. If specified, lists Key Vaults from all subscriptions.

	.EXAMPLE
		List-AzKeyVaults

	.EXAMPLE
		List-AzKeyVaults -All

	.EXAMPLE
		List-AzKeyVaults -Ask

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs object with VaultName and ResourceGroupName

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2023.10.10
#>
	[CmdletBinding()]
	param(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure subscription would you like to target?')]
		[Alias('AzSub')]
		[string]$AzSubscription,

        [switch]$Ask,
        [switch]$All
	)

    $KVaults = @()

    IF($All) {
        Get-AzSubscription | Select-Object -ExpandProperty Id | ForEach-Object {
            $KVaults += Get-AzKeyVault -SubscriptionId $_
        }
    }ELSEIF($AzSubscription) {
        Get-AzSubscription -SubscriptionName $AzSubscription | Select-Object -ExpandProperty Id | ForEach-Object {
            $KVaults += Get-AzKeyVault -SubscriptionId $_
        }
    }ELSEIF($Ask) {
        $Menu = @{}
        $Items =  Get-AzSubscription | Select-Object Name,Id | Sort-Object -Property Name
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].Name)"
            $Menu.Add($i,($Items[$i-1]))
        }

        [int]$ans = Read-Host 'Enter selection'
        $AzSub = $Menu.Item($ans)

        Write-OutPut $AzSub.Name
        Write-OutPut $AzSub.Id
        $KVaults = Get-AzKeyVault -SubscriptionId $AzSub.Id
	}ELSE {
        $KVaults = Get-AzKeyVault
    }

    $KVaults
}
