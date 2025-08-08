@echo off
title AI Client Control Center
color 0B
chcp 65001 >nul 2>&1

:: Set working directory to script location
cd /d "%~dp0"
set "CLIENT_PATH=%CD%"

:: Create logs directory
if not exist "%CLIENT_PATH%\logs" mkdir "%CLIENT_PATH%\logs"
set "LOG_FILE=%CLIENT_PATH%\logs\client.log"

:MENU
cls
echo ================================================================================
echo                          AI CLIENT CONTROL CENTER
echo                           Remote Control Client
echo ================================================================================
echo.
echo    Working Directory: %CLIENT_PATH%
echo.
echo    [1] SETUP   - Install Client ^& Connect to Server
echo    [2] CONNECT - Connect to AI Server (Auto Mode)
echo    [3] TEST    - Test Server Connection
echo    [4] CONTROL - Start Interactive Control Session
echo    [5] COMMAND - Send Single Command
echo    [6] MONITOR - View Active Sessions ^& Status
echo    [7] UPDATE  - Update Client Software
echo    [8] CONFIG  - Configure Settings
echo    [9] HELP    - Show Help ^& Commands
echo    [0] EXIT    - Close Control Center
echo.
echo ================================================================================
set /p choice="Select Option [0-9]: "

if "%choice%"=="1" goto SETUP
if "%choice%"=="2" goto CONNECT
if "%choice%"=="3" goto TEST
if "%choice%"=="4" goto CONTROL
if "%choice%"=="5" goto COMMAND
if "%choice%"=="6" goto MONITOR
if "%choice%"=="7" goto UPDATE
if "%choice%"=="8" goto CONFIG
if "%choice%"=="9" goto HELP
if "%choice%"=="0" exit

echo Invalid option! Press any key to continue...
pause >nul
goto MENU

:SETUP
cls
echo ================================================================================
echo                         CLIENT SETUP ^& INSTALLATION
echo ================================================================================
echo.
echo %date% %time% - Starting client setup >> "%LOG_FILE%"

echo Working Directory: %CLIENT_PATH%
echo.

:: Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Not running as administrator
    echo Some automation features may not work properly
    timeout /t 3 /nobreak >nul
)

echo [Phase 1/5] Checking System Requirements...
echo ----------------------------------------

:: Check Python
echo Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found!
    echo.
    echo Please install Python 3.8+ first:
    echo 1. Visit: https://www.python.org/downloads/
    echo 2. Download Python 3.11 or newer
    echo 3. Make sure to check "Add Python to PATH" during installation
    echo 4. Restart this script after installation
    echo.
    pause
    goto MENU
) else (
    echo [OK] Python is installed
    python --version
)

:: Check pip
echo Checking pip...
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] pip not found, trying to install...
    python -m ensurepip --upgrade >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Could not install pip
        pause
        goto MENU
    )
) else (
    echo [OK] pip is available
)

echo.
echo [Phase 2/5] Server Configuration...
echo ----------------------------------------

:: Get server IP with validation
:GET_SERVER_IP
set /p SERVER_IP="Enter Server IP Address (e.g., 192.168.1.100): "

:: Validate IP format (basic check)
echo %SERVER_IP% | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Invalid IP format! Please enter a valid IP address.
    goto GET_SERVER_IP
)

:: Test basic connectivity
echo Testing connectivity to %SERVER_IP%...
ping %SERVER_IP% -n 1 -w 1000 >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Cannot ping server. Continue anyway? (y/n)
    set /p continue_setup="Continue setup? [y/n]: "
    if /i not "%continue_setup%"=="y" goto MENU
)

echo [OK] Server IP: %SERVER_IP%

echo.
echo [Phase 3/5] Installing Python Libraries...
echo ----------------------------------------

echo Upgrading pip...
python -m pip install --upgrade pip --quiet --no-warn-script-location

echo Installing core libraries...
echo - pyautogui (GUI automation)
echo - pillow (Image processing)  
echo - websocket-client (WebSocket communication)
echo - requests (HTTP requests)
echo - keyboard (Keyboard monitoring)
echo - psutil (System monitoring)
echo - opencv-python (Advanced image processing)

python -m pip install --quiet --no-warn-script-location pyautogui pillow websocket-client requests keyboard psutil opencv-python
if errorlevel 1 (
    echo [WARNING] Some packages failed to install
    echo Trying with basic packages only...
    python -m pip install --quiet pyautogui pillow websocket-client requests
    if errorlevel 1 (
        echo [ERROR] Critical packages installation failed
        echo Please check your internet connection and try again
        pause
        goto MENU
    )
)

echo [OK] Python libraries installed successfully

echo.
echo [Phase 4/5] Creating Configuration Files...
echo ----------------------------------------

:: Save server configuration
echo Creating server configuration...
(
echo {
echo   "server_ip": "%SERVER_IP%",
echo   "server_port": 8000,
echo   "websocket_port": 8000,
echo   "auto_reconnect": true,
echo   "max_reconnect_attempts": 5,
echo   "reconnect_delay": 3,
echo   "screenshot_quality": 80,
echo   "safety_mode": true,
echo   "log_commands": true,
echo   "created": "%date% %time%"
echo }
) > "%CLIENT_PATH%\client_config.json"

:: Backup simple config for compatibility
echo %SERVER_IP% > "%CLIENT_PATH%\server_config.txt"

echo [OK] Configuration files created

echo.
echo [Phase 5/5] Creating Client Script...
echo ----------------------------------------

call :CREATE_CLIENT_FILE
if exist "%CLIENT_PATH%\ai_client.py" (
    echo [OK] Client script created successfully
) else (
    echo [ERROR] Failed to create client script
    pause
    goto MENU
)

:: Create startup script
call :CREATE_STARTUP_SCRIPT
echo [OK] Startup script created

echo %date% %time% - Client setup completed >> "%LOG_FILE%"

cls
echo ================================================================================
echo                           SETUP COMPLETE!
echo ================================================================================
echo.
echo Configuration Summary:
echo ---------------------
echo Server IP: %SERVER_IP%
echo Server Port: 8000
echo WebSocket: ws://%SERVER_IP%:8000/ws
echo Working Directory: %CLIENT_PATH%
echo.
echo Files Created:
echo - ai_client.py (Main client script)
echo - client_config.json (Configuration)
echo - start_client.bat (Quick startup)
echo - logs\ (Log directory)
echo.
echo Next Steps:
echo 1. Use option [3] to test connection
echo 2. Use option [4] for interactive control
echo 3. Use option [2] for automatic mode
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:CONNECT
cls
echo ================================================================================
echo                        CONNECTING TO AI SERVER
echo                            (Automatic Mode)
echo ================================================================================
echo.

if not exist "%CLIENT_PATH%\client_config.json" (
    if not exist "%CLIENT_PATH%\server_config.txt" (
        echo [ERROR] No configuration found!
        echo Please run SETUP first (option 1).
        pause
        goto MENU
    )
)

:: Load configuration
if exist "%CLIENT_PATH%\client_config.json" (
    echo Loading configuration from client_config.json...
    for /f "tokens=2 delims=:" %%a in ('type "%CLIENT_PATH%\client_config.json" ^| findstr "server_ip"') do (
        set SERVER_IP=%%a
        set SERVER_IP=!SERVER_IP: =!
        set SERVER_IP=!SERVER_IP:"=!
        set SERVER_IP=!SERVER_IP:,=!
    )
) else (
    echo Loading configuration from server_config.txt...
    set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
)

echo Server: %SERVER_IP%
echo Mode: Automatic (waiting for commands)
echo.
echo ================================================================================
echo CLIENT IS NOW RUNNING - Ready to receive commands
echo ================================================================================
echo.
echo Instructions:
echo - This window will show executed commands
echo - Send commands from the server or another client
echo - Press Ctrl+C to stop the client
echo.
echo ----------------------------------------
echo.

python "%CLIENT_PATH%\ai_client.py" auto

echo.
echo Connection closed. Press any key to return to menu...
pause >nul
goto MENU

:TEST
cls
echo ================================================================================
echo                         SERVER CONNECTION TEST
echo ================================================================================
echo.

:: Load server IP
if exist "%CLIENT_PATH%\client_config.json" (
    echo Loading server configuration...
    for /f "tokens=2 delims=:" %%a in ('type "%CLIENT_PATH%\client_config.json" ^| findstr "server_ip"') do (
        set SERVER_IP=%%a
        set SERVER_IP=!SERVER_IP: =!
        set SERVER_IP=!SERVER_IP:"=!
        set SERVER_IP=!SERVER_IP:,=!
    )
) else if exist "%CLIENT_PATH%\server_config.txt" (
    set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
) else (
    set /p SERVER_IP="Enter Server IP: "
)

echo Testing connection to: %SERVER_IP%
echo ================================================================================
echo.

:: Test 1: Basic connectivity
echo [Test 1/5] Basic Network Connectivity...
ping %SERVER_IP% -n 2 -w 2000 >nul 2>&1
if %errorlevel%==0 (
    echo [✓] Server is reachable via ping
) else (
    echo [✗] Server is not responding to ping
    echo      This might be due to firewall settings
)

echo.

:: Test 2: Ollama port
echo [Test 2/5] Ollama Service (Port 11434)...
powershell -Command "try { $tcp = New-Object Net.Sockets.TcpClient; $tcp.Connect('%SERVER_IP%', 11434); $tcp.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo [✓] Ollama port is accessible
) else (
    echo [✗] Cannot connect to Ollama port 11434
)

echo.

:: Test 3: AI Server port
echo [Test 3/5] AI Server (Port 8000)...
powershell -Command "try { $tcp = New-Object Net.Sockets.TcpClient; $tcp.Connect('%SERVER_IP%', 8000); $tcp.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel%==0 (
    echo [✓] AI Server port is accessible
) else (
    echo [✗] Cannot connect to AI Server port 8000
)

echo.

:: Test 4: HTTP API
echo [Test 4/5] HTTP API Endpoint...
curl -s -m 10 http://%SERVER_IP%:8000/status >nul 2>&1
if %errorlevel%==0 (
    echo [✓] HTTP API is responding
    echo.
    echo Server Status Information:
    echo --------------------------
    curl -s -m 10 http://%SERVER_IP%:8000/status 2>nul | python -m json.tool 2>nul
    if errorlevel 1 (
        curl -s -m 10 http://%SERVER_IP%:8000/status 2>nul
    )
) else (
    echo [✗] HTTP API is not responding
)

echo.

:: Test 5: WebSocket
echo [Test 5/5] WebSocket Connection...
python -c "
import websocket
import sys
try:
    ws = websocket.create_connection('ws://%SERVER_IP%:8000/ws', timeout=10)
    ws.close()
    print('[✓] WebSocket connection successful')
    sys.exit(0)
except Exception as e:
    print(f'[✗] WebSocket connection failed: {e}')
    sys.exit(1)
" 2>nul
if %errorlevel%==0 (
    echo     WebSocket is ready for communication
) else (
    echo     WebSocket connection failed
)

echo.
echo ================================================================================
echo Connection test completed!
echo.
echo If any tests failed, check:
echo 1. Server is running and accessible
echo 2. Firewall settings on both machines
echo 3. Network connectivity between devices
echo 4. Correct IP address configuration
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:CONTROL
cls
echo ================================================================================
echo                        INTERACTIVE CONTROL SESSION
echo ================================================================================
echo.

if not exist "%CLIENT_PATH%\ai_client.py" (
    echo [ERROR] Client script not found!
    echo Please run SETUP first (option 1).
    pause
    goto MENU
)

:: Load server configuration
if exist "%CLIENT_PATH%\client_config.json" (
    for /f "tokens=2 delims=:" %%a in ('type "%CLIENT_PATH%\client_config.json" ^| findstr "server_ip"') do (
        set SERVER_IP=%%a
        set SERVER_IP=!SERVER_IP: =!
        set SERVER_IP=!SERVER_IP:"=!
        set SERVER_IP=!SERVER_IP:,=!
    )
) else if exist "%CLIENT_PATH%\server_config.txt" (
    set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
) else (
    echo [ERROR] No server configuration found!
    echo Please run SETUP first (option 1).
    pause
    goto MENU
)

echo Server: %SERVER_IP%
echo Mode: Interactive Control
echo.
echo ================================================================================
echo                         INTERACTIVE MODE STARTING
echo ================================================================================
echo.
echo AVAILABLE COMMANDS:
echo - Natural language: "Open Chrome", "Take screenshot"
echo - System commands: "dir", "ipconfig", "tasklist"  
echo - Special commands: "exit", "help", "status"
echo.
echo CONTROLS:
echo - Type commands and press Enter
echo - Type 'exit' to end session
echo - Ctrl+C for emergency stop
echo.
echo ----------------------------------------

python "%CLIENT_PATH%\ai_client.py" interactive

echo.
echo Session ended. Press any key to return to menu...
pause >nul
goto MENU

:COMMAND
cls
echo ================================================================================
echo                         SEND SINGLE COMMAND
echo ================================================================================
echo.

if not exist "%CLIENT_PATH%\ai_client.py" (
    echo [ERROR] Client script not found!
    echo Please run SETUP first (option 1).
    pause
    goto MENU
)

echo Enter a single command to execute on this computer:
echo (Examples: "open notepad", "take screenshot", "show desktop")
echo.
set /p CMD="Command: "

if "%CMD%"=="" (
    echo No command entered.
    pause
    goto MENU
)

echo.
echo Executing: %CMD%
echo ----------------------------------------

python "%CLIENT_PATH%\ai_client.py" command "%CMD%"

echo.
echo Command completed. Press any key to return to menu...
pause >nul
goto MENU

:MONITOR
cls
echo ================================================================================
echo                       SESSION MONITOR ^& STATUS
echo ================================================================================
echo.
echo %date% %time%
echo Working Directory: %CLIENT_PATH%
echo.

:: Check configuration
echo Configuration Status:
echo ---------------------
if exist "%CLIENT_PATH%\client_config.json" (
    echo [✓] Main configuration file exists
    for /f "tokens=2 delims=:" %%a in ('type "%CLIENT_PATH%\client_config.json" ^| findstr "server_ip"') do (
        set SERVER_IP=%%a
        set SERVER_IP=!SERVER_IP: =!
        set SERVER_IP=!SERVER_IP:"=!
        set SERVER_IP=!SERVER_IP:,=!
    )
    echo     Configured Server: !SERVER_IP!
) else if exist "%CLIENT_PATH%\server_config.txt" (
    echo [!] Using legacy configuration
    set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
    echo     Server: !SERVER_IP!
) else (
    echo [✗] No configuration found
    set SERVER_IP=Not configured
)

if exist "%CLIENT_PATH%\ai_client.py" (
    echo [✓] Client script available
) else (
    echo [✗] Client script missing
)

echo.

:: Check active processes
echo Process Status:
echo ---------------
tasklist /FI "IMAGENAME eq python.exe" 2>nul | find /I "ai_client" >nul
if %errorlevel%==0 (
    echo [ACTIVE] AI Client processes running
    echo.
    echo Active Client Processes:
    for /f "tokens=1,2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV /NH') do (
        echo   PID %%b - %%a
    )
) else (
    echo [IDLE] No AI Client processes running
)

echo.

:: System resources
echo System Resources:
echo -----------------
echo CPU Usage:
wmic cpu get loadpercentage /value 2>nul | find "LoadPercentage" 2>nul
echo.
echo Memory Usage:
for /f "tokens=4" %%a in ('systeminfo ^| findstr "Available Physical Memory"') do echo Available RAM: %%a

echo.

:: Network status
if not "%SERVER_IP%"=="Not configured" (
    echo Network Status:
    echo ---------------
    echo Testing connection to %SERVER_IP%...
    ping %SERVER_IP% -n 1 -w 2000 >nul 2>&1
    if %errorlevel%==0 (
        echo [✓] Server is reachable
        
        :: Quick API test
        curl -s -m 5 http://%SERVER_IP%:8000/health >nul 2>&1
        if %errorlevel%==0 (
            echo [✓] Server API is responding
        ) else (
            echo [!] Server API not responding
        )
    ) else (
        echo [✗] Server is not reachable
    )
)

echo.

:: Log files
echo Log Information:
echo ----------------
if exist "%CLIENT_PATH%\logs\client.log" (
    echo [✓] Client log file exists
    for /f %%a in ('find /c /v "" "%CLIENT_PATH%\logs\client.log"') do echo     Lines: %%a
    echo     Last modified: 
    dir "%CLIENT_PATH%\logs\client.log" | find "client.log"
) else (
    echo [!] No log file found
)

echo.

:: Quick actions
echo Quick Actions:
echo --------------
echo [K] Kill all Python processes
echo [L] View recent logs  
echo [T] Test connection
echo [R] Return to menu
echo.
set /p monitor_action="Select action [K/L/T/R]: "

if /i "%monitor_action%"=="K" (
    echo Stopping all Python processes...
    taskkill /F /IM python.exe >nul 2>&1
    echo Done.
    timeout /t 2 /nobreak >nul
)
if /i "%monitor_action%"=="L" (
    if exist "%CLIENT_PATH%\logs\client.log" (
        echo.
        echo Recent log entries:
        echo -------------------
        type "%CLIENT_PATH%\logs\client.log" | more
    ) else (
        echo No log file found.
    )
    pause
)
if /i "%monitor_action%"=="T" (
    goto TEST
)

goto MENU

:UPDATE
cls
echo ================================================================================
echo                         UPDATE CLIENT SOFTWARE
echo ================================================================================
echo.

echo Checking for updates...
echo.

echo [1/3] Updating Python packages...
echo --------------------------------
python -m pip install --upgrade pip --quiet
python -m pip install --upgrade pyautogui pillow websocket-client requests keyboard psutil opencv-python --quiet

if errorlevel 1 (
    echo [WARNING] Some packages failed to update
    echo Trying essential packages only...
    python -m pip install --upgrade pyautogui pillow websocket-client requests --quiet
)

echo [OK] Python packages updated

echo.
echo [2/3] Checking configuration...
echo ------------------------------
if exist "%CLIENT_PATH%\client_config.json" (
    echo [OK] Configuration file is current
) else (
    echo [!] Configuration needs update
    echo Creating updated configuration template...
    if exist "%CLIENT_PATH%\server_config.txt" (
        set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
        call :CREATE_CONFIG_FILE
        echo [OK] Configuration updated
    )
)

echo.
echo [3/3] Updating client script...
echo ------------------------------
echo Creating latest version of client script...
call :CREATE_CLIENT_FILE
if exist "%CLIENT_PATH%\ai_client.py" (
    echo [OK] Client script updated to latest version
) else (
    echo [ERROR] Failed to update client script
)

echo.
echo ================================================================================
echo Update completed successfully!
echo ================================================================================
echo.
echo Updated Components:
echo - Python packages (latest versions)
echo - Client script (enhanced features)
echo - Configuration files (if needed)
echo.
echo Restart the client to use the updated version.
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:CONFIG
cls
echo ================================================================================
echo                         CONFIGURATION SETTINGS
echo ================================================================================
echo.

echo Current Configuration:
echo ----------------------
if exist "%CLIENT_PATH%\client_config.json" (
    echo Configuration file: client_config.json
    type "%CLIENT_PATH%\client_config.json"
) else if exist "%CLIENT_PATH%\server_config.txt" (
    echo Configuration file: server_config.txt (legacy)
    set /p SERVER_IP=<"%CLIENT_PATH%\server_config.txt"
    echo Server IP: %SERVER_IP%
) else (
    echo [!] No configuration found
)

echo.
echo Configuration Options:
echo ----------------------
echo [1] Change server IP address
echo [2] Reset to default settings  
echo [3] Create new configuration
echo [4] View current settings
echo [5] Return to menu
echo.
set /p config_choice="Select option [1-5]: "

if "%config_choice%"=="1" (
    set /p NEW_SERVER_IP="Enter new server IP: "
    if exist "%CLIENT_PATH%\client_config.json" (
        echo Updating configuration file...
        call :CREATE_CONFIG_FILE
    ) else (
        echo %NEW_SERVER_IP% > "%CLIENT_PATH%\server_config.txt"
    )
    echo [OK] Server IP updated to: %NEW_SERVER_IP%
    pause
)

if "%config_choice%"=="2" (
    echo Resetting to default configuration...
    if exist "%CLIENT_PATH%\client_config.json" del "%CLIENT_PATH%\client_config.json"
    if exist "%CLIENT_PATH%\server_config.txt" del "%CLIENT_PATH%\server_config.txt"
    echo [OK] Configuration reset. Run SETUP to reconfigure.
    pause
)

if "%config_choice%"=="3" (
    goto SETUP
)

if "%config_choice%"=="4" (
    pause
)

goto MENU

:HELP
cls
echo ================================================================================
echo                            HELP ^& COMMAND GUIDE
echo ================================================================================
echo.
echo GETTING STARTED:
echo ================================================================================
echo 1. Run SETUP to configure the client for your server
echo 2. Use TEST to verify connection to the server
echo 3. Use CONTROL for interactive command sessions
echo 4. Use CONNECT for automatic mode (waits for server commands)
echo.
echo COMMAND EXAMPLES:
echo ================================================================================
echo.
echo 🖥️  System Control:
echo    "open task manager"     - Opens Task Manager
echo    "show desktop"          - Minimizes all windows  
echo    "lock screen"           - Locks the computer
echo    "take screenshot"       - Captures screen
echo.
echo 📁 File Operations:
echo    "open file explorer"    - Opens File Explorer
echo    "create folder Desktop\Test" - Creates a folder
echo    "open notepad"          - Opens Notepad
echo    "list files"            - Shows directory contents
echo.
echo 🌐 Applications:
echo    "open chrome"           - Opens Chrome browser
echo    "go to youtube.com"     - Opens website
echo    "open calculator"       - Opens Calculator
echo    "start word"            - Opens Microsoft Word
echo.
echo ⌨️  Input Automation:
echo    "type hello world"      - Types text
echo    "press enter"           - Presses Enter key
echo    "press ctrl+c"          - Copies selection
echo    "click at 500,300"      - Clicks at coordinates
echo.
echo 🔧 Advanced Commands:
echo    "run ipconfig"          - Shows network info
echo    "check cpu usage"       - Shows system performance
echo    "list running programs" - Shows active processes
echo.
echo CONTROL MODES:
echo ================================================================================
echo.
echo 🔄 AUTO MODE (Option 2):
echo   - Connects and waits for server commands
echo   - Best for remote control scenarios
echo   - Runs continuously until stopped
echo.
echo 💬 INTERACTIVE MODE (Option 4): 
echo   - Direct command input via keyboard
echo   - Type commands and see immediate results
echo   - Good for testing and direct control
echo.
echo 📤 SINGLE COMMAND (Option 5):
echo   - Send one command and return to menu
echo   - Quick execution for specific tasks
echo.
echo SAFETY FEATURES:
echo ================================================================================
echo - Dangerous commands are filtered for safety
echo - All commands are logged for review
echo - Emergency stop with Ctrl+C
echo - Automatic reconnection on connection loss
echo.
echo TROUBLESHOOTING:
echo ================================================================================
echo.
echo ❌ "Connection failed":
echo   - Check server is running
echo   - Verify IP address is correct
echo   - Test with option [3] TEST
echo   - Check firewall settings
echo.
echo ❌ "Python not found":
echo   - Install Python 3.8+ from python.org
echo   - Make sure "Add to PATH" was checked
echo   - Restart command prompt after install
echo.
echo ❌ "Permission denied":
echo   - Run as Administrator
echo   - Check antivirus settings
echo   - Ensure automation is allowed
echo.
echo ❌ "Commands not working":
echo   - Check server logs
echo   - Verify model is loaded on server
echo   - Try simpler commands first
echo.
echo KEYBOARD SHORTCUTS:
echo ================================================================================
echo Ctrl+C          - Emergency stop (works in all modes)
echo ESC             - Cancel current operation  
echo Up/Down Arrows  - Navigate command history (interactive mode)
echo.
echo FILES CREATED:
echo ================================================================================
echo ai_client.py       - Main client script
echo client_config.json - Configuration settings
echo start_client.bat   - Quick startup script
echo logs\client.log    - Activity logs
echo.
echo Press any key to return to menu...
pause >nul
goto MENU

:: ============================================================================
:: HELPER FUNCTIONS  
:: ============================================================================

:CREATE_CONFIG_FILE
if not defined NEW_SERVER_IP (
    if defined SERVER_IP (
        set NEW_SERVER_IP=%SERVER_IP%
    ) else (
        set NEW_SERVER_IP=127.0.0.1
    )
)

(
echo {
echo   "server_ip": "%NEW_SERVER_IP%",
echo   "server_port": 8000,
echo   "websocket_port": 8000,
echo   "auto_reconnect": true,
echo   "max_reconnect_attempts": 5,
echo   "reconnect_delay": 3,
echo   "screenshot_quality": 80,
echo   "safety_mode": true,
echo   "log_commands": true,
echo   "created": "%date% %time%"
echo }
) > "%CLIENT_PATH%\client_config.json"
goto :eof

:CREATE_STARTUP_SCRIPT
echo Creating startup script...
(
echo @echo off
echo title AI Client - Quick Start
echo cd /d "%CLIENT_PATH%"
echo.
echo echo Starting AI Client...
echo echo.
echo python ai_client.py auto
echo.
echo echo.
echo echo Client stopped. Press any key to close...
echo pause ^>nul
) > "%CLIENT_PATH%\start_client.bat"
goto :eof

:CREATE_CLIENT_FILE
echo Creating enhanced AI client script...
(
echo import asyncio
echo import websocket
echo import json
echo import sys
echo import os
echo import time
echo import threading
echo import logging
echo import subprocess
echo import base64
echo import io
echo from datetime import datetime
echo from pathlib import Path
echo.
echo # Enhanced error handling for imports
echo missing_modules = []
echo.
echo try:
echo     import pyautogui
echo     # Configure pyautogui safety
echo     pyautogui.FAILSAFE = True
echo     pyautogui.PAUSE = 0.1
echo except ImportError:
echo     missing_modules.append('pyautogui'^)
echo     pyautogui = None
echo.
echo try:
echo     from PIL import Image, ImageGrab
echo except ImportError:
echo     missing_modules.append('pillow'^)
echo     ImageGrab = None
echo.
echo try:
echo     import requests
echo except ImportError:
echo     missing_modules.append('requests'^)
echo     requests = None
echo.
echo try:
echo     import keyboard
echo except ImportError:
echo     keyboard = None
echo.
echo try:
echo     import psutil
echo except ImportError:
echo     psutil = None
echo.
echo # Setup logging
echo os.makedirs('logs', exist_ok=True^)
echo logging.basicConfig(
echo     level=logging.INFO,
echo     format='%%(asctime^)s - %%(name^)s - %%(levelname^)s - %%(message^)s',
echo     handlers=[
echo         logging.FileHandler('logs/client.log'^),
echo         logging.StreamHandler(^)
echo     ]
echo ^)
echo logger = logging.getLogger(__name__^)
echo.
echo if missing_modules:
echo     logger.warning(f"Missing optional modules: {', '.join(missing_modules^)}"^)
echo     print(f"⚠️  Missing modules: {', '.join(missing_modules^)}"^)
echo     print("Some features may not work. Run 'pip install' to install missing modules."^)
echo     print("^")
echo.
echo class SafeExecutor:
echo     """Safe command execution with filtering"""
echo     
echo     DANGEROUS_COMMANDS = [
echo         'format',
echo         'del *',
echo         'rmdir /s',
echo         'rm -rf',
echo         'shutdown /s',
echo         'restart',
echo         'reboot',
echo         'diskpart',
echo         'fdisk',
echo         'mkfs'
echo     ]
echo     
echo     @staticmethod
echo     def is_safe_command(command):
echo         """Check if command is safe to execute"""
echo         command_lower = command.lower(^)
echo         return not any(dangerous in command_lower for dangerous in SafeExecutor.DANGEROUS_COMMANDS^)
echo     
echo     @staticmethod
echo     def sanitize_command(command):
echo         """Sanitize command for safe execution"""
echo         # Remove potentially dangerous characters
echo         dangerous_chars = ['&', '|', ';', '>', '<', '`']
echo         for char in dangerous_chars:
echo             command = command.replace(char, ' '^)
echo         return command.strip(^)
echo.
echo class RemoteExecutor:
echo     """Enhanced remote command executor"""
echo     
echo     def __init__(self^):
echo         self.running = True
echo         self.config = self.load_config(^)
echo         self.reconnect_count = 0
echo         self.max_reconnects = self.config.get('max_reconnect_attempts', 5^)
echo         self.reconnect_delay = self.config.get('reconnect_delay', 3^)
echo         self.ws = None
echo         self.command_history = []
echo         
echo         logger.info("Remote Executor initialized"^)
echo         
echo         # Configure pyautogui if available
echo         if pyautogui:
echo             pyautogui.FAILSAFE = not self.config.get('disable_failsafe', False^)
echo             logger.info(f"PyAutoGUI configured - Failsafe: {pyautogui.FAILSAFE}"^)
echo.
echo     def load_config(self^):
echo         """Load configuration from file"""
echo         config_file = 'client_config.json'
echo         legacy_config = 'server_config.txt'
echo         
echo         try:
echo             if os.path.exists(config_file^):
echo                 with open(config_file, 'r'^) as f:
echo                     config = json.load(f^)
echo                 logger.info(f"Configuration loaded from {config_file}"^)
echo                 return config
echo             elif os.path.exists(legacy_config^):
echo                 with open(legacy_config, 'r'^) as f:
echo                     server_ip = f.read(^).strip(^)
echo                 config = {
echo                     'server_ip': server_ip,
echo                     'server_port': 8000,
echo                     'auto_reconnect': True,
echo                     'safety_mode': True
echo                 }
echo                 logger.info(f"Legacy configuration loaded from {legacy_config}"^)
echo                 return config
echo             else:
echo                 server_ip = input("Enter Server IP: "^)
echo                 config = {
echo                     'server_ip': server_ip,
echo                     'server_port': 8000,
echo                     'auto_reconnect': True,
echo                     'safety_mode': True
echo                 }
echo                 return config
echo         except Exception as e:
echo             logger.error(f"Error loading configuration: {e}"^)
echo             return {'server_ip': '127.0.0.1', 'server_port': 8000}
echo.
echo     def get_server_url(self^):
echo         """Get WebSocket server URL"""
echo         server_ip = self.config.get('server_ip', '127.0.0.1'^)
echo         server_port = self.config.get('websocket_port', 8000^)
echo         return f"ws://{server_ip}:{server_port}/ws"
echo.
echo     def connect(self^):
echo         """Connect to server with retry logic"""
echo         server_url = self.get_server_url(^)
echo         
echo         try:
echo             logger.info(f"Connecting to {server_url}..."^)
echo             self.ws = websocket.create_connection(server_url, timeout=10^)
echo             logger.info(f"✓ Connected to server: {self.config['server_ip']}"^)
echo             print(f"✅ Connected to server: {self.config['server_ip']}"^)
echo             self.reconnect_count = 0
echo             return True
echo             
echo         except Exception as e:
echo             logger.error(f"Connection failed: {e}"^)
echo             print(f"❌ Connection failed: {e}"^)
echo             
echo             if self.config.get('auto_reconnect', True^) and self.reconnect_count < self.max_reconnects:
echo                 self.reconnect_count += 1
echo                 logger.info(f"Retry {self.reconnect_count}/{self.max_reconnects} in {self.reconnect_delay} seconds..."^)
echo                 print(f"🔄 Retry {self.reconnect_count}/{self.max_reconnects} in {self.reconnect_delay} seconds..."^)
echo                 time.sleep(self.reconnect_delay^)
echo                 return self.connect(^)
echo             
echo             return False
echo.
echo     def disconnect(self^):
echo         """Safely disconnect from server"""
echo         if self.ws:
echo             try:
echo                 self.ws.close(^)
echo                 logger.info("Disconnected from server"^)
echo             except:
echo                 pass
echo             finally:
echo                 self.ws = None
echo.
echo     def get_screenshot(self^):
echo         """Capture screenshot and encode as base64"""
echo         try:
echo             if not ImageGrab:
echo                 return None
echo                 
echo             screenshot = ImageGrab.grab(^)
echo             
echo             # Resize for efficiency
echo             quality = self.config.get('screenshot_quality', 80^)
echo             if quality < 100:
echo                 width, height = screenshot.size
echo                 new_width = int(width * (quality / 100^)^)
echo                 new_height = int(height * (quality / 100^)^)
echo                 screenshot = screenshot.resize((new_width, new_height^), Image.Resampling.LANCZOS^)
echo             
echo             buffered = io.BytesIO(^)
echo             screenshot.save(buffered, format="PNG"^)
echo             return base64.b64encode(buffered.getvalue(^)^).decode(^)
echo             
echo         except Exception as e:
echo             logger.error(f"Screenshot error: {e}"^)
echo             return None
echo.
echo     def get_system_info(self^):
echo         """Get basic system information"""
echo         info = {
echo             'os': os.name,
echo             'platform': sys.platform,
echo             'python_version': sys.version,
echo             'timestamp': datetime.now(^).isoformat(^)
echo         }
echo         
echo         if psutil:
echo             try:
echo                 info.update({
echo                     'cpu_percent': psutil.cpu_percent(^),
echo                     'memory_percent': psutil.virtual_memory(^).percent,
echo                     'disk_usage': psutil.disk_usage('/'^).percent if os.name != 'nt' else psutil.disk_usage('C:\\'^).percent
echo                 }^)
echo             except:
echo                 pass
echo                 
echo         return info
echo.
echo     def execute_action(self, action^):
echo         """Execute received command with enhanced safety"""
echo         action_type = action.get('type'^)
echo         code = action.get('code', ''^)
echo         
echo         if not code:
echo             return "No command provided"
echo         
echo         logger.info(f"Executing {action_type}: {code[:50]}..."^)
echo         self.command_history.append({
echo             'timestamp': datetime.now(^).isoformat(^),
echo             'type': action_type,
echo             'code': code[:100] + ('...' if len(code^) > 100 else ''^ )
echo         }^)
echo         
echo         try:
echo             if action_type == 'command':
echo                 return self._execute_system_command(code^)
echo             elif action_type == 'python':
echo                 return self._execute_python_code(code^)
echo             elif action_type == 'click':
echo                 return self._execute_click(code^)
echo             elif action_type == 'type':
echo                 return self._execute_type(code^)
echo             elif action_type == 'hotkey':
echo                 return self._execute_hotkey(code^)
echo             elif action_type in ['execute', 'auto']:
echo                 # Auto-detect command type
echo                 return self._auto_execute(code^)
echo             else:
echo                 return f"Unknown action type: {action_type}"
echo                 
echo         except Exception as e:
echo             error_msg = f"Execution error: {e}"
echo             logger.error(error_msg^)
echo             return error_msg
echo.
echo     def _execute_system_command(self, command^):
echo         """Execute system command safely"""
echo         if self.config.get('safety_mode', True^):
echo             if not SafeExecutor.is_safe_command(command^):
echo                 return f"Command blocked for safety: {command}"
echo             command = SafeExecutor.sanitize_command(command^)
echo         
echo         try:
echo             result = subprocess.run(
echo                 command, 
echo                 shell=True, 
echo                 capture_output=True, 
echo                 text=True, 
echo                 timeout=30
echo             ^)
echo             
echo             output = result.stdout
echo             if result.stderr:
echo                 output += f"\nError: {result.stderr}"
echo                 
echo             logger.info(f"System command executed: {command}"^)
echo             return output or "Command executed successfully"
echo             
echo         except subprocess.TimeoutExpired:
echo             return "Command timed out (30s limit^)"
echo         except Exception as e:
echo             return f"Command execution failed: {e}"
echo.
echo     def _execute_python_code(self, code^):
echo         """Execute Python code safely"""
echo         # Basic safety checks
echo         dangerous_imports = ['os.system', 'subprocess', '__import__', 'exec', 'eval']
echo         if any(dangerous in code for dangerous in dangerous_imports^):
echo             return "Python code contains potentially dangerous functions"
echo         
echo         try:
echo             # Create restricted environment
echo             restricted_globals = {
echo                 '__builtins__': {
echo                     'print': print,
echo                     'len': len,
echo                     'str': str,
echo                     'int': int,
echo                     'float': float,
echo                     'range': range
echo                 }
echo             }
echo             
echo             # Add available modules
echo             if pyautogui:
echo                 restricted_globals['pyautogui'] = pyautogui
echo                 
echo             # Capture output
echo             old_stdout = sys.stdout
echo             sys.stdout = io.StringIO(^)
echo             
echo             exec(code, restricted_globals^)
echo             
echo             output = sys.stdout.getvalue(^)
echo             sys.stdout = old_stdout
echo             
echo             logger.info("Python code executed successfully"^)
echo             return output or "Python code executed"
echo             
echo         except Exception as e:
echo             if 'old_stdout' in locals(^):
echo                 sys.stdout = old_stdout
echo             return f"Python execution error: {e}"
echo.
echo     def _execute_click(self, code^):
echo         """Execute mouse click"""
echo         if not pyautogui:
echo             return "PyAutoGUI not available for click actions"
echo         
echo         try:
echo             # Parse coordinates
echo             coords = code.replace('click', ''^ ).replace('(', ''^ ).replace(')', ''^ ).split(','^ )
echo             x = int(coords[0].strip(^)^)
echo             y = int(coords[1].strip(^)^)
echo             
echo             pyautogui.click(x, y^)
echo             logger.info(f"Clicked at ({x}, {y}^)"^)
echo             return f"Clicked at position ({x}, {y}^)"
echo             
echo         except Exception as e:
echo             return f"Click execution failed: {e}"
echo.
echo     def _execute_type(self, code^):
echo         """Execute typing action"""
echo         if not pyautogui:
echo             return "PyAutoGUI not available for typing"
echo         
echo         try:
echo             text = code.replace('type ', ''^ ).strip(^)
echo             pyautogui.write(text^)
echo             logger.info(f"Typed text: {text[:30]}..."^)
echo             return f"Typed: {text}"
echo             
echo         except Exception as e:
echo             return f"Typing failed: {e}"
echo.
echo     def _execute_hotkey(self, code^):
echo         """Execute keyboard shortcut"""
echo         if not pyautogui:
echo             return "PyAutoGUI not available for hotkeys"
echo         
echo         try:
echo             keys = code.replace('hotkey ', ''^ ).replace('press ', ''^ ).split('+'^ )
echo             keys = [key.strip(^) for key in keys]
echo             
echo             pyautogui.hotkey(*keys^)
echo             logger.info(f"Executed hotkey: {'+'.join(keys^)}"^)
echo             return f"Executed hotkey: {'+'.join(keys^)}"
echo             
echo         except Exception as e:
echo             return f"Hotkey execution failed: {e}"
echo.
echo     def _auto_execute(self, code^):
echo         """Auto-detect and execute command"""
echo         code_lower = code.lower(^)
echo         
echo         # GUI automation patterns
echo         if 'click' in code_lower and any(c.isdigit(^) for c in code^):
echo             return self._execute_click(code^)
echo         elif code_lower.startswith(('type ', 'write '^)^):
echo             return self._execute_type(code^)
echo         elif 'press ' in code_lower or '+' in code:
echo             return self._execute_hotkey(code^)
echo         elif code_lower.startswith(('import ', 'print(', 'pyautogui.'^)^):
echo             return self._execute_python_code(code^)
echo         else:
echo             # Default to system command
echo             return self._execute_system_command(code^)
echo.
echo     def send_message(self, message^):
echo         """Send message to server"""
echo         if not self.ws:
echo             return False
echo         
echo         try:
echo             self.ws.send(json.dumps(message^)^)
echo             return True
echo         except Exception as e:
echo             logger.error(f"Failed to send message: {e}"^)
echo             return False
echo.
echo     def receive_message(self^):
echo         """Receive message from server"""
echo         if not self.ws:
echo             return None
echo         
echo         try:
echo             message = self.ws.recv(^)
echo             return json.loads(message^)
echo         except Exception as e:
echo             logger.error(f"Failed to receive message: {e}"^)
echo             return None
echo.
echo     def run_auto_mode(self^):
echo         """Run in automatic mode - wait for commands"""
echo         if not self.connect(^):
echo             return
echo         
echo         print("\n" + "="*60^)
echo         print("🤖 AI CLIENT - AUTOMATIC MODE"^)
echo         print("="*60^)
echo         print("✅ Connected and ready to receive commands"^)
echo         print("🎯 Server:", self.config['server_ip']^)
echo         print("⚡ Press Ctrl+C to stop"^)
echo         print("="*60^)
echo         print("^")
echo         
echo         try:
echo             while self.running:
echo                 message = self.receive_message(^)
echo                 if not message:
echo                     continue
echo                 
echo                 message_type = message.get('type'^)
echo                 
echo                 if message_type == 'command_result':
echo                     # Handle command from server
echo                     result_data = message.get('result', {}^)
echo                     actions = result_data.get('actions', []^)
echo                     
echo                     if actions:
echo                         print(f"📨 Received {len(actions^)} action(s^) from server"^)
echo                         for i, action in enumerate(actions, 1^):
echo                             print(f"   [{i}] {action.get('type', 'unknown'^)}: {action.get('code', 'N/A'^)[:50]}..."^)
echo                             result = self.execute_action(action^)
echo                             print(f"       ✓ {result[:100]}..."^)
echo                 
echo                 elif message_type == 'ping':
echo                     # Respond to ping
echo                     self.send_message({'type': 'pong'}^)
echo                 
echo                 elif message_type == 'connection_established':
echo                     print("🔗 Server connection established"^)
echo                 
echo                 else:
echo                     print(f"📩 Received: {message_type}"^)
echo                 
echo         except KeyboardInterrupt:
echo             print("\n🛑 Stopping automatic mode..."^)
echo         except Exception as e:
echo             logger.error(f"Auto mode error: {e}"^)
echo             print(f"❌ Error in auto mode: {e}"^)
echo         finally:
echo             self.disconnect(^)
echo             print("👋 Disconnected from server"^)
echo.
echo     def run_interactive_mode(self^):
echo         """Run in interactive mode"""
echo         if not self.connect(^):
echo             return
echo         
echo         print("\n" + "="*60^)
echo         print("💬 AI CLIENT - INTERACTIVE MODE"^)  
echo         print("="*60^)
echo         print("✅ Connected to server:", self.config['server_ip']^)
echo         print("💡 Type commands naturally (e.g., 'open chrome'^)"^)
echo         print("🚪 Type 'exit' to quit, 'help' for commands"^)
echo         print("="*60^)
echo         print("^")
echo         
echo         try:
echo             while self.running:
echo                 try:
echo                     command = input("Command> "^).strip(^)
echo                     
echo                     if not command:
echo                         continue
echo                     
echo                     if command.lower(^) in ['exit', 'quit', 'q']:
echo                         print("👋 Goodbye!"^)
echo                         break
echo                     
echo                     if command.lower(^) == 'help':
echo                         self._show_help(^)
echo                         continue
echo                     
echo                     if command.lower(^) == 'status':
echo                         self._show_status(^)
echo                         continue
echo                     
echo                     # Send command to server for processing
echo                     message = {
echo                         'type': 'command',
echo                         'command': command,
echo                         'context': {
echo                             'mode': 'interactive',
echo                             'system_info': self.get_system_info(^)
echo                         }
echo                     }
echo                     
echo                     # Add screenshot if available
echo                     screenshot = self.get_screenshot(^)
echo                     if screenshot:
echo                         message['screenshot'] = screenshot
echo                     
echo                     print(f"📤 Sending command: {command}"^)
echo                     
echo                     if not self.send_message(message^):
echo                         print("❌ Failed to send command"^)
echo                         continue
echo                     
echo                     # Wait for response
echo                     response = self.receive_message(^)
echo                     if not response:
echo                         print("❌ No response from server"^)
echo                         continue
echo                     
echo                     # Process response
echo                     if response.get('type'^) == 'command_result':
echo                         result = response.get('result', {}^)
echo                         actions = result.get('actions', []^)
echo                         
echo                         if actions:
echo                             print(f"📨 Received {len(actions^)} action(s^):"^)
echo                             for i, action in enumerate(actions, 1^):
echo                                 print(f"   [{i}] Executing: {action.get('type'^)}"^)
echo                                 exec_result = self.execute_action(action^)
echo                                 print(f"       ✓ {exec_result}"^)
echo                         else:
echo                             print("ℹ️  No actions to execute"^)
echo                     else:
echo                         print(f"📩 Server response: {response}"^)
echo                     
echo                     print("^")  # Add blank line for readability
echo                     
echo                 except KeyboardInterrupt:
echo                     print("\n🛑 Use 'exit' to quit properly"^)
echo                 except EOFError:
echo                     print("\n👋 Session ended"^)
echo                     break
echo                 except Exception as e:
echo                     logger.error(f"Interactive mode error: {e}"^)
echo                     print(f"❌ Error: {e}"^)
echo                     
echo         finally:
echo             self.disconnect(^)
echo             print("👋 Disconnected from server"^)
echo.
echo     def send_single_command(self, command^):
echo         """Send a single command and exit"""
echo         if not self.connect(^):
echo             return
echo         
echo         try:
echo             print(f"📤 Sending command: {command}"^)
echo             
echo             message = {
echo                 'type': 'command',
echo                 'command': command,
echo                 'context': {
echo                     'mode': 'single',
echo                     'system_info': self.get_system_info(^)
echo                 }
echo             }
echo             
echo             # Add screenshot if available
echo             screenshot = self.get_screenshot(^)
echo             if screenshot:
echo                 message['screenshot'] = screenshot
echo             
echo             if not self.send_message(message^):
echo                 print("❌ Failed to send command"^)
echo                 return
echo             
echo             # Wait for response
echo             response = self.receive_message(^)
echo             if not response:
echo                 print("❌ No response from server"^)
echo                 return
echo             
echo             # Execute actions
echo             if response.get('type'^) == 'command_result':
echo                 result = response.get('result', {}^)
echo                 actions = result.get('actions', []^)
echo                 
echo                 if actions:
echo                     print(f"📨 Executing {len(actions^)} action(s^):"^)
echo                     for i, action in enumerate(actions, 1^):
echo                         print(f"   [{i}] {action.get('type'^)}: {action.get('code', ''^ )[:50]}"^)
echo                         result = self.execute_action(action^)
echo                         print(f"       ✓ {result}"^)
echo                 else:
echo                     print("ℹ️  No actions to execute"^)
echo             
echo         except Exception as e:
echo             logger.error(f"Single command error: {e}"^)
echo             print(f"❌ Error: {e}"^)
echo         finally:
echo             self.disconnect(^)
echo.
echo     def _show_help(self^):
echo         """Show help information"""
echo         print("^")
echo         print("📖 HELP - Available Commands:"^)
echo         print("="*40^)
echo         print("System:")^)
echo         print("  • open chrome"^)
echo         print("  • take screenshot"^)
echo         print("  • show desktop"^)
echo         print("  • open task manager"^)
echo         print("^")
echo         print("Input:"^)
echo         print("  • type hello world"^)
echo         print("  • press enter"^)
echo         print("  • press ctrl+c"^)
echo         print("  • click at 500,300"^)
echo         print("^")
echo         print("Special:"^)
echo         print("  • help    - Show this help"^)
echo         print("  • status  - Show connection status"^)
echo         print("  • exit    - Quit interactive mode"^)
echo         print("="*40^)
echo         print("^")
echo.
echo     def _show_status(self^):
echo         """Show current status"""
echo         print("^")
echo         print("📊 STATUS:"^)
echo         print("="*30^)
echo         print(f"Server: {self.config['server_ip']}"^)
echo         print(f"Connected: {'✅' if self.ws else '❌'}"^)
echo         print(f"Commands executed: {len(self.command_history^)}"^)
echo         print(f"Safety mode: {'✅' if self.config.get('safety_mode'^) else '❌'}"^)
echo         
echo         if self.command_history:
echo             print(f"Last command: {self.command_history[-1]['type']} at {self.command_history[-1]['timestamp']}"^)
echo         
echo         print("="*30^)
echo         print("^")
echo.
echo def main(^):
echo     """Main function"""
echo     print("🤖 AI Remote Client v2.0"^)
echo     print("========================"^)
echo     
echo     if missing_modules:
echo         print(f"⚠️  Warning: Missing modules: {', '.join(missing_modules^)}"^)
echo         print("   Install with: pip install " + " ".join(missing_modules^)^)
echo         print("^")
echo     
echo     executor = RemoteExecutor(^)
echo     
echo     # Handle command line arguments
echo     if len(sys.argv^) > 1:
echo         mode = sys.argv[1].lower(^)
echo         
echo         if mode == 'auto':
echo             executor.run_auto_mode(^)
echo         elif mode == 'interactive':
echo             executor.run_interactive_mode(^)
echo         elif mode == 'command' and len(sys.argv^) > 2:
echo             command = ' '.join(sys.argv[2:]^)
echo             executor.send_single_command(command^)
echo         else:
echo             print("Usage:"^)
echo             print("  python ai_client.py auto         - Automatic mode"^)
echo             print("  python ai_client.py interactive  - Interactive mode"^)
echo             print("  python ai_client.py command 'cmd' - Single command"^)
echo     else:
echo         # Default to auto mode
echo         executor.run_auto_mode(^)
echo.
echo if __name__ == "__main__":
echo     try:
echo         main(^)
echo     except KeyboardInterrupt:
echo         print("\n👋 Client stopped by user"^)
echo     except Exception as e:
echo         logger.error(f"Fatal error: {e}"^)
echo         print(f"💥 Fatal error: {e}"^)
echo     finally:
echo         print("🔚 Client shutdown complete"^)