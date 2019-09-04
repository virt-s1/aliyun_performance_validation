#!/bin/bash

# This script run on test and peer host.

# History:
#   v1.0  2017-11-23  charles.shih  init version
#   v2.0  2019-09-04  charles.shih  Refactory

# check netperf
res_np=$(netperf -V 2>/dev/null)
: ${res_np:="Not installed"}

# check iperf3
res_i3=$(iperf3 -v | head -n1 2>/dev/null)
: ${res_i3:="Not installed"}

# check multiple queue
if [ "$(ethtool -l eth0 | grep "^Combined:" | sort -u | wc -l)" = "1" ]; then
    res_nq="PASS"
else
    res_nq="FAIL"
fi

# check IRQ balance
systemctl status irqbalance | grep "active (running)" &>/dev/null
if [ $? -eq 0 ]; then
    res_ir="PASS"
else
    res_ir="FAIL"
fi

# check rps
if [ "$(grep f /sys/class/net/eth0/queues/rx-*/rps_cpus | wc -l)" != "0" ]; then
    res_rp="PASS"
else
    res_rp="FAIL"
fi

# Show summary
echo "${res_np},${res_i3},${res_nq},${res_ir},${res_rp}" \
| column -s "," -t --table-columns NETPERF,IPERF3,NIC_QUEUE,IRQ_BALANCE,RPS


exit 0
