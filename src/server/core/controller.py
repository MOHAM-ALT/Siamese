import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List
from fastapi import WebSocket

# Assuming interpreter service is in a sibling directory
from ..services.interpreter import process_with_interpreter, process_basic_command

logger = logging.getLogger(__name__)

class AIController:
    def __init__(self, interpreter_instance=None):
        self.clients: Dict[int, WebSocket] = {}
        self.command_history: List[Dict] = []
        self.max_history = 100
        self.interpreter = interpreter_instance
        logger.info("AI Controller initialized")

    async def process_command(self, command: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process commands with AI assistance"""
        try:
            logger.info(f"Processing command: {command[:100]}...")

            if not command or not command.strip():
                return {"error": "Empty command", "actions": []}

            command = command.strip()

            if self.interpreter:
                result = await process_with_interpreter(self.interpreter, command, context)
            else:
                result = process_basic_command(command)

            result["timestamp"] = datetime.now().isoformat()
            self._add_to_history(command, result)
            return result

        except Exception as e:
            logger.error(f"Error processing command: {e}")
            return {
                "error": str(e),
                "actions": [],
                "timestamp": datetime.now().isoformat()
            }

    def _add_to_history(self, command: str, result: Dict):
        """Add command to history with size limit"""
        history_entry = {
            "timestamp": datetime.now().isoformat(),
            "input": command,
            "output": result
        }

        self.command_history.append(history_entry)

        if len(self.command_history) > self.max_history:
            self.command_history = self.command_history[-self.max_history:]

    def get_history(self, limit: int = 10) -> List[Dict]:
        """Get recent command history"""
        return self.command_history[-limit:]

    async def broadcast_to_clients(self, message: Dict):
        """Broadcast message to all connected clients"""
        if not self.clients:
            return

        disconnected_clients = []
        for client_id, websocket in self.clients.items():
            try:
                await websocket.send_text(json.dumps(message))
            except Exception:
                disconnected_clients.append(client_id)

        for client_id in disconnected_clients:
            if client_id in self.clients:
                del self.clients[client_id]
