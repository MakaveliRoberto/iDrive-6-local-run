#!/bin/ksh

# ////////////////////////// DEFINES START /////////////////////////////////

EXIT_OK=0
EXIT_ERROR=1

echo "Run Upgrade Script commco (mm_commco_migration.sh)" > /dev/console

backupVersion=$1
expectedVersion=$2

echo "Backup version:" > /dev/console
echo $backupVersion > /dev/console
echo "Expected version:" > /dev/console
echo $expectedVersion > /dev/console

function cleanupFileSystem
{
   rm -rf /mnt/quota/mm/backup/*
   rm -rf /mnt/quota/mm/backup2/*
   rm -rf /mnt/quota/mm/PVCache/*
   rm -rf /mnt/quota/mm/gracenote/* 
   rm -rf /mnt/quota/mm/ODLCoverart/*
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppMmeCommon
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppmassstoragecontrol
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppMultimediaPlayerFront
   echo "Create hu and rse PVCache directories"
   mkdir /mnt/quota/mm/PVCache/hu
   mkdir /mnt/quota/mm/PVCache/rse
}

# ////////////////////////// DEFINES END /////////////////////////////////

# ////////////////////////// UPGRADE START /////////////////////////////////

if [ $backupVersion -gt $expectedVersion ] ; then
   echo "Software downgrade (Backup db version is greater then software db version) DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR      
fi

if [ $backupVersion -eq 0 ] ; then
   echo "Backup version is 0 DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR   
fi

if [ $backupVersion -le 3 ] && [ $expectedVersion -gt 3 ] ; then
   echo "Incompatible DB update DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR
fi

# ////////////////////////// UPGRADE 1 /////////////////////////////////

if [ $backupVersion -le 5 ] && [ $expectedVersion -gt 5 ] ; then
   echo "Upgrade is done in customer script, because there all triggers and indexes are generated at finish !!!" > /dev/console   
   echo "Set commco version 6" > /dev/console
   qdbc -dmme "UPDATE _custom_info_ SET version=6" > /dev/console
   if [[ $? -ne 0 ]] ; then
      echo -n "ERROR: Can not set version 6, delete backup" > /dev/console
      exit $EXIT_ERROR
   fi
fi

# ////////////////////////// UPGRADE END ///////////////////////////////////
      
# ////////////////////////// RETURN START //////////////////////////////////

echo "Upgrade done!" > /dev/console
exit $EXIT_OK

# ////////////////////////// RETURN END ////////////////////////////////////
