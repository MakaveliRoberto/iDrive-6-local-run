#!/bin/sh

ONOFF_IPC_CHANNEL=/dev/ipc/ipc2

log_msg()
{
	echo "$0: $1"
   echo "$0: $1" > /dev/console
}

# Modified for emulation: accept any hostname, default to non-OMAP mode
if [[ $HOSTNAME == "hu-omap" ]]; then
   OMAP=1
   JACINTO_NODE=hu-jacinto
elif [[ $HOSTNAME == "rse-omap" ]]; then
   OMAP=1
   JACINTO_NODE=rse-jacinto
elif [[ $HOSTNAME == *"omap"* ]]; then
   # Accept any hostname containing "omap" for compatibility
   OMAP=1
   JACINTO_NODE=hu-jacinto
else
   # Default to non-OMAP mode for emulation (will use local IPC)
   OMAP=0
fi

if [[ $OMAP -eq 1 ]]; then
   ONOFF_IPC_CHANNEL=/net/${JACINTO_NODE}$ONOFF_IPC_CHANNEL
fi

# Make sure that OnOff IPC channel is open...
if [[ ! -e $ONOFF_IPC_CHANNEL ]]; then
   
   log_msg "OnOff IPC channel $ONOFF_IPC_CHANNEL not available!"
   log_msg "Starting OnOff IPC channel first..."
   
   # Start appropriate resource manager. Concrete choice depends on IPC Protocol Version used by V850.
   whence ipc-version-check > /dev/null
   if [[ $? -ne 0 ]]; then
      log_msg "Failed to locate ipc-version-check!"
      exit 1
   fi
   
   ipc-version-check   
   IPC_VERSION=$?
   
   case "$IPC_VERSION" in
      0) # Initial IPC
         START_ONOFF_IPC_CHANNEL="dev-spi-dra6xx -v -c /etc/spi3.cfg"
         ;;
      1) # IPC V1 - Block IPC on Jacinto
         START_ONOFF_IPC_CHANNEL="io-ipc -c /etc/io-ipc-j5.cfg"
         ;;
      2) # IPC V2 - Block IPC on Jacinto and OMAP
         START_ONOFF_IPC_CHANNEL="io-ipc -c /etc/io-ipc-v2-j5.cfg"
         ;;
      *) log_msg "Unknown IPC Version $IPC_VERSION - unable to start OnOff IPC channel!"
         exit 2
         ;;
   esac

   if [[ $OMAP -eq 1 ]]; then
      log_msg "Starting IPC resource manager on $JACINTO_NODE ..."
      log_msg "$START_ONOFF_IPC_CHANNEL"
      on -f /net/$JACINTO_NODE $START_ONOFF_IPC_CHANNEL
   else
      log_msg "Starting IPC resource manager ..."
      log_msg "$START_ONOFF_IPC_CHANNEL"
      $START_ONOFF_IPC_CHANNEL
   fi
   
   waitfor $ONOFF_IPC_CHANNEL 10
   if [[ ! -e $ONOFF_IPC_CHANNEL ]]; then
      log_msg "Failed to start IPC resource manager!"
      exit 3
   fi
   
fi

# ... then execute v850commander (may run on any node)
log_msg "Executing v850commander $* ..."
exec v850commander $*

log_msg "Failed to execute v850commander!"

exit 4
