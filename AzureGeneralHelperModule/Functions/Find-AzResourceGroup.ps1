function Find-AzResourceGroup {
    <#
    .SYNOPSIS
        Finds Azure Resource Groups across subscriptions using Azure Resource Graph.

    .DESCRIPTION
        This function searches for Azure Resource Groups across one or more subscriptions using Azure Resource Graph queries.
        It supports exact or partial name matching, filtering by subscription and location, and optionally including resources within the resource groups.

    .PARAMETER ResourceGroupName
        The name of the Resource Group to search for. Supports exact or partial matching based on the ExactMatch parameter.

    .PARAMETER ExactMatch
        If specified, performs an exact name match. Otherwise, performs a partial match (contains).

    .PARAMETER IncludeResources
        If specified, includes all resources within the matching resource groups in the results.

    .PARAMETER SubscriptionIds
        Optional. Array of subscription IDs to search within. If not specified, searches all accessible subscriptions.

    .PARAMETER Locations
        Optional. Array of Azure locations to filter by. If not specified, searches all locations.

    .PARAMETER ShowSubscriptionSummary
        If specified, displays a summary of results grouped by subscription.

    .EXAMPLE
        Find-AzResourceGroup -ResourceGroupName "myapp" -ExactMatch

        Finds resource groups with the exact name "myapp".

    .EXAMPLE
        Find-AzResourceGroup -ResourceGroupName "prod" -IncludeResources

        Finds all resource groups containing "prod" in their name and includes all resources within them.

    .EXAMPLE
        Find-AzResourceGroup -ResourceGroupName "network" -SubscriptionIds @("sub-id-1", "sub-id-2") -ShowSubscriptionSummary

        Finds resource groups containing "network" in the specified subscriptions and shows a summary.

    .INPUTS
        Input is from command line or called from a script.

    .OUTPUTS
        Outputs resource group information with subscription details to the pipeline.

    .NOTES
        Author:             Lars Panzerbjørn
        Creation Date:      2026.01.29
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ResourceGroupName,

        [Parameter()]
        [switch]$ExactMatch,

        [Parameter()]
        [switch]$IncludeResources,

        [Parameter()]
        [string[]]$SubscriptionIds,

        [Parameter()]
        [string[]]$Locations,

        [Parameter()]
        [switch]$ShowSubscriptionSummary
    )

    BEGIN{
        Write-Verbose "Starting search for resource group: $ResourceGroupName"
    }

    PROCESS{
        # Build where clause based on match type
        IF($ExactMatch) {
            $WhereClause = "name == '$ResourceGroupName'"
            Write-Verbose "Using exact match search"
        } else {
            $WhereClause = "name contains '$ResourceGroupName'"
            Write-Verbose "Using partial match search"
        }

        # Build the base query
        IF($IncludeResources) {
            $Query = @"
Resources
| where resourceGroup $($WhereClause -replace 'name','resourceGroup')
| project subscriptionId, resourceGroup, name, type, location
"@
        Write-Verbose "Query will include resources within resource groups"
        } else {
            $Query = @"
ResourceContainers
| where type == 'microsoft.resources/subscriptions/resourcegroups'
| where $WhereClause
| project subscriptionId, resourceGroup = name, location
"@
        }

        # Add subscription filtering if specified
        IF($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
            $SubsList = $SubscriptionIds -join "', '"
            $Query = $Query + "`n| where subscriptionId in ('$SubsList')"
            Write-Verbose "Filtering to specific subscriptions: $($SubscriptionIds -join ', ')"
        }

        # Add location filtering if specified
        IF($Locations -and $Locations.Count -gt 0) {
            $LocationsList = $Locations -join "', '"
            $Query = $Query + "`n| where location in ('$LocationsList')"
            Write-Verbose "Filtering to specific locations: $($Locations -join ', ')"
        }

        TRY{
            Write-Verbose "Executing Azure Resource Graph query"
            $Results = Search-AzGraph -Query $Query

            IF($Results.Count -eq 0) {
                Write-Warning "No resource groups found matching the pattern '$ResourceGroupName'"
                return
            }

            # Format output with subscription names
            $FormattedResults = @()
            $SubscriptionCache = @{}

            foreach ($Result in $Results) {
                # Cache subscription names to avoid repeated lookups
                IF(-not $SubscriptionCache.ContainsKey($Result.subscriptionId)) {
                    $SubName = (Get-AzSubscription -SubscriptionId $Result.subscriptionId -ErrorAction SilentlyContinue).Name
                    IF(-not $SubName) { $SubName = "Unknown" }
                    $SubscriptionCache[$Result.subscriptionId] = $SubName
                }

                IF($IncludeResources) {
                    $FormattedResults += [PSCustomObject]@{
                        SubscriptionName = $SubscriptionCache[$Result.subscriptionId]
                        SubscriptionId = $Result.subscriptionId
                        ResourceGroupName = $Result.resourceGroup
                        ResourceName = $Result.name
                        ResourceType = $Result.type
                        Location = $Result.location
                    }
                } else {
                    $FormattedResults += [PSCustomObject]@{
                        SubscriptionName = $SubscriptionCache[$Result.subscriptionId]
                        SubscriptionId = $Result.subscriptionId
                        ResourceGroupName = $Result.resourceGroup
                        Location = $Result.location
                    }
                }
            }

            # Show summary if requested
            IF($ShowSubscriptionSummary) {
                Write-Host "`nSubscription Summary:" -ForegroundColor Green
                $FormattedResults | Group-Object SubscriptionName | ForEach-Object {
                    Write-Host "  $($_.Name): $($_.Count) resource group(s)" -ForegroundColor Cyan
                }
            }

            return $FormattedResults
        }
        CATCH{
            Write-Error "Failed to search for resource group: $($_.Exception.Message)"
        }
    }

    END{
        Write-Verbose "Search completed"
    }
}
