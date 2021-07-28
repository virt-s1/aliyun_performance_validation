# aliyun_performance_validation

Performance Validation on Alibaba Cloud with Ansible

# Usage

## Create environment
export ALICLOUD_ACCESS_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_id')"
export ALICLOUD_SECRET_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_secret')"

vi ./ansible_vars.yml

ansible-playbook ./create_vpc.yml
ansible-playbook ./create_instances.yml && sleep 300

./update_inventory.sh

## Ping all the hosts
ansible all -m ping -o

## Install test tools
ansible-playbook ./install_netperf.yml

## Optimization before testing
ansible-playbook ./performance_optimize.yml

## Check the status of the hosts
ansible all -m script -a "./scripts/check_environment.sh"

## Copy the private key to test host (for test script to run)
ansible test -m copy -a "src='~/.pem/cheshi-docker.pem' dest='/root/sshkey.pem' mode=400"

## Get a list of peer-ips
unset ipaddrs
ipaddrs=$(ansible peers -m shell -a "ifconfig eth0 | grep inet | awk '{print \$2}'" | grep 172 | xargs echo)
echo $ipaddrs

## Run the test scripts
ansible test -m script -a "./scripts/netperf_test.sh <peer-ip list>"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs $ipaddrs"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs $ipaddrs $ipaddrs $ipaddrs"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs"
ansible test -m script -a "./scripts/netperf_test.sh $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs $ipaddrs"

## Check the log
ansible test -m command -a 'ls netperf_test_*.log'

## Destroy environment
ansible-playbook ./release_instances.yml && sleep 30
ansible-playbook ./remove_vpc.yml
