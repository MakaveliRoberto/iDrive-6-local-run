#!/bin/ksh

# NEW TRACELOGGER BY MARTTI:
# You can use the modified kernel that I sent to you already some time ago, and that you already integrated into an image for me.
#
# ktb_alloc is the process that allocates a shared buffer. It should be started first and never terminated. It allocates the buffer, tells us the physical address and then just sleeps holding the allocation and waiting for a signal. (ktb is by the way Kernel Trace buffer)
#
# You can all it like this: ktb_alloc -t /memory/below4G/ram/dma/sysram -o /tmp/traceaddr
# Where:
#        -k number of buffers (default is 32)
#        -o file where the physical address of the buffer will be written
#        -t name of the typed memory to use
#
# However, the user interface has changed:
# 1) Tracelogger –p doesn’t accept file names any more. You have to give it a number. This mean that you’ll probably need to wrap it in a small  script to pass the buffer address in.
# 2) The –a option in trace logger was rejected. Instead I wrote a completely separate program ktb_dump, to dump the trace buffer contents into a file. The resulting file has enough header data to enable the tracelog-fixer to ‘fix” it and make it usable with our standard trace tools. Usage: ktb_dumper -p phys_address -o output_path [-k buffer_count]


SLOG="/dev/console"

echo "$0: started with parameter $1" > $SLOG

# Wait until some early KPIs are over.
# exp. HU:  Jan 01 00:00:29.907    6 20000     0 Interface [09]: 'AVAIL' '/proc/mount/dev/cputemp'
# exp. RSE: Jan 01 00:00:42.217    6 20000     0 Interface [11]: 'AVAIL' '/proc/mount/dev/cputemp'
if [[ $1 == "hu" ]]; then
   /bin/sleep 30
else
   /bin/sleep 18
fi

if [[ $1 == "hu" || $1 == "rse" ]]; then                                   # check for valid parameters
   if [[ $(pidin -p tracelogger -fa | grep -E [0-9]+) == "" ]]; then       # check if tracelogger is already running
      if [[ -e /boot/bin/ktb_alloc ]]; then
         /boot/bin/ktb_alloc -t /memory/below4G/ram/dma/sysram -o /dev/shmem/traceaddr &
         waitfor /dev/never/appears 0.5
         TRACE_ADDR=$(/bin/cat /dev/shmem/traceaddr)                       # get the content of traceaddr file written by ktb_alloc
         /boot/bin/tracelogger -r -p $TRACE_ADDR &                         # start kerneltrace
         echo "$0: tracelogger executed [PID=$!, args=-r -p $TRACE_ADDR]." > $SLOG
         waitfor /net/$1-jacinto/dev/shmem 5                               # ensure that the other node is ready
         if [[ $? -eq 0 ]]; then
            echo "$0: QNET available. Copying ktb_alloc's output file." > $SLOG
            cp -f /dev/shmem/traceaddr /net/$1-jacinto/dev/shmem           # copy the ktb_alloc output file to J5
            if [[ $? -eq 0 ]]; then
               echo "Copying pidin dump to J5 to have all PIDs available." > $SLOG
               /bin/pidin -F %8a,%8e,%35N,%4b,%65h,%p,%J,%B,%z,%H > /net/$1-jacinto/dev/shmem/omap_pidin.log
               if [[ $? -eq 0 ]]; then
                  echo "$0: Success." > $SLOG
                  RETVAL=0
               else
                  echo "$0: Couldn't copy pidin dump to J5. Not fatal..." > $SLOG
                  RETVAL=6
               fi
            else
               echo "$0: Couldn't copy the file to the other node, even if QNET was available." > $SLOG
               RETVAL=1
            fi
         else
            echo "$0: QNET not available. Can't copy ktb_alloc's output file." > $SLOG
            RETVAL=2
         fi
      else
         echo "$0: ktb_alloc not available, unable to start kerneltrace." > $SLOG
         RETVAL=3
      fi
   else
      echo "$0: Kerneltrace already running. Skipping." > $SLOG
      RETVAL=4
   fi
else
   echo "$0: Invalid parameter." > $SLOG
   RETVAL=5
fi

exit $RETVAL

