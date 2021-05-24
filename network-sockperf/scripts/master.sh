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

# Main
rm -f /tmp/sockperf.log.*
mkdir -p /root/workspace/log

hostip=$(ifconfig $NIC | grep -w inet | awk '{print $2}')
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)

echo "hostip=$hostip"
echo "flavor=$flavor"
echo "clients=$clients"
echo "timeout=$timeout"
echo "duplicates=$duplicates"

for client in $clients; do
    echo "Starting test from client $client..."
    log=/root/workspace/log/transmit_${flavor}_${client}.log
    ssh root@$client "/root/workspace/transmit.sh -s $hostip \
        -d $duplicates -t $(($timeout + 40)) &>$log" &
done

# Start data collecting
datafile=/root/workspace/log/master_${flavor}.sa
sleep 20 # ramp time
sar -A 1 $timeout -o $datafile &>/dev/null
wait # waiting for clients

# Analyse
logfile=/root/workspace/log/master_${flavor}.log
sar -n DEV -f $datafile | tee $logfile
