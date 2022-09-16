#!/bin/bash

set -e

function show_usage() {
    echo "Untar sockperf logs and summarize the report."
    echo "$(basename $0) [-l LOGDIR]"
    echo "-l: The directory with sockperf log tarball."
    echo "-f: The flavor"
    echo "    Will use '.' if not specified."
}

while getopts :hl:f: ARGS; do
    case $ARGS in
    h)
        # Help option
        show_usage
        exit 0
        ;;
    l)
        # Logdir option
        logdir=$OPTARG
        ;;
    f)
        # Flavor
        flavor=$OPTARG
        ;;
    "?")
        echo "$(basename $0): unknown option: $OPTARG" >&2
        ;;
    ":")
        echo "$(basename $0): option requires an argument -- '$OPTARG'" >&2
        echo "Try '$(basename $0) -h' for more information." >&2
        exit 1
        ;;
    *)
        # Unexpected errors
        echo "$(basename $0): unexpected error -- $ARGS" >&2
        echo "Try '$(basename $0) -h' for more information." >&2
        exit 1
        ;;
    esac
done

: ${logdir:=$PWD}
workspace=$(mktemp -d)
if [[ $flavor != '' ]]; then
    for i in $(ls logs/*perf*.tar.gz | grep $flavor); do
        cp -f $i $workspace
    done
else
    cp $logdir/*perf*.tar.gz $workspace
fi

cd $workspace
for file in $(ls *.tar.gz); do
    #echo "FILE: $file" >&2
    tar -xf $file ${file/%.tar.gz/.txt}
done

cat *perf*.txt | head -n 1 | sort -u
tail -n +2 -q *perf*.txt

rm -rf $workspace

exit 0
