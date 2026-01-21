<#

server cleanup script
Created By Ollie Leggett
Please review this script and test on a non production environment before using on a server that is business critical.

#>


# 1. Component Store Cleanup (WinSxS)
Write-Host "Cleaning up Windows Component Store..." -ForegroundColor Cyan
Dism.exe /Online /Cleanup-Image /StartComponentCleanup 

# 2. Delete System-wide Temp Files
Write-Host "Clearing System Temp files..." -ForegroundColor Cyan
Get-ChildItem -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

# 3. Delete User-specific Temp Files
Write-Host "Clearing User Temp files..." -ForegroundColor Cyan
Get-ChildItem -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

# 4. Clear IIS Logs (Older than 30 days)
if (Test-Path "C:\inetpub\logs\LogFiles") {
    Write-Host "Clearing IIS logs older than 30 days..." -ForegroundColor Cyan
    Get-ChildItem -Path "C:\inetpub\logs\LogFiles" -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force
}

# 5. Empty Recycle Bin
Write-Host "Emptying Recycle Bin..." -ForegroundColor Cyan
Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue

#6. Disable Hibernation
Write-Host "Disabling Hibernation to remove hiberfil.sys..." -ForegroundColor Cyan
powercfg -h off
