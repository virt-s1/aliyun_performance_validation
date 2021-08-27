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

Issue when attach disk to the instance, change delete_with_instance and perform the playbook again.

> Updating disk d-2zefv1zpnwshgmbmj4mq attribute is failed, error: HTTP Status: 400 Error:NoAttributeToModify No attribute to be modified in this request.

The ali_instance module doesn't support cloud_essd as system disk category. Manually update the following file:
/home/cheshi/.local/lib/python3.8/site-packages/ansible/modules/cloud/alicloud/ali_instance.py

> value of system_disk_category must be one of: cloud_efficiency, cloud_ssd, got: cloud_essd

The ali_disk module doesn't support specifing the performance level.

> PL1 is used in stead of PL3 for 10TiB disks.

Don't know why. Add the following config into ansible.cfg?
`[ssh_connection]\nssh_args="-C -o ControlMaster=auto`

> fatal: [39.106.61.201]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: Connection timed out during banner exchange", "unreachable": true}

footmark latest version (1.20.0) can not work with the latest Python (3.9) #296
https://github.com/alibaba/alibaba.alicloud/issues/296

> error: __init__() got an unexpected keyword argument 'encoding'


# Environment

## Cloud Disk

Disk      TiB  GiB    IOPS     Test
ESSD-PL3  5    5120   257800   250k
ESSD-PL3  6    6144   309000   300k
ESSD-PL3  10   10240  513800   500k
ESSD-PL3  20   20480  1000000  1m


## Test methodology

https://bugzilla.redhat.com/show_bug.cgi?id=1874366#c6
https://www.alibabacloud.com/help/zh/doc-detail/65077.htm?spm=a2c63.p38356

# Commands

```
vi ./ansible_vars.yml

ansible-playbook ./create_vpc.yml
ansible-playbook ./create_instances.yml
ansible-playbook ./create_disk.yml
ansible-playbook ./attach_disk.yml

./update_inventory.sh
ansible-playbook ./run_storage_test.yml
./scripts/summarize.sh -l ./logs
ls -latr ./logs

ansible-playbook ./detach_disk.yml
ansible-playbook ./delete_disk.yml
ansible-playbook ./release_instances.yml && sleep 30
ansible-playbook ./remove_vpc.yml
```

```
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
