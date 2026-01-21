# Specify the path to the security event log (replace with your actual path)
$eventLogPath = 'C:\Windows\System32\winevt\Logs\Security.evtx'

# Retrieve events with ID 4624 (logon) or 4634 (logoff) and filter for local logon (logon type = 2)
$events = Get-WinEvent -Path $eventLogPath | Where-Object {
    ($_.Id -eq 4624 -and $_.Properties[8].Value -eq 2) -or
    ($_.Id -eq 4634 -and $_.Properties[4].Value -eq 2)
}

# Extract relevant information (time created, task display name, machine name, and user ID)
foreach ($event in $events) {
    $timeCreated = $event.TimeCreated
    $taskDisplayName = $event.TaskDisplayName
    $machineName = $event.MachineName

    # User ID varies depending on event type
    if ($event.Id -eq 4624) {
        $userId = $event.Properties[5].Value
    } elseif ($event.Id -eq 4634) {
        $userId = $event.Properties[1].Value
    }

    # Print comma-separated values
    Write-Host ("{0},{1},{2},{3}" -f $timeCreated, $taskDisplayName, $machineName, $userId)
}
