Get-WmiObject Win32_Service | Where-Object {
    $_.StartName -eq "LocalSystem" -and $_.PathName -match '\s' -and $_.PathName -notmatch '"'
} | Select-Object Name, StartName, PathName