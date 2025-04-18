:: Check for Administrator privileges
@echo off
chcp 65001 > nul

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 This script requires Administrator privileges.
    echo 🚀 Restarting with elevated privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Check for required commands
echo Checking required commands...
setlocal
set "commands=wmic getmac ipconfig netsh whoami"

for %%C in (%commands%) do (
    where %%C >nul 2>&1
    if errorlevel 1 (
        echo [❌] Command "%%C" not found in the system.
        echo [💡] Please install or add it to your PATH.
        echo.

        if "%%C"=="wmic" (
            echo 🔧 "wmic" has been deprecated in recent Windows versions.
            echo ✅ Attempting to install RSAT tools via DISM...
            echo --------------------------------------------------

            dism /online /add-capability /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

            if %errorlevel%==0 (
                echo ✅ RSAT tools installed successfully.
            ) else (
                echo ❌ Failed to install RSAT tools.
                echo 🔍 Please check your Windows version or internet connection.
                echo 🛠️ You may also try manual installation via Settings > Optional Features.
                pause
                exit /b
            )
        )


        if "%%C"=="netsh" (
            echo 🔧 "netsh" is part of Windows by default.
            echo ✅ If missing, check Windows Features or repair system using:
            echo sfc /scannow
        )

        if "%%C"=="ipconfig" (
            echo 🔧 "ipconfig" is normally in System32.
            echo ✅ Check if PATH includes C:\Windows\System32
        )

        if "%%C"=="getmac" (
            echo 🔧 "getmac" is included with Windows.
            echo ✅ If missing, consider system repair or use PowerShell instead.
        )

        if "%%C"=="whoami" (
            echo 🔧 "whoami" is located in System32.
            echo ✅ Check PATH or try running in PowerShell.
        )

        echo.
        echo [⛔] Cannot proceed. Please install the required command first.
        pause
        exit /b
    )
)
endlocal
echo ✅ All required commands are available.
echo.

rem Get MAC Address and remove unwanted characters
for /f "tokens=2 delims=:" %%A in ('getmac /v /fo list ^| findstr "Physical Address"') do (
    set "mac=%%A"
)

rem Get username
for /f "delims=" %%u in ('whoami') do set "username=%%u"
for /f "tokens=2 delims=\" %%a in ("%username%") do set "username=%%a"

rem Set filename as username.txt and specify path to Desktop
set "filename=%USERPROFILE%\Desktop\%username%.txt"

rem Start collecting system and monitor information
echo Collecting system and monitor information... > "%filename%"
echo ============================== >> "%filename%"

rem CPU Information
echo CPU Information: >> "%filename%"
for /f "tokens=1,2,3 delims=," %%A in ('wmic cpu get Name^,NumberOfCores^,NumberOfLogicalProcessors /format:csv') do (
    echo CPU: %%A %%B %%C >> "%filename%"
)
echo ============================== >> "%filename%"

rem Motherboard Information
echo Motherboard Information: >> "%filename%"
for /f "tokens=1,2 delims=," %%A in ('wmic baseboard get Manufacturer^,Product /format:csv') do (
    echo Manufacturer: %%A Product: %%B >> "%filename%"
)
echo ============================== >> "%filename%"

rem RAM Information
echo RAM Information: >> "%filename%"
for /f "tokens=1,2,3 delims=," %%A in ('wmic memorychip get Capacity^,Speed^,Manufacturer /format:csv') do (
    echo Capacity: %%A Speed: %%B Manufacturer: %%C >> "%filename%"
)
echo ============================== >> "%filename%"

rem Storage Information
echo Storage Information: >> "%filename%"
for /f "tokens=1,2 delims=," %%A in ('wmic diskdrive get Model^,Size /format:csv') do (
    echo Model: %%A Size: %%B >> "%filename%"
)
echo ============================== >> "%filename%"

rem GPU Information
echo GPU Information: >> "%filename%"
for /f "tokens=1,2,3 delims=," %%A in ('wmic path win32_videocontroller get Name^,AdapterRAM^,DriverVersion /format:csv') do (
    echo GPU Name: %%A RAM: %%B Driver: %%C >> "%filename%"
)
echo ============================== >> "%filename%"

rem Monitor Information
echo Monitor Information: >> "%filename%"
for /f "tokens=1,2,3 delims=," %%A in ('wmic desktopmonitor get Name^,MonitorType^,ScreenHeight^,ScreenWidth /format:csv') do (
    echo Monitor: %%A Type: %%B Resolution: %%C x %%D >> "%filename%"
)
echo ============================== >> "%filename%"

rem MAC Address
echo MAC Address: >> "%filename%"
getmac /v /fo list >> "%filename%"
echo ============================== >> "%filename%"

rem Operating System Information
echo Operating System: >> "%filename%"
for /f "tokens=1,2 delims=," %%A in ('wmic os get Caption^,Version /format:csv') do (
    echo OS: %%A Version: %%B >> "%filename%"
)
echo ============================== >> "%filename%"

rem Network Connection (IP)
echo Network IP Address: >> "%filename%"
for /f "tokens=*" %%A in ('ipconfig ^| findstr "IPv4"') do (
    echo %%A >> "%filename%"
)
echo ============================== >> "%filename%"

rem Wifi Information
echo Wifi Details: >> "%filename%"
netsh wlan show interfaces >> "%filename%"
echo ============================== >> "%filename%"

rem User Information (Logged in user)
echo Logged in User: >> "%filename%"
whoami >> "%filename%"
echo ============================== >> "%filename%"

echo Information saved to %filename%
echo Press any key to exit...
pause
