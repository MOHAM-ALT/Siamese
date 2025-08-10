@echo off
echo Creating missing project files...

:: Create directory structure
mkdir src\client\core 2>nul
mkdir src\server\core 2>nul
mkdir src\server\api 2>nul
mkdir src\server\services 2>nul

:: Create __init__.py files
echo. > src\__init__.py
echo. > src\client\__init__.py
echo. > src\client\core\__init__.py
echo. > src\server\__init__.py
echo. > src\server\core\__init__.py
echo. > src\server\api\__init__.py
echo. > src\server\services\__init__.py

:: Create src/client/config.py
(
echo import json
echo import os
echo import logging
echo.
echo logger = logging.getLogger^(__name__^)
echo.
echo DEFAULT_CONFIG = {
echo     'server_ip': '127.0.0.1',
echo     'server_port': 8000,
echo     'websocket_port': 8000,
echo     'auto_reconnect': True,
echo     'max_reconnect_attempts': 5,
echo     'reconnect_delay': 3,
echo     'screenshot_quality': 80,
echo     'safety_mode': True,
echo     'log_commands': True
echo }
echo.
echo def load_config^(^):
echo     """Load configuration from file, with fallbacks."""
echo     config_file = 'client_config.json'
echo     
echo     try:
echo         if os.path.exists^(config_file^):
echo             with open^(config_file, 'r'^) as f:
echo                 config = json.load^(f^)
echo             logger.info^(f"Configuration loaded from {config_file}"^)
echo             for key, value in DEFAULT_CONFIG.items^(^):
echo                 config.setdefault^(key, value^)
echo             return config
echo         else:
echo             logger.warning^("No configuration file found. Using default settings."^)
echo             return DEFAULT_CONFIG
echo     except Exception as e:
echo         logger.error^(f"Error loading configuration: {e}"^)
echo         return DEFAULT_CONFIG
echo.
echo def get_server_url^(config^):
echo     """Construct the WebSocket server URL from config."""
echo     server_ip = config.get^('server_ip', '127.0.0.1'^)
echo     ws_port = config.get^('websocket_port', 8000^)
echo     return f"ws://{server_ip}:{ws_port}/ws"
) > src\client\config.py

:: Create src/client/connection.py
(
echo import websocket
echo import json
echo import time
echo import logging
echo.
echo logger = logging.getLogger^(__name__^)
echo.
echo class Connection:
echo     def __init__^(self, server_url, config^):
echo         self.ws = None
echo         self.server_url = server_url
echo         self.config = config
echo         self.reconnect_attempts = 0
echo         self.max_reconnects = self.config.get^('max_reconnect_attempts', 5^)
echo         self.reconnect_delay = self.config.get^('reconnect_delay', 3^)
echo.
echo     def connect^(self^):
echo         """Establish WebSocket connection with retry logic."""
echo         if self.is_connected^(^):
echo             return True
echo         return self._reconnect^(^)
echo.
echo     def _reconnect^(self^):
echo         """Internal method to handle reconnection attempts."""
echo         self.reconnect_attempts = 0
echo         while self.reconnect_attempts ^< self.max_reconnects:
echo             try:
echo                 logger.info^(f"Attempting to connect to {self.server_url} ^(Attempt {self.reconnect_attempts + 1}^)..."^)
echo                 self.ws = websocket.create_connection^(self.server_url, timeout=10^)
echo                 logger.info^("Connection successful."^)
echo                 print^(f"Connected to server: {self.config.get^('server_ip'^)}"^)
echo                 self.reconnect_attempts = 0
echo                 return True
echo             except Exception as e:
echo                 logger.error^(f"Connection attempt failed: {e}"^)
echo                 print^(f"Connection failed: {e}"^)
echo                 self.reconnect_attempts += 1
echo                 if self.reconnect_attempts ^< self.max_reconnects:
echo                     logger.info^(f"Retrying in {self.reconnect_delay} seconds..."^)
echo                     print^(f"Retrying in {self.reconnect_delay} seconds..."^)
echo                     time.sleep^(self.reconnect_delay^)
echo                 else:
echo                     logger.error^("Max reconnect attempts reached."^)
echo                     print^("Could not connect to the server."^)
echo                     return False
echo         return False
echo.
echo     def disconnect^(self^):
echo         """Safely close the WebSocket connection."""
echo         if self.ws:
echo             try:
echo                 self.ws.close^(^)
echo                 logger.info^("Connection closed."^)
echo             except Exception as e:
echo                 logger.error^(f"Error during disconnection: {e}"^)
echo             finally:
echo                 self.ws = None
echo.
echo     def send_message^(self, message: dict^):
echo         """Send a JSON message."""
echo         if not self.is_connected^(^):
echo             logger.warning^("Connection lost. Attempting to reconnect..."^)
echo             if not self._reconnect^(^):
echo                 return False
echo         try:
echo             self.ws.send^(json.dumps^(message^)^)
echo             return True
echo         except Exception as e:
echo             logger.error^(f"Failed to send message: {e}"^)
echo             self.disconnect^(^)
echo             return False
echo.
echo     def receive_message^(self^):
echo         """Receive a JSON message."""
echo         if not self.is_connected^(^):
echo             return None
echo         try:
echo             message = self.ws.recv^(^)
echo             return json.loads^(message^)
echo         except Exception as e:
echo             logger.warning^(f"Connection issue: {e}"^)
echo             self.disconnect^(^)
echo             return None
echo.
echo     def is_connected^(self^):
echo         """Check if the WebSocket is connected."""
echo         return self.ws and self.ws.connected
) > src\client\connection.py

:: Create src/client/core/executor.py
(
echo import os
echo import sys
echo import subprocess
echo import logging
echo from datetime import datetime
echo.
echo logger = logging.getLogger^(__name__^)
echo.
echo # Safe dynamic imports
echo try:
echo     import pyautogui
echo     pyautogui.FAILSAFE = True
echo     pyautogui.PAUSE = 0.1
echo except ImportError:
echo     pyautogui = None
echo.
echo try:
echo     import psutil
echo except ImportError:
echo     psutil = None
echo.
echo class SafeExecutor:
echo     """Filters and sanitizes commands before execution."""
echo     DANGEROUS_COMMANDS = [
echo         'format', 'del *', 'rmdir /s', 'rm -rf', 'shutdown /s',
echo         'restart', 'reboot', 'diskpart', 'fdisk', 'mkfs'
echo     ]
echo.
echo     @staticmethod
echo     def is_safe_command^(command^):
echo         command_lower = command.lower^(^)
echo         return not any^(dangerous in command_lower for dangerous in SafeExecutor.DANGEROUS_COMMANDS^)
echo.
echo class ActionExecutor:
echo     """Handles the execution of various actions received from the server."""
echo     def __init__^(self, config^):
echo         self.config = config
echo         self.command_history = []
echo.
echo     def execute_action^(self, action: dict^):
echo         """Executes a single action dictionary."""
echo         action_type = action.get^('type'^)
echo         code = action.get^('code', ''^)
echo.
echo         if not code:
echo             return "No code provided in action."
echo.
echo         logger.info^(f"Executing {action_type}: {code[:60]}..."^)
echo         self._add_to_history^(action_type, code^)
echo.
echo         try:
echo             if action_type == 'command':
echo                 return self._execute_system_command^(code^)
echo             elif action_type == 'python':
echo                 return self._execute_python_code^(code^)
echo             else:
echo                 return self._execute_system_command^(code^)
echo         except Exception as e:
echo             error_msg = f"Execution failed: {e}"
echo             logger.error^(error_msg^)
echo             return error_msg
echo.
echo     def _execute_system_command^(self, command^):
echo         if self.config.get^('safety_mode', True^):
echo             if not SafeExecutor.is_safe_command^(command^):
echo                 return f"Command blocked for safety: {command}"
echo.
echo         try:
echo             result = subprocess.run^(
echo                 command, shell=True, capture_output=True, text=True, timeout=30
echo             ^)
echo             output = result.stdout or result.stderr
echo             return output.strip^(^) or "Command executed successfully."
echo         except subprocess.TimeoutExpired:
echo             return "Command timed out."
echo         except Exception as e:
echo             return f"Command failed: {e}"
echo.
echo     def _execute_python_code^(self, code^):
echo         return "Python execution not implemented yet"
echo.
echo     def get_system_info^(self^):
echo         info = {'os': os.name, 'platform': sys.platform, 'python_version': sys.version}
echo         if psutil:
echo             try:
echo                 info.update^({
echo                     'cpu_percent': psutil.cpu_percent^(^),
echo                     'memory_percent': psutil.virtual_memory^(^).percent,
echo                 }^)
echo             except Exception:
echo                 pass
echo         return info
echo.
echo     def _add_to_history^(self, action_type, code^):
echo         self.command_history.append^({
echo             'timestamp': datetime.now^(^).isoformat^(^),
echo             'type': action_type,
echo             'code': code
echo         }^)
) > src\client\core\executor.py

:: Create src/client/requirements.txt
(
echo websocket-client
echo requests
echo pyautogui
echo pillow
echo keyboard
echo psutil
echo pytest
) > src\client\requirements.txt

:: Create src/server/requirements.txt
(
echo fastapi
echo uvicorn
echo websockets
echo requests
echo aiofiles
echo python-multipart
echo ollama
echo pyautogui
echo pillow
echo open-interpreter
echo pytest
) > src\server\requirements.txt

echo.
echo Project files created successfully!
echo.
echo Now try running:
echo scripts\run_client.bat
echo.
pause