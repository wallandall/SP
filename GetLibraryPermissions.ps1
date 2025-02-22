# Define SharePoint site and document library
$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"
$libraryName = "Northshor"
$outputFile = "$env:USERPROFILE\Desktop\UniquePermissions.csv" # Saves file on Desktop

# Connect to SharePoint
Connect-PnPOnline -Url $siteUrl -UseWebLogin

# Test if list retrieval works
$items = Get-PnPListItem -List $libraryName -PageSize 10
Write-Host "Total Items Found: " $items.Count

# If the above command works, proceed with the script
if ($items.Count -eq 0) {
    Write-Host " No items found in the library!" -ForegroundColor Yellow
    Exit
}

# Initialize CSV file with headers
"Path,User,Permission" | Out-File -FilePath $outputFile -Encoding UTF8

# Loop through each item and check permissions
foreach ($item in $items) {
    $filePath = $item.FieldValues["FileRef"]
    if ([string]::IsNullOrEmpty($filePath)) { continue }

    if ($item["HasUniqueRoleAssignments"] -eq $true) {
        $permissions = Get-PnPObjectPermission -List $libraryName -Identity $item.Id
        foreach ($perm in $permissions) {
            $user = $perm.PrincipalName
            $role = $perm.Roles -join ", "

            "$filePath,$user,$role" | Out-File -FilePath $outputFile -Append -Encoding UTF8
            Write-Host "Path: $filePath | User: $user | Permission: $role" -ForegroundColor Green
        }
    }
}

Write-Host "Export complete! File saved at: $outputFile" -ForegroundColor Green
