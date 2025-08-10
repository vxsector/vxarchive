# Privilege Escalation Scanner Script

# Function to display vulnerabilities
function ShowVuln($source, $name, $path, $extra) {
    Write-Host "`n[$source] $name" -ForegroundColor Yellow
    Write-Host "  Path:  $path"
    if ($extra) { Write-Host "  Extra: $extra" }
}

Write-Host "[+] Starting Privilege Escalation Scanner..." -ForegroundColor Cyan

# === SERVICES ===
Write-Host "`n[+] Checking Services (LocalSystem) with unquoted spaces..." -ForegroundColor Green
$services = Get-WmiObject Win32_Service |
    Where-Object { $_.StartName -eq 'LocalSystem' -and $_.PathName -match '\s' -and $_.PathName -notmatch '^"' }
foreach ($svc in $services) {
    ShowVuln 'Service' $svc.Name $svc.PathName 'Runs as SYSTEM'
}

# === STARTUP REGISTRY (HKLM & HKCU) ===
Write-Host "`n[+] Checking Startup Registry entries with spaces..." -ForegroundColor Green
$regPaths = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)
$registryEntries = @()
foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        Get-ItemProperty -Path $regPath | ForEach-Object {
            $obj = $_
            foreach ($prop in $obj.PSObject.Properties) {
                $val = $obj.$($prop.Name)
                if ($val -is [string] -and $val -match '\s') {
                    ShowVuln 'Registry' $prop.Name $val $regPath
                    $registryEntries += [PSCustomObject]@{ Type='Registry'; Name=$prop.Name; Path=$val }
                }
            }
        }
    }
}

# === SCHEDULED TASKS ===
Write-Host "`n[+] Checking Scheduled Tasks with spaces..." -ForegroundColor Green
$taskEntries = @()
Get-ScheduledTask | ForEach-Object {
    $task = $_
    foreach ($act in $task.Actions) {
        $exe = $act.Execute
        if ($exe -match '\s') {
            ShowVuln 'ScheduledTask' $task.TaskName $exe $task.Principal.UserId
            $taskEntries += [PSCustomObject]@{ Type='ScheduledTask'; Name=$task.TaskName; Path=$exe }
        }
    }
}

# === DRIVERS ===
Write-Host "`n[+] Checking System Drivers (LocalSystem) with unquoted spaces..." -ForegroundColor Green
$driverEntries = Get-WmiObject Win32_SystemDriver |
    Where-Object { $_.StartName -eq 'LocalSystem' -and $_.PathName -match '\s' -and $_.PathName -notmatch '^"' }
foreach ($drv in $driverEntries) {
    ShowVuln 'Driver' $drv.Name $drv.PathName 'System Driver'
}

# === FINAL SUMMARY ===
Write-Host "`n[?] FINAL SUMMARY:" -ForegroundColor Cyan

# Calculate max name lengths for alignment
$maxSvcLen    = ($services        | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
$maxRegLen    = ($registryEntries | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
$maxTaskLen   = ($taskEntries     | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
$maxDriverLen = ($driverEntries   | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum

# Cap ScheduledTask padding to avoid overflow
$padTaskLen = if ($maxTaskLen -gt 20) { 20 } else { $maxTaskLen }

Write-Host "[?] Services that start as SYSTEM with unquoted spaces:" -ForegroundColor Magenta
foreach ($svc in $services) {
    $n = $svc.Name.PadRight($maxSvcLen)
    Write-Host ("  {0} -> {1}" -f $n, $svc.PathName) -ForegroundColor Cyan
}

Write-Host ""  # blank line for spacing
Write-Host "[?] Other SYSTEM-level vectors with spaces:" -ForegroundColor Magenta

if ($registryEntries) {
    Write-Host "  [Registry]" -ForegroundColor Gray
    foreach ($r in $registryEntries) {
        $n = $r.Name.PadRight($maxRegLen)
        Write-Host ("    {0} -> {1}" -f $n, $r.Path) -ForegroundColor DarkYellow
    }
    Write-Host ""  # blank line
}

if ($taskEntries) {
    Write-Host "  [ScheduledTask]" -ForegroundColor Gray
    foreach ($t in $taskEntries) {
        $n = $t.Name.PadRight($padTaskLen)
        Write-Host ("    {0} -> {1}" -f $n, $t.Path) -ForegroundColor DarkGreen
    }
    Write-Host ""  # blank line
}

if ($driverEntries) {
    Write-Host "  [Driver]" -ForegroundColor Gray
    foreach ($d in $driverEntries) {
        $n = $d.Name.PadRight($maxDriverLen)
        Write-Host ("    {0} -> {1}" -f $n, $d.PathName) -ForegroundColor DarkRed
    }
    Write-Host ""  # blank line
}

Write-Host "[!] Done. Review results carefully!" -ForegroundColor Cyan
