# Import PnP PowerShell module (if not installed, run: Install-Module PnP.PowerShell)
Import-Module PnP.PowerShell

# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "YourLibraryName"
$outputFile = "$env:USERPROFILE\Desktop\UniquePermissions.csv" # Saves file on Desktop

# Connect to SharePoint using modern authentication
#Connect-PnPOnline -Url $siteUrl -Interactive
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Retrieve all items from the library
$items = Get-PnPListItem -List $libraryName -Fields FileRef, HasUniqueRoleAssignments -PageSize 1000

# Initialize CSV file with headers
"Path,User,Permission" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each item and check for unique permissions
foreach ($item in $items) {
    if ($item["HasUniqueRoleAssignments"] -eq $true) {
        # Get file/folder path
        $filePath = $item.FieldValues["FileRef"]

        # Get unique permissions for the item
        $permissions = Get-PnPObjectPermission -List $libraryName -Identity $item.Id
        
        foreach ($perm in $permissions) {
            $user = $perm.PrincipalName
            $role = $perm.Roles -join ", "  # Convert roles array to comma-separated string
            
            # Store data in an object
            $permissionData = [PSCustomObject]@{
                Path        = $filePath
                User        = $user
                Permission  = $role
            }

            # Display on screen in green
            Write-Host "Path: $filePath | User: $user | Permission: $role" -ForegroundColor Green

            # Append data to CSV immediately
            "$filePath,$user,$role" | Out-File -FilePath $outputFile -Append -Encoding UTF8
        }
    }
}

Write-Host "Export complete! File saved at: $outputFile" -ForegroundColor Green

