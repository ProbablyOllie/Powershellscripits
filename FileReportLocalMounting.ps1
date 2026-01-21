$DriveLetter = "C:"
$OutputCsv   = "C:\Temp\OldFilesReport.csv"
$DepthLimit  = 4
$CutoffDate  = (Get-Date).AddYears(-2)

$oldFiles = Get-ChildItem -Path $DriveLetter -Recurse -Depth $DepthLimit -File | 
    Where-Object { $_.LastWriteTime -lt $CutoffDate } |
    Select-Object FullName, CreationTime, LastWriteTime, Length

if ($oldFiles) {
    $oldFiles | Export-Csv -Path $OutputCsv -NoTypeInformation
    Write-Host "Report generated: $OutputCsv"
}
else {
    Write-Host "No files found older than $CutoffDate within the specified depth limit."
}