#!/bin/bash

USER_DIR="/home"  # Adjust the user directory path as needed

# Check if any user's .bash_history is empty or not present
for dir in "$USER_DIR"/*; do
    username=$(basename "$dir")
    history_file="$dir/.bash_history"

    if [ ! -f "$history_file" ] || [ ! -s "$history_file" ]; then
        echo "Shutting down the machine because $username's .bash_history is either not present or empty." | wall
        sudo shutdown -h now
        break  # Exit the loop as soon as a match is found
    fi
done
