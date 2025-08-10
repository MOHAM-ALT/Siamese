@echo off
title AI Control System - Windows Installer
color 0E
chcp 65001 >nul 2>&1
cd /d "%~dp0..\."

echo ================================================================================
echo               AI CONTROL SYSTEM - WINDOWS INSTALLER
echo ================================================================================
echo This script will set up the Python virtual environments for the Server and Client.
echo.
echo IMPORTANT:
echo - This script must be run from the project's root directory.
echo - Ensure you have Python 3.8+ installed and added to your PATH.
echo - For the server, you must install Ollama separately from https://ollama.ai/
echo.
pause
cls

:MENU
echo ================================================================================
echo                           INSTALLATION MENU
echo ================================================================================
echo.
echo   [1] Install Server Dependencies
echo   [2] Install Client Dependencies
echo   [3] Install BOTH Server and Client Dependencies
echo.
echo   [0] Exit
echo.
echo ================================================================================
set /p choice="Select an option [0-3]: "

if "%choice%"=="1" (
    call :INSTALL_SERVER
    goto END
)
if "%choice%"=="2" (
    call :INSTALL_CLIENT
    goto END
)
if "%choice%"=="3" (
    call :INSTALL_SERVER
    call :INSTALL_CLIENT
    goto BOTH_DONE
)
if "%choice%"=="0" exit

echo Invalid option.
pause
goto MENU

:INSTALL_SERVER
echo.
echo ================================================================================
echo                        INSTALLING SERVER DEPENDENCIES
echo ================================================================================
echo.
echo [1/3] Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install it and add it to your PATH.
    pause
    exit /b 1
)
echo [OK] Python found.

echo.
echo [2/3] Creating virtual environment for the server...
if not exist "venv_server" (
    python -m venv venv_server
    if errorlevel 1 (
        echo [ERROR] Could not create server virtual environment.
        pause
        exit /b 1
    )
    echo [OK] Server virtual environment created at .\venv_server
) else (
    echo [OK] Server virtual environment already exists.
)

echo.
echo [3/3] Installing packages from src/server/requirements.txt...
call venv_server\Scripts\activate.bat
python -m pip install --upgrade pip >nul
python -m pip install -r src\server\requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install server packages. Check requirements and connection.
    pause
    exit /b 1
)
call venv_server\Scripts\deactivate.bat
echo [OK] Server packages installed successfully.
echo [REMINDER] Don't forget to install Ollama and pull your desired models!
echo.
exit /b 0

:INSTALL_CLIENT
echo.
echo ================================================================================
echo                        INSTALLING CLIENT DEPENDENCIES
echo ================================================================================
echo.
echo [1/3] Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Please install it and add it to your PATH.
    pause
    exit /b 1
)
echo [OK] Python found.

echo.
echo [2/3] Creating virtual environment for the client...
if not exist "venv_client" (
    python -m venv venv_client
    if errorlevel 1 (
        echo [ERROR] Could not create client virtual environment.
        pause
        exit /b 1
    )
    echo [OK] Client virtual environment created at .\venv_client
) else (
    echo [OK] Client virtual environment already exists.
)

echo.
echo [3/3] Installing packages from src/client/requirements.txt...
call venv_client\Scripts\activate.bat
python -m pip install --upgrade pip >nul
python -m pip install -r src\client\requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install client packages. Check requirements and connection.
    pause
    exit /b 1
)
call venv_client\Scripts\deactivate.bat
echo [OK] Client packages installed successfully.
echo.
exit /b 0

:BOTH_DONE
echo.
echo ================================================================================
echo                  BOTH SERVER AND CLIENT ARE SET UP!
echo ================================================================================
echo.
echo To start the server, run: scripts\run_server.bat
echo To start the client, run: scripts\run_client.bat
echo.
pause

:END
