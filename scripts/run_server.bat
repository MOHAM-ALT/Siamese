@echo off
setlocal

:: Set a dedicated log file for debugging this script
set "DEBUG_LOG=logs\run_server_debug.log"

:: Create logs directory if it doesn't exist
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control Server Launcher ---
echo Detailed debug output will be saved to %DEBUG_LOG%
echo.

:: Function-like structure for logging
call :log_and_run "echo [STEP] Changing to project root directory..."
call :log_and_run "cd /d "%~dp0..\.""

call :log_and_run "echo [STEP] Checking for server virtual environment..."
if not exist "venv_server\Scripts\activate.bat" (
    call :log_and_run "echo [ERROR] Server virtual environment not found."
    call :log_and_run "echo Please run 'scripts\install.bat' first."
    goto :error
)
call :log_and_run "echo [SUCCESS] Server venv found."

call :log_and_run "echo [STEP] Activating environment..."
call :log_and_run "call venv_server\Scripts\activate.bat"

call :log_and_run "echo [STEP] Checking for Ollama service..."
call :log_and_run "tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul"
if errorlevel 1 (
    call :log_and_run "echo [INFO] Ollama not found, starting it now..."
    call :log_and_run "start "Ollama" ollama serve"
    call :log_and_run "timeout /t 5 >nul"
) else (
    call :log_and_run "echo [INFO] Ollama is already running."
)

call :log_and_run "echo [STEP] Launching Python server script..."
echo =================================================================
echo.
call :log_and_run "python -m src.server.main"
echo.
echo =================================================================

goto :success

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
echo   An error occurred while trying to run the server.
echo   Please check the details in the log file: %DEBUG_LOG%
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1

:success
echo.
echo Server script has finished. Press any key to close this window...
pause
exit /b 0
