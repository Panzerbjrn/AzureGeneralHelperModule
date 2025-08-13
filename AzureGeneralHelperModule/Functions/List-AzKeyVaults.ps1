Function List-AzKeyVaults {
<#
	.SYNOPSIS
		Lists Azure Key Vaults

	.DESCRIPTION
		Lists Azure Key Vaults, either for all contexts or the active context. Or user can be asked which context to use.

	.EXAMPLE
		Lists Azusre Key Vaults

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs object with VaultName and ResourceGroupName

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2023.10.10
		Purpose/Change:     Initial script development
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

    IF($All){
        Get-AzSubscription | select-Object -ExpandProperty Id | ForEach-Object {
            $KVaults += Get-AzKeyVault -SubscriptionId $_
        }
    }
    ELSEIF($AzSubscription){
        Get-AzSubscription -SubscriptionName $AzSubscription | select-Object -ExpandProperty Id | ForEach-Object {
            $KVaults += Get-AzKeyVault -SubscriptionId $_
        }
    }
    ELSEIF($Ask){
        $Menu = @{}
        $Items =  Get-AzSubscription | select Name,Id | Sort -Property Name
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].Name)"
            $Menu.Add($i,($Items[$i-1]))
            }

        [int]$ans = Read-Host 'Enter selection'
        $AzSub = $Menu.Item($ans)

        Write-OutPut $AzSub.Name
        Write-OutPut $AzSub.Id
        $KVaults = Get-AzKeyVault -SubscriptionId $AzSub.Id
    }
    ELSE{
        $KVaults = Get-AzKeyVault
    }

    $KVaults
}