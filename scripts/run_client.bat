@echo off
setlocal

set "DEBUG_LOG=logs\run_client_debug.log"
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control Client Launcher ---
echo Detailed debug output will be saved to %DEBUG_LOG%
echo.

(
    echo [INFO] Changing to project root directory...
    cd /d "%~dp0..\"

    echo [STEP] Checking for client virtual environment...
    if not exist "venv_client\Scripts\activate.bat" (
        echo [ERROR] Client virtual environment not found.
        echo Please run 'scripts\install.bat' first.
        goto :error_exit
    )
    echo [SUCCESS] Client venv found.

    echo [STEP] Activating environment...
    call venv_client\Scripts\activate.bat

) >> "%DEBUG_LOG%" 2>>&1

:MENU
cls
echo ================================================================================
echo                           CLIENT LAUNCH MENU
echo ================================================================================
echo.
echo   [1] Connect in Automatic Mode
echo   [2] Start Interactive Mode
echo   [3] Send a Single Command
echo.
echo   [0] Exit
echo.
echo ================================================================================
set /p choice="Select a mode [0-3]: "

if "%choice%"=="1" goto AUTO
if "%choice%"=="2" goto INTERACTIVE
if "%choice%"=="3" goto SINGLE
if "%choice%"=="0" goto :EOF

echo Invalid option.
pause
goto MENU

:AUTO
echo [ACTION] Starting client in Automatic Mode... >> "%DEBUG_LOG%"
python -m src.client.main auto >> "%DEBUG_LOG%" 2>>&1
pause
goto MENU

:INTERACTIVE
echo [ACTION] Starting client in Interactive Mode... >> "%DEBUG_LOG%"
python -m src.client.main interactive >> "%DEBUG_LOG%" 2>>&1
pause
goto MENU

:SINGLE
echo [ACTION] Starting client in Single Command Mode... >> "%DEBUG_LOG%"
set /p cmd_string="Enter the command to send: "
if "%cmd_string%"=="" (
    echo No command entered.
    pause
    goto MENU
)
echo [COMMAND] %cmd_string% >> "%DEBUG_LOG%"
python -m src.client.main command "%cmd_string%" >> "%DEBUG_LOG%" 2>>&1
pause
goto MENU

:error_exit
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo.
echo   An error occurred during script initialization.
echo   Please check the details in the log file: %DEBUG_LOG%
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1
