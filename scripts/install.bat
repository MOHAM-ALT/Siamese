@echo off
setlocal enabledelayedexpansion
title AI Control System - Windows Installer v3.0

:: إعداد متغيرات اللوج
set "DEBUG_LOG=logs\install_debug.log"
set "ERROR_LOG=logs\install_errors.log"

:: إنشاء مجلد اللوج
if not exist "logs" mkdir "logs"
del "%DEBUG_LOG%" >nul 2>&1
del "%ERROR_LOG%" >nul 2>&1

:: بدء اللوج
echo [%date% %time%] Starting AI Control System Installation > "%DEBUG_LOG%"
echo [%date% %time%] Starting AI Control System Installation > "%ERROR_LOG%"

echo ==================================================================================
echo                    🤖 AI CONTROL SYSTEM INSTALLER v3.0
echo ==================================================================================
echo.
echo This installer will set up both Server and Client components with:
echo   ✅ Python virtual environments for isolation
echo   ✅ All required dependencies
echo   ✅ Enhanced error handling and logging
echo   ✅ Multi-AI model support (Ollama, OpenAI, Anthropic, Google)
echo.
echo Installation will be logged to: %DEBUG_LOG%
echo.
pause

:: تغيير إلى المجلد الجذر للمشروع
echo [%date% %time%] Changing to project root directory... >> "%DEBUG_LOG%"
cd /d "%~dp0.." 2>> "%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Failed to change to project directory >> "%ERROR_LOG%"
    goto :error_exit
)

echo [SUCCESS] Working directory: %CD%
echo [%date% %time%] Working directory: %CD% >> "%DEBUG_LOG%"

:: ============================================================================
:: مرحلة 1: فحص متطلبات النظام
:: ============================================================================
echo.
echo [PHASE 1/6] 🔍 Checking System Requirements...
echo ============================================================================

:: فحص Python
echo [STEP] Checking Python installation...
echo [%date% %time%] Checking Python installation... >> "%DEBUG_LOG%"

python --version >nul 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [ERROR] Python not found in PATH.
    echo [ERROR] Python not found in PATH. >> "%ERROR_LOG%"
    echo.
    echo ❌ Python is required but not found!
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

:: فحص pip
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
:: مرحلة 2: تنظيف البيئات السابقة
:: ============================================================================
echo.
echo [PHASE 2/6] 🧹 Cleaning Previous Installations...
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
:: مرحلة 3: إعداد بيئة الخادم
:: ============================================================================
echo.
echo [PHASE 3/6] 🖥️ Setting Up Server Environment...
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

python -m pip install -r src\server\requirements.txt --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [WARNING] Some server packages failed to install, trying individually...
    echo [WARNING] Some server packages failed to install >> "%ERROR_LOG%"
    
    :: تثبيت الحزم الأساسية واحدة تلو الأخرى
    for %%p in (fastapi uvicorn websockets requests aiofiles python-multipart) do (
        echo [ACTION] Installing %%p...
        python -m pip install %%p --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
        if errorlevel 1 (
            echo [WARNING] Failed to install %%p
            echo [WARNING] Failed to install %%p >> "%ERROR_LOG%"
        ) else (
            echo [SUCCESS] Installed %%p
        )
    )
    
    :: حزم اختيارية
    for %%p in (ollama pyautogui pillow open-interpreter pytest) do (
        echo [ACTION] Installing optional package %%p...
        python -m pip install %%p --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
        if errorlevel 1 (
            echo [INFO] Optional package %%p not installed (this is okay)
            echo [INFO] Optional package %%p not installed >> "%DEBUG_LOG%"
        ) else (
            echo [SUCCESS] Installed optional package %%p
        )
    )
) else (
    echo [SUCCESS] All server dependencies installed
    echo [%date% %time%] All server dependencies installed >> "%DEBUG_LOG%"
)

call venv_server\Scripts\deactivate.bat 2>nul

:: ============================================================================
:: مرحلة 4: إعداد بيئة العميل
:: ============================================================================
echo.
echo [PHASE 4/6] 💻 Setting Up Client Environment...
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

python -m pip install -r src\client\requirements.txt --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
if errorlevel 1 (
    echo [WARNING] Some client packages failed to install, trying individually...
    echo [WARNING] Some client packages failed to install >> "%ERROR_LOG%"
    
    :: تثبيت الحزم الأساسية للعميل
    for %%p in (websocket-client requests) do (
        echo [ACTION] Installing essential %%p...
        python -m pip install %%p --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
        if errorlevel 1 (
            echo [ERROR] Failed to install essential package %%p
            echo [ERROR] Failed to install essential package %%p >> "%ERROR_LOG%"
        ) else (
            echo [SUCCESS] Installed %%p
        )
    )
    
    :: حزم اختيارية للعميل
    for %%p in (pyautogui pillow keyboard psutil opencv-python pytest) do (
        echo [ACTION] Installing optional %%p...
        python -m pip install %%p --quiet >>"%DEBUG_LOG%" 2>"%ERROR_LOG%"
        if errorlevel 1 (
            echo [INFO] Optional package %%p not installed (features may be limited)
            echo [INFO] Optional package %%p not installed >> "%DEBUG_LOG%"
        ) else (
            echo [SUCCESS] Installed optional package %%p
        )
    )
) else (
    echo [SUCCESS] All client dependencies installed
    echo [%date% %time%] All client dependencies installed >> "%DEBUG_LOG%"
)

call venv_client\Scripts\deactivate.bat 2>nul

:: ============================================================================
:: مرحلة 5: إنشاء ملفات التكوين
:: ============================================================================
echo.
echo [PHASE 5/6] ⚙️ Creating Configuration Files...
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
        echo         "mistral:7