#Uninstall-Module PnP.PowerShell -AllVersions -Force
#Install-Module -Name PnP.PowerShell -Force
#Import-Module PnP.PowerShell

# Connect to SharePoint Online
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
Connect-PnPOnline -Url $siteUrl -Interactive

# Define Library Name
$libraryName = "YourLibraryName"

# Output CSV File Path
$outputFile = "C:\temp\UniquePermissions.csv"

# Retrieve all items in the Library
$items = Get-PnPListItem -List $libraryName -Fields FileRef, HasUniqueRoleAssignments

# Initialize an empty array for results
$permissionResults = @()

# Loop through items and check for unique permissions
foreach ($item in $items) {
    if ($item["HasUniqueRoleAssignments"] -eq $true) {
        # Store data in a structured object
        $permissionData = [PSCustomObject]@{
            Path        = $item["FileRef"]
            Permission  = "Unique"
        }
        # Add to results array
        $permissionResults += $permissionData
    }
}

# Export results to CSV
$permissionResults | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Export complete! File saved at: $outputFile"



