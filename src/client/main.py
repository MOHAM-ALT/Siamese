import sys
import os
import logging
import json
from datetime import datetime

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/client.log', mode='w'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Project-specific imports
from .config import load_config, get_server_url
from .connection import Connection
from .core.executor import ActionExecutor

class AIClient:
    """Orchestrates the client application."""

    def __init__(self):
        self.config = load_config()
        server_url = get_server_url(self.config)
        self.connection = Connection(server_url, self.config)
        self.executor = ActionExecutor(self.config)
        self.running = True

    def start(self, mode, command=None):
        """Starts the client in the specified mode."""
        if not self.connection.connect():
            return

        if mode == 'auto':
            self.run_auto_mode()
        elif mode == 'interactive':
            self.run_interactive_mode()
        elif mode == 'command' and command:
            self.send_single_command(command)

        self.connection.disconnect()
        print("👋 Client has shut down.")

    def run_auto_mode(self):
        """Waits for and executes commands from the server."""
        print("🤖 AI Client running in Automatic Mode. Press Ctrl+C to exit.")
        try:
            while self.running:
                message = self.connection.receive_message()
                if not message:
                    if not self.connection.is_connected():
                        print("Connection lost. Attempting to reconnect...")
                        if not self.connection.connect():
                            break # Stop if reconnect fails
                    continue

                self._handle_server_message(message)

        except KeyboardInterrupt:
            logger.info("Automatic mode stopped by user.")
            print("\n🛑 Automatic mode stopped.")
        finally:
            self.running = False

    def run_interactive_mode(self):
        """Allows the user to send commands interactively."""
        print("💬 AI Client running in Interactive Mode. Type 'exit' to quit.")
        try:
            while self.running:
                user_input = input("Command> ").strip()
                if not user_input:
                    continue
                if user_input.lower() in ['exit', 'quit']:
                    break

                self._send_command(user_input, mode='interactive')
                response = self.connection.receive_message()
                if response:
                    self._handle_server_message(response)
                else:
                    print("❌ No response from server. Is it running?")

        except KeyboardInterrupt:
            logger.info("Interactive mode stopped by user.")
            print("\n🛑 Interactive mode stopped.")
        finally:
            self.running = False

    def send_single_command(self, command):
        """Sends a single command and exits."""
        print(f"📦 Sending single command: {command}")
        self._send_command(command, mode='single')
        response = self.connection.receive_message()
        if response:
            self._handle_server_message(response)
        else:
            print("❌ No response from server.")

    def _send_command(self, command, mode):
        """Constructs and sends a command message to the server."""
        message = {
            'type': 'command',
            'command': command,
            'context': {
                'mode': mode,
                'system_info': self.executor.get_system_info()
            },
            'timestamp': datetime.now().isoformat()
        }
        # Optionally add a screenshot
        # screenshot = self.executor.get_screenshot()
        # if screenshot:
        #     message['screenshot'] = screenshot

        self.connection.send_message(message)

    def _handle_server_message(self, message):
        """Processes messages received from the server."""
        msg_type = message.get('type')
        logger.info(f"Received message of type: {msg_type}")

        if msg_type == 'command_result':
            result_data = message.get('result', {})
            actions = result_data.get('actions', [])
            if actions:
                print(f"📨 Received {len(actions)} action(s) from server.")
                for i, action in enumerate(actions, 1):
                    print(f"  - Action {i}: {action.get('type')} - {action.get('code', 'N/A')[:50]}")
                    exec_result = self.executor.execute_action(action)
                    print(f"    ↳ Result: {exec_result}")
            else:
                print("ℹ️ Server returned no actions.")

        elif msg_type == 'connection_established':
            print(f"🔗 Connection established with client ID: {message.get('client_id')}")

        elif msg_type == 'error':
            print(f"❗️ Server error: {message.get('message')}")

        elif msg_type == 'ping':
            self.connection.send_message({'type': 'pong'})

def main():
    """Main entry point for the client application."""
    # Check for missing dependencies
    missing = []
    try:
        import pyautogui
    except ImportError:
        missing.append("pyautogui")
    try:
        import PIL
    except ImportError:
        missing.append("Pillow")

    if missing:
        print(f"⚠️  Warning: Missing modules: {', '.join(missing)}")
        print(f"   Install with: pip install {' '.join(missing)}")
        print("-" * 20)

    client = AIClient()

    # Simple command-line argument parsing
    args = sys.argv[1:]
    mode = 'auto' # Default mode
    command = None

    if len(args) > 0:
        mode = args[0].lower()
        if mode not in ['auto', 'interactive', 'command']:
            print(f"Unknown mode: {mode}")
            print("Usage: python -m src.client.main [auto|interactive|command] [command_string]")
            return
        if mode == 'command':
            if len(args) < 2:
                print("Error: 'command' mode requires a command string.")
                return
            command = " ".join(args[1:])

    try:
        client.start(mode, command)
    except Exception as e:
        crash_log_path = os.path.join('logs', 'client_crash.log')
        with open(crash_log_path, 'a') as f:
            import traceback
            f.write(f"--- CRASH AT {datetime.now()} ---\n")
            traceback.print_exc(file=f)
            f.write("\n")
        logger.fatal(f"A fatal error occurred: {e}", exc_info=True)
        print(f"💥 A fatal error occurred. Details saved to {crash_log_path}")

if __name__ == "__main__":
    main()
