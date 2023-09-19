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
size=$5
time_based
group_reporting
runtime=30
" > /tmp/test.fio

    targets=$(ls  /dev/vd* | grep -v /dev/vda | awk -F'/' '{print $3}')
    [ -z "$targets" ] && targets=$(lsblk -l | grep nvme | cut -d ' ' -f 1 | grep -v nvme0)
    # The local disk type is nvme and the ESSD type is virtio-blk for ecs.i4 instance family,
    # so cannot use the following command to filter the ESSD devices
    #targets=$(lsblk -l | grep -E 'nvme|vd' | cut -d ' ' -f 1 | grep -vE 'nvme0|vda')
    first_dev=$(echo $targets | awk '{print $1}')
    cpulist=""
    for ((i = 1; i < 15; i++))
    do
        list=$(cat /sys/block/$first_dev/mq/*/cpu_list |
            awk '{if(i<=NF) print $i;}' i="$i" | tr -d ',' | tr '\n' ',')
        if [ -z $list ]; then
            break
        fi
        cpulist=${cpulist}${list}
    done

    let i=0
    numjobs=$1
    for target in $targets
    do
        let start_index=$numjobs*$i+1
        let end_index=$start_index+$numjobs-1
        spincpu=$(echo $cpulist | cut -d ',' -f $start_index-$end_index)
        let i=$i+1

        echo "[tester_$target]
filename=/dev/$target" >> /tmp/test.fio

        : << EOF
        In rhel-7.9 the cpu cores bound to disk request queues are uneven, so need to 
        set "cpus_allowed=1-4" in /tmp/test.fio
        # cat /sys/block/vdb/mq/*/cpu_list
        0, 4, 5, 8, 9, 12, 13, 16, 17...
        1
        2, 6, 7, 10, 11, 14, 15, 18...
        3
EOF
        if [[ "$os" =~ "rhel-7" ]]; then
            echo "cpus_allowed=1-4" >> /tmp/test.fio
        else
            echo "cpus_allowed=$spincpu" >> /tmp/test.fio
        fi
        echo "cpus_allowed_policy=split" >> /tmp/test.fio

        # Refer to https://help.aliyun.com/document_detail/65077.html
        echo 2 >/sys/block/$target/queue/rq_affinity
        sleep 2
    done

    fio --output-format=json+ --output=/tmp/fio.log /tmp/test.fio
}

logdir=$HOME/workspace/log
mkdir -p $logdir
flavor=$(curl http://100.100.100.200/latest/meta-data/instance/instance-type 2>/dev/null)
[ -z "$flavor" ] && flavor=unknown
zone=$(curl http://100.100.100.200/latest/meta-data/zone-id 2>/dev/null)
[ -z "$zone" ] && zone=unknown
os=$(source /etc/os-release && echo ${ID}-${VERSION_ID})
timestamp=$(date +D%y%m%dT%H%M%S)

# Test IOPS (size=100G for regular instance families,but must set size >= 1024G for g7se, IOPS=1000000)
RunFio 4 64 4k randwrite 100G
mv /tmp/fio.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_iops_multiple_disks.log
mv /tmp/test.fio $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_iops_job_file.log

# Test BW (seems size option is not important for BW test)
RunFio 4 64 1m write 100G
mv /tmp/fio.log $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_bw_multiple_disks.log
mv /tmp/test.fio $logdir/fio_${flavor}_${os}_${zone}_${timestamp}_bw_job_file.log

exit 0
