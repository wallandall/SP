
# Import PnP PowerShell module (if not installed, run: Install-Module PnP.PowerShell)
Import-Module PnP.PowerShell

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
"File Path,File Name,User/Group,Entity Type,Permission Level" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each file and retrieve permissions
foreach ($file in $files) {
    $filePath = $file.FieldValues["FileRef"]
    $fileName = $file.FieldValues["FileLeafRef"]

    # Retrieve role assignments for the file
    $roleAssignments = Get-PnPProperty -ClientObject $file -Property RoleAssignments

    # Check if any permissions exist
    if ($roleAssignments.Count -eq 0) {
        Write-Host "⚠️ No permissions found for: $filePath" -ForegroundColor Yellow
        continue
    }

    # Loop through each role assignment
    foreach ($roleAssignment in $roleAssignments) {
        # Get Principal ID
        $principalId = $roleAssignment.PrincipalId
        
        # Get User or Group Information
        $userGroup = ""
        $entityType = "Unknown"

        # Try to get Azure AD Users and Groups
        try {
            $user = Get-PnPUser -Identity $principalId -ErrorAction SilentlyContinue
            if ($user) {
                $userGroup = $user.Title
                $entityType = "M365 User (Azure AD User)"
            }
        } catch {}

        # Try to get SharePoint Groups
        if ($userGroup -eq "") {
            try {
                $spGroup = Get-PnPGroup -Identity $principalId -ErrorAction SilentlyContinue
                if ($spGroup) {
                    $userGroup = $spGroup.Title
                    $entityType = "SharePoint Group"
                }
            } catch {}
        }

        # If user/group is still empty, assume it's an Azure AD Security Group
        if ($userGroup -eq "") {
            $userGroup = "Unknown Group ($principalId)"
            $entityType = "Azure AD Security Group"
        }

        # Retrieve role permissions
        $roles = Get-PnPProperty -ClientObject $roleAssignment -Property RoleDefinitionBindings
        $permissionLevel = ($roles | ForEach-Object { $_.Name }) -join ", "

        # Display output on screen
        Write-Host "File: $filePath | User/Group: $userGroup | Entity Type: $entityType | Permission: $permissionLevel" -ForegroundColor Green

        # Append data to CSV immediately
        "$filePath,$fileName,$userGroup,$entityType,$permissionLevel" | Out-File -FilePath $outputFile -Append -Encoding UTF8
    }
}

Write-Host "✅ Export complete! File saved at: $outputFile" -ForegroundColor Green

