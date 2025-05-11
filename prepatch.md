Okay, here's a pre-patch bash script designed to read a list of Linux servers, check all running processes on each, and log the output to a file.

**Assumptions:**

1.  **SSH Key-Based Authentication:** The script assumes you have SSH key-based authentication set up for the user running the script to all target servers. This means you can SSH to each server without being prompted for a password. If not, you'll need to set this up or modify the script to handle password authentication (which is generally less secure and harder to automate).
2.  **`ssh` and `ps` commands:** The script relies on the `ssh` client being available on the machine running the script and the `ps` command being available on all remote servers.
3.  **Server List File Format:** The server list file should contain one hostname or IP address per line.

**Pre-Patch Script (`check_processes.sh`):**



**How to Use:**

1.  **Create the Server List File:**
    Create a file named `server_list.txt` (or the name you specify in `SERVER_LIST_FILE` within the script). Add the hostnames or IP addresses of your Linux servers, one per line. For example:

    ```text
    server1.example.com
    192.168.1.10
    #server2.example.com (this line will be skipped)
    appserver03
    ```

2.  **Save the Script:**
    Save the script above as `check_processes.sh` (or any other name) on the machine from which you will run the checks.

3.  **Make the Script Executable:**
    Open your terminal and run:
    ```bash
    chmod +x check_processes.sh
    ```

4.  **Configure SSH (Important!):**
    * **SSH User:** Modify the `SSH_USER` variable in the script if the user running the script is different from the user you need to SSH as on the remote servers.
    * **Key-Based Authentication:** Ensure you can SSH from the machine running the script to each server in your `server_list.txt` as the `SSH_USER` *without* a password prompt. If you haven't set this up, you'll need to generate an SSH key pair (using `ssh-keygen`) and copy the public key to the `~/.ssh/authorized_keys` file on each target server for the respective user.

5.  **Run the Script:**
    Execute the script from your terminal:
    ```bash
    ./check_processes.sh
    ```

6.  **Check the Output:**
    * A log file named `process_log_YYYYMMDD_HHMMSS.txt` (e.g., `process_log_20250510_214022.txt`) will be created in the same directory. This file will contain the list of processes for each server.
    * An error log file named `process_log_YYYYMMDD_HHMMSS.txt.error` will be created. This will contain any errors encountered during SSH connections or command execution (e.g., "Permission denied", "Connection timed out").

**Explanation:**

* **`#!/bin/bash`**: Shebang, specifies the interpreter for the script.
* **`SERVER_LIST_FILE`**: Variable holding the name of the file containing server IPs/hostnames.
* **`OUTPUT_LOG_FILE`**: Variable for the main log file. The `$(date +%Y%m%d_%H%M%S)` part adds a timestamp to make the log file unique for each run.
* **`SSH_USER`**: The username to use for SSH connections. `$(whoami)` defaults to the current user.
* **`SSH_TIMEOUT`**: Sets a timeout for SSH connections to prevent the script from hanging indefinitely on an unresponsive server.
* **`log_message()` function**: A simple function to prepend a timestamp to messages and write them to both the console and the main log file.
* **`check_server_processes()` function**:
    * Takes a server address as an argument.
    * Logs the connection attempt and server details to the output file.
    * Uses the `ssh` command:
        * `-o ConnectTimeout="$SSH_TIMEOUT"`: Sets the connection timeout.
        * `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`: These options are included for ease of use in environments where host keys might not be pre-configured or might change. **Security Note:** For production environments with stable infrastructure, it's generally better to use `StrictHostKeyChecking=yes` (or `ask`) and manage your `known_hosts` file properly to prevent man-in-the-middle attacks.
        * `"$SSH_USER@$server"`: Specifies the user and server for the SSH connection.
        * `"ps aux"`: The command executed on the remote server. `ps aux` is a common command to get a comprehensive list of all running processes, including those from other users and those without a controlling terminal.
        * `>> "$OUTPUT_LOG_FILE"`: Appends the standard output (the process list) to the log file.
        * `2>> "$OUTPUT_LOG_FILE.error"`: Appends any standard error output from the SSH command (like connection errors) to a separate error log file.
    * Logs success or failure of the operation.
* **Main Script Logic**:
    * Checks if the `SERVER_LIST_FILE` exists.
    * Initializes the log files.
    * Uses a `while IFS= read -r server_address || [ -n "$server_address" ]` loop to read each line from the `SERVER_LIST_FILE`.
        * `IFS=`: Prevents leading/trailing whitespace from being trimmed by `read`.
        * `-r`: Prevents backslash escapes from being interpreted.
        * `|| [ -n "$server_address" ]`: Ensures that the last line of the file is processed even if it doesn't end with a newline character.
    * Skips empty lines and lines starting with `#` (comments) in the server list.
    * Calls `check_server_processes` for each valid server address.
    * Logs the completion of the script.

**Further Enhancements (Optional):**

* **Password Authentication (Less Secure):** If key-based auth isn't feasible, you could look into tools like `sshpass` (requires installation and is generally discouraged due to security risks of exposing passwords).
* **Parallel Execution:** For a very large number of servers, you might want to run the checks in parallel to speed things up (e.g., using `xargs -P` or GNU Parallel).
* **More Specific Process Filtering:** If you only care about specific processes, you could modify the `ps aux` command (e.g., `ps aux | grep 'my_process_name'`).
* **Configuration File:** For more options, consider moving configurations like `SSH_USER`, `SSH_TIMEOUT`, and output directories to a separate configuration file that the script reads.
* **Error Reporting:** Send email notifications on failure.
* **Pre-Patch/Post-Patch Comparison:** If you run this script before and after patching, you could write another script to compare the process lists and highlight differences.

This script provides a solid foundation for your pre-patch process checking. Remember to adapt it to your specific environment and security policies.
