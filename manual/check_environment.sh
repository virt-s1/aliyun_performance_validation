#!/bin/bash

# This script run on test and peer host.

# History:
#   v1.0  2017-11-23  charles.shih  init version

# check netperf
type netperf &>/dev/null
if [ $? -eq 0 ]; then
    res_np="PASS"
else
    res_np="FAIL"
fi

# check iperf3
type iperf3 &>/dev/null
if [ $? -eq 0 ]; then
    res_i3="PASS"
else
    res_i3="FAIL"
fi

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
echo "Netperf:$res_np Iperf3:$res_i3 NIC_Queue:$res_nq IRQ_Bal:$res_ir RPS:$res_rp"

exit 0
