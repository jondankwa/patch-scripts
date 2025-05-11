#!/bin/bash

# --- Configuration ---
SERVER_LIST_FILE="server_list.txt"
OUTPUT_LOG_FILE="process_log_$(date +%Y%m%d_%H%M%S).txt"
SSH_USER="$(whoami)" # Or specify a different user: SSH_USER="your_ssh_user"
SSH_TIMEOUT=10 # Seconds to wait for SSH connection

# --- Functions ---

# Function to log messages
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$OUTPUT_LOG_FILE"
  echo "$1" # Also print to stdout
}

# Function to check processes on a remote server
check_server_processes() {
  local server="$1"

  log_message "Connecting to $server..."
  echo "==================================================" >> "$OUTPUT_LOG_FILE"
  echo "Server: $server" >> "$OUTPUT_LOG_FILE"
  echo "Timestamp: $(date +'%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_LOG_FILE"
  echo "--------------------------------------------------" >> "$OUTPUT_LOG_FILE"

  # Attempt to SSH and get process list
  # -o ConnectTimeout: Specifies the timeout (in seconds) used when connecting to the SSH server.
  # -o StrictHostKeyChecking=no: Disables strict host key checking (use with caution, consider 'yes' or 'ask' in production with known_hosts).
  # -o UserKnownHostsFile=/dev/null: Prevents ssh from adding host keys to the user's known_hosts file (again, use with caution).
  # The 'ps aux' command provides a detailed list of all running processes.
  if ssh -o ConnectTimeout="$SSH_TIMEOUT" \
         -o StrictHostKeyChecking=no \
         -o UserKnownHostsFile=/dev/null \
         "$SSH_USER@$server" "ps aux" >> "$OUTPUT_LOG_FILE" 2>> "$OUTPUT_LOG_FILE.error"; then
    log_message "Successfully retrieved processes from $server."
  else
    log_message "ERROR: Failed to connect to $server or execute command. Check $OUTPUT_LOG_FILE.error for details."
    echo "--------------------------------------------------" >> "$OUTPUT_LOG_FILE"
    echo "Error connecting to $server or executing command." >> "$OUTPUT_LOG_FILE"
    echo "See $OUTPUT_LOG_FILE.error for specific SSH errors." >> "$OUTPUT_LOG_FILE"
  fi
  echo "==================================================" >> "$OUTPUT_LOG_FILE"
  echo "" >> "$OUTPUT_LOG_FILE" # Add a blank line for readability
}

# --- Main Script ---

# Check if server list file exists
if [ ! -f "$SERVER_LIST_FILE" ]; then
  echo "ERROR: Server list file '$SERVER_LIST_FILE' not found."
  exit 1
fi

# Start logging
log_message "Starting pre-patch process check script."
log_message "Reading servers from: $SERVER_LIST_FILE"
log_message "Logging output to: $OUTPUT_LOG_FILE"
log_message "Logging errors to: $OUTPUT_LOG_FILE.error"
echo "" > "$OUTPUT_LOG_FILE.error" # Clear/create error log file

# Read server list and process each server
while IFS= read -r server_address || [ -n "$server_address" ]; do
  # Skip empty lines or lines starting with # (comments)
  if [[ -z "$server_address" ]] || [[ "$server_address" =~ ^# ]]; then
    continue
  fi

  check_server_processes "$server_address"
done < "$SERVER_LIST_FILE"

log_message "Pre-patch process check script finished."
log_message "Review $OUTPUT_LOG_FILE for process details."
log_message "Review $OUTPUT_LOG_FILE.error for any connection or command execution errors."

exit 0
