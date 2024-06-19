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

# Get the directory of the script
script_dir=$(dirname "$(readlink -f "$0")")
status_file="$script_dir/ping_status.txt"

# Initialize the status file if it doesn't exist
if [[ ! -f "$status_file" ]]; then
    for hostname in "${hostnames[@]}"; do
        echo "$hostname:SUCCESS" >> "$status_file"
    done
fi

check_and_send_mail() {
    hostname=$1
    MailServer=$2
    BackupMailServer=$3
    ADMINS=$4
    SENDER=$5
    status_file=$6

    # Find the IP address that starts with 172. This can ommit/modify if you have a different IP range.
    ip=$(getent ahosts "$hostname" | awk '/^172\./ {print $1; exit}')
    if [[ -z "$ip" ]]; then
        echo "No internal IP found for $hostname"
    else
        if ping -q -c 3 "$ip" &> /dev/null; then
            echo "Ping ${hostname} ${ip} Success"
            current_status="SUCCESS"
        else
            echo "Ping ${hostname} ${ip} Failed"
            current_status="FAILED"
        fi

        # Get the last status
        last_status=$(grep "^$hostname:" "$status_file" | cut -d':' -f2)

        # If the status has changed, send an email and update the status file
        if [[ "$current_status" != "$last_status" ]]; then
            if [[ "$current_status" == "FAILED" ]]; then
                Subject="Ping Failure Alert: $hostname ($ip)"
                Body="Ping to $hostname ($ip) failed. Please check server status."
            else
                Subject="Ping Recovery Alert: $hostname ($ip)"
                Body="Ping to $hostname ($ip) is successful now."
            fi

            # Try sending email via the main mail server
            if ! ssh "$MailServer" "echo -e '$Body' | mail -s '$Subject' -r '$SENDER' '$ADMINS'"; then
                # If it fails, try the backup mail server
                ssh "$BackupMailServer" "echo -e '$Body' | mail -s '$Subject' -r '$SENDER' '$ADMINS'"
            fi

            # Update the status file
            sed -i "s/^$hostname:.*/$hostname:$current_status/" "$status_file"
        fi
    fi
}

# Export the function so it can be used by parallel processes
export -f check_and_send_mail

# Loop through the hostnames and run the check in parallel
for hostname in "${hostnames[@]}"; do
    check_and_send_mail "$hostname" "$MailServer" "$BackupMailServer" "$ADMINS" "$SENDER" "$status_file" &
done

# Wait for all background jobs to complete
wait
