#!/bin/bash
# List of hosts
hostname=(nlgn01 nlgn02 nlgn03 nlgn04 \
       ncpn01 ncpn02 ncpn03 ncpn04 ncpn05 ncpn06 ncpn07 ncpn08 ncpn09 ncpn10 \
       ncpn11 ncpn12 ncpn13 ncpn14 ncpn15 ncpn16 ncpn17 ncpn18 ncpn19 ncpn20 \
       ncpn21 ncpn22 ncpn23 ncpn24 ncpn25 ncpn26 ncpn27 ncpn28 ncpn29 ncpn30 \
       ncpn31 ncpn32 ncpn33 ncpn34 ncpn35 ncpn36 ncpn37 ncpn38 ncpn39 ncpn40)
rate=200
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

# Check ethernet status
echo "Checking ethernet status"
echo "If rate is less than ${rate}, it will be marked as FAILED"
echo "Usage: $(basename $0) -v will enable verbose output"

for host in ${hostname[@]}; do
  # Get ethernet status
  status=$(ssh -o ConnectTimeout=5 "${host}" "ibstat | grep -A 20 'mlx5_1\\|mlx5_3' | awk '/Physical state|Rate:|Link layer:/{gsub(/^[ \\t]+/, \"\"); print}'" 2>/dev/null)
  if [[ -z "${status}" ]]; then
    rate_now=0
    status="OFFLINE"
  else
    rate_now=$(echo $status | awk '{print $5}')
  fi
  # Check if verbose output is enabled
  if [[ $VERBOSE == "true" ]]; then
    echo "####${host} status####"
    echo "${status}"
    echo ""
  else
    # Check if rate is less than expected
    if (( $(echo "$rate_now == 0" | bc -l) )); then
      rate_status="OFFLINE"
    elif (( $(echo "$rate_now < $rate" | bc -l) )); then
      rate_status="DEGRADED"
    else
      rate_status="SUCCESS"
    fi
    echo "${host}: ${rate_status}"
  fi
done
