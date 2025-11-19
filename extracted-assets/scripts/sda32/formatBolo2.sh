#!/bin/ksh
# set -x
# formats filesystems

VERSION=V0.0.1
echo "formatBolo2.sh: $VERSION"

echo "Check and format Partition bolo2"

create_sdc.sh -p bolo2 -f 
umount -f /fs/sda32
create_sdc.sh -p bolo2 -c format -c mount 

echo "formatBolo2.sh: Ready"
