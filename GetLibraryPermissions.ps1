# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "Northshor"
$outputFile = "$env:USERPROFILE\Desktop\AllPermissions.csv"  # Save to Desktop

# Connect to SharePoint
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all items in the document library
$items = Get-PnPListItem -List $libraryName -Fields FileRef -PageSize 1000

# Ensure items were retrieved
Write-Host "Total Items Found: $($items.Count)" -ForegroundColor Cyan

# Initialize CSV file with headers
"Path,User,Permission" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each item and retrieve permissions
foreach ($item in $items) {
    # Get file/folder path
    $filePath = $item.FieldValues["FileRef"]

    # Skip empty paths
    if ([string]::IsNullOrEmpty($filePath)) {
        Write-Host "⚠️ Skipped an item with no file path." -ForegroundColor Yellow
        continue
    }

    # Retrieve all permissions for the file/folder
    $permissions = Get-PnPObjectPermission -List $libraryName -Identity $item.Id

    # Check if any permissions exist
    if ($permissions.Count -eq 0) {
        Write-Host "⚠️ No permissions found for: $filePath" -ForegroundColor Yellow
        continue
    }

    # Loop through permissions and write data
    foreach ($perm in $permissions) {
        $user = $perm.PrincipalName
        $role = $perm.Roles -join ", "  # Convert roles array to comma-separated string

        # Display output on screen
        Write-Host "Path: $filePath | User: $user | Permission: $role" -ForegroundColor Green

        # Append data to CSV immediately
        "$filePath,$user,$role" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green
