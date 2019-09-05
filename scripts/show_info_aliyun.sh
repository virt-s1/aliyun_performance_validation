#!/bin/bash

# This script runs on test host to show some general infomation.

# History:
#   v1.0  2017-11-23  charles.shih  init version

function show() {
	# $1: Title;
	# $@: Command;

	if [ "$1" = "" ]; then
		echo -e "\n\$$@"
	else
		echo -e "\n* $1"
	fi
	echo -e "---------------"
	shift
	$@ 2>&1
}

show "Time" date
show "Release" cat /etc/system-release

show "" uname -a
show "" cat /proc/cmdline
show "" systemd-analyze

show "" free -m
show "" lscpu

show "" lsblk -p
show "" ip addr
show "Metadata" ./metadata.sh

# Additional

show "" ethtool -l eth0
show "" systemctl status irqbalance
show "" tail /sys/class/net/eth0/queues/rx-*/{rps_cpus,rps_flow_cnt}

exit 0
