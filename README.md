# patch-scripts

Prerequisites:

Install Paramiko: If you don't have it installed, open your terminal or command prompt and run:

Bash

pip install paramiko

#############################


How to Use:

1,Save:  Save the code above as a Python file (e.g., ssh_yum_update.py).

2, Configure:

Modify the SSH_USERNAME variable to your actual SSH username.

If your private SSH key isn't in the default location (~/.ssh/id_rsa, ~/.ssh/id_dsa, etc.), set the PRIVATE_KEY_PATH variable. Otherwise, leave it as None.

Ensure servers.txt exists in the same directory and contains the list of servers.

3, Run: Open your terminal, navigate to the directory where you saved the files, and run the script:
Bash

python ssh_yum_update.py
Check Output: The script will print progress to your console and write detailed logs (including the output of yum update for each server or any errors encountered) to the update_log.log file in the same directory.
Important Considerations:

Security: Using AutoAddPolicy automatically trusts unknown host keys. This is convenient but less secure. For production environments, consider using paramiko.WarningPolicy or manually managing a known_hosts file.

Error Handling: The script includes basic error handling for common SSH issues (authentication, connection errors, command failures) but can be expanded further.

sudo Password:
If passwordless sudo is not configured, sudo yum update -y will fail because it expects a password prompt which the script cannot handle in this basic form. Handling sudo passwords programmatically is complex and generally discouraged for security reasons. Setting up passwordless sudo for specific commands (like yum) for your management user is the standard approach.

Timeouts: Connection and command execution timeouts have been added to prevent the script from hanging indefinitely on unresponsive servers or long-running updates. Adjust the timeout values in connect() and exec_command() if needed.

Resource Usage: Running yum update simultaneously or in rapid succession on many servers can consume significant network bandwidth and potentially impact server performance. Consider adding delays (time.sleep()) or using more advanced parallel execution methods (like threading or asyncio) if dealing with a very large number of servers.
~                                                                                                                                                                                  
~                                                                                                        
