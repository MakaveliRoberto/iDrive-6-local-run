#!/bin/ksh

#LoggingPath
LOGGINGPATH=/dev/console

#Hostaddress Head Unit OMAP
HOSTADDRESS=160.48.199.119

# binary fs-nfs3
NFSCLIENT=fs-nfs3

#binary showmount
SHOWMOUNT=showmount

# we'd like to get 5 mount points: /mnt/data, /mnt/quota/mm, /mnt/quota/sys, /mnt/share, /ramdisk/mm
REQUIREDMOUNTPOINTS=5
# robustness: after a number of failed attempts, we're satisfied if one mountpoint is missing
FALLBACKAFTER=3
FALLBACKMOUNTPOINTS=4

#check if binaries are available
whence -v $SHOWMOUNT  >/dev/null 2>&1
if [[ $? -ne 0 ]] ; then
   echo "fs-nfs3_launcher.sh: ERROR: Could not find $SHOWMOUNT!" > $LOGGINGPATH
   exit 1
fi

whence -v $NFSCLIENT  >/dev/null 2>&1
if [[ $? -ne 0 ]] ; then
   echo "fs-nfs3_launcher.sh: ERROR: Could not find $NFSCLIENT!" > $LOGGINGPATH
   exit 1
fi

# we wait until showmount supplies required mountpoints on HU
ATTEMPTS=0

while (true) ; do
   if [[ -e /fs/sda0 ]] ; then
      countMountPoints=`$SHOWMOUNT -e $HOSTADDRESS 2>&1 | grep -cE '\/(mnt|ramdisk)\/'`      
      if [[ $countMountPoints -ge $REQUIREDMOUNTPOINTS ]] ; then
         echo "fs-nfs3_launcher.sh: starting $NFSCLIENT" > $LOGGINGPATH
         exec $NFSCLIENT -Z a -eus -o soft=1,udp $HOSTADDRESS:/mnt/data /mnt/data -Z a -eus -o soft=1,udp $HOSTADDRESS:/mnt/quota/mm /mnt/quota/mm -Z a -eus -o soft=1,udp $HOSTADDRESS:/mnt/quota/sys /mnt/quota/sys -Z a -eus -o soft=1,udp $HOSTADDRESS:/mnt/share /mnt/share -Z a -eus -o soft=1,udp $HOSTADDRESS:/ramdisk/mm /mnt/ramdisk/mm
      else
         if [[ ++ATTEMPTS -eq $FALLBACKAFTER ]]; then
            echo "fs-nfs3_launcher.sh: Fall back after $ATTEMPTS attempts: Now waiting for $FALLBACKMOUNTPOINTS instead of $REQUIREDMOUNTPOINTS mount points!" > $LOGGINGPATH
            REQUIREDMOUNTPOINTS=$FALLBACKMOUNTPOINTS
         else
            echo "fs-nfs3_launcher.sh: showmount call #$ATTEMPTS reports $countMountPoints NFS exports from Head Unit, but we're waiting for at least $REQUIREDMOUNTPOINTS, trying again..." > $LOGGINGPATH
         fi
      fi
      sleep 1
   else
      exit 0
   fi
done

# we should never get here
exit 1