#!/bin/ksh
# set -x
# formats filesystems

VERSION=V0.0.1
echo "formatBolo1.sh: $VERSION"

echo "Check and format Partition bolo1"

create_sdc.sh -p bolo1 -f 
umount -f /fs/sda31
create_sdc.sh -p bolo1 -c format -c mount 

echo "formatBolo1.sh: ready"
