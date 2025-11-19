#!/bin/sh

value=$(cat /var/dump/save/Lifecycle.log | cut -f2 -d":" | cut -f2 -d" ")

/opt/core/bin/omapconf-qnx dump prcm > /var/log/omapconf-qnx_dump_prcm_$value.log
/opt/core/bin/omapconf-qnx show prcm > /var/log/omapconf-qnx_show_prcm_$value.log
/opt/core/bin/omapconf-qnx dump dpll > /var/log/omapconf-qnx_dump_dpll_$value.log

return 0