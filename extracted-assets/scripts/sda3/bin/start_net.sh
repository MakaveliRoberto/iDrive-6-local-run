#!/bin/ksh

ADJREAD=sysetadjread

display_msg()
{
    echo "$1"
}

determineHWIdx()
{
   if [[ -n $INTERNAL_O5HW_INDEX ]]; then
      hwidx=$((16#$INTERNAL_O5HW_INDEX))     # hexadecimal to decimal
      echo $hwidx
      return $hwidx
   fi
   
   whence hwidx.sh > /dev/null
   if [[ $? -eq 0 ]]; then
      hwidx=$(hwidx.sh)
      if [[ $? -eq 0 ]]; then
         echo $hwidx
         return $hwidx
      fi
   fi
   
   # fallback solution if hwidx.sh fails
   HW_REV=$(if-test ksh -c "echo \${HW_REV}") # get the HW_REV string
   hwidx=${HW_REV##*,0x}                      # truncate beginning until 0x found
   hwidx=${hwidx%%,*}                         # truncate ending from the next ,
   hwidx=$((0x$hwidx))                        # interpret hex value as decimal value
   echo $hwidx
   return $hwidx
}

check_mac_address()
{
   if [[ (-n $MAC_ADDRESS) && (${#MAC_ADDRESS} == 12) && ("$MAC_ADDRESS" != "FFFFFFFFFFFF") && ("$MAC_ADDRESS" != "ffffffffffff") && ("$MAC_ADDRESS" != "000000000000") ]]; then
      return 1
   fi
   
   return 0
}

determine_mac_address()
{
   check_mac_address
   
   if [[ $? == 1 ]]; then
      echo "INFO: Retrieved MAC address $MAC_ADDRESS!"
      return
   fi
   
   # MAC_ADDRESS not valid - get value from adjust data
   MAC_ADDRESS="FFFFFFFFFFFF"
   type $ADJREAD >/dev/null 2>&1
   if [ $? -ne 0 ] ; then
      echo "ERROR: Could not find $ADJREAD!"
   else
      ADJINFO=$($ADJREAD --get=E2P.Networking.Eth0MacAddr)
      if [[ $? -eq 0 ]]; then
         MAC_ADDRESS="${ADJINFO##E2P.Networking.Eth0MacAddr=}"
         if [[ "$MAC_ADDRESS" == "$ADJINFO" ]]; then
            echo "ERROR: invalid adjust data!"
         fi
      fi
   fi
   
   check_mac_address
   
   if [[ $? == 1 ]] ; then
      echo "INFO: Retrieved MAC address $MAC_ADDRESS from adjdata!"
   else
      echo "ERROR: Could not read valid MAC-Address from adjustblock ($MAC_ADDRESS). Please update the ajustblock!"
      # read omap5 - Wafer and die unique identifier // WAFERUID
      ID0=$(in32 0x4A002200)
      ID0=${ID0##* : }
      # read omap5 - Wafer fab and lot unique identifier
      ID2=$(in32 0x4A002208)
      ID2=${ID2##* : }
      ID3=`echo ${ID0}${ID2} | crc32`
      # MAC => "00+WAFERUID[0]+CRC32" 
      MAC_ADDRESS=00${ID0#??????}$ID3
      echo "INFO: Fake MAC-Address is $MAC_ADDRESS!"
   fi
}

determine_mac_address

# check HW revision
# check HW revision
HWIDX=$(determineHWIdx)

if [[ $HWIDX -ge 12 ]] ; then  # FPLANE
    # todo remove when available in sysregs/ipl
    # activate Gigabit Ethernet
    out32 0x5e40f0d4 0x1
fi

display_msg "starting DWC Ethernet interface with MAC_ADDRESS: $MAC_ADDRESS ..."
mount -T io-pkt -o speed=1000,duplex=1,mac=$MAC_ADDRESS devnp-dwcmac.so
if_up -p -r 10 dwc0

ifconfig dwc0 up
if_up -p -l dwc0 || echo "##### WARNING: dwcmac link status is not going to be up! #####"

mount -T io-pkt -o if=dwc0,ip=169.254.199.119,debug,delay=200,force lsm-autoip.so
  
display_msg "VLAN 0x49 is activated ..."
ifconfig vlan73 create vlan 73 vlanif dwc0 160.48.199.119/25 up
display_msg "VLAN 0x4D is activated ..."
ifconfig vlan77 create vlan 77 vlanif dwc0 up
display_msg "VLAN 0x56 is activated ..."
ifconfig vlan86 create vlan 86 vlanif dwc0 up
display_msg "VLAN 0x50 is activated ..."
ifconfig vlan80 create vlan 80 vlanif dwc0 160.48.199.185/29 up

if [[ "$BOOTMODE" != "EMERGENCY" ]]; then
   #IPv6 for Online
   ifconfig vlan77 inet6 alias 2a03:1e80:a00:4d01::E1/64
fi

if [[ "$BOOTMODE" != "EMERGENCY" ]]; then
   #add route for multicast
   route add -net 224.0.0.0/4 160.48.199.119
   echo "224.0.0.0/4 160.48.199.119" > /dev/shmem/multicast_route.txt
fi
   
# only start dhcp.client in SSP-only mode
if [[ "$BOOTMODE" == "EMERGENCY" ]]; then
   dhcp.client -i dwc0 -unabt1 -H &
elif [[ ! -e /var/opt/sys/ETH_CTL ]]; then
   echo "" > /var/opt/sys/ETH_CTL
fi
     

echo "done" > /dev/shmem/start_net.done

if [[ "$BOOTMODE" != "EMERGENCY" ]]; then
   # --------------------------------------------------------------------------
   # (mandatory for Online) enable ip forwarding
   #
   display_msg "enable ip forwarding..."
   sysctl -w net.inet6.ip6.forwarding=1 net.inet.ip.forwarding=1 > /dev/null
   #Hack Servicebrokerproblem (Online / Connectivity)
   route add 160.48.199.249 160.48.199.38
   route add 160.48.199.250 160.48.199.118
fi

exit 0
