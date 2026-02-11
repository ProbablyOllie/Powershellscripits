$dir = "C:\temp"
$url = "https://go.microsoft.com/fwlink/?linkid=2171764"
$file = "$dir\Windows11InstallationAssistant.exe"

if (!(Test-Path $dir)) { 
    New-Item -Path $dir -ItemType Directory | Out-Null 
}

Write-Host "Downloading Windows 11 Installation Assistant..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $url -OutFile $file -ErrorAction Stop
} catch {
    Write-Host "Error: Failed to download the installer. Check your internet connection." -ForegroundColor Red
    return
}

Write-Host "Starting silent upgrade preparation..." -ForegroundColor Cyan
$process = Start-Process -FilePath $file -ArgumentList "/QuietInstall /SkipEULA /Auto Upgrade /NoRestartUI" -Wait -PassThru

if ($process.ExitCode -eq 0) {
    Write-Host "Success: The upgrade has been staged. Windows 11 will install upon the next restart." -ForegroundColor Green
} else {
    Write-Host "Failure: The installer exited with error code: $($process.ExitCode)" -ForegroundColor Red
}