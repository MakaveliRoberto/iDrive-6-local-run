#! /bin/sh

cat /opt/conn/etc/lighttpd-nbt-cfg-full.cfg

# If TraceClient multicore exists, activate logging
if [ -f /hbsystem/multicore/navi/h ]; then
	cat /opt/conn/etc/lighttpd-logging.cfg
fi

return 0
