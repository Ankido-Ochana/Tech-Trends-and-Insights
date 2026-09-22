$endpoints = @(
    "intunemaape7.neu.attest.azure.net",
    "intunemaape8.neu.attest.azure.net",
    "intunemaape9.neu.attest.azure.net",
    "intunemaape10.weu.attest.azure.net",
    "intunemaape11.weu.attest.azure.net",
    "intunemaape12.weu.attest.azure.net"
)

$results = foreach ($endpoint in $endpoints) {

    Write-Host "`nTesting $endpoint" -ForegroundColor Cyan

    $dnsIP = $null
    $dnsStatus = "Failed"

    try {
        $dns = Resolve-DnsName `
            -Name $endpoint `
            -Type A `
            -ErrorAction Stop

        $dnsIP = (
            $dns |
            Where-Object { $_.Type -eq "A" } |
            Select-Object -First 1 -ExpandProperty IPAddress
        )

        if ($dnsIP) {
            $dnsStatus = "Success"
        }
    }
    catch {
        $dnsStatus = "Failed"
    }

    if ($dnsStatus -eq "Success") {

        try {
            $tcpResult = Test-NetConnection `
                -ComputerName $endpoint `
                -Port 443 `
                -WarningAction SilentlyContinue `
                -ErrorAction Stop

            $tcpSucceeded = $tcpResult.TcpTestSucceeded
        }
        catch {
            $tcpSucceeded = $false
        }

        try {
            $httpsStatus = curl.exe `
                -I `
                -s `
                -o NUL `
                -w "%{http_code}" `
                --connect-timeout 10 `
                --max-time 20 `
                "https://$endpoint"

            if ([string]::IsNullOrWhiteSpace($httpsStatus)) {
                $httpsStatus = "000"
            }
        }
        catch {
            $httpsStatus = "000"
        }

    }
    else {
        $tcpSucceeded = "Skipped"
        $httpsStatus  = "Skipped"
    }

    [PSCustomObject]@{
        Endpoint = $endpoint
        DNS      = $dnsStatus
        DNS_IP   = $dnsIP
        TCP_443  = $tcpSucceeded
        HTTPS    = $httpsStatus
    }
}

$results | Format-Table -AutoSize

$passCount = (
    $results |
    Where-Object {
        $_.DNS -eq "Success" -and
        $_.TCP_443 -eq $true -and
        $_.HTTPS -match '^\d{3}$'
    }
).Count

$totalCount = $results.Count
$summaryColor = if ($passCount -eq $totalCount) { "Green" } else { "Yellow" }

Write-Host "`nSummary: $passCount of $totalCount endpoints reachable" -ForegroundColor $summaryColor

$desktopPath = [Environment]::GetFolderPath("Desktop")
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = Join-Path $desktopPath "MAA-Connectivity-$timestamp.csv"

$results | Export-Csv `
    -Path $csvPath `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "MAA NETWORK TEST COMPLETE" -ForegroundColor Green
Write-Host "CSV exported to:" -ForegroundColor Green
Write-Host $csvPath -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
