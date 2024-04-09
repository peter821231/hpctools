#!/bin/bash

# parse command line arguments
OPTSTRING="ai:h"
while getopts ${OPTSTRING} opt; do
  case "$opt" in
    i)
      arg="$OPTARG"
      inventory="$OPTARG"
      #Check inventory name
      #regex="^icpnq([1-7][0-4][0-9]|[1-7]5[0-6])|icpnp([1-2][0-4][0-9]|[1-2]5[0-6])|icpnp3([0-3][0-9]|4[0-8])|gpn0[1-6]|ncpn(0[1-9]|[1-3][0-9]|40)$"
      #[[ "$OPTARG" =~ $regex ]] && echo "matched" || echo "did not match"
      ;;
    a)
      inventory="icpnq[1-7][1-56],icpnp[1-2][1-56],icpnp3[1-48],gpn[1-6],ncpn[1-40]"
      ;;
    ?|h)
      echo "Usage: $(basename $0) [-i inventory]"
      echo "Available iventory:"
      echo "icpnq[1-7][1-56],icpnp[1-2][1-56],icpnp3[1-48],gpn[1-6],ncpn[1-40]"
      echo "Ex: $(basename $0) -i icpnq101"
      echo "Ex: $(basename $0) -i icpnp101,icpnq234"
      echo Usage: $(basename $0) -a
      echo "Check all inventory(not recommended)"
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

exit

# Check IB switch status
pdsh -w ${inventory} "ibstat | grep 'State\|Rate'"
# Check GPFS directory status
pdsh -w ${inventory} "df -h | grep 'home1\|project\|work1\|mgmt\|pkg'"
# Check slurmd and ldap status
pdsh -w ${inventory} "systemctl status slurmd | grep 'Active:'"
pdsh -w ${inventory} "systemctl status sssd | grep 'Active:'"
# Check CPU and memory status
pdsh -w ${inventory} "free -g | grep Mem | awk '{print \$2}'"
pdsh -w ${inventory} "lscpu | grep -m 1 'CPU(s):' | awk '{print \$2}'"