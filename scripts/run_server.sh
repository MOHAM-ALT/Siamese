#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

echo "================================================================================"
echo "                           AI CONTROL SERVER LAUNCHER"
echo "================================================================================"
echo

# Check for virtual environment
if [ ! -f "venv_server/bin/activate" ]; then
    echo "[ERROR] Server virtual environment not found."
    echo "Please run './scripts/install.sh' first to set up the server."
    exit 1
fi

echo "Activating server environment..."
source venv_server/bin/activate

echo
echo "[INFO] Checking for running Ollama service..."
if ! pgrep -x "ollama" > /dev/null; then
    echo "   - Ollama not found, starting it in the background."
    ollama serve &
    sleep 5
else
    echo "   - Ollama is already running."
fi

echo
echo "Launching the FastAPI server..."
echo "To stop the server, press Ctrl+C in this window."
echo "================================================================================"
echo

python -m src.server.main

# Deactivate venv on exit
deactivate
