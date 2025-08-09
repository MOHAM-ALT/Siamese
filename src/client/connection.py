import websocket
import json
import time
import logging

logger = logging.getLogger(__name__)

class Connection:
    def __init__(self, server_url, config):
        self.ws = None
        self.server_url = server_url
        self.config = config
        self.reconnect_attempts = 0
        self.max_reconnects = self.config.get('max_reconnect_attempts', 5)
        self.reconnect_delay = self.config.get('reconnect_delay', 3)

    def connect(self):
        """Establish WebSocket connection with retry logic."""
        if self.is_connected():
            return True
        return self._reconnect()

    def _reconnect(self):
        """Internal method to handle reconnection attempts."""
        self.reconnect_attempts = 0
        while self.reconnect_attempts < self.max_reconnects:
            try:
                logger.info(f"Attempting to connect to {self.server_url} (Attempt {self.reconnect_attempts + 1})...")
                self.ws = websocket.create_connection(self.server_url, timeout=10)
                logger.info("Connection successful.")
                print(f"✅ Connected to server: {self.config.get('server_ip')}")
                self.reconnect_attempts = 0  # Reset on success
                return True
            except Exception as e:
                logger.error(f"Connection attempt failed: {e}")
                print(f"❌ Connection failed: {e}")
                self.reconnect_attempts += 1
                if self.reconnect_attempts < self.max_reconnects:
                    logger.info(f"Retrying in {self.reconnect_delay} seconds...")
                    print(f"🔄 Retrying in {self.reconnect_delay} seconds...")
                    time.sleep(self.reconnect_delay)
                else:
                    logger.error("Max reconnect attempts reached. Giving up.")
                    print("❌ Could not connect to the server. Please check the server and your network.")
                    return False
        return False

    def disconnect(self):
        """Safely close the WebSocket connection."""
        if self.ws:
            try:
                self.ws.close()
                logger.info("Connection closed.")
            except Exception as e:
                logger.error(f"Error during disconnection: {e}")
            finally:
                self.ws = None

    def send_message(self, message: dict):
        """Send a JSON message, reconnecting if necessary."""
        if not self.is_connected():
            logger.warning("Connection lost. Attempting to reconnect before sending...")
            if not self._reconnect():
                return False
        try:
            self.ws.send(json.dumps(message))
            return True
        except (websocket.WebSocketConnectionClosedException, BrokenPipeError) as e:
            logger.error(f"Failed to send message due to connection error: {e}")
            self.disconnect()
            if self._reconnect():
                return self.send_message(message) # Retry sending after reconnect
            return False

    def receive_message(self):
        """Receive a JSON message, reconnecting if necessary."""
        if not self.is_connected():
            logger.warning("Connection lost. Attempting to reconnect before receiving...")
            if not self._reconnect():
                return None # Cannot receive if reconnect fails
        try:
            message = self.ws.recv()
            return json.loads(message)
        except (websocket.WebSocketConnectionClosedException, BrokenPipeError) as e:
            logger.warning(f"Connection closed while waiting for message: {e}")
            self.disconnect()
            return None # Don't retry receiving, let the main loop handle it

    def is_connected(self):
        """Check if the WebSocket is connected."""
        return self.ws and self.ws.connected
