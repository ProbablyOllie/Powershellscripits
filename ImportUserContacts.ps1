# 1. Configuration
$NewUserEmail = "newuser@yourdomain.com"
$ImportPath = "C:\Temp\UserContacts.csv"

# 2. Connect to Microsoft Graph with Write Permissions
Connect-MgGraph -Scopes "Contacts.ReadWrite", "User.Read.All"

# 3. Import CSV Data
if (Test-Path $ImportPath) {
    $ContactsToImport = Import-Csv -Path $ImportPath
    Write-Host "Starting import for $NewUserEmail..." -ForegroundColor Cyan
} else {
    Write-Error "CSV file not found at $ImportPath"
    return
}

# 4. Loop through each contact and create in the new mailbox
foreach ($Contact in $ContactsToImport) {
    # Construct the Email Address object (Graph requires a specific format)
    $EmailObject = @(
        @{
            Address = $Contact.EmailAddress
            Name    = $Contact.DisplayName
        }
    )

    # Create the parameters for the new contact
    $Params = @{
        GivenName      = $Contact.GivenName
        Surname        = $Contact.Surname
        DisplayName    = $Contact.DisplayName
        EmailAddresses = $EmailObject
        BusinessPhones = @($Contact.Phone)
        MobilePhone    = $Contact.MobilePhone
        CompanyName    = $Contact.CompanyName
    }

    try {
        New-MgUserContact -UserId $NewUserEmail -BodyParameter $Params
        Write-Host "Successfully imported: $($Contact.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to import: $($Contact.DisplayName). Error: $_"
    }
}

Write-Host "Process Complete." -ForegroundColor White

# 5. Clean up
Disconnect-MgGraph