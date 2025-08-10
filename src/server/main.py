import os
import sys
import socket
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Project-specific imports
from .config import setup_logging, configure_interpreter
from .core.controller import AIController
from .api.endpoints import register_endpoints

# Setup logging
logger = setup_logging()

# --- Application Setup ---

# Create FastAPI app
app = FastAPI(
    title="AI Control Server",
    description="A refactored, professional remote AI control system.",
    version="3.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Dependency Initialization ---

# Attempt to import and configure the Open Interpreter
try:
    import interpreter
    interpreter_instance = configure_interpreter(interpreter)
    logger.info("Open Interpreter loaded and configured.")
except ImportError:
    interpreter_instance = None
    logger.warning("Open Interpreter not available. Running in basic mode.")
except Exception as e:
    interpreter_instance = None
    logger.error(f"Failed to configure Open Interpreter: {e}")


# Initialize the main controller
ai_controller = AIController(interpreter_instance=interpreter_instance)

# Register API endpoints
register_endpoints(app, ai_controller)


# --- Main Execution ---

def main():
    # Get network information for display
    hostname = socket.gethostname()
    try:
        local_ip = socket.gethostbyname(hostname)
    except socket.gaierror:
        local_ip = "127.0.0.1"

    # Display server info
    print("\n" + "="*80)
    print("🚀 AI CONTROL SERVER v3.0 (Refactored)")
    print("="*80)
    print(f"🌐 Local Access:    http://localhost:8000")
    print(f"🌐 Network Access:  http://{local_ip}:8000")
    print(f"🔌 WebSocket:       ws://{local_ip}:8000/ws")
    print(f"📊 Status Endpoint: http://{local_ip}:8000/status")
    print("="*80)
    print(f"📁 Working Directory: {os.getcwd()}")
    print(f"🤖 Open Interpreter: {'✓ Available' if interpreter_instance else '✗ Not Available'}")
    print(f"📝 Logs: {os.path.join(os.getcwd(), 'logs')}")
    print("="*80)
    print("Press Ctrl+C to stop the server")
    print("="*80)

    logger.info("Starting AI Control Server v3.0")
    logger.info(f"Server accessible at: http://{local_ip}:8000")

    # Run the server
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Server stopped by user.")
    except Exception as e:
        # Log the exception to a dedicated crash file
        crash_log_path = os.path.join('logs', 'server_crash.log')
        with open(crash_log_path, 'a') as f:
            import traceback
            f.write(f"--- CRASH AT {datetime.now()} ---\n")
            traceback.print_exc(file=f)
            f.write("\n")
        logger.error(f"A critical error occurred. Details saved to {crash_log_path}")
        print(f"A critical error occurred. Details have been saved to {crash_log_path}")
    finally:
        logger.info("Server shutdown complete.")
