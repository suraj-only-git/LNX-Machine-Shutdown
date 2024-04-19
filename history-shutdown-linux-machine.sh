#!/bin/bash

# Ensure the script is executed with sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (with sudo)."
   exit 1
fi

# Define the command to add to .bashrc
command_to_add="PROMPT_COMMAND='history -a'"
timestamp_command="export HISTTIMEFORMAT='%F %T '"  # Add this command to enable history timestamps


# Iterate through all users in /home and root
for user_dir in /home/* /root; do
   user=$(basename "$user_dir")

   # Check if .bashrc exists for the user
   if [ -f "$user_dir/.bashrc" ]; then
      # Append the command to .bashrc
      echo "$command_to_add" | tee -a "$user_dir/.bashrc" > /dev/null
      echo "$timestamp_command" | tee -a "$user_dir/.bashrc" > /dev/null
      echo "Added $command_to_add to $user's .bashrc"
   else
      echo "$user does not have a .bashrc file." | wall
   fi
done

echo "Script completed." | wall

# Define excluded editors
excluded_editors=("vi" "nano" "vim" "emacs")  # Add other editors if needed

# Check if any excluded editor is running
for editor in "${excluded_editors[@]}"; do
    if pgrep "$editor" >/dev/null; then
        echo "An excluded editor ($editor) is running. Exiting the script."
        exit 0  # Exit the script
    fi
done

# Set thresholds for idle times in seconds
shutdown_threshold=150  # 15 minutes
warning_threshold=350  # 15 minutes

# Get the list of all non-root users
#users=$(who | awk '$1 != "root" {print $1}')

# Get the list of all users (only home users)
users=$(who | awk '{print $1}')

# Include the root user explicitly
users="$users root"

# Print the list of users using wall
echo "$users" | wall

# Loop through all users
for user in $users; do
    # Get the user's home directory
    user_home=$(eval echo ~$user)

    # Check if the user's .bash_history file exists
    history_file="$user_home/.bash_history"

    if [ -f "$history_file" ]; then
        # Calculate the time difference based on the last modification time of .bash_history
        current_time=$(date +%s)
        last_modification_time_seconds=$(stat -c %Y "$history_file")
        time_difference=$((current_time - last_modification_time_seconds))

        # Convert seconds into minutes and seconds
        #minutes=$((time_difference / 60))
        #seconds=$((time_difference % 60))

        # Display the time difference in a more human-readable format
        #echo "Time since last activity: $minutes minutes and $seconds seconds" | wall

        # Check if the user's bash history file meets the shutdown threshold
        if [ "$time_difference" -ge "$shutdown_threshold" ]; then
            echo "Machine is idle. Initiating automatic shutdown." | wall
            sudo rm -r "$history_file"
            sudo shutdown -h now
            exit
        elif [ "$time_difference" -ge "$warning_threshold" ]; then
            echo "Machine is idle. Please use the machine or else it will shut down in 5 minutes." | wall
        fi
    fi
done
