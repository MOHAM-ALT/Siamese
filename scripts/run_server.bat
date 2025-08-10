@echo off
setlocal enabledelayedexpansion
title AI Control Server Launcher v3.0

:: إعداد متغيرات اللوج
set "DEBUG_LOG=logs\run_server_debug.log"
set "ERROR_LOG=logs\run_server_errors.log"

:: إنشاء مجلد اللوج
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1
del "%ERROR_LOG%" >nul 2>&1

echo ==================================================================================
echo                       🚀 AI CONTROL SERVER LAUNCHER v3.0
echo ==================================================================================
echo.
echo 🎯 Features:
echo    - Multi-AI Provider Support (Ollama, OpenAI, Anthropic, Google)
echo    - Enhanced Command Processing
echo    - Real-time WebSocket Communication
echo    - Comprehensive Logging ^& Error Handling
echo.
echo 📝 Debug output will be saved to: %DEBUG_LOG%
echo 📝 Error output will be saved to: %ERROR_LOG%
echo.
pause

:: بدء اللوج
echo [%date% %time%] Starting AI Control Server v3.0 > "%DEBUG_LOG%"
echo [%date% %time%] Starting AI Control Server v3.0 > "%ERROR_LOG%"

:: تغيير إلى المجلد الجذر
echo [INFO] Changing to project root directory...
echo [%date% %time%] Changing to project root directory... >> "%DEBUG_LOG%"
cd /d "%~dp0.." 2>> "%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to change to project directory
    echo [ERROR] Failed to change to project directory >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Working directory: %CD%
echo [%date% %time%] Working directory: %CD% >> "%DEBUG_LOG%"

:: ============================================================================
:: فحص البيئة الافتراضية للخادم
:: ============================================================================
echo.
echo [STEP 1/5] 🔍 Checking Server Environment...
echo ============================================================================

echo [CHECK] Looking for server virtual environment...
echo [%date% %time%] Checking server virtual environment... >> "%DEBUG_LOG%"

if not exist "venv_server\Scripts\activate.bat" (
    echo [ERROR] Server virtual environment not found!
    echo [ERROR] Server virtual environment not found >> "%ERROR_LOG%"
    echo.
    echo ❌ Server environment is missing. Please run the installer first:
    echo    scripts\install.bat
    echo.
    pause
    goto :error_exit
)

echo [SUCCESS] Server virtual environment found
echo [%date% %time%] Server virtual environment found >> "%DEBUG_LOG%"

:: تفعيل البيئة
echo [ACTION] Activating server environment...
echo [%date% %time%] Activating server environment... >> "%DEBUG_LOG%"

call venv_server\Scripts\activate.bat >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to activate server environment
    echo [ERROR] Failed to activate server environment >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Server environment activated
echo [%date% %time%] Server environment activated >> "%DEBUG_LOG%"

:: ============================================================================
:: فحص Ollama (اختياري)
:: ============================================================================
echo.
echo [STEP 2/5] 🦙 Checking Ollama Service...
echo ============================================================================

echo [CHECK] Looking for Ollama service...
echo [%date% %time%] Checking Ollama service... >> "%DEBUG_LOG%"

:: فحص ما إذا كان Ollama يعمل
tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Ollama not currently running
    echo [%date% %time%] Ollama not running, attempting to start... >> "%DEBUG_LOG%"
    
    :: محاولة تشغيل Ollama
    where ollama >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Ollama not found in PATH
        echo [WARNING] Ollama not found in PATH >> "%ERROR_LOG%"
        echo.
        echo ⚠️  Ollama not found. The server will run in basic mode.
        echo    To enable full AI features:
        echo    1. Install Ollama from https://ollama.ai/
        echo    2. Pull a model: ollama pull qwen2.5-coder:7b
        echo    3. Restart this server
        echo.
        set "OLLAMA_STATUS=not_installed"
    ) else (
        echo [ACTION] Starting Ollama service...
        echo [%date% %time%] Starting Ollama service... >> "%DEBUG_LOG%"
        
        start "Ollama Server" ollama serve >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
        echo [INFO] Ollama startup initiated
        echo [INFO] Waiting for Ollama to initialize...
        timeout /t 8 /nobreak >nul 2>&1
        
        :: التحقق من نجاح التشغيل
        tasklist /FI "IMAGENAME eq ollama.exe" 2>nul | find /I "ollama.exe" >nul 2>&1
        if errorlevel 1 (
            echo [WARNING] Ollama may not have started properly
            echo [WARNING] Ollama startup may have failed >> "%ERROR_LOG%"
            set "OLLAMA_STATUS=start_failed"
        ) else (
            echo [SUCCESS] Ollama is now running
            echo [%date% %time%] Ollama started successfully >> "%DEBUG_LOG%"
            set "OLLAMA_STATUS=running"
        )
    )
) else (
    echo [SUCCESS] Ollama is already running
    echo [%date% %time%] Ollama already running >> "%DEBUG_LOG%"
    set "OLLAMA_STATUS=running"
)

:: ============================================================================
:: فحص التبعيات المطلوبة
:: ============================================================================
echo.
echo [STEP 3/5] 📦 Verifying Dependencies...
echo ============================================================================

echo [CHECK] Verifying Python packages...
echo [%date% %time%] Verifying Python packages... >> "%DEBUG_LOG%"

:: فحص الحزم الأساسية
set "MISSING_PACKAGES="

for %%p in (fastapi uvicorn websockets requests) do (
    echo [VERIFY] Checking %%p...
    python -c "import %%p" >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
    if errorlevel 1 (
        echo [ERROR] Missing critical package: %%p
        echo [ERROR] Missing critical package: %%p >> "%ERROR_LOG%"
        set "MISSING_PACKAGES=!MISSING_PACKAGES! %%p"
    ) else (
        echo [SUCCESS] %%p is available
    )
)

:: فحص الحزم الاختيارية
for %%p in (interpreter ollama pyautogui) do (
    echo [VERIFY] Checking optional %%p...
    python -c "import %%p" >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
    if errorlevel 1 (
        echo [INFO] Optional package %%p not available (features may be limited)
        echo [INFO] Optional package %%p not available >> "%DEBUG_LOG%"
    ) else (
        echo [SUCCESS] Optional %%p is available
    )
)

if not "!MISSING_PACKAGES!"=="" (
    echo [ERROR] Critical packages missing: !MISSING_PACKAGES!
    echo [ERROR] Critical packages missing: !MISSING_PACKAGES! >> "%ERROR_LOG%"
    echo.
    echo ❌ Critical dependencies are missing!
    echo    Please run the installer to fix this: scripts\install.bat
    echo.
    pause
    goto :error_exit
)

echo [SUCCESS] All critical dependencies verified
echo [%date% %time%] All critical dependencies verified >> "%DEBUG_LOG%"

:: ============================================================================
:: فحص ملفات التكوين
:: ============================================================================
echo.
echo [STEP 4/5] ⚙️ Loading Configuration...
echo ============================================================================

echo [CHECK] Checking configuration files...
echo [%date% %time%] Checking configuration files... >> "%DEBUG_LOG%"

if exist "ai_models_config.json" (
    echo [SUCCESS] AI models configuration found
    echo [%date% %time%] AI models configuration found >> "%DEBUG_LOG%"
    
    :: عرض معلومات النموذج النشط
    for /f "tokens=*" %%i in ('python -c "import json; data=json.load(open('ai_models_config.json')); print(f\"{data['default_provider']}/{data['providers'][data['default_provider']]['default_model']}\");"') do (
        echo [INFO] Active AI Model: %%i
        echo [%date% %time%] Active AI Model: %%i >> "%DEBUG_LOG%"
    )
) else (
    echo [WARNING] AI models configuration not found
    echo [WARNING] AI models configuration not found >> "%ERROR_LOG%"
    echo [INFO] Server will create default configuration
)

if exist "src\server\main.py" (
    echo [SUCCESS] Server main script found
    echo [%date% %time%] Server main script found >> "%DEBUG_LOG%"
) else (
    echo [ERROR] Server main script missing!
    echo [ERROR] Server main script missing >> "%ERROR_LOG%"
    goto :error_exit
)

:: ============================================================================
:: تشغيل الخادم
:: ============================================================================
echo.
echo [STEP 5/5] 🎯 Launching AI Control Server...
echo ============================================================================

echo [ACTION] Starting Python server...
echo [%date% %time%] Starting Python server... >> "%DEBUG_LOG%"

:: عرض معلومات التشغيل
for /f "tokens=*" %%i in ('python -c "import socket; print(socket.gethostbyname(socket.gethostname()))"') do set LOCAL_IP=%%i

echo.
echo ==================================================================================
echo                         🚀 AI CONTROL SERVER STARTING
echo ==================================================================================
echo.
echo 🌐 Server Access Points:
echo    - Local:     http://localhost:8000
echo    - Network:   http://!LOCAL_IP!:8000
echo    - WebSocket: ws://!LOCAL_IP!:8000/ws
echo    - Status:    http://!LOCAL_IP!:8000/status
echo.
echo 🤖 AI Configuration:
if "!OLLAMA_STATUS!"=="running" (
    echo    - Ollama: ✅ Available
) else (
    echo    - Ollama: ❌ Not Available ^(basic mode^)
)
echo    - Multi-Provider: ✅ Supported
echo.
echo 📁 Working Directory: %CD%
echo 📝 Logs: %CD%\logs\
echo.
echo ==================================================================================
echo                   Server is starting... Press Ctrl+C to stop
echo ==================================================================================
echo.

:: تشغيل الخادم مع تسجيل مفصل
python -m src.server.main
set "SERVER_EXIT_CODE=%errorlevel%"

echo.
echo ==================================================================================

if %SERVER_EXIT_CODE%==0 (
    echo [INFO] Server stopped normally
    echo [%date% %time%] Server stopped normally >> "%DEBUG_LOG%"
) else (
    echo [ERROR] Server stopped with error code: %SERVER_EXIT_CODE%
    echo [ERROR] Server stopped with error code: %SERVER_EXIT_CODE% >> "%ERROR_LOG%"
)

echo.
echo 📝 Session logs saved to:
echo    - Debug: %DEBUG_LOG%
echo    - Errors: %ERROR_LOG%
echo.

if %SERVER_EXIT_CODE% neq 0 (
    echo ❌ Server encountered an error. Check the logs above for details.
    echo.
)

echo Press any key to close this window...
pause >nul
exit /b %SERVER_EXIT_CODE%

:: ============================================================================
:: معالج الأخطاء
:: ============================================================================
:error_exit
echo.
echo ==================================================================================
echo                              ❌ SERVER STARTUP FAILED
echo ==================================================================================
echo.
echo An error occurred while starting the server.
echo.
echo 📝 Check these files for details:
echo    - Debug Log: %DEBUG_LOG%
echo    - Error Log: %ERROR_LOG%
echo.
echo 🔧 Common Solutions:
echo    1. Run scripts\install.bat to fix dependencies
echo    2. Ensure Python 3.8+ is properly installed
echo    3. Check that no other service is using port 8000
echo    4. Run as Administrator for full functionality
echo    5. Install Ollama from https://ollama.ai/ for AI features
echo.
echo 📞 Need Help?
echo    - Check the project documentation
echo    - Review the error logs above
echo    - Ensure all requirements are met
echo.

echo [%date% %time%] Server startup failed >> "%ERROR_LOG%"

echo Press any key to close this window...
pause >nul
exit /b 1