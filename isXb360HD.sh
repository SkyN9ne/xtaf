#!/usr/bin/env bash

# ./isXb360Hd /dev/sda && echo OK || echo KO
# KO
# ./isXb360Hd /dev/loop0 && echo OK || echo KO
# OK
# ./isXb360Hd /dev/loop0 -v && echo OK || echo KO
# device: /dev/loop0
# serial number: 6VCT9Z2W
# firmware revision: 0002CE02
# model number: ST9250315AS
# size: 488397168 bytes
# xtaf at 0x10c080000: ok
# xtaf at 0x118eb0000: ok
# xtaf at 0x120eb0000: ok
# xtaf at 0x130eb0000: ok
# OK


# strict mode
set -eu

# usage function
function usage {
    echo "usage: $( basename "$0" ) device [-v|--verbose]" > /dev/stderr
    exit 2
}

# script parameters
[ "${1:-x}" == 'x' ] && usage
[ "${2:-x}" != 'x' ] && [ "${2:-x}" != '-v' ] && [ "${2:-x}" != '--verbose' ] && usage
[ "${3:-x}" != 'x' ] && usage

# checking the "Josh" signature at offet 0x800
if [ "$( dd status=none if="$1" bs=1 skip=2048 count=4 | tr '\0' '\n' )" == $'Josh' ]
then
    # checking the PNG signature at offset 0x2204
    if [ "$( dd status=none if="$1" bs=1 skip=8708 count=5 | tr '\0' '\n' )" == $'\x89PNG\x0d' ]
    then
        if [ "${2:-x}" != 'x' ]
        then
            # verbose mode
            echo "device: "$1
            # reading informations at offset 0x2000
            data=$( dd status=none if="$1" bs=1 skip=8192 count=48 )
            echo "serial number: "$( echo ${data::20} )
            echo "firmware revision: "$( echo ${data:20:8} )
            echo "model number: "$( echo ${data:28} )
            echo "size: "$( blockdev --getsz "$1" )" bytes"
            # checking the "XTAF" signature of the four known xtaf partitions
            echo -n "xtaf at 0x10c080000: "
            [ "$( dd status=none if="$1" bs=1 skip=$((0x10c080000)) count=4 | tr '\0' '\n' )" == $'XTAF' ] && echo ok || echo KO
            echo -n "xtaf at 0x118eb0000: "
            [ "$( dd status=none if="$1" bs=1 skip=$((0x118eb0000)) count=4 | tr '\0' '\n' )" == $'XTAF' ] && echo ok || echo KO
            echo -n "xtaf at 0x120eb0000: "
            [ "$( dd status=none if="$1" bs=1 skip=$((0x120eb0000)) count=4 | tr '\0' '\n' )" == $'XTAF' ] && echo ok || echo KO
            echo -n "xtaf at 0x130eb0000: "
            [ "$( dd status=none if="$1" bs=1 skip=$((0x130eb0000)) count=4 | tr '\0' '\n' )" == $'XTAF' ] && echo ok || echo KO
        fi
        # return device is Xbox 360 hard disk
        exit 0
    fi
fi
# return device is not Xbox 360 hard disk
exit 1
