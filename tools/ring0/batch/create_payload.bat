@echo off
:: Ask for the payload name
set /p PayloadName=Enter the name for the payload (e.g., MyPayload): 

:: Check if the PayloadName is not empty
if "%PayloadName%"=="" (
    echo You must provide a name for the payload. Exiting...
    exit /b
)

:: Ask the user for the path to drop the payload
set /p PayloadPath=Enter the path where the payload should be dropped (e.g., C:\Users\Public\): 

:: Check if the path is not empty
if "%PayloadPath%"=="" (
    echo You must provide a valid path. Exiting...
    exit /b
)

:: Make sure the directory exists, and if not, create it
if not exist "%PayloadPath%" (
    echo The path does not exist. Creating it now...
    mkdir "%PayloadPath%"
    if errorlevel 1 (
        echo Failed to create directory. Exiting...
        exit /b
    )
)

:: Queue the copy action by setting the full path to where it will go
set PayloadFullPath=%PayloadPath%\%PayloadName%.exe

:: Prepare to simulate byte-by-byte copying
echo Preparing to copy "%~dp0cmd.exe" to "%PayloadFullPath%"...
timeout /t 1 /nobreak > nul

:: Loop to copy the file byte by byte, simulating the process
setlocal enabledelayedexpansion
for /f "tokens=1 delims=" %%A in ('findstr /n "^" "%~dp0cmd.exe"') do (
    set "line=%%A"
    set /a byteCount+=1
    echo Copied Byte !byteCount!: !line!
    timeout /t 0.1 /nobreak > nul
)

:: Copy the file after the byte-by-byte simulation
copy "%~dp0cmd.exe" "%PayloadFullPath%"

:: Confirmation
echo Payload %PayloadName%.exe has been copied to %PayloadPath%\%PayloadName%.exe.

:: Pause to keep the window open
pause
