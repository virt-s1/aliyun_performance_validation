#!/bin/bash

set -e

yaml_vars=./ansible_vars.yml
inventory=./inventory

# Get facts
tmpfolder=/tmp/ansible_update_inventory
region_id=$(cat $yaml_vars | shyaml -q get-value global.alicloud_region)
instance_name=$(cat $yaml_vars | shyaml -q get-value instance.instance_name)
mkdir -p $tmpfolder
ansible localhost -m ali_instance_info \
    -a "alicloud_region=$region_id name_prefix=$instance_name" \
    --tree $tmpfolder &>$tmpfolder/ali_instance_info.log
x=$(cat $tmpfolder/localhost)

# Compose inventory
tmpfile=$tmpfolder/inventory
: >$tmpfile

# test
echo "[tests]" >>$tmpfile
public_ip=$(echo $x | jq -r ".instances[0].public_ip_address")
private_ip=$(echo $x | jq -r ".instances[0].private_ip_address")
echo "test ansible_host=$public_ip private_ip=$private_ip" >>$tmpfile

# peers
echo "[peers]" >>$tmpfile
for ((i = 1; i < 100; i++)); do
    public_ip=$(echo $x | jq -r ".instances[$i].public_ip_address")
    private_ip=$(echo $x | jq -r ".instances[$i].private_ip_address")
    [ "$public_ip" = "null" ] && break
    echo "peer${i} ansible_host=$public_ip private_ip=$private_ip" >>$tmpfile
done

# Deliver
cp $tmpfile $inventory
