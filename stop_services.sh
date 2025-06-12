#!/bin/bash

# A shell script to remotely stop Tomcat and ActiveMQ services.
#
# Usage:
# ./stop_services.sh /path/to/your/server_list.txt
#
# The server_list.txt file should contain one hostname or IP address per line.
# Example server_list.txt:
# server1.example.com
# 192.168.1.10
# server2.example.com

# --- Configuration ---
# The script identifies processes by looking for these unique strings in the process list.
# You might need to adjust these if your process names are different.
TOMCAT_IDENTIFIER="catalina.startup.Bootstrap"
ACTIVEMQ_IDENTIFIER="activemq.jar"

# --- Script Logic ---

# Check if a server list file was provided as an argument.
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <server_list_file>"
    exit 1
fi

SERVER_LIST_FILE=$1

# Check if the server list file exists and is readable.
if [ ! -f "$SERVER_LIST_FILE" ]; then
    echo "Error: Server list file not found at '$SERVER_LIST_FILE'"
    exit 1
fi

# Loop through each server in the provided file.
while IFS= read -r server || [[ -n "$server" ]]; do
    
    # Skip empty lines in the server list file.
    if [ -z "$server" ]; then
        continue
    fi

    echo "----------------------------------------------------"
    echo "Connecting to: $server"
    echo "----------------------------------------------------"

    # Use SSH to execute the stop commands on the remote server.
    # The commands are enclosed in a single set of double quotes.
    ssh -n -o ConnectTimeout=10 "$server" "
        echo '[INFO] Searching for Tomcat and ActiveMQ processes...'

        # Find and kill the Tomcat process.
        # We use ps -ef to get all processes, grep for the identifier,
        # and grep -v grep to exclude the grep command itself from the results.
        TOMCAT_PID=\$(ps -ef | grep '$TOMCAT_IDENTIFIER' | grep -v grep | awk '{print \$2}')
        
        if [ -n \"\$TOMCAT_PID\" ]; then
            echo \"[SUCCESS] Found Tomcat process with PID: \$TOMCAT_PID\"
            echo \"[ACTION] Stopping Tomcat...\"
            kill -9 \$TOMCAT_PID
            echo \"[STATUS] Tomcat process terminated.\"
        else
            echo \"[WARN] Tomcat process not found.\"
        fi

        echo # For a blank line separator

        # Find and kill the ActiveMQ process.
        ACTIVEMQ_PID=\$(ps -ef | grep '$ACTIVEMQ_IDENTIFIER' | grep -v grep | awk '{print \$2}')

        if [ -n \"\$ACTIVEMQ_PID\" ]; then
            echo \"[SUCCESS] Found ActiveMQ process with PID: \$ACTIVEMQ_PID\"
            echo \"[ACTION] Stopping ActiveMQ...\"
            kill -9 \$ACTIVEMQ_PID
            echo \"[STATUS] ActiveMQ process terminated.\"
        else
            echo \"[WARN] ActiveMQ process not found.\"
        fi

        echo '[INFO] Actions complete on $server.'
    "
    
    # Check the exit code of the SSH command to see if the connection failed.
    if [ $? -ne 0 ]; then
        echo "[ERROR] Could not connect to $server. Please check the hostname and your SSH configuration."
    fi


done < "$SERVER_LIST_FILE"

echo "===================================================="
echo "Script finished."
echo "===================================================="
