# Universal Privesc Toolkit Launcher Script

# Main loop
while ($true) {
    Write-Host "`nWhich exploit script do you want?" -ForegroundColor Cyan
    Write-Host "[1] Vulnerability Finder (ALL) -> vuln2.ps1"
    Write-Host "[2] Scheduled Path Modifier -> manpath.ps1"
    Write-Host "[3] Startup Task Modifier -> manstart.ps1"
    Write-Host "[4] Vulnerability Finder (DEPRECATED) -> vulnfinder.ps1"

    # Prompt for choice
    $choice = Read-Host "Enter choice [1-4]"
    switch ($choice) {
        '1' {
            Write-Host "Running Vulnerability Finder (ALL)..." -ForegroundColor Cyan
            & "$PSScriptRoot\vuln2.ps1"
        }
        '2' {
            Write-Host "Running Scheduled Path Modifier..." -ForegroundColor Cyan
            & "$PSScriptRoot\manpath.ps1"
        }
        '3' {
            Write-Host "Running Startup Task Modifier..." -ForegroundColor Cyan
            & "$PSScriptRoot\manstart.ps1"
        }
        '4' {
            Write-Host "Running Vulnerability Finder (DEPRECATED)..." -ForegroundColor Cyan
            & "$PSScriptRoot\vulnfinder.ps1"
        }
        default {
            Write-Host "Invalid choice." -ForegroundColor Red
        }
    }

    Write-Host "`n[!] Execution complete." -ForegroundColor Cyan

    # Prompt to run again
    $again = Read-Host "Run a new one? (Y/n)"
    if ($again -match '^[Nn]') {
        break
    }
}

Write-Host "Exiting launcher. Goodbye!" -ForegroundColor Cyan
