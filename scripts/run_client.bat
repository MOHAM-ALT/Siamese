@echo off
title AI Control Client
color 0B
cd /d "%~dp0..\."

echo ================================================================================
echo                           AI CONTROL CLIENT LAUNCHER
echo ================================================================================
echo.

rem Check for virtual environment
if not exist "venv_client\Scripts\activate.bat" (
    echo [ERROR] Client virtual environment not found.
    echo Please run 'scripts\install.bat' first to set up the client.
    pause
    exit
)

echo Activating client environment...
call venv_client\Scripts\activate.bat

:MENU
cls
echo ================================================================================
echo                           CLIENT LAUNCH MENU
echo ================================================================================
echo.
echo   [1] Connect in Automatic Mode (waits for server commands)
echo   [2] Start Interactive Mode (send commands from here)
echo   [3] Send a Single Command
echo.
echo   [0] Exit
echo.
echo ================================================================================
set /p choice="Select a mode [0-3]: "

if "%choice%"=="1" goto AUTO
if "%choice%"=="2" goto INTERACTIVE
if "%choice%"=="3" goto SINGLE
if "%choice%"=="0" goto QUIT

echo Invalid option.
pause
goto MENU

:AUTO
echo.
echo Starting client in Automatic Mode...
python -m src.client.main auto
pause
goto MENU

:INTERACTIVE
echo.
echo Starting client in Interactive Mode...
python -m src.client.main interactive
pause
goto MENU

:SINGLE
echo.
set /p cmd_string="Enter the command to send: "
if "%cmd_string%"=="" (
    echo No command entered.
    pause
    goto MENU
)
python -m src.client.main command "%cmd_string%"
pause
goto MENU

:QUIT
call venv_client\Scripts\deactivate.bat
exit
