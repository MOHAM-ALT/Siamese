import json
import logging
from typing import Dict, Any, Optional, List

logger = logging.getLogger(__name__)

async def process_with_interpreter(interpreter, command: str, context: Optional[Dict] = None) -> Dict[str, Any]:
    """Process command using Open Interpreter"""
    try:
        # Build context-aware prompt
        prompt_parts = [
            f"User request: {command}",
            "Please provide executable commands for Windows."
        ]

        if context:
            prompt_parts.append(f"Context: {json.dumps(context)}")

        prompt_parts.append(\"\"\"
        Return your response as executable commands or code.
        If the request involves file operations, use full paths.
        If it's a system command, provide the exact command syntax.
        Be safe and avoid destructive operations without explicit confirmation.\"\"\"
        )

        full_prompt = "\n".join(prompt_parts)

        # Get response from interpreter
        response = interpreter.chat(full_prompt, display=False)
        commands = extract_commands_from_response(response)

        return {
            "success": True,
            "actions": commands,
            "method": "interpreter"
        }

    except Exception as e:
        logger.error(f"Interpreter processing error: {e}")
        # Fallback to basic processing
        return process_basic_command(command)

def process_basic_command(command: str) -> Dict[str, Any]:
    """Basic command processing without Open Interpreter"""
    command_lower = command.lower()
    actions = []

    # Enhanced basic command mapping
    command_mappings = {
        'open chrome': 'start chrome',
        'open browser': 'start chrome',
        'open notepad': 'notepad',
        'open calculator': 'calc',
        'open file explorer': 'explorer',
        'open task manager': 'taskmgr',
        'open control panel': 'control',
        'shutdown': 'shutdown /s /t 0',
        'restart': 'shutdown /r /t 0',
        'lock screen': 'rundll32.exe user32.dll,LockWorkStation',
        'take screenshot': 'screenshot_command',
        'list files': 'dir',
        'current directory': 'cd',
        'system info': 'systeminfo'
    }

    # Check for direct matches
    matched = False
    for key, value in command_mappings.items():
        if key in command_lower:
            if value == 'screenshot_command':
                actions.append({
                    "type": "python",
                    "code": "import pyautogui; pyautogui.screenshot().save('screenshot.png'); print('Screenshot saved as screenshot.png')"
                })
            else:
                actions.append({
                    "type": "command",
                    "code": value
                })
            matched = True
            break

    # If no match found, treat as direct command
    if not matched:
        # Basic safety checks
        dangerous_commands = ['format', 'del *', 'rm -rf', 'rmdir /s']
        if any(dangerous in command_lower for dangerous in dangerous_commands):
            actions.append({
                "type": "error",
                "code": f"Potentially dangerous command blocked: {command}"
            })
        else:
            actions.append({
                "type": "command",
                "code": command
            })

    return {
        "success": True,
        "actions": actions,
        "method": "basic"
    }

def extract_commands_from_response(response) -> List[Dict]:
    """Extract executable commands from interpreter response"""
    commands = []

    if not response:
        return commands

    # Handle different response formats
    if isinstance(response, list):
        for item in response:
            if isinstance(item, dict):
                if item.get('type') == 'code':
                    commands.append({
                        'type': 'execute',
                        'code': item.get('content', ''),
                        'language': item.get('format', 'python')
                    })
                elif item.get('type') == 'message':
                    # Extract code blocks from message
                    content = item.get('content', '')
                    if '```' in content:
                        # Extract code blocks
                        blocks = content.split('```')
                        for i, block in enumerate(blocks):
                            if i % 2 == 1:  # Odd indices are code blocks
                                commands.append({
                                    'type': 'execute',
                                    'code': block.strip(),
                                    'language': 'auto'
                                })

    # If no commands extracted, return the raw response
    if not commands and response:
        commands.append({
            'type': 'response',
            'code': str(response),
            'language': 'text'
        })

    return commands
