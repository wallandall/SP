# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "YourLibraryName"
$outputFile = "$env:USERPROFILE\Desktop\UniquePermissions.csv" # Saves file on Desktop

# Connect to SharePoint
#Connect-PnPOnline -Url $siteUrl -Interactive
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all items
$items = Get-PnPListItem -List $libraryName -Fields FileRef, HasUniqueRoleAssignments -PageSize 1000

# Verify items exist
if ($items.Count -eq 0) {
    Write-Host "No items found in the library!" -ForegroundColor Yellow
    Exit
}

# Initialize CSV file with headers
"Path,User,Permission" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each item and check permissions
foreach ($item in $items) {
    # Get file/folder path
    $filePath = $item.FieldValues["FileRef"]

    # Skip empty paths
    if ([string]::IsNullOrEmpty($filePath)) {
        continue
    }

    # Check if the file/folder has unique permissions
    if ($item["HasUniqueRoleAssignments"] -eq $true) {
        # Get unique permissions for the item
        $permissions = Get-PnPObjectPermission -List $libraryName -Identity $item.Id

        # Check if permissions exist
        if ($permissions.Count -eq 0) {
            Write-Host " No unique permissions found for: $filePath" -ForegroundColor Yellow
            continue
        }

        # Loop through permissions and write data
        foreach ($perm in $permissions) {
            $user = $perm.PrincipalName
            $role = $perm.Roles -join ", "  # Convert roles array to comma-separated string

            # Store and log data
            "$filePath,$user,$role" | Out-File -FilePath $outputFile -Append -Encoding UTF8
            Write-Host "Path: $filePath | User: $user | Permission: $role" -ForegroundColor Green
        }
    }
}

Write-Host "Export complete! File saved at: $outputFile" -ForegroundColor Green
