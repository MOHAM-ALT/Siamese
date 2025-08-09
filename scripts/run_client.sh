#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

echo "================================================================================"
echo "                           AI CONTROL CLIENT LAUNCHER"
echo "================================================================================"
echo

# Check for virtual environment
if [ ! -f "venv_client/bin/activate" ]; then
    echo "[ERROR] Client virtual environment not found."
    echo "Please run './scripts/install.sh' first to set up the client."
    exit 1
fi

echo "Activating client environment..."
source venv_client/bin/activate

while true; do
    echo "================================================================================"
    echo "                           CLIENT LAUNCH MENU"
    echo "================================================================================"
    echo
    echo "   [1] Connect in Automatic Mode (waits for server commands)"
    echo "   [2] Start Interactive Mode (send commands from here)"
    echo "   [3] Send a Single Command"
    echo
    echo "   [0] Exit"
    echo
    read -p "Select a mode [0-3]: " choice

    case $choice in
        1)
            echo
            echo "Starting client in Automatic Mode..."
            python -m src.client.main auto
            read -p "Press Enter to return to the menu..."
            ;;
        2)
            echo
            echo "Starting client in Interactive Mode..."
            python -m src.client.main interactive
            read -p "Press Enter to return to the menu..."
            ;;
        3)
            echo
            read -p "Enter the command to send: " cmd_string
            if [ -z "$cmd_string" ]; then
                echo "No command entered."
            else
                python -m src.client.main command "$cmd_string"
            fi
            read -p "Press Enter to return to the menu..."
            ;;
        0)
            deactivate
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
