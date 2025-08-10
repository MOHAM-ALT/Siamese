@echo off
title AI Control Server
color 0A
cd /d "%~dp0..\."

echo ================================================================================
echo                           AI CONTROL SERVER LAUNCHER
echo ================================================================================
echo.

rem Check for virtual environment
if not exist "venv_server\Scripts\activate.bat" (
    echo [ERROR] Server virtual environment not found.
    echo Please run 'scripts\install.bat' first to set up the server.
    pause
    exit
)

echo Activating server environment...
call venv_server\Scripts\activate.bat

echo.
echo [INFO] Starting Ollama if not already running...
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if errorlevel 1 (
    echo    - Ollama not found, starting it in the background.
    start "Ollama" ollama serve
    timeout /t 5 >nul
) else (
    echo    - Ollama is already running.
)

echo.
echo Launching the FastAPI server...
echo To stop the server, press Ctrl+C in this window.
echo ================================================================================
echo.

python -m src.server.main

echo.
echo Server script has finished. Press any key to close this window...
pause
call venv_server\Scripts\deactivate.bat
