# src/server/core/controller.py
import json
import logging
import time
from datetime import datetime
from typing import Dict, Any, Optional, List
from fastapi import WebSocket

from ..services.interpreter import (
    process_with_interpreter, 
    process_basic_command,
    get_system_status,
    validate_command_safety
)
from ..config import switch_ai_model, get_available_models, load_ai_config

logger = logging.getLogger(__name__)

class AIController:
    """المعالج الرئيسي للذكاء الاصطناعي مع دعم متعدد المقدمين"""
    
    def __init__(self, interpreter_instance=None):
        self.clients: Dict[int, WebSocket] = {}
        self.command_history: List[Dict] = []
        self.max_history = 100
        self.interpreter = interpreter_instance
        self.ai_config = load_ai_config()
        
        # إحصائيات الاستخدام
        self.stats = {
            "total_commands": 0,
            "successful_commands": 0,
            "failed_commands": 0,
            "blocked_commands": 0,
            "uptime_start": datetime.now(),
            "last_command_time": None,
            "active_provider": self.ai_config.get("default_provider", "basic"),
            "active_model": self._get_current_model()
        }
        
        logger.info("✅ AI Controller initialized")
        logger.info(f"🤖 Active AI: {self.stats['active_provider']}/{self.stats['active_model']}")

    def _get_current_model(self) -> str:
        """الحصول على النموذج النشط حالياً"""
        provider = self.ai_config.get("default_provider", "basic")
        if provider == "basic":
            return "basic_commands"
        
        provider_config = self.ai_config.get("providers", {}).get(provider, {})
        return provider_config.get("default_model", "unknown")

    async def process_command(self, command: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """معالجة الأوامر مع AI محسن"""
        start_time = time.time()
        self.stats["total_commands"] += 1
        self.stats["last_command_time"] = datetime.now()
        
        try:
            logger.info(f"🔄 Processing command: {command[:100]}...")
            
            # التحقق من صحة الأمر
            if not command or not command.strip():
                self.stats["failed_commands"] += 1
                return {"error": "Empty command", "actions": [], "processing_time": 0}

            command = command.strip()
            
            # فحص الأمان
            is_safe, safety_message = validate_command_safety(command)
            if not is_safe:
                self.stats["blocked_commands"] += 1
                logger.warning(f"🚫 Command blocked: {safety_message}")
                return {
                    "error": f"Command blocked for safety: {safety_message}",
                    "actions": [],
                    "processing_time": time.time() - start_time,
                    "safety_block": True
                }

            # معالجة الأمر
            if self.interpreter:
                result = await process_with_interpreter(
                    self.interpreter, command, context, self.ai_config
                )
            else:
                result = process_basic_command(command)

            # إضافة معلومات إضافية للنتيجة
            processing_time = time.time() - start_time
            result.update({
                "timestamp": datetime.now().isoformat(),
                "processing_time": processing_time,
                "provider": self.stats["active_provider"],
                "model": self.stats["active_model"],
                "client_context": context
            })

            # تحديث الإحصائيات
            if result.get("success", False):
                self.stats["successful_commands"] += 1
            else:
                self.stats["failed_commands"] += 1

            # حفظ في التاريخ
            self._add_to_history(command, result)
            
            logger.info(f"✅ Command processed successfully in {processing_time:.2f}s")
            return result

        except Exception as e:
            self.stats["failed_commands"] += 1
            processing_time = time.time() - start_time
            error_msg = f"Error processing command: {str(e)}"
            logger.error(f"❌ {error_msg}", exc_info=True)
            
            return {
                "error": error_msg,
                "actions": [],
                "processing_time": processing_time,
                "timestamp": datetime.now().isoformat()
            }

    async def switch_ai_provider(self, provider: str, model: str) -> Dict[str, Any]:
        """تبديل مقدم خدمة AI أثناء التشغيل"""
        try:
            success, message = switch_ai_model(self.interpreter, provider, model, self.ai_config)
            
            if success:
                # تحديث التكوين المحلي
                self.ai_config = load_ai_config()
                self.stats["active_provider"] = provider
                self.stats["active_model"] = model
                
                # إشعار جميع العملاء
                await self.broadcast_to_clients({
                    "type": "ai_provider_changed",
                    "provider": provider,
                    "model": model,
                    "timestamp": datetime.now().isoformat()
                })
                
                logger.info(f"🔄 AI provider switched to {provider}/{model}")
            
            return {"success": success, "message": message}
            
        except Exception as e:
            error_msg = f"Failed to switch AI provider: {str(e)}"
            logger.error(error_msg)
            return {"success": False, "message": error_msg}

    def get_available_ai_models(self) -> Dict[str, Any]:
        """الحصول على قائمة نماذج AI المتاحة"""
        try:
            available = get_available_models(self.ai_config)
            return {
                "success": True,
                "current_provider": self.stats["active_provider"],
                "current_model": self.stats["active_model"],
                "available_models": available
            }
        except Exception as e:
            logger.error(f"Error getting available models: {e}")
            return {"success": False, "error": str(e)}

    def get_server_stats(self) -> Dict[str, Any]:
        """الحصول على إحصائيات مفصلة للخادم"""
        uptime = datetime.now() - self.stats["uptime_start"]
        
        # حساب معدل النجاح
        total_executed = self.stats["successful_commands"] + self.stats["failed_commands"]
        success_rate = (self.stats["successful_commands"] / total_executed * 100) if total_executed > 0 else 0
        
        return {
            "uptime": {
                "seconds": uptime.total_seconds(),
                "formatted": str(uptime).split('.')[0]  # إزالة المايكروثواني
            },
            "commands": {
                "total": self.stats["total_commands"],
                "successful": self.stats["successful_commands"],
                "failed": self.stats["failed_commands"],
                "blocked": self.stats["blocked_commands"],
                "success_rate": round(success_rate, 2)
            },
            "ai_info": {
                "provider": self.stats["active_provider"],
                "model": self.stats["active_model"],
                "interpreter_available": self.interpreter is not None
            },
            "connections": {
                "active_clients": len(self.clients),
                "total_history_entries": len(self.command_history)
            },
            "last_activity": self.stats["last_command_time"].isoformat() if self.stats["last_command_time"] else None,
            "system": get_system_status()
        }

    def _add_to_history(self, command: str, result: Dict):
        """إضافة الأمر للتاريخ مع حد أقصى للحجم"""
        history_entry = {
            "id": len(self.command_history) + 1,
            "timestamp": datetime.now().isoformat(),
            "input": command,
            "output": result,
            "provider": self.stats["active_provider"],
            "model": self.stats["active_model"],
            "success": result.get("success", False),
            "processing_time": result.get("processing_time", 0)
        }

        self.command_history.append(history_entry)

        # الحفاظ على حد أقصى للتاريخ
        if len(self.command_history) > self.max_history:
            self.command_history = self.command_history[-self.max_history:]

    def get_history(self, limit: int = 10, include_errors: bool = True) -> List[Dict]:
        """الحصول على تاريخ الأوامر مع خيارات تصفية"""
        history = self.command_history[-limit:]
        
        if not include_errors:
            history = [entry for entry in history if entry.get("success", False)]
        
        return history

    def clear_history(self) -> bool:
        """مسح تاريخ الأوامر"""
        try:
            self.command_history.clear()
            logger.info("🗑️ Command history cleared")
            return True
        except Exception as e:
            logger.error(f"Error clearing history: {e}")
            return False

    async def broadcast_to_clients(self, message: Dict):
        """بث رسالة لجميع العملاء المتصلين"""
        if not self.clients:
            return

        disconnected_clients = []
        for client_id, websocket in self.clients.items():
            try:
                await websocket.send_text(json.dumps(message, ensure_ascii=False))
            except Exception as e:
                logger.warning(f"Failed to send message to client {client_id}: {e}")
                disconnected_clients.append(client_id)

        # تنظيف العملاء المنقطعين
        for client_id in disconnected_clients:
            if client_id in self.clients:
                del self.clients[client_id]
                logger.info(f"🔌 Client {client_id} disconnected")

    async def handle_special_commands(self, command: str) -> Optional[Dict[str, Any]]:
        """معالجة الأوامر الخاصة للخادم"""
        command_lower = command.lower().strip()
        
        if command_lower == "server:stats":
            return {
                "success": True,
                "actions": [{"type": "info", "data": self.get_server_stats()}],
                "special_command": True
            }
        
        elif command_lower == "server:models":
            return {
                "success": True,
                "actions": [{"type": "info", "data": self.get_available_ai_models()}],
                "special_command": True
            }
        
        elif command_lower.startswith("server:switch "):
            # تبديل النموذج: server:switch provider/model
            try:
                switch_part = command_lower.replace("server:switch ", "")
                if "/" in switch_part:
                    provider, model = switch_part.split("/", 1)
                    result = await self.switch_ai_provider(provider.strip(), model.strip())
                    return {
                        "success": result["success"],
                        "actions": [{"type": "info", "data": result}],
                        "special_command": True
                    }
            except Exception as e:
                return {
                    "success": False,
                    "error": f"Invalid switch command format: {e}",
                    "special_command": True
                }
        
        elif command_lower == "server:clear-history":
            success = self.clear_history()
            return {
                "success": success,
                "actions": [{"type": "info", "data": {"message": "History cleared" if success else "Failed to clear history"}}],
                "special_command": True
            }
        
        return None  # ليس أمر خاص