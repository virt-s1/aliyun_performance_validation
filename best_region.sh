#!/bin/bash
#
# Description:
#   Find best region to go based on instace types in full.txt and pass.txt
#

PATH=$PATH:.

[ "$1" = "-f" ] && flavor=$2
[ "$1" = "-z" ] && zone=$2

[ -f ./pass.txt ] && grep -v -f ./pass.txt ./full.txt >/tmp/todo.txt || cat ./full.txt >/tmp/todo.txt

resource_matrix=/tmp/aliyun_flavor_distribution.txt
if [ -f $resource_matrix ]; then
	echo "Notice: '$resource_matrix' was updated at $(stat -c %z $resource_matrix)." >&2
	echo "Notice: You might consider running 'query_flavors.sh' again to get the latest status." >&2
else
	query_flavors.sh >&2 || exit 1
fi
echo "======" >&2

# get matrix
grep -f /tmp/todo.txt $resource_matrix >/tmp/matrix.txt

# show status
if [ ! -z $flavor ]; then
	# show flavor status
	echo -e "FLAVOR STATUS" >&2

	if [ "$flavor" = "all" ]; then
		for flavor in $(cat /tmp/todo.txt); do
			echo -e "\n$flavor\n------"
			grep $flavor /tmp/matrix.txt | cut -d, -f1
		done
	else
		echo -e "\n$flavor\n------"
		grep $flavor /tmp/matrix.txt | cut -d, -f1
	fi
fi

if [ ! -z $zone ]; then
	# show zone status
	echo -e "ZONE DETAILS" >&2
	if [ "$zone" = "all" ]; then
		for zone in $(cat $resource_matrix | cut -d, -f1 | sort -u); do
			echo -e "\n$zone\n------"
			grep $zone /tmp/matrix.txt | cut -d, -f2
		done
	else
		echo -e "\n$zone\n------"
		grep $zone /tmp/matrix.txt | cut -d, -f2
	fi
fi

if [ -z $flavor ] && [ -z $zone ]; then
	# show best region
	echo -e "BEST REGIONS\n" >&2
	cat /tmp/matrix.txt | cut -d, -f1 | uniq -c | sort -nr
fi

exit 0
