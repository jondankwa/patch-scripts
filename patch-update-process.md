Okay, here's a shell script that should accomplish what you're looking for.

**Important Considerations and Assumptions:**

1.  **SSH Key-Based Authentication:** This script assumes you have SSH key-based authentication set up for all servers listed in `server.txt`. This is crucial because the script will otherwise hang waiting for password input for each server.
2.  **User for SSH:** The script will attempt to connect as the current user running the script. If you need to connect as a different user, you'll need to modify the `ssh` command (e.g., `ssh user@$server ...`).
3.  **`sudo` for `yum`:** `yum check-update` typically requires `sudo` privileges. The script includes `sudo` in the command. Ensure the user you're connecting as has passwordless `sudo` rights for `yum check-update` on the remote servers, or the script will hang.
4.  **Tomcat Process Identification:** The script uses `ps aux | grep '[t]omcat'` to check for Tomcat.
    * The `[t]omcat` is a common trick to prevent the `grep` command itself from showing up in the results.
    * This might not be perfectly accurate for all Tomcat installations. You might need to adjust this based on how Tomcat is named or run in your environment (e.g., looking for `java` processes with specific Tomcat paths or a specific service name like `systemctl is-active tomcat`).
5.  **Error Handling:** This script has basic error checking for file existence. Robust error handling for SSH connection failures, command failures on remote hosts, etc., would make the script significantly more complex.
6.  **Log File Naming:** Log files are created with a timestamp in their name to avoid overwriting previous logs.
7.  **`server.txt` Format:** This file should contain one server hostname or IP address per line.

```bash
#!/bin/bash

# Define the server list file
SERVER_LIST="server.txt"

# Define log file names with timestamps
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
YUM_UPDATE_LOG="yum_updates_${TIMESTAMP}.log"
TOMCAT_STATUS_LOG="tomcat_status_${TIMESTAMP}.log"

# Check if server list file exists
if [ ! -f "${SERVER_LIST}" ]; then
    echo "ERROR: Server list file '${SERVER_LIST}' not found."
    exit 1
fi

echo "Starting server checks..."
echo "----------------------------------------"

# Create or clear log files
> "${YUM_UPDATE_LOG}"
> "${TOMCAT_STATUS_LOG}"

# Read the server list file line by line
while IFS= read -r server || [[ -n "$server" ]]; do
    if [ -z "$server" ]; then
        continue # Skip empty lines
    fi

    echo "Processing server: ${server}"

    # --- Check for YUM updates ---
    echo "Checking YUM updates on ${server}..."
    # Attempt to connect and run yum check-update. Output errors to stderr.
    # The `|| true` prevents the script from exiting if ssh or yum fails on one server.
    ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "sudo yum check-update" >> "${YUM_UPDATE_LOG}" 2>> "${YUM_UPDATE_LOG}.error" || true
    if [ $? -ne 0 ]; then
        echo "WARNING: Could not retrieve YUM updates from ${server}. Check ${YUM_UPDATE_LOG}.error" | tee -a "${YUM_UPDATE_LOG}"
    else
        # Add a header for each server in the yum log for clarity
        echo "--- Updates for ${server} (${TIMESTAMP}) ---" >> "${YUM_UPDATE_LOG}"
        ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "sudo yum check-update" >> "${YUM_UPDATE_LOG}" 2>/dev/null || true
        echo "--- End of updates for ${server} ---" >> "${YUM_UPDATE_LOG}"
        echo "" >> "${YUM_UPDATE_LOG}"
    fi

    # --- Check for Tomcat process ---
    echo "Checking Tomcat status on ${server}..."
    # The `grep '[t]omcat'` avoids matching the grep process itself.
    # `ssh -n` prevents reading from stdin, which is good for non-interactive commands.
    # `BatchMode=yes` disables password prompting, relying on key-based auth.
    # `ConnectTimeout` sets a timeout for the connection attempt.
    if ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "ps aux | grep '[t]omcat'" > /dev/null 2>&1; then
        tomcat_running_status="RUNNING"
        echo "${TIMESTAMP} - ${server} - Tomcat: ${tomcat_running_status}" >> "${TOMCAT_STATUS_LOG}"
        echo "Tomcat is RUNNING on ${server}"
    else
        # If the grep command fails (exit code > 0), it means no matching process was found.
        # Or if SSH itself failed. We'll assume not running for simplicity here,
        # but more robust error handling could differentiate SSH failure from no process.
        if ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "exit 0" > /dev/null 2>&1; then # Check if server is reachable
            tomcat_running_status="NOT RUNNING"
            echo "Tomcat is NOT RUNNING on ${server}"
        else
            tomcat_running_status="COULD NOT CONNECT"
            echo "WARNING: Could not connect to ${server} to check Tomcat status."
        fi
        echo "${TIMESTAMP} - ${server} - Tomcat: ${tomcat_running_status}" >> "${TOMCAT_STATUS_LOG}"
    fi

    echo "----------------------------------------"

done < "${SERVER_LIST}"

echo "Server checks completed."
echo "YUM update checks logged to: ${YUM_UPDATE_LOG}"
echo "Tomcat status logged to: ${TOMCAT_STATUS_LOG}"
if [ -f "${YUM_UPDATE_LOG}.error" ] && [ -s "${YUM_UPDATE_LOG}.error" ]; then
    echo "Errors during YUM update checks logged to: ${YUM_UPDATE_LOG}.error"
fi
```

**How to Use:**

1.  **Save the Script:** Save the code above into a file, for example, `server_checker.sh`.
2.  **Make it Executable:** Open your terminal and run `chmod +x server_checker.sh`.
3.  **Create `server.txt`:** Create a file named `server.txt` in the same directory as the script. Add the hostnames or IP addresses of your servers, one per line. For example:
    ```
    server1.example.com
    192.168.1.10
    server2.domain.local
    ```
4.  **Set up SSH Keys:** Ensure you can SSH into each server listed in `server.txt` from the machine where you'll run the script *without* being prompted for a password.
    * If you haven't, you'll need to generate an SSH key pair (e.g., using `ssh-keygen`) on the machine running the script and then copy the public key to the `~/.ssh/authorized_keys` file on each remote server for the appropriate user.
5.  **Ensure `sudo` Access (for `yum`):** The user connecting via SSH needs to be able to run `sudo yum check-update` without a password prompt on the remote servers. You can configure this in the `/etc/sudoers` file on each remote server (be very careful when editing this file!).
6.  **Run the Script:** Execute the script from your terminal: `./server_checker.sh`

**Explanation:**

* `#!/bin/bash`: Shebang, specifies the interpreter.
* `SERVER_LIST="server.txt"`: Defines the input file.
* `TIMESTAMP=$(date +%Y%m%d_%H%M%S)`: Creates a timestamp string (e.g., `20230512_103055`).
* `YUM_UPDATE_LOG="yum_updates_${TIMESTAMP}.log"`: Sets the name for the YUM log file.
* `TOMCAT_STATUS_LOG="tomcat_status_${TIMESTAMP}.log"`: Sets the name for the Tomcat status log file.
* `if [ ! -f "${SERVER_LIST}" ]`: Checks if `server.txt` exists.
* `> "${YUM_UPDATE_LOG}"`: Creates or truncates the log files at the beginning of the script.
* `while IFS= read -r server || [[ -n "$server" ]]`: This is a robust way to read a file line by line, handling lines with leading/trailing whitespace and ensuring the last line is read even if it doesn't have a newline character.
* `if [ -z "$server" ]; then continue; fi`: Skips empty lines in `server.txt`.
* `ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "sudo yum check-update"`:
    * `ssh`: The command to connect to the remote server.
    * `-n`: Redirects stdin from `/dev/null` (prevents ssh from trying to read input).
    * `-o ConnectTimeout=10`: Sets a 10-second timeout for establishing the SSH connection.
    * `-o BatchMode=yes`: If password or passphrase authentication is required, ssh will fail instead of prompting the user. This is essential for scripting.
    * `"${server}"`: The server hostname or IP from the `server.txt` file.
    * `"sudo yum check-update"`: The command to execute on the remote server. `sudo` is used because `yum` typically requires root privileges.
    * `>> "${YUM_UPDATE_LOG}"`: Appends the standard output of the command to the YUM log file.
    * `2>> "${YUM_UPDATE_LOG}.error"`: Appends standard error to a separate error log for YUM checks.
    * `|| true`: This part ensures that if the `ssh` command fails (e.g., server unreachable, `yum` command fails), the script doesn't exit immediately but continues to the next server.
* `ssh -n -o ConnectTimeout=10 -o BatchMode=yes "${server}" "ps aux | grep '[t]omcat'"`:
    * This command remotely executes `ps aux` (to list all running processes) and pipes the output to `grep '[t]omcat'`.
    * `grep '[t]omcat'`: Searches for lines containing "tomcat". The brackets around the 't' prevent `grep` from matching its own process in the output.
    * `> /dev/null 2>&1`: Redirects both standard output and standard error to `/dev/null`. We are only interested in the *exit status* of this command.
* `if ssh ... "ps aux | grep '[t]omcat'" > /dev/null 2>&1; then`:
    * If the `grep` command finds any lines matching "tomcat", it will exit with a status of `0` (success), and the `if` condition will be true.
    * If `grep` doesn't find "tomcat", or if the `ssh` command itself fails, the exit status will be non-zero, and the `else` block will be executed.
* `echo "${TIMESTAMP} - ${server} - Tomcat: ${tomcat_running_status}" >> "${TOMCAT_STATUS_LOG}"`: Logs the server, timestamp, and Tomcat status to the Tomcat log file.
* `done < "${SERVER_LIST}"`: Indicates the end of the `while` loop and specifies that its input comes from the `SERVER_LIST` file.

Remember to adapt the Tomcat detection command (`ps aux | grep '[t]omcat'`) if your Tomcat setup is different. You might also want to add more sophisticated logging or error handling depending on your needs.
