#! /bin/sh

export PATH=$PATH:/opt/car/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/car/lib:/opt/conn/lib/browser

SLOG=/dev/console

logMsg()
{
   echo "$0: $*" > $SLOG
}

checkAndCreateDirectory()
{
   if [ -e $1 ]; then
      if [ ! -d $1 ]; then
         logMsg "Warning: $1 not a directory!"
         rm -f $1 2>&1 > $SLOG
      fi
   fi

   if [ ! -d $1 ]; then
      logMsg "Creating directory $1"
      mkdir -p $1 2>&1 > $SLOG
   fi
}


# Set up download for Internal Log & Trace file download as well as for sheenshots (in /mnt/quota/sys/core/)
# The downloadable files must be in /mnt/quota/sys/trace/ and /mnt/quota/sys/core/
# The HEADER.txt (which beautifies the directory listing for /mnt/quota/sys/trace/ and /mnt/quota/sys/core/)
# must be in /opt/car/data/trace

HEADERFILE=/opt/car/data/trace/HEADER.txt

if [ -f $HEADERFILE ]; then
   if [ -e /mnt/quota/sys ]; then
      # create directories if necessary
      checkAndCreateDirectory /mnt/quota/sys/trace
      checkAndCreateDirectory /mnt/quota/sys/core
      
      cp -sfu $HEADERFILE /mnt/quota/sys/trace/ 2>&1 > $SLOG
      cp -sfu $HEADERFILE /mnt/quota/sys/core/ 2>&1 > $SLOG
   fi
else
   logMsg "Warning: File $HEADERFILE not found. Internal trace & core download affected."
fi


TRACE=/opt/car/data/trace/Trace.tr
TRACE_BOLO=/opt/car/data/trace/Trace_bolo.tr

if [ -f $TRACE ]; then
   if [ -e /mnt/quota/sys ]; then
      # create directories if necessary
      checkAndCreateDirectory /mnt/quota/sys/trace/ioc
      
      cp -sfu $TRACE /mnt/quota/sys/trace/ioc/ 2>&1 > $SLOG
      cp -sfu $TRACE_BOLO /mnt/quota/sys/trace/ioc/ 2>&1 > $SLOG
   fi
else
   logMsg "Warning: File $TRACE or $TRACEB1 not found."
fi


# Start Lighttpd for DAB Journaline, Internal Log & Trace downloading, ...
logMsg "Starting lighttpd Web Server..."
exec lighttpd -f /opt/car/etc/lighttpd-nbt.conf -m /opt/car/lib

# we should never get here
return 1
