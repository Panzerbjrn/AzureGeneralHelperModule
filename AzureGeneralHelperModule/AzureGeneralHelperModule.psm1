#region Script Header
#	Thought for the day:
#	NAME: AzureGeneralHelperModule.psm1
#	AUTHOR: Lars Panzerbjørn
#	CONTACT:  / GitHub: Panzerbjrn / Twitter: lpetersson
#	DATE: 2025.07.27
#	VERSION: 0.1 - 2025.07.27 - Module Created with Create-NewModuleStructure by Lars Panzerbj�rn
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

#Requires -Version 4.0

[CmdletBinding(PositionalBinding=$false)]
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

