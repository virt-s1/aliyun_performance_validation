#!/bin/bash

function RunFio()
{
    echo "[global]
ioengine=libaio
numjobs=$1
iodepth=$2
bs=$3
rw=$4
direct=1
time_based
group_reporting
runtime=30
" > /tmp/test.fio

    #count=$(ls  /dev/vd* | grep -v /dev/vda | uniq | wc -l)
    for filename in $(ls  /dev/vd* | grep -v /dev/vda)
    do
        echo "[tester_$filename]
filename=$filename
" >> /tmp/test.fio
    done

    fio --output-format=json+ --output=/tmp/fio.log /tmp/test.fio
}

# Test BW
RunFio 10 64 1m write

logdir=$HOME/workspace/log
mkdir -p $logdir
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)
[ -z "$flavor" ] && flavor=unknown
zone=$(curl http://100.100.100.200/latest/meta-data/zone-id 2>/dev/null)
[ -z "$zone" ] && zone=unknown
os=$(source /etc/os-release && echo ${ID}-${VERSION_ID})
timestamp=$(date +D%y%m%dT%H%M%S)

mv /tmp/fio.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_bw_multiple_disks.log

exit 0
