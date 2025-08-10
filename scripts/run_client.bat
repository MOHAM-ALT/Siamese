@echo off
setlocal enabledelayedexpansion
title AI Control Client Launcher v3.0

:: إعداد متغيرات اللوج
set "DEBUG_LOG=logs\run_client_debug.log"
set "ERROR_LOG=logs\run_client_errors.log"

:: إنشاء مجلد اللوج
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1
del "%ERROR_LOG%" >nul 2>&1

:: بدء اللوج
echo [%date% %time%] Starting AI Control Client v3.0 > "%DEBUG_LOG%"
echo [%date% %time%] Starting AI Control Client v3.0 > "%ERROR_LOG%"

:: تغيير إلى المجلد الجذر
echo [%date% %time%] Changing to project root directory... >> "%DEBUG_LOG%"
cd /d "%~dp0.." 2>> "%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to change to project directory >> "%ERROR_LOG%"
    goto :error_exit
)

echo [%date% %time%] Working directory: %CD% >> "%DEBUG_LOG%"

:: ============================================================================
:: فحص البيئة الافتراضية للعميل
:: ============================================================================
echo [%date% %time%] Checking client virtual environment... >> "%DEBUG_LOG%"

if not exist "venv_client\Scripts\activate.bat" (
    echo [ERROR] Client virtual environment not found >> "%ERROR_LOG%"
    cls
    echo ==================================================================================
    echo                              ❌ CLIENT SETUP ERROR
    echo ==================================================================================
    echo.
    echo Client virtual environment not found!
    echo.
    echo Please run the installer first: scripts\install.bat
    echo.
    pause
    goto :error_exit
)

echo [%date% %time%] Client virtual environment found >> "%DEBUG_LOG%"

:: تفعيل البيئة
echo [%date% %time%] Activating client environment... >> "%DEBUG_LOG%"
call venv_client\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to activate client environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [%date% %time%] Client environment activated >> "%DEBUG_LOG%"

:: ============================================================================
:: الواجهة الرئيسية للعميل
:: ============================================================================
:MAIN_MENU
cls
echo ==================================================================================
echo                       🤖 AI CONTROL CLIENT v3.0
echo ==================================================================================
echo.
echo 🎯 Remote AI Computer Control System
echo 📝 Debug logs: %DEBUG_LOG%
echo.

:: عرض حالة الاتصال إذا كانت متاحة
if exist "client_config.json" (
    for /f "tokens=*" %%i in ('python -c "import json; data=json.load(open('client_config.json')); print(data.get('server_ip', 'Not configured'))"') do (
        echo 🌐 Configured Server: %%i
    )
) else (
    echo ⚠️  No server configured - will use defaults
)

echo.
echo ================================================================================
echo                                CLIENT MODES
echo ================================================================================
echo.
echo    [1] 🔄 Automatic Mode
echo        Connect and wait for server commands automatically
echo        Best for: Remote control scenarios, background operation
echo.
echo    [2] 💬 Interactive Mode  
echo        Send commands directly through chat interface
echo        Best for: Testing commands, direct control
echo.
echo    [3] 📤 Single Command
echo        Send one specific command and exit
echo        Best for: Quick tasks, scripting
echo.
echo    [4] ⚙️  Configuration
echo        Configure server connection and client settings
echo        
echo    [5] 📊 Connection Test
echo        Test connection to the server and show diagnostics
echo.
echo    [6] 📖 Help ^& Examples
echo        Show command examples and usage guide
echo.
echo    [0] 🚪 Exit
echo.
echo ================================================================================
set /p choice="Select a mode [0-6]: "

if "%choice%"=="1" goto :AUTO_MODE
if "%choice%"=="2" goto :INTERACTIVE_MODE
if "%choice%"=="3" goto :SINGLE_COMMAND
if "%choice%"=="4" goto :CONFIGURATION
if "%choice%"=="5" goto :CONNECTION_TEST
if "%choice%"=="6" goto :HELP
if "%choice%"=="0" goto :EXIT

echo.
echo ❌ Invalid option. Please select 0-6.
timeout /t 2 /nobreak >nul
goto :MAIN_MENU

:: ============================================================================
:: الوضع التلقائي
:: ============================================================================
:AUTO_MODE
cls
echo ==================================================================================
echo                            🔄 AUTOMATIC MODE
echo ==================================================================================
echo.
echo This mode will:
echo ✅ Connect to the AI server automatically
echo ✅ Wait for commands from the server
echo ✅ Execute received commands silently
echo ✅ Reconnect automatically if connection drops
echo.
echo 🔧 Controls:
echo    - Press Ctrl+C to stop
echo    - Commands will be executed automatically
echo    - Status updates will be shown below
echo.
echo Press any key to start automatic mode or Ctrl+C to cancel...
pause >nul

echo.
echo [%date% %time%] Starting automatic mode >> "%DEBUG_LOG%"
echo Starting automatic mode...

python -m src.client.main auto >> "%DEBUG_LOG%" 2>> "%ERROR_LOG%"
set "CLIENT_EXIT_CODE=%errorlevel%"

if %CLIENT_EXIT_CODE% neq 0 (
    echo.
    echo ❌ Automatic mode ended with error code: %CLIENT_EXIT_CODE%
    echo    Check %DEBUG_LOG% for details
) else (
    echo.
    echo ✅ Automatic mode ended normally
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :MAIN_MENU

:: ============================================================================
:: الوضع التفاعلي
:: ============================================================================
:INTERACTIVE_MODE
cls
echo ==================================================================================
echo                           💬 INTERACTIVE MODE
echo ==================================================================================
echo.
echo This mode allows you to:
echo ✅ Send commands directly to the AI server
echo ✅ See immediate responses and execution results
echo ✅ Test different command types interactively
echo ✅ Get real-time feedback
echo.
echo 📝 Example Commands:
echo    • "open chrome" - Opens Chrome browser
echo    • "take screenshot" - Captures screen
echo    • "open notepad" - Opens Notepad
echo    • "system info" - Shows system information
echo    • "exit" - End interactive session
echo.
echo Press any key to start interactive mode or Ctrl+C to cancel...
pause >nul

echo.
echo [%date% %time%] Starting interactive mode >> "%DEBUG_LOG%"
echo Starting interactive mode...

python -m src.client.main interactive >> "%DEBUG_LOG%" 2>> "%ERROR_LOG%"
set "CLIENT_EXIT_CODE=%errorlevel%"

if %CLIENT_EXIT_CODE% neq 0 (
    echo.
    echo ❌ Interactive mode ended with error code: %CLIENT_EXIT_CODE%
    echo    Check %DEBUG_LOG% for details
) else (
    echo.
    echo ✅ Interactive mode ended normally
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :MAIN_MENU

:: ============================================================================
:: أمر واحد
:: ============================================================================
:SINGLE_COMMAND
cls
echo ==================================================================================
echo                            📤 SINGLE COMMAND MODE
echo ==================================================================================
echo.
echo Send one specific command to the server and return to menu.
echo.
echo 💡 Popular Commands:
echo    • open chrome          • take screenshot
echo    • open notepad         • system info
echo    • open calculator      • list files
echo    • open file explorer   • network info
echo.
set /p cmd_string="Enter command to send (or 'back' to return): "

if /i "%cmd_string%"=="back" goto :MAIN_MENU
if "%cmd_string%"=="" (
    echo.
    echo ❌ No command entered.
    timeout /t 2 /nobreak >nul
    goto :SINGLE_COMMAND
)

echo.
echo [%date% %time%] Sending single command: %cmd_string% >> "%DEBUG_LOG%"
echo Sending command: %cmd_string%
echo.

python -m src.client.main command "%cmd_string%" >> "%DEBUG_LOG%" 2>> "%ERROR_LOG%"
set "CLIENT_EXIT_CODE=%errorlevel%"

if %CLIENT_EXIT_CODE% neq 0 (
    echo ❌ Command failed with error code: %CLIENT_EXIT_CODE%
    echo    Check %DEBUG_LOG% for details
) else (
    echo ✅ Command completed successfully
)

echo.
echo Press any key to return to main menu...
pause >nul
goto :MAIN_MENU

:: ============================================================================
:: التكوين
:: ============================================================================
:CONFIGURATION
cls
echo ==================================================================================
echo                            ⚙️ CLIENT CONFIGURATION
echo ==================================================================================
echo.

if exist "client_config.json" (
    echo Current Configuration:
    echo ----------------------
    type "client_config.json"
    echo.
) else (
    echo No configuration file found. Will create default.
    echo.
)

echo Configuration Options:
echo ----------------------
echo [1] Change server IP address
echo [2] Change server port
echo [3] Reset to defaults
echo [4] View current settings
echo [5] Test current configuration
echo [0] Return to main menu
echo.
set /p config_choice="Select option [0-5]: "

if "%config_choice%"=="1" (
    set /p new_ip="Enter new server IP address: "
    if not "!new_ip!"=="" (
        python -c "
import json
try:
    with open('client_config.json', 'r') as f:
        config = json.load(f)
except:
    config = {'server_ip': '127.0.0.1', 'server_port': 8000, 'websocket_port': 8000, 'auto_reconnect': True, 'max_reconnect_attempts': 5, 'reconnect_delay': 3, 'screenshot_quality': 80, 'safety_mode': True, 'log_commands': True}
config['server_ip'] = '!new_ip!'
with open('client_config.json', 'w') as f:
    json.dump(config, f, indent=2)
print('✅ Server IP updated to: !new_ip!')
"
        echo [%date% %time%] Server IP updated to: !new_ip! >> "%DEBUG_LOG%"
    )
    timeout /t 2 /nobreak >nul
)

if "%config_choice%"=="2" (
    set /p new_port="Enter new server port: "
    if not "!new_port!"=="" (
        python -c "
import json
try:
    with open('client_config.json', 'r') as f:
        config = json.load(f)
except:
    config = {'server_ip': '127.0.0.1', 'server_port': 8000, 'websocket_port': 8000, 'auto_reconnect': True, 'max_reconnect_attempts': 5, 'reconnect_delay': 3, 'screenshot_quality': 80, 'safety_mode': True, 'log_commands': True}
config['server_port'] = int('!new_port!')
config['websocket_port'] = int('!new_port!')
with open('client_config.json', 'w') as f:
    json.dump(config, f, indent=2)
print('✅ Server port updated to: !new_port!')
"
        echo [%date% %time%] Server port updated to: !new_port! >> "%DEBUG_LOG%"
    )
    timeout /t 2 /nobreak >nul
)

if "%config_choice%"=="3" (
    echo Creating default configuration...
    python -c "
import json
config = {
    'server_ip': '127.0.0.1',
    'server_port': 8000,
    'websocket_port': 8000,
    'auto_reconnect': True,
    'max_reconnect_attempts': 5,
    'reconnect_delay': 3,
    'screenshot_quality': 80,
    'safety_mode': True,
    'log_commands': True
}
with open('client_config.json', 'w') as f:
    json.dump(config, f, indent=2)
print('✅ Configuration reset to defaults')
"
    echo [%date% %time%] Configuration reset to defaults >> "%DEBUG_LOG%"
    timeout /t 2 /nobreak >nul
)

if "%config_choice%"=="4" (
    timeout /t 3 /nobreak >nul
)

if "%config_choice%"=="5" (
    echo Testing configuration...
    python -c "
import json
try:
    with open('client_config.json', 'r') as f:
        config = json.load(f)
    print(f'🌐 Server: {config[\"server_ip\"]}:{config[\"server_port\"]}')
    print(f'🔌 WebSocket: ws://{config[\"server_ip\"]}:{config[\"websocket_port\"]}/ws')
    print(f'🔄 Auto-reconnect: {config[\"auto_reconnect\"]}')
    print(f'🛡️  Safety mode: {config[\"safety_mode\"]}')
except Exception as e:
    print(f'❌ Error reading config: {e}')
"
    echo.
    echo Press any key to continue...
    pause >nul
)

if "%config_choice%"=="0" goto :MAIN_MENU

goto :CONFIGURATION

:: ============================================================================
:: اختبار الاتصال
:: ============================================================================
:CONNECTION_TEST
cls
echo ==================================================================================
echo                            📊 CONNECTION TEST
echo ==================================================================================
echo.

if exist "client_config.json" (
    for /f "tokens=*" %%i in ('python -c "import json; config=json.load(open('client_config.json')); print(f\"{config['server_ip']}:{config['server_port']}\")"') do (
        set "SERVER_ADDRESS=%%i"
    )
) else (
    set "SERVER_ADDRESS=127.0.0.1:8000"
)

echo Testing connection to: %SERVER_ADDRESS%
echo.
echo [%date% %time%] Testing connection to: %SERVER_ADDRESS% >> "%DEBUG_LOG%"

:: اختبار شبكة أساسي
for /f "tokens=1 delims=:" %%i in ("%SERVER_ADDRESS%") do set "SERVER_IP=%%i"
echo [Test 1/4] Basic network connectivity...
ping %SERVER_IP% -n 2 -w 2000 >nul 2>&1
if %errorlevel%==0 (
    echo ✅ Server is reachable via ping
) else (
    echo ❌ Server is not responding to ping
    echo    ^(This might be normal due to firewall settings^)
)

:: اختبار HTTP
echo [Test 2/4] HTTP server availability...
python -c "
import requests
try:
    response = requests.get('http://%SERVER_ADDRESS%/health', timeout=5)
    if response.status_code == 200:
        print('✅ HTTP server is responding')
    else:
        print(f'⚠️  HTTP server responded with code: {response.status_code}')
except Exception as e:
    print(f'❌ HTTP connection failed: {e}')
" 2>> "%ERROR_LOG%"

:: اختبار WebSocket
echo [Test 3/4] WebSocket connectivity...
python -c "
import websocket
try:
    ws = websocket.create_connection('ws://%SERVER_ADDRESS%/ws', timeout=10)
    ws.close()
    print('✅ WebSocket connection successful')
except Exception as e:
    print(f'❌ WebSocket connection failed: {e}')
" 2>> "%ERROR_LOG%"

:: اختبار حالة الخادم
echo [Test 4/4] Server status check...
python -c "
import requests
try:
    response = requests.get('http://%SERVER_ADDRESS%/status', timeout=5)
    if response.status_code == 200:
        data = response.json()
        print('✅ Server status retrieved:')
        print(f'   - Status: {data.get(\"status\", \"unknown\")}')
        print(f'   - AI Available: {data.get(\"interpreter_available\", \"unknown\")}')
        print(f'   - Connected Clients: {data.get(\"connected_clients\", \"unknown\")}')
        print(f'   - Total Commands: {data.get(\"total_commands\", \"unknown\")}')
    else:
        print(f'⚠️  Status endpoint responded with code: {response.status_code}')
except Exception as e:
    print(f'❌ Status check failed: {e}')
" 2>> "%ERROR_LOG%"

echo.
echo ==================================================================================
echo Connection test completed!
echo.
echo 💡 Troubleshooting:
echo    - If tests fail, ensure the server is running
echo    - Check firewall settings on both machines
echo    - Verify IP address and port configuration
echo    - Try running server with: scripts\run_server.bat
echo.
echo Press any key to return to main menu...
pause >nul
goto :MAIN_MENU

:: ============================================================================
:: المساعدة والأمثلة
:: ============================================================================
:HELP
cls
echo ==================================================================================
echo                            📖 HELP ^& COMMAND EXAMPLES
echo ==================================================================================
echo.
echo 🎯 GETTING STARTED:
echo ================================================================================
echo 1. Ensure the server is running: scripts\run_server.bat
echo 2. Configure client connection if needed: option [4] in main menu
echo 3. Choose a mode: Automatic, Interactive, or Single Command
echo 4. Send commands using natural language
echo.
echo 💬 COMMAND EXAMPLES:
echo ================================================================================
echo.
echo 🖥️  System Control:
echo    "open task manager"        - Opens Task Manager
echo    "take screenshot"          - Captures screen and saves it
echo    "system info"              - Shows detailed system information
echo    "lock screen"              - Locks the computer
echo    "show desktop"             - Minimizes all windows
echo.
echo 📁 File Operations:
echo    "open file explorer"       - Opens Windows File Explorer
echo    "list files"               - Shows files in current directory
echo    "open notepad"             - Opens Notepad text editor
echo    "create folder test"       - Creates a new folder named 'test'
echo.
echo 🌐 Applications:
echo    "open chrome"              - Opens Google Chrome browser
echo    "open calculator"          - Opens Windows Calculator
echo    "open word"                - Opens Microsoft Word
echo    "open powershell"          - Opens PowerShell terminal
echo.
echo 🔧 Network ^& System:
echo    "network info"             - Shows network configuration
echo    "ping google.com"          - Tests internet connectivity
echo    "list processes"           - Shows running programs
echo    "check cpu usage"          - Shows system performance
echo.
echo 🎮 Advanced Commands:
echo    "volume up"                - Increases system volume
echo    "volume down"              - Decreases system volume
echo    "mute"                     - Toggles mute/unmute
echo    "shutdown"                 - Safely shuts down computer ^(60s delay^)
echo    "restart"                  - Restarts computer ^(60s delay^)
echo.
echo 🤖 Server Commands:
echo    "server:stats"             - Shows server statistics
echo    "server:models"            - Lists available AI models
echo    "server:switch ollama/llama3.2:3b" - Switches AI model
echo    "server:clear-history"     - Clears command history
echo.
echo 🛡️  SAFETY FEATURES:
echo ================================================================================
echo • Dangerous commands are automatically blocked
echo • All actions are logged for review
echo • Emergency stop with Ctrl+C
echo • Automatic reconnection on connection loss
echo • Safe shutdown delays for system commands
echo.
echo 🔧 TROUBLESHOOTING:
echo ================================================================================
echo.
echo ❌ "Connection failed":
echo   - Ensure server is running ^(scripts\run_server.bat^)
echo   - Check IP address configuration ^(option [4]^)
echo   - Test connection ^(option [5]^)
echo   - Verify firewall settings
echo.
echo ❌ "Commands not working":
echo   - Check server logs for AI model issues
echo   - Try simpler commands first
echo   - Ensure Ollama is installed for full AI features
echo   - Verify internet connection for cloud AI models
echo.
echo ❌ "Client crashes":
echo   - Run installer: scripts\install.bat
echo   - Check Python installation
echo   - Review client logs: %DEBUG_LOG%
echo.
echo 📞 GETTING MORE HELP:
echo ================================================================================
echo • Check server status: http://[server-ip]:8000/status
echo • Review installation logs: logs\install_debug.log
echo • Test individual components using the connection test
echo • Ensure all dependencies are properly installed
echo.
echo Press any key to return to main menu...
pause >nul
goto :MAIN_MENU

:: ============================================================================
:: الخروج
:: ============================================================================
:EXIT
cls
echo ==================================================================================
echo                            👋 AI CONTROL CLIENT
echo ==================================================================================
echo.
echo Thank you for using AI Control Client v3.0!
echo.
echo 📝 Session logs saved to:
echo    - Debug: %DEBUG_LOG%
echo    - Errors: %ERROR_LOG%
echo.
echo 💡 Tips for next time:
echo    - Keep the server running for automatic mode
echo    - Use interactive mode for testing commands
echo    - Check connection test if you have issues
echo.
echo [%date% %time%] Client session ended normally >> "%DEBUG_LOG%"

timeout /t 3 /nobreak >nul
exit /b 0

:: ============================================================================
:: معالج الأخطاء
:: ============================================================================
:error_exit
cls
echo ==================================================================================
echo                              ❌ CLIENT ERROR
echo ==================================================================================
echo.
echo An error occurred while starting the client.
echo.
echo 📝 Check these files for details:
echo    - Debug Log: %DEBUG_LOG%
echo    - Error Log: %ERROR_LOG%
echo.
echo 🔧 Common Solutions:
echo    1. Run scripts\install.bat to fix dependencies
echo    2. Ensure Python 3.8+ is properly installed
echo    3. Check that client virtual environment exists
echo    4. Verify server is running and accessible
echo.
echo [%date% %time%] Client startup failed >> "%ERROR_LOG%"

echo.
echo Press any key to close...
pause >nul
exit /b 1