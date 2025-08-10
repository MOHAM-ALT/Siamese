import pytest
import sys
import os

# Add the src directory to the Python path to allow for absolute imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../src')))

from client.core.executor import SafeExecutor

# Test cases for safe and dangerous commands
safe_commands = [
    "echo Hello World",
    "dir",
    "ipconfig",
    "tasklist"
]

dangerous_commands = [
    "format C:",
    "del *.*",
    "rmdir /s /q important_folder",
    "shutdown /s",
    "reboot"
]

# Test cases for sanitization
commands_to_sanitize = {
    "echo hello & dir": "echo hello   dir",
    "tasklist | findstr python": "tasklist   findstr python",
    "cd C:; del *.*": "cd C:  del *.*",
    "cat /etc/passwd > my_passwords.txt": "cat /etc/passwd   my_passwords.txt"
}

@pytest.mark.parametrize("command", safe_commands)
def test_safe_commands_are_allowed(command):
    """Verify that known safe commands are correctly identified as safe."""
    assert SafeExecutor.is_safe_command(command) is True

@pytest.mark.parametrize("command", dangerous_commands)
def test_dangerous_commands_are_blocked(command):
    """Verify that known dangerous commands are correctly identified as unsafe."""
    assert SafeExecutor.is_safe_command(command) is False

@pytest.mark.parametrize("command, sanitized", commands_to_sanitize.items())
def test_command_sanitization(command, sanitized):
    """Verify that commands with special characters are properly sanitized."""
    assert SafeExecutor.sanitize_command(command) == sanitized

def test_is_safe_command_case_insensitivity():
    """Verify that safety checks are case-insensitive."""
    assert SafeExecutor.is_safe_command("SHUTDOWN /s") is False
    assert SafeExecutor.is_safe_command("Format D:") is False

def test_sanitize_command_no_special_chars():
    """Verify that commands without special characters are unchanged."""
    command = "python --version"
    assert SafeExecutor.sanitize_command(command) == command
