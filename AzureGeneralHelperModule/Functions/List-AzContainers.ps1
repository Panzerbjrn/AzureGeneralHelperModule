Function List-AzContainers{
<#
	.SYNOPSIS
		Lists Azure Containers

	.DESCRIPTION
		Lists Azure Containers. Will ask for Resource Group/Storage Account if none is specified.

	.EXAMPLE
		List-AzContainers

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
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure subscription would you like to target?')]
		[Alias('AzSub')]
		[string]$AzSubscription,

		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure resource group would you like to target?')]
		[Alias('AzRG')]
		[string]$AzResourceGroup,

		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure storage account would you like to target?')]
		[Alias('AzSA')]
		[string]$AzStorageAccount
	)

	BEGIN{
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"
	}

	PROCESS{
		Write-Verbose "Processing $($MyInvocation.Mycommand)"

        IF($AzSubscription){
            Set-AzContext -Subscription $AzSubscription | Out-null
        }

		IF(!$AzResourceGroup){
			$Menu = @{}
        	$RGs = Get-AzResourceGroup | Sort-Object -Property ResourceGroupName
			for ($i=1;$i -le $RGs.count; $i++) {
				Write-Host "$i. $($RGs[$i-1].ResourceGroupName)"
				$Menu.Add($i,($RGs[$i-1].ResourceGroupName))
				}

			[int]$ans = Read-Host 'Enter selection'
			$AzResourceGroup = $Menu.Item($ans)
		}

        IF($AzStorageAccount){$AzStorageAccount = Get-AzStorageAccount -ResourceGroupName $AzResourceGroup -Name $AzStorageAccount}
		IF(!$AzStorageAccount){
			$Menu = @{}
        	$RGs = Get-AzStorageAccount -ResourceGroupName $AzResourceGroup | Sort-Object -Property StorageAccountName
			for ($i=1;$i -le $RGs.count; $i++) {
				Write-Host "$i. $($RGs[$i-1].StorageAccountName)"
				$Menu.Add($i,($RGs[$i-1].StorageAccountName))
			}

			[int]$ans = Read-Host 'Enter selection'
			$AzStorageAccount = $Menu.Item($ans)
		}

        Get-AzStorageContainer -Context (Get-AzStorageAccount -ResourceGroupName $AzResourceGroup -Name $AzStorageAccount).Context | Select-Object -ExpandProperty Name | Sort-Object


    }

	END{
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}