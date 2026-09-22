Detection – IME Service Health


$service = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue

if (-not $service) { exit 1 }
if ($service.Status -ne "Running") { exit 1 }

exit 0
  
Remediation – Restart IME Service


Restart-Service IntuneManagementExtension -Force -ErrorAction SilentlyContinue
  
Detection – Log Cleanup (Always Run)


exit 1
  
Remediation – Log Cleanup


$path = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"

if (-not (Test-Path $path)) { exit 0 }

Get-ChildItem $path -File -ErrorAction SilentlyContinue |
Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } |
Remove-Item -Force -ErrorAction SilentlyContinue

exit 0
  
Detection – Win32 Stall


$log = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"

if (-not (Test-Path $log)) { exit 0 }

$lastWrite = (Get-Item $log).LastWriteTime

if ($lastWrite -lt (Get-Date).AddMinutes(-30)) {
    exit 1
}

exit 0
  
Remediation – Restart IME (Win32 Stall)


Restart-Service IntuneManagementExtension -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 15
exit 0
  
 Full IME reset should only be used in targeted scenarios. Removing policy cache may trigger a full re-sync and impact deployments.
Detection – Full IME Reset


exit 1
  
Remediation – Full IME Reset (Safe)


$base = "C:\ProgramData\Microsoft\IntuneManagementExtension"

Stop-Service IntuneManagementExtension -Force -ErrorAction SilentlyContinue

Remove-Item "$base\Logs\*" -Recurse -Force -ErrorAction SilentlyContinue

# Optional deep reset:
# Remove-Item "$base\Policies\*" -Recurse -Force -ErrorAction SilentlyContinue

Start-Service IntuneManagementExtension

exit 0
