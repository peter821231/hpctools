#!/bin/bash
# Check the status of a list of hostnames by pinging them by internal IP and send an email if the status changes.
# The script will send an email if the ping status changes from success to failure or vice versa.
# The script will try to send the email via the main mail server first, and if that fails, it will try the backup mail server.
# The script uses a status file to keep track of the last ping status for each hostname.
# The script can be run as a cron job to periodically check the status of the hostnames.

# Mail settings
ADMINS="ADMIN_EMAIL_ADDRESS"
MailServer="MAILSERVER"
BackupMailServer="MAILSERVER_BACKUP"
SENDER="PING_CHECK"
hostnames=(TARGET_HOSTNAME1 TARGET_HOSTNAME2 TARGET_HOSTNAME3)
# Special Check for ecs ip (Non-internal IP)
# ecs_hostname=("RANDOM_ECS1" "RANDOM_ECS2" "RANDOM_ECS3")
# ecs_ip=("RANDOM_IP1" "RANDOM_IP2" "RANDOM_IP3)

# Ping_status settins
script_dir=$(dirname "$(readlink -f "$0")")
status_file="$script_dir/ping_status.txt"
VERBOSE=false

# Parse command line arguments
while getopts "vh" opt; do
  case $opt in
    v)
      VERBOSE=true
      ;;
    h)
      echo "Usage: $0 [-v]"
      echo "  -v  Enable verbose output"
      exit 0
      ;;
    *)
      echo "Usage: $0 [-v]"
      exit 1
      ;;
  esac
done

check_and_send_mail() {
    hostname=$1
    ip=$2
    MailServer=$3
    BackupMailServer=$4
    ADMINS=$5
    SENDER=$6
    status_file=$7
    VERBOSE=$8

    if ping -q -c 3 "$ip" &> /dev/null; then
        [[ "$VERBOSE" == "true" ]] && echo "Ping ${hostname} ${ip} Success"
        current_status="SUCCESS"
    else
        [[ "$VERBOSE" == "true" ]] && echo "Ping ${hostname} ${ip} Failed"
        current_status="FAILED"
    fi

    last_status=$(grep "^$hostname:" "$status_file" | cut -d':' -f2)

    if [[ "$current_status" != "$last_status" ]]; then
        if [[ "$current_status" == "FAILED" ]]; then
            Subject="Ping Failure Alert: $hostname ($ip)"
            Body="Ping to $hostname ($ip) failed. Please check server status."
        else
            Subject="Ping Recovery Alert: $hostname ($ip)"
            Body="Ping to $hostname ($ip) is successful now."
        fi

        if ! ssh "$MailServer" "echo -e '$Body' | mail -s '$Subject' -r '$SENDER' '$ADMINS'" > /dev/null 2>&1; then
            ssh "$BackupMailServer" "echo -e '$Body' | mail -s '$Subject' -r '$SENDER' '$ADMINS'" > /dev/null 2>&1
        fi

        sed -i "s/^$hostname:.*/$hostname:$current_status/" "$status_file"
    fi
}

# Export the function so it can be used by parallel processes
export -f check_and_send_mail


# Main code 
# Initialize the status file
if [[ ! -f "$status_file" ]]; then
    touch "$status_file"
fi

# Process each hostname
for hostname in "${hostnames[@]}"; do
    ip=$(getent ahosts "$hostname" | awk '/^172\./ {print $1; exit}')
    if [[ -n "$ip" ]]; then
        # Add hostname to status file if not present
        if ! grep -q "^$hostname:" "$status_file"; then
            echo "$hostname:SUCCESS" >> "$status_file"
        fi
        # Check and send mail
        check_and_send_mail "$hostname" "$ip" "$MailServer" "$BackupMailServer" "$ADMINS" "$SENDER" "$status_file" "$VERBOSE" &
    else
        [[ "$VERBOSE" == "true" ]] && echo "Skipping $hostname, no internal IP found."
    fi
done

# Special Check for ecs
# COUNT=0
# for hostname in "${ecs_hostname[@]}"; do
#   ip=${ecs_ip[${COUNT}]}
#   # Add hostname to status file if not present
#   if ! grep -q "^$hostname:" "$status_file"; then
#     echo "$hostname:SUCCESS" >> "$status_file"
#   fi
#   check_and_send_mail "$hostname" "$ip" "$MailServer" "$BackupMailServer" "$ADMINS" "$SENDER" "$status_file" "$VERBOSE" &
#   COUNT=$COUNT+1
# done

# Wait for all background jobs to complete
wait