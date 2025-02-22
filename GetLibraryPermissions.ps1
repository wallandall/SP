# Import PnP PowerShell module (if not installed, run: Install-Module PnP.PowerShell)
Import-Module PnP.PowerShell

# Variables
$SiteURL = "https://yourtenant.sharepoint.com/sites/yoursite" # Change to your SharePoint site URL
$LibraryName = "Documents"  # Change to your document library name
$CSVPath = "C:\SharePointPermissionsReport.csv"

# Connect to SharePoint Online (Interactive Login)
#Connect-PnPOnline -Url $SiteURL -Interactive

Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Get all files and folders in the library
$Items = Get-PnPListItem -List $LibraryName -Fields "FileRef", "FileDirRef", "HasUniqueRoleAssignments" -PageSize 5000

# Create an array to store permission results
$PermissionsReport = @()

# Loop through each file/folder in the document library
foreach ($Item in $Items) {
    $FilePath = $Item["FileRef"]  # Get file or folder path
    $HasUniquePermissions = $Item["HasUniqueRoleAssignments"]

    # Get all users/groups and their permissions for the item
    $Permissions = Get-PnPListItemPermission -List $LibraryName -Identity $Item.Id

    # If permissions exist, process each user/group
    foreach ($Permission in $Permissions) {
        $PermissionsReport += [PSCustomObject]@{
            FilePath        = $FilePath
            UniquePerms     = if ($HasUniquePermissions) { "Yes" } else { "No (Inherited)" }
            Principal       = $Permission.PrincipalName  # User or Group name
            Role            = $Permission.Roles -join ", "  # Multiple roles in one field
        }
    }
}

# Export results to CSV
$PermissionsReport | Export-Csv -Path $CSVPath -NoTypeInformation

Write-Host "✅ Permissions Report generated: $CSVPath"
