# 1. Define the User Principal Name (Email) and Export Path
$UserEmail = "olduser@yourdomain.com"
$ExportPath = "C:\Temp\UserContacts.csv"

# 2. Connect to Microsoft Graph
# This will prompt for a browser login. Ensure you have Admin rights.
Connect-MgGraph -Scopes "Contacts.Read", "User.Read.All"

# 3. Fetch Contacts
Write-Host "Fetching contacts for $UserEmail..." -ForegroundColor Cyan

# We select specific properties to ensure the CSV is clean
$Contacts = Get-MgUserContact -UserId $UserEmail -Property "DisplayName", "GivenName", "Surname", "EmailAddresses", "BusinessPhones", "MobilePhone", "CompanyName" -All

# 4. Process and Export
# Since 'EmailAddresses' is a complex object, we expand the first email address for the CSV
$ProcessedContacts = $Contacts | Select-Object `
    DisplayName, `
    GivenName, `
    Surname, `
    @{Name="EmailAddress"; Expression={$_.EmailAddresses[0].Address}}, `
    @{Name="Phone"; Expression={$_.BusinessPhones[0]}}, `
    MobilePhone, `
    CompanyName

$ProcessedContacts | Export-Csv -Path $ExportPath -NoTypeInformation

Write-Host "Export complete! File saved to $ExportPath" -ForegroundColor Green

# 5. Disconnect
Disconnect-MgGraph