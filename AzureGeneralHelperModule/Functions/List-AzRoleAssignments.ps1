Function List-AzRoleAssignments {
<#
	.SYNOPSIS
		Lists Azure Role Assignments

	.DESCRIPTION
		Lists Azure Role Assignments, either for all contexts or the active context. Or user can be asked which context to use.

	.EXAMPLE
		Lists Azusre Role Assignments

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

		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Object Type would you like to target?')]
		[Alias('Type')]
		[ValidateSet('User', 'ServicePrincipal')]
		[string]$ObjectType,

        [switch]$Ask,
        [switch]$All
	)

	$AZSubs = Get-AzSubscription
	$OutPut = [System.Collections.Generic.List[psobject]]::new()

    IF($All){
        $AzRoleAssignments = Get-AzRoleAssignment
    }
    IF($Ask){
        $Menu = @{}
        $Items =  Get-AzSubscription | select Name,Id | Sort -Property Name
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].Name)"
            $Menu.Add($i,($Items[$i-1]))
            }

        [int]$ans = Read-Host 'Enter selection'
        $AzSub = $Menu.Item($ans)

        $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($AzSub.Id)"
    }
    IF($AzSubscription){
        $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$(Get-AzSubscription -SubscriptionName $AzSubscription)"
    }

	IF($ObjectType -eq "User"){
		$AzRoleAssignments = $AzRoleAssignments | Where-Object {$_.ObjectType -eq "User"}
	}
	IF($ObjectType -eq "ServicePrincipal"){
		$AzRoleAssignments = $AzRoleAssignments | Where-Object {$_.ObjectType -eq "ServicePrincipal"}
	}


	Write-Verbose "There are $($AzRoleAssignments.count) Az Role Assignments"
	ForEach($AzRoleAssignment in $AzRoleAssignments){
		#$AzRoleAssignment
		#$AzRoleAssignment.DisplayName
		$Output.Add($([pscustomobject]@{
			DisplayName = $AzRoleAssignment.RoleAssignmentName
			SignInName = $AzRoleAssignment.SignInName
			Scope = $AzRoleAssignment.Scope
			Subscription = ($AZSubs | Where-Object {$_.Id -eq $($AzRoleAssignment.Scope.Split('/') | Select-object -First 1 -Skip 2)}).Name
			ObjectType = $AzRoleAssignment.ObjectType
			RoleDefinitionName = $AzRoleAssignment.RoleDefinitionName
			Description = $AzRoleAssignment.Description
		}))
	}

	$Output
}