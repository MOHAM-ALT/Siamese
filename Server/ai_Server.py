import os
import sys
import json
import asyncio
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# Try importing required packages
try:
    from fastapi import FastAPI, WebSocket, HTTPException
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    import uvicorn
except ImportError as e:
    print(f"Error: Missing required package - {e}")
    print("Please run: pip install fastapi uvicorn websockets")
    sys.exit(1)

try:
    import interpreter
    INTERPRETER_AVAILABLE = True
except ImportError:
    print("Warning: Open Interpreter not installed")
    print("Run: pip install open-interpreter")
    INTERPRETER_AVAILABLE = False
    interpreter = None

# Setup logging
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(title="AI Control Server", version="2.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Open Interpreter if available
if INTERPRETER_AVAILABLE and interpreter:
    interpreter.llm.model = "ollama/qwen2.5-coder:7b"
    interpreter.llm.api_base = "http://localhost:11434"
    interpreter.auto_run = False
    interpreter.safe_mode = 'off'
    interpreter.system_message = """
    You are an AI assistant that controls Windows computers remotely.
    Analyze commands and return executable instructions.
    Be precise and ensure commands are correct for Windows systems.
    """

class AIController:
    def __init__(self):
        self.clients: Dict[int, WebSocket] = {}
        self.command_history = []
        logger.info("AI Controller initialized")

    async def process_command(self, command: str, context: Optional[Dict] = None) -> Dict[str, Any]:
        """Process commands with AI"""
        try:
            logger.info(f"Processing command: {command}")
            
            # If interpreter is not available, return basic response
            if not INTERPRETER_AVAILABLE or not interpreter:
                logger.warning("Open Interpreter not available, using basic mode")
                return self.basic_command_processor(command)
            
            # Build prompt
            full_prompt = f"User command: {command}\n"
            if context:
                full_prompt += f"Context: {json.dumps(context)}\n"
            
            full_prompt += """
            Return executable commands in this JSON format:
            {
                "actions": [
                    {
                        "type": "command",
                        "code": "the actual command or code to execute"
                    }
                ]
            }
            """
            
            # Process with interpreter
            response = interpreter.chat(full_prompt, display=False)
            commands = self.extract_commands(response)
            
            # Log to history
            self.command_history.append({
                "timestamp": datetime.now().isoformat(),
                "input": command,
                "output": commands
            })
            
            logger.info("Command processed successfully")
            return commands
            
        except Exception as e:
            logger.error(f"Error processing command: {e}")
            return {"error": str(e), "actions": []}

    def basic_command_processor(self, command: str) -> Dict[str, Any]:
        """Basic command processor when Open Interpreter is not available"""
        command_lower = command.lower()
        actions = []
        
        # Basic command mapping
        if "open chrome" in command_lower:
            actions.append({
                "type": "command",
                "code": "start chrome"
            })
        elif "open notepad" in command_lower:
            actions.append({
                "type": "command",
                "code": "notepad"
            })
        elif "open youtube" in command_lower:
            actions.append({
                "type": "command",
                "code": "start chrome https://www.youtube.com"
            })
        elif "screenshot" in command_lower:
            actions.append({
                "type": "execute",
                "code": "import pyautogui; pyautogui.screenshot().save('screenshot.png')"
            })
        elif "task manager" in command_lower:
            actions.append({
                "type": "command",
                "code": "taskmgr"
            })
        elif "file explorer" in command_lower:
            actions.append({
                "type": "command",
                "code": "explorer"
            })
        else:
            # Try to execute as is
            actions.append({
                "type": "command",
                "code": command
            })
        
        return {"actions": actions}

    def extract_commands(self, response) -> Dict[str, Any]:
        """Extract commands from interpreter response"""
        if not response:
            return {"actions": []}
        
        commands = []
        for message in response:
            if isinstance(message, dict) and message.get('type') == 'code':
                code = message.get('content', '')
                commands.append({
                    'type': 'execute',
                    'code': code
                })
        
        return {"actions": commands}

# Initialize controller
ai_controller = AIController()

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "status": "AI Server Running",
        "version": "2.0",
        "interpreter_available": INTERPRETER_AVAILABLE,
        "endpoints": {
            "websocket": "/ws",
            "process": "/process",
            "status": "/status"
        }
    }

@app.get("/status")
async def status():
    """Status endpoint"""
    return {
        "status": "online",
        "interpreter_available": INTERPRETER_AVAILABLE,
        "total_commands": len(ai_controller.command_history),
        "connected_clients": len(ai_controller.clients),
        "timestamp": datetime.now().isoformat()
    }

@app.post("/process")
async def process_command(data: Dict[str, Any]):
    """Process a single command"""
    command = data.get('command')
    if not command:
        raise HTTPException(status_code=400, detail="No command provided")
    
    context = data.get('context')
    result = await ai_controller.process_command(command, context)
    return JSONResponse(content=result)

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time communication"""
    await websocket.accept()
    client_id = id(websocket)
    ai_controller.clients[client_id] = websocket
    logger.info(f"Client {client_id} connected")
    
    try:
        # Send welcome message
        await websocket.send_text(json.dumps({
            "type": "connected",
            "message": "Connected to AI Server",
            "interpreter_available": INTERPRETER_AVAILABLE
        }))
        
        # Message loop
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            command = message.get('command')
            if command:
                result = await ai_controller.process_command(command)
                await websocket.send_text(json.dumps(result))
                
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
    finally:
        if client_id in ai_controller.clients:
            del ai_controller.clients[client_id]
        logger.info(f"Client {client_id} disconnected")

if __name__ == "__main__":
    import socket
    
    # Get local IP
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    print("\n" + "="*60)
    print("AI CONTROL SERVER")
    print("="*60)
    print(f"Local URL: http://localhost:8000")
    print(f"Network URL: http://{local_ip}:8000")
    print(f"WebSocket: ws://{local_ip}:8000/ws")
    print("="*60)
    print("Press Ctrl+C to stop the server\n")
    
    # Start server
    logger.info("Starting server...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
