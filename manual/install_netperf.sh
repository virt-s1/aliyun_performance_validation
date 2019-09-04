#!/bin/bash

# This script is used in VM

# History:
#   v1.0  2017-11-23  charles.shih  init version

type netperf && echo "Already installed." && exit 0

#curl -O https://codeload.github.com/HewlettPackard/netperf/tar.gz/netperf-2.5.0
#mv netperf-2.5.0 netperf-2.5.0.tar.gz
#tar -zxvf netperf-2.5.0.tar.gz
#cd netperf-netperf-2.5.0
#./configure && make && make install && cd ..

cat /etc/redhat-release | grep "release 7" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL7
	curl -O http://www.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/netperf-2.6.0-1.el6.rf.x86_64.rpm
fi

cat /etc/redhat-release | grep "release 6" &>/dev/null
if [ $? -eq 0 ]; then
	# on RHEL6
	curl -O http://www.rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/netperf-2.6.0-1.el6.rf.x86_64.rpm
fi

rpm -ivh netperf-*.rpm

netperf -V
netserver -V

exit 0

