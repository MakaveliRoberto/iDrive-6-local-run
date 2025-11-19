#!/bin/ksh

# ////////////////////////// DEFINES START /////////////////////////////////

EXIT_OK=0
EXIT_ERROR=1

backupVersion=$1
expectedVersion=$2

echo "Run HU-Upgrade Script custom (mm_custom_migration.sh) from Version ${backupVersion} to Version ${expectedVersion}" > /dev/console

# ////////////////////////// UPGRADE START /////////////////////////////////

function errorHandling
{
   if [[ $? -ne 0 ]] ; then      
      echo $1 > /dev/console
      cleanupFileSystem
      exit $EXIT_ERROR
   fi
}

function cleanupFileSystem
{
   echo "Cleanup File System" > /dev/console
   rm -rf /mnt/quota/mm/backup/*
   rm -rf /mnt/quota/mm/backup2/*
   rm -rf /mnt/quota/mm/PVCache/*
   rm -rf /mnt/quota/mm/gracenote/* 
   rm -rf /mnt/quota/mm/ODLCoverart/*
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppMmeCommon
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppmassstoragecontrol
   rm -f /var/opt/sys/persistence/normal/pers_NBTMediaMainAppMultimediaPlayerFront
   rm -rf /mnt/quota/mm/OnlineEntertainment
   echo "Create OnlineEntertainment directories (Content, Coverart, App)" > /dev/console
   mkdir /mnt/quota/mm/OnlineEntertainment
   mkdir /mnt/quota/mm/OnlineEntertainment/Content
   mkdir /mnt/quota/mm/OnlineEntertainment/Coverart
   mkdir /mnt/quota/mm/OnlineEntertainment/App
   echo "Create hu and rse PVCache directories"
   mkdir /mnt/quota/mm/PVCache/hu
   mkdir /mnt/quota/mm/PVCache/rse
}

function cleanupRemovableDataAndCoverarts
{
}
function regenerateTriggersAndIndexes
{
}
function setPragmas
{
}
function commcoUpgrade
{
}
function triggerSyncInJapan
{
}
function setnewversion
{
   echo "Set new Version to ${expectedVersion}" > /dev/console
   qdbc -dmme "DELETE FROM _qdb_info_custom_" > /dev/console
   errorHandling "ERROR: Can not DELETE FROM _qdb_info_custom_, delete backup"
   qdbc -dmme "INSERT INTO _qdb_info_custom_(version) VALUES(${expectedVersion})"> /dev/console;
   errorHandling "ERROR: Can not set expected Version, delete backup"
}

#---------------------Begin---------------------------------

if [ $backupVersion -gt $expectedVersion ]; then
   echo "Set Custom-Version from Version ${backupVersion} to Version ${expectedVersion} -> Downgrade DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   echo "MediaUpgrade" > /dev/shmem/MediaUpgrade
   exit $EXIT_ERROR   
fi

if [ $backupVersion -lt 3006 ]; then
   echo "Set Custom-Version from Version ${backupVersion} to Version ${expectedVersion} -> Backup version is unserviceable DELETE BACKUP!!!" > /dev/console
   cleanupFileSystem
   echo "MediaUpgrade" > /dev/shmem/MediaUpgrade
   exit $EXIT_ERROR   
fi

if [ $backupVersion -lt $expectedVersion ] ; then
   echo "Set Custom-Version from Version ${backupVersion} to Version ${expectedVersion}" > /dev/console

   #regenerateTriggersAndIndexes

	setnewversion
   # When live cycle was long enougth to finish the script write a backup, in next live cycle upgrade script will not be called!!!
   qdbc -dmme -B
   echo "MediaUpgrade" > /dev/shmem/MediaUpgrade
fi
echo "Upgrade done!" > /dev/console
exit $EXIT_OK
