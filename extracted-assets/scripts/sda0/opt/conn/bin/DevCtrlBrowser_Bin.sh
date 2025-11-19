#!/bin/ksh
exec on -X aps=interaction -P /opt/conn/bin/DevCtrlBrowser_Bin --bp=/opt/conn/data --bp=/var/opt/conn --mapDSCPBrowser.DSCPBrowser=DSCPBrowser_BIN.DSCPBrowser --mapDSCPBrowserListener.DSCPBrowserListener=InternalListener_DSCPBrowser_BIN.DSCPBrowserListener --heartbeat-interval=2
exit 1

