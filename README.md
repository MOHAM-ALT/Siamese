# 🤖 AI Control System v3.0 - Professional Edition

<div align="center">

![Version](https://img.shields.io/badge/version-3.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-green.svg)
![Platform](https://img.shields.io/badge/platform-Windows-blue.svg)
![Status](https://img.shields.io/badge/status-production--ready-success.svg)
![License](https://img.shields.io/badge/license-MIT-yellow.svg)

**نظام متكامل للتحكم عن بُعد في الأجهزة باستخدام الذكاء الاصطناعي المتعدد**

[التثبيت](#-installation) • [الاستخدام](#-usage) • [المميزات](#-features) • [حل المشاكل](#-troubleshooting) • [API](#-api-reference)

</div>

---

## 📌 نظرة عامة

**AI Control System v3.0** هو نظام احترافي للتحكم عن بُعد بأجهزة Windows باستخدام الذكاء الاصطناعي المتقدم. يدعم النظام عدة مقدمي خدمات AI ويوفر معالجة ذكية للأوامر مع ميزات أمان متقدمة.

### 🎯 المميزات الرئيسية

✅ **دعم AI متعدد المقدمين** - Ollama, OpenAI, Anthropic, Google  
✅ **معالجة أوامر ذكية** - فهم اللغة الطبيعية المتقدم  
✅ **اتصال WebSocket آمن** - تواصل في الوقت الفعلي  
✅ **نظام أمان شامل** - حماية من الأوامر الخطيرة  
✅ **واجهات سهلة الاستخدام** - سكريپتات Windows محسنة  
✅ **سجلات مفصلة** - تتبع شامل للعمليات والأخطاء  
✅ **إعادة اتصال تلقائية** - استقرار عالي للاتصال  

---

## 🏗️ البنية التقنية

### مخطط النظام

```
┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐
│           🖥️ جهاز الخادم              │    │           💻 جهاز العميل             │
│         (Server Machine)           │    │         (Client Machine)           │
├─────────────────────────────────────┤    ├─────────────────────────────────────┤
│                                     │    │                                     │
│ 🤖 AI Providers:                   │    │ 🎮 Client Modes:                  │
│   • Ollama (Local)                 │◄───┤   • Automatic Mode                 │
│   • OpenAI (GPT-4)                 │    │   • Interactive Mode               │
│   • Anthropic (Claude)             │    │   • Single Command                 │
│   • Google (Gemini)                │    │                                     │
│                                     │    │ 🔧 Features:                      │
│ ⚙️ Core Components:                │    │   • Command Execution              │
│   • FastAPI Server                 │    │   • Screen Automation              │
│   • WebSocket Handler              │    │   • File Operations                │
│   • Command Processor              │    │   • System Control                 │
│   • Safety Validator               │    │                                     │
│                                     │    │ 🛡️ Safety:                       │
│ 📊 Advanced Features:              │    │   • Command Filtering              │
│   • Multi-AI Support               │    │   • Safe Execution                 │
│   • Command History                │    │   • Error Handling                 │
│   • Real-time Monitoring           │    │   • Logging System                 │
│   • Configuration Management       │    │                                     │
└─────────────────────────────────────┘    └─────────────────────────────────────┘
                      │                                          │
                      └──────────── 🌐 LAN Network ──────────────┘
                         (WebSocket + HTTP Communication)
```

### التقنيات المستخدمة

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Backend** | FastAPI | 0.104+ | Web framework and API |
| **WebSockets** | uvicorn | 0.24+ | Real-time communication |
| **AI Local** | Ollama | Latest | Local LLM execution |
| **AI Cloud** | OpenAI API | v4 | GPT models access |
| **AI Cloud** | Anthropic API | v3 | Claude models access |
| **AI Cloud** | Google API | Latest | Gemini models access |
| **Automation** | PyAutoGUI | 0.9.54+ | GUI automation |
| **Processing** | Open Interpreter | Latest | Code execution |
| **Language** | Python | 3.8+ | Core development |

---

## 📂 هيكل المشروع

```
AI_Control_System_v3/
│
├── 📁 src/                          # الكود المصدري
│   ├── 📁 server/                   # كود الخادم
│   │   ├── 📄 main.py              # نقطة البداية
│   │   ├── 📄 config.py            # تكوين AI متعدد
│   │   ├── 📁 api/                 # واجهات API
│   │   │   └── 📄 endpoints.py     # نقاط النهاية
│   │   ├── 📁 core/                # المكونات الأساسية
│   │   │   └── 📄 controller.py    # معالج AI الرئيسي
│   │   ├── 📁 services/            # الخدمات
│   │   │   └── 📄 interpreter.py   # معالج الأوامر
│   │   └── 📄 requirements.txt     # متطلبات الخادم
│   │
│   └── 📁 client/                   # كود العميل
│       ├── 📄 main.py              # نقطة البداية
│       ├── 📄 config.py            # تكوين العميل
│       ├── 📄 connection.py        # إدارة الاتصال
│       ├── 📁 core/                # المكونات الأساسية
│       │   └── 📄 executor.py      # منفذ الأوامر
│       └── 📄 requirements.txt     # متطلبات العميل
│
├── 📁 scripts/                      # سكريپتات التشغيل
│   ├── 📄 install.bat              # مثبت شامل محسن
│   ├── 📄 run_server.bat           # مشغل الخادم
│   └── 📄 run_client.bat           # مشغل العميل
│
├── 📁 tests/                        # الاختبارات
│   ├── 📁 server/                  # اختبارات الخادم
│   ├── 📁 client/                  # اختبارات العميل
│   └── 📄 test_integration.py      # اختبارات التكامل
│
├── 📁 logs/                         # سجلات النظام
│   ├── 📄 server.log               # سجل الخادم
│   ├── 📄 client.log               # سجل العميل
│   ├── 📄 install_debug.log        # سجل التثبيت
│   └── 📄 *_debug.log              # سجلات إضافية
│
├── 📁 config/                       # ملفات التكوين
│   ├── 📄 ai_models_config.json    # تكوين AI
│   └── 📄 client_config.json       # تكوين العميل
│
└── 📄 README.md                     # هذا الملف
```

---

## 🚀 التثبيت

### متطلبات النظام

#### للخادم (Server):
- **نظام التشغيل:** Windows 10/11 (64-bit)
- **Python:** 3.8+ (مع pip)
- **الذاكرة:** 8GB RAM (16GB+ موصى به)
- **المعالج:** Intel Core i5 أو AMD equivalent
- **كرت الشاشة:** NVIDIA GPU (اختياري للأداء الأفضل)
- **التخزين:** 10GB مساحة فارغة
- **الشبكة:** اتصال LAN مستقر

#### للعميل (Client):
- **نظام التشغيل:** Windows 10/11
- **Python:** 3.8+
- **الذاكرة:** 4GB RAM
- **الشبكة:** نفس شبكة الخادم

### 📥 خطوات التثبيت السريع

1. **تحميل المشروع:**
   ```cmd
   git clone https://github.com/your-repo/AI_Control_System
   cd AI_Control_System
   ```

2. **تشغيل المثبت (كمسؤول):**
   ```cmd
   scripts\install.bat
   ```

3. **اتباع التعليمات:**
   - المثبت سيقوم بتثبيت كل شيء تلقائياً
   - إعداد البيئات الافتراضية
   - تثبيت جميع التبعيات
   - إنشاء ملفات التكوين

### 🎮 إعداد مقدمي AI

#### Ollama (محلي - مجاني)
```cmd
# تثبيت Ollama
# تحميل من: https://ollama.ai/

# تحميل نموذج
ollama pull qwen2.5-coder:7b
ollama pull llama3.2:3b
```

#### OpenAI (سحابي - مدفوع)
```json
# في ai_models_config.json
{
  "providers": {
    "openai": {
      "enabled": true,
      "api_key": "your-openai-api-key-here",
      "default_model": "gpt-4"
    }
  }
}
```

#### Anthropic Claude (سحابي - مدفوع)
```json
# في ai_models_config.json
{
  "providers": {
    "anthropic": {
      "enabled": true,
      "api_key": "your-anthropic-api-key-here",
      "default_model": "claude-3-sonnet-20240229"
    }
  }
}
```

---

## 💻 الاستخدام

### تشغيل الخادم

```cmd
# تشغيل الخادم
scripts\run_server.bat

# الخادم سيكون متاحاً على:
# http://localhost:8000 (محلي)
# http://[IP]:8000 (الشبكة)
# ws://[IP]:8000/ws (WebSocket)
```

### تشغيل العميل

```cmd
# تشغيل العميل
scripts\run_client.bat

# اختيار من الخيارات:
# [1] وضع تلقائي - انتظار الأوامر
# [2] وضع تفاعلي - إرسال أوامر مباشرة
# [3] أمر واحد - إرسال أمر محدد
```

### 🎯 أمثلة الأوامر

#### أوامر أساسية
```
open chrome                 # فتح متصفح Chrome
take screenshot            # التقاط لقطة شاشة
open notepad               # فتح المفكرة
system info                # معلومات النظام
list files                 # عرض الملفات
```

#### أوامر متقدمة
```
create folder "My Project" # إنشاء مجلد
ping google.com           # اختبار الاتصال
volume up                 # زيادة الصوت
lock screen              # قفل الشاشة
open task manager        # مدير المهام
```

#### أوامر الخادم الخاصة
```
server:stats                     # إحصائيات الخادم
server:models                    # النماذج المتاحة
server:switch ollama/llama3.2:3b # تبديل النموذج
server:clear-history            # مسح التاريخ
```

---

## 🎛️ تكوين المقدمين

### تحرير ملف التكوين

```json
{
  "default_provider": "ollama",
  "providers": {
    "ollama": {
      "enabled": true,
      "base_url": "http://localhost:11434",
      "default_model": "qwen2.5-coder:7b",
      "models": [
        "qwen2.5-coder:7b",
        "llama3.2:3b",
        "mistral:7b",
        "deepseek-coder:6.7b"
      ]
    },
    "openai": {
      "enabled": false,
      "api_key": "sk-...",
      "default_model": "gpt-4",
      "models": ["gpt-4", "gpt-3.5-turbo"]
    },
    "anthropic": {
      "enabled": false,
      "api_key": "sk-ant-...",
      "default_model": "claude-3-sonnet-20240229",
      "models": ["claude-3-opus-20240229", "claude-3-sonnet-20240229"]
    },
    "google": {
      "enabled": false,
      "api_key": "AIza...",
      "default_model": "gemini-pro",
      "models": ["gemini-pro", "gemini-pro-vision"]
    }
  }
}
```

### تبديل المقدمين أثناء التشغيل

```python
# عبر API
POST http://localhost:8000/switch-provider
{
  "provider": "openai",
  "model": "gpt-4"
}

# عبر WebSocket
{
  "type": "switch_provider",
  "provider": "anthropic",
  "model": "claude-3-sonnet-20240229"
}

# عبر الأوامر
server:switch openai/gpt-4
```

---

## 📊 مراقبة النظام

### لوحة المعلومات

```
http://localhost:8000/status
```

**معلومات متاحة:**
- حالة الخادم والاتصالات
- إحصائيات الأوامر المنفذة
- معلومات مقدم AI النشط
- استخدام الموارد
- تاريخ الأوامر

### سجلات النظام

| Log File | Purpose |
|----------|---------|
| `logs/server.log` | سجل الخادم الرئيسي |
| `logs/client.log` | سجل العميل |
| `logs/install_debug.log` | سجل التثبيت التفصيلي |
| `logs/run_server_debug.log` | سجل تشغيل الخادم |
| `logs/run_client_debug.log` | سجل تشغيل العميل |

---

## 🛡️ الأمان

### ميزات الأمان المطبقة

1. **تصفية الأوامر الخطيرة**
   ```python
   DANGEROUS_COMMANDS = [
       'format', 'fdisk', 'mkfs', 'diskpart',
       'del /s', 'rm -rf', 'shutdown /s /t 0'
   ]
   ```

2. **حماية المجلدات الحساسة**
   ```python
   PROTECTED_DIRECTORIES = [
       'C:\\Windows\\System32',
       'C:\\Windows\\SysWOW64',
       '/etc', '/sys', '/proc'
   ]
   ```

3. **تحقق من الأوامر**
   - فحص تلقائي للأوامر الواردة
   - منع الأوامر المدمرة
   - تسجيل كامل للعمليات

4. **شبكة آمنة**
   - اتصال محلي فقط (LAN)
   - تشفير WebSocket
   - مصادقة العملاء

### إعدادات الأمان

```json
{
  "safety_mode": true,
  "allow_system_commands": false,
  "require_confirmation": true,
  "log_all_commands": true,
  "max_command_length": 1000
}
```

---

## 🔧 حل المشاكل

### مشاكل التثبيت

#### المشكلة: "Python not found"
```cmd
# الحل:
1. تثبيت Python من python.org
2. التأكد من إضافته لـ PATH
3. إعادة تشغيل Command Prompt
4. تشغيل: python --version
```

#### المشكلة: "Virtual environment failed"
```cmd
# الحل:
1. تشغيل كـ Administrator
2. التأكد من مساحة القرص الكافية
3. تعطيل Antivirus مؤقتاً
4. تشغيل: scripts\install.bat
```

### مشاكل الخادم

#### المشكلة: "Port 8000 already in use"
```cmd
# فحص المنفذ:
netstat -ano | findstr :8000

# إنهاء العملية:
taskkill /PID [PID_NUMBER] /F

# أو تغيير المنفذ في التكوين
```

#### المشكلة: "Ollama not responding"
```cmd
# إعادة تشغيل Ollama:
taskkill /F /IM ollama.exe
ollama serve

# فحص النماذج:
ollama list

# تحميل نموذج:
ollama pull qwen2.5-coder:7b
```

### مشاكل العميل

#### المشكلة: "Connection failed"
```cmd
# فحوصات الشبكة:
ping [server-ip]
telnet [server-ip] 8000

# فحص التكوين:
type client_config.json

# اختبار الاتصال:
scripts\run_client.bat -> [5] Connection Test
```

#### المشكلة: "Commands not executing"
```cmd
# فحص السجلات:
type logs\client_debug.log
type logs\server.log

# فحص أذونات PyAutoGUI:
python -c "import pyautogui; print('OK')"

# تشغيل كـ Administrator
```

### مشاكل الأداء

#### بطء في الاستجابة
```json
// تحسين الإعدادات
{
  "screenshot_quality": 60,
  "max_reconnect_attempts": 3,
  "reconnect_delay": 1,
  "timeout_seconds": 15
}
```

#### استهلاك ذاكرة عالي
```cmd
# مراقبة الاستخدام:
http://localhost:8000/status

# مسح التاريخ:
server:clear-history

# إعادة تشغيل الخدمات
```

---

## 📡 API Reference

### HTTP Endpoints

| Endpoint | Method | Description | Example |
|----------|--------|-------------|---------|
| `/` | GET | صفحة الحالة الرئيسية | `GET /` |
| `/status` | GET | حالة الخادم المفصلة | `GET /status` |
| `/process` | POST | معالجة أمر مباشر | `POST /process` |
| `/history` | GET | تاريخ الأوامر | `GET /history?limit=20` |
| `/models` | GET | النماذج المتاحة | `GET /models` |
| `/switch-provider` | POST | تبديل مقدم AI | `POST /switch-provider` |
| `/health` | GET | فحص صحة النظام | `GET /health` |

### WebSocket Messages

#### إرسال أمر
```json
{
  "type": "command",
  "command": "open notepad",
  "context": {
    "mode": "interactive",
    "system_info": {...}
  }
}
```

#### استقبال نتيجة
```json
{
  "type": "command_result",
  "success": true,
  "actions": [
    {
      "type": "command",
      "code": "notepad",
      "result": "Notepad opened successfully"
    }
  ],
  "processing_time": 0.15,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

#### تبديل مقدم AI
```json
{
  "type": "switch_provider",
  "provider": "openai",
  "model": "gpt-4"
}
```

#### إحصائيات الخادم
```json
{
  "type": "get_stats"
}
```

### Python Client API

```python
from src.client.main import AIClient

# إنشاء عميل
client = AIClient()

# إرسال أمر واحد
client.start('command', 'open chrome')

# وضع تفاعلي
client.start('interactive')

# وضع تلقائي
client.start('auto')
```

### أمثلة cURL

```bash
# فحص حالة الخادم
curl http://localhost:8000/status

# إرسال أمر
curl -X POST http://localhost:8000/process \
  -H "Content-Type: application/json" \
  -d '{"command": "open notepad"}'

# الحصول على التاريخ
curl http://localhost:8000/history?limit=10

# تبديل النموذج
curl -X POST http://localhost:8000/switch-provider \
  -H "Content-Type: application/json" \
  -d '{"provider": "openai", "model": "gpt-4"}'
```

---

## 🧪 الاختبارات

### تشغيل الاختبارات

```cmd
# تفعيل البيئة
call venv_server\Scripts\activate.bat

# تشغيل جميع الاختبارات
pytest

# اختبارات محددة
pytest tests/server/
pytest tests/client/
pytest tests/test_integration.py

# مع تفاصيل
pytest -v --tb=short
```

### أنواع الاختبارات

1. **اختبارات الوحدة** - فحص المكونات الفردية
2. **اختبارات التكامل** - فحص التفاعل بين المكونات
3. **اختبارات الأمان** - فحص آليات الحماية
4. **اختبارات الأداء** - قياس سرعة الاستجابة

---

## 🚀 النشر والإنتاج

### إعداد الإنتاج

1. **إعدادات الأمان المتقدمة**
   ```json
   {
     "environment": "production",
     "debug": false,
     "safe_mode": true,
     "require_authentication": true,
     "enable_ssl": true
   }
   ```

2. **مراقبة الأداء**
   ```python
   # في production
   uvicorn.run(
       app,
       host="0.0.0.0",
       port=8000,
       workers=4,
       access_log=True,
       log_level="warning"
   )
   ```

3. **النسخ الاحتياطي**
   ```cmd
   # نسخ احتياطي للتكوين
   xcopy config\*.json backup\config\ /Y
   
   # نسخ احتياطي للسجلات
   xcopy logs\*.log backup\logs\ /Y
   ```

### Docker Deployment (اختياري)

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ ./src/
COPY config/ ./config/

EXPOSE 8000
CMD ["python", "-m", "src.server.main"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  ai-server:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - ENVIRONMENT=production
```

---

## 📈 الإحصائيات والمراقبة

### لوحة المراقبة

```
http://localhost:8000/dashboard
```

**المقاييس المتاحة:**
- عدد الأوامر المنفذة
- معدل النجاح
- زمن الاستجابة المتوسط
- استخدام الموارد
- العملاء النشطون

### التنبيهات

```json
{
  "alerts": {
    "high_cpu_usage": 80,
    "high_memory_usage": 85,
    "failed_commands_threshold": 10,
    "connection_errors_threshold": 5
  }
}
```

---

## 🔮 التطوير المستقبلي

### الميزات المخططة

- [ ] **واجهة ويب متقدمة** - لوحة تحكم شاملة
- [ ] **دعم أنظمة متعددة** - Linux و macOS
- [ ] **مصادقة متقدمة** - OAuth2, JWT
- [ ] **تشفير end-to-end** - أمان إضافي
- [ ] **دعم العملاء المتعددين** - إدارة مركزية
- [ ] **ذكاء اصطناعي محسن** - نماذج مخصصة
- [ ] **تطبيق موبايل** - تحكم من الهاتف
- [ ] **نظام الإضافات** - تطوير مكونات إضافية

### المساهمة في التطوير

```bash
# نسخ المستودع
git clone https://github.com/your-repo/AI_Control_System
cd AI_Control_System

# إنشاء فرع جديد
git checkout -b feature/new-feature

# تطوير الميزة
# ...

# إرسال التغييرات
git commit -m "Add new feature"
git push origin feature/new-feature

# إنشاء Pull Request
```

---

## 📞 الدعم والمساعدة

### طرق الحصول على المساعدة

1. **الوثائق** - قراءة هذا الدليل بالكامل
2. **السجلات** - فحص ملفات logs/ للتفاصيل
3. **الاختبارات** - تشغيل اختبارات التشخيص
4. **المجتمع** - GitHub Issues و Discussions

### معلومات الاتصال

- **GitHub Repository:** [AI Control System](https://github.com/your-repo)
- **Issues:** [Report Bug](https://github.com/your-repo/issues)
- **Discussions:** [Community Forum](https://github.com/your-repo/discussions)
- **Email:** support@ai-control-system.com

### الأسئلة الشائعة

**س: هل يعمل النظام مع أنظمة أخرى غير Windows؟**  
ج: حالياً النظام مُحسّن لـ Windows، لكن دعم Linux و macOS مخطط للمستقبل.

**س: هل يمكن استخدام عدة مقدمي AI في نفس الوقت؟**  
ج: لا، يمكن استخدام مقدم واحد في كل مرة، لكن يمكن التبديل بينهم بسهولة.

**س: ما هو أفضل نموذج AI للاستخدام؟**  
ج: للأداء المحلي: qwen2.5-coder:7b، للسحابة: GPT-4 أو Claude-3.

**س: هل النظام آمن للاستخدام في بيئة الإنتاج؟**  
ج: نعم، مع تفعيل جميع ميزات الأمان وإعدادات الإنتاج المناسبة.

---

## 📄 الترخيص

```
MIT License

Copyright (c) 2024 AI Control System

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 الشكر والتقدير

- **OpenAI** - لتقنيات GPT المتقدمة
- **Anthropic** - لنماذج Claude الذكية  
- **Google** - لنماذج Gemini المبتكرة
- **Ollama Team** - لجعل AI المحلي متاحاً للجميع
- **FastAPI Community** - للإطار الممتاز
- **Python Community** - للغة والمكتبات الرائعة
- **Open Source Community** - للإلهام والدعم

---

<div align="center">

**🌟 شكراً لاستخدامك AI Control System v3.0 🌟**

صُنع بـ ❤️ للمطورين وعشاق التقنية

[![Star on GitHub](https://img.shields.io/github/stars/your-repo/AI_Control_System.svg?style=social)](https://github.com/your-repo/AI_Control_System)
[![Follow](https://img.shields.io/github/followers/your-username.svg?style=social&label=Follow)](https://github.com/your-username)

[⬆ العودة للأعلى](#-ai-control-system-v30---professional-edition)

</div>