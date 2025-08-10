import json
import os
import logging

logger = logging.getLogger(__name__)

DEFAULT_CONFIG = {
    'server_ip': '127.0.0.1',
    'server_port': 8000,
    'websocket_port': 8000,
    'auto_reconnect': True,
    'max_reconnect_attempts': 5,
    'reconnect_delay': 3,
    'screenshot_quality': 80,
    'safety_mode': True,
    'log_commands': True
}

def load_config():
    """Load configuration from file, with fallbacks."""
    config_file = 'client_config.json'
    legacy_config = 'server_config.txt'

    try:
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                config = json.load(f)
            logger.info(f"Configuration loaded from {config_file}")
            # Ensure all default keys are present
            for key, value in DEFAULT_CONFIG.items():
                config.setdefault(key, value)
            return config

        elif os.path.exists(legacy_config):
            with open(legacy_config, 'r') as f:
                server_ip = f.read().strip()
            config = DEFAULT_CONFIG.copy()
            config['server_ip'] = server_ip
            logger.info(f"Legacy configuration loaded from {legacy_config}")
            return config

        else:
            logger.warning("No configuration file found. Using default settings.")
            # In a real app, you might prompt for this.
            # For now, we use defaults, which might require user input later.
            return DEFAULT_CONFIG

    except Exception as e:
        logger.error(f"Error loading configuration: {e}")
        return DEFAULT_CONFIG

def get_server_url(config):
    """Construct the WebSocket server URL from config."""
    server_ip = config.get('server_ip', '127.0.0.1')
    ws_port = config.get('websocket_port', 8000)
    return f"ws://{server_ip}:{ws_port}/ws"
