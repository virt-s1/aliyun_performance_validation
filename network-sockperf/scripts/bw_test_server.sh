#!/bin/bash

# Description: Schedule bandwidth test and analyse data on server.
# Ref. https://help.aliyun.com/document_detail/419630.htm?spm=a2c4g.11186623.0.0.43cb5aa3H7WJYC#section-kpj-k1e-x5g

function show_usage() {
    echo "Schedule bandwidth test and analyse data on server."
    echo "$(basename $0) <-c CLIENTS> <-z ZONE>"
    echo "   CLIENTS: The list of clients' IP address."
    echo "     ZONE:  The zone of the test"
}

while getopts :hc:z: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    c)
        # clients option
        clients=$OPTARG
        ;;
    z)
        # zone option
        zone=$OPTARG
        ;;
    "?")
        echo "$(basename $0): unknown option: $OPTARG" >&2
        ;;
    ":")
        echo "$(basename $0): option requires an argument -- '$OPTARG'" >&2
        echo "Try '$(basename $0) -h' for more information." >&2
        exit 1
        ;;
    *)
        # Unexpected errors
        echo "$(basename $0): unexpected error -- $ARGS" >&2
        echo "Try '$(basename $0) -h' for more information." >&2
        exit 1
        ;;
    esac
done

if [ -z "$clients" ]; then
    show_usage
    exit 1
fi

: ${timeout:=30}

NIC=eth0
BINPATH=~/workspace
LOGPATH=~/workspace/log
BASEPORT=16000

# Main
hostip=$(ifconfig $NIC | grep -w inet | awk '{print $2}')
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)
os=$(source /etc/os-release && echo ${ID}-${VERSION_ID})
timestamp=$(date +D%y%m%dT%H%M%S)

echo "hostip=$hostip"
echo "flavor=$flavor"
echo "clients=$clients"
echo "baseport=$BASEPORT"
echo "timeout=$timeout"
echo "os=$os"
echo "timestamp=$timestamp"

logdir=$LOGPATH/netperf_${flavor}_${os}_${timestamp}
mkdir -p $logdir

for client in $clients; do
    echo "Setup $client..."
    scp $BINPATH/bw_test_client.sh root@$client:/tmp/ || exit 1
done

# Start netperf server
killall -q netserver 
for j in `seq 32`; do
    netserver -p $[$BASEPORT+j] &
done

# Schedule netperf server to stop
sleep $(($timeout + 50)) && killall -q netserver &


# Trigger workload
client_num=0
for client in $clients; do
    client_num=$((client_num + 1))
    echo "Starting test from client $client..."
    log=$logdir/bw_test_client_${flavor}_${os}_${client}.log
    ssh root@$client "/tmp/bw_test_client.sh -s $hostip \
        -p $BASEPORT -t $(($timeout + 40))" &>$log &
done

# Collect data
safile=$logdir/bw_test_server_${flavor}_${os}_${timestamp}.sa
sleep 20 # ramp time
sar -A 1 $timeout -o $safile &>/dev/null
wait # waiting for clients

# Analyse data
rxpckps=$(sar -n DEV -f $safile | grep "Average.*$NIC" | awk '{print $3}')
rxkpps=$(echo "scale=2; ${rxpckps:-0} / 1000" | bc)
rxkBps=$(sar -n DEV -f $safile | grep "Average.*$NIC" | awk '{print $5}')
rxGbps=$(echo "scale=2; ${rxkBps:-0} * 8 / 1000000" | bc)

# Dump results
logfile=$logdir/netperf_${flavor}_${os}_${timestamp}.txt
echo "
Flavor  OS  Mode          CLT         CPU       DUP     Links    Duration PPSrx(k)  BWrx(Gb/s) Zone
$flavor $os BW            $client_num n/a       n/a     n/a      $timeout ${rxkpps} ${rxGbps}  ${zone}
" | column -t >$logfile

tarfile=$LOGPATH/netperf_${flavor}_${os}_${timestamp}.tar.gz
cd $logdir && tar -zcvf $tarfile *.sa *.log *.txt

echo "---"
cat $logfile
