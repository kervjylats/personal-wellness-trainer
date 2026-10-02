@echo off
rem ============================================================================
rem serve.bat - on-demand static server for the built web app (port 9090)
rem
rem   serve.bat            start (no-op if already running)
rem   serve.bat stop       stop it - nothing lingers in the background
rem   serve.bat status     show state
rem
rem You do NOT need this for normal app use. Run the app directly with:
rem   flutter run -d windows        (native window, no server, no port)
rem   flutter run -d chrome         (browser + hot reload)
rem
rem This server only exists to open the RELEASE build in a browser or for
rem the test harness. Port 9090 because 8080 belongs to the LocalAI hub's
rem `big` slot (see C:\LocalAI\hub_server.py SLOT_PORTS).
rem ============================================================================
setlocal
set PORT=9090
set WEBDIR=%~dp0build\web

if /i "%~1"=="stop" goto :stop
if /i "%~1"=="status" goto :status

:start
if not exist "%WEBDIR%\index.html" (
    echo build\web not found. Run first: flutter build web
    exit /b 1
)
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /c:":%PORT%" ^| findstr /c:"LISTENING"') do (
    echo Already running: http://localhost:%PORT%  ^(pid %%p^)
    exit /b 0
)
powershell -NoProfile -Command "Start-Process python -ArgumentList '-m','http.server','%PORT%','--directory','%WEBDIR%' -WindowStyle Hidden"
ping -n 3 127.0.0.1 >nul
echo Serving %WEBDIR% at http://localhost:%PORT%
exit /b 0

:stop
set FOUND=0
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /c:":%PORT%" ^| findstr /c:"LISTENING"') do (
    taskkill /f /pid %%p >nul 2>&1
    echo Stopped pid %%p on port %PORT%.
    set FOUND=1
)
if "%FOUND%"=="0" echo Nothing listening on port %PORT%.
exit /b 0

:status
set FOUND=0
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /c:":%PORT%" ^| findstr /c:"LISTENING"') do (
    echo UP: http://localhost:%PORT%  ^(pid %%p^)
    set FOUND=1
)
if "%FOUND%"=="0" echo DOWN: nothing on port %PORT%
exit /b 0