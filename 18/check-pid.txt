#!/bin/bash
# filepath: /path/to/check-pid.sh

# Tên script cần kiểm tra
PROCESS_NAME="processfile18.sh"

# Tìm PID của processfile.sh
PID=$(pgrep -f "$PROCESS_NAME")

if [ -n "$PID" ]; then
    echo "$PROCESS_NAME is already running with PID $PID. Exiting script."
    exit 0
else
    echo "$PROCESS_NAME is not running. Starting it..."
    bash /Users/richard/Data/80/18/processfile18.sh &
    echo "$PROCESS_NAME has been started."
fi