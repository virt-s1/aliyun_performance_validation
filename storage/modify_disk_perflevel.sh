#!/bin/bash

# Set performance level to PL3 by default
perf_level=PL3

which aliyun > /dev/null || {
    echo "ERROR: Please make sure aliyun CLI exists in your env!"
    exit 1
}
 
region=$(grep alicloud_region ansible_vars.yml | awk '{print $2}')
endpoint=$(aliyun ecs DescribeRegions | jq -r ".Regions.Region[] | select(.RegionId==\"$region\") | .RegionEndpoint")

disk_name=$(grep disk_name ansible_vars.yml | awk '{print $2}')
disk_ids=$(aliyun --endpoint $endpoint ecs DescribeDisks --RegionId $region --PageSize 100 | jq -r ".Disks.Disk[] | select(.DiskName | contains(\"$disk_name\")) | .DiskId")

for id in $disk_ids
do
    echo "Disk Id: $id"
    aliyun --endpoint $endpoint ecs ModifyDiskSpec --DiskId $id --PerformanceLevel $perf_level
done
