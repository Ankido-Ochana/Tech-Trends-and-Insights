#requires -Version 5.1

$ErrorActionPreference = 'Stop'

$ExportFileName = 'PrinterExport-2026.printerExport'

$WorkFolder = Join-Path $env:ProgramData 'Intune\PrinterDeployment'
$PackageExport = Join-Path $PSScriptRoot $ExportFileName
$LocalExport = Join-Path $WorkFolder $ExportFileName
$PrintBrm = Join-Path $env:windir 'System32\spool\tools\PrintBrm.exe'


# Create working directory
if (-not (Test-Path -LiteralPath $WorkFolder)) {
    New-Item -Path $WorkFolder -ItemType Directory -Force | Out-Null
}


# Verify PrintBRM
if (-not (Test-Path -LiteralPath $PrintBrm)) {
    Write-Error "PrintBRM was not found: $PrintBrm"
    exit 1
}


# Verify printer export
if (-not (Test-Path -LiteralPath $PackageExport)) {
    Write-Error "Printer export was not found: $PackageExport"
    exit 1
}


# Make sure the Print Spooler is running
$Spooler = Get-Service -Name Spooler -ErrorAction Stop

if ($Spooler.Status -ne 'Running') {
    Start-Service -Name Spooler -ErrorAction Stop
    $Spooler.WaitForStatus(
        [System.ServiceProcess.ServiceControllerStatus]::Running,
        [TimeSpan]::FromSeconds(30)
    )
}


# Copy the printer export locally
Copy-Item -LiteralPath $PackageExport -Destination $LocalExport -Force -ErrorAction Stop


# Restore the printer configuration
& $PrintBrm -r -f $LocalExport

$ExitCode = $LASTEXITCODE


# Check PrintBRM result
if ($ExitCode -ne 0) {
    Write-Error "PrintBRM failed with exit code $ExitCode."
    exit $ExitCode
}


Write-Output 'Printer deployment completed successfully.'

exit 0
Uninstall-Printers.ps1
