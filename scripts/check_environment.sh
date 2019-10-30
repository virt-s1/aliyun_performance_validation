#!/bin/bash

# This script run on test and peer host.

# History:
#   v1.0  2017-11-23  charles.shih  init version
#   v2.0  2019-09-04  charles.shih  Refactory
#   v2.1  2019-09-05  charles.shih  Enhance the outputs
#   v2.2  2019-09-06  charles.shih  Bugfix for rps display
#   v2.3  2019-10-30  charles.shih  Add RHEL7 support

nif=eth0

# check netperf
res_np=$(netperf -V 2>/dev/null)
: ${res_np:="Not installed"}

# check iperf3
res_i3=$(iperf3 -v 2>/dev/null | head -n1)
: ${res_i3:="Not installed"}

# check IRQ balance
res_ir=$(systemctl is-active irqbalance)

# check multiple queue
res=$(ethtool -l $nif | grep "^Combined:")
max=$(echo $res | cut -d ' ' -f 2)
cur=$(echo $res | cut -d ' ' -f 4)
res_nq="${cur:-?}/${max:-?}"

# check rps
res_rp=""
for file in $(ls /sys/class/net/$nif/queues/rx-*/rps_cpus); do
    res_rp=${res_rp}:$(cat $file)
done

# Show summary
if [[ "$(uname -r)" =~ "el7" ]]; then
    echo -e "NETPERF | IPERF3 | IRQ_BALANCE | NIC_QUEUE | RPS_STAT"
    echo -e "${res_np} | ${res_i3} | ${res_ir} | ${res_nq} | ${res_rp}"
else
    echo "${res_np};${res_i3};${res_ir};${res_nq};${res_rp}" |
        column -s ";" -t --table-columns NETPERF,IPERF3,IRQ_BALANCE,NIC_QUEUE,RPS_STAT
fi

exit 0
