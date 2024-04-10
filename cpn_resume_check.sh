#!/bin/bash
# Check compurte node before resume from slurm
# You need to install pdsh and configure passwordless ssh
# Need execute on deploy node (imn05)
# sinfo command need to execute on slurm controller
# Note: This script should be run as a privileged user with appropriate permissions to interact with the slurm system.
slurm_controller="isn09"

# parse command line arguments
help_func() 
{
  echo "Usage: $(basename $0) -s"
  echo "Check drained node"
  echo "Usage: $(basename $0) [-i inventory]"
  echo "Available iventory:"
  echo "icpnq[1-7][1-56],icpnp[1-2][1-56],icpnp3[1-48],gpn[1-6],ncpn[1-40]"
  echo "Ex: $(basename $0) -i icpnq101"
  echo "Ex: $(basename $0) -i icpnp101,icpnq234"
  exit 1
}

OPTSTRING="i:sh"
while getopts ${OPTSTRING} opt; do
    case "$opt" in
        i)
        arg="$OPTARG"
        inventory="$OPTARG"
        ;;
        s)
        echo "Check Drained node"
        pdsh -w ${slurm_controller} "sinfo -R"
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

# Check IB switch status
echo "=====Check IB switch status (State/Rate)====="
pdsh -w ${inventory} "ibstat | grep 'State\|Rate' | awk '{print \$2,\$4}'"
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
pdsh -w ${inventory} "free -g | grep Mem | awk '{print \$2}'"
echo "=====Check CPU status====="
pdsh -w ${inventory} "lscpu | grep -m 1 'CPU(s):' | awk '{print \$2}'"