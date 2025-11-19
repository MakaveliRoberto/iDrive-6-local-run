#!/bin/sh

MAX_RETRIES=20
I2C_RESOURCE="/dev/i2c/i2c_0/usb1_pwr"
LATEST_USB2SATA_VERSION=FW_v1.04


function clear_OC
{
   retval=0
   retries=0
   
   if [[ -e $I2C_RESOURCE ]] ; then
      echo "clear OC usb 1 with dummy read to usb charger"
      while [[ $retries -lt $MAX_RETRIES ]] ;
      do
         i2ctool -d $I2C_RESOURCE -r 0x10
         if [[ $? -eq 0 ]] ; then
            echo "INFO: usb charger initalized!"
            return 0
         else
            sleep 1
         fi
         retries=$((retries + 1))
      done
   else
      # echo "INFO: No I2C configuration to initalize the usb charger! That is not a failure just a hint!"
      return 0
   fi
   return 1
}

function determineHWIdx
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

# check HW revision
HWIDX=$(determineHWIdx)

io-usb -c -vvv -d omap5-xhci ioport=0x4a030000,irq=124,verbose=5 -d hb-ehci-omap3 ioport=0x4a064c00,irq=109,verbose=5,num_itd=256,portd   &
waitfor /dev/io-usb/io-usb 10


# turn on usb hub for asic and f-plane modules
if [[ -e /dev/sysregs/USB_HUB_RST_CLR ]]; then
   echo 0x00000001 > /dev/sysregs/USB_HUB_RST_CLR
fi

if [[ -e /dev/sysregs/USB_SATA_BRIDGE_RST_CLR ]]; then
   echo 0x00000001 > /dev/sysregs/USB_SATA_BRIDGE_RST_CLR
fi


if [[ -e /dev/sysregs/H_USBH_NRESET ]]; then

   #Bx HW only
   echo 0x00000001 > /dev/sysregs/H_USBH_NRESET
   
   # for reworked boards (complete USB rework)  <remark> Optional provision to clock USB hub "USB84604" from OMAP internal clock-signal (instead of using external crystal oscillator at hub) - not used at the moment. </remark>  
   # for original boards with R5803 assembled, testing OMAP internal clock-signal
   # switch pinmux back to auxclk0
   # echo 0x05000500 > /dev/sysregs/PINMUX
   # and enable clock
   # echo 0x00070104 > /dev/sysregs/USB_CLOCK
fi

# turn on usb power supplies   
if [[ -e /dev/sysregs/USB1_PWR_ON_SET ]]; then
   echo "switch usb 1 power VBUS on"  >/dev/console
   echo 0x00000001 >/dev/sysregs/USB1_PWR_ON_SET
fi   
if [[ -e /dev/sysregs/USB2_PWR_ON_SET  ]]; then
   echo "switch usb 2 power VBUS on"  >/dev/console
   echo 0x00000001 >/dev/sysregs/USB2_PWR_ON_SET 
fi
if [[ -e /dev/sysregs/H_USBH_NRESET ]]; then  
   #Bx HW only
   clear_OC
fi

# configure devb-umass for dvd support on f-plane samples only
if [[ -e /dev/sysregs/USB_SATA_BRIDGE ]]; then
   sleep 2
   if [[ $(usb |grep -c .) -gt 2 ]]; then
      cd_dev=$(usb)
      cd_tmp=$cd_dev
      cd_tmp=${cd_tmp%% \(Texas *}
      cd_tmp=${cd_tmp##*: }
      # echo "tmp cd $cd_tmp"
      if [[ $cd_tmp -eq 0x0451 ]]; then
		 tmp2=${cd_dev:##*: 0x0451}
		 echo Vendor: 0x0451 ${tmp2%%Class*} >/dev/console
         cd_dev=${cd_dev%%: 0x0451*}
         cd_dev=${cd_dev%Vendor*}
         cd_dev=${cd_dev##*: }
         # echo "device no=$cd_dev"
         devb-umass mem name=/ram/dma cam cache,async,resmgr,verbose=1 blk cache=1m,vnode=256,delwri=2,marking=none,noatime umass ign_remove,vid=0x451,did=0x9261,busno=1,port=2,devno=$cd_dev udf verify=none cdrom timeout=30:30:30:30,retries=3
         
         USB2SATA_VERSION=$tmp2
         USB2SATA_VERSION=${USB2SATA_VERSION#*TUSB9261 }
         USB2SATA_VERSION=${USB2SATA_VERSION%%)*}
         if [[ $USB2SATA_VERSION != $LATEST_USB2SATA_VERSION ]] ; then
            echo "\033[1;37;41mWARNING: The USB2SATA bridge has an old firmware $USB2SATA_VERSION!  \033[0m\n         \033[1;37;41mPlease update the usb2sata bridge to $LATEST_USB2SATA_VERSION by call: flashusb2sata.sh \033[0m" >/dev/console
            echo "\033[1;37;41mWARNING: The USB2SATA bridge has an old firmware $USB2SATA_VERSION!  \033[0m\n         \033[1;37;41mPlease update the usb2sata bridge to $LATEST_USB2SATA_VERSION by call: flashusb2sata.sh \033[0m"
         fi
      fi
   fi
else
   #in case of F-Plane write a error message 
   if [[ $HWIDX -gt 11 ]] ; then
      echo "\033[1;37;41mWARNING: no usb2sata bridge \033[0m\n" >/dev/console
      echo "\033[1;37;41mWARNING: no usb2sata bridge \033[0m\n"
   fi
fi

# take ACP out of reset
echo 0x00000001 > /dev/sysregs/AppleAuthRst_CLR

echo "done" > /dev/shmem/start_usb.done
exit 0
