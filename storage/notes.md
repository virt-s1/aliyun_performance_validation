# Ansible setup

https://docs.ansible.com/ansible/latest/scenario_guides/guide_alicloud.html

## Install modules
pip install ansible-alicloud
pip install footmark

> ERROR! couldn't resolve module/action 'ali_vpc'.

## Load credentials
export ALICLOUD_ACCESS_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_id')"
export ALICLOUD_SECRET_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_secret')"

> Failed to describe VPCs: 'VPCConnection' object has no attribute 'FootmarkClientError'

# Workaround

# Issue 1

While attaching disk to the instance, it shows:

```
[root@bc06a760dffc storage]# ansible-playbook ./attach_disk.yml
......
TASK [Attach disk to instance] ***************************************************************************************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"changed": false, "msg": "Updating disk d-2ze1dhkt8qrgdmlvufgp attribute is failed, error: HTTP Status: 400 Error:NoAttributeToModify No attribute to be modified in this request. RequestID: A69DBE3D-5F57-5FBE-8F7D-A1E2A2D4C80D"}
```

**Root cause**  
Ansible Alibaba module issue.

**Solution**  
Modify the value of `delete_with_instance` in `ansible_vars.yml` and perform this playbook again.

**Notes**  
Some times it fails due to instance doesn't get ready for it. So wait for minutes after creating the new instance.

# Issue 2

While creating cloud disks, it shows:

`value of system_disk_category must be one of: cloud_efficiency, cloud_ssd, got: cloud_essd`

**Root cause**  
The ali_instance module doesn't support cloud_essd as system disk category.

**Solution**  
Manually update the `ali_instance.py` file:

```
[root@bc06a760dffc storage]# ansible-doc -F | grep ali_instance.py
ali_instance                 /usr/local/lib/python3.8/site-packages/ansible/modules/cloud/alicloud/ali_instance.py

[root@bc06a760dffc storage]# sed -i "s/'cloud_ssd']/'cloud_ssd', 'cloud_essd']/" /usr/local/lib/python3.8/site-packages/ansible/modules/cloud/alicloud/ali_instance.py
```

# Issue 3

The cloud disk performance is much lower than declaration.

**Root cause**  
The ali_disk module doesn't support specifing the performance level.

**Solution**  
Manually change the disk performance level to PL3:  
1. Go to https://ecs.console.aliyun.com/
2. Access "Elastic Compute" > "Service" > "Disks".
3. Find the cloud disk and click "Modify Performance Level"
4. Select "PL3" and confirm.


# Issue 4

Failed to connect the instances, it shows:

```
fatal: [39.106.61.201]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Connection timed out during banner exchange", "unreachable": true}
```

**Root cause**  
I don't know exactly, but it maybe due to the Ansible.

**Solution**  
Add the following configure into `ansible.cfg` may helps:

```
[ssh_connection]
ssh_args="-C -o ControlMaster=auto"
```

# Issue 5

Failed to run most of the playbooks, it shows:
```
error: __init__() got an unexpected keyword argument 'encoding'
```

**Root cause**  
footmark latest version (1.20.0) can not work with the latest Python (3.9) #296
https://github.com/alibaba/alibaba.alicloud/issues/296

**Solution**  
Use matched versions. As a solution, using containerized environment directly. Refer to `../README.md`.


# Environment

## Cloud Disk

Disk      TiB  GiB    IOPS     Test
ESSD-PL3  5    5120   257800   250k
ESSD-PL3  6    6144   309000   300k
ESSD-PL3  10   10240  513800   500k
ESSD-PL3  20   20480  1000000  1m

instance_type: ecs.c6e.26xlarge (480,000/2048) | highest performance certified
instance_type: ecs.g7.32xlarge (600,000/4096) | highest performance to certify (bz1987375)


## Test methodology

https://bugzilla.redhat.com/show_bug.cgi?id=1874366#c6
https://www.alibabacloud.com/help/zh/doc-detail/65077.htm?spm=a2c63.p38356

# Commands

Single test steps:

```bash
vi ./ansible_vars.yml

ansible-playbook ./create_vpc.yml
ansible-playbook ./create_instances.yml
ansible-playbook ./create_disk.yml
ansible-playbook ./attach_disk.yml (optional)

# Don't forget to change the disk performance level to PL3 manually for some high performance instances families

./update_inventory.sh
ansible-playbook ./run_storage_test.yml
./scripts/summarize.sh -l ./logs
ls -latr ./logs

ansible-playbook ./detach_disk.yml (optional)
ansible-playbook ./delete_disk.yml (optional)
ansible-playbook ./release_instances.yml && sleep 30
ansible-playbook ./remove_vpc.yml
```

Bandwidth test steps with multiple disks:

```bash
# Specify the disk_size and disk_count
vi ./ansible_vars.yml

ansible-playbook ./create_vpc.yml
ansible-playbook ./create_instances.yml
ansible-playbook ./create_disk.yml

# Don't forget to change the disk performance level to PL3 manually for some high performance instances families

./update_inventory.sh
ansible-playbook ./run_bw_storage_test.yml
./scripts/summarize.sh -l ./logs

ansible-playbook ./release_instances.yml
ansible-playbook ./remove_vpc.yml
```

Muliple instance types validation steps:

```bash
# prepare
ansible-playbook ./create_vpc.yml
ansible-playbook ./create_disk.yml

# create
ansible-playbook ./create_instances.yml
sleep 600
ansible-playbook ./attach_disk.yml

# test
./update_inventory.sh
ansible-playbook ./run_storage_test.yml
./scripts/summarize.sh -l ./logs

# destroy
ansible-playbook ./detach_disk.yml
ansible-playbook ./release_instances.yml

# teardown
ansible-playbook ./delete_disk.yml
sleep 20
ansible-playbook ./remove_vpc.yml
```
