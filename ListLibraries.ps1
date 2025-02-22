$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"

Connect-PnPOnline -Url $siteUrl -Interactive

# Get all document libraries
Get-PnPList | Where-Object {$_.BaseType -eq "DocumentLibrary"} | Select Title
