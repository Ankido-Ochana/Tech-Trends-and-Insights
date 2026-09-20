<#
.SYNOPSIS
    Checks the health of the Windows domain trust relationship.

.DESCRIPTION
    Collects basic domain and secure channel information from the local
    Windows computer and reports whether the computer's secure channel
    with the Active Directory domain is healthy.

    This script is diagnostic only. It does not modify the computer,
    repair the secure channel, or change any registry settings.

.NOTES
    Project: Tech Trends and Insights
    Repository: Windows-Domain-Trust
    Requires: Windows PowerShell 5.1 or PowerShell 7+
    Requires: Domain-joined Windows device for full results

.EXAMPLE
    .\Get-DomainTrustStatus.ps1

.EXAMPLE
    .\Get-DomainTrustStatus.ps1 -Detailed
#>

[CmdletBinding()]
param(
    [switch]$Detailed
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Windows Domain Trust Status" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Get computer information
$ComputerName = $env:COMPUTERNAME

try {
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $Domain = $ComputerSystem.Domain
    $PartOfDomain = $ComputerSystem.PartOfDomain
}
catch {
    Write-Host "Unable to retrieve computer/domain information." -ForegroundColor Red
    exit 1
}

Write-Host "Computer Name : $ComputerName"
Write-Host "Domain        : $Domain"
Write-Host "Domain Joined : $PartOfDomain"
Write-Host ""

# Stop if the computer is not domain joined
if (-not $PartOfDomain) {
    Write-Host "STATUS: Not Domain Joined" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The computer is not joined to an Active Directory domain."
    exit 0
}

# Test the secure channel
try {
    $SecureChannel = Test-ComputerSecureChannel -ErrorAction Stop
}
catch {
    Write-Host "Unable to test the domain secure channel." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Secure Channel: " -NoNewline

if ($SecureChannel) {
    Write-Host "Healthy" -ForegroundColor Green
    $Status = "Healthy"
}
else {
    Write-Host "Failed" -ForegroundColor Red
    $Status = "Failed"
}

# Detailed information
if ($Detailed) {
    Write-Host ""
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray
    Write-Host " Detailed Information" -ForegroundColor Cyan
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray

    try {
        $DomainRole = $ComputerSystem.DomainRole

        $DomainRoleName = switch ($DomainRole) {
            0 { "Standalone Workstation" }
            1 { "Member Workstation" }
            2 { "Standalone Server" }
            3 { "Member Server" }
            4 { "Backup Domain Controller" }
            5 { "Primary Domain Controller" }
            default { "Unknown" }
        }

        Write-Host "Domain Role   : $DomainRoleName"
    }
    catch {
        Write-Host "Domain Role   : Unable to determine"
    }

    try {
        $OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

        Write-Host "OS            : $($OperatingSystem.Caption)"
        Write-Host "OS Version    : $($OperatingSystem.Version)"
    }
    catch {
        Write-Host "OS Information: Unable to determine"
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan

if ($Status -eq "Healthy") {
    Write-Host "Result: Domain trust appears healthy." -ForegroundColor Green
}
else {
    Write-Host "Result: Secure Channel requires investigation." -ForegroundColor Red
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Return a useful exit code for automation
if ($Status -eq "Healthy") {
    exit 0
}
else {
    exit 2
}
