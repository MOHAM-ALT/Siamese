@echo off
setlocal

:: Set a dedicated log file for debugging this script
set "DEBUG_LOG=logs\install_debug.log"

:: Create logs directory if it doesn't exist
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1

echo --- AI Control System Windows Installer ---
echo This script will install all dependencies for the Server and Client.
echo Detailed progress will be saved to %DEBUG_LOG%
echo.
pause

(
    echo [INFO] Changing to project root directory...
    cd /d "%~dp0..\"

    echo [STEP] Checking for Python...
    python --version
    if errorlevel 1 (
        echo [ERROR] Python not found in PATH.
        goto :error_exit
    )
    echo [SUCCESS] Python found.

    :: --- Server Installation ---
    echo.
    echo [STEP] Setting up Server...
    echo [ACTION] Creating server virtual environment...
    if not exist "venv_server" (
        python -m venv venv_server
        if errorlevel 1 (
            echo [ERROR] Failed to create server virtual environment.
            goto :error_exit
        )
    )
    echo [SUCCESS] Server venv exists.

    echo [ACTION] Installing server dependencies...
    call venv_server\Scripts\activate.bat
    echo --- Upgrading pip... ---
    python -m pip install --upgrade pip
    echo --- Installing server packages... ---
    python -m pip install -r src\server\requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install server packages.
        call venv_server\Scripts\deactivate.bat
        goto :error_exit
    )
    call venv_server\Scripts\deactivate.bat
    echo [SUCCESS] Server dependencies installed.

    :: --- Client Installation ---
    echo.
    echo [STEP] Setting up Client...
    echo [ACTION] Creating client virtual environment...
    if not exist "venv_client" (
        python -m venv venv_client
        if errorlevel 1 (
            echo [ERROR] Failed to create client virtual environment.
            goto :error_exit
        )
    )
    echo [SUCCESS] Client venv exists.

    echo [ACTION] Installing client dependencies...
    call venv_client\Scripts\activate.bat
    echo --- Upgrading pip... ---
    python -m pip install --upgrade pip
    echo --- Installing client packages... ---
    python -m pip install -r src\client\requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install client packages.
        call venv_client\Scripts\deactivate.bat
        goto :error_exit
    )
    call venv_client\Scripts\deactivate.bat
    echo [SUCCESS] Client dependencies installed.

) >> "%DEBUG_LOG%" 2>>&1

echo.
echo =================================================================
echo.
echo   Installation completed successfully!
echo   You can now run the server and client using the run scripts.
echo.
echo =================================================================
pause
exit /b 0

:error_exit
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo.
echo   An error occurred during installation.
echo   Please check the details in the log file: %DEBUG_LOG%
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause
exit /b 1
