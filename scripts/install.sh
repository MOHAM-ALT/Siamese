#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

echo "================================================================================"
echo "                     AI CONTROL SYSTEM - UNIFIED INSTALLER"
echo "================================================================================"
echo "This script will set up the necessary Python environments for the Server and Client."
echo
echo "IMPORTANT:"
echo "- This script should be run from the project's root directory."
echo "- Please ensure you have Python 3.8+ installed."
echo "- For the server, you must install Ollama separately from https://ollama.ai/"
echo

# --- Helper Functions ---
install_server_deps() {
    echo
    echo "================================================================================"
    echo "                        INSTALLING SERVER DEPENDENCIES"
    echo "================================================================================"
    echo
    echo "[1/3] Checking for Python..."
    if ! command -v python &> /dev/null; then
        echo "[ERROR] Python could not be found. Please install it first."
        exit 1
    fi
    echo "[OK] Python found."

    echo
    echo "[2/3] Creating virtual environment for the server..."
    if [ ! -d "venv_server" ]; then
        python -m venv venv_server
        if [ $? -ne 0 ]; then
            echo "[ERROR] Could not create server virtual environment."
            exit 1
        fi
        echo "[OK] Server virtual environment created at ./venv_server"
    else
        echo "[OK] Server virtual environment already exists."
    fi

    echo
    echo "[3/3] Installing packages from src/server/requirements.txt..."
    source venv_server/bin/activate
    pip install --upgrade pip > /dev/null
    pip install -r src/server/requirements.txt
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install server packages."
        exit 1
    fi
    deactivate
    echo "[OK] Server packages installed successfully."
    echo "[REMINDER] Don't forget to install Ollama and pull your desired models!"
    echo
}

install_client_deps() {
    echo
    echo "================================================================================"
    echo "                        INSTALLING CLIENT DEPENDENCIES"
    echo "================================================================================"
    echo
    echo "[1/3] Checking for Python..."
    if ! command -v python &> /dev/null; then
        echo "[ERROR] Python could not be found. Please install it first."
        exit 1
    fi
    echo "[OK] Python found."

    echo
    echo "[2/3] Creating virtual environment for the client..."
    if [ ! -d "venv_client" ]; then
        python -m venv venv_client
        if [ $? -ne 0 ]; then
            echo "[ERROR] Could not create client virtual environment."
            exit 1
        fi
        echo "[OK] Client virtual environment created at ./venv_client"
    else
        echo "[OK] Client virtual environment already exists."
    fi

    echo
    echo "[3/3] Installing packages from src/client/requirements.txt..."
    source venv_client/bin/activate
    pip install --upgrade pip > /dev/null
    pip install -r src/client/requirements.txt
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install client packages."
        exit 1
    fi
    deactivate
    echo "[OK] Client packages installed successfully."
    echo
}

# --- Main Menu ---
while true; do
    echo "================================================================================"
    echo "                           INSTALLATION MENU"
    echo "================================================================================"
    echo
    echo "   [1] Install Server Dependencies"
    echo "   [2] Install Client Dependencies"
    echo "   [3] Install BOTH Server and Client Dependencies"
    echo
    echo "   [0] Exit"
    echo
    read -p "Select an option [0-3]: " choice

    case $choice in
        1)
            install_server_deps
            break
            ;;
        2)
            install_client_deps
            break
            ;;
        3)
            install_server_deps
            install_client_deps
            echo
            echo "================================================================================"
            echo "                  BOTH SERVER AND CLIENT ARE SET UP!"
            echo "================================================================================"
            echo
            echo "To start the server, run: ./scripts/run_server.sh"
            echo "To start the client, run: ./scripts/run_client.sh"
            echo
            break
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
