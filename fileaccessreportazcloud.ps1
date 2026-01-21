# Configuration
$ResourceGroupName = "Enzygo-VM"
$StorageAccountName = "enzygoazfilesstorage"
$ShareName = "data"
$OutputCsv = "$HOME/OldFilesReport.csv" # Adjusted for Cloud Shell storage
$CutoffDate = (Get-Date).AddYears(-2)

# Authenticate (Interactive - usually auto-handled in Cloud Shell but good for safety)
# Connect-AzAccount

# Get Context
$Ctx = (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Context

# Array to hold results
$ReportData = @()

# Recursive Function
Function Get-AzureFilesRecursive {
    Param (
        [string]$Path,
        [int]$CurrentDepth
    )

    # Get files and folders in current path
    $Items = Get-AzStorageFile -Context $Ctx -ShareName $ShareName -Path $Path

    foreach ($Item in $Items) {
        
        # LOGIC FOR FILES
        if ($Item.GetType().Name -eq "AzureStorageFile") {
            # Check if file is older than the cutoff date
            if ($Item.Properties.LastModified -lt $CutoffDate) {
                $Object = [PSCustomObject]@{
                    Name         = $Item.Name
                    Path         = if ($Path) { "$Path/$($Item.Name)" } else { $Item.Name }
                    Type         = "File"
                    SizeKB       = [math]::Round($Item.Properties.Length / 1KB, 2)
                    LastModified = $Item.Properties.LastModified
                    Depth        = $CurrentDepth
                }
                $script:ReportData += $Object
            }
        }

        # LOGIC FOR DIRECTORIES (Recurse if depth limit not reached)
        if ($Item.GetType().Name -eq "AzureStorageFileDirectory" -and $CurrentDepth -lt 4) {
            $NextPath = if ($Path) { "$Path/$($Item.Name)" } else { $Item.Name }
            Get-AzureFilesRecursive -Path $NextPath -CurrentDepth ($CurrentDepth + 1)
        }
    }
}

# Run Script
Write-Host "Scanning for files older than $CutoffDate... This may take time."
Get-AzureFilesRecursive -Path "" -CurrentDepth 0

# Export
$ReportData | Export-Csv -Path $OutputCsv -NoTypeInformation
Write-Host "Done. Found $($ReportData.Count) files. Report saved to $OutputCsv"