#!/bin/bash

which aliyun &> /dev/null || {
    curl -s -kL  https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz -o /tmp/aliyun-cli-linux-latest-amd64.tgz
    tar zxf /tmp/aliyun-cli-linux-latest-amd64.tgz
    mv -f aliyun /usr/local/bin
    rm -f /tmp/aliyun-cli-linux-latest-amd64.tgz
}
 
region=$(grep alicloud_region ansible_vars.yml | awk '{print $2}')
endpoint=$(aliyun ecs DescribeRegions | jq -r ".Regions.Region[] | select(.RegionId==\"$region\") | .RegionEndpoint")

zone=$(grep alicloud_zone ansible_vars.yml | awk '{print $2}')
disk_name=$(grep disk_name ansible_vars.yml | awk '{print $2}')
disk_size=$(grep disk_size ansible_vars.yml | awk '{print $2}')
disk_category=$(cat ansible_vars.yml | grep disk_category | grep -v system_disk_category | awk '{print $2}')
disk_count=$(grep disk_count ansible_vars.yml | awk '{print $2}')

for ((i=1; i<=$disk_count; i++))
do
    aliyun --endpoint $endpoint ecs CreateDisk --RegionId $region --ZoneId $zone \
           --DiskName $disk_name-$i --DiskCategory $disk_category \
           --Size $disk_size --PerformanceLevel PL3
done
