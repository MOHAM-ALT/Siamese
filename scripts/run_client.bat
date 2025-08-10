@echo off
setlocal

:: Set a dedicated log file for debugging this script
set "DEBUG_LOG=logs\run_client_debug.log"

:: Create logs directory if it doesn't exist
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control Client Launcher ---
echo Detailed debug output will be saved to %DEBUG_LOG%
echo.

:: Function-like structure for logging
call :log_and_run "echo [STEP] Changing to project root directory..."
call :log_and_run "cd /d "%~dp0..\.""

call :log_and_run "echo [STEP] Checking for client virtual environment..."
if not exist "venv_client\Scripts\activate.bat" (
    call :log_and_run "echo [ERROR] Client virtual environment not found."
    call :log_and_run "echo Please run 'scripts\install.bat' first."
    goto :error
)
call :log_and_run "echo [SUCCESS] Client venv found."

call :log_and_run "echo [STEP] Activating environment..."
call :log_and_run "call venv_client\Scripts\activate.bat"

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
if "%choice%"=="0" goto :success

echo Invalid option.
pause
goto MENU

:AUTO
call :log_and_run "echo [ACTION] Starting client in Automatic Mode..."
call :log_and_run "python -m src.client.main auto"
pause
goto MENU

:INTERACTIVE
call :log_and_run "echo [ACTION] Starting client in Interactive Mode..."
call :log_and_run "python -m src.client.main interactive"
pause
goto MENU

:SINGLE
call :log_and_run "echo [ACTION] Starting client in Single Command Mode..."
set /p cmd_string="Enter the command to send: "
if "%cmd_string%"=="" (
    echo No command entered.
    pause
    goto MENU
)
call :log_and_run "python -m src.client.main command "%cmd_string%""
pause
goto MENU

:: --- Helper Functions ---
:log_and_run
    echo [%time%] %~1 >> "%DEBUG_LOG%"
    %~1
    if errorlevel 1 (
        echo [%time%] [FATAL] Command failed with error code %errorlevel%: %~1 >> "%DEBUG_LOG%"
        echo [FATAL] A command failed to execute. Check %DEBUG_LOG% for details.
        pause
        exit /b 1
    )
    goto :eof

:: --- Exit Points ---
:error
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo.
echo   An error occurred while trying to run the client.
echo   Please check the details in the log file: %DEBUG_LOG%
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1

:success
echo.
echo Client script has finished. Press any key to close this window...
pause
exit /b 0
