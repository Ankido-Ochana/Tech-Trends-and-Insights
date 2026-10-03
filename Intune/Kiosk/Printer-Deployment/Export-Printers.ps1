
#requires -Version 5.1

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "          Printer BRM Export Tool" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. Locate PrintBRM.exe
# ------------------------------------------------------------

$PrintBrm = Join-Path $env:windir "System32\spool\tools\PrintBrm.exe"

Write-Host "Checking for PrintBRM.exe..." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $PrintBrm)) {

    Write-Host ""
    Write-Host "ERROR: PrintBrm.exe was not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected location:" -ForegroundColor Yellow
    Write-Host $PrintBrm
    Write-Host ""

    exit 1
}

Write-Host "PrintBRM found:" -ForegroundColor Green
Write-Host $PrintBrm
Write-Host ""

# ------------------------------------------------------------
# 2. Check Print Spooler
# ------------------------------------------------------------

Write-Host "Checking Print Spooler service..." -ForegroundColor Yellow

try {

    $Spooler = Get-Service -Name Spooler -ErrorAction Stop

}
catch {

    Write-Host ""
    Write-Host "ERROR: Print Spooler service was not found." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

if ($Spooler.Status -ne 'Running') {

    Write-Host "Print Spooler is not running." -ForegroundColor Yellow
    Write-Host "Starting Print Spooler..." -ForegroundColor Yellow

    try {

        Start-Service -Name Spooler -ErrorAction Stop
        $Spooler.WaitForStatus(
            [System.ServiceProcess.ServiceControllerStatus]::Running,
            [TimeSpan]::FromSeconds(15)
        )

    }
    catch {

        Write-Host ""
        Write-Host "ERROR: Unable to start Print Spooler." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        exit 1
    }
}

Write-Host "Print Spooler is running." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# 3. Get installed printers
# ------------------------------------------------------------

Write-Host "Scanning installed printers..." -ForegroundColor Yellow

try {

    $printers = @(Get-Printer -ErrorAction Stop)

}
catch {

    Write-Host ""
    Write-Host "ERROR: Unable to retrieve printers." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

if ($printers.Count -eq 0) {

    Write-Host ""
    Write-Host "No printers found on this device." -ForegroundColor Red

    exit 1
}

# ------------------------------------------------------------
# 4. Display printers
# ------------------------------------------------------------

Write-Host ""
Write-Host "Detected printers:" -ForegroundColor Green
Write-Host ""

for ($i = 0; $i -lt $printers.Count; $i++) {

    $printer = $printers[$i]

    Write-Host ("[{0}] {1}" -f ($i + 1), $printer.Name) `
        -ForegroundColor White

    Write-Host ("     Driver : {0}" -f $printer.DriverName) `
        -ForegroundColor DarkGray

    Write-Host ("     Port   : {0}" -f $printer.PortName) `
        -ForegroundColor DarkGray

    try {

        $port = Get-PrinterPort `
            -Name $printer.PortName `
            -ErrorAction SilentlyContinue

        if ($port -and $port.PrinterHostAddress) {

            Write-Host ("     IP     : {0}" -f $port.PrinterHostAddress) `
                -ForegroundColor DarkGray
        }

    }
    catch {
        # Ignore port lookup errors
    }

    Write-Host ""
}

# ------------------------------------------------------------
# 5. Select printers
# ------------------------------------------------------------

$selection = Read-Host "Enter printer numbers you want to export (example: 1,2)"

if ([string]::IsNullOrWhiteSpace($selection)) {

    Write-Host ""
    Write-Host "No selection was made." -ForegroundColor Red

    exit 1
}

$numbers = $selection -split ',' |
    ForEach-Object {
        $_.Trim()
    } |
    Where-Object {
        $_ -match '^\d+$'
    } |
    ForEach-Object {
        [int]$_
    }

$selected = foreach ($number in $numbers) {

    if ($number -ge 1 -and $number -le $printers.Count) {

        $printers[$number - 1]

    }
    else {

        Write-Host `
            "Ignoring invalid printer number: $number" `
            -ForegroundColor DarkYellow
    }
}

$selected = @($selected)

if ($selected.Count -eq 0) {

    Write-Host ""
    Write-Host "No valid printers selected." -ForegroundColor Red

    exit 1
}

# ------------------------------------------------------------
# 6. Display selection
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "             Selected printers" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

foreach ($printer in $selected) {

    Write-Host " - $($printer.Name)" -ForegroundColor White
}

Write-Host ""

# ------------------------------------------------------------
# 7. Prepare export folder
# ------------------------------------------------------------

$ExportFolder = "C:\PrinterInventory"

$ExportFile = Join-Path `
    $ExportFolder `
    "PrinterExport.printerExport"

if (-not (Test-Path -LiteralPath $ExportFolder)) {

    Write-Host "Creating export folder..." -ForegroundColor Yellow

    New-Item `
        -Path $ExportFolder `
        -ItemType Directory `
        -Force |
        Out-Null
}

# ------------------------------------------------------------
# 8. Remove previous export
# ------------------------------------------------------------

if (Test-Path -LiteralPath $ExportFile) {

    Write-Host "Removing previous export..." -ForegroundColor Yellow

    Remove-Item `
        -LiteralPath $ExportFile `
        -Force
}

# ------------------------------------------------------------
# 9. Run PrintBRM
# ------------------------------------------------------------

Write-Host ""
Write-Host "Starting PrintBRM export..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Export file:" -ForegroundColor Cyan
Write-Host $ExportFile -ForegroundColor White
Write-Host ""

Write-Host "Running command:" -ForegroundColor DarkGray
Write-Host "$PrintBrm -b -f `"$ExportFile`"" -ForegroundColor DarkGray
Write-Host ""

# IMPORTANT:
# Call PrintBRM directly instead of Start-Process.
# This allows us to see PrintBRM output and avoids
# argument/quoting problems.

try {

    & $PrintBrm -b -f $ExportFile

    $PrintBrmExitCode = $LASTEXITCODE

}
catch {

    Write-Host ""
    Write-Host "ERROR: PrintBRM failed to start." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

# ------------------------------------------------------------
# 10. Check exit code
# ------------------------------------------------------------

Write-Host ""
Write-Host "PrintBRM exit code: $PrintBrmExitCode" `
    -ForegroundColor Cyan

if ($PrintBrmExitCode -ne 0) {

    Write-Host ""
    Write-Host "ERROR: PrintBRM export failed." `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "Exit code: $PrintBrmExitCode" `
        -ForegroundColor Red

    exit $PrintBrmExitCode
}

# ------------------------------------------------------------
# 11. Search for the export file
# ------------------------------------------------------------

Write-Host ""
Write-Host "Checking for exported file..." -ForegroundColor Yellow

if (Test-Path -LiteralPath $ExportFile) {

    $File = Get-Item -LiteralPath $ExportFile

}
else {

    # PrintBRM may have created the file in the current
    # working directory. Search for it as a fallback.

    $FileName = Split-Path -Path $ExportFile -Leaf

    $PossibleFiles = @(
        Get-ChildItem `
            -Path "C:\PrinterInventory" `
            -Filter $FileName `
            -File `
            -ErrorAction SilentlyContinue

        Get-ChildItem `
            -Path (Get-Location).Path `
            -Filter $FileName `
            -File `
            -ErrorAction SilentlyContinue
    ) | Sort-Object LastWriteTime -Descending

    if ($PossibleFiles.Count -gt 0) {

        $File = $PossibleFiles[0]

        Write-Host ""
        Write-Host "PrintBRM created the file here instead:" `
            -ForegroundColor Yellow

        Write-Host $File.FullName -ForegroundColor White

    }
    else {

        Write-Host ""
        Write-Host "ERROR: PrintBRM returned exit code 0," `
            -ForegroundColor Red

        Write-Host "but no .printerExport file could be found." `
            -ForegroundColor Red

        Write-Host ""
        Write-Host "This is the PrintBRM output location that was requested:" `
            -ForegroundColor Yellow

        Write-Host $ExportFile

        Write-Host ""
        Write-Host "Please run this command manually to verify PrintBRM:" `
            -ForegroundColor Yellow

        Write-Host ""
        Write-Host "`"$PrintBrm`" -b -f `"$ExportFile`"" `
            -ForegroundColor White

        Write-Host ""

        exit 1
    }
}

# ------------------------------------------------------------
# 12. Verify file size
# ------------------------------------------------------------

if ($File.Length -eq 0) {

    Write-Host ""
    Write-Host "ERROR: Export file exists but is empty." `
        -ForegroundColor Red

    exit 1
}

# ------------------------------------------------------------
# 13. Success
# ------------------------------------------------------------

Write-Host ""
Write-Host "==============================================" `
    -ForegroundColor Cyan

Write-Host "       Printer export completed" `
    -ForegroundColor Green

Write-Host "==============================================" `
    -ForegroundColor Cyan

Write-Host ""

Write-Host "Export file:" -ForegroundColor Yellow
Write-Host $File.FullName -ForegroundColor White

Write-Host ""
Write-Host "File size:" -ForegroundColor Yellow
Write-Host "$($File.Length) bytes" -ForegroundColor White

Write-Host ""
Write-Host "Selected printers:" -ForegroundColor Yellow

foreach ($printer in $selected) {

    Write-Host " - $($printer.Name)" `
        -ForegroundColor White
}

Write-Host ""
Write-Host "Export completed successfully." `
    -ForegroundColor Green

Write-Host ""
