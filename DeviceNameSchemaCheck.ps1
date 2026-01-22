
<##created by Ollie Leggett

This script retreives devices that are not part of the naming convention- please see ITG documentation for more details on how to alter this script for your needs##>

# Import the Microsoft Graph Device Management module and connect
Import-Module Microsoft.Graph.DeviceManagement
Connect-MgGraph -Scopes DeviceManagementManagedDevices.ReadWrite.All

# Load Visual Basic assembly for the popup
Add-Type -AssemblyName Microsoft.VisualBasic

# Ask the user for the naming convention prefix
$Prefix = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the Naming Convention Prefix (e.g., 'MCi-'):", "Naming Convention Input")

if ([string]::IsNullOrWhiteSpace($Prefix)) {
    Write-Host "Operation cancelled or no input provided." -ForegroundColor Yellow
    exit
}

$Devices = Get-MgDeviceManagementManagedDevice -All | Where-Object {$_.DeviceName -notlike "$Prefix*" }

ForEach ($Device in $Devices) {

    $NewName = "$Prefix$($Device.SerialNumber)"

    Write-Host "Renaming $($Device.DeviceName) to $NewName" -ForegroundColor Cyan
    Update-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.Id -DeviceName $NewName
}