# cpn_resume_check.sh README
## Description
This script is a command-line utility for Slurm administrators to perform various health and status checks on compute nodes. It's designed to help diagnose nodes before resuming them from a `drained` state, ensuring they are ready to accept jobs. The script uses `pdsh` to execute commands in parallel across multiple nodes.

## Prerequisites
Before using this script, please ensure the following requirements are met:
- **`pdsh` is installed**: The script relies on `pdsh` for parallel command execution.
- **Passwordless SSH**: You must have passwordless SSH access configured from the deployment node to all compute nodes for the user running the script.
- **Privileged Access**: The script should be run as a privileged user (e.g., `root`) with permissions to check system services and hardware status.
- **Deployment Node**: It is intended to be executed from a central management or deployment node (e.g., `imn05` as mentioned in the script's comments).

## Configuration
You need to configure one variable at the top of the script to match your environment:
- **`slurm_controller`**: Set this to the hostname of your main Slurm controller (`slurmctld`) node.
  ```bash
  slurm_controller="isn09" # Change isn09 to your Slurm controller's hostname
  ```
## Usage
The script is controlled via command-line options.
```bash
./your_script_name.sh [option] <inventory> [arguments...]
```
Option	Description
```
-i <inventory>	Online Check: Performs a comprehensive status check on the specified nodes. This includes IB status, GPFS mounts, slurmd and sssd service status, and CPU/Memory resources.
-q <inventory> [start] [end]	Queue Check: Checks the Slurm job history. It has three modes:
    1. Current Jobs: Shows currently running jobs.
    2. 10-Min History: Shows jobs in the 10 minutes prior to a given timestamp.
    3. Time Range History: Shows jobs within a specified start and end timestamp.
-m <inventory>	GPFS Health Check: Displays the GPFS mmhealth status for the specified nodes.
-r <inventory>	ECC Error Check: Scans the IPMI system event log (sel) for "Correctable ECC" memory errors and provides a summarized count per node.
-s	Drained Node Check: Lists all nodes that are currently in a drained or draining state. This command does not require an <inventory>.
-h	Help: Displays the help message with usage instructions and examples.
```
# ibcheck.sh README

## Description
ibcheck.sh is a script that performs various checks on InfiniBand (IB) network configurations.

## Prerequisites
- InfiniBand hardware and drivers installed
- Bash shell

## Usage

1. Make the script executable:
    ```bash
    chmod +x ibcheck.sh
    ```
2. Edit default OFFLINE port mapping
    ```bash
    # Variable format: IB{LF/SP}{Switch number}=(port1 port2 port3 ...)
    IBSP01=(47 48 51 52 61 62 63 64)
    ```
3. Run the script:
    ```bash
    ./ibcheck.sh
    ```
4. Get the result:
    ```bash
    Check switch and port status by iblinkinfo
    Format: physical port(virtual port)
    All Switches online OK
    IBLF01 OK
    IBLF02 OK
    IBLF03 OK
    IBLF04 OK
    IBLF05 OK
    IBLF06 OK
    IBLF07 OK
    IBLF08 OK
    IBLF09 OK
    IBLF10 OK
    IBLF11 port 3(10) Down
    IBLF11 port 3(11) Down
    IBLF11 port 26(102) Down
    IBLF11 port 26(103) Down
    IBLF12 OK
    IBLF13 OK
    IBLF14 OK
    IBLF15 OK
    IBSP01 OK
    IBSP02 OK
    IBSP03 OK
    IBSP04 OK
    IBSP05 OK
    IBSP06 OK
    IBSP07 OK
    IBSP08 OK
    ```
# ping_check.sh README
## Description
ping_check.sh is a script that periodically checks the status of a list of hostnames by pinging them using their internal IP addresses. It sends an email notification if the ping status changes from success to failure or vice versa. The script first attempts to send the email via the main mail server and, if that fails, it tries the backup mail server. It utilizes a status file to keep track of the last ping status for each hostname.

## Prerequisites
- Bash shell

## Usage

1. Make the script executable:
    ```bash
    chmod +x ping_check.sh
    ```
2. Edit the list of settings to ping:
    ```bash
    ADMINS="ADMIN_EMAIL_ADDRESS"
    MailServer="MAILSERVER"
    BackupMailServer="MAILSERVER_BACKUP"
    SENDER="PING_CHECK"
    hostnames=(TARGET_HOSTNAME1 TARGET_HOSTNAME2 TARGET_HOSTNAME3)
    ```
3. Run the script:
    ```bash
    # Quiet mode for crontab
    ./ping_check.sh
    # Verbose mode
    ./ping_check.sh -v
    ```
4. Get the result and a file:
    ```bash
    Ping TARGET_HOSTNAME1 TARGET_IP Success
    ```
# Contributing
Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
