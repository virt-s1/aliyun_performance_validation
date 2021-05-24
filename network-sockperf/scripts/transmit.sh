#!/bin/bash

# Description: Run sockperf test.
# Maintainer: Charles Shih <schrht@gmail.com>

function show_usage() {
    echo "Run sockperf test."
    echo "$(basename $0) <-s SERVERIP> [-p BASEPORT] [-t TIMEOUT]"
    echo "SERVERIP: The server's IP address."
    echo "BASEPORT: The ports start from (default=6000)."
    echo " TIMEOUT: The interval of the test (default=30)."
}

while getopts :hs:p:t: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    s)
        # serverip option
        serverip=$OPTARG
        ;;
    p)
        # baseport option
        baseport=$OPTARG
        ;;
    t)
        # timeout option
        timeout=$OPTARG
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

if [ -z $serverip ]; then
    show_usage
    exit 1
fi

: ${baseport:=6000}
: ${timeout:=30}

# Main
killall -q sockperf
rm -f /tmp/sockperf.log.*

cpu_core=$(cat /proc/cpuinfo | grep process | wc -l)

echo "cpu_core=$cpu_core"
echo "serverip=$serverip"
echo "baseport=$baseport"
echo "timeout=$timeout"

for ((i = 0; i < $cpu_core; i++)); do
    port=$(($baseport + $i))
    echo "Starting test on port $port..."
    sockperf tp -i $serverip --client_port $port --pps max -m 14 \
        -t $timeout --port $port &>/tmp/sockperf.log.$i &
done

wait

grep ^ /tmp/sockperf.log.*