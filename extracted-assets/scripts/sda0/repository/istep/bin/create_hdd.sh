#!/bin/ksh

# ----------------------------------------------------------------------
#   Project    : Harman Car Multimedia System
#   Harman/becker Automotive Systems GmbH
#   All rights reserved
#
#   File      : HDD Management Script
#   Author    : SPreuss
#   Co-Author : HSauer
# ----------------------------------------------------------------------
MAC_ADDRESS=FFFFFFFFFFFF
BTMAC_ADDRESS=FFFFFFFFFFFF
NBT_SERIALNUMBER=FFFFFFFFFFFFFFFFFFFF
ADJINFO_READY=0
ADJBLOCK_JACINTO_TXT=NBT_AdjBlock_Jacinto.txt
SYSETADJINFO=sysetadjread
JACINTO_HOST=hu-jacinto
FILE_ADJ_DATA=/net/$JACINTO_HOST/dev/fs0

NAND_FS="/fs/sda0"
REPOSITORY=$NAND_FS/repository/istep
export PATH=$PATH:$REPOSITORY/bin:$REPOSITORY/opt/sys/bin:.
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$REPOSITORY/lib:$REPOSITORY/usr/lib:$REPOSITORY/opt/sys/lib:.

CDIR=$PWD
VERSION=V1.2.7
CHKQNX6FS=chkqnx6fs
HDDSECURITY=hddsecurity2
rRETVAL=0
QUIET=0

BLOCK_SIZE=4096

## new partition table
HDD_SIZE_200GB=195360984
DEF_DATA_200GB="177 /mnt/data ro 135348"
DEF_SHARE_200GB="178 /mnt/share rw 14688"
DEF_MEDIA_200GB="179 /mnt/quota/mm rw 39422"
DEF_DEBUG_200GB="180 /mnt/quota/sys rw 1321"

DOMAIN_DIRS="car conn hmi mm nav speech sys"

DEVICE=/dev/hd0

LOG=/dev/ser1
#LOG=/dev/console

if [[ ! -e $LOG ]]; then
   LOG=/dev/null
fi

cd ${0%/*}
export PATH=$PATH:$PWD
cd $CDIR

getDef()
{
   rNAME=$1
   
   if [[ $rNAME == data ]]; then
      echo $DEF_DATA
   elif [[ $rNAME == share ]]; then
      echo $DEF_SHARE
   elif [[ $rNAME == media ]]; then
      echo $DEF_MEDIA
   elif [[ $rNAME == debug ]]; then
      echo $DEF_DEBUG
   else
      echo
   fi
   
   return 0
}

getAdjInfo()
{
   #  return if adjust info is already known.
   if [[ $ADJINFO_READY -eq 1 ]]; then
      return 0
   fi
   
   if [[ $rSTAT -eq 0 ]]; then
      if [[ -e $FILE_ADJ_DATA ]]; then
         ADJINFO=$($SYSETADJINFO --get=E2P.Networking.Eth0MacAddr) && MAC_ADDRESS="${ADJINFO##E2P.Networking.Eth0MacAddr=*( )}"
          if [[ $? -eq 0 ]]; then
            if [[ ("$MAC_ADDRESS" == "$ADJINFO") || ("$MAC_ADDRESS" == "") || ("$MAC_ADDRESS" == "FFFFFFFFFFFF") || ("$MAC_ADDRESS" == "ffffffffffff") ]]; then
               echo "ERROR: Could not read MAC-Address from adjustblock. Please update the ajustblock!"
               rSTAT=$((rSTAT + 1))
            fi
         fi

         ADJINFO=$($SYSETADJINFO --get=E2P.Networking.Bt0Addr) && BTMAC_ADDRESS="${ADJINFO##E2P.Networking.Bt0Addr=*( )}"
          if [[ $? -eq 0 ]]; then
            if [[ ("$BTMAC_ADDRESS" == "$ADJINFO") || ("$BTMAC_ADDRESS" == "") || ("$BTMAC_ADDRESS" == "FFFFFFFFFFFF") || ("$BTMAC_ADDRESS" == "ffffffffffff") ]]; then
               echo "ERROR: Could not read BLMAC-Address from adjustblock. Please update the ajustblock!"
               rSTAT=$((rSTAT + 1))
            fi
         fi
         
         ADJINFO=$($SYSETADJINFO --get=E2P.ProdLogistic.SerialNo) && NBT_SERIALNUMBER="${ADJINFO##E2P.ProdLogistic.SerialNo=*( )}"
          if [[ $? -eq 0 ]]; then
            if [[ ("$NBT_SERIALNUMBER" == "$ADJINFO") || ("$NBT_SERIALNUMBER" == "") || ("$NBT_SERIALNUMBER" == "FFFFFFFFFFFF") || ("$NBT_SERIALNUMBER" == "ffffffffffff") ]]; then
               echo "ERROR: Could not read  serial number from adjustblock. Please update the ajustblock!"
               rSTAT=$((rSTAT + 1))
            fi
         fi
         
         if [[ $QUIET -eq 0 ]]; then
            echo "MAC_ADDRESS:      $MAC_ADDRESS"
            echo "BTMAC_ADDRESS:    $BTMAC_ADDRESS"
            echo "NBT_SERIALNUMBER: $NBT_SERIALNUMBER"
            ADJINFO_READY=1
         fi
      else
         if [[ -e /net/$JACINTO_HOST ]]; then
            echo "ERROR: No flash device $FILE_ADJ_DATA at jacinto available!"
         else
            echo "ERROR: No connection to jacinto /net/$JACINTO_HOST!"
         fi
         rSTAT=$((rSTAT + 1))
      fi
   fi
   return $rSTAT
}


kPartitionHdd()
{
   rSTAT=0
   rDEVICE=$1
   rSTART=1
   rEND=0
   shift
   echo "fdisk $rDEVICE delete -a"
   fdisk $rDEVICE delete -a || rSTAT=$((rSTAT + 1))
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      rEND=$((rSTART + $rSIZE - 1))
      echo "fdisk $rDEVICE add -t $rTYPE -c $rSTART,$rEND"
      fdisk $rDEVICE add -t $rTYPE -c $rSTART,$rEND || rSTAT=$((rSTAT + 1))
      rSTART=$((rEND + 1))
   done
   fdisk $rDEVICE show || rSTAT=$((rSTAT + 1))
   mount -e $rDEVICE || rSTAT=$((rSTAT + 1))
   return $rSTAT
}

kFormatHdd()
{
   rBS=$BLOCK_SIZE
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      echo "mkqnx6fs -q -b$rBS ${rDEVICE}t$rTYPE"
      mkqnx6fs -q -b$rBS ${rDEVICE}t$rTYPE || rSTAT=$((rSTAT + 1))
   done
   return $rSTAT
}

kMountHdd()
{
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      
      if [[ -e $rMP ]]; then
         if [[ $QUIET -eq 0 ]]; then
            echo "INFO: mount point $rMP already exist!"
         fi
      else
         if [[ $QUIET -eq 0 ]]; then
            echo "mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP"
         fi
         if [[ -e /dev/hd0t180 && -e /dev/hd0t179 && -e /dev/hd0t178 && -e /dev/hd0t177 ]]; then
            mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP || rSTAT=$((rSTAT + 1))
         else
            echo "ERROR: Not all hdd partitions /dev/hd0t1xx could be found!"
            if [[ -e /net/$JACINTO_HOST ]]; then
               echo "Probably your hdd needs to be initalized."
               echo "Please set up your hdd by using the following command: "
               echo "create_hdd.sh -i"
            else
               echo "Probably your hdd is locked, but no adjust data to unlock the hdd is available."
               echo "The adjust block must have been flashed and"
               echo "qnet has to be established (see: /net/$JACINTO_HOST)."
            fi
            rSTAT=$((rSTAT + 1))
            exit $rSTAT
         fi
      fi
      
   done
   return $rSTAT
}

kReMountHdd()
{
   rSTAT=0
   rDEVICE=$1
   rMODE=$2
   shift; shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rNULL=$3
      rSIZE=$4
      shift; shift; shift; shift
      
      if [[ -e $rMP ]]; then
         if [[ $QUIET -eq 0 ]]; then
            echo "INFO: mount point $rMP already exist!"
         fi
      else
         if [[ $QUIET -eq 0 ]]; then
            echo "mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP"
         fi
         if [[ -e /dev/hd0t180 && -e /dev/hd0t179 && -e /dev/hd0t178 && -e /dev/hd0t177 ]]; then
            mount -t qnx6 -o $rMODE ${rDEVICE}t$rTYPE $rMP || rSTAT=$((rSTAT + 1))
         else
            echo "ERROR: Not all hdd partitions /dev/hd0t1xx could be found!"
            if [[ -e /net/$JACINTO_HOST ]]; then
               echo "Probably your hdd needs to be initalized."
               echo "Please set up your hdd by using the following command: "
               echo "create_hdd.sh -i"
            else
               echo "Probably your hdd is locked, but no adjust data to unlock the hdd is available."
               echo "The adjust block must have been flashed and"
               echo "qnet has to be established (see: /net/$JACINTO_HOST)."
            fi
            rSTAT=$((rSTAT + 1))
            exit $rSTAT
         fi
      fi
      
   done
   return $rSTAT
}
kUmountHdd()
{
   rSTAT=0
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      if [[ -e $rMP ]]; then
         if [[ $QUIET -eq 0 ]]; then
            echo "umount -f $rMP"
         fi
         umount -f $rMP || rSTAT=$((rSTAT + 1))
      else
         echo "WRANING: mountpoint $rMP not available"
      fi
   done
   return $rSTAT
}

kDirectoriesHdd()
{
   rSTAT=0
   rCURRDIR=$PWD
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      mount -u -o rw $rMP || rSTAT=$((rSTAT + 1))
      cd $rMP
      for rDIR in $DOMAIN_DIRS
      do
         if [[ $QUIET -eq 0 ]]; then
            echo "mkdir $rMP/$rDIR"
         fi
         mkdir -p $rDIR || rSTAT=$((rSTAT + 1))
      done      
      mount -u -o $rMODE $rMP || rSTAT=$((rSTAT + 1))
   done
   cd $rCURRDIR || rSTAT=$((rSTAT + 1))
   return $rSTAT
}

kCleanUp()
{
   rSTAT=0
   rCURRDIR=$PWD
   cd /dev/shmem
   rDEVICE=$1
   shift
   while [[ $# -gt 0 ]]
   do
      rTYPE=$1
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      mount -u -o rw $rMP || rSTAT=$((rSTAT + 1))
      if [[ $QUIET -eq 0 ]]; then
         echo "deleting 'rm -rf $rMP/*' ..."
      fi
      rm -rf $rMP/* || rSTAT=$((rSTAT + 1))
      mount -u -o $rMODE $rMP || rSTAT=$((rSTAT + 1))
   done
   cd $rCURRDIR || rSTAT=$((rSTAT + 1))
   return $rSTAT
}

kHddSecurity()
{
   rSTAT=0
   rDEVICE=$1
   
   type $HDDSECURITY >/dev/null 2>&1
   if [ $? -eq 0 ] ; then
      $HDDSECURITY -v -m ${rDEVICE} || rSTAT=$((rSTAT + 1))
   else
      echo "WARNING: $HDDSECURITY not found!"
   fi
   return $rSTAT
}

kNoSecurity()
{
   rSTAT=0
   rDEVICE=$1
   type $HDDSECURITY >/dev/null 2>&1
   if [ $? -eq 0 ] ; then
      getAdjInfo   
      if [ $? -eq 0 ] ; then
         $HDDSECURITY -d $MAC_ADDRESS,$BTMAC_ADDRESS,$NBT_SERIALNUMBER -m ${rDEVICE} >/dev/console 2>&1 
         if [ $? -gt 1 ]; then
            # return value 1 is no password to delete. 
            rSTAT=$((rSTAT + 1))
         fi
      fi
   else
      echo "WARNING: $HDDSECURITY not found!"
   fi
   return $rSTAT
}

kSecurity()
{
   rSTAT=0
   rDEVICE=$1
   type $HDDSECURITY >/dev/null 2>&1
   if [ $? -eq 0 ] ; then
      getAdjInfo   
      if [ $? -eq 0 ] ; then
         $HDDSECURITY -s $MAC_ADDRESS,$BTMAC_ADDRESS,$NBT_SERIALNUMBER -m ${rDEVICE} >/dev/console 2>&1 
         if [ $? -gt 1 ]; then
            # return value 1 is no password to delete. 
            rSTAT=$((rSTAT + 1))
         fi
      fi
   else
      echo "WARNING: $HDDSECURITY not found!"
   fi
   return $rSTAT
}

kHddUnlock()
{
   rSTAT=0
   rDEVICE=$1
   
   type $HDDSECURITY >/dev/null 2>&1
   if [ $? -eq 0 ] ; then
      getAdjInfo   
      if [ $? -eq 0 ] ; then
         $HDDSECURITY -u $MAC_ADDRESS,$BTMAC_ADDRESS,$NBT_SERIALNUMBER -m ${rDEVICE} >/dev/console 2>&1 
         rSTAT=$((rSTAT + $?))
      fi
   else
      echo "WARNING: $HDDSECURITY not found!"
   fi
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
      rMP=$2
      rMODE=$3
      rSIZE=$4
      shift; shift; shift; shift
      $CHKQNX6FS -svv ${rDEVICE}t$rTYPE  || rSTAT=$((rSTAT + 1))
      $CHKQNX6FS -vv ${rDEVICE}t$rTYPE  || rSTAT=$((rSTAT + 1))
   done
   
   return $rSTAT
}

kHelp()
{
   echo "usage $0 [-i] [-c <command> [ -c <command> ] ...]"
   echo "-i initalize the HDD partitions: create partiton table, make filesystems and add domain directories."
   echo "-m mount all partitons"
   echo "-R mount all partitons read only"
   echo "-W mount all partitons writeable"
   echo "-u umount all partitons"
   echo "-f check qnx6fs"
   echo "-p print hdd security status"
   echo "-d delete the hdd password"
   echo "-r clean up all writeable partitions"
   echo "-s set the hdd password"
   echo "-c <command>"
   echo "-q QUIET no messages exept errors."
   echo "commands:"
   echo "========="
   echo "partition:   create partiton table"
   echo "format:      make filesystems"
   echo "info:        info about partition definition"
   echo "mount:       mount filesystems"
   echo "umount:      umount filesystems"
   echo "hddsecurity: print hdd security status"
   echo "unlock:      unlock the hdd"
   echo "secure:      set the hdd password"
   echo "nosecure:    delete the hdd password"
   echo "directories: make domain directories on certain filesystems"
   echo "cleanup:     removes content in the writeable partitions: "
   echo "chkfs:       checks the qnx6 file system"
   echo "help:        print this help screen"
   echo "Commands are executed in the order specified on the command line."
   echo "Example: $0 -c partition -c format -c mount -c directories"
   echo
}

COMMANDLIST=""

# if there are no arguments
if [[ $# -lt 1 ]] ; then
   kHelp
   exit 0
fi

# parse command line
while getopts "b:fumic:hsdpqrRW" OPTION
do
   case $OPTION in
      b)
         BLOCK_SIZE=$OPTARG
         ;;
      f)
         COMMANDLIST="umount unlock hddsecurity chkfs mount"
         ;;
      i)
         COMMANDLIST="umount unlock partition format mount directories"
         ;;
      c)
         COMMANDLIST="$COMMANDLIST $OPTARG"
         ;;
      u)
         COMMANDLIST="umount"
         ;;
      m)
         COMMANDLIST="unlock mount"
         ;;
      R)
         COMMANDLIST="remount_r"
         ;;
      W)
         COMMANDLIST="remount_w"
         ;;
      p)
         COMMANDLIST="hddsecurity"
         ;;
      d)
         COMMANDLIST="unlock nosecure"
         ;;
      s)
         COMMANDLIST="secure"
         ;;
      r)
         COMMANDLIST="cleanup directories"
         ;;
      q)
         QUIET=1
         ;;
      h | *)
         kHelp
         exit 0
         ;;
   esac
done

# preset the partition sizes to 80GB hdd as fallback
DEF_DATA=$DEF_DATA_200GB
DEF_SHARE=$DEF_SHARE_200GB
DEF_MEDIA=$DEF_MEDIA_200GB
DEF_DEBUG=$DEF_DEBUG_200GB

type df >/dev/null 2>&1
if [ $? -ne 0 ] ; then
   echo "ERROR: Could not determine HDD size. The 'df' command is not available."
   exit 1
fi

# check size of $DEVICE
DF_OUTP=`df -k ${DEVICE}`

CUT_FRONT=${DF_OUTP#* }
CUT_BACK=`echo ${CUT_FRONT%%%* }`
HDD_SIZE=`echo ${CUT_BACK% * * *}`

if [[ $QUIET -eq 0 ]]; then
   echo "HDD size: ${HDD_SIZE} [kb]"
fi

if [[ ${HDD_SIZE} -lt ${HDD_SIZE_200GB} ]] ; then
   echo "ERROR: HDD size $HDD_SIZE cylinder are too small, expecting $HDD_SIZE_200GB cylinder or more!"
   exit 1
fi
if [[ $QUIET -eq 0 ]]; then
   echo "-------------------------"
   echo "$0 $VERSION"
   echo "-------------------------"
fi

for COMMAND in $COMMANDLIST
do
   if [[ $COMMAND == partition ]]; then
      kPartitionHdd $DEVICE $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
      rRETVAL=$((rRETVAL + $?))
   fi
   
   if [[ $COMMAND == format* ]]; then
      if [[ $COMMAND > format ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kFormatHdd $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else
         kFormatHdd $DEVICE $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi
   
   if [[ $COMMAND == info* ]]; then
      if [[ $COMMAND > info ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            echo $def
            rRETVAL=$((rRETVAL + $?))
         else
            echo "info not found ..."
            rRETVAL=1
         fi
      else   
         def_data=`getDef data`
         def_share=`getDef share`
         def_media=`getDef media`
         def_debug=`getDef debug`
         if [[ ! -z def_data ]] && [[ ! -z def_share ]] && [[ ! -z def_media ]] && [[ ! -z def_debug ]]; then
            echo $def_data
            echo $def_share
            echo $def_media
            echo $def_debug
         else
            echo "info not found ..."
            rRETVAL=1
         fi	
      fi
   fi

   if [[ $COMMAND == mount* ]]; then
      if [[ $COMMAND > mount ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kMountHdd $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kMountHdd $DEVICE $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == remount_r* ]]; then
      if [[ $COMMAND > remount_r ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kReMountHdd $DEVICE ro $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kReMountHdd $DEVICE ro $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == remount_w* ]]; then
      if [[ $COMMAND > remount_w ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kReMountHdd $DEVICE rw $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kReMountHdd $DEVICE rw $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == umount* ]]; then
      if [[ $COMMAND > umount ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kUmountHdd $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kUmountHdd $DEVICE $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == hddsecurity* ]]; then
      if [[ $COMMAND > hddsecurity ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kHddSecurity $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kHddSecurity $DEVICE
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == nosecure* ]]; then
      if [[ $COMMAND > nosecure ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ -z $def ]]; then
            rRETVAL=$((rRETVAL + 1))
            echo "ERROR: Wrong paraneters '$def'"
         fi
      else      
         kNoSecurity $DEVICE
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == secure* ]]; then
      if [[ $COMMAND > secure ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ -z $def ]]; then
            rRETVAL=$((rRETVAL + 1))
            echo "ERROR: Wrong paraneters '$def'"
         fi
      else      
         kSecurity $DEVICE
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == unlock* ]]; then
      if [[ $COMMAND > unlock ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            rRETVAL=$((rRETVAL + 1))
            echo "ERROR: Wrong paraneters '$def'"
         fi
      else      
         kHddUnlock $DEVICE
         if [ $? -gt 1 ]; then
            # return value 1 is no password to unlock. 
            rRETVAL=$((rRETVAL + $?))
         fi
      fi
   fi

   if [[ $COMMAND == chkfs* ]]; then
      if [[ $COMMAND > chkfs ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ ! -z $def ]]; then
            kChkfs $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else      
         kChkfs $DEVICE $DEF_DATA $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == directories* ]]; then
      if [[ $COMMAND > directories ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ $def == $DEF_DATA ]] || [[ $def == $DEF_SHARE ]];then
            kDirectoriesHdd $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else            
         kDirectoriesHdd $DEVICE $DEF_DATA $DEF_SHARE
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == cleanup* ]]; then
      if [[ $COMMAND > cleanup ]]; then
         def=`getDef ${COMMAND#*_}`
         if [[ $def == $DEF_MEDIA ]] || [[ $def == $DEF_SHARE ]] || [[ $def == $DEF_DEBUG ]];then
            kCleanUp $DEVICE $def
            rRETVAL=$((rRETVAL + $?))
         fi
      else            
         kCleanUp $DEVICE $DEF_SHARE $DEF_MEDIA $DEF_DEBUG
         rRETVAL=$((rRETVAL + $?))
      fi
   fi

   if [[ $COMMAND == help ]]; then
      kHelp
   fi
   
   if [[ $rRETVAL -ne 0 ]]; then
      echo "ERROR: $0 failed returnval=$rRETVAL!"
      exit $rRETVAL
   fi
done

if [[ $QUIET -eq 0 ]]; then
   echo "SUCCESS: $0 finished!"
fi
