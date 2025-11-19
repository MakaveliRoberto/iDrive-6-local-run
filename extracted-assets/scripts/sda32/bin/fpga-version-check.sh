#!/bin/sh

VERSION=V1.0.4

LATEST_VIRTEX=000006A2
LATEST_ARTIX=00008025
LATEST_ASIC=01000000 # version info of asic

function print_msg
{
   if [[ $QUIET -ne 1 ]]; then
      echo "$1"
      echo "$1" >/dev/console
   fi
}

print_msg "$0: $VERSION"

function determineHWIdx
{
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

if [[ $HWIDX -le 5 ]] ; then # VIRTEX6
   LATEST_FPGA=$LATEST_VIRTEX
elif [[ $HWIDX -ge 12 ]] ; then # FPLANE
   LATEST_FPGA=$LATEST_ARTIX
else # ASIC
   LATEST_FPGA=$LATEST_ASIC # version info of asic
fi

FPGA_TO_CHECK=$LATEST_FPGA

while getopts d:q OPTION
   do
      case "$OPTION" in
         d) FPGA_TO_CHECK=$OPTARG
            ;;
         q) QUIET=1
            ;;
         ?) echo "$0: usage: [-d datecode] [-q]"
            echo " options: -d datecode      datecode of the fpga to check (e.g 000001C8)"
            echo " options: -q               be quiet"
            exit 2 
            ;;
      esac
   done
shift $OPTIND-1

print_msg "check FPGA version..."

# Wait for hardware to become available (for emulation)
MAX_WAIT=30
WAIT_COUNT=0
while [[ ! -e /bin/in32 && ! -e /boot/bin/in32 && ! -e /dev/sysregs/FPGA_VERSION ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
   sleep 1
   WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [[ ! -e /bin/in32 && ! -e /boot/bin/in32 && ! -e /dev/sysregs/FPGA_VERSION ]]; then
   print_msg "WARNING: Could not determine FPGA version due to missing binary in32 or sysregs register /dev/sysregs/FPGA_VERSION!"
   print_msg "INFO: Running in emulation mode - skipping FPGA check"
   exit 0
fi

if [[ -e /dev/sysregs/FPGA_VERSION ]] ; then 
   FLASHED_FPGA=$(cat /dev/sysregs/FPGA_VERSION)
else
   if command -v in32 >/dev/null 2>&1; then
      RESULT=$(in32 0x5e40F018)
      FLASHED_FPGA=0x${RESULT##5e40f018 : }
   else
      # Emulation mode - use default FPGA version
      print_msg "INFO: Hardware not available - using default FPGA version for emulation"
      FLASHED_FPGA=$LATEST_FPGA
   fi
fi

print_msg "FPGA version: $FLASHED_FPGA"
if [[ 0x$FPGA_TO_CHECK -gt $FLASHED_FPGA ]]; then
   print_msg "\033[1;37;41mWARNING: Your FPGA (ver. $FLASHED_FPGA) is not up to date. Please update your FPGA at least to ver. $FPGA_TO_CHECK! \033[0m"
   exit 1
fi

if [[ -e /dev/sysregs/FPGA_GOLD_LOADED ]] ; then
   # Test is gold FPGA is loaded
   FPGA_GOLD_LOADED=$(cat /dev/sysregs/FPGA_GOLD_LOADED)
   if [[ $FPGA_GOLD_LOADED -eq 1 ]]; then
      print_msg "\033[1;37;41mWARNING: Your running FPGA is the emergency FPGA!                                   \033[0m"
      print_msg "\033[1;37;41m         Please update the application FPGA by flashing 'flashomap.sh -c fpga_appl'!\033[0m"
      # no exit 1 due to problably not starting sw parts if -d option is used.
   fi
fi

exit 0
