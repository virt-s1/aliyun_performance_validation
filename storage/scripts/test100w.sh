#!/bin/bash

# Owner: Charles Shih <schrht@gmail.com>
# Description: Perform fio tests and collect the storage performance numbers
#
# Ref. https://www.alibabacloud.com/help/zh/doc-detail/65077.htm?spm=a2c63.p38356

function RunFio() {
    numjobs=$1  # 实例中的测试线程数，例如示例中的10
    iodepth=$2  # 同时发出I/O数的上限，例如示例中的64
    bs=$3       # 单次I/O的块文件大小，例如示例中的4k
    rw=$4       # 测试时的读写策略，例如示例中的randwrite
    filename=$5 # 指定测试文件的名称，例如示例中的/dev/vdb
    nr_cpus=$(cat /proc/cpuinfo | grep "processor" | wc -l)
    devname=${filename##*/}
    if [ $nr_cpus -lt $numjobs ]; then
        echo "Numjobs is more than cpu cores, exit!"
        return 1
    fi
    let nu=$numjobs+1
    cpulist=""
    for ((i = 1; i < 10; i++)); do
        list=$(cat /sys/block/$devname/mq/*/cpu_list |
            awk '{if(i<=NF) print $i;}' i="$i" | tr -d ',' | tr '\n' ',')
        if [ -z $list ]; then
            break
        fi
        cpulist=${cpulist}${list}
    done
    spincpu=$(echo $cpulist | cut -d ',' -f 2-${nu})
    # echo "cpus_allowed=$spincpu"

    # Add "--size=1024g" for a workaround mentioned in BZ1953904#c9
    date >> /tmp/test100w.log
    echo "command: fio --ioengine=libaio --runtime=30s --numjobs=${numjobs} \
        --iodepth=${iodepth} --bs=${bs} --rw=${rw} --filename=${filename} \
        --time_based=1 --direct=1 --name=test --group_reporting \
        --cpus_allowed=$spincpu --cpus_allowed_policy=split \
        --ramp_time=5 --output-format=json+ --output=/tmp/fio.log \
        --size=1024g" >> /tmp/test100w.log
    fio --ioengine=libaio --runtime=30s --numjobs=${numjobs} \
        --iodepth=${iodepth} --bs=${bs} --rw=${rw} --filename=${filename} \
        --time_based=1 --direct=1 --name=test --group_reporting \
        --cpus_allowed=$spincpu --cpus_allowed_policy=split \
        --ramp_time=5 --output-format=json+ --output=/tmp/fio.log \
        --size=1024g
}

# Main
target=$(ls /dev/vd* | tail -n 1)
logdir=$HOME/workspace/log
mkdir -p $logdir
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)
[ -z "$flavor" ] && flavor=unknown
zone=$(curl http://100.100.100.200/latest/meta-data/zone-id 2>/dev/null)
[ -z "$zone" ] && zone=unknown
os=$(source /etc/os-release && echo ${ID}-${VERSION_ID})
timestamp=$(date +D%y%m%dT%H%M%S)
devname=${target##*/}

# Check
if [ ! -b $target ]; then
    echo "Disk $target is not ready."
    exit 1
fi

# Tuning
echo 2 >/sys/block/$devname/queue/rq_affinity
sleep 5

# Test IOPS
RunFio 10 64 4k randwrite $target
mv /tmp/fio.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_iops.log
mv /tmp/test100w.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_iops_test100w.log

# Test BW
RunFio 10 64 1m write $target
mv /tmp/fio.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_bw.log
mv /tmp/test100w.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_bw_test100w.log

exit 0
