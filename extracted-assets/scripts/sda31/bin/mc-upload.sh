#!/bin/ksh
#
# Send "post mortem data" (esp. core files) to multicore console F
# Benefit is that the last version of the file is still on hdd if transmission should fail.
# Additional benefit is that files are usually stored with identical filenames so that the archive is "self-cleaning"
#
# Files get transferred via HBFileUpload (extractable with HBFileExtract on host).
#
# external programs used: ksh, sleep, mkdir, mv, ls, echo, nice, cp
# be sure to have these in path (should be /bin)
#
# more infos: stephan.knauss@harman.com, juergen.lorff@harman.com, sascha.morgenstern@harman.com, stefan.gaertner@harman.com
#
# 2011/05: New feature: Copy /var/dump to an attached USB stick (recursively). A directory "HBCoreUpload" has to be existant in root folder of USB device.
#
#set -x

# *** CONFIG ***
COREDIR_PREFIX=/var/dump
INITIALWAIT=20
ARCHIVE=0

# used for copying corefiles directly to an attached USB stick at startup
USB_COREDIR="HBCoreUpload"
LS_CMD="ls -d /mnt/umass*"
CP="/bin/cp"
CP_PARAMS="-c -r -s -f -V"
SLOG="/dev/console"


# *** SCRIPT ***
echo "Starting $0..." > $SLOG

export PATH=/bin


# start additional tracing here
if [[ ! -e /dev/srm ]]
then
   /opt/sys/bin/srm
fi
# on -X aps=softrt_SYS /opt/sys/bin/thogs -a -t -z -c -d 1000 -l 0.5  >/hbsystem/multicore/navi/z 2>/hbsystem/multicore/navi/z &
# on -X aps=softrt_SYS /bin/aps show -vv -l  >/hbsystem/multicore/navi/z 2>/hbsystem/multicore/navi/z &

sleep $INITIALWAIT

# First try that command to check the return value
TEMP=$($LS_CMD) > /dev/null 2>&1

# If command returns EOK, we check the contents of /mnt/umass*
if [[ $? -eq 0 ]]
then
   for MY_LINE in $($LS_CMD)
   do
      DESTPATH="$MY_LINE/$USB_COREDIR"
      if [[ -e $DESTPATH ]]
      then
         echo "$0: Copy $COREDIR_PREFIX to $DESTPATH" > $SLOG 2>&1
         FILESPEC="$COREDIR_PREFIX/*"
         $CP $CP_PARAMS $FILESPEC $DESTPATH > $SLOG 2>&1
      fi
   done
fi

sleep $INITIALWAIT

# In some rare cases the system was up and running, but HBFileUpload never connected to multicored. In those cases we now do retries.
# Additionally we set again a delay of 20ms between packets in order to not overload the multicored buffer.
while [[ $(pidin -p HBFileUpload -fa | grep -E [0-9]+) == "" ]]; do
   echo "$0: Starting HBFileUpload..." > $SLOG
   # even if starting in background is not needed, we still do it to get the PID much much easier. Otherwise we would have to call pidin again...
   /opt/sys/bin/HBFileUpload -v -D ${COREDIR_PREFIX} -r -i 5000 -d 20 &
   HBFILEUPLOADPID=$!
   echo "$0: HBFileUpload has PID $HBFILEUPLOADPID" > $SLOG
   sleep $INITIALWAIT
   ls /proc/$HBFILEUPLOADPID > /dev/null 2>&1
   if [[ $? -eq 0 ]]; then
      echo "$0: HBFileUpload seems to be running. Finished." > $SLOG
      break
   fi
   echo "$0: HBFileUpload failed to start -> retrying..." > $SLOG
done

exit 0
