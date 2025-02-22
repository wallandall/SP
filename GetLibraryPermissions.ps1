# Define SharePoint site
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$outputFile = "$env:USERPROFILE\Desktop\FolderPermissions.csv"  # Save to Desktop

# Connect to SharePoint using Web Login
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all document libraries in the site
$docLibraries = Get-PnPList | Where-Object {$_.BaseType -eq "DocumentLibrary"}

# Ensure libraries exist
if ($docLibraries.Count -eq 0) {
    Write-Host "⚠️ No document libraries found!" -ForegroundColor Yellow
    Exit
}

# Initialize CSV file with headers
"Library Name,Folder Path,User/Group,Permission Type,Permission Level" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each document library
foreach ($library in $docLibraries) {
    $libraryName = $library.Title
    Write-Host "🔍 Processing Library: $libraryName" -ForegroundColor Cyan

    # Get all folders in the document library
    $folders = Get-PnPListItem -List $libraryName -PageSize 1000 -Fields FileRef, FileLeafRef -Query "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>1</Value></Eq></Where></Query></View>"

    # Ensure folders exist
    if ($folders.Count -eq 0) {
        Write-Host "⚠️ No folders found in: $libraryName" -ForegroundColor Yellow
        continue
    }

    # Loop through each folder
    foreach ($folder in $folders) {
        $folderPath = $folder.FieldValues["FileRef"]
        $folderName = $folder.FieldValues["FileLeafRef"]

        # Retrieve all assigned permissions for the folder
        $roleAssignments = Get-PnPListItemPermission -List $libraryName -Identity $folder.Id

        # Check if any permissions exist
        if ($roleAssignments.Count -eq 0) {
            Write-Host "⚠️ No permissions found for: $folderPath" -ForegroundColor Yellow
            continue
        }

        # Loop through permissions and retrieve users/groups
        foreach ($roleAssignment in $roleAssignments) {
            $userGroup = $roleAssignment.PrincipalName  # User or Group Name
            $roles = $roleAssignment.Roles -join ", "  # Convert roles array to comma-separated string

            # Identify whether it's a SharePoint Group, AD User, or AD Group
            if ($roleAssignment.PrincipalType -eq "User") {
                $permissionType = "AD User"
            } elseif ($roleAssignment.PrincipalType -eq "SecurityGroup") {
                $permissionType = "AD Group"
            } elseif ($roleAssignment.PrincipalType -eq "SharePointGroup") {
                $permissionType = "SharePoint Group"
            } else {
                $permissionType = "Unknown"
            }

            # Display output on screen
            Write-Host "Folder: $folderPath | User/Group: $userGroup | Type: $permissionType | Permission: $roles" -ForegroundColor Green

            # Append data to CSV immediately
            "$libraryName,$folderPath,$userGroup,$permissionType,$roles" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        }
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green
