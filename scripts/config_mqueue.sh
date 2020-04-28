#!/bin/bash

# This script run on test and peer host to configure NIC multiple queue.
# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

# History:
#   v1.0  2019-09-05  charles.shih  init version
#   v1.1  2019-09-05  charles.shih  configure NIC queue number
#   v1.2  2019-10-30  charles.shih  make this script idempotent
#   v1.3  2020-04-28  charles.shih  calculate cpu sets

nic=eth0

if [ "$1" = "enable" ] || [ "$1" = "disable" ]; then
    action="$1"
else
    echo "Usage: config_mqueue.sh <enable|disable>"
    exit 1
fi

# configure NIC queue num
qmax=$(ethtool -l $nic | grep -m 1 "^Combined:" | awk '{print $2}')
qcur=$(ethtool -l $nic | grep "^Combined:" | tail -n 1 | awk '{print $2}')
[ "$action" = "enable" ] && qnum=$qmax || qnum=$(($qmax / 2))
[ "$qcur" = "$qnum" ] || ethtool -L $nic combined $qnum || exit 1

# configure rps
cnum=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
if [ "$action" = "enable" ]; then
    cset=$(echo "obase=16; ibase=10; 2^${cnum}-1" | bc) || exit 1
else
    cset=0
fi
echo "CPU Number: $cnum; CPU Set: $cset"

for file in $(ls /sys/class/net/$nic/queues/rx-*/rps_cpus); do
    echo $cset >$file || exit 1
done

exit 0
