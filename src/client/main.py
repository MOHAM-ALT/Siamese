# src/client/main.py
import sys
import os
import logging
import json
from datetime import datetime

# Fix Windows console encoding
if sys.platform == "win32":
    # Set console to UTF-8 for Windows
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.detach())
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.detach())

# Setup logging with Windows-safe format
try:
    os.makedirs('logs', exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('logs/client.log', mode='w', encoding='utf-8'),
            logging.StreamHandler()
        ]
    )
except:
    # Fallback logging if file creation fails
    logging.basicConfig(level=logging.INFO)

logger = logging.getLogger(__name__)

# Project-specific imports
try:
    from .config import load_config, get_server_url
    from .connection import Connection
    from .core.executor import ActionExecutor
except ImportError as e:
    print(f"ERROR: Failed to import required modules: {e}")
    print("Please ensure all project files are present in src/client/")
    input("Press Enter to exit...")
    sys.exit(1)

class AIClient:
    """Orchestrates the client application."""

    def __init__(self):
        try:
            self.config = load_config()
            server_url = get_server_url(self.config)
            self.connection = Connection(server_url, self.config)
            self.executor = ActionExecutor(self.config)
            self.running = True
            logger.info("AI Client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize AI Client: {e}")
            raise

    def start(self, mode, command=None):
        """Starts the client in the specified mode."""
        try:
            if not self.connection.connect():
                print("Failed to connect to server")
                return

            if mode == 'auto':
                self.run_auto_mode()
            elif mode == 'interactive':
                self.run_interactive_mode()
            elif mode == 'command' and command:
                self.send_single_command(command)
            else:
                print(f"Unknown mode: {mode}")

        except KeyboardInterrupt:
            print("\nStopping client...")
        except Exception as e:
            logger.error(f"Client error: {e}")
            print(f"Client error: {e}")
        finally:
            self.connection.disconnect()
            print("Client has shut down.")

    def run_auto_mode(self):
        """Waits for and executes commands from the server."""
        print("AI Client running in Automatic Mode. Press Ctrl+C to exit.")
        try:
            while self.running:
                message = self.connection.receive_message()
                if not message:
                    if not self.connection.is_connected():
                        print("Connection lost. Attempting to reconnect...")
                        if not self.connection.connect():
                            break
                    continue

                self._handle_server_message(message)

        except KeyboardInterrupt:
            logger.info("Automatic mode stopped by user.")
            print("\nAutomatic mode stopped.")
        finally:
            self.running = False

    def run_interactive_mode(self):
        """Allows the user to send commands interactively."""
        print("AI Client running in Interactive Mode. Type 'exit' to quit.")
        try:
            while self.running:
                try:
                    user_input = input("Command> ").strip()
                except EOFError:
                    break
                
                if not user_input:
                    continue
                if user_input.lower() in ['exit', 'quit']:
                    break

                self._send_command(user_input, mode='interactive')
                response = self.connection.receive_message()
                if response:
                    self._handle_server_message(response)
                else:
                    print("No response from server. Is it running?")

        except KeyboardInterrupt:
            logger.info("Interactive mode stopped by user.")
            print("\nInteractive mode stopped.")
        finally:
            self.running = False

    def send_single_command(self, command):
        """Sends a single command and exits."""
        print(f"Sending single command: {command}")
        self._send_command(command, mode='single')
        response = self.connection.receive_message()
        if response:
            self._handle_server_message(response)
        else:
            print("No response from server.")

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

        success = self.connection.send_message(message)
        if not success:
            print("Failed to send command to server")

    def _handle_server_message(self, message):
        """Processes messages received from the server."""
        msg_type = message.get('type')
        logger.info(f"Received message of type: {msg_type}")

        if msg_type == 'command_result':
            result_data = message.get('result', {})
            actions = result_data.get('actions', [])
            if actions:
                print(f"Received {len(actions)} action(s) from server.")
                for i, action in enumerate(actions, 1):
                    action_type = action.get('type', 'unknown')
                    action_code = action.get('code', 'N/A')
                    print(f"  - Action {i}: {action_type} - {action_code[:50]}")
                    try:
                        exec_result = self.executor.execute_action(action)
                        print(f"    Result: {exec_result}")
                    except Exception as e:
                        print(f"    Error: {e}")
            else:
                print("Server returned no actions.")

        elif msg_type == 'connection_established':
            client_id = message.get('client_id', 'unknown')
            print(f"Connection established with client ID: {client_id}")

        elif msg_type == 'error':
            error_msg = message.get('message', 'Unknown error')
            print(f"Server error: {error_msg}")

        elif msg_type == 'ping':
            self.connection.send_message({'type': 'pong'})

        else:
            print(f"Received unknown message type: {msg_type}")

def main():
    """Main entry point for the client application."""
    
    # Check for missing dependencies with Windows-safe output
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
        print("Warning: Missing modules: " + ", ".join(missing))
        print("Install with: pip install " + " ".join(missing))
        print("-" * 20)

    try:
        client = AIClient()
    except Exception as e:
        print(f"Failed to create AI Client: {e}")
        print("Please check that all required files are present")
        input("Press Enter to exit...")
        return

    # Simple command-line argument parsing
    args = sys.argv[1:]
    mode = 'auto'  # Default mode
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
        try:
            os.makedirs('logs', exist_ok=True)
            with open(crash_log_path, 'a', encoding='utf-8') as f:
                import traceback
                f.write(f"--- CRASH AT {datetime.now()} ---\n")
                traceback.print_exc(file=f)
                f.write("\n")
        except:
            pass
        
        logger.fatal(f"A fatal error occurred: {e}", exc_info=True)
        print(f"A fatal error occurred. Details may be saved to {crash_log_path}")

if __name__ == "__main__":
    main()