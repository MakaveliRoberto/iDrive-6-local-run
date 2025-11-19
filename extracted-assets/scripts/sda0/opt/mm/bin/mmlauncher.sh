#!/bin/ksh

# ----------------------------------------------------------------------
#   Project    : Harman Car Multimedia System
#   Harman/becker Automotive Systems GmbH
#   All rights reserved
#
#   File      : mmlauncher.sh
#   Author    : JLorff
# ----------------------------------------------------------------------
LOGGING_PATH=/dev/console
export LD_LIBRARY_PATH=/opt/mm/lib:/opt/conn/foreignLibs:${LD_LIBRARY_PATH}
if [[ "$HOSTNAME" == "hu-omap" ]] ; then
   # HU
   if [[ -f /mnt/data/mm/gracenote/db/content.xml ]] ; then
      exec /opt/mm/bin/mmlauncher -c /opt/mm/etc/mmlauncher_B069.cfg -v --heartbeat-interval=2 --tp=/opt/mm/bin/mmlauncher.hbtc >$LOGGING_PATH 2>&1
   else
      exec /opt/mm/bin/mmlauncher -c /opt/mm/etc/mmlauncher_B069_without_gracenote.cfg -v --heartbeat-interval=2 --tp=/opt/mm/bin/mmlauncher.hbtc >$LOGGING_PATH 2>&1
   fi
else
   # RSE
   exec /opt/mm/bin/mmlauncher -c /opt/mm/etc/mmlauncher_B075.cfg -v --heartbeat-interval=2 --tp=/opt/mm/bin/mmlauncher.hbtc >$LOGGING_PATH 2>&1
fi

exit 1
