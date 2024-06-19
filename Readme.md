# cpn_resume_check.sh README

## Description
 Check compute node before resuming from slurm.
 This script checks the compute node before resuming from slurm. It requires the installation of pdsh and the configuration of passwordless ssh. 
 The script should be executed on the deploy node (imn05). The `sinfo` command needs to be executed on the slurm controller.

## Preseqquisites
- slurm and pdsh
- Bash shell

## Usage
1. Make the script executable:
    ```bash
    chmod +x cpn_resume_check.sh
    ```
2. Edit slurm controller node
3. Run the script:
    ``` bash
    # Get information
    ./cpn_resume_check.sh -h
    # Get Drained node information
    ./cpn_resume_check.sh -s
    # Check ECC memory error count
    ./cpn_resume_check.sh -r <target_inventory>
    # Check node status
    ./cpn_resume_check.sh -i <target_inventory>
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
    ./ping_check.sh
    ```
4. Get the result and a file:
    ```bash
    Ping TARGET_HOSTNAME1 TARGET_IP Success
    ```
# Contributing
Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.