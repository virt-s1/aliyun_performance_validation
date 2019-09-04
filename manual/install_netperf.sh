#!/bin/bash

# This script is used in VM to install netperf for RHEL system.

# History:
#   v1.0  2017-11-23  charles.shih  init version
#   v2.0  2019-09-04  charles.shih  Support RHEL8

type netperf && echo "Already installed." && exit 0

cd $(mktemp -d)

grep -q "release 8" /etc/redhat-release
if [ $? -eq 0 ]; then
	# on RHEL8
	dnf install -y wget make gcc
	wget https://github.com/HewlettPackard/netperf/archive/netperf-2.7.0.tar.gz
	tar -xf netperf-2.7.0.tar.gz
	cd netperf-netperf-2.7.0/
	make clean && ./configure && make && make install
fi

cat /etc/redhat-release | grep "release 7" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL7
	curl -O http://www.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/netperf-2.6.0-1.el6.rf.x86_64.rpm
	rpm -ivh netperf-*.rpm
fi

cat /etc/redhat-release | grep "release 6" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL6
	curl -O http://www.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/netperf-2.6.0-1.el6.rf.x86_64.rpm
	rpm -ivh netperf-*.rpm
fi

netperf -V
netserver -V

exit 0

