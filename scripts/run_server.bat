@echo off
setlocal

set "DEBUG_LOG=logs\run_server_debug.log"
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control Server Launcher ---
echo Detailed debug output will be saved to %DEBUG_LOG%
echo.

(
    echo [INFO] Changing to project root directory...
    cd /d "%~dp0..\"

    echo [STEP] Checking for server virtual environment...
    if not exist "venv_server\Scripts\activate.bat" (
        echo [ERROR] Server virtual environment not found.
        echo Please run 'scripts\install.bat' first.
        goto :error_exit
    )
    echo [SUCCESS] Server venv found.

    echo [STEP] Activating environment...
    call venv_server\Scripts\activate.bat

    echo [STEP] Checking for Ollama service...
    tasklist /FI "IMAGENAME eq ollama.exe" | find /I "ollama.exe" >nul
    if errorlevel 1 (
        echo [INFO] Ollama not found, starting it now...
        start "Ollama" ollama serve
        timeout /t 5 >nul
    ) else (
        echo [INFO] Ollama is already running.
    )

    echo [STEP] Launching Python server script...
    echo =================================================================
    python -m src.server.main
    echo =================================================================

) >> "%DEBUG_LOG%" 2>>&1

:error_exit
if exist "%DEBUG_LOG%" (
    type "%DEBUG_LOG%"
    echo.
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo An error may have occurred. Please check the output above and
    echo the details in the log file: %DEBUG_LOG%
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
)

echo.
echo Server script has finished. Press any key to close this window...
pause
exit /b 0
