# Ansible setup

https://docs.ansible.com/ansible/latest/scenario_guides/guide_alicloud.html

> Notice: Using containerized environment is highly recommended!!! See ../README.md !!!

## Install modules
pip install ansible-alicloud
pip install footmark

> ERROR! couldn't resolve module/action 'ali_vpc'.

## Load credentials
export ALICLOUD_ACCESS_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_id')"
export ALICLOUD_SECRET_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_secret')"

> Failed to describe VPCs: 'VPCConnection' object has no attribute 'FootmarkClientError'

# Workaround

## Issue 1

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

## Issue 2

While deploying keypairs, it shows:
```
[root@1a894173add1 network-sockperf]# ansible-playbook ./deploy_keypairs.yml
......
ERROR! couldn't resolve module/action 'openssh_keypair'. This often indicates a misspelling, missing collection, or incorrect module path.
```

**Root cause**
Checking with `ansible-doc -F | grep openssh_keypairi` to know `crytop` was not installed.

**Solution**
Install `community.crypto` by command `ansible-galaxy collection install community.crypto`.


# Environment

## Involve Alibaba

ansible all -m lineinfile -a "path=~/.ssh/authorized_keys line='ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAHUW13f7VltyJXFPjV01jpqzVFC3ZqbiFrVlO/AXnmC6Zpg/kUHxndsOjgz9GlFUOpn56mC5yine7ygMxhlGBZNgADr5uQvV90N2Qg8JAClcSXGmWZnMFwikeHEETwL1gqZ5bnOMnyPJDGpA50iyYUG2cYGxq4Km3/1Xn1HBdTSBvc0Zg== root@iZuf63e3cxev6d4sajq1w1Z' create=yes"

ansible all -m lineinfile -a "path=~/.ssh/authorized_keys line='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9/cPjik/kwG59Xm3Ki2yvCkizcv4ZN0+Myo/fimnmD0lIxW19bmpFQiwjjCndsjAI2wnA5UzUNj4bLktxwk8lyCEnWX7JTb3xrL/JJ7DCi25I44xr1NdYhLPGerdye2lTZhOxiqS6emcJicO31rkoMAy0WoVAcixhp8+dBEVrpUDQIKwXQJTDoez7O+prhU3Aj+Skeq1KPcU3JPrVcqcC/rr9lGMrXTt81dOLIw953UOcHhXV+rhXtEej8n610QkY+Yy3bc31hIV26qdU0RgkvJOHxtXd1b00wVdA7NLxiykfAOZLCYHWY4NAFc+qKEBdiOXwF0SmDPCfcPapUCuaQhtyfsB5/PmejhJmG+sywcFeZmpMl6/+UzVQwt6GcgdybOBmuRy3kyoFVvtwTd3ZssfPnp6F6ysA5HiDwMntkxoEjpg8sKoqnitP7lTP3RWIOp7gtyDM0MaqKV9byOuJo1aVaGUNqYRbeinNKuerSuhDD/73FZEI8+eYO1+HP1s= born@B-WCX0MD6M-2237.local' create=yes"

ansible all -m lineinfile -a "path=~/.ssh/authorized_keys line='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxsEVChyav4s09iXAy2U0359icPBmVkmU6P4mzzYYnwRhlMuNoFDvNRuAdmJIEkhACcnx3KgOs8rF3JAASm8lZrOiQGHZIrhAm8JiIIA1F5yJal66DXI5j6LGFU8PWoBF8y9CmSM3KL+/GyAVlKQgox9KOPEoNLtJlVuhtut7haenZZRGABkHunonvXUUCiFCWzb5YVd2vl5HK3sGhRU2XGZQq7j3fonQ1RTu9ypU7Abm6+/WXi6CK7iSu+Jt2iZF1HuUcI3an4imEXg7x7RN3gFX/ZmmAukbq61yHrnKmtFGSic/I5nB6V61PMsDngswRBqYWSRUEG/+2y3CHsmGf zhixiong@zhixiongdeMacBook-Pro.local' create=yes"

# Test methodology

ecs.hfc7.24xlarge (32/12m) highest performance certified

## Commands

```
vi ./ansible_vars.yml

ansible-playbook ./create_vpc.yml
ansible-playbook ./create_instances.yml && sleep 180

./update_inventory.sh
ansible all -m ping -o
ansible-playbook ./deploy_keypairs.yml
ansible-playbook ./install_sockperf.yml
ansible-playbook ./performance_tuning.yml

ansible-playbook ./run_sockperf_test.yml
./scripts/summarize.sh -l ./logs

ansible-playbook ./release_instances.yml && sleep 30
ansible-playbook ./remove_vpc.yml
```

### Debugging

```
./master.sh -m pps -t 10 -c "192.168.8.134" -d 4 | tee -a results.txt
./master.sh -m pps -t 10 -c "192.168.8.135" -d 4 | tee -a results.txt
./master.sh -m pps -t 10 -c "192.168.8.136" -d 4 | tee -a results.txt
./master.sh -m pps -t 10 -c "192.168.8.137" -d 4 | tee -a results.txt
./master.sh -m pps -t 10 -c "192.168.8.138" -d 4 | tee -a results.txt
cat results.txt | grep -w PPS
```
