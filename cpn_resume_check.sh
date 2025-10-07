#!/bin/bash
# Check compurte node before resume from slurm
# You need to install pdsh and configure passwordless ssh
# Need execute on deploy node (imn05)
# sinfo command need to execute on slurm controller
# Note: This script should be run as a privileged user with appropriate permissions to interact with the slurm system.
slurm_controller="isn09"

function help_func()
{
  echo "# Usage: $(basename $0) -s, Check drained node"
  echo "# Usage: $(basename $0) -i <inventory>, Check compute node status"
  echo "# Usage: $(basename $0) -q <inventory>, Check compute node queue status"
  echo "# Usage: $(basename $0) -q <inventory> <time_stamp>, Search 10min compute status"
  echo "# Usage: $(basename $0) -q <inventory> <time_stamp_start> <time_stamp_end>, Search compute node history status"
  echo "# Usage: $(basename $0) -m <inventory>, Check compute node IB recently status"
  echo "# Usage: $(basename $0) -r <inventory>, Check ECC Memory error msg"
  echo "# Available iventory:"
  echo "# icpnq[1-7][01-56],icpnp[1-2][01-56],icpnp3[01-48],gpn[01-06],ncpn[01-40]"
  echo "Ex: $(basename $0) -i icpnq101"
  echo "Ex: $(basename $0) -i icpnp101,icpnq234"
  echo "Ex: $(basename $0) -q icpnp101,icpnq234"
  echo "Ex: $(basename $0) -q icpnp101,icpnq234 2025-10-05T22:35:06"
  echo "Ex: $(basename $0) -q icpnp101,icpnq234 2025-10-01T22:35:06 2025-10-05T22:35:06"

  exit 1
}

function online_check()
{
  local inventory="$1" # Receive inventory as an argument
  # Check IB switch status
  echo "# =====Check IB switch status (State/Rate)====="
  pdsh -w ${inventory} "ibstat | grep 'Link layer\|Physical\|State\|Rate' | awk '{print \$1,\$2,\$3}'"
  # Check GPFS directory status
  echo "# =====Check GPFS directory status====="
  pdsh -w ${inventory} "df -h | grep 'home1\|home2\|project\|work1\|work2\|mgmt\|pkg' && echo ''"
  # Check slurmd and ldap status
  echo "# =====Check slurmd status====="
  pdsh -w ${inventory} "systemctl status slurmd | grep 'Active:'"
  echo "# =====Check slurmd detail status====="
  pdsh -w ${inventory} "systemctl status slurmd "
  echo "# =====Check ldap status====="
  pdsh -w ${inventory} "systemctl status sssd | grep 'Active:'"
  # Check CPU and memory status
  echo "# =====Check RAM status====="
  pdsh -w ${inventory} "free -g | grep Mem | awk '{print \$1,\$2}'"
  echo "# =====Check CPU status====="
  pdsh -w ${inventory} 'lscpu | grep -m 1 "CPU(s):" | awk "{printf \"%s %s \", \$1, \$2}"; offline=$(lscpu | grep "Off-line"); if [ -z "$offline" ]; then echo "Offline: None"; else echo "Offline: $offline"; fi'
}

function slurm_job_check()
{
    local inventory="$1"
    local time_stamp_first="$2"
    local time_stamp_second="$3"

    # Scenario 1: Inventory and two timestamp is provided, chck job history
    if [ -n "${time_stamp_second}" ]; then
        echo "## Searching time range: ${time_stamp_first} -> ${time_stamp_second}"
        ssh ${slurm_controller} "sacct -S ${time_stamp_first} -E ${time_stamp_second} -N ${inventory} -o jobid,partition,uid,start,end,Nodelist%30,state"

    # Scenario 2: Inventory and one timestamp are provided, check job history
    elif [ -n "${time_stamp_first}" ]; then
        # Calculate the start time (10 minutes before the given timestamp)
        local start_time=$(date -d "-10 mins ${time_stamp_first}" +"%Y-%m-%dT%H:%M:%S")
        echo "## Searching time range: ${start_time} -> ${time_stamp_first}"
        ssh ${slurm_controller} "sacct -S ${start_time} -E ${time_stamp_first} -N ${inventory} -o jobid,partition,uid,start,end,Nodelist%30,state"

    # Scenario 3: Only inventory is provided, check current running jobs
    else
        echo "## Checking current running jobs"
        ssh ${slurm_controller} "sacct -X -N ${inventory} -s R -o jobid,partition%15,uid,start,end,Elapsed,Timelimit,Nodelist%30,state"
    fi
}

# ===== SCRIPT EXECUTION LOGIC =====
# Variables to hold the parsed options
ACTION=""
INVENTORY=""

OPTSTRING="i:q:m:sr:h"
while getopts ${OPTSTRING} opt; do
    case "$opt" in
        i) ACTION="online_check"; INVENTORY="$OPTARG"; ;;
        q) ACTION="slurm_job_check"; INVENTORY="$OPTARG"; ;;
        m) ACTION="mmhealth"; INVENTORY="$OPTARG"; ;;
        s) ACTION="drained_check"; ;;
        r) ACTION="ecc_check"; INVENTORY="$OPTARG"; ;;
        ?|h) help_func; ;;
    esac
done

# This command shifts the processed options away, so that $1, $2, etc.
# refer to the remaining arguments. For '-q', this would be the timestamp.
shift "$(($OPTIND -1))"

# Now, execute the action based on the parsed options
if [ -n "${ACTION}" ]; then
    case "${ACTION}" in
        online_check)
            [ -z "${INVENTORY}" ] && help_func
            online_check "${INVENTORY}"
            ;;
        slurm_job_check)
            [ -z "${INVENTORY}" ] && help_func
            # Pass inventory and all remaining arguments ($@) to the function
            slurm_job_check "${INVENTORY}" "$@"
            ;;
        mmhealth)
            [ -z "${INVENTORY}" ] && help_func
            pdsh -w "${INVENTORY}" "mmhealth node show"
            ;;
        drained_check)
            echo "# Check Drained node"
            ssh ${slurm_controller} "sinfo -R"
            ;;
        ecc_check)
            [ -z "${INVENTORY}" ] && help_func
            echo "# Check ECC Memory error msg"
            echo "  Count,   Node: Date"
            pdsh -w "${INVENTORY}" "ipmitool sel elist | grep 'Correctable ECC'" | awk '{print $1, $4}' | sort | uniq -c
            ;;
    esac
else
    # If no action was specified, show help
    help_func
fi
