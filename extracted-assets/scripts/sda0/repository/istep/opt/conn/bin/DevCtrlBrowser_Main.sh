#!/bin/ksh
exec on -X aps=interaction -P /opt/conn/bin/DevCtrlBrowser_Main --bp=/opt/conn/data --bp=/var/opt/conn --mapDSCPBrowser.DSCPBrowser=DSCPBrowser_MAIN.DSCPBrowser --mapDSCPBrowserListener.DSCPBrowserListener=InternalListener_DSCPBrowser_MAIN.DSCPBrowserListener --heartbeat-interval=2
exit 1

