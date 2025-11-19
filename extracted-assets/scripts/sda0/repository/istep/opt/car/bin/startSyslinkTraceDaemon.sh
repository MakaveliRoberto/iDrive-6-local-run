#!/bin/sh

echo " Start syslink_trace_daemon when multicore is available "
echo " Wait for /proc/mount/hbsystem/multicore "
#waitfor /proc/mount/hbsystem/multicore

while [[ ! -e /proc/mount/hbsystem/multicore ]]
do
    waitfor /dev/never/appears 1
    cat /dev/syslink-trace2 >> /var/dump/tmp/SyslinkTraces.txt
done

echo " Multicore available. Cat /var/dump/tmp/SyslinkTraces.txt to multicore"
cat /dev/syslink-trace2 >> /var/dump/tmp/SyslinkTraces.txt
cat /var/dump/tmp/SyslinkTraces.txt > /hbsystem/multicore/custom/1

echo "Start syslink_trace_daemon with output to multicore"
/bin/syslink_trace_daemon -l /hbsystem/multicore/custom/1

echo "Remove temporary file /var/dump/tmp/SyslinkTraces.txt"
rm /var/dump/tmp/SyslinkTraces.txt

exit 0