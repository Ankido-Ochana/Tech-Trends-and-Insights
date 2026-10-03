#requires -Version 5.1

$RequiredPrinters = @(
    'Printer_1st_floor'
    'Printer_2nd_floor'
)

$InstalledPrinters = @(
    Get-Printer -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name
)

$MissingPrinters = @(
    $RequiredPrinters |
    Where-Object { $_ -notin $InstalledPrinters }
)


if ($MissingPrinters.Count -eq 0) {
    Write-Output 'All required printers are installed.'
    exit 0
}


Write-Output 'The following printers are missing:'

foreach ($PrinterName in $MissingPrinters) {
    Write-Output " - $PrinterName"
}

exit 1
