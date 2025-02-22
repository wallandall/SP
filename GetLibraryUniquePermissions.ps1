#Uninstall-Module PnP.PowerShell -AllVersions -Force
#Install-Module -Name PnP.PowerShell -Force
#Import-Module PnP.PowerShell

# Connect to SharePoint Online
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"

$libraryName = "YourLibraryName"
$outputFile = "$env:USERPROFILE\Desktop\UniquePermissions.csv" # Saves file on Desktop

# Connect to SharePoint using modern authentication
Connect-PnPOnline -Url $siteUrl -Interactive

# Retrieve all items from the library
$items = Get-PnPListItem -List $libraryName -Fields FileRef, HasUniqueRoleAssignments -PageSize 1000

# Initialize an array for storing results
$permissionResults = @()

# Loop through each item and check for unique permissions
foreach ($item in $items) {
    if ($item["HasUniqueRoleAssignments"] -eq $true) {
        # Ensure the path is retrieved properly
        $filePath = $item.FieldValues["FileRef"]

        # Store data in an object
        $permissionData = [PSCustomObject]@{
            Path        = $filePath
            Permission  = "Unique"
        }

        # Add to results array
        $permissionResults += $permissionData
    }
}

# Check if data exists before exporting
if ($permissionResults.Count -gt 0) {
    $permissionResults | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8 -Force
    Write-Host "✅ Export complete! File saved at: $outputFile"
} else {
    Write-Host "⚠️ No items with unique permissions found."
}
