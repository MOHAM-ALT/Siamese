# src/server/services/interpreter.py
import json
import logging
import os
import platform
import psutil
import requests
from typing import Dict, Any, Optional, List, Tuple

logger = logging.getLogger(__name__)

# قائمة الأوامر الخطيرة المحظورة
DANGEROUS_COMMANDS = [
    'format', 'fdisk', 'mkfs', 'diskpart',
    'del /s', 'rm -rf', 'rmdir /s',
    'shutdown /s /t 0', 'poweroff', 'halt', 'init 0',
    'net user', 'passwd', 'chpasswd',
    'sudo rm', 'sudo dd', 'dd if='
]

# مجلدات محمية
PROTECTED_DIRECTORIES = [
    'C:\\Windows\\System32', 'C:\\Windows\\SysWOW64',
    '/etc', '/sys', '/proc', '/dev', '/bin', '/sbin',
    '/System', '/Library'
]

def validate_command_safety(command: str) -> Tuple[bool, str]:
    """التحقق من أمان الأمر قبل التنفيذ"""
    command_lower = command.lower().strip()
    
    # فحص الأوامر المحظورة
    for dangerous in DANGEROUS_COMMANDS:
        if dangerous.lower() in command_lower:
            return False, f"Contains dangerous command: {dangerous}"
    
    # فحص المجلدات المحمية
    for protected_dir in PROTECTED_DIRECTORIES:
        if protected_dir.lower() in command_lower:
            return False, f"Targets protected directory: {protected_dir}"
    
    # فحص الرموز الخطيرة
    dangerous_chars = ['&&', '||', ';', '|', '>', '>>', '<']
    for char in dangerous_chars:
        if char in command and len(command.split(char)) > 2:
            return False, f"Contains potentially dangerous operator: {char}"
    
    return True, "Command is safe"

async def process_with_interpreter(
    interpreter, 
    command: str, 
    context: Optional[Dict] = None,
    ai_config: Optional[Dict] = None
) -> Dict[str, Any]:
    """معالجة الأمر باستخدام Open Interpreter مع تحسينات"""
    try:
        # بناء prompt محسن مع السياق
        prompt_parts = [
            f"المهمة: {command}",
            "",
            "قم بتحليل هذه المهمة وتحويلها إلى أوامر قابلة للتنفيذ على Windows.",
            "",
            "متطلبات الاستجابة:",
            "1. استخدم أوامر Windows صحيحة (CMD أو PowerShell)",
            "2. قدم مسارات كاملة للملفات عند الحاجة", 
            "3. تجنب العمليات المدمرة تماماً",
            "4. إذا كانت المهمة تتطلب أتمتة GUI، استخدم pyautogui",
            "5. كن دقيقاً في بناء الجملة",
            "",
        ]

        if context:
            prompt_parts.extend([
                "معلومات السياق:",
                f"- نوع العميل: {context.get('mode', 'unknown')}",
                f"- نظام التشغيل: {context.get('system_info', {}).get('platform', 'unknown')}",
                f"- معلومات إضافية: {json.dumps(context, ensure_ascii=False, indent=2)}",
                ""
            ])

        # إضافة أمثلة للتوضيح
        prompt_parts.extend([
            "أمثلة على الاستجابات المطلوبة:",
            "",
            "مثال 1 - فتح تطبيق:",
            "المهمة: 'افتح متصفح Chrome'",
            "الاستجابة: start chrome",
            "",
            "مثال 2 - إنشاء ملف:",
            "المهمة: 'أنشئ ملف نصي باسم test.txt'",
            "الاستجابة: echo. > test.txt",
            "",
            "مثال 3 - لقطة شاشة:",
            "المهمة: 'التقط لقطة شاشة'",
            "الاستجابة: import pyautogui; pyautogui.screenshot().save('screenshot.png')",
            "",
            "الآن، حلل المهمة المطلوبة واعطني الأوامر المناسبة:"
        ])

        full_prompt = "\n".join(prompt_parts)

        # الحصول على استجابة من المفسر
        try:
            response = interpreter.chat(full_prompt, display=False)
            commands = extract_commands_from_response(response)
            
            if not commands:
                # إذا لم نحصل على أوامر، استخدم المعالج الأساسي
                logger.warning("No commands extracted from interpreter, falling back to basic processing")
                return process_basic_command(command)

            return {
                "success": True,
                "actions": commands,
                "method": "interpreter",
                "raw_response": str(response)[:500] + "..." if len(str(response)) > 500 else str(response)
            }

        except Exception as e:
            logger.error(f"Interpreter chat error: {e}")
            return process_basic_command(command)

    except Exception as e:
        logger.error(f"Interpreter processing error: {e}")
        return process_basic_command(command)

def process_basic_command(command: str) -> Dict[str, Any]:
    """معالجة أساسية للأوامر بدون Open Interpreter - محسنة"""
    command_lower = command.lower().strip()
    actions = []

    # خريطة أوامر محسنة ومتوسعة
    command_mappings = {
        # متصفحات
        'open chrome': 'start chrome',
        'open browser': 'start chrome',
        'open firefox': 'start firefox',
        'open edge': 'start msedge',
        
        # تطبيقات Windows أساسية
        'open notepad': 'notepad',
        'open calculator': 'calc',
        'open file explorer': 'explorer',
        'open task manager': 'taskmgr',
        'open control panel': 'control',
        'open settings': 'start ms-settings:',
        'open cmd': 'start cmd',
        'open powershell': 'start powershell',
        
        # تطبيقات Office
        'open word': 'start winword',
        'open excel': 'start excel',
        'open powerpoint': 'start powerpnt',
        'open outlook': 'start outlook',
        
        # أوامر النظام
        'system info': 'systeminfo',
        'list files': 'dir',
        'current directory': 'cd',
        'list processes': 'tasklist',
        'network info': 'ipconfig /all',
        'disk space': 'dir C:\\ /-c',
        'system uptime': 'systeminfo | findstr "System Boot Time"',
        
        # أوامر الطاقة (آمنة مع تأخير)
        'shutdown': 'shutdown /s /t 60',
        'restart': 'shutdown /r /t 60',
        'lock screen': 'rundll32.exe user32.dll,LockWorkStation',
        'sleep': 'rundll32.exe powrprof.dll,SetSuspendState 0,1,0',
        
        # أوامر خاصة
        'take screenshot': 'screenshot_command',
        'screen capture': 'screenshot_command',
        'get screenshot': 'screenshot_command',
        'volume up': 'volume_up_command',
        'volume down': 'volume_down_command',
        'mute': 'volume_mute_command'
    }

    # البحث عن تطابق مباشر أولاً
    matched = False
    for key, value in command_mappings.items():
        if key in command_lower:
            matched = True
            
            if value == 'screenshot_command':
                actions.append({
                    "type": "python",
                    "code": """
import pyautogui
import os
from datetime import datetime

try:
    # التقاط لقطة الشاشة
    screenshot = pyautogui.screenshot()
    
    # إنشاء اسم ملف مع الوقت
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'screenshot_{timestamp}.png'
    
    # حفظ في مجلد Screenshots
    os.makedirs('Screenshots', exist_ok=True)
    filepath = os.path.join('Screenshots', filename)
    screenshot.save(filepath)
    
    print(f'Screenshot saved: {filepath}')
except Exception as e:
    print(f'Screenshot failed: {e}')
"""
                })
            elif value.endswith('_command'):
                # أوامر التحكم في الصوت
                if 'volume_up' in value:
                    actions.append({
                        "type": "python",
                        "code": """
import subprocess
try:
    # زيادة الصوت بـ 10%
    subprocess.run(['powershell', '-Command', '(New-Object -com wscript.shell).SendKeys([char]175)'], check=True)
    print('Volume increased')
except Exception as e:
    print(f'Volume control failed: {e}')
"""
                    })
                elif 'volume_down' in value:
                    actions.append({
                        "type": "python", 
                        "code": """
import subprocess
try:
    # تقليل الصوت بـ 10%
    subprocess.run(['powershell', '-Command', '(New-Object -com wscript.shell).SendKeys([char]174)'], check=True)
    print('Volume decreased')
except Exception as e:
    print(f'Volume control failed: {e}')
"""
                    })
                elif 'volume_mute' in value:
                    actions.append({
                        "type": "python",
                        "code": """
import subprocess
try:
    # كتم/إلغاء كتم الصوت
    subprocess.run(['powershell', '-Command', '(New-Object -com wscript.shell).SendKeys([char]173)'], check=True)
    print('Volume muted/unmuted')
except Exception as e:
    print(f'Mute control failed: {e}')
"""
                    })
            else:
                actions.append({
                    "type": "command",
                    "code": value
                })
            break

    # إذا لم نجد تطابق، حاول تحليل أكثر ذكاءً
    if not matched:
        actions.extend(smart_command_analysis(command))

    # إذا لم نجد أي أوامر، استخدم الأمر كما هو مع فحص الأمان
    if not actions:
        is_safe, safety_msg = validate_command_safety(command)
        if is_safe:
            actions.append({
                "type": "command",
                "code": command
            })
        else:
            actions.append({
                "type": "error",
                "code": f"Command blocked for safety: {safety_msg}"
            })

    return {
        "success": True,
        "actions": actions,
        "method": "basic_enhanced"
    }

def smart_command_analysis(command: str) -> List[Dict]:
    """تحليل ذكي للأوامر غير المطابقة"""
    command_lower = command.lower().strip()
    actions = []
    
    # تحليل أوامر فتح التطبيقات
    if any(word in command_lower for word in ['open', 'start', 'launch', 'run']):
        # استخراج اسم التطبيق
        app_name = ""
        for word in ['open', 'start', 'launch', 'run']:
            if word in command_lower:
                parts = command_lower.split(word, 1)
                if len(parts) > 1:
                    app_name = parts[1].strip()
                    break
        
        if app_name:
            # تنظيف اسم التطبيق
            app_name = app_name.replace('the ', '').replace('application', '').replace('app', '').strip()
            
            # محاولة فتح التطبيق
            actions.append({
                "type": "command",
                "code": f"start {app_name}"
            })
    
    # تحليل أوامر إنشاء الملفات
    elif any(word in command_lower for word in ['create', 'make', 'new']):
        if 'file' in command_lower or 'document' in command_lower:
            # استخراج نوع واسم الملف
            if '.txt' in command_lower:
                filename = extract_filename(command, '.txt') or 'new_file.txt'
                actions.append({
                    "type": "command",
                    "code": f"echo. > {filename}"
                })
            elif '.py' in command_lower:
                filename = extract_filename(command, '.py') or 'new_script.py'
                actions.append({
                    "type": "command",
                    "code": f"echo # New Python script > {filename}"
                })
    
    # تحليل أوامر البحث
    elif any(word in command_lower for word in ['search', 'find', 'look for']):
        search_term = extract_search_term(command)
        if search_term:
            actions.append({
                "type": "command",
                "code": f"dir /s *{search_term}*"
            })
    
    # تحليل أوامر الشبكة
    elif any(word in command_lower for word in ['ping', 'connect', 'test connection']):
        if 'ping' in command_lower:
            target = extract_ping_target(command)
            if target:
                actions.append({
                    "type": "command",
                    "code": f"ping {target} -n 4"
                })
    
    return actions

def extract_filename(command: str, extension: str) -> Optional[str]:
    """استخراج اسم الملف من الأمر"""
    try:
        words = command.split()
        for i, word in enumerate(words):
            if extension in word:
                return word
            # البحث عن كلمة تبدو كاسم ملف
            if i > 0 and any(key in words[i-1].lower() for key in ['called', 'named', 'called']):
                return f"{word}{extension}"
    except:
        pass
    return None

def extract_search_term(command: str) -> Optional[str]:
    """استخراج مصطلح البحث من الأمر"""
    try:
        for keyword in ['search for', 'find', 'look for']:
            if keyword in command.lower():
                parts = command.lower().split(keyword, 1)
                if len(parts) > 1:
                    return parts[1].strip().strip('"\'')
    except:
        pass
    return None

def extract_ping_target(command: str) -> Optional[str]:
    """استخراج هدف ping من الأمر"""
    try:
        words = command.split()
        for word in words:
            # البحث عن IP أو domain
            if '.' in word and not word.startswith('.'):
                return word
    except:
        pass
    return "google.com"  # افتراضي

def extract_commands_from_response(response) -> List[Dict]:
    """استخراج الأوامر من استجابة المفسر - محسن"""
    commands = []

    if not response:
        return commands

    try:
        # معالجة استجابة Open Interpreter
        if isinstance(response, list):
            for item in response:
                if isinstance(item, dict):
                    if item.get('type') == 'code':
                        content = item.get('content', '').strip()
                        language = item.get('format', 'auto')
                        
                        if content:
                            commands.append({
                                'type': 'execute' if language == 'python' else 'command',
                                'code': content,
                                'language': language
                            })
                    
                    elif item.get('type') == 'message':
                        content = item.get('content', '')
                        # استخراج كتل الكود من الرسالة
                        if '```' in content:
                            extracted_commands = extract_code_blocks(content)
                            commands.extend(extracted_commands)
                        elif content.strip():
                            # إذا كان النص يبدو كأمر مباشر
                            if is_likely_command(content):
                                commands.append({
                                    'type': 'command',
                                    'code': content.strip(),
                                    'language': 'cmd'
                                })

        # معالجة الاستجابة كنص
        elif isinstance(response, str):
            if '```' in response:
                commands.extend(extract_code_blocks(response))
            elif is_likely_command(response):
                commands.append({
                    'type': 'command',
                    'code': response.strip(),
                    'language': 'cmd'
                })

    except Exception as e:
        logger.error(f"Error extracting commands: {e}")

    return commands

def extract_code_blocks(text: str) -> List[Dict]:
    """استخراج كتل الكود من النص"""
    commands = []
    try:
        blocks = text.split('```')
        for i, block in enumerate(blocks):
            if i % 2 == 1:  # كتل الكود في المواضع الفردية
                lines = block.strip().split('\n')
                if lines:
                    # إزالة تحديد اللغة من السطر الأول إن وجد
                    first_line = lines[0].strip()
                    if first_line in ['python', 'cmd', 'powershell', 'bash', 'shell']:
                        code = '\n'.join(lines[1:])
                        language = first_line
                    else:
                        code = block.strip()
                        language = 'auto'
                    
                    if code:
                        commands.append({
                            'type': 'execute' if language == 'python' else 'command',
                            'code': code,
                            'language': language
                        })
    except Exception as e:
        logger.error(f"Error extracting code blocks: {e}")
    
    return commands

def is_likely_command(text: str) -> bool:
    """تحديد ما إذا كان النص يبدو كأمر"""
    text = text.strip().lower()
    
    # كلمات مفتاحية تدل على الأوامر
    command_indicators = [
        'start', 'run', 'execute', 'open', 'close',
        'dir', 'ls', 'cd', 'mkdir', 'echo',
        'ping', 'ipconfig', 'tasklist', 'taskkill'
    ]
    
    return any(indicator in text for indicator in command_indicators)

def get_system_status() -> Dict[str, Any]:
    """الحصول على حالة النظام الحالية"""
    try:
        status = {
            "os": platform.system(),
            "platform": platform.platform(),
            "python_version": platform.python_version(),
            "cpu_count": psutil.cpu_count(),
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory": {
                "total": psutil.virtual_memory().total,
                "available": psutil.virtual_memory().available,
                "percent": psutil.virtual_memory().percent
            },
            "disk": {
                "total": psutil.disk_usage('/').total if platform.system() != 'Windows' else psutil.disk_usage('C:\\').total,
                "free": psutil.disk_usage('/').free if platform.system() != 'Windows' else psutil.disk_usage('C:\\').free,
                "percent": psutil.disk_usage('/').percent if platform.system() != 'Windows' else psutil.disk_usage('C:\\').percent
            }
        }
        
        # فحص Ollama
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=3)
            status["ollama"] = {
                "status": "running" if response.status_code == 200 else "error",
                "models": response.json() if response.status_code == 200 else []
            }
        except:
            status["ollama"] = {"status": "not_running", "models": []}
        
        return status
        
    except Exception as e:
        logger.error(f"Error getting system status: {e}")
        return {"error": str(e)}