@echo off
setlocal

:: Set a dedicated log file for debugging this script
set "DEBUG_LOG=logs\install_debug.log"

:: Create logs directory if it doesn't exist
if not exist "logs" mkdir "logs"

:: Clean up old log
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control System Windows Installer ---
echo This script will install all dependencies for the Server and Client.
echo Detailed progress will be saved to %DEBUG_LOG%
echo.
pause

:: Function-like structure using goto
call :log_and_run "cd /d "%~dp0..\.""
call :log_and_run "echo [STEP] Checking for Python..."

python --version >nul 2>&1
if errorlevel 1 (
    call :log_and_run "echo [ERROR] Python not found in PATH."
    goto :error
)
call :log_and_run "echo [SUCCESS] Python found."

:: --- Server Installation ---
call :log_and_run "echo."
call :log_and_run "echo [STEP] Setting up Server..."
call :log_and_run "echo [ACTION] Creating server virtual environment..."
if not exist "venv_server" (
    call :log_and_run "python -m venv venv_server"
    if errorlevel 1 (
        call :log_and_run "echo [ERROR] Failed to create server virtual environment."
        goto :error
    )
)
call :log_and_run "echo [SUCCESS] Server venv exists."

call :log_and_run "echo [ACTION] Installing server dependencies..."
call :log_and_run "call venv_server\Scripts\activate.bat"
call :log_and_run "python -m pip install --upgrade pip"
call :log_and_run "python -m pip install -r src\server\requirements.txt"
if errorlevel 1 (
    call :log_and_run "echo [ERROR] Failed to install server packages."
    call venv_server\Scripts\deactivate.bat
    goto :error
)
call :log_and_run "call venv_server\Scripts\deactivate.bat"
call :log_and_run "echo [SUCCESS] Server dependencies installed."

:: --- Client Installation ---
call :log_and_run "echo."
call :log_and_run "echo [STEP] Setting up Client..."
call :log_and_run "echo [ACTION] Creating client virtual environment..."
if not exist "venv_client" (
    call :log_and_run "python -m venv venv_client"
    if errorlevel 1 (
        call :log_and_run "echo [ERROR] Failed to create client virtual environment."
        goto :error
    )
)
call :log_and_run "echo [SUCCESS] Client venv exists."

call :log_and_run "echo [ACTION] Installing client dependencies..."
call :log_and_run "call venv_client\Scripts\activate.bat"
call :log_and_run "python -m pip install --upgrade pip"
call :log_and_run "python -m pip install -r src\client\requirements.txt"
if errorlevel 1 (
    call :log_and_run "echo [ERROR] Failed to install client packages."
    call venv_client\Scripts\deactivate.bat
    goto :error
)
call :log_and_run "call venv_client\Scripts\deactivate.bat"
call :log_and_run "echo [SUCCESS] Client dependencies installed."

goto :success

:: --- Helper Functions ---
:log_and_run
    echo %~1 >> "%DEBUG_LOG%"
    %~1
    if errorlevel 1 (
        echo [FATAL] Command failed: %~1 >> "%DEBUG_LOG%"
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
echo   An error occurred during installation.
echo   Please check the details in the log file: %DEBUG_LOG%
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1

:success
echo.
echo =================================================================
echo.
echo   Installation completed successfully!
echo   You can now run the server and client using the run scripts.
echo.
echo =================================================================
pause
exit /b 0
