import os
import sys
import subprocess
import base64
import io
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

# Safe dynamic imports
try:
    import pyautogui
    pyautogui.FAILSAFE = True
    pyautogui.PAUSE = 0.1
except ImportError:
    pyautogui = None

try:
    from PIL import Image, ImageGrab
except ImportError:
    ImageGrab = None

try:
    import psutil
except ImportError:
    psutil = None


class SafeExecutor:
    """Filters and sanitizes commands before execution."""

    DANGEROUS_COMMANDS = [
        'format', 'del *', 'rmdir /s', 'rm -rf', 'shutdown /s',
        'restart', 'reboot', 'diskpart', 'fdisk', 'mkfs'
    ]

    @staticmethod
    def is_safe_command(command):
        command_lower = command.lower()
        return not any(dangerous in command_lower for dangerous in SafeExecutor.DANGEROUS_COMMANDS)

    @staticmethod
    def sanitize_command(command):
        dangerous_chars = ['&', '|', ';', '>', '<', '`']
        for char in dangerous_chars:
            command = command.replace(char, ' ')
        return command.strip()


class ActionExecutor:
    """Handles the execution of various actions received from the server."""

    def __init__(self, config):
        self.config = config
        self.command_history = []

    def execute_action(self, action: dict):
        """Executes a single action dictionary."""
        action_type = action.get('type')
        code = action.get('code', '')

        if not code:
            return "No code provided in action."

        logger.info(f"Executing {action_type}: {code[:60]}...")
        self._add_to_history(action_type, code)

        try:
            if action_type == 'command':
                return self._execute_system_command(code)
            elif action_type == 'python':
                return self._execute_python_code(code)
            elif action_type == 'click':
                return self._execute_click(code)
            elif action_type == 'type':
                return self._execute_type(code)
            elif action_type == 'hotkey':
                return self._execute_hotkey(code)
            elif action_type in ['execute', 'auto']:
                return self._auto_execute(code)
            else:
                return f"Unknown action type: {action_type}"
        except Exception as e:
            error_msg = f"Execution failed: {e}"
            logger.error(error_msg)
            return error_msg

    def _execute_system_command(self, command):
        if self.config.get('safety_mode', True):
            if not SafeExecutor.is_safe_command(command):
                return f"Command blocked for safety: {command}"
            command = SafeExecutor.sanitize_command(command)

        try:
            result = subprocess.run(
                command, shell=True, capture_output=True, text=True, timeout=30
            )
            output = result.stdout or result.stderr
            return output.strip() or "Command executed successfully."
        except subprocess.TimeoutExpired:
            return "Command timed out."
        except Exception as e:
            return f"Command failed: {e}"

    def _execute_python_code(self, code):
        if not pyautogui:
            return "PyAutoGUI not available for Python execution."

        # A very basic sandbox
        restricted_globals = {'pyautogui': pyautogui}
        try:
            exec(code, {"__builtins__": {}}, restricted_globals)
            return "Python code executed."
        except Exception as e:
            return f"Python execution error: {e}"

    def _execute_click(self, code):
        if not pyautogui: return "PyAutoGUI not available."
        try:
            coords = code.replace('click', '').replace('(', '').replace(')', '').split(',')
            x, y = int(coords[0].strip()), int(coords[1].strip())
            pyautogui.click(x, y)
            return f"Clicked at ({x}, {y})."
        except Exception as e:
            return f"Click failed: {e}"

    def _execute_type(self, code):
        if not pyautogui: return "PyAutoGUI not available."
        try:
            text = code.replace('type ', '').strip()
            pyautogui.write(text, interval=0.05)
            return f"Typed: {text}"
        except Exception as e:
            return f"Type failed: {e}"

    def _execute_hotkey(self, code):
        if not pyautogui: return "PyAutoGUI not available."
        try:
            keys = [key.strip() for key in code.replace('hotkey ', '').split('+')]
            pyautogui.hotkey(*keys)
            return f"Executed hotkey: {', '.join(keys)}"
        except Exception as e:
            return f"Hotkey failed: {e}"

    def _auto_execute(self, code):
        """Auto-detects and executes the command type."""
        lower_code = code.lower()
        if 'click' in lower_code: return self._execute_click(code)
        if lower_code.startswith('type'): return self._execute_type(code)
        if 'hotkey' in lower_code: return self._execute_hotkey(code)
        # Add more auto-detection rules as needed
        return self._execute_system_command(code)

    def get_screenshot(self):
        if not ImageGrab: return None
        try:
            screenshot = ImageGrab.grab()
            quality = self.config.get('screenshot_quality', 80)
            if quality < 100:
                w, h = screenshot.size
                new_w = int(w * quality / 100)
                new_h = int(h * quality / 100)
                screenshot = screenshot.resize((new_w, new_h))

            buffered = io.BytesIO()
            screenshot.save(buffered, format="PNG")
            return base64.b64encode(buffered.getvalue()).decode()
        except Exception as e:
            logger.error(f"Screenshot error: {e}")
            return None

    def get_system_info(self):
        info = {'os': os.name, 'platform': sys.platform, 'python_version': sys.version}
        if psutil:
            try:
                info.update({
                    'cpu_percent': psutil.cpu_percent(),
                    'memory_percent': psutil.virtual_memory().percent,
                })
            except Exception as e:
                logger.warning(f"Could not get system stats: {e}")
        return info

    def _add_to_history(self, action_type, code):
        self.command_history.append({
            'timestamp': datetime.now().isoformat(),
            'type': action_type,
            'code': code
        })
