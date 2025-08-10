# 🤖 AI Control System - Version 3.0 (Refactored)

<div align="center">

![Version](https://img.shields.io/badge/version-3.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-green.svg)
![Status](https://img.shields.io/badge/status-active-success.svg)
![License](https://img.shields.io/badge/license-MIT-yellow.svg)

**A professionally refactored, robust system for remote computer control using AI.**

</div>

---

## 📌 Overview

The AI Control System is a powerful solution for remotely managing Windows devices using AI. It comprises a server that runs on the host machine and a client that can be run from any other computer on the same network. This refactored version prioritizes stability, maintainability, and best practices in software architecture.

### 🎯 Project Goals

- **Full Remote Control:** Execute commands and automate tasks on a Windows PC from anywhere on the network.
- **AI-Powered Commands:** Use local AI models via Ollama and Open Interpreter to process natural language commands.
- **Modular and Stable:** A professional code structure that is easy to maintain and extend.
- **Simplified Setup:** A clear and standard installation process.

---

## 🏗️ Technical Architecture

### System Components

```
┌─────────────────────────┐         ┌─────────────────────────┐
│      Server Machine     │◄────────►│      Client Machine     │
│  (Windows 10/11 Host)   │   LAN    │   (Any OS with Python)  │
├─────────────────────────┤         ├─────────────────────────┤
│ • Ollama Server         │         │ • Python Client Script  │
│ • AI Language Models    │         │ • WebSocket Connection  │
│ • FastAPI Python Server │         │ • Interactive/Auto Mode │
└─────────────────────────┘         └─────────────────────────┘
```

### Core Technologies

| Technology      | Role                    |
|-----------------|-------------------------|
| Python 3.8+     | Core programming language |
| FastAPI         | Modern web framework for the server API |
| Uvicorn         | High-performance ASGI server |
| WebSockets      | Real-time, bidirectional communication |
| Ollama          | Runs local large language models |
| Open Interpreter| Executes natural language commands |
| PyAutoGUI       | For GUI automation (mouse/keyboard) |

---

## 📂 New Project Structure

The project has been refactored into a clean, standard Python project structure.

```
AI_Control_System/
│
├── 📁 src/
│   ├── 📁 client/
│   │   ├── 📄 main.py             # Client entry point
│   │   ├── 📄 config.py           # Client configuration
│   │   ├── 📄 connection.py       # WebSocket connection handler
│   │   ├── 📁 core/
│   │   │   └── 📄 executor.py     # Command execution logic
│   │   └── 📄 requirements.txt   # Client Python dependencies
│   │
│   └── 📁 server/
│       ├── 📄 main.py             # Server entry point (FastAPI app)
│       ├── 📄 config.py           # Server configuration
│       ├── 📁 api/
│       │   └── 📄 endpoints.py    # API routes (HTTP & WebSocket)
│       ├── 📁 core/
│       │   └── 📄 controller.py    # AI controller logic
│       ├── 📁 services/
│       │   └── 📄 interpreter.py   # Ollama interaction logic
│       └── 📄 requirements.txt   # Server Python dependencies
│
├── 📁 scripts/
│   ├── 📄 install.bat           # Unified installer for dependencies
│   ├── 📄 run_server.bat         # Script to launch the server
│   └── 📄 run_client.bat         # Script to launch the client
│
├── 📁 logs/                      # Log files (created automatically)
│
└── 📄 README.md                  # This file
```

---

## 🚀 Installation

Follow these steps to set up the server and client.

### Prerequisites

#### Server Machine:
- **OS:** Windows 10/11 (64-bit)
- **Python:** 3.8 or newer
- **Ollama:** Must be installed separately from [ollama.ai](https://ollama.ai/). After installing, pull a model:
  ```sh
  ollama pull qwen2.5-coder:7b
  ```
- **Hardware:** Recommended 16GB+ RAM and an NVIDIA GPU for good performance.

#### Client Machine:
- **OS:** Windows 10/11
- **Python:** 3.8 or newer

### 📥 Setup Instructions

1.  **Clone the repository:**
    ```sh
    git clone <repository_url>
    cd AI_Control_System
    ```

2.  **Run the Installer:**
    Open a Command Prompt and run the installer script:
    ```batch
    scripts\install.bat
    ```
    This script will guide you through setting up the Python virtual environments and installing the required dependencies for the server and/or client from their respective `requirements.txt` files.

3.  **Configure the Client:**
    After installation, the client needs to know the server's IP address. The first time you run the client, you may be prompted for it. Alternatively, you can create a `client_config.json` file in the root directory:
    ```json
    {
      "server_ip": "192.168.1.100",
      "server_port": 8000,
      "websocket_port": 8000
    }
    ```

---

## 💻 Usage

### 1. Start the Server

On the host machine, run the server launch script:
```batch
scripts\run_server.bat
```
This will activate the server's environment, check for the Ollama service, and launch the FastAPI server.

### 2. Run the Client

On your remote machine, run the client launch script:
```batch
scripts\run_client.bat
```
This will present a menu to run the client in one of three modes:
- **Automatic Mode:** Connects and waits passively for commands from the server.
- **Interactive Mode:** Provides a command prompt to send commands to the server.
- **Single Command Mode:** Sends one specific command and then exits.

### Quick Usage Example

To send a single command to the server to open Notepad, you can use the "Single Command" mode:
1.  Run `scripts\run_client.bat`.
2.  Choose option `[3] Send a Single Command`.
3.  When prompted, enter the command: `open notepad`

The client will send the command to the server, the server will process it, and the client on the host machine will execute the action.

---

## ✅ Running Tests

This project uses `pytest` for testing. The necessary dependencies are included in the `requirements.txt` files.

1.  **Activate your virtual environment** (for either server or client).
    ```batch
    # For server tests
    call venv_server\Scripts\activate.bat
    
    # For client tests
    call venv_client\Scripts\activate.bat
    ```

2.  **Run pytest:**
    From the root of the project directory, run:
    ```sh
    pytest
    ```
    This will automatically discover and run all the tests in the `tests/` directory. The integration test will be skipped by default. To run it, you need to explicitly include it:
    ```sh
    pytest -m integration
    ```
    **Note:** The integration test will start a live server, so ensure port 8000 is free.

---

## 📡 API Endpoints

The server exposes the following endpoints, accessible at `http://<server_ip>:8000`.

| Path       | Method | Description                               |
|------------|--------|-------------------------------------------|
| `/`        | GET    | A simple HTML status page.                |
| `/status`  | GET    | Returns detailed server status as JSON.   |
| `/history` | GET    | Retrieves the history of processed commands. |
| `/process` | POST   | Submits a command for processing via HTTP.|
| `/health`  | GET    | A simple health check endpoint.           |
| `/ws`      | WebSocket| The endpoint for real-time communication.|

---

## 🌟 Future Improvements

- [ ] Add a web interface for easier control.
- [ ] Implement user authentication and encrypted communication.
- [ ] Support for managing multiple clients from the server.
- [ ] Add advanced macro recording and playback.

---

## 🙏 Acknowledgements

- **Ollama Team** - For making local LLMs accessible.
- **FastAPI Community** - For an excellent web framework.
- **The original author, Mohammed Abdullah Al-Qahtani**, for the innovative concept.

<div align="center">
  **This project was refactored to ensure stability and maintainability.**
</div>
