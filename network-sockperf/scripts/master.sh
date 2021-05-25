#!/bin/bash

# Description: Schedule test and analyse data on server.
# Maintainer: Charles Shih <schrht@gmail.com>

function show_usage() {
    echo "Schedule test and analyse data on server."
    echo "$(basename $0) <-c CLIENTS> [-t TIMEOUT] [-d DUPLICATES]"
    echo "   CLIENTS: The list of clients' IP address."
    echo "   TIMEOUT: The interval of the test (default=30)."
    echo "DUPLICATES: The duplicates of the test (default=1)."
}

while getopts :hc:t:d: ARGS; do
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
    t)
        # timeout option
        timeout=$OPTARG
        ;;
    d)
        # duplicates option
        duplicates=$OPTARG
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
: ${duplicates:=1}

NIC=eth0
BINPATH=~/workspace
LOGPATH=~/workspace/log

# Main
hostip=$(ifconfig $NIC | grep -w inet | awk '{print $2}')
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)
cpu_core=$(cat /proc/cpuinfo | grep process | wc -l)
timestamp=$(date +D%y%m%dT%H%M%S)

echo "hostip=$hostip"
echo "flavor=$flavor"
echo "clients=$clients"
echo "timeout=$timeout"
echo "cpu_core=$cpu_core"
echo "duplicates=$duplicates"
echo "timestamp=$timestamp"

logdir=$LOGPATH/sockperf_${flavor}_${timestamp}
mkdir -p $logdir

for client in $clients; do
    echo "Setup $client..."
    scp $BINPATH/transmit.sh root@$client:/tmp/ || exit 1
done

client_num=0
for client in $clients; do
    client_num=$((client_num + 1))
    echo "Starting test from client $client..."
    log=$logdir/transmit_${flavor}_${client}.log
    ssh root@$client "/tmp/transmit.sh -s $hostip \
        -d $duplicates -t $(($timeout + 40))" &>$log &
done

# Start data collection
sa_pps=$logdir/master_${flavor}_pps.sa
sleep 20 # ramp time
sar -A 1 $timeout -o $sa_pps &>/dev/null
wait # waiting for clients

# Analyse
links=$(($client_num * $cpu_core * $duplicates))
links_detail="$client_num/$cpu_core/$duplicates"
rxpckps=$(sar -n DEV -f $sa_pps | grep "Average.*$NIC" | awk '{print $3}')

# Dump results
logfile=$logdir/sockperf_${flavor}_${timestamp}.txt
printf "%-20s %-4s %-5s %-11s %-8s %-15s\n" \
    Flavor CPU# Links "CLT/CPU/DUP" Duration PPSrx >>$logfile
printf "%-20s %-4s %-5s %-11s %-8s %-15s\n" \
    $flavor $cpu_core $links "$links_detail" $timeout $rxpckps >>$logfile

tarfile=$LOGPATH/sockperf_${flavor}_${timestamp}.tar.gz
cd $logdir && tar -zcvf $tarfile *.sa *.log *.txt
