#!/bin/bash

# This script run on test and peer host to configure NIC multiple queue.
# Ref. https://www.alibabacloud.com/help/zh/doc-detail/52559.htm?spm=a3c0i.l25365zh.b99.21.162d2537upKn5j

# History:
#   v1.0  2019-09-05  charles.shih  init version

nic=eth0

if [ "$1" = "enable" ] || [ "$1" = "disable" ]; then
    action="$1"
else
    echo "Usage: config_mqueue.sh <enable|disable>"
    exit 1
fi

for file in $(ls /sys/class/net/$nic/queues/rx-*/rps_cpus); do
    [ "$action" = "enable" ] && cpuset=$(cat $file | tr "[:xdigit:]" "f") || cpuset=0
    echo $cpuset >$file
done

exit 0
