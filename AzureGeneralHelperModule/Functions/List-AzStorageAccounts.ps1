function List-AzStorageAccounts {
<#
	.SYNOPSIS
		Lists Azure Storage Accounts

	.DESCRIPTION
		Lists Azure Storage Accounts. Will ask for Resource Group if none is specified.

	.EXAMPLE
		List-AzStorageAccounts

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		Outputs to screen

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2023.10.06
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
		[string]$AzResourceGroup
	)

	begin {
		Write-Verbose "Beginning $($MyInvocation.Mycommand)"
	}

	process {
		Write-Verbose "Processing $($MyInvocation.Mycommand)"

        if ($AzSubscription) {
            Set-AzContext -Subscription $AzSubscription | Out-null
        }

		if (!$AzResourceGroup) {
			$Menu = @{}
        	$RGs = Get-AzResourceGroup | Sort-Object -Property ResourceGroupName
			for ($i=1;$i -le $RGs.count; $i++) {
				Write-Host "$i. $($RGs[$i-1].ResourceGroupName)"
				$Menu.Add($i,($RGs[$i-1].ResourceGroupName))
			}

			[int]$ans = Read-Host 'Enter selection'
			$AzResourceGroup = $Menu.Item($ans)
		}

		Get-AzStorageAccount -ResourceGroupName $AzResourceGroup | Select-Object -ExpandProperty StorageAccountName
    }

	end {
		Write-Verbose "Ending $($MyInvocation.Mycommand)"
	}
}