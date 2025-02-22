# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "YourLibraryName"
$outputFile = "$env:USERPROFILE\Desktop\DocumentPermissions.csv"  # Save to Desktop

# Connect to SharePoint using Web Login
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all files (not folders) in the specified document library
$files = Get-PnPListItem -List $libraryName -PageSize 1000 -Fields "FileRef", "FileLeafRef", "FSObjType" `
         | Where-Object { $_["FSObjType"] -eq 0 }  # 0 = File, 1 = Folder

# Ensure files exist
if ($files.Count -eq 0) {
    Write-Host "⚠️ No files found in the library: $libraryName" -ForegroundColor Yellow
    Exit
}

# Initialize CSV file with headers
"File Path,File Name,User/Group,Permission Type,Permission Level" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each file and retrieve permissions
foreach ($file in $files) {
    $filePath = $file.FieldValues["FileRef"]
    $fileName = $file.FieldValues["FileLeafRef"]

    # Retrieve all assigned permissions for the file
    $roleAssignments = Get-PnPListItemPermission -List $libraryName -Identity $file.Id

    # Check if any permissions exist
    if ($roleAssignments.Count -eq 0) {
        Write-Host "⚠️ No permissions found for: $filePath" -ForegroundColor Yellow
        continue
    }

    # Loop through permissions and retrieve users/groups
    foreach ($roleAssignment in $roleAssignments) {
        $userGroup = $roleAssignment.PrincipalName  # User or Group Name
        $roles = $roleAssignment.Roles -join ", "  # Convert roles array to comma-separated string

        # Identify whether it's a SharePoint Group, AD User, or AD Group
        switch ($roleAssignment.PrincipalType) {
            "User" { $permissionType = "AAD User" }
            "SecurityGroup" { $permissionType = "AAD Group" }
            "SharePointGroup" { $permissionType = "SharePoint Group" }
            default { $permissionType = "Unknown" }
        }

        # Display output on screen
        Write-Host "File: $filePath | User/Group: $userGroup | Type: $permissionType | Permission: $roles" -ForegroundColor Green

        # Append data to CSV immediately
        "$filePath,$fileName,$userGroup,$permissionType,$roles" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green
