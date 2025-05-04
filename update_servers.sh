#!/bin/bash

# --- Configuration ---
SERVER_FILE="servers.txt"  # File containing list of servers, one per line
LOG_FILE="update_log.txt"    # File to write output to
SSH_USER=""                # Optional: Specify SSH user if different from current user
                           # Example: SSH_USER="admin"
                           # If empty, uses the current logged-in username

# --- Script Logic ---

# Check if the server list file exists
if [ ! -f "$SERVER_FILE" ]; then
    echo "Error: Server list file '$SERVER_FILE' not found."
    exit 1
fi

# Prepare the log file (overwrite if exists, create if not)
# Use '>>' instead of '>' if you want to append to an existing log file
echo "Starting server updates at $(date)" > "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Construct the SSH user prefix if specified
SSH_TARGET_PREFIX=""
if [ -n "$SSH_USER" ]; then
    SSH_TARGET_PREFIX="${SSH_USER}@"
fi

# Read the server list and loop through each server
# Note: This 'for server in $(cat ...)' approach can have issues if server names
# contain spaces or special characters. A 'while read' loop is generally safer.
# See alternative below the script.
echo "Reading servers from $SERVER_FILE..."
for server in $(cat "$SERVER_FILE")
do
    # Skip empty lines or lines starting with # (comments)
    if [[ -z "$server" ]] || [[ "$server" == \#* ]]; then
        continue
    fi

    TARGET="${SSH_TARGET_PREFIX}${server}"

    echo "----------------------------------------" | tee -a "$LOG_FILE"
    echo "Attempting update on: $server (as user: ${SSH_USER:-$(whoami)})" | tee -a "$LOG_FILE"
    echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
    echo "----------------------------------------" | tee -a "$LOG_FILE"

    # Connect via SSH and run the update command
    # -t option forces pseudo-terminal allocation, sometimes needed for sudo
    # -q option suppresses some SSH messages
    # 'sudo yum update -y' attempts the update non-interactively
    # Output (stdout & stderr) is appended to the log file
    ssh -t -q "${TARGET}" 'sudo yum update -y' >> "$LOG_FILE" 2>&1

    # Check the exit status of the SSH command
    if [ $? -eq 0 ]; then
        echo "Update command completed successfully (or no updates needed) on $server." | tee -a "$LOG_FILE"
    else
        echo "!!! Update command failed or SSH connection issue on $server. Check log file. !!!" | tee -a "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE" # Add a blank line for readability in the log

done

echo "========================================" >> "$LOG_FILE"
echo "Server update process finished at $(date)" >> "$LOG_FILE"
echo "All server updates attempted. Check '$LOG_FILE' for detailed results."

exit 0
