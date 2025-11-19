#!/bin/sh

SUBSYSTEM=$(uname -n || $HOSTNAME)
SUBSYSTEM=${SUBSYSTEM#*-}

HWIDX0=0
HWIDX1=0
HWIDX2=0
HWIDX3=0
HWIDX4=0

# Wait for hardware registers to become available (for emulation)
MAX_WAIT=30
WAIT_COUNT=0
while [[ ! -e /dev/sysregs ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
   sleep 1
   WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [[ ! -e /dev/sysregs ]]; then
   # Hardware registers not available after waiting - return default for emulation
   echo 0
   exit 0
fi

if [[ "$SUBSYSTEM" == "jacinto" ]]; then
   # set variable gpios to input if necessary
   if [[ $(cat /dev/sysregs/DSP_LED_DIR) -eq 0x00000000 ]]; then
      SAVE_DSP_LED_DIR=$(cat /dev/sysregs/DSP_LED_DIR)
      echo 0x00000001>/dev/sysregs/DSP_LED_DIR
   fi
   if [[ $(cat /dev/sysregs/ARM_LED_DIR) -eq 0x00000000 ]]; then
      SAVE_ARM_LED_DIR=$(cat /dev/sysregs/ARM_LED_DIR)
      echo 0x00000001>/dev/sysregs/ARM_LED_DIR
   fi

   # determine the hardware index - wait for it to become available
   MAX_WAIT=30
   WAIT_COUNT=0
   while [[ ! -e /dev/sysregs/HW_ID0 ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
      sleep 1
      WAIT_COUNT=$((WAIT_COUNT + 1))
   done
   
   if [[ ! -e /dev/sysregs/HW_ID0 ]]; then
      # Hardware not available after waiting - return default value for emulation
      echo 0
      exit 0
   fi
   HWIDX0=$(($(cat /dev/sysregs/HW_ID0)))
   HWIDX1=$(($(cat /dev/sysregs/HW_ID1)))
   HWIDX2=$(($(cat /dev/sysregs/HW_ID2)))
   HWIDX3=$(($(cat /dev/sysregs/HW_ID3)))
   # ignore msb pin due to problems on rse targets
   # HWIDX4=$(($(cat /dev/sysregs/HW_ID4)))

   # check and reset gpios
   if [[ -n $SAVE_DSP_LED_DIR ]]; then
      if [[ $(cat /dev/sysregs/DSP_LED_DIR) -eq $SAVE_DSP_LED_DIR ]]; then
         exit 1
      fi
      echo $SAVE_DSP_LED_DIR>/dev/sysregs/DSP_LED_DIR
   fi
   if [[ -n $SAVE_ARM_LED_DIR ]]; then
      if [[ $(cat /dev/sysregs/ARM_LED_DIR) -eq $SAVE_ARM_LED_DIR ]]; then
         exit 1
      fi
      echo $SAVE_ARM_LED_DIR>/dev/sysregs/ARM_LED_DIR
   fi
elif [[ "$SUBSYSTEM" == "omap" ]]; then
   # determine the hardware index - wait for it to become available
   MAX_WAIT=30
   WAIT_COUNT=0
   while [[ ! -e /dev/sysregs/HW_IDX0 ]] && [[ $WAIT_COUNT -lt $MAX_WAIT ]]; do
      sleep 1
      WAIT_COUNT=$((WAIT_COUNT + 1))
   done
   
   if [[ ! -e /dev/sysregs/HW_IDX0 ]]; then
      # Hardware not available after waiting - return default value for emulation
      echo 0
      exit 0
   fi
   HWIDX0=$(($(cat /dev/sysregs/HW_IDX0)))
   HWIDX1=$(($(cat /dev/sysregs/HW_IDX1)))
   HWIDX2=$(($(cat /dev/sysregs/HW_IDX2)))
   HWIDX3=$(($(cat /dev/sysregs/HW_IDX3)))
   if [[ -e /dev/sysregs/HW_IDX4 ]]; then
      HWIDX4=$(($(cat /dev/sysregs/HW_IDX4)))
   fi
else
   # Unknown subsystem - return default value for emulation instead of failing
   echo 0
   exit 0
fi

echo $((2#$HWIDX4$HWIDX3$HWIDX2$HWIDX1$HWIDX0))

exit 0
