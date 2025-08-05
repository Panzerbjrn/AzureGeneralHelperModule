#region Script Header
#	NAME: AzureGeneralHelperModule.psm1
#	AUTHOR: Lars Panzerbjørn
#	GitHub: Panzerbjrn
#	DATE: 2023.10.05
#	VERSION: 0.1 - 2023.10.05 - Module Created with Create-NewModuleStructure by Lars Panzerbjørn
#
#	SYNOPSIS:
#
#
#	DESCRIPTION:
#	Module to help with simple Azure tasks
#
#	REQUIREMENTS:
#
#endregion Script Header

#Requires -Version 5.0

[CmdletBinding(PositionalBinding=$False)]
param()

Write-Verbose $PSScriptRoot

#Get Functions and Helpers function definition files.
$Functions	= @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )
$Helpers = @( Get-ChildItem -Path $PSScriptRoot\Helpers\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
ForEach ($Import in @($Functions + $Helpers)){
	Try{
		. $Import.Fullname
	}
	Catch{
		Write-Error -Message "Failed to Import function $($Import.Fullname): $_"
	}
}

Export-ModuleMember -Function $Functions.Basename

