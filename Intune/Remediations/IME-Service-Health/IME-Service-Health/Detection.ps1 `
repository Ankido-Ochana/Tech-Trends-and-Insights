$service = Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue

if (-not $service) { exit 1 }
if ($service.Status -ne "Running") { exit 1 }

exit 0
