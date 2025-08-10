@echo off
setlocal enabledelayedexpansion
title AI Control System - Windows Installer v3.0

:: Setup log variables
set "DEBUG_LOG=logs\install_debug.log"
set "ERROR_LOG=logs\install_errors.log"

:: Create logs directory
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1
del "%ERROR_LOG%" >nul 2>&1

:: Start logging
echo [%date% %time%] Starting AI Control System Installation > "%DEBUG_LOG%"
echo [%date% %time%] Starting AI Control System Installation > "%ERROR_LOG%"

echo ==================================================================================
echo                    AI CONTROL SYSTEM INSTALLER v3.0
echo ==================================================================================
echo.
echo This installer will set up both Server and Client components with:
echo   - Python virtual environments for isolation
echo   - All required dependencies
echo   - Enhanced error handling and logging
echo   - Multi-AI model support (Ollama, OpenAI, Anthropic, Google)
echo.
echo Installation will be logged to: %DEBUG_LOG%
echo.
pause

:: Change to project root directory
echo [%date% %time%] Changing to project root directory... >> "%DEBUG_LOG%"
cd /d "%~dp0.." 2>> "%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to change to project directory >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Working directory: %CD%
echo [%date% %time%] Working directory: %CD% >> "%DEBUG_LOG%"

:: ============================================================================
:: Phase 1: Check System Requirements
:: ============================================================================
echo.
echo [PHASE 1/6] Checking System Requirements...
echo ============================================================================

:: Check Python
echo [STEP] Checking Python installation...
echo [%date% %time%] Checking Python installation... >> "%DEBUG_LOG%"

python --version >nul 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Python not found in PATH.
    echo [ERROR] Python not found in PATH. >> "%ERROR_LOG%"
    echo.
    echo Python is required but not found!
    echo.
    echo Please install Python 3.8+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    goto :error_exit
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [SUCCESS] %PYTHON_VERSION% found
echo [%date% %time%] %PYTHON_VERSION% found >> "%DEBUG_LOG%"

:: Check pip
echo [STEP] Checking pip...
echo [%date% %time%] Checking pip... >> "%DEBUG_LOG%"

python -m pip --version >nul 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [WARNING] pip not found, attempting to install...
    echo [%date% %time%] pip not found, attempting to install... >> "%DEBUG_LOG%"
    
    python -m ensurepip --upgrade >"%DEBUG_LOG%" 2>"%ERROR_LOG%"
    if errorlevel 1 (
        echo [ERROR] Failed to install pip
        echo [ERROR] Failed to install pip >> "%ERROR_LOG%"
        goto :error_exit
    )
)

echo [SUCCESS] pip is available
echo [%date% %time%] pip is available >> "%DEBUG_LOG%"

:: ============================================================================
:: Phase 2: Clean Previous Installations
:: ============================================================================
echo.
echo [PHASE 2/6] Cleaning Previous Installations...
echo ============================================================================

echo [STEP] Removing old virtual environments...
echo [%date% %time%] Removing old virtual environments... >> "%DEBUG_LOG%"

if exist "venv_server" (
    echo [ACTION] Removing old server environment...
    rmdir /s /q "venv_server" 2>"%ERROR_LOG%"
    if exist "venv_server" (
        echo [WARNING] Could not fully remove old server environment
        echo [WARNING] Could not fully remove old server environment >> "%ERROR_LOG%"
    ) else (
        echo [SUCCESS] Old server environment removed
        echo [%date% %time%] Old server environment removed >> "%DEBUG_LOG%"
    )
)

if exist "venv_client" (
    echo [ACTION] Removing old client environment...
    rmdir /s /q "venv_client" 2>"%ERROR_LOG%"
    if exist "venv_client" (
        echo [WARNING] Could not fully remove old client environment
        echo [WARNING] Could not fully remove old client environment >> "%ERROR_LOG%"
    ) else (
        echo [SUCCESS] Old client environment removed
        echo [%date% %time%] Old client environment removed >> "%DEBUG_LOG%"
    )
)

:: ============================================================================
:: Phase 3: Setup Server Environment
:: ============================================================================
echo.
echo [PHASE 3/6] Setting Up Server Environment...
echo ============================================================================

echo [STEP] Creating server virtual environment...
echo [%date% %time%] Creating server virtual environment... >> "%DEBUG_LOG%"

python -m venv venv_server >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to create server virtual environment
    echo [ERROR] Failed to create server virtual environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Server virtual environment created
echo [%date% %time%] Server virtual environment created >> "%DEBUG_LOG%"

echo [STEP] Activating server environment and installing dependencies...
echo [%date% %time%] Activating server environment... >> "%DEBUG_LOG%"

call venv_server\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to activate server environment
    echo [ERROR] Failed to activate server environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [ACTION] Upgrading pip in server environment...
python -m pip install --upgrade pip --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"

echo [ACTION] Installing server dependencies...
echo [%date% %time%] Installing server dependencies... >> "%DEBUG_LOG%"

echo Installing core packages individually...
call :install_package fastapi
call :install_package uvicorn
call :install_package websockets
call :install_package requests
call :install_package aiofiles
call :install_package python-multipart

echo Installing optional packages...
call :install_optional_package ollama
call :install_optional_package pyautogui
call :install_optional_package pillow
call :install_optional_package open-interpreter
call :install_optional_package pytest

echo [SUCCESS] Server dependencies installation completed
echo [%date% %time%] Server dependencies installation completed >> "%DEBUG_LOG%"

call venv_server\Scripts\deactivate.bat 2>nul

:: ============================================================================
:: Phase 4: Setup Client Environment
:: ============================================================================
echo.
echo [PHASE 4/6] Setting Up Client Environment...
echo ============================================================================

echo [STEP] Creating client virtual environment...
echo [%date% %time%] Creating client virtual environment... >> "%DEBUG_LOG%"

python -m venv venv_client >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to create client virtual environment
    echo [ERROR] Failed to create client virtual environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Client virtual environment created
echo [%date% %time%] Client virtual environment created >> "%DEBUG_LOG%"

echo [STEP] Activating client environment and installing dependencies...
echo [%date% %time%] Activating client environment... >> "%DEBUG_LOG%"

call venv_client\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to activate client environment
    echo [ERROR] Failed to activate client environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [ACTION] Upgrading pip in client environment...
python -m pip install --upgrade pip --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"

echo [ACTION] Installing client dependencies...
echo [%date% %time%] Installing client dependencies... >> "%DEBUG_LOG%"

echo Installing essential client packages...
call :install_package websocket-client
call :install_package requests

echo Installing optional client packages...
call :install_optional_package pyautogui
call :install_optional_package pillow
call :install_optional_package keyboard
call :install_optional_package psutil
call :install_optional_package opencv-python
call :install_optional_package pytest

echo [SUCCESS] Client dependencies installation completed
echo [%date% %time%] Client dependencies installation completed >> "%DEBUG_LOG%"

call venv_client\Scripts\deactivate.bat 2>nul

:: ============================================================================
:: Phase 5: Create Configuration Files
:: ============================================================================
echo.
echo [PHASE 5/6] Creating Configuration Files...
echo ============================================================================

echo [STEP] Creating AI models configuration...
echo [%date% %time%] Creating AI models configuration... >> "%DEBUG_LOG%"

if not exist "ai_models_config.json" (
    (
        echo {
        echo   "default_provider": "ollama",
        echo   "providers": {
        echo     "ollama": {
        echo       "enabled": true,
        echo       "base_url": "http://localhost:11434",
        echo       "default_model": "qwen2.5-coder:7b",
        echo       "models": [
        echo         "qwen2.5-coder:7b",
        echo         "llama3.2:3b",
        echo         "mistral:7b",
        echo         "deepseek-coder:6.7b",
        echo         "phi3:mini"
        echo       ]
        echo     },
        echo     "openai": {
        echo       "enabled": false,
        echo       "api_key": "",
        echo       "default_model": "gpt-4",
        echo       "models": ["gpt-4", "gpt-3.5-turbo"]
        echo     },
        echo     "anthropic": {
        echo       "enabled": false,
        echo       "api_key": "",
        echo       "default_model": "claude-3-sonnet-20240229",
        echo       "models": ["claude-3-opus-20240229", "claude-3-sonnet-20240229"]
        echo     },
        echo     "google": {
        echo       "enabled": false,
        echo       "api_key": "",
        echo       "default_model": "gemini-pro",
        echo       "models": ["gemini-pro", "gemini-pro-vision"]
        echo     }
        echo   }
        echo }
    ) > "ai_models_config.json"
    
    echo [SUCCESS] AI models configuration created
    echo [%date% %time%] AI models configuration created >> "%DEBUG_LOG%"
) else (
    echo [INFO] AI models configuration already exists
    echo [%date% %time%] AI models configuration already exists >> "%DEBUG_LOG%"
)

echo [STEP] Creating example client configuration...
if not exist "client_config.json" (
    (
        echo {
        echo   "server_ip": "127.0.0.1",
        echo   "server_port": 8000,
        echo   "websocket_port": 8000,
        echo   "auto_reconnect": true,
        echo   "max_reconnect_attempts": 5,
        echo   "reconnect_delay": 3,
        echo   "screenshot_quality": 80,
        echo   "safety_mode": true,
        echo   "log_commands": true
        echo }
    ) > "client_config.json"
    
    echo [SUCCESS] Client configuration created
    echo [%date% %time%] Client configuration created >> "%DEBUG_LOG%"
) else (
    echo [INFO] Client configuration already exists
    echo [%date% %time%] Client configuration already exists >> "%DEBUG_LOG%"
)

:: ============================================================================
:: Phase 6: Verify Installation
:: ============================================================================
echo.
echo [PHASE 6/6] Verifying Installation...
echo ============================================================================

echo [STEP] Testing server environment...
echo [%date% %time%] Testing server environment... >> "%DEBUG_LOG%"

call venv_server\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
python -c "import fastapi, uvicorn, websockets; print('Server dependencies verified')" >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [WARNING] Server environment verification failed
    echo [WARNING] Server environment verification failed >> "%ERROR_LOG%"
) else (
    echo [SUCCESS] Server environment verified
)
call venv_server\Scripts\deactivate.bat 2>nul

echo [STEP] Testing client environment...
echo [%date% %time%] Testing client environment... >> "%DEBUG_LOG%"

call venv_client\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
python -c "import websocket, requests; print('Client dependencies verified')" >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [WARNING] Client environment verification failed
    echo [WARNING] Client environment verification failed >> "%ERROR_LOG%"
) else (
    echo [SUCCESS] Client environment verified
)
call venv_client\Scripts\deactivate.bat 2>nul

echo [STEP] Checking script files...
echo [%date% %time%] Checking script files... >> "%DEBUG_LOG%"

if exist "scripts\run_server.bat" (
    echo [SUCCESS] Server launcher found
) else (
    echo [WARNING] Server launcher missing
    echo [WARNING] Server launcher missing >> "%ERROR_LOG%"
)

if exist "scripts\run_client.bat" (
    echo [SUCCESS] Client launcher found
) else (
    echo [WARNING] Client launcher missing
    echo [WARNING] Client launcher missing >> "%ERROR_LOG%"
)

:: ============================================================================
:: Installation Complete
:: ============================================================================
echo.
echo ==================================================================================
echo                           INSTALLATION COMPLETED!
echo ==================================================================================
echo.
echo Server Environment: Ready (venv_server)
echo Client Environment: Ready (venv_client)
echo Configuration Files: Created
echo AI Models Support: Multi-provider ready
echo.
echo Configuration Files Created:
echo    - ai_models_config.json (AI provider settings)
echo    - client_config.json (client connection settings)
echo.
echo Quick Start:
echo    1. Start Server: scripts\run_server.bat
echo    2. Start Client: scripts\run_client.bat
echo    3. Configure AI models by editing ai_models_config.json
echo.
echo Supported AI Providers:
echo    - Ollama (Local models - default)
echo    - OpenAI (GPT-4, GPT-3.5)
echo    - Anthropic (Claude-3)
echo    - Google (Gemini)
echo.
echo Logs saved to:
echo    - Installation: %DEBUG_LOG%
echo    - Errors: %ERROR_LOG%
echo.
echo Important Notes:
echo    - For Ollama: Install from https://ollama.ai/ and pull models
echo    - For other providers: Add your API keys to ai_models_config.json
echo    - Run as Administrator for best compatibility
echo.
echo [%date% %time%] Installation completed successfully >> "%DEBUG_LOG%"

pause
exit /b 0

:: ============================================================================
:: Helper Functions
:: ============================================================================

:install_package
echo [INSTALL] %1...
python -m pip install %1 --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to install %1
    echo [ERROR] Failed to install %1 >> "%ERROR_LOG%"
    goto :error_exit
) else (
    echo [SUCCESS] Installed %1
)
goto :eof

:install_optional_package
echo [INSTALL] %1 (optional)...
python -m pip install %1 --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [INFO] Optional package %1 not installed (this is okay)
    echo [INFO] Optional package %1 not installed >> "%DEBUG_LOG%"
) else (
    echo [SUCCESS] Installed optional package %1
)
goto :eof

:: ============================================================================
:: Error Handler
:: ============================================================================
:error_exit
echo.
echo ==================================================================================
echo                              INSTALLATION FAILED
echo ==================================================================================
echo.
echo An error occurred during installation.
echo.
echo Check these log files for details:
echo    - Debug Log: %DEBUG_LOG%
echo    - Error Log: %ERROR_LOG%
echo.
echo Common Solutions:
echo    1. Run as Administrator
echo    2. Check Python installation and PATH
echo    3. Ensure internet connection for downloads
echo    4. Disable antivirus temporarily
echo    5. Check available disk space
echo.
echo If problems persist:
echo    - Check the GitHub repository for troubleshooting
echo    - Review the installation logs above
echo.
echo [%date% %time%] Installation failed >> "%ERROR_LOG%"

pause
exit /b 1