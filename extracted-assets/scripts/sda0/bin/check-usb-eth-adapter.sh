#!/bin/sh

#
# usb ethernet configuration script for NBTevo (on all qnx subsystems)
#
VERBOSE=0
DHCP_CONFIG_ONLY=0
STATIC_IP_CONF=0.0.0.0/32
SLEEP_DELAY=5
SLEEP_APP=sleep

# sleep $SLEEP_DELAY seconds before retry
whence -v $SLEEP_APP >/dev/null 2>&1
if [[ $? -ne 0 ]] ; then
   print_debug1 "ERROR: $SLEEP_APP is not available, using waitfor!"
   SLEEP_APP="waitfor"
fi


while getopts s:vdp: OPTION
   do
      case "$OPTION" in
         s) STATIC_IP_CONF=$OPTARG
            ;;
         v) ((VERBOSE++))
            ;;
         d) DHCP_CONFIG_ONLY=1
            ;;
         p) SLEEP_DELAY=$OPTARG
            ;;
         ?) echo "$0: usage: -s ip/prefix"
            echo " options: -s ip/prefix  ip adress and network prefix for static ip usage (e.g. 192.168.199.99/24)"
            echo "          -v            be verbose"
            echo "          -d            configure dhcp for upcoming usb interfaces only"
            echo "          -p            configure the pause in seconds between each retry."
            exit 2 
            ;;
      esac
   done
shift $OPTIND-1

print_debug1()
{
   if [[ VERBOSE -eq 1 ]]; then
      echo $1
   fi
}

print_debug2()
{
   if [[ VERBOSE -eq 2 ]]; then
      echo $1
   fi
}

# --------------------------------------------------------------------------
#  precondition:
#  wait for ip stack and usb stack
#
waitfor /dev/io-usb 10 || exit 1
waitfor /dev/socket 10 || exit 1

# --------------------------------------------------------------------------
#  check for usb-eth-adapter
#

DOONLYONCE=1
USB_ETH_ADAPTER_FOUND=0

# retry search of usb ethernet adapter until at least one is found
while [[ $USB_ETH_ADAPTER_FOUND -eq 0 ]]; do
   if [[ $DHCP_CONFIG_ONLY -eq 1 ]]; then
      #  check for usb-eth-adapter interface only
      if [[ -e /dev/io-net/en5 ]]; then
         USB_ETH_ADAPTER_FOUND=1
      fi
   else
      # search usb device for each bus and device number, start with busno=0 and devno=1
      DEVICE_SEARCH_FINISHED=0
      BUSNO=0
      DEVNO=1
      while [[ $DEVICE_SEARCH_FINISHED -eq 0 ]]; do
         # call usb for specific bus and device number and search for strings USB (to determine valid bus number) and Product (to determine valid device number)
         print_debug2 "check usb at busnum=$BUSNO and devnum=$DEVNO..."
         USB_OUTPUT=$(usb -b$BUSNO -d$DEVNO | grep -e "USB" -e "Product")
         if [[ -n $USB_OUTPUT ]]; then
            # USB output is not empty --> bus number valid!
            if [[ $USB_OUTPUT == *@(Product)* ]]; then
               # usb output contains Product entry --> check if this is a supported device
               case $USB_OUTPUT in
                  *"0x9500"* | *"0x9e00"*)
                     USB_ETH_ADAPTER_FOUND=1
                     DEVICE_SEARCH_FINISHED=1
                     print_debug1 "mount smsc9500 with options busnum=$BUSNO,devnum=$DEVNO,lan=5..."
                     mount -T io-pkt -obusnum=$BUSNO,devnum=$DEVNO,lan=5 devn-smsc9500.so || echo "mount of smsc9500 adapter failed!"
                     ;;
                  *"0x3c05"* | *"0x1a02"*)
                     USB_ETH_ADAPTER_FOUND=1
                     DEVICE_SEARCH_FINISHED=1
                     print_debug1 "mount asix with options busnum=$BUSNO,devnum=$DEVNO,phy_88772=0,lan=5..."
                     mount -T io-pkt -obusnum=$BUSNO,devnum=$DEVNO,phy_88772=0,lan=5 devn-asix.so || echo "mount of asix adapter failed!"
                     ;;
                  *"0x1720"* | *"0x7720"* | *"0x1040"*)
                     USB_ETH_ADAPTER_FOUND=1
                     DEVICE_SEARCH_FINISHED=1
                     print_debug1 "mount asix with options busnum=$BUSNO,devnum=$DEVNO,lan=5..."
                     mount -T io-pkt -obusnum=$BUSNO,devnum=$DEVNO,lan=5 devn-asix.so || echo "mount of asix adapter failed!"
                     ;;
                  *)
                     # device unknown or no ethernet adapter --> check next device number
                     ((DEVNO++))
                     ;;
               esac
            else
               # usb output contains no Product entry --> no devices at this bus number, check next bus number
               DEVNO=1
               ((BUSNO++))
            fi
         else
            # USB output is empty --> bus number invalid, finish searching for devices
            DEVICE_SEARCH_FINISHED=1
         fi
      done
   fi
   if [[ $USB_ETH_ADAPTER_FOUND -eq 0 ]]; then
      if [[ $DOONLYONCE -eq 1 ]]; then
         DOONLYONCE=0
         print_debug1 "no usb ethernet adapter found until now, checking next time in 5 seconds, continue startup..."
         echo "done" > /dev/shmem/check-usb-eth-adapter.done
      fi
      $SLEEP_APP $SLEEP_DELAY
   fi
done

if [[ $USB_ETH_ADAPTER_FOUND -eq 1 ]]; then
   if [[ $DHCP_CONFIG_ONLY -ne 1 ]]; then
      print_debug1 "configure en5 with ip $STATIC_IP_CONF..."
      if_up -r2 -p en5 && ifconfig en5 $STATIC_IP_CONF
      echo "done" > /dev/shmem/check-usb-eth-adapter.done
   fi
   print_debug1 "start dhcp.client for interface en5 with options unbt1..."
   dhcp.client -i en5 -unbt1 -H
   /fs/sda0/bin/date > /dev/shmem/check-usb-eth-adapter.dhcp.done
   echo "done" >> /dev/shmem/check-usb-eth-adapter.dhcp.done
fi

echo "done" > /dev/shmem/check-usb-eth-adapter.done
exit 0
