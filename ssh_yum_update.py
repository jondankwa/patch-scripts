import paramiko
import os
import logging
from datetime import datetime

# --- Configuration ---
SERVER_LIST_FILE = 'servers.txt'
OUTPUT_LOG_FILE = 'update_log.log'
SSH_USERNAME = 'your_ssh_username'  # Replace with your SSH username
# Optional: Specify path to your private key if not in the default location (~/.ssh/id_rsa)
# PRIVATE_KEY_PATH = '/path/to/your/private/key'
PRIVATE_KEY_PATH = None # Set to None to use default key location
COMMAND = 'sudo yum update -y' # Command to execute
# --- End Configuration ---

# --- Setup Logging ---
# Clear previous log file content or setup basic config
# Setup logging to file and console
log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
log_handler_file = logging.FileHandler(OUTPUT_LOG_FILE, mode='w') # 'w' to overwrite each run
log_handler_file.setFormatter(log_formatter)

log_handler_console = logging.StreamHandler()
log_handler_console.setFormatter(log_formatter)

logger = logging.getLogger('ssh_updater')
logger.setLevel(logging.INFO) # Set level to INFO to capture info, warning, error
logger.addHandler(log_handler_file)
logger.addHandler(log_handler_console) # Also print logs to the console

# --- Main Script ---
if not os.path.exists(SERVER_LIST_FILE):
    logger.error(f"Server list file not found: {SERVER_LIST_FILE}")
    exit(1)

logger.info("Starting SSH Yum Update Process...")

try:
    with open(SERVER_LIST_FILE, 'r') as f:
        servers = [line.strip() for line in f if line.strip()] # Read servers, ignore empty lines
except IOError as e:
    logger.error(f"Error reading server list file {SERVER_LIST_FILE}: {e}")
    exit(1)

if not servers:
    logger.warning(f"No servers found in {SERVER_LIST_FILE}. Exiting.")
    exit(0)


for server in servers:
    logger.info(f"--- Processing Server: {server} ---")
    ssh_client = None # Ensure client is None initially for finally block
    try:
        ssh_client = paramiko.SSHClient()
        # Automatically add host keys (less secure, use only in trusted environments)
        # For production, consider using WarningPolicy or loading known_hosts
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        logger.info(f"Connecting to {server} as {SSH_USERNAME}...")

        connect_args = {
            'hostname': server,
            'username': SSH_USERNAME,
            'timeout': 15 # Add a connection timeout (seconds)
        }
        if PRIVATE_KEY_PATH:
            connect_args['key_filename'] = PRIVATE_KEY_PATH
            logger.info(f"Using private key: {PRIVATE_KEY_PATH}")
        else:
             logger.info("Using default SSH key location.")
             # Paramiko searches default locations like ~/.ssh/id_rsa, id_dsa etc. if key_filename is not set

        ssh_client.connect(**connect_args)

        logger.info(f"Connected successfully. Executing command: '{COMMAND}'")

        # Execute the command
        stdin, stdout, stderr = ssh_client.exec_command(COMMAND, timeout=600) # Add command timeout (seconds)

        # Wait for the command to complete and get the exit status
        exit_status = stdout.channel.recv_exit_status()

        # Read output and errors
        stdout_output = stdout.read().decode('utf-8').strip()
        stderr_output = stderr.read().decode('utf-8').strip()

        if exit_status == 0:
            logger.info(f"Command executed successfully on {server} (Exit Status: {exit_status})")
            if stdout_output:
                logger.info(f"Standard Output:\n{stdout_output}")
            else:
                 logger.info("No standard output.")
            if stderr_output: # Sometimes successful commands still print to stderr (e.g., warnings)
                logger.warning(f"Standard Error Output (Warning/Info):\n{stderr_output}")
        else:
            logger.error(f"Command failed on {server} (Exit Status: {exit_status})")
            if stdout_output:
                logger.error(f"Standard Output:\n{stdout_output}")
            if stderr_output:
                logger.error(f"Standard Error Output:\n{stderr_output}")

    except paramiko.AuthenticationException:
        logger.error(f"Authentication failed for {SSH_USERNAME}@{server}. Check username/key.")
    except paramiko.SSHException as ssh_ex:
        logger.error(f"SSH error connecting or executing on {server}: {ssh_ex}")
    except TimeoutError:
        logger.error(f"Connection or command timed out for {server}.")
    except socket.gaierror: # More specific error for DNS resolution issues
         logger.error(f"Could not resolve hostname {server}. Check DNS or server name.")
    except Exception as e:
        logger.error(f"An unexpected error occurred for {server}: {e}")
    finally:
        if ssh_client:
            ssh_client.close()
            logger.info(f"Connection closed for {server}")
        logger.info(f"--- Finished Processing Server: {server} ---")


logger.info("SSH Yum Update Process Completed.")
logger.info(f"Check '{OUTPUT_LOG_FILE}' for detailed logs.")
