#!/bin/sh

#CARPLAY_FLAG_FILE=/var/opt/sys/CARPLAY_USB_ON
MEDIALAUNCH_APP="/opt/sys/bin/evo-medialaunch"
HUUMASSCFG=/etc/umass-enum.cfg

function medialaunch_ssp
{
   echo "INFO: medialaunch_ssp"
   ARGS="-z -x port=0,port=1 -f /etc/umass-enum.cfg -C -H hub_detect,maxhubs=4 -d -vv"
}

#function medialaunch_app_hu_usb_carplay
#{
#   echo "INFO: medialaunch_app_hu_usb_carplay"
#   ARGS="-b -F -z -x port=0,port=1 -L dos,hfs,nt,cd -f /etc/umass-enum_carplay.cfg -E -C -H hub_detect,maxhubs=4 -d -vv -O nbt"
#}

#function medialaunch_app_hu_2100mA_usb_carplay
#{
#   echo "INFO: medialaunch_app_hu_2100mA_usb_carplay"
#   ARGS="-b -F -z -x port=0,port=1 -L dos,hfs,nt,cd -f /etc/umass-enum_carplay.cfg -E -C -H hub_detect,maxhubs=4 -d -vv -O mib"
#}

function portpower
{
    case "$1" in
        "2100MA")
            echo "2100"
            ;;
        "1500MA")
            # intentionally 1000, as apple devices don't know how to handle 1500
            echo "1000"
            ;;
        "1000MA")
            echo "1000"
            ;;
        *)
            echo "$2"
            ;;
    esac
}

function medialaunch_app_hu_2100mA
{
   echo "INFO: medialaunch_app_hu"
   CODING=$(sysetshellevo --noconnect << EOF | grep VALUE | cut -f 2 -d ' '
getc EXBOX.USB_HUB_AVAIL
getc EXBOX.USB_MAX_CHARGING_CURRENT
exit
EOF
)
   P1="1000"
   P2="500"
   PORT=$(echo "$CODING"|while read line; do echo $line; break; done)
   POWER=$(echo "$CODING"|tail -1)
   case $PORT in
      HUB_ON_USB1)
          P1=$(portpower $POWER $P1)
          ;;
      HUB_ON_USB2)
          P2=$(portpower $POWER $P2)
          ;;
   esac
   ARGS="-b -F -z -x port=0,port=1 -L dos,hfs,nt,cd -f "$HUUMASSCFG" -C -H hub_detect,maxhubs=4 -d -vv -O nbtevo,port1=$P1,port2=$P2"
}

function medialaunch_app_rse
{
   echo "INFO: medialaunch_app_rse"
   ARGS="-F -b -z -x port=0,port=1 -L dos,hfs,nt,cd -f /etc/umass-enum.cfg -C -H hub_detect,maxhubs=4 -d -vv -O mib"
}

function medialaunch_bolo
{
   echo "INFO: medialaunch_app_bolo"
   ARGS="-z -x port=0,port=1 -L dos,hfs,nt,cd -f /etc/umass-enum.cfg -C -H hub_detect,maxhubs=4 -d -vv"
}

case $1 in
   ssp)
      medialaunch_ssp
      ;;
   hu)
#      if [[ -e $CARPLAY_FLAG_FILE ]] ; then
#         medialaunch_app_hu_usb_carplay
#      else
         medialaunch_app_hu_2100mA
#      fi
      ;;
   hu_2100mA)
#      if [[ -e $CARPLAY_FLAG_FILE ]] ; then
#         medialaunch_app_hu_2100mA_usb_carplay
#      else
         HUUMASSCFG=/etc/umass-enum_2100mA.cfg
         medialaunch_app_hu_2100mA
#      fi
      ;;
   rse)
      medialaunch_app_rse
      ;;
   bolo)
      medialaunch_bolo
      ;;
   *)
      echo "ERROR: Wrong parameter $1\n"
      exit 1
      ;;
esac


#echo "$MEDIALAUNCH_APP $ARGS"
#echo "$MEDIALAUNCH_APP $ARGS" >/dev/console
exec $MEDIALAUNCH_APP $ARGS
exit $?
