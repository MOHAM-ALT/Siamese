import pytest
import sys
import os
import time
import subprocess
import websocket
import json
from threading import Thread

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

# --- Test Setup ---

def run_server():
    """Runs the FastAPI server in a subprocess."""
    # Use python -m to ensure it's run as a module
    process = subprocess.Popen(
        [sys.executable, "-m", "src.server.main"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    return process

def wait_for_server(process, timeout=15):
    """Waits for the server to start and be ready."""
    start_time = time.time()
    while time.time() - start_time < timeout:
        line = process.stdout.readline()
        if "Uvicorn running on" in line:
            print("Server started successfully.")
            return True
        time.sleep(0.1)
    print("Server did not start in time.")
    return False

# --- Test Case ---

@pytest.mark.integration
def test_client_server_communication():
    """
    An integration test to verify basic WebSocket communication.
    1. Starts the server.
    2. Connects a client.
    3. Sends a 'status' request.
    4. Verifies the response.
    """
    server_process = None
    try:
        # 1. Start the server in a background process
        print("\nAttempting to start the server...")
        server_process = run_server()

        if not wait_for_server(server_process):
            pytest.fail("Server failed to start. Check server logs.")

        # 2. Connect a WebSocket client
        ws_url = "ws://127.0.0.1:8000/ws"
        try:
            print(f"Connecting to WebSocket at {ws_url}...")
            ws = websocket.create_connection(ws_url, timeout=5)
            print("Connection successful.")
        except Exception as e:
            pytest.fail(f"WebSocket connection failed: {e}")

        # 3. Wait for the connection established message
        welcome_message = ws.recv()
        welcome_data = json.loads(welcome_message)
        print(f"Received welcome message: {welcome_data}")
        assert welcome_data['type'] == 'connection_established'
        assert 'client_id' in welcome_data

        # 4. Send a 'get_status' command from the client
        print("Sending 'get_status' command...")
        ws.send(json.dumps({'type': 'get_status'}))

        # 5. Receive and verify the response
        response_message = ws.recv()
        response_data = json.loads(response_message)
        print(f"Received status response: {response_data}")

        assert response_data['type'] == 'status_response'
        status = response_data.get('status', {})
        assert status.get('status') == 'online'
        assert 'timestamp' in status

        # Clean up
        ws.close()
        print("Test completed successfully.")

    finally:
        # Ensure the server process is always terminated
        if server_process:
            print("Terminating server process...")
            server_process.terminate()
            server_process.wait()
            print("Server process terminated.")
            # Print any remaining output for debugging
            stdout, stderr = server_process.communicate()
            if stdout: print(f"\nServer stdout:\n{stdout}")
            if stderr: print(f"\nServer stderr:\n{stderr}")
