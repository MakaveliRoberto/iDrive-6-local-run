#!/bin/ksh
# set -x
# formats filesystems

VERSION=V0.0.1
echo "formatAppChkPers.sh: $VERSION"

echo "Check and format Partition appl"

create_sdc.sh -p appl -f 
umount -f /fs/sda0


# following code will replace this  statement
# create_sdc.sh -p appl -c format -c mount 
# out of the original script.

# information and code copy from other script create_sdc.sh 

#definitions type slot ext mount pt  mode size           option  inodes
#DEF_APPL="  179    2   1 /fs/sda0    ro $SIZE_QNX_APPL   qnx6  default"

	  

whence wipe > /dev/null
if [[ $? -eq 0 ]]; then
    echo "discard application partition before formation."
    wipe -i -me -sp /dev/sda0t179
fi

# now format the partition
debug_msg "mkqnx6fs -q -b4096 -i95000 /dev/sda0t179"
mkqnx6fs -q -b4096 -i95000 /dev/sda0t179

# and now mount it
create_sdc.sh -p appl -c mount


echo "Check and format Partition pers if necessary"

if create_sdc.sh -p pers -f; then
   echo "Partition pers OK"
else
   echo " *** ERROR: Partition pers is corrupt, will be formated!!! ***"
   umount -f /fs/sda1
   create_sdc.sh -p pers -c format -c mount -c directories
fi

echo "formatAppChkPers.sh: Ready"
