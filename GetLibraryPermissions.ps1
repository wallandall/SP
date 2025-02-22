# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "Northshor"
$outputFile = "$env:USERPROFILE\Desktop\AllPermissions.csv"  # Save to Desktop

# Connect to SharePoint using Web Login
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all items in the document library
$items = Get-PnPListItem -List $libraryName -Fields FileLeafRef, FileRef -PageSize 1000

# Ensure items were retrieved
Write-Host "Total Items Found: $($items.Count)" -ForegroundColor Cyan

# Initialize CSV file with headers
"Path,File Name,User/Group,Permission Type,Permission Level" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each item and retrieve permissions
foreach ($item in $items) {
    # Get file/folder path and file name (with extension)
    $filePath = $item.FieldValues["FileRef"]
    $fileName = $item.FieldValues["FileLeafRef"]  # Includes file name and extension

    # Skip empty paths
    if ([string]::IsNullOrEmpty($filePath)) {
        Write-Host "⚠️ Skipped an item with no file path." -ForegroundColor Yellow
        continue
    }

    # Retrieve all assigned permissions for the item
    $roleAssignments = Get-PnPProperty -ClientObject $item -Property RoleAssignments

    # Check if any permissions exist
    if ($roleAssignments.Count -eq 0) {
        Write-Host "⚠️ No permissions found for: $filePath" -ForegroundColor Yellow
        continue
    }

    # Loop through permissions and retrieve users/groups
    foreach ($roleAssignment in $roleAssignments) {
        $principal = Get-PnPProperty -ClientObject $roleAssignment -Property Principal
        $roles = Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings

        # Extract user/group name
        $userGroup = $principal.Title
        $permissionLevel = ($roles | ForEach-Object { $_.Name }) -join ", "  # Convert roles array to comma-separated string

        # Identify whether it's a SharePoint Group, AD User, or AD Group
        if ($principal.PrincipalType -eq "User") {
            $permissionType = "AD User"
        } elseif ($principal.PrincipalType -eq "SecurityGroup") {
            $permissionType = "AD Group"
        } elseif ($principal.PrincipalType -eq "SharePointGroup") {
            $permissionType = "SharePoint Group"
        } else {
            $permissionType = "Unknown"
        }

        # Display output on screen
        Write-Host "Path: $filePath | File: $fileName | User/Group: $userGroup | Type: $permissionType | Permission: $permissionLevel" -ForegroundColor Green

        # Append data to CSV immediately
        "$filePath,$fileName,$userGroup,$permissionType,$permissionLevel" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green
