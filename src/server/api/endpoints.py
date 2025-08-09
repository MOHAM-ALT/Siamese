import json
import logging
from datetime import datetime
from typing import Dict, Any

from fastapi import FastAPI, WebSocket, HTTPException, Request
from fastapi.responses import JSONResponse, HTMLResponse

logger = logging.getLogger(__name__)

def register_endpoints(app: FastAPI, controller):

    @app.get("/")
    async def root():
        """Root endpoint with server information"""
        return HTMLResponse(content=f\"\"\"
        <!DOCTYPE html>
        <html>
        <head>
            <title>AI Control Server</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
                .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
                .status {{ color: #28a745; font-weight: bold; }}
                .info {{ background: #e7f3ff; padding: 15px; border-left: 4px solid #007bff; margin: 15px 0; }}
                .endpoint {{ background: #f8f9fa; padding: 10px; margin: 5px 0; border-radius: 5px; font-family: monospace; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>AI Control Server <span class="status">[ONLINE]</span></h1>
                <div class="info">
                    <h3>Server Status</h3>
                    <p>Version: 2.0</p>
                    <p>Open Interpreter: {"Available" if controller.interpreter else "Not Available"}</p>
                    <p>Active Connections: {len(controller.clients)}</p>
                    <p>Commands Processed: {len(controller.command_history)}</p>
                </div>
                <h3>Available Endpoints</h3>
                <div class="endpoint">GET /status - Server status information</div>
                <div class="endpoint">POST /process - Process single command</div>
                <div class="endpoint">GET /history - Get command history</div>
                <div class="endpoint">WebSocket /ws - Real-time communication</div>
            </div>
        </body>
        </html>
        \"\"\")

    @app.get("/status")
    async def get_status():
        """Get server status"""
        # This will need to be improved, maybe move requests to a service
        import requests
        ollama_status = "disconnected"
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=5)
            if response.status_code == 200:
                ollama_status = "connected"
        except:
            pass

        return {
            "status": "online",
            "version": "2.0",
            "timestamp": datetime.now().isoformat(),
            "interpreter_available": controller.interpreter is not None,
            "ollama_status": ollama_status,
            "connected_clients": len(controller.clients),
            "total_commands": len(controller.command_history),
            "uptime": "running"
        }

    @app.post("/process")
    async def process_command_endpoint(request: Request):
        """Process a single command"""
        try:
            data = await request.json()
            command = data.get('command')

            if not command:
                raise HTTPException(status_code=400, detail="No command provided")

            context = data.get('context')
            result = await controller.process_command(command, context)

            await controller.broadcast_to_clients({
                "type": "command_processed",
                "command": command,
                "result": result
            })

            return JSONResponse(content=result)

        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid JSON")
        except Exception as e:
            logger.error(f"Command processing error: {e}")
            raise HTTPException(status_code=500, detail=str(e))

    @app.get("/history")
    async def get_history(limit: int = 10):
        """Get command history"""
        return {
            "history": controller.get_history(limit),
            "total_commands": len(controller.command_history)
        }

    @app.websocket("/ws")
    async def websocket_endpoint(websocket: WebSocket):
        """WebSocket endpoint for real-time communication"""
        await websocket.accept()
        client_id = id(websocket)
        controller.clients[client_id] = websocket

        logger.info(f"WebSocket client {client_id} connected")

        try:
            await websocket.send_text(json.dumps({
                "type": "connection_established",
                "client_id": client_id,
                "message": "Connected to AI Control Server",
                "server_info": {
                    "version": "2.0",
                    "interpreter_available": controller.interpreter is not None,
                    "timestamp": datetime.now().isoformat()
                }
            }))

            while True:
                try:
                    data = await websocket.receive_text()
                    message = json.loads(data)

                    message_type = message.get('type', 'command')

                    if message_type == 'command':
                        command = message.get('command')
                        if command:
                            context = message.get('context')
                            result = await controller.process_command(command, context)

                            await websocket.send_text(json.dumps({
                                "type": "command_result",
                                "command": command,
                                "result": result,
                                "timestamp": datetime.now().isoformat()
                            }))
                        else:
                            await websocket.send_text(json.dumps({"type": "error", "message": "No command provided"}))

                    elif message_type == 'ping':
                        await websocket.send_text(json.dumps({"type": "pong", "timestamp": datetime.now().isoformat()}))

                    elif message_type == 'get_status':
                        status = await get_status()
                        await websocket.send_text(json.dumps({"type": "status_response", "status": status}))

                except Exception as e:
                    logger.error(f"WebSocket message handling error: {e}")
                    # Handle specific exceptions if needed
                    break

        except Exception as e:
            logger.error(f"WebSocket error for client {client_id}: {e}")
        finally:
            if client_id in controller.clients:
                del controller.clients[client_id]
            logger.info(f"WebSocket client {client_id} disconnected")

    @app.get("/health")
    async def health_check():
        """Simple health check"""
        return {"status": "healthy", "timestamp": datetime.now().isoformat()}
