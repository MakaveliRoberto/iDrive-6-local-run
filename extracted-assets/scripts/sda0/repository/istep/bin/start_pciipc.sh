#!/bin/sh

ifconfig veom0 160.48.199.254/30 up

if [[ $(if_up -p veom0) -ne 0 ]]; then
   ifconfig veom0 160.48.199.254/30 up
fi

echo "done" > /dev/shmem/start_net.done

exit 0
