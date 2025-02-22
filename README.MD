## Check SharePoint Permisions for a Document Library

1. Uninstall-Module PnP.PowerShell -AllVersions -Force
2. Install-Module -Name PnP.PowerShell -Force
3. Import-Module PnP.PowerShell
4. Update variable ```$siteUrl = "https://yourtenant.sharepoint.com/sites/yoursite"```
5. Update Variable ```$libraryName = "YourLibraryName"```
6. Update folder where CSV is saved  ```$outputFile = "C:\temp\UniquePermissions.csv"```
7. Run Script ```./Get_SP_Permissions.ps1```
