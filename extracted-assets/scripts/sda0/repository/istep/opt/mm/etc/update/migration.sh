#!/bin/ksh

# ////////////////////////// DEFINES START /////////////////////////////////

EXIT_OK=0
EXIT_ERROR=1

echo "Run Upgrade Script (migration.sh)" > /dev/console

backupVersion=$1
expectedVersion=$2

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

echo "Backup version:" > /dev/console
echo $backupVersion > /dev/console
echo "Expected version:" > /dev/console
echo $expectedVersion > /dev/console

# ////////////////////////// DEFINES END /////////////////////////////////

# ////////////////////////// UPGRADE START /////////////////////////////////

if [ $backupVersion -gt $expectedVersion ] ; then
   echo "Software downgrade (backup db version is greater then software db version) -> delete backup!!!" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR
fi

if [ $backupVersion -eq 0 ] ; then
   echo "Backup version is 0 DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR   
fi

if [ $backupVersion -le 1009 ] && [ $expectedVersion -gt 1009 ] ; then
      
   echo "Delete backup for one time" > /dev/console
   cleanupFileSystem
   exit $EXIT_ERROR
fi

# ////////////////////////// UPGRADE END ///////////////////////////////////
      
# ////////////////////////// RETURN START //////////////////////////////////

echo "Upgrade (mme) done!" > /dev/console
exit $EXIT_OK


# ////////////////////////// RETURN END ////////////////////////////////////
