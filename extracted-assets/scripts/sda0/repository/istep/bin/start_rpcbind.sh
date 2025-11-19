#!/bin/ksh

rpcbind $*
# daemon is now in background
# provide flag file for synchronization purposes
echo "rpcbind $*" > /dev/shmem/start_rpcbind.done

exit 0
