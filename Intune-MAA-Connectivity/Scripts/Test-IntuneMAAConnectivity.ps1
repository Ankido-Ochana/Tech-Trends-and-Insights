<#
.SYNOPSIS
    Tests DNS, TCP 443, and HTTPS connectivity to Microsoft Intune MAA endpoints.

.DESCRIPTION
    Tests network connectivity from the local Windows device to Microsoft
    Azure Attestation (MAA) endpoints used by Microsoft Intune.

    The script validates:
      - DNS resolution
      - TCP port 443 connectivity
      - HTTPS communication

    The script does not modify firewall, proxy, registry, or Intune settings.

    Results are displayed in the console and exported to a timestamped CSV
    file on the user's Desktop.

.PARAMETER Region
    Selects the MAA endpoint region.

    Valid values:
      Europe
      NorthAmerica
      AsiaPacific

.PARAMETER TimeoutSeconds
    Maximum time allowed for HTTPS connectivity testing.

.EXAMPLE
    .\Test-IntuneMAAConnectivity.ps1

    Tests the European MAA endpoints.

.EXAMPLE
    .\Test-IntuneMAAConnectivity.ps1 -Region NorthAmerica

    Tests the North America MAA endpoints.

.NOTES
    Project: Tech Trends and Insights
    Repository: Tech-Trends-and-Insights
    Requires: Windows PowerShell 5.1 or PowerShell 7+

    Always verify the current Microsoft Intune network endpoint
    documentation before making firewall, proxy, or TLS inspection changes.

.LINK
    https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-endpoints
#>

[CmdletBinding()]
param(
    [ValidateSet("Europe", "NorthAmerica", "AsiaPacific")]
    [string]$Region = "Europe",

    [ValidateRange(5, 120)]
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = "SilentlyContinue"

# Microsoft Intune MAA endpoints
$Endpoints = @{
    Europe = @(
        "intunemaape7.neu.attest.azure.net"
        "intunemaape8.neu.attest.azure.net"
        "intunemaape9.neu.attest.azure.net"
        "intunemaape10.weu.attest.azure.net"
        "intunemaape11.weu.attest.azure.net"
        "intunemaape12.weu.attest.azure.net"
    )

    NorthAmerica = @(
        "intunemaape1.eus.attest.azure.net"
        "intunemaape2.eus2.attest.azure.net"
        "intunemaape3.cus.attest.azure.net"
        "intunemaape4.wus.attest.azure.net"
        "intunemaape5.scus.attest.azure.net"
        "intunemaape6.ncus.attest.azure.net"
    )

    AsiaPacific = @(
        "intunemaape13.jpe.attest.azure.net"
        "intunemaape17.jpe.attest.azure.net"
        "intunemaape18.jpe.attest.azure.net"
        "intunemaape19.jpe.attest.azure.net"
    )
}

$SelectedEndpoints = $Endpoints[$Region]

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Microsoft Intune MAA Connectivity Test" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Region : $Region"
Write-Host "Device : $env:COMPUTERNAME"
Write-Host ""

$Results = foreach ($Endpoint in $SelectedEndpoints) {

    Write-Host "Testing: $Endpoint" -ForegroundColor Cyan

    # -----------------------------
    # DNS
    # -----------------------------

    $DnsStatus = "Failed"
    $DnsIP = $null

    try {
        $DnsRecords = Resolve-DnsName `
            -Name $Endpoint `
            -Type A `
            -ErrorAction Stop

        $DnsIP = (
            $DnsRecords |
            Where-Object { $_.Type -eq "A" } |
            Select-Object -First 1 -ExpandProperty IPAddress
        )

        if ($DnsIP) {
            $DnsStatus = "Success"
        }
    }
    catch {
        $DnsStatus = "Failed"
    }

    # -----------------------------
    # TCP 443
    # -----------------------------

    $Tcp443 = "Skipped"

    if ($DnsStatus -eq "Success") {
        try {
            $TcpResult = Test-NetConnection `
                -ComputerName $Endpoint `
                -Port 443 `
                -WarningAction SilentlyContinue `
                -InformationLevel Quiet

            $Tcp443 = [bool]$TcpResult
        }
        catch {
            $Tcp443 = $false
        }
    }

    # -----------------------------
    # HTTPS
    # -----------------------------

    $HttpsStatus = "Skipped"

    if ($DnsStatus -eq "Success" -and $Tcp443 -eq $true) {

        try {
            $HttpsStatus = curl.exe `
                -I `
                -s `
                -o NUL `
                -w "%{http_code}" `
                --connect-timeout $TimeoutSeconds `
                --max-time $TimeoutSeconds `
                "https://$Endpoint"

            if ([string]::IsNullOrWhiteSpace($HttpsStatus)) {
                $HttpsStatus = "000"
            }
        }
        catch {
            $HttpsStatus = "000"
        }
    }

    # -----------------------------
    # Result
    # -----------------------------

    $HttpsReachable = (
        $HttpsStatus -match '^\d{3}$' -and
        $HttpsStatus -ne "000"
    )

    $Reachable = (
        $DnsStatus -eq "Success" -and
        $Tcp443 -eq $true -and
        $HttpsReachable
    )

    [PSCustomObject]@{
        Endpoint        = $Endpoint
        DNS             = $DnsStatus
        DNS_IP          = $DnsIP
        TCP_443         = $Tcp443
        HTTPS           = $HttpsStatus
        HTTPS_Reachable = $Reachable
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Results" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$Results | Format-Table -AutoSize

# -----------------------------
# Summary
# -----------------------------

$Total = $Results.Count

$Reachable = (
    $Results |
    Where-Object { $_.HTTPS_Reachable -eq $true }
).Count

$Failed = $Total - $Reachable

Write-Host ""

if ($Failed -eq 0) {
    Write-Host "Summary: $Reachable of $Total endpoints reachable." -ForegroundColor Green
}
else {
    Write-Host "Summary: $Reachable of $Total endpoints reachable." -ForegroundColor Yellow
    Write-Host "Failed or unreachable endpoints: $Failed" -ForegroundColor Yellow
}

# -----------------------------
# Export CSV
# -----------------------------

$DesktopPath = [Environment]::GetFolderPath("Desktop")

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$CsvPath = Join-Path `
    $DesktopPath `
    "Intune-MAA-Connectivity-$Region-$Timestamp.csv"

$Results |
    Export-Csv `
        -Path $CsvPath `
        -NoTypeInformation `
        -Encoding UTF8

Write-Host ""
Write-Host "CSV report:" -ForegroundColor Cyan
Write-Host $CsvPath -ForegroundColor Yellow

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " MAA NETWORK TEST COMPLETE" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

# Exit code:
# 0 = all endpoints reachable
# 2 = one or more endpoints failed
if ($Failed -eq 0) {
    exit 0
}
else {
    exit 2
}
