#!/bin/bash

# This script run on test and peer host to configure NIC multiple queue.
# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

# History:
#   v1.0  2019-09-05  charles.shih  init version
#   v1.1  2019-09-05  charles.shih  configure NIC queue number

nic=eth0

if [ "$1" = "enable" ] || [ "$1" = "disable" ]; then
    action="$1"
else
    echo "Usage: config_mqueue.sh <enable|disable>"
    exit 1
fi

# configure NIC queue num
qmax=$(ethtool -l $nic | grep -m 1 "^Combined:" | awk '{print $2}')
[ "$action" = "enable" ] && qnum=$qmax || qnum=$(($qmax / 2))
ethtool -L $nic combined $qnum || exit 1

# configure rps
for file in $(ls /sys/class/net/$nic/queues/rx-*/rps_cpus); do
    [ "$action" = "enable" ] && cpuset=$(cat $file | tr "[:xdigit:]" "f") || cpuset=0
    echo $cpuset >$file || exit 1
done

exit 0
