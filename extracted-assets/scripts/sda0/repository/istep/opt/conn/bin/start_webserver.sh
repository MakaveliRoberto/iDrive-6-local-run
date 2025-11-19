#! /bin/sh

export PATH=$PATH:/opt/conn/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/conn/lib:/opt/conn/lib/browser

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

# temp directory for webserver is on Hard Disk Drive
SHAREDIR=/mnt/share

# need share directory for our webserver
while [ ! -e $SHAREDIR ]; do
  logMsg "Waiting for $SHAREDIR on HDD..."
  waitfor $SHAREDIR 60 2>&1 > /dev/null
done

# some directories must exist. We should test if they are there before we try to create them.
TMPWEBSERVER=$SHAREDIR/conn/tmp-webserver
checkAndCreateDirectory $TMPWEBSERVER

# clean up any temporary webserver files from previous lifecycles
if [ -d $TMPWEBSERVER ]; then
   rm -rf $TMPWEBSERVER/*
fi

# The temporary directory of lighttpd is configured in lighttpd.conf
# The temporary directory of php-cgi is configured through TMPDIR
export TMPDIR=$TMPWEBSERVER

# Link to Online Entertainment Coverart
if [[ ! -e /mnt/share/conn/AppFS/oe ]] ; then
   ln -sP /mnt/quota/mm/OnlineEntertainment/Coverart /mnt/share/conn/AppFS/oe
fi

# Link to PluginFS
if [[ ! -e /mnt/share/conn/AppFS/PluginFS ]] ; then
	ln -sP /mnt/share/conn/PluginFS /mnt/share/conn/AppFS/PluginFS
fi


#check if lighttpd is already running. If not start it from here
LOGFILE=/dev/shmem/lighttpd_error.log
if [ ! -f $LOGFILE ]; then
	# Start Lighttpd for DAB Journaline, Internal Log & Trace downloading, ...
	logMsg "Starting lighttpd Web Server..."
	/opt/conn/bin/lighttpd -f /opt/conn/etc/lighttpd-nbt.conf -m /opt/conn/lib &

	if [ -f /hbsystem/multicore/navi/h ]; then
		logMsg "Starting IPCEServer with logging"
		exec /opt/conn/bin/IPCEServer -f /opt/conn/etc/ipce.cfg
	else
		logMsg "Starting IPCEServer without logging"
		exec /opt/conn/bin/IPCEServer -f /opt/conn/etc/ipce_no_logging.cfg
	fi
	
else
	logMsg "CONN: lighttpd Web Server is already running..."
fi

# we should never get here
return 1
