function Find-AzResourceGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [switch]$ExactMatch,

        [Parameter(Mandatory)]
        [switch]$IncludeResources,

        [Parameter(Mandatory)]
        [string[]]$SubscriptionIds,

        [Parameter(Mandatory)]
        [string[]]$Locations,

        [Parameter(Mandatory)]
        [switch]$ShowSubscriptionSummary
    )

    begin {
        Write-Verbose "Starting search for resource group: $ResourceGroupName"
    }

    process {
        # Build where clause based on match type
        if ($ExactMatch) {
            $WhereClause = "name == '$ResourceGroupName'"
            Write-Verbose "Using exact match search"
        } else {
            $WhereClause = "name contains '$ResourceGroupName'"
            Write-Verbose "Using partial match search"
        }

        # Build the base query
        if ($IncludeResources) {
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
        if ($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
            $SubsList = $SubscriptionIds -join "', '"
            $Query = $Query + "`n| where subscriptionId in ('$SubsList')"
            Write-Verbose "Filtering to specific subscriptions: $($SubscriptionIds -join ', ')"
        }

        # Add location filtering if specified
        if ($Locations -and $Locations.Count -gt 0) {
            $LocationsList = $Locations -join "', '"
            $Query = $Query + "`n| where location in ('$LocationsList')"
            Write-Verbose "Filtering to specific locations: $($Locations -join ', ')"
        }

        try {
            Write-Verbose "Executing Azure Resource Graph query"
            $Results = Search-AzGraph -Query $Query

            if ($Results.Count -eq 0) {
                Write-Warning "No resource groups found matching the pattern '$ResourceGroupName'"
                return
            }

            # Format output with subscription names
            $FormattedResults = @()
            $SubscriptionCache = @{}

            foreach ($Result in $Results) {
                # Cache subscription names to avoid repeated lookups
                if (-not $SubscriptionCache.ContainsKey($Result.subscriptionId)) {
                    $SubName = (Get-AzSubscription -SubscriptionId $Result.subscriptionId -ErrorAction SilentlyContinue).Name
                    if (-not $SubName) { $SubName = "Unknown" }
                    $SubscriptionCache[$Result.subscriptionId] = $SubName
                }

                if ($IncludeResources) {
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
            if ($ShowSubscriptionSummary) {
                Write-Host "`nSubscription Summary:" -ForegroundColor Green
                $FormattedResults | Group-Object SubscriptionName | ForEach-Object {
                    Write-Host "  $($_.Name): $($_.Count) resource group(s)" -ForegroundColor Cyan
                }
            }

            return $FormattedResults
        }
        catch {
            Write-Error "Failed to search for resource group: $($_.Exception.Message)"
        }
    }

    end {
        Write-Verbose "Search completed"
    }
}