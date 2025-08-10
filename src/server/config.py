# src/server/config.py
import logging
import os
import json
from typing import Dict, Any, Optional

def setup_logging():
    """إعداد نظام تسجيل محسن"""
    os.makedirs('logs', exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('logs/server.log', mode='w', encoding='utf-8'),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

def load_ai_config() -> Dict[str, Any]:
    """تحميل إعدادات AI من ملف التكوين"""
    config_file = "ai_models_config.json"
    default_config = {
        "default_provider": "ollama",
        "providers": {
            "ollama": {
                "enabled": True,
                "base_url": "http://localhost:11434",
                "default_model": "qwen2.5-coder:7b",
                "models": [
                    "qwen2.5-coder:7b",
                    "llama3.2:3b", 
                    "mistral:7b",
                    "deepseek-coder:6.7b",
                    "phi3:mini"
                ]
            },
            "openai": {
                "enabled": False,
                "api_key": "",
                "default_model": "gpt-4",
                "models": ["gpt-4", "gpt-3.5-turbo"]
            },
            "anthropic": {
                "enabled": False,
                "api_key": "",
                "default_model": "claude-3-sonnet-20240229",
                "models": ["claude-3-opus-20240229", "claude-3-sonnet-20240229"]
            },
            "google": {
                "enabled": False,
                "api_key": "",
                "default_model": "gemini-pro",
                "models": ["gemini-pro", "gemini-pro-vision"]
            }
        }
    }
    
    try:
        if os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
    except Exception as e:
        logging.error(f"Error loading AI config: {e}")
    
    # إنشاء ملف التكوين الافتراضي
    try:
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)
        logging.info(f"Created default AI config: {config_file}")
    except Exception as e:
        logging.error(f"Error creating default config: {e}")
    
    return default_config

def configure_interpreter(interpreter, ai_config: Optional[Dict] = None):
    """تكوين Open Interpreter مع دعم AI متعدد"""
    if not ai_config:
        ai_config = load_ai_config()
    
    try:
        provider = ai_config.get("default_provider", "ollama")
        provider_config = ai_config.get("providers", {}).get(provider, {})
        
        if not provider_config.get("enabled", False):
            logging.warning(f"Provider {provider} is disabled")
            return None
        
        if provider == "ollama":
            model = provider_config.get("default_model", "qwen2.5-coder:7b")
            base_url = provider_config.get("base_url", "http://localhost:11434")
            
            interpreter.llm.model = f"ollama/{model}"
            interpreter.llm.api_base = base_url
            interpreter.auto_run = False
            interpreter.safe_mode = 'off'
            
        elif provider == "openai":
            api_key = provider_config.get("api_key", "")
            if not api_key:
                logging.error("OpenAI API key not provided")
                return None
            
            interpreter.llm.model = provider_config.get("default_model", "gpt-4")
            interpreter.llm.api_key = api_key
            
        elif provider == "anthropic":
            api_key = provider_config.get("api_key", "")
            if not api_key:
                logging.error("Anthropic API key not provided")
                return None
            
            interpreter.llm.model = provider_config.get("default_model", "claude-3-sonnet-20240229")
            interpreter.llm.api_key = api_key
            
        elif provider == "google":
            api_key = provider_config.get("api_key", "")
            if not api_key:
                logging.error("Google API key not provided")
                return None
            
            interpreter.llm.model = provider_config.get("default_model", "gemini-pro")
            interpreter.llm.api_key = api_key
        
        # إعداد رسالة النظام المحسنة
        interpreter.system_message = """أنت مساعد ذكي للتحكم عن بُعد في أجهزة الكمبيوتر.
        
المهام الأساسية:
- تحليل أوامر المستخدم بالذكاء الاصطناعي
- تحويل الطلبات إلى أوامر قابلة للتنفيذ
- التركيز على أوامر Windows وأتمتة المهام
- إعطاء الأولوية للأمان وطلب التأكيد للعمليات المدمرة

قواعد الأمان:
- تجنب أوامر حذف النظام أو تهيئة الأقراص
- استخدم مسارات كاملة للملفات
- قدم بناء جملة دقيق للأوامر
- اطلب التأكيد للعمليات الخطيرة

أنواع الأوامر المدعومة:
- فتح التطبيقات (open chrome, notepad, etc.)
- إدارة الملفات (create, copy, move, etc.)
- تحكم النظام (screenshot, system info, etc.)
- أتمتة GUI (click, type, hotkeys)
- أوامر PowerShell و CMD

استجب بتنسيق JSON مع actions قابلة للتنفيذ."""
        
        logging.info(f"✅ Open Interpreter configured with {provider} ({provider_config.get('default_model')})")
        return interpreter
        
    except Exception as e:
        logging.error(f"❌ Error configuring Open Interpreter: {e}")
        return None

def get_available_models(ai_config: Optional[Dict] = None) -> Dict[str, list]:
    """الحصول على قائمة النماذج المتاحة لكل مقدم خدمة"""
    if not ai_config:
        ai_config = load_ai_config()
    
    available_models = {}
    for provider, config in ai_config.get("providers", {}).items():
        if config.get("enabled", False):
            available_models[provider] = config.get("models", [])
    
    return available_models

def switch_ai_model(interpreter, provider: str, model: str, ai_config: Optional[Dict] = None):
    """تبديل نموذج AI أثناء التشغيل"""
    if not ai_config:
        ai_config = load_ai_config()
    
    try:
        provider_config = ai_config.get("providers", {}).get(provider, {})
        if not provider_config.get("enabled", False):
            return False, f"Provider {provider} is disabled"
        
        if model not in provider_config.get("models", []):
            return False, f"Model {model} not available for {provider}"
        
        # تحديث التكوين
        ai_config["default_provider"] = provider
        ai_config["providers"][provider]["default_model"] = model
        
        # حفظ التكوين المحدث
        with open("ai_models_config.json", 'w', encoding='utf-8') as f:
            json.dump(ai_config, f, indent=2, ensure_ascii=False)
        
        # إعادة تكوين المفسر
        new_interpreter = configure_interpreter(interpreter, ai_config)
        if new_interpreter:
            logging.info(f"✅ Switched to {provider}/{model}")
            return True, f"Successfully switched to {provider}/{model}"
        else:
            return False, f"Failed to configure {provider}/{model}"
            
    except Exception as e:
        logging.error(f"Error switching model: {e}")
        return False, str(e)