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

function show_usage() {
    echo "Analyse fio json outputs and summarize the report."
    echo "$(basename $0) [-l LOGDIR] [-f FILENAME]"
    echo "-l: The directory with fio json output files."
    echo "    Will use '~/workspace/log/' than '.' if not specified."
    echo "-f: The filename of the report. Will use STDOUT if not specified."
}

while getopts :hl:f: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    l)
        # Logdir option
        logdir=$OPTARG
        ;;
    f)
        # Filename option
        filename=$OPTARG
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

if [ -z $logdir ]; then
    [ -d $HOME/workspace/log ] && logdir=$HOME/workspace/log || logdir=$PWD
fi

# Main
cd $logdir || exit 1
for log in $(ls fio-*.log); do
    analyse $log
done

[ -z $filename ] && print || print >$filename

exit 0
