#!/bin/ksh

# Script to chain start-up of PrepareMedia and NBTMediaMainApp processes.
# Avoids server-starter bottleneck in spawning processes.

SLOG=/dev/console

log_msg()
{
   # log to SLOG
   echo $* > $SLOG
}

log_error()
{
   # log to both SLOG and STDOUT
   echo $* > $SLOG
   echo $*
}

# Failure exit codes
FAIL_NODEVICE=17
FAIL_WRONGDEVICE=18
FAIL_NORAMDISK=19
FAIL_EXEC=20
FAIL_FINAL=21

fail()
{
   EXITCODE=$1
   shift
   log_error $*
   exit $EXITCODE   
}

#
# MAIN
#

# log to entertainment special consol -L /hbsystem/multicore/navi/o
if [[ $1 == "-L" ]]; then
   SLOG=$2
   shift 2
fi

# First argument identifies device type (head unit, RSE).
DEVICE=$1

if [[ "$DEVICE" = "-h" ]]; then
   # Head unit. use prepare media option -h to indicate presence of Hard Disk Drive.
   PREPARE_MEDIA_OPT="-h"   
elif [[ "$DEVICE" = "-r" ]]; then
   # RSE. no special options.
   PREPARE_MEDIA_OPT=
   
   #Check if BluRay persistence partition exists
   BDPERSISTENCE=/mnt/bdpersistence
   BDPERSISTENCY_FILE=/var/opt/mm/BDPersistency.img

   if [[ -e $BDPERSISTENCE ]]; then
      echo "BluRay persistence partition exists, nothing to do!"
      if [[ -f $BDPERSISTENCY_FILE ]]; then
         echo "Just delete $BDPERSISTENCY_FILE"
         rm $BDPERSISTENCY_FILE
      fi 
   else
      echo "BluRay persistence partition not existing, do something!"
      if [[ -f $BDPERSISTENCY_FILE ]]; then
         echo "BDPersistency file available"
      else
         echo "Create new BDPersistency file"
         echo > $BDPERSISTENCY_FILE 
         dinit -hq -S10m $BDPERSISTENCY_FILE
      fi
      
      LOOPBACK_DEVICE=/sbin/devb-loopback
      LOOPBACK_OPTIONS="blk cache=128k,automount=bdper0:$BDPERSISTENCE:qnx4 loopback fd=$BDPERSISTENCY_FILE,prefix=bdper,blksz=4096 &"
      
      $LOOPBACK_DEVICE $LOOPBACK_OPTIONS      
   fi
     
elif [[ "$DEVICE" = "" ]]; then
   fail $FAIL_NODEVICE "$0: Failed to specify device! Please specify either -h or -r!"
else
   fail $FAIL_WRONGDEVICE "$0: Wrong device: $DEVICE ! Please specify either -h or -r!"
fi

# First argument has been parsed.
shift


# Action: run PrepareMedia in foreground, if so required.
PREPARE_MEDIA=/opt/mm/bin/PrepareMedia
PREPARE_MEDIA_FINISHED=/dev/shmem/prepareMediaFinished

if [[ ! -e $PREPARE_MEDIA_FINISHED ]]; then
   $PREPARE_MEDIA $PREPARE_MEDIA_OPT
   log_msg "$0: $PREPARE_MEDIA finished with exit code $?"
   if [[ ! -e $PREPARE_MEDIA_FINISHED ]]; then
      log_msg "$0: $PREPARE_MEDIA_FINISHED does not exist! Continuing with Media Main App anyway."
   fi
else
   log_msg "$0: Second or subsequent start, $PREPARE_MEDIA_FINISHED already exists. Continuing with Media Main App."
fi

# Media RAM Disk is a prerequisite for Media Main App.
# It is started by server-starter, so wait for it, if necessary.
MEDIA_RAM_DISK=/ramdisk/mm

if [[ ! -e $MEDIA_RAM_DISK ]]; then
   waitfor $MEDIA_RAM_DISK 120.0
   if [[ ! -e $MEDIA_RAM_DISK ]]; then
      fail $FAIL_NORAMDISK "$0: $MEDIA_RAM_DISK not found!"
   fi
fi

GRACENOTE=/mnt/data/mm/gracenote/db/content.xml

if [[ -f $GRACENOTE ]]; then
   JAPAN='05'
   echo "Check for country $SYSTEM_EINSTELLUNGEN_COUNTRY" > /dev/console
   if [[ $SYSTEM_EINSTELLUNGEN_COUNTRY = $JAPAN ]] ; then
      echo -n "Coded country is JAPAN, copy Gracenote config to /dev/shmem" > /dev/console
      cp /opt/mm/etc/gracenoteJapan.cfg /dev/shmem/gracenote.cfg
   else
      echo -n "Coded country is not JAPAN, copy Gracenote config to /dev/shmem" > /dev/console
      cp /opt/mm/etc/gracenote.cfg /dev/shmem/gracenote.cfg
   fi
fi

if [[ "$DEVICE" = "-h" ]]; then
   EAF=/mnt/quota/mm/A4A/eaf.cfg
   if [[ ! -f $EAF ]]; then
      echo "eaf.cfg does not exist - brand=$HMI_BRAND" > /dev/console
      MINI='02'
      if [[ $HMI_BRAND = $MINI ]]; then
         echo "copy eaf_mini.cfg" > /dev/console
         cp /opt/mm/etc/eaf_mini.cfg $EAF
      else
         echo "copy eaf_default.cfg" > /dev/console
         cp /opt/mm/etc/eaf_default.cfg $EAF
      fi
   fi
fi

# Action: Exec into NBTMediaMainApp
# Server-starter retains control because we're exec'ing, rather than creating a child process.
MEDIA_MAIN_APP=/opt/mm/bin/NBTMediaMainApp

log_msg "$0: Exec'ing into $MEDIA_MAIN_APP $*"
exec on -P $MEDIA_MAIN_APP $*
# if we get here, exec failed
fail $FAIL_EXEC "$0: Exec $MEDIA_MAIN_APP failed!"

# we should never get here
exit $FAIL_FINAL
