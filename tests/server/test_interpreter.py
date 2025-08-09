import pytest
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src')))

from server.services.interpreter import process_basic_command

# Test cases for the basic command mapping
# Format: { "input_command": "expected_output_code" }
command_test_cases = {
    "open chrome": "start chrome",
    "please open the browser": "start chrome",
    "can you open notepad for me": "notepad",
    "launch the calculator": "calc",
    "show me the file explorer": "explorer",
    "I need the task manager": "taskmgr",
    "open control panel": "control",
    "shut down the computer": "shutdown /s /t 0",
    "restart my pc": "restart /r /t 0",
    "lock this screen": "rundll32.exe user32.dll,LockWorkStation",
    "give me system info": "systeminfo",
    "list all files": "dir",
    "where am i": "cd",
    "what is the current directory": "cd"
}

# Test cases for commands that should be blocked
dangerous_commands = [
    "format my C drive",
    "can you run del *.*? a=b",
    "execute rmdir /s"
]

@pytest.mark.parametrize("input_command, expected_code", command_test_cases.items())
def test_basic_command_mapping(input_command, expected_code):
    """Test that various natural language commands map to the correct system command."""
    result = process_basic_command(input_command)
    assert result['success'] is True
    assert len(result['actions']) == 1
    action = result['actions'][0]
    assert action['type'] == 'command'
    assert action['code'] == expected_code

def test_screenshot_command():
    """Test the specific 'take screenshot' command, which returns a python action."""
    result = process_basic_command("take a screenshot")
    assert result['success'] is True
    assert len(result['actions']) == 1
    action = result['actions'][0]
    assert action['type'] == 'python'
    assert "pyautogui.screenshot" in action['code']

@pytest.mark.parametrize("command", dangerous_commands)
def test_dangerous_command_blocking(command):
    """Test that commands containing dangerous keywords are blocked."""
    result = process_basic_command(command)
    assert result['success'] is True
    assert len(result['actions']) == 1
    action = result['actions'][0]
    assert action['type'] == 'error'
    assert "Potentially dangerous command blocked" in action['code']

def test_unknown_command_is_passed_through():
    """Test that a command not in the map is passed through directly."""
    unknown_command = "this is a test command"
    result = process_basic_command(unknown_command)
    assert result['success'] is True
    assert len(result['actions']) == 1
    action = result['actions'][0]
    assert action['type'] == 'command'
    assert action['code'] == unknown_command
