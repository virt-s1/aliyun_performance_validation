#!/bin/bash

# This script run on testing host to configure the NIC queues.
# Ref. https://www.alibabacloud.com/help/faq-detail/55757.htm?spm=a2c63.p38356.879954.235.1b212d44tzuIVV
# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

# History:
#   v1.0  2019-09-05  charles.shih  init version
#   v1.1  2019-09-05  charles.shih  configure NIC queue number
#   v1.2  2019-10-30  charles.shih  make this script idempotent
#   v1.3  2020-04-28  charles.shih  calculate cpu sets
#   v1.4  2020-04-29  charles.shih  Refactory this script
#   v1.5  2020-04-29  charles.shih  Bugfix for the cpuset calculation

set -e

# Parse the parameters
nic=eth0

if [ "$1" = "optimized" ] || [ "$1" = "restore" ]; then
    action="$1"
else
    echo "Usage: config_nic_queues.sh <optimized|restore>"
    exit 1
fi

# Get the maxium and current NIC queue number
qmax=$(ethtool -l $nic | grep "^Combined:" | head -n 1 | awk '{print $2}')
qcur=$(ethtool -l $nic | grep "^Combined:" | tail -n 1 | awk '{print $2}')

if [ "$action" = "optimized" ]; then
    qnum=$qmax
else
    qnum=$(($qmax / 2))
fi

# Configure the NIC queue number
echo "Set the NIC queue number to $qnum (max:$qmax)."
[ "$qcur" != "$qnum" ] && ethtool -L $nic combined $qnum

# Calculate the cpuset for rps
cnum=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
if [ "$action" = "optimized" ]; then
    #cset=$(echo "obase=16; ibase=10; 2^${cnum}-1" | bc)
    cset=$(cat /sys/class/net/$nic/queues/rx-0/rps_cpus | tr "[:xdigit:]" "f")
    case $(($cnum % 4)) in
    3) cset=${cset/f/7} ;;
    2) cset=${cset/f/3} ;;
    1) cset=${cset/f/1} ;;
    esac
else
    cset=0
fi

# Set the cpuset for rps
echo "Set cpuset for rps to '$cset'."
for file in $(ls /sys/class/net/$nic/queues/rx-*/rps_cpus); do
    echo $cset >$file
done

exit 0
