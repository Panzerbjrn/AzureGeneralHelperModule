Function List-AzContexts {
<#
	.SYNOPSIS
		Lists Azure Contexts

	.DESCRIPTION
		Lists Azure Contexts or if one is specified, all the details.

	.EXAMPLE
		List-AzContexts

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
	param
	(
		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Azure subscription would you like to target?')]
		[Alias('AzCTX')]
		[string]$AzContext
	)

	IF($AzContext){
		Get-AzContext -Name $AzContext | Select-Object * -Force
	}
	ELSE{
		Get-AzContext -ListAvailable | Sort-Object -Property Name
	}
}