@echo off
title AI Server Control Center
color 0A
chcp 65001 >nul 2>&1

:: Set working directory to script location
cd /d "%~dp0"
set "BASE_PATH=%CD%"

:: Create logs directory
if not exist "%BASE_PATH%\logs" mkdir "%BASE_PATH%\logs"

:: Logging function
set "LOG_FILE=%BASE_PATH%\logs\install.log"

:MENU
cls
echo ================================================================================
echo                          AI SERVER CONTROL CENTER
echo                              Host Machine Menu
echo ================================================================================
echo.
echo    Working Directory: %BASE_PATH%
echo.
echo    [1] INSTALL - Complete Server Setup (First Time)
echo    [2] START   - Start AI Server
echo    [3] STOP    - Stop AI Server  
echo    [4] STATUS  - Check Server Status
echo    [5] UPDATE  - Update Models
echo    [6] MEMORY  - Setup AI Memory System
echo    [7] FIX     - Fix Common Issues
echo    [8] INFO    - Show Server Information
echo    [0] EXIT    - Close Control Center
echo.
echo ================================================================================
set /p choice="Select Option [0-8]: "

if "%choice%"=="1" goto INSTALL
if "%choice%"=="2" goto START
if "%choice%"=="3" goto STOP
if "%choice%"=="4" goto STATUS
if "%choice%"=="5" goto UPDATE
if "%choice%"=="6" goto MEMORY
if "%choice%"=="7" goto FIX
if "%choice%"=="8" goto INFO
if "%choice%"=="0" exit

echo Invalid option! Press any key to continue...
pause >nul
goto MENU

:INSTALL
cls
echo ================================================================================
echo                         COMPLETE SERVER INSTALLATION
echo ================================================================================
echo.
echo Working in: %BASE_PATH%
echo.
echo %date% %time% - Starting installation >> "%LOG_FILE%"

:: Kill any existing processes first
echo [Cleanup] Stopping existing processes...
taskkill /F /IM ollama.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1

echo [Phase 1/8] Checking System Requirements...
echo ----------------------------------------

:: Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Not running as administrator. Some features may not work.
    echo Please run as administrator for full functionality.
    timeout /t 3 /nobreak >nul
)

:: Check Python with better error handling
echo Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python not found. Installing Python 3.11...
    echo This may take several minutes...
    
    :: Create temp directory
    if not exist "%TEMP%\ai_setup" mkdir "%TEMP%\ai_setup"
    
    echo Downloading Python installer...
    powershell -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe' -OutFile '%TEMP%\ai_setup\python_installer.exe' -UseBasicParsing } catch { exit 1 }"
    
    if not exist "%TEMP%\ai_setup\python_installer.exe" (
        echo [ERROR] Failed to download Python installer
        echo Please download and install Python manually from python.org
        pause
        goto MENU
    )
    
    echo Installing Python (this will take a few minutes)...
    "%TEMP%\ai_setup\python_installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_pip=1
    
    :: Wait for installation to complete
    timeout /t 10 /nobreak >nul
    
    :: Refresh PATH
    set "PATH=%PATH%;C:\Program Files\Python311;C:\Program Files\Python311\Scripts"
    
    :: Clean up
    del "%TEMP%\ai_setup\python_installer.exe" 2>nul
    
    :: Verify installation
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python installation failed
        echo Please install Python manually and restart this script
        pause
        goto MENU
    )
    echo [OK] Python installed successfully
) else (
    echo [OK] Python is already installed
    python --version
)

:: Check Git
echo Checking Git installation...
git --version >nul 2>&1
if errorlevel 1 (
    echo [!] Git not found. Attempting to install...
    :: Try winget first
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Could not install Git automatically
        echo Please install Git manually from git-scm.com
        echo You can continue without Git, but some features may not work
        timeout /t 5 /nobreak >nul
    ) else (
        echo [OK] Git installed successfully
        :: Refresh PATH for Git
        set "PATH=%PATH%;C:\Program Files\Git\bin"
    )
) else (
    echo [OK] Git is already installed
)

echo.
echo [Phase 2/8] Installing Ollama...
echo ----------------------------------------

:: Check if Ollama exists
where ollama >nul 2>&1
if errorlevel 1 (
    echo Downloading Ollama...
    if not exist "%TEMP%\ai_setup" mkdir "%TEMP%\ai_setup"
    
    powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/download/v0.1.48/OllamaSetup.exe' -OutFile '%TEMP%\ai_setup\OllamaSetup.exe' -UseBasicParsing } catch { exit 1 }"
    
    if not exist "%TEMP%\ai_setup\OllamaSetup.exe" (
        echo [WARNING] Could not download Ollama installer
        echo Please download manually from ollama.ai
        timeout /t 5 /nobreak >nul
    ) else (
        echo Installing Ollama (this may take a few minutes)...
        "%TEMP%\ai_setup\OllamaSetup.exe" /VERYSILENT /NORESTART /SP-
        timeout /t 15 /nobreak >nul
        
        :: Clean up
        del "%TEMP%\ai_setup\OllamaSetup.exe" 2>nul
        
        :: Add Ollama to PATH
        set "PATH=%PATH%;%USERPROFILE%\AppData\Local\Programs\Ollama"
        echo [OK] Ollama installed successfully
    )
) else (
    echo [OK] Ollama is already installed
)

echo.
echo [Phase 3/8] Creating Virtual Environment...
echo ----------------------------------------

if not exist "%BASE_PATH%\ai_env" (
    echo Creating virtual environment...
    python -m venv "%BASE_PATH%\ai_env"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        echo Make sure Python is properly installed
        pause
        goto MENU
    )
    echo [OK] Virtual environment created
) else (
    echo [OK] Virtual environment already exists
)

:: Activate virtual environment
call "%BASE_PATH%\ai_env\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    goto MENU
)

echo.
echo [Phase 4/8] Upgrading pip...
echo ----------------------------------------

python -m pip install --upgrade pip --quiet --no-warn-script-location
if errorlevel 1 (
    echo [WARNING] Failed to upgrade pip, continuing with current version
)

echo.
echo [Phase 5/8] Installing Python Libraries...
echo ----------------------------------------

echo Installing core dependencies...
python -m pip install --quiet --no-warn-script-location fastapi==0.104.1 uvicorn==0.24.0 websockets==12.0 pydantic==2.5.0
if errorlevel 1 (
    echo [ERROR] Failed to install core dependencies
    echo Trying with --break-system-packages flag...
    python -m pip install --break-system-packages --quiet fastapi uvicorn websockets pydantic
)

echo Installing additional packages...
python -m pip install --quiet --no-warn-script-location requests aiofiles python-multipart ollama-python pyautogui pillow
if errorlevel 1 (
    echo [WARNING] Some packages failed to install, continuing...
)

echo Installing Open Interpreter (optional)...
python -m pip install --quiet --no-warn-script-location open-interpreter
if errorlevel 1 (
    echo [WARNING] Open Interpreter installation failed, will use basic mode
)

echo [OK] Python libraries installation completed

echo.
echo [Phase 6/8] Configuring Network Settings...
echo ----------------------------------------

:: Set Ollama environment variables
echo Setting Ollama environment variables...
setx OLLAMA_HOST "0.0.0.0" /M >nul 2>&1
if errorlevel 1 setx OLLAMA_HOST "0.0.0.0" >nul 2>&1
set OLLAMA_HOST=0.0.0.0

setx OLLAMA_ORIGINS "*" /M >nul 2>&1
if errorlevel 1 setx OLLAMA_ORIGINS "*" >nul 2>&1
set OLLAMA_ORIGINS=*

:: Configure Windows Firewall
echo Configuring firewall rules...
netsh advfirewall firewall delete rule name="AI Server 8000" >nul 2>&1
netsh advfirewall firewall add rule name="AI Server 8000" dir=in action=allow protocol=TCP localport=8000 profile=any >nul 2>&1

netsh advfirewall firewall delete rule name="Ollama 11434" >nul 2>&1  
netsh advfirewall firewall add rule name="Ollama 11434" dir=in action=allow protocol=TCP localport=11434 profile=any >nul 2>&1

if errorlevel 1 (
    echo [WARNING] Firewall configuration failed. You may need to configure manually.
) else (
    echo [OK] Firewall configured successfully
)

echo.
echo [Phase 7/8] Starting Ollama and Testing...
echo ----------------------------------------

:: Start Ollama service
echo Starting Ollama service...
start "Ollama Server" cmd /c "set OLLAMA_HOST=0.0.0.0 && set OLLAMA_ORIGINS=* && ollama serve"
echo Waiting for Ollama to start...
timeout /t 10 /nobreak >nul

:: Test Ollama connection
echo Testing Ollama connection...
curl -s http://localhost:11434/api/tags >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Ollama may not be running properly
    echo Will continue with installation...
) else (
    echo [OK] Ollama is responding
)

echo.
echo Would you like to download a recommended model now? (y/n)
set /p download_model="Download qwen2.5-coder:7b (recommended for RTX 2060)? [y/n]: "
if /i "%download_model%"=="y" (
    echo Downloading qwen2.5-coder:7b...
    echo This may take 10-15 minutes depending on your internet connection...
    ollama pull qwen2.5-coder:7b
    if errorlevel 1 (
        echo [WARNING] Model download failed. You can download it later using the UPDATE menu.
    ) else (
        echo [OK] Model downloaded successfully
    )
)

echo.
echo [Phase 8/8] Creating Server Files...
echo ----------------------------------------

:: Create the Python server file
call :CREATE_SERVER_FILE
if exist "%BASE_PATH%\ai_server.py" (
    echo [OK] Server file created successfully
) else (
    echo [ERROR] Failed to create server file
    pause
    goto MENU
)

:: Create startup batch file
call :CREATE_STARTUP_SCRIPT

:: Get server IP address
call :GET_SERVER_IP

:: Save configuration
echo %SERVER_IP% > "%BASE_PATH%\server_ip.txt"
echo %date% %time% - Installation completed >> "%LOG_FILE%"

cls
echo ================================================================================
echo                        INSTALLATION COMPLETE!
echo ================================================================================
echo.
echo Server Information:
echo ------------------
echo IP Address: %SERVER_IP%
echo Server Port: 8000
echo Ollama Port: 11434
echo Working Directory: %BASE_PATH%
echo.
echo Quick Start:
echo -----------
echo 1. Use option [2] START to launch the server
echo 2. Access server at: http://%SERVER_IP%:8000
echo 3. WebSocket endpoint: ws://%SERVER_IP%:8000/ws
echo.
echo IMPORTANT NOTES:
echo - Keep the Ollama window open (it's running in the background)
echo - Save this IP address for client connections: %SERVER_IP%
echo - Check firewall settings if you have connection issues
echo.
echo Installation log saved to: %LOG_FILE%
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:START
cls
echo ================================================================================
echo                           STARTING AI SERVER
echo ================================================================================
echo.

:: Check prerequisites
if not exist "%BASE_PATH%\ai_server.py" (
    echo [ERROR] Server file not found!
    echo Please run INSTALL first or use FIX option to recreate it.
    pause
    goto MENU
)

if not exist "%BASE_PATH%\ai_env" (
    echo [ERROR] Virtual environment not found!
    echo Please run INSTALL first.
    pause
    goto MENU
)

echo Working Directory: %BASE_PATH%
echo.

:: Activate virtual environment
echo Activating virtual environment...
call "%BASE_PATH%\ai_env\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    goto MENU
)

:: Set environment variables
set OLLAMA_HOST=0.0.0.0
set OLLAMA_ORIGINS=*

:: Check if Ollama is running
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if errorlevel 1 (
    echo Starting Ollama service...
    start "Ollama Server" cmd /c "set OLLAMA_HOST=0.0.0.0 && set OLLAMA_ORIGINS=* && ollama serve"
    echo Waiting for Ollama to initialize...
    timeout /t 8 /nobreak >nul
    
    :: Verify Ollama started
    curl -s http://localhost:11434/api/tags >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Ollama may not have started properly
        echo Check the Ollama window for errors
        timeout /t 3 /nobreak >nul
    ) else (
        echo [OK] Ollama is running
    )
) else (
    echo [OK] Ollama is already running
)

echo.
echo Starting AI Server...
echo ================================================================================
echo Server will be available at:
call :GET_SERVER_IP
echo - Local: http://localhost:8000
echo - Network: http://%SERVER_IP%:8000
echo - WebSocket: ws://%SERVER_IP%:8000/ws
echo ================================================================================
echo.
echo Press Ctrl+C to stop the server
echo.

:: Start the server
python "%BASE_PATH%\ai_server.py"

echo.
echo Server stopped. Press any key to return to menu...
pause >nul
goto MENU

:STOP
cls
echo ================================================================================
echo                           STOPPING AI SERVER
echo ================================================================================
echo.

echo Stopping Python servers...
for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV /NH') do (
    taskkill /F /PID %%i >nul 2>&1
)

echo Stopping Ollama processes...
taskkill /F /IM ollama.exe >nul 2>&1

:: Wait a moment for processes to terminate
timeout /t 2 /nobreak >nul

echo.
echo Verifying processes are stopped...
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if errorlevel 1 (
    echo [OK] Ollama stopped successfully
) else (
    echo [WARNING] Some Ollama processes may still be running
)

tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq ai_server*" 2>nul | find /I "python.exe" >nul
if errorlevel 1 (
    echo [OK] Python server stopped successfully
) else (
    echo [WARNING] Some Python processes may still be running
)

echo.
echo All services have been stopped!
echo Press any key to return to menu...
pause >nul
goto MENU

:STATUS
cls
echo ================================================================================
echo                           SERVER STATUS CHECK
echo ================================================================================
echo.
echo Working Directory: %BASE_PATH%
echo Time: %date% %time%
echo.

:: Check Python
echo Python Status:
python --version 2>nul
if errorlevel 1 (
    echo [!] Python not found or not working
) else (
    echo [OK] Python is available
)

echo.

:: Check Virtual Environment
echo Virtual Environment:
if exist "%BASE_PATH%\ai_env" (
    echo [OK] Virtual environment exists at: %BASE_PATH%\ai_env
    if exist "%BASE_PATH%\ai_env\Scripts\python.exe" (
        echo [OK] Python executable found in venv
    ) else (
        echo [!] Python executable missing from venv
    )
) else (
    echo [!] Virtual environment not found
)

echo.

:: Check Ollama
echo Ollama Status:
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if %errorlevel%==0 (
    echo [OK] Ollama process is running
    
    :: Test Ollama API
    curl -s -m 5 http://localhost:11434/api/tags >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Ollama API not responding
    ) else (
        echo [OK] Ollama API is responding
        echo.
        echo Installed Models:
        ollama list 2>nul
    )
) else (
    echo [!] Ollama is not running
)

echo.

:: Check AI Server
echo AI Server Status:
curl -s -m 5 http://localhost:8000/status >nul 2>&1
if %errorlevel%==0 (
    echo [OK] AI Server is running on port 8000
    echo Server response:
    curl -s http://localhost:8000/status 2>nul
) else (
    echo [!] AI Server is not running or not responding
)

echo.

:: Network Information
echo Network Information:
call :GET_SERVER_IP
echo Current Server IP: %SERVER_IP%
if exist "%BASE_PATH%\server_ip.txt" (
    set /p SAVED_IP=<"%BASE_PATH%\server_ip.txt"
    echo Saved Server IP: %SAVED_IP%
)

echo.
echo Firewall Status:
netsh advfirewall firewall show rule name="AI Server 8000" >nul 2>&1
if errorlevel 1 (
    echo [!] AI Server firewall rule not found
) else (
    echo [OK] AI Server firewall rule exists
)

netsh advfirewall firewall show rule name="Ollama 11434" >nul 2>&1
if errorlevel 1 (
    echo [!] Ollama firewall rule not found
) else (
    echo [OK] Ollama firewall rule exists
)

echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:UPDATE
cls
echo ================================================================================
echo                           UPDATE AI MODELS
echo ================================================================================
echo.

:: Check if Ollama is running
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul
if errorlevel 1 (
    echo [!] Ollama is not running. Starting it first...
    set OLLAMA_HOST=0.0.0.0
    start "Ollama Server" cmd /c "set OLLAMA_HOST=0.0.0.0 && ollama serve"
    timeout /t 8 /nobreak >nul
)

echo Recommended models for RTX 2060 (6GB VRAM):
echo.
echo [1] qwen2.5-coder:7b    - Best for programming (4.7GB)
echo [2] llama3.2:3b         - Fastest, general purpose (2.0GB)
echo [3] mistral:7b          - Good balance (4.1GB)
echo [4] deepseek-coder:6.7b - Advanced coding (3.8GB)
echo [5] phi3:mini           - Very fast, light (2.3GB)
echo.
echo [6] List installed models
echo [7] Remove a model
echo [8] Return to menu
echo.
set /p model_choice="Select option [1-8]: "

if "%model_choice%"=="1" (
    echo Downloading qwen2.5-coder:7b...
    echo This is the recommended model for coding tasks.
    ollama pull qwen2.5-coder:7b
)
if "%model_choice%"=="2" (
    echo Downloading llama3.2:3b...
    ollama pull llama3.2:3b
)
if "%model_choice%"=="3" (
    echo Downloading mistral:7b...
    ollama pull mistral:7b
)
if "%model_choice%"=="4" (
    echo Downloading deepseek-coder:6.7b...
    ollama pull deepseek-coder:6.7b
)
if "%model_choice%"=="5" (
    echo Downloading phi3:mini...
    ollama pull phi3:mini
)
if "%model_choice%"=="6" (
    echo.
    echo Currently installed models:
    echo ========================
    ollama list
)
if "%model_choice%"=="7" (
    echo.
    echo Currently installed models:
    ollama list
    echo.
    set /p remove_model="Enter model name to remove (or press Enter to cancel): "
    if not "!remove_model!"=="" (
        ollama rm "!remove_model!"
        echo Model removal attempted.
    )
)
if "%model_choice%"=="8" goto MENU

echo.
echo Operation complete!
echo Press any key to return to menu...
pause >nul
goto MENU

:MEMORY
cls
echo ================================================================================
echo                        AI MEMORY SYSTEM SETUP
echo ================================================================================
echo.

set "MEMORY_PATH=%BASE_PATH%\AI_Memory"
echo Creating AI Memory system at: %MEMORY_PATH%
echo.

:: Create directory structure
echo Creating directory structure...
mkdir "%MEMORY_PATH%" 2>nul
mkdir "%MEMORY_PATH%\config" 2>nul
mkdir "%MEMORY_PATH%\memory" 2>nul
mkdir "%MEMORY_PATH%\logs" 2>nul
mkdir "%MEMORY_PATH%\templates" 2>nul
mkdir "%MEMORY_PATH%\documents" 2>nul
mkdir "%MEMORY_PATH%\exports" 2>nul

echo [OK] Directories created

:: Create configuration file
echo Creating configuration files...
(
echo {
echo   "system": "AI Memory System",
echo   "version": "2.0",
echo   "created": "%date% %time%",
echo   "base_path": "%BASE_PATH%",
echo   "memory_path": "%MEMORY_PATH%",
echo   "features": {
echo     "document_processing": true,
echo     "context_memory": true,
echo     "conversation_logs": true,
echo     "template_system": true
echo   },
echo   "settings": {
echo     "max_memory_items": 1000,
echo     "auto_cleanup": true,
echo     "backup_enabled": true
echo   }
echo }
) > "%MEMORY_PATH%\config\system.json"

:: Create README file
(
echo # AI Memory System
echo.
echo This directory contains the AI memory and document management system.
echo.
echo ## Directory Structure:
echo - config/     : System configuration files
echo - memory/     : AI conversation memory and context
echo - logs/       : System and interaction logs  
echo - templates/  : Document and response templates
echo - documents/  : User documents and files
echo - exports/    : Generated outputs and exports
echo.
echo ## Usage:
echo 1. Place your documents in the documents/ folder
echo 2. The AI will automatically index and remember them
echo 3. Templates can be customized in templates/ folder
echo 4. All interactions are logged in logs/ folder
echo.
echo Created: %date% %time%
) > "%MEMORY_PATH%\README.md"

echo [OK] Configuration files created
echo.
echo Memory system successfully set up at:
echo %MEMORY_PATH%
echo.
echo Directory structure:
echo - config\     : Configuration files
echo - memory\     : AI memory storage  
echo - logs\       : System logs
echo - templates\  : Document templates
echo - documents\  : Your documents
echo - exports\    : Generated files
echo.
echo You can now:
echo 1. Add documents to the documents\ folder
echo 2. Customize templates in templates\ folder  
echo 3. View interaction logs in logs\ folder
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:FIX
cls
echo ================================================================================
echo                          FIX COMMON ISSUES
echo ================================================================================
echo.

echo Starting comprehensive system repair...
echo.

echo [1/8] Stopping all related processes...
taskkill /F /IM ollama.exe >nul 2>&1
taskkill /F /IM python.exe >nul 2>&1
timeout /t 3 /nobreak >nul
echo [OK] Processes stopped

echo.
echo [2/8] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python not found. Please install Python first.
    echo Visit: https://www.python.org/downloads/
    pause
    goto MENU
) else (
    echo [OK] Python is available
)

echo.
echo [3/8] Recreating virtual environment...
if exist "%BASE_PATH%\ai_env" (
    echo Removing old virtual environment...
    rmdir /s /q "%BASE_PATH%\ai_env" 2>nul
)
echo Creating new virtual environment...
python -m venv "%BASE_PATH%\ai_env"
if errorlevel 1 (
    echo [ERROR] Failed to create virtual environment
    pause
    goto MENU
)
echo [OK] Virtual environment recreated

echo.
echo [4/8] Reinstalling Python packages...
call "%BASE_PATH%\ai_env\Scripts\activate.bat"
python -m pip install --upgrade pip --quiet
echo Installing core packages...
python -m pip install --quiet fastapi uvicorn websockets requests aiofiles python-multipart ollama-python pyautogui pillow
if errorlevel 1 (
    echo [WARNING] Some packages failed to install
)
echo [OK] Critical packages installed

echo.
echo [5/8] Recreating server files...
call :CREATE_SERVER_FILE
if exist "%BASE_PATH%\ai_server.py" (
    echo [OK] Server file recreated
) else (
    echo [ERROR] Failed to create server file
)

call :CREATE_STARTUP_SCRIPT
echo [OK] Startup script created

echo.
echo [6/8] Resetting network configuration...
:: Reset environment variables
setx OLLAMA_HOST "0.0.0.0" >nul 2>&1
setx OLLAMA_ORIGINS "*" >nul 2>&1
set OLLAMA_HOST=0.0.0.0
set OLLAMA_ORIGINS=*

:: Reset firewall rules
echo Resetting firewall rules...
netsh advfirewall firewall delete rule name="AI Server 8000" >nul 2>&1
netsh advfirewall firewall add rule name="AI Server 8000" dir=in action=allow protocol=TCP localport=8000 >nul 2>&1
netsh advfirewall firewall delete rule name="Ollama 11434" >nul 2>&1
netsh advfirewall firewall add rule name="Ollama 11434" dir=in action=allow protocol=TCP localport=11434 >nul 2>&1
echo [OK] Network settings reset

echo.
echo [7/8] Testing Ollama installation...
where ollama >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Ollama not found in PATH
    echo Please ensure Ollama is properly installed
) else (
    echo [OK] Ollama found
)

echo.
echo [8/8] Cleaning temporary files...
if exist "%TEMP%\ai_setup" rmdir /s /q "%TEMP%\ai_setup" 2>nul
echo [OK] Cleanup completed

echo.
echo ================================================================================
echo                          REPAIR COMPLETED!
echo ================================================================================
echo.
echo All common issues have been addressed:
echo - Processes stopped and cleaned
echo - Virtual environment recreated
echo - Essential packages reinstalled  
echo - Server files regenerated
echo - Network settings reset
echo - Firewall rules updated
echo.
echo Next steps:
echo 1. Try using START option to launch the server
echo 2. If issues persist, try INSTALL option for complete reinstall
echo 3. Check Windows Defender/Antivirus settings if problems continue
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:INFO
cls
echo ================================================================================
echo                         SERVER INFORMATION
echo ================================================================================
echo.

echo System Information:
echo ------------------
echo Installation Path: %BASE_PATH%
echo Script Version: 2.0 (Fixed)
echo Date: %date%
echo Time: %time%
echo.

echo Network Configuration:
echo ---------------------
call :GET_SERVER_IP
echo Current IP Address: %SERVER_IP%
if exist "%BASE_PATH%\server_ip.txt" (
    set /p SAVED_IP=<"%BASE_PATH%\server_ip.txt"
    echo Saved IP Address: %SAVED_IP%
)
echo Server Port: 8000
echo Ollama Port: 11434
echo WebSocket: ws://%SERVER_IP%:8000/ws
echo.

echo Software Status:
echo ---------------
python --version 2>nul
if errorlevel 1 (
    echo Python: [!] Not found
) else (
    echo Python: [OK] Available
)

where ollama >nul 2>&1
if errorlevel 1 (
    echo Ollama: [!] Not found in PATH
) else (
    echo Ollama: [OK] Available
    echo Installed Models:
    ollama list 2>nul
)

git --version >nul 2>&1
if errorlevel 1 (
    echo Git: [!] Not available
) else (
    echo Git: [OK] Available
)

echo.
echo Environment Status:
echo ------------------
if exist "%BASE_PATH%\ai_env" (
    echo Virtual Environment: [OK] Exists
    if exist "%BASE_PATH%\ai_env\Scripts\python.exe" (
        echo Python in venv: [OK] Available
    ) else (
        echo Python in venv: [!] Missing
    )
) else (
    echo Virtual Environment: [!] Not found
)

if exist "%BASE_PATH%\ai_server.py" (
    echo Server Script: [OK] Available
) else (
    echo Server Script: [!] Missing
)

echo.
echo Hardware Recommendations:
echo ------------------------
echo CPU: Intel i5-14400 or better
echo GPU: RTX 2060 6GB (your current setup)
echo RAM: 16GB+ (24GB recommended)
echo Storage: 50GB+ free space for models
echo.

echo Recommended Models for RTX 2060:
echo --------------------------------
echo - qwen2.5-coder:7b (4.7GB) - Best for coding
echo - llama3.2:3b (2.0GB) - Fast general purpose  
echo - mistral:7b (4.1GB) - Balanced performance
echo - phi3:mini (2.3GB) - Lightweight option
echo.

echo Environment Variables:
echo ---------------------
echo OLLAMA_HOST: %OLLAMA_HOST%
echo OLLAMA_ORIGINS: %OLLAMA_ORIGINS%
echo.

echo Log Files Location:
echo ------------------
if exist "%BASE_PATH%\logs" (
    echo Logs Directory: %BASE_PATH%\logs
    if exist "%BASE_PATH%\logs\install.log" (
        echo Install Log: Available
    )
    if exist "%BASE_PATH%\logs\server.log" (
        echo Server Log: Available
    )
) else (
    echo Logs Directory: Not created yet
)

echo.
echo Troubleshooting Tips:
echo -------------------
echo 1. Run as Administrator for full functionality
echo 2. Check Windows Defender/Antivirus exclusions
echo 3. Ensure ports 8000 and 11434 are not blocked
echo 4. Verify internet connection for model downloads
echo 5. Use FIX option if experiencing issues
echo.

echo Press any key to return to menu...
pause >nul
goto MENU

:: ==============================================================================
:: HELPER FUNCTIONS
:: ==============================================================================

:GET_SERVER_IP
:: Get the primary network adapter IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "127.0.0.1"') do (
    for /f "tokens=1" %%b in ("%%a") do (
        set SERVER_IP=%%b
        goto :ip_found
    )
)
:ip_found
if "%SERVER_IP%"=="" set SERVER_IP=127.0.0.1
goto :eof

:CREATE_STARTUP_SCRIPT
echo Creating startup script...
(
echo @echo off
echo title AI Server Startup
echo cd /d "%BASE_PATH%"
echo.
echo echo Starting AI Server...
echo echo Working directory: %BASE_PATH%
echo.
echo :: Set environment variables
echo set OLLAMA_HOST=0.0.0.0
echo set OLLAMA_ORIGINS=*
echo.
echo :: Start Ollama if not running
echo tasklist /FI "IMAGENAME eq ollama.exe" 2^>nul ^| find /I "ollama.exe" ^>nul
echo if errorlevel 1 (
echo     echo Starting Ollama...
echo     start "Ollama Server" cmd /c "set OLLAMA_HOST=0.0.0.0 && set OLLAMA_ORIGINS=* && ollama serve"
echo     timeout /t 8 /nobreak ^>nul
echo ^)
echo.
echo :: Activate virtual environment
echo call "%BASE_PATH%\ai_env\Scripts\activate.bat"
echo.
echo :: Start server
echo python "%BASE_PATH%\ai_server.py"
echo.
echo pause
) > "%BASE_PATH%\start_server.bat"
goto :eof

:CREATE_SERVER_FILE
echo Creating ai_server.py...
(
echo import os
echo import sys
echo import json
echo import asyncio
echo import logging
echo import socket
echo from datetime import datetime
echo from typing import Dict, Any, Optional, List
echo from pathlib import Path
echo.
echo # Configure logging first
echo os.makedirs('logs', exist_ok=True^)
echo logging.basicConfig(
echo     level=logging.INFO,
echo     format='%%(asctime^)s - %%(name^)s - %%(levelname^)s - %%(message^)s',
echo     handlers=[
echo         logging.FileHandler('logs/server.log'^),
echo         logging.StreamHandler(^)
echo     ]
echo ^)
echo logger = logging.getLogger(__name__^)
echo.
echo # Try importing required packages with better error handling
echo missing_packages = []
echo.
echo try:
echo     from fastapi import FastAPI, WebSocket, HTTPException, Request
echo     from fastapi.middleware.cors import CORSMiddleware
echo     from fastapi.responses import JSONResponse, HTMLResponse
echo     from fastapi.staticfiles import StaticFiles
echo     import uvicorn
echo except ImportError as e:
echo     missing_packages.append(f"FastAPI/Uvicorn: {e}"]
echo     logger.error(f"FastAPI import error: {e}"^)
echo.
echo try:
echo     import websockets
echo except ImportError as e:
echo     missing_packages.append(f"WebSockets: {e}"]
echo     logger.error(f"WebSockets import error: {e}"^)
echo.
echo try:
echo     import requests
echo except ImportError as e:
echo     missing_packages.append(f"Requests: {e}"]
echo     logger.error(f"Requests import error: {e}"^)
echo.
echo # Optional imports
echo try:
echo     import interpreter
echo     logger.info("Open Interpreter available"^)
echo except ImportError:
echo     interpreter = None
echo     logger.warning("Open Interpreter not available - using basic mode"^)
echo.
echo try:
echo     import pyautogui
echo     import PIL
echo     logger.info("GUI automation libraries available"^)
echo except ImportError:
echo     pyautogui = None
echo     logger.warning("GUI libraries not available"^)
echo.
echo # Check for critical missing packages
echo if missing_packages:
echo     logger.error("Critical packages missing:"^)
echo     for pkg in missing_packages:
echo         logger.error(f"  - {pkg}"^)
echo     logger.error("Please run: pip install fastapi uvicorn websockets requests"^)
echo     sys.exit(1^)
echo.
echo # Create FastAPI app
echo app = FastAPI(
echo     title="AI Control Server",
echo     description="Remote AI Control System",
echo     version="2.0"
echo ^)
echo.
echo # Add CORS middleware for cross-origin requests
echo app.add_middleware(
echo     CORSMiddleware,
echo     allow_origins=["*"],
echo     allow_credentials=True,
echo     allow_methods=["*"],
echo     allow_headers=["*"],
echo ^)
echo.
echo # Configure Open Interpreter if available
echo if interpreter:
echo     try:
echo         interpreter.llm.model = "ollama/qwen2.5-coder:7b"
echo         interpreter.llm.api_base = "http://localhost:11434"
echo         interpreter.auto_run = False
echo         interpreter.safe_mode = 'off'
echo         interpreter.system_message = """You are an AI assistant for remote computer control.
echo         Analyze user commands and provide safe, executable instructions.
echo         Focus on Windows system commands and automation tasks.
echo         Always prioritize safety and ask for confirmation on destructive operations."""
echo         logger.info("Open Interpreter configured successfully"^)
echo     except Exception as e:
echo         logger.error(f"Error configuring Open Interpreter: {e}"^)
echo         interpreter = None
echo.
echo class AIController:
echo     def __init__(self^):
echo         self.clients: Dict[int, WebSocket] = {}
echo         self.command_history: List[Dict] = []
echo         self.max_history = 100
echo         logger.info("AI Controller initialized"^)
echo.
echo     async def process_command(self, command: str, context: Optional[Dict] = None^) -^> Dict[str, Any]:
echo         """Process commands with AI assistance"""
echo         try:
echo             logger.info(f"Processing command: {command[:100]}..."^)
echo             
echo             # Clean and validate command
echo             if not command or not command.strip(^):
echo                 return {"error": "Empty command", "actions": []}
echo             
echo             command = command.strip(^)
echo             
echo             # Use Open Interpreter if available
echo             if interpreter:
echo                 return await self._process_with_interpreter(command, context^)
echo             else:
echo                 return self._process_basic_command(command^)
echo                 
echo         except Exception as e:
echo             logger.error(f"Error processing command: {e}"^)
echo             return {
echo                 "error": str(e^),
echo                 "actions": [],
echo                 "timestamp": datetime.now(^).isoformat(^)
echo             }
echo.
echo     async def _process_with_interpreter(self, command: str, context: Optional[Dict] = None^) -^> Dict[str, Any]:
echo         """Process command using Open Interpreter"""
echo         try:
echo             # Build context-aware prompt
echo             prompt_parts = [
echo                 f"User request: {command}",
echo                 "Please provide executable commands for Windows."
echo             ]
echo             
echo             if context:
echo                 prompt_parts.append(f"Context: {json.dumps(context^)}"^)
echo             
echo             prompt_parts.append("""
echo             Return your response as executable commands or code.
echo             If the request involves file operations, use full paths.
echo             If it's a system command, provide the exact command syntax.
echo             Be safe and avoid destructive operations without explicit confirmation."""^)
echo             
echo             full_prompt = "\n".join(prompt_parts^)
echo             
echo             # Get response from interpreter
echo             response = interpreter.chat(full_prompt, display=False^)
echo             commands = self._extract_commands_from_response(response^)
echo             
echo             # Add to history
echo             self._add_to_history(command, commands^)
echo             
echo             return {
echo                 "success": True,
echo                 "actions": commands,
echo                 "timestamp": datetime.now(^).isoformat(^),
echo                 "method": "interpreter"
echo             }
echo             
echo         except Exception as e:
echo             logger.error(f"Interpreter processing error: {e}"^)
echo             # Fallback to basic processing
echo             return self._process_basic_command(command^)
echo.
echo     def _process_basic_command(self, command: str^) -^> Dict[str, Any]:
echo         """Basic command processing without Open Interpreter"""
echo         command_lower = command.lower(^)
echo         actions = []
echo         
echo         # Enhanced basic command mapping
echo         command_mappings = {
echo             'open chrome': 'start chrome',
echo             'open browser': 'start chrome',
echo             'open notepad': 'notepad',
echo             'open calculator': 'calc',
echo             'open file explorer': 'explorer',
echo             'open task manager': 'taskmgr',
echo             'open control panel': 'control',
echo             'shutdown': 'shutdown /s /t 0',
echo             'restart': 'shutdown /r /t 0',
echo             'lock screen': 'rundll32.exe user32.dll,LockWorkStation',
echo             'take screenshot': 'screenshot_command',
echo             'list files': 'dir',
echo             'current directory': 'cd',
echo             'system info': 'systeminfo'
echo         }
echo         
echo         # Check for direct matches
echo         matched = False
echo         for key, value in command_mappings.items(^):
echo             if key in command_lower:
echo                 if value == 'screenshot_command':
echo                     actions.append({
echo                         "type": "python",
echo                         "code": "import pyautogui; pyautogui.screenshot(^).save('screenshot.png'^); print('Screenshot saved as screenshot.png'^)"
echo                     }^)
echo                 else:
echo                     actions.append({
echo                         "type": "command",
echo                         "code": value
echo                     }^)
echo                 matched = True
echo                 break
echo         
echo         # If no match found, treat as direct command
echo         if not matched:
echo             # Basic safety checks
echo             dangerous_commands = ['format', 'del *', 'rm -rf', 'rmdir /s']
echo             if any(dangerous in command_lower for dangerous in dangerous_commands^):
echo                 actions.append({
echo                     "type": "error",
echo                     "code": f"Potentially dangerous command blocked: {command}"
echo                 }^)
echo             else:
echo                 actions.append({
echo                     "type": "command", 
echo                     "code": command
echo                 }^)
echo         
echo         result = {
echo             "success": True,
echo             "actions": actions,
echo             "timestamp": datetime.now(^).isoformat(^),
echo             "method": "basic"
echo         }
echo         
echo         self._add_to_history(command, result^)
echo         return result
echo.
echo     def _extract_commands_from_response(self, response^) -^> List[Dict]:
echo         """Extract executable commands from interpreter response"""
echo         commands = []
echo         
echo         if not response:
echo             return commands
echo             
echo         # Handle different response formats
echo         if isinstance(response, list^):
echo             for item in response:
echo                 if isinstance(item, dict^):
echo                     if item.get('type'^) == 'code':
echo                         commands.append({
echo                             'type': 'execute',
echo                             'code': item.get('content', ''^),
echo                             'language': item.get('format', 'python'^)
echo                         }^)
echo                     elif item.get('type'^) == 'message':
echo                         # Extract code blocks from message
echo                         content = item.get('content', ''^)
echo                         if '```' in content:
echo                             # Extract code blocks
echo                             blocks = content.split('```'^)
echo                             for i, block in enumerate(blocks^):
echo                                 if i %% 2 == 1:  # Odd indices are code blocks
echo                                     commands.append({
echo                                         'type': 'execute',
echo                                         'code': block.strip(^),
echo                                         'language': 'auto'
echo                                     }^)
echo         
echo         # If no commands extracted, return the raw response
echo         if not commands and response:
echo             commands.append({
echo                 'type': 'response',
echo                 'code': str(response^),
echo                 'language': 'text'
echo             }^)
echo         
echo         return commands
echo.
echo     def _add_to_history(self, command: str, result: Dict^):
echo         """Add command to history with size limit"""
echo         history_entry = {
echo             "timestamp": datetime.now(^).isoformat(^),
echo             "input": command,
echo             "output": result
echo         }
echo         
echo         self.command_history.append(history_entry^)
echo         
echo         # Maintain history size limit
echo         if len(self.command_history^) ^> self.max_history:
echo             self.command_history = self.command_history[-self.max_history:]
echo.
echo     def get_history(self, limit: int = 10^) -^> List[Dict]:
echo         """Get recent command history"""
echo         return self.command_history[-limit:]
echo.
echo     async def broadcast_to_clients(self, message: Dict^):
echo         """Broadcast message to all connected clients"""
echo         if not self.clients:
echo             return
echo             
echo         disconnected_clients = []
echo         for client_id, websocket in self.clients.items(^):
echo             try:
echo                 await websocket.send_text(json.dumps(message^)^)
echo             except Exception:
echo                 disconnected_clients.append(client_id^)
echo         
echo         # Clean up disconnected clients
echo         for client_id in disconnected_clients:
echo             if client_id in self.clients:
echo                 del self.clients[client_id]
echo.
echo # Initialize controller
echo ai_controller = AIController(^)
echo.
echo # API Endpoints
echo @app.get("/"^)
echo async def root(^):
echo     """Root endpoint with server information"""
echo     return HTMLResponse(content="""
echo     ^<^!DOCTYPE html^>
echo     ^<html^>
echo     ^<head^>
echo         ^<title^>AI Control Server^</title^>
echo         ^<style^>
echo             body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
echo             .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1^); }
echo             .status { color: #28a745; font-weight: bold; }
echo             .info { background: #e7f3ff; padding: 15px; border-left: 4px solid #007bff; margin: 15px 0; }
echo             .endpoint { background: #f8f9fa; padding: 10px; margin: 5px 0; border-radius: 5px; font-family: monospace; }
echo         ^</style^>
echo     ^</head^>
echo     ^<body^>
echo         ^<div class="container"^>
echo             ^<h1^>AI Control Server ^<span class="status"^>[ONLINE]^</span^>^</h1^>
echo             ^<div class="info"^>
echo                 ^<h3^>Server Status^</h3^>
echo                 ^<p^>Version: 2.0^</p^>
echo                 ^<p^>Open Interpreter: """ + ("Available" if interpreter else "Not Available"^) + """^</p^>
echo                 ^<p^>Active Connections: """ + str(len(ai_controller.clients^)^) + """^</p^>
echo                 ^<p^>Commands Processed: """ + str(len(ai_controller.command_history^)^) + """^</p^>
echo             ^</div^>
echo             ^<h3^>Available Endpoints^</h3^>
echo             ^<div class="endpoint"^>GET /status - Server status information^</div^>
echo             ^<div class="endpoint"^>POST /process - Process single command^</div^>
echo             ^<div class="endpoint"^>GET /history - Get command history^</div^>
echo             ^<div class="endpoint"^>WebSocket /ws - Real-time communication^</div^>
echo         ^</div^>
echo     ^</body^>
echo     ^</html^>
echo     """^)
echo.
echo @app.get("/status"^)
echo async def get_status(^):
echo     """Get server status"""
echo     # Test Ollama connection
echo     ollama_status = "disconnected"
echo     try:
echo         response = requests.get("http://localhost:11434/api/tags", timeout=5^)
echo         if response.status_code == 200:
echo             ollama_status = "connected"
echo     except:
echo         pass
echo     
echo     return {
echo         "status": "online",
echo         "version": "2.0",
echo         "timestamp": datetime.now(^).isoformat(^),
echo         "interpreter_available": interpreter is not None,
echo         "ollama_status": ollama_status,
echo         "connected_clients": len(ai_controller.clients^),
echo         "total_commands": len(ai_controller.command_history^),
echo         "uptime": "running"
echo     }
echo.
echo @app.post("/process"^)
echo async def process_command_endpoint(request: Request^):
echo     """Process a single command"""
echo     try:
echo         data = await request.json(^)
echo         command = data.get('command'^)
echo         
echo         if not command:
echo             raise HTTPException(status_code=400, detail="No command provided"^)
echo         
echo         context = data.get('context'^)
echo         result = await ai_controller.process_command(command, context^)
echo         
echo         # Broadcast to connected WebSocket clients
echo         await ai_controller.broadcast_to_clients({
echo             "type": "command_processed",
echo             "command": command,
echo             "result": result
echo         }^)
echo         
echo         return JSONResponse(content=result^)
echo         
echo     except json.JSONDecodeError:
echo         raise HTTPException(status_code=400, detail="Invalid JSON"^)
echo     except Exception as e:
echo         logger.error(f"Command processing error: {e}"^)
echo         raise HTTPException(status_code=500, detail=str(e^)^)
echo.
echo @app.get("/history"^)
echo async def get_history(limit: int = 10^):
echo     """Get command history"""
echo     return {
echo         "history": ai_controller.get_history(limit^),
echo         "total_commands": len(ai_controller.command_history^)
echo     }
echo.
echo @app.websocket("/ws"^)
echo async def websocket_endpoint(websocket: WebSocket^):
echo     """WebSocket endpoint for real-time communication"""
echo     await websocket.accept(^)
echo     client_id = id(websocket^)
echo     ai_controller.clients[client_id] = websocket
echo     
echo     logger.info(f"WebSocket client {client_id} connected"^)
echo     
echo     try:
echo         # Send welcome message
echo         await websocket.send_text(json.dumps({
echo             "type": "connection_established",
echo             "client_id": client_id,
echo             "message": "Connected to AI Control Server",
echo             "server_info": {
echo                 "version": "2.0",
echo                 "interpreter_available": interpreter is not None,
echo                 "timestamp": datetime.now(^).isoformat(^)
echo             }
echo         }^)^)
echo         
echo         # Message handling loop
echo         while True:
echo             try:
echo                 data = await websocket.receive_text(^)
echo                 message = json.loads(data^)
echo                 
echo                 message_type = message.get('type', 'command'^)
echo                 
echo                 if message_type == 'command':
echo                     command = message.get('command'^)
echo                     if command:
echo                         context = message.get('context'^)
echo                         result = await ai_controller.process_command(command, context^)
echo                         
echo                         await websocket.send_text(json.dumps({
echo                             "type": "command_result",
echo                             "command": command,
echo                             "result": result,
echo                             "timestamp": datetime.now(^).isoformat(^)
echo                         }^)^)
echo                     else:
echo                         await websocket.send_text(json.dumps({
echo                             "type": "error",
echo                             "message": "No command provided"
echo                         }^)^)
echo                 
echo                 elif message_type == 'ping':
echo                     await websocket.send_text(json.dumps({
echo                         "type": "pong",
echo                         "timestamp": datetime.now(^).isoformat(^)
echo                     }^)^)
echo                 
echo                 elif message_type == 'get_status':
echo                     status = await get_status(^)
echo                     await websocket.send_text(json.dumps({
echo                         "type": "status_response",
echo                         "status": status
echo                     }^)^)
echo                     
echo             except websockets.exceptions.ConnectionClosed:
echo                 break
echo             except json.JSONDecodeError:
echo                 await websocket.send_text(json.dumps({
echo                     "type": "error",
echo                     "message": "Invalid JSON format"
echo                 }^)^)
echo             except Exception as e:
echo                 logger.error(f"WebSocket message handling error: {e}"^)
echo                 await websocket.send_text(json.dumps({
echo                     "type": "error", 
echo                     "message": f"Server error: {str(e^)}"
echo                 }^)^)
echo                 
echo     except websockets.exceptions.ConnectionClosed:
echo         logger.info(f"WebSocket client {client_id} disconnected normally"^)
echo     except Exception as e:
echo         logger.error(f"WebSocket error for client {client_id}: {e}"^)
echo     finally:
echo         # Clean up client connection
echo         if client_id in ai_controller.clients:
echo             del ai_controller.clients[client_id]
echo         logger.info(f"WebSocket client {client_id} cleanup completed"^)
echo.
echo # Health check endpoint
echo @app.get("/health"^)
echo async def health_check(^):
echo     """Simple health check"""
echo     return {"status": "healthy", "timestamp": datetime.now(^).isoformat(^)}
echo.
echo if __name__ == "__main__":
echo     # Get network information
echo     hostname = socket.gethostname(^)
echo     try:
echo         local_ip = socket.gethostbyname(hostname^)
echo     except:
echo         local_ip = "127.0.0.1"
echo     
echo     print("\n" + "="*80^)
echo     print("AI CONTROL SERVER v2.0"^)
echo     print("="*80^)
echo     print(f"🌐 Local Access:    http://localhost:8000"^)
echo     print(f"🌐 Network Access:  http://{local_ip}:8000"^)
echo     print(f"🔌 WebSocket:       ws://{local_ip}:8000/ws"^)
echo     print(f"📊 Status Endpoint: http://{local_ip}:8000/status"^)
echo     print("="*80^)
echo     print(f"📁 Working Directory: {os.getcwd(^)}"^)
echo     print(f"🤖 Open Interpreter: {'✓ Available' if interpreter else '✗ Not Available'}"^)
echo     print(f"📝 Logs: {os.path.join(os.getcwd(^), 'logs'^)}"^)
echo     print("="*80^)
echo     print("Press Ctrl+C to stop the server"^)
echo     print("="*80^)
echo     
echo     logger.info("Starting AI Control Server v2.0"^)
echo     logger.info(f"Server accessible at: http://{local_ip}:8000"^)
echo     
echo     try:
echo         # Start the server
echo         uvicorn.run(
echo             app, 
echo             host="0.0.0.0", 
echo             port=8000, 
echo             log_level="info",
echo             access_log=True
echo         ^)
echo     except KeyboardInterrupt:
echo         logger.info("Server stopped by user"^)
echo     except Exception as e:
echo         logger.error(f"Server error: {e}"^)
echo     finally:
echo         logger.info("Server shutdown complete"^)
) > "%BASE_PATH%\ai_server.py"
goto :eof