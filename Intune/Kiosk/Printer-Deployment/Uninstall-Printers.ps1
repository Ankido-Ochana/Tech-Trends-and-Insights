#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$ManagedPrinters = @(
    'Printer_1st_floor'
    'Printer_2nd_floor'
)

$WorkFolder = Join-Path $env:ProgramData 'Intune\PrinterDeployment'


# Remove managed printer queues
foreach ($PrinterName in $ManagedPrinters) {
    $Printer = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue

    if ($null -eq $Printer) {
        continue
    }

    Remove-Printer -Name $PrinterName -Confirm:$false -ErrorAction Stop
}


# Remove the local printer export
$LocalExport = Join-Path $WorkFolder 'PrinterExport-2026.printerExport'

if (Test-Path -LiteralPath $LocalExport) {
    Remove-Item -LiteralPath $LocalExport -Force
}


# Remove the working directory if it is empty
if (Test-Path -LiteralPath $WorkFolder) {
    $RemainingFiles = Get-ChildItem -LiteralPath $WorkFolder -Force -ErrorAction SilentlyContinue

    if ($RemainingFiles.Count -eq 0) {
        Remove-Item -LiteralPath $WorkFolder -Force
    }
}


Write-Output 'Printer removal completed successfully.'

exit 0
