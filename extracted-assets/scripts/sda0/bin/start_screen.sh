#!/bin/sh 

# Start QNX screen resource manager with a coding-dependent graphics configuration

CONFIGFILE=${GRAPHICS_ROOT}/graphics.conf
DEFAULT_RESOLUTION_CID="1280_480"
DEFAULT_RESOLUTION_RSE="800_480"
SYSLOG=/dev/console

log_info()
{
   echo "start_screen: INFO: $*" > $SYSLOG
}

log_warning()
{
   WARNINGMSG="start_screen: WARNING: $*"
   echo "$WARNINGMSG"
   echo "$WARNINGMSG" > $SYSLOG
}

log_error()
{
   ERRORMSG="start_screen: ERROR: $*"
   echo "$ERRORMSG"
   echo "$ERRORMSG" > $SYSLOG
}

get_display_resolution_head_unit()
{
   if [[ -z $CID_DISPLAY_RES ]]; then
      log_warning "CID_DISPLAY_RES not set, defaulting to resolution of ${DEFAULT_RESOLUTION_CID}!"
      RESOLUTION=$DEFAULT_RESOLUTION_CID
   else
      case $CID_DISPLAY_RES in
      01 )
         RESOLUTION="800_480"
         ;;
      02 )
         RESOLUTION="1280_480"
         ;;
      03 )
         RESOLUTION="1440_540"
         ;;
      04 )
         RESOLUTION="1600_600"
         ;;
      05 )
         RESOLUTION="1920_720"
         ;;
      * )
         log_warning "Invalid CID_DISPLAY_RES=${CID_DISPLAY_RES}, defaulting to resolution of ${DEFAULT_RESOLUTION_CID}!"
         RESOLUTION=$DEFAULT_RESOLUTION_CID
         ;;
      esac
      
      log_info "CID_DISPLAY_RES=${CID_DISPLAY_RES} -> RESOLUTION=${RESOLUTION}"
   fi      
}

get_display_resolution_rse()
{
   if [[ -z $RSE_DISPLAY_RES ]]; then
      log_warning "RSE_DISPLAY_RES not set, defaulting to resolution of ${DEFAULT_RESOLUTION_RSE}!"
      RESOLUTION=$DEFAULT_RESOLUTION_RSE
   else
      case $RSE_DISPLAY_RES in
      01 )
         RESOLUTION="800_480"
         ;;
      02 )
         RESOLUTION="1280_720"
         ;;
      * )
         log_warning "Invalid RSE_DISPLAY_RES=${RSE_DISPLAY_RES}, defaulting to resolution of ${DEFAULT_RESOLUTION_RSE}!"
         RESOLUTION=$DEFAULT_RESOLUTION_RSE
         ;;
      esac
      
      log_info "RSE_DISPLAY_RES=${RSE_DISPLAY_RES} -> RESOLUTION=${RESOLUTION}"      
   fi      
}

#create a symbolic links for libcapture-soc-omap4-5.so to let Multimedia stuff load it properly
if [[ ! -e /lib/libcapture.so ]]; then
   ln -sP /lib/libcapture-soc-omap4-5.so /lib/libcapture.so
fi
if [[ ! -e /lib/libcapture.so.1 ]]; then
   ln -sP /lib/libcapture-soc-omap4-5.so /lib/libcapture.so.1
fi

if [[ -e $CONFIGFILE ]]; then
   log_info "$CONFIGFILE already exists"
else
   if [[ "$HOSTNAME" == "hu-omap" ]]; then
      get_display_resolution_head_unit
   elif [[ "$HOSTNAME" == "rse-omap" ]]; then
      get_display_resolution_rse
   else
      log_error "Invalid HOSTNAME=${HOSTNAME}!"
      exit 1
   fi
   
   # do create symbolic link in RAM (option -P) to resolution-dependent graphics config
   CONCRETE_CONFIGFILE="${GRAPHICS_ROOT}/graphics-${RESOLUTION}.conf"
   if [[ -e $CONCRETE_CONFIGFILE ]]; then
      log_info "Creating procmgr symlink to $CONCRETE_CONFIGFILE"
      ln -sP $CONCRETE_CONFIGFILE $CONFIGFILE
   else
      log_error "Resolution-dependent configfile $CONCRETE_CONFIGFILE does not exist! Giving up..."
      exit 2
   fi
fi

exec screen $*

# we should never get here
exit 3
