@echo off
chcp 65001 > nul

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 This script requires Administrator privileges.
    echo 🚀 Restarting with elevated privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Check commands except wmic (replaced with PowerShell)
echo Checking required commands...
setlocal
set "commands=getmac ipconfig netsh whoami"
for %%C in (%commands%) do (
    where %%C >nul 2>&1
    if errorlevel 1 (
        echo ❌ Command "%%C" not found.
        pause
        exit /b
    )
)
endlocal
echo ✅ All required commands are available.
echo.

:: Get username
for /f "delims=" %%u in ('whoami') do set "username=%%u"
for /f "tokens=2 delims=\" %%a in ("%username%") do set "username=%%a"

:: Set output file
set "filename=%USERPROFILE%\Desktop\%username%.txt"
echo Collecting system information... > "%filename%"
echo ============================== >> "%filename%"

:: CPU Info via PowerShell
echo CPU Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_Processor | ForEach-Object { 'Name: ' + $_.Name + ', Cores: ' + $_.NumberOfCores + ', Logical: ' + $_.NumberOfLogicalProcessors }" >> "%filename%"
echo ============================== >> "%filename%"

:: Motherboard Info via PowerShell
echo Motherboard Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_BaseBoard | ForEach-Object { 'Manufacturer: ' + $_.Manufacturer + ', Product: ' + $_.Product }" >> "%filename%"
echo ============================== >> "%filename%"

:: RAM Info via PowerShell
echo RAM Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_PhysicalMemory | ForEach-Object { 'Capacity: ' + [math]::Round($_.Capacity / 1GB) + 'GB, Speed: ' + $_.Speed + ', Manufacturer: ' + $_.Manufacturer }" >> "%filename%"
echo ============================== >> "%filename%"

:: Disk Info via PowerShell
echo Storage Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_DiskDrive | ForEach-Object { 'Model: ' + $_.Model + ', Size: ' + [math]::Round($_.Size / 1GB) + 'GB' }" >> "%filename%"
echo ============================== >> "%filename%"

:: GPU Info via PowerShell
echo GPU Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_VideoController | ForEach-Object { 'GPU: ' + $_.Name + ', Driver Version: ' + $_.DriverVersion }" >> "%filename%"
echo ============================== >> "%filename%"

:: Monitor Info via PowerShell
echo Monitor Information: >> "%filename%"
powershell -Command "Get-CimInstance Win32_DesktopMonitor | ForEach-Object { 'Monitor: ' + $_.Name + ', Resolution: ' + $_.ScreenWidth + 'x' + $_.ScreenHeight }" >> "%filename%"
echo ============================== >> "%filename%"

:: MAC Address
echo MAC Address: >> "%filename%"
getmac /v /fo list >> "%filename%"
echo ============================== >> "%filename%"

:: OS Info via PowerShell
echo Operating System: >> "%filename%"
powershell -Command "Get-CimInstance Win32_OperatingSystem | ForEach-Object { 'OS: ' + $_.Caption + ', Version: ' + $_.Version }" >> "%filename%"
echo ============================== >> "%filename%"

:: IP Address
echo Network IP Address: >> "%filename%"
for /f "tokens=*" %%A in ('ipconfig ^| findstr "IPv4"') do (
    echo %%A >> "%filename%"
)
echo ============================== >> "%filename%"

:: Wifi Info
echo Wifi Details: >> "%filename%"
netsh wlan show interfaces >> "%filename%"
echo ============================== >> "%filename%"

:: User
echo Logged in User: >> "%filename%"
whoami >> "%filename%"
echo ============================== >> "%filename%"

echo 🔍 Information saved to %filename%
pause
