#!/bin/ksh

# ----------------------------------------------------------------------
#   Project    : Harman Car Multimedia System
#   Harman/becker Automotive Systems GmbH
#   All rights reserved
#
#   File      : NAND Management Script
#   Author    : SPreuss
# ----------------------------------------------------------------------

CDIR=$PWD
VERSION=V2.1.2
SDA0_DEVICE=/dev/sda0
SDA1_DEVICE=/dev/sda1
DEVICE=$SDA0_DEVICE
rRETVAL=0
QUITE=0

cd ${0%/*}
export PATH=$PATH:$PWD
cd $CDIR

LOG=/dev/ser1
if [[ ! -e $LOG ]]; then
   LOG=/dev/console
fi

NUM_CYLINDERS=$(fdisk $DEVICE query -T)
echo "Found NAND with $NUM_CYLINDERS cylinders!"

# calculate partition sizes
SIZE_FAT_BOOT=32
SIZE_RAW_BOOT=16
SIZE_QNX_APPL=6500
SIZE_QNX_BOLO=200
SIZE_QNX_PERS=$(($NUM_CYLINDERS-$SIZE_FAT_BOOT-2*$SIZE_RAW_BOOT-$SIZE_QNX_APPL-2*$SIZE_QNX_BOLO))
SIZE_EXT_PART=$(($SIZE_QNX_APPL+2*$SIZE_QNX_BOLO+$SIZE_QNX_PERS))


# notes: ext:      != 0  add partition to extended partition of specifed slot
#                  == 0  add partition as primary partition in specified slot
#        mount pt: none      don't mount this partition
#                  /fs/sdaX  mount partition to specified mount point
#        size:     != 0   size of the partition 
#                  == 0   size size is been filled up to the rest of the partition table
#        option:   boot   format and mount fs as FAT16 and set partition as boot partition
#                  dos    format and mount fs as FAT16
#                  fat16  format and mount fs as FAT16
#                  fat32  format and mount fs as FAT32
#                  qnx6   format and mount fs as QNX6
#                  ext    mark partition as extended partition (no format and/or mount)
#                  raw    mark partition as raw partition (no format and/or mount)

#          type slot ext mount pt  mode size           option  inodes
DEF_BOOT="    4    1   0 /fs/sda2    ro $SIZE_FAT_BOOT   boot  default"
DEF_EXT="    15    2   0 none        ro $SIZE_EXT_PART   ext   default"
DEF_APPL="  179    2   1 /fs/sda0    ro $SIZE_QNX_APPL   qnx6  95000"
DEF_BOLO1=" 177    2   2 /fs/sda31   ro $SIZE_QNX_BOLO   qnx6  default"
DEF_BOLO2=" 180    2   3 /fs/sda32   ro $SIZE_QNX_BOLO   qnx6  default"
DEF_PERS="  178    2   4 /fs/sda1    rw $SIZE_QNX_PERS   qnx6  default"
DEF_BOOT1=" 101    3   0 none        ro $SIZE_RAW_BOOT   raw   default"
DEF_BOOT2=" 102    4   0 none        ro $SIZE_RAW_BOOT   raw   default"
ALL_PARTITIONS="$DEF_BOOT $DEF_EXT $DEF_APPL $DEF_BOLO1 $DEF_BOLO2 $DEF_PERS $DEF_BOOT1 $DEF_BOOT2"

VAR_DIRS="log dump opt/car opt/conn opt/hmi opt/mm opt/nav opt/speech opt/sys"

debug_msg()
{
   if [[ $QUITE -eq 0 ]]; then
      echo "$*"
   fi
}

kPartitionSdc()
{
   rSTAT=0
   rDEVICE=$1
   shift
   
   # test if we are running in emergency mode.
   if [[ -e /dev/starter ]] ; then
      echo "ERROR: To initalize the NAND Flash you need to boot into emergency IFS."
      rSTAT=$((rSTAT + 1))
      return $rSTAT;
   fi
   
   # test if partition is called with specific partition parameter.
   if [[ -n $PARTITION ]] ; then
      echo "ERROR: To repartition the NAND Flash you must not use the -p parameter!"
      rSTAT=$((rSTAT + 1))
      return $rSTAT;
   fi

   debug_msg "fdisk $rDEVICE delete -a"
   fdisk $rDEVICE delete -a || rSTAT=$((rSTAT + 1))
   
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift
      
      if [[ $rEXT -ne 0 ]]; then
         if [[ $rSIZE -ne 0 ]]; then
            debug_msg "fdisk $rDEVICE add -t $rTYPE -s $rSLOT -e $rEXT -n $rSIZE"
            fdisk $rDEVICE add -t $rTYPE -s $rSLOT -e $rEXT -n $rSIZE || rSTAT=$((rSTAT + 1))
         else
            debug_msg "fdisk $rDEVICE add -t $rTYPE -s $rSLOT -e $rEXT"
            fdisk $rDEVICE add -t $rTYPE -s $rSLOT -e $rEXT || rSTAT=$((rSTAT + 1))
         fi
      else
         if [[ $rSIZE -ne 0 ]]; then
            debug_msg "fdisk $rDEVICE add -t $rTYPE -s $rSLOT -n $rSIZE"
            fdisk $rDEVICE add -t $rTYPE -s $rSLOT -n $rSIZE || rSTAT=$((rSTAT + 1))
         else
            debug_msg "fdisk $rDEVICE add -t $rTYPE -s $rSLOT"
            fdisk $rDEVICE add -t $rTYPE -s $rSLOT || rSTAT=$((rSTAT + 1))
         fi
      fi
      if [[ $rOPTION == "boot" ]]; then
         debug_msg "fdisk $rDEVICE boot -t $rTYPE"
         fdisk $rDEVICE boot -t $rTYPE
      fi
   done
   fdisk $rDEVICE show || rSTAT=$((rSTAT + 1))
   mount -e $rDEVICE || rSTAT=$((rSTAT + 1))
   return $rSTAT
}

kFormatSdc()
{
   rBS=4096
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      rINODES=""
      if [[ $8 != "default" ]]; then
         rINODES="-i $8"
      fi
      shift; shift; shift; shift; shift; shift; shift; shift
      if [[ $rOPTION == "boot" ||  $rOPTION == "dos" || $rOPTION == "fat16" ]]; then
         debug_msg "mkdosfs -e32 -F16 -c$rBS ${rDEVICE}t$rTYPE"
         mkdosfs -e32 -F16 -c$rBS ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
      elif [[ $rOPTION == "fat32" ]]; then
         debug_msg "mkdosfs -F32 -c$rBS ${rDEVICE}t$rTYPE"
         mkdosfs -F32 -c$rBS ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
      elif [[ $rOPTION == "qnx6" ]]; then
         whence wipe > /dev/null
         if [[ $? -eq 0 ]]; then
            debug_msg "discard partition ${rDEVICE}t$rTYPE before formation."
            wipe -i -me -sp ${rDEVICE}t$rTYPE
         fi
         debug_msg "mkqnx6fs -q -b$rBS $rINODES ${rDEVICE}t$rTYPE"
         mkqnx6fs -q -b$rBS $rINODES ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
      fi
   done
   return $rSTAT
}

kMountSdc()
{
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift

      if [[ $rOPTION == "boot" ||  $rOPTION == "dos" || $rOPTION == "fat16" || $rOPTION == "fat32" ]]; then
         debug_msg "mount -t dos -o $rMODE ${rDEVICE}t$rTYPE $rMP"
         mount -t dos -o $rMODE ${rDEVICE}t$rTYPE $rMP || rSTAT=$((rSTAT + 1))
      elif [[ $rOPTION == "qnx6" ]]; then
         debug_msg "mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP"
         mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP || rSTAT=$((rSTAT + 1))
      fi
   done
   return $rSTAT
}

kUmountSdc()
{
   rSTAT=0
   rDEVICE=$1
   shift

   # test if we are running in emergency mode.
   if [[ -e /dev/starter ]] ; then
      echo "ERROR: Unmounting in application or bootloader mode is no good idea. ;-)"
      rSTAT=$((rSTAT + 1))
      return $rSTAT;
   fi
   
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift
      if [[ $rMP != "none" ]]; then
         if [[ -e $rMP ]]; then
            debug_msg "umount -f $rMP"
            umount -f $rMP || rSTAT=$((rSTAT + 1))
         else
            echo "mountpoint $rMP not available"
         fi
      fi
   done
   return $rSTAT
}

kRemountSdc()
{
   rSTAT=0
   rNEW_MODE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift
      if [[ $rMP != "none" ]]; then
         if [[ -e $rMP ]] ; then
            if [[ $rNEW_MODE != "default" ]] ; then
               rMODE=$rNEW_MODE
            fi
            debug_msg "mount -u -o $rMODE $rMP"
            mount -u -o $rMODE $rMP || rSTAT=$((rSTAT + 1))
         fi
      fi
   done
   return $rSTAT
}

kDirectoriesSdc()
{
   rSTAT=0
   rCURRDIR=$PWD
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift
      mount -u -o rw $rMP
      cd $rMP
      for rDIR in $VAR_DIRS
      do
         debug_msg "mkdir $rMP/$rDIR"
         mkdir -p $rDIR || rSTAT=$((rSTAT + 1))
      done      
      mount -u -o $rMODE $rMP
   done
   cd $rCURRDIR
   return $rSTAT
}

kChkfs()
{
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rSLOT=$2
      rEXT=$3
      rMP=$4
      rMODE=$5
      rSIZE=$6
      rOPTION=$7
      shift; shift; shift; shift; shift; shift; shift; shift
      if [[ $rOPTION == "boot" ||  $rOPTION == "dos" || $rOPTION == "fat16" || $rOPTION == "fat32" ]]; then
         debug_msg "chkdosfs -un ${rDEVICE}t$rTYPE"
         chkdosfs -un ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
      elif [[ $rOPTION == "qnx6" ]]; then
         if [[ $rTYPE == 181 && ! -e /dev/sda0t181 ]] ; then
            echo "WARNING: BD persistence is missing, please update your partition table!"
         else
            debug_msg "chkqnx6fs -vvv ${rDEVICE}t$rTYPE"
            chkqnx6fs -svvv ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
            chkqnx6fs -vvv ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
         fi
      fi
   done
   if [ $rSTAT -ne 0 ] ; then
      echo "ERROR: while checking file systems!"
   else
      echo "SUCCESS: checking file systems finished!"
   fi   
   
   return $rSTAT
}

kPrintPartitionTabel()
{
   CURRENT_PART_TAB=$(fdisk /dev/sda0 show) || rSTAT=$((rSTAT + 1))
   echo "$CURRENT_PART_TAB"
   return $rSTAT
}

kHelp()
{
   echo "Usage $0 [-d <device_num>] [-p <partition>] [-c <command> [-c <command>] ...]"
   echo "      [-i] [-f] [-m] [-r] [-w] [-R] [-u] [-q] [-P]"
   echo "  -d <device_num> set device (default: 0 (for /dev/sda0))"
   echo "  -p <partition> set specific partition (default: all partitions)"
   echo "     valid partitions: boot appl bolo1 bolo2 pers boot1 boot2"
   echo "  -i initalize the NAND flash: create partiton table, make filesystems and add domain directories."
   echo "  -I <partition> initalize one partiton, make filesystems and add domain directories."
   echo "  -f check nand file systems"
   echo "  -m mount all partitons"
   echo "  -r remount all partitons read only"
   echo "  -P print the partition table"
   echo "  -w remount all partitons read and write"
   echo "  -R remount all partitons in default mode"
   echo "  -u umount all partitons"
   echo "  -q quite no messages except errors."
   echo "  -h print this help screen"
   echo "  -c <command>"
   echo "     valid commands:"
   echo "     ==============="
   echo "     partition:  create partiton table"
   echo "     format:  make filesystems"
   echo "     mount:  mount filesystems"
   echo "     umount:  umount filesystems"
   echo "     remount_r:  remount filesystems read only"
   echo "     remount_w:  remount filesystems read and write"
   echo "     remount:  remount filesystems in default mode"
   echo "     directories:  make domain directories on certain filesystems"
   echo "     chkfs:  checks the qnx6 file system"
   echo "     help:  print this help screen"
   echo "     Commands are executed in the order specified on the command line."
   echo " Examples:"
   echo "    $0 -c umount -c partition -c format -c mount -c directories"
   echo "    $0 -p pers -c format -c mount -c directories"
   echo
}

COMMANDLIST=""

# if there are no arguments
if [[ $# -lt 1 ]] ; then
   kHelp
   exit 0
fi

# parse command line
while getopts "d:p:c:PRrvwfumiI:hq" OPTION
do
   case $OPTION in
      d)
         if [[ $OPTARG -eq 1 ]] ; then
            DEVICE=$SDA1_DEVICE
         elif [[ $OPTARG -eq 0 ]] ; then
               DEVICE=$SDA0_DEVICE
         else
            echo "ERROR: Invalid device id! Only [0|1] is valid!"
            exit 1
         fi
         echo "INFO: Set device to $DEVICE!"
         ;;
      p)
         typeset -u ARG=$OPTARG
         eval "PARTITION=\$DEF_$ARG"
         if [[ -z $PARTITION ]] ; then
            echo "ERROR: Invalid partition specified!"
            exit 1
         fi
         ;;
      f)
         COMMANDLIST="remount_r chkfs remount"
         ;;
      i)
         COMMANDLIST="umount partition format mount directories"
         ;;
      I)
         typeset -u ARG=$OPTARG
         eval "PARTITION=\$DEF_$ARG"
         if [[ -z $PARTITION ]] ; then
            echo "ERROR: Invalid partition specified!"
            exit 1
         fi
         COMMANDLIST="umount format mount directories"
         ;;
      u)
         COMMANDLIST="umount"
         ;;
      m)
         COMMANDLIST="mount"
         ;;
      R)
         COMMANDLIST="remount"
         ;;
      r)
         COMMANDLIST="remount_r"
         ;;
      P)
         COMMANDLIST="print_parttab"
         ;;
      w)
         COMMANDLIST="remount_w"
         ;;
      c)
         COMMANDLIST="$COMMANDLIST $OPTARG"
         ;;
      q)
         QUITE=1
         ;;
      h | *)
         kHelp
         exit 0
         ;;
   esac
done

debug_msg "-------------------------"
debug_msg "$0 $VERSION"
debug_msg "-------------------------"

if [[ -n $PARTITION ]] ; then
   PATITIONS_TO_PROCESS=$PARTITION
else
   PATITIONS_TO_PROCESS=$ALL_PARTITIONS
fi

for COMMAND in $COMMANDLIST
do
   if [[ $COMMAND == partition ]]; then
      kPartitionSdc $DEVICE $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == format ]]; then
      kFormatSdc $DEVICE $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == mount ]]; then
      kMountSdc $DEVICE $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == umount ]]; then
      kUmountSdc $DEVICE $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == remount ]]; then
      kRemountSdc default $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == remount_r ]]; then
      kRemountSdc ro $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == remount_w ]]; then
      kRemountSdc rw $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == directories ]]; then
      kDirectoriesSdc $DEVICE $DEF_PERS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == chkfs ]]; then
      kChkfs $DEVICE $PATITIONS_TO_PROCESS
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == print_parttab ]]; then
      kPrintPartitionTabel
      rRETVAL=$((rRETVAL + $?))
   fi

   if [[ $COMMAND == help ]]; then
      kHelp
   fi
   
   if [[ $rRETVAL -ne 0 ]]; then
      echo "ERROR: $0 failed!"
      exit $rRETVAL
   fi
done

debug_msg "SUCCESS: $0 finished!"

exit $rRETVAL
