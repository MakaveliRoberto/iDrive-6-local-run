#!/bin/ksh

if [ -e $1 ] ; then
   echo "[$0].INFO: remove $1" >/dev/console
   rm -f $1
   if [ ! $? -eq 0 ] ; then
      echo "[$0].ERROR: Failed to delete $1!" >/dev/console
   fi
fi
if [ -z $2 ] ; then
   echo "[$0].WARNING: No link to do!" >/dev/console
else
   echo "[$0].INFO: create link $2 -> $1!" >/dev/console
   ln -sP $2 $1
   if [ $? -ne 0 ] ; then
      echo "[$0].ERROR: Failed to create link $2 -> $1!" >/dev/console
      exit 1
   fi
fi

exit 0
