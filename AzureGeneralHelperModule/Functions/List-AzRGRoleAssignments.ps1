Function List-AzRGRoleAssignments {
<#
	.SYNOPSIS
		Lists Azure Role Assignments on a Resource Group.

	.DESCRIPTION
		Lists Azure Role Assignments, for a Resource Group.

	.EXAMPLE
		Lists Azure Role Assignments

	.INPUTS
        Input is from command line or called from a script.
	.OUTPUTS
		Outputs object with DisplayName, SignInName, Scope, Subscription, ObjectType, RoleDefinitionName and Description.

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
			HelpMessage='Which Azure resource group would you like to target?')]
		[Alias('AzRG')]
		[string]$AzResourceGroup,

		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='Which Object Type would you like to target?')]
		[Alias('Type')]
		[ValidateSet('User', 'ServicePrincipal')]
		[string]$ObjectType,

		[Parameter(
			ValueFromPipeline=$True,
			ValueFromPipelineByPropertyName=$True,
			HelpMessage='What is the name of the account?')]
		[Alias('AccountName')]
		[string]$Name,

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
        Set-AzContext -Subscription $Menu.Item($ans).Name

        $Menu = @{}
        $Items =  Get-AzResourceGroup | select ResourceGroupName,ResourceId | Sort -Property ResourceGroupName
        for ($i=1;$i -le $Items.count; $i++) {
            Write-Host "$i. $($Items[$i-1].ResourceGroupName)"
            $Menu.Add($i,($Items[$i-1]))
            }

        [int]$ans = Read-Host 'Enter selection'
        $AZRG = $Menu.Item($ans).ResourceGroupName

        $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($AzSub.Id)/resourceGroups/$AZRG" |
        Where-Object { -not $_.Inherited }


        #$AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($AzSub.Id)"
    }
    IF($AzSubscription){
        $AzSub = Get-AzSubscription -SubscriptionName $AzSubscription
        #Set-AzContext -Subscription $AzSub.Name

        IF($AzResourceGroup){
            $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($AzSub.Id)/resourceGroups/$AzResourceGroup" |
            Where-Object { -not $_.Inherited }
        }
        ELSE{
            $AzRoleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($AzSub.Id)"
        }
    }

	IF($ObjectType -eq "User"){
		$AzRoleAssignments = $AzRoleAssignments | Where-Object {$_.ObjectType -eq "User"}
	}
	IF($ObjectType -eq "ServicePrincipal"){
		$AzRoleAssignments = $AzRoleAssignments | Where-Object {$_.ObjectType -eq "ServicePrincipal"}
	}

    IF($Name){
        $AzRoleAssignments = $AzRoleAssignments | Where-Object {$_.DisplayName -like "*$Name*"}
    }

	Write-Verbose "There are $($AzRoleAssignments.count) Az Role Assignments"
	ForEach($AzRoleAssignment in $AzRoleAssignments){
		#$AzRoleAssignment
		#$AzRoleAssignment.DisplayName
		$Output.Add($([pscustomobject]@{
			DisplayName = $AzRoleAssignment.DisplayName
			ObjectType = $AzRoleAssignment.ObjectType
			RoleDefinitionName = $AzRoleAssignment.RoleDefinitionName
			Subscription = $AzSub.Name
            ResourceGroup = $AzResourceGroup
			#SignInName = $AzRoleAssignment.SignInName
			#Scope = $AzRoleAssignment.Scope
			#Description = $AzRoleAssignment.Description
		}))
	}

	$Output
}