<#
.SYNOPSIS
    Finds AD group memberships for a user and scans a directory for folder access.
    
.DESCRIPTION
    1. Prompts for AD Username and Target Folder Path.
    2. Retrieves all recursive group memberships for the user.
    3. Scans the folder structure (recursive).
    4. Checks if the user or any of their groups have explicit permissions on the folders.
    5. Exports results to a CSV file.

.NOTES
    - Requires ActiveDirectory PowerShell module (RSAT).
    - Must be run as Administrator or with sufficient permissions to read ACLs.
    - Large directory trees may take a long time to scan.
#>

# Import Active Directory Module
if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Write-Error "ActiveDirectory module is required but not found."
    exit
}

# --- Inputs ---
$TargetUser = Read-Host "Enter the AD Username (SamAccountName)"
$RootPath   = Read-Host "Enter the Folder Path to scan (e.g., D:\Data)"
$CsvPath    = Read-Host "Enter path to save CSV (e.g., C:\Temp\Permissions.csv)"

# --- Get User and Group Info ---
Write-Host "Retrieving user and group information..." -ForegroundColor Cyan

try {
    $ADUser = Get-ADUser -Identity $TargetUser -Properties MemberOf, SID
}
catch {
    Write-Error "User '$TargetUser' not found in Active Directory."
    exit
}

# Get Recursive Group Memberships (Get-ADPrincipalGroupMembership finds nested groups automatically)
Write-Host "Retrieving all recursive group memberships..." -ForegroundColor Cyan
try {
    $UserGroups = Get-ADPrincipalGroupMembership -Identity $TargetUser
}
catch {
    Write-Error "Failed to retrieve group memberships. Error: $($_.Exception.Message)"
    exit
}

# Initialize Identity Lists with standard groups
$IdentityList = @($ADUser.SID.Value) # Start with User SID
$IdentityNames = @("NT AUTHORITY\Authenticated Users", "Everyone") 

# Add User's NTAccount Name
try {
    $IdentityNames += "$($ADUser.SID.Translate([System.Security.Principal.NTAccount]))"
} catch {
    Write-Warning "Could not translate User SID to NTAccount."
}

# Add Groups found
foreach ($Group in $UserGroups) {
    try {
        $IdentityList += $Group.SID.Value
        $IdentityNames += "$($Group.SID.Translate([System.Security.Principal.NTAccount]))"
    }
    catch {
        Write-Warning "Could not resolve group name for SID: $($Group.SID.Value)"
    }
}

Write-Host "Found $($IdentityNames.Count) identities (User + Groups) to check:" -ForegroundColor Green
$IdentityNames | ForEach-Object { Write-Host " - $_" }

$Confirm = Read-Host "Do you want to continue with the scan? (Y/N)"
if ($Confirm -ne 'Y') {
    Write-Host "Cancelled."
    exit
}

# --- Scan Folders ---
Write-Host "Scanning folder structure. This may take time..." -ForegroundColor Cyan

$Results = @()
$ErrorList = @()

# Get all folders recursively. Capture errors for unreadable folders.
$Folders = Get-ChildItem -Path $RootPath -Recurse -Directory -ErrorVariable FolderAccessErrors -ErrorAction SilentlyContinue

foreach ($Err in $FolderAccessErrors) {
    $ErrorList += [PSCustomObject]@{
        Path  = $Err.TargetObject
        Error = $Err.Exception.Message
    }
}

foreach ($Folder in $Folders) {
    try {
        $Acl = Get-Acl -Path $Folder.FullName
        
        foreach ($AccessRule in $Acl.Access) {
            # Check if the Identity in the ACL matches User or their Groups
            # We check both Name (DOMAIN\Group) and checking if the SID matches
            
            $MappedIdentity = $AccessRule.IdentityReference.Value
            
            # Simple check: Is the ACL identity in our list of User/Group names?
            if ($IdentityNames -contains $MappedIdentity -and $AccessRule.AccessControlType -eq 'Allow') {
                
                $Results += [PSCustomObject]@{
                    FolderName        = $Folder.Name
                    FolderPath        = $Folder.FullName
                    UserOrGroup       = $MappedIdentity
                    FileSystemRights  = $AccessRule.FileSystemRights
                    AccessControlType = $AccessRule.AccessControlType
                    IsInherited       = $AccessRule.IsInherited
                }
            }
        }
    }
    catch {
        Write-Warning "Access Denied or Error reading ACL on: $($Folder.FullName)"
        $ErrorList += [PSCustomObject]@{
            Path  = $Folder.FullName
            Error = $_.Exception.Message
        }
    }
}

# --- Export ---
if ($Results.Count -gt 0) {
    $Results | Export-Csv -Path $CsvPath -NoTypeInformation
    Write-Host "Scan complete. Results exported to $CsvPath" -ForegroundColor Green
}
else {
    Write-Host "No specific permissions found for this user in the scanned path." -ForegroundColor Yellow
}

if ($ErrorList.Count -gt 0) {
    $ErrorLogPath = "$($CsvPath)_Errors.csv"
    $ErrorList | Export-Csv -Path $ErrorLogPath -NoTypeInformation
    Write-Host "Errors were encountered. Error log exported to $ErrorLogPath" -ForegroundColor Red
}