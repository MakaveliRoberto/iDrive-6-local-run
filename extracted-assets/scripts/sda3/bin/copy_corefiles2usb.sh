#!/bin/ksh

for USBPATH in `/bin/ls -d /net/hu-omap/mnt/umass*`
do 
   /bin/cp -rsfAc /net/hu-jacinto/var/dump/ $USBPATH/NBTevo_corefiles/dump_hu_j5/
   /bin/cp -rsfAc /net/hu-omap/fs/sda1/dump/ $USBPATH/NBTevo_corefiles/dump_hu_o5/
   /bin/cp -rsfAc /net/hu-omap/mnt/share/conn/cores $USBPATH/NBTevo_corefiles/mnt_share_conn_cores_hu_o5/
done
