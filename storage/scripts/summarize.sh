#!/bin/bash

# Owner: Charles Shih <schrht@gmail.com>
# Description: Analyse fio json outputs and summarize the report

function analyse() {
    # $1: fio json log
    file=$1
    flavor=$(echo $file | cut -d '-' -f 2)
    [ -z "$flavor" ] && flavor=unknown

    rw=$(cat $file | jq -r '."global options".rw')
    bs=$(cat $file | jq -r '."global options".bs')
    iodepth=$(cat $file | jq -r '."global options".iodepth')
    numjobs=$(cat $file | jq -r '."global options".numjobs')

    iops_r=$(cat $file | jq -r '.jobs[0].read.iops')
    iops_w=$(cat $file | jq -r '.jobs[0].write.iops')
    iops=$(echo "$iops_r + $iops_w" | bc)

    bw_r=$(cat $file | jq -r '.jobs[0].read.bw')
    bw_w=$(cat $file | jq -r '.jobs[0].write.bw')
    bw=$(echo "($bw_r + $bw_w) / 1024" | bc) # KiB/s to MiB/s

    lat_ns_r=$(cat $file | jq -r '.jobs[0].read.lat_ns.mean')
    lat_ns_w=$(cat $file | jq -r '.jobs[0].write.lat_ns.mean')
    lat_ms=$(echo "($lat_ns_r + $lat_ns_w) / 1000000" | bc) # ns to ms

    table="${table}$(printf '%s;%s;%s;%d;%d;%d;%d;%d;%s' \
        $flavor $rw $bs $iodepth $numjobs $iops $bw $lat_ms $file)\n"
}

function print() {
    echo -e $table | column -t -s ';' \
        -N "Flavor,RW,BS,IODepth,Numjobs,IOPS,BW(MiB/s),Lat(ms),Logfile"
}

# Main
if [ -d $1 ]; then
    logdir=$1
else
    logdir=$HOME/workspace/log
fi
cd $logdir || exit 1

if [ ! -z $2 ]; then
    flavor=$2
else
    flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type)
fi
output=$logdir/summary-${flavor:-unknown}.log

for log in $(ls fio-*.log); do
    analyse $log
done

print | tee $output

exit 0
