import logging
import os

def setup_logging():
    os.makedirs('logs', exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('logs/server.log'),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

def configure_interpreter(interpreter):
    try:
        interpreter.llm.model = "ollama/qwen2.5-coder:7b"
        interpreter.llm.api_base = "http://localhost:11434"
        interpreter.auto_run = False
        interpreter.safe_mode = 'off'
        interpreter.system_message = \"\"\"You are an AI assistant for remote computer control.
        Analyze user commands and provide safe, executable instructions.
        Focus on Windows system commands and automation tasks.
        Always prioritize safety and ask for confirmation on destructive operations.\"\"\"
        logging.info("Open Interpreter configured successfully")
        return interpreter
    except Exception as e:
        logging.error(f"Error configuring Open Interpreter: {e}")
        return None
