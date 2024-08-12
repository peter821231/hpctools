#!/bin/bash
# Check compurte node before resume from slurm
# You need to install pdsh and configure passwordless ssh
# Need execute on deploy node (imn05)
# sinfo command need to execute on slurm controller
# Note: This script should be run as a privileged user with appropriate permissions to interact with the slurm system.
slurm_controller="isn09"

# parse command line arguments
function help_func() 
{
  echo "Usage: $(basename $0) -s, Check drained node"
  echo "Usage: $(basename $0) -i <inventory>, Check compute node status"
  echo "Usage: $(basename $0) -q <inventory>, Check compute node queue status"
  echo "Usage: $(basename $0) -m <inventory>, Check compute node IB recently status"
  echo "Usage: $(basename $0) -r <inventory>, Check ECC Memory error msg"
  echo "Available iventory:"
  echo "icpnq[1-7][01-56],icpnp[1-2][01-56],icpnp3[01-48],gpn[01-06],ncpn[01-40]"
  echo "Ex: $(basename $0) -i icpnq101"
  echo "Ex: $(basename $0) -i icpnp101,icpnq234"

  exit 1
}

function online_check()
{
  # Check IB switch status
  echo "=====Check IB switch status (State/Rate)====="
  pdsh -w ${inventory} "ibstat | grep 'Link layer\|Physical\|State\|Rate' | awk '{print \$1,\$2,\$3}'"
  # Check GPFS directory status
  echo "=====Check GPFS directory status====="
  pdsh -w ${inventory} "df -h | grep 'home1\|home2\|project\|work1\|work2\|mgmt\|pkg' && echo ''"
  # Check slurmd and ldap status
  echo "=====Check slurmd status====="
  pdsh -w ${inventory} "systemctl status slurmd | grep 'Active:'"
  echo "=====Check ldap status====="
  pdsh -w ${inventory} "systemctl status sssd | grep 'Active:'"
  # Check CPU and memory status
  echo "=====Check RAM status====="
  pdsh -w ${inventory} "free -g | grep Mem | awk '{print \$1,\$2}'"
  echo "=====Check CPU status====="
  pdsh -w ${inventory} "lscpu | grep -m 1 'CPU(s):' | awk '{print \$1,\$2}'"
  offline_cpu=`pdsh -w ${inventory} "lscpu | grep Off-line"`
  if [ -n "${offline_cpu}" ]; then
    echo "Warning: ${offline_cpu}"
  fi
}

OPTSTRING="i:q:m:sr:h"
while getopts ${OPTSTRING} opt; do
    case "$opt" in
        i)
        arg="$OPTARG"
        inventory="$OPTARG"
        online_check
        exit
        ;;
        q)
        arg="$OPTARG"
        inventory="$OPTARG"
        ssh ${slurm_controller} "squeue -w ${inventory}"
        exit        
        ;;
        m)
        arg="$OPTARG"
        inventory="$OPTARG" 
        pdsh -w ${inventory} "mmhealth node show"
        exit
        ;;
        s)
        echo "Check Drained node"
        ssh ${slurm_controller} "sinfo -R"
        exit
        ;;
        r)
        echo "Check ECC Memory error msg"
        echo "  Count,    Node: Date"
        arg="$OPTARG"
        inventory="$OPTARG"
        pdsh -w ${inventory} "ipmitool sel elist | grep 'Correctable ECC'" | awk '{print $1, $4}' | sort | uniq -c
        exit
        ;;
      ?|h)
        help_func
        ;;
    esac
done
shift "$(($OPTIND -1))"

if [ -z "$inventory" ]; then
    help_func
fi