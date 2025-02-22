# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "YourLibraryName"
$outputFile = "$env:USERPROFILE\Desktop\DocumentPermissions.csv"  # Save to Desktop

# Connect to SharePoint using Web Login
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all files (not folders) in the specified document library
$files = Get-PnPListItem -List $libraryName -Fields "FileRef", "FileLeafRef", "FSObjType" -PageSize 1000 `
         | Where-Object { $_.FieldValues["FSObjType"] -eq 0 }  # 0 = File, 1 = Folder

# Ensure files exist
if ($files.Count -eq 0) {
    Write-Host "⚠️ No files found in the library: $libraryName" -ForegroundColor Yellow
    Exit
}

# Initialize CSV file with headers
"File Path,File Name,User/Group,Permission Level" | Out-File -FilePath $outputFile -Encoding UTF8

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

    # Loop through each permission entry
    foreach ($roleAssignment in $roleAssignments) {
        $userGroup = $roleAssignment.PrincipalName  # User or Group Name
        $permissionLevel = ($roleAssignment.Roles -join ", ")  # Permission levels

        # Display output on screen
        Write-Host "File: $filePath | User/Group: $userGroup | Permission: $permissionLevel" -ForegroundColor Green

        # Append data to CSV immediately
        "$filePath,$fileName,$userGroup,$permissionLevel" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green
