#!/bin/ksh

LOGFILE=""
CONTINUOUS_LOGGING=0           # variable used to stop the loop
CONTINUOUS_LOGGING_PERIOD=5    # seconds

OUTPUTDIR=$1
USECASE=$2
PARAM_CONTINUOUS=0
FOUND=0
SCRIPT_RUNNING=0
# enumeration of possible dump modes
DUMP_BASIC=0
DUMP_FULL=1

if [[ $# > 0 ]] #path
then
   OUTPUTDIR=$1
   if [[ $# > 1 ]] #UseCase || -c
   then
      if [[ $2 == "-c" ]]
      then         
         PARAM_CONTINUOUS=$2 # -c
         #echo "Continous logging enabled"
      else
         USECASE=$2 # usecase
      fi
      if [[ $# > 2 ]] # -c || logging period
      then         
         if [[ $3 == "-c" ]]
         then
            PARAM_CONTINUOUS=$3 # -c
            #echo "Continous logging enabled"
         else         
            CONTINUOUS_LOGGING_PERIOD=$3 # logging period
            #echo "Logging period set to $CONTINUOUS_LOGGING_PERIOD"
         fi
         if [[ $# > 3 ]] # ogging period
         then
            CONTINUOUS_LOGGING_PERIOD=$4 # logging period
            #echo "Logging period set to $CONTINUOUS_LOGGING_PERIOD"
         fi
      fi
   fi
fi

function PrintError # <message>
{
   MESSAGE=$*

   if [[ $LOGFILE == "" ]]
   then
      echo "FATAL ERROR: no logfile is set"
      exit 2
   fi
   
   if [[ $MESSAGE == "" ]]
   then
      echo "FATAL ERROR: no message"
      exit 2
   fi

   echo "Error: $MESSAGE" 
   echo "Error: $MESSAGE" >> $LOGFILE
}

function PrintInfo # <message>
{
   MESSAGE=$*

   if [[ $LOGFILE == "" ]]
   then
      echo "FATAL ERROR: no logfile is set"
      exit 2
   fi
   
   if [[ $MESSAGE == "" ]]
   then
      echo "FATAL ERROR: no message"
      exit 2
   fi

   echo "Info : $MESSAGE" 
   echo "Info : $MESSAGE" >> $LOGFILE
}

function ScriptAbort # <message>
{
   MESSAGE=$*

   PrintError $MESSAGE
   echo "Script aborted!"
   echo "Script aborted!" >> $LOGFILE
   exit 1
}

# Check if srm has been started already, if not do solution
# needed by:
#   - heapinfo
function CheckAndRunSRM # <hostname>
{
   net_name=$1
         
   if [[ $net_name == $HOSTNAME ]]; then
      if [[ ! -e /dev/srm/status ]]; then
         $path_to_srm 2> /dev/null

         if [[ $? -ne 0 ]]
         then
            PrintInfo "Unable to start $path_to_srm on local host"
         fi
      fi
   else
      if [[ ! -e /net/$net_name/dev/srm/status ]]; then
         on -f $net_name $path_to_srm 2> /dev/null

         if [[ $? -ne 0 ]]
         then
            PrintInfo "Unable to start $path_to_srm on $net_name"
         fi
      fi
   fi
}

function DumpData # <output-directory> <unittype> <hwtype> <processor> <usecase> <whattodump>
{
   outputdir=$1
   unittype=$2
   hwtype=$3
   processor=$4
   usecase=$5
   whattodump=$6
   
   PrintInfo "......Dump processor $unittype, $processor, $usecase"

   BASEPATH=$outputdir/$hwtype/Logs
   NETNAME=$unittype-$processor
   
   if [[ ! -e /net/$NETNAME ]]
   then
      ScriptAbort "Unable to find host $unittype-$processor"      
   fi   
   
   mkdir -p $BASEPATH
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to create target directory"
   fi
   
   path_to_srm="srm"
   path_to_showmem="showmem"      
  
   CheckAndRunSRM $NETNAME
   
   # Dump pidins
   # -- args
   on -f $NETNAME pidin arg > $BASEPATH/pidin-arg-$processor-$usecase.txt
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to execute pidin args"
   fi

   # -- Mem
   on -f $NETNAME pidin mem > $BASEPATH/pidin-mem-$processor-$usecase.txt
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to execute pidin mem"
   fi

   # -- Aps (OMAP only)
   if [[ $processor == "omap" ]]
   then
      on -f $NETNAME pidin -F "%a|%30N|%b|%30h|%H" > $BASEPATH/pidin-aps-$processor-$usecase.txt
      if [[ $? -ne 0 ]]
      then
         ScriptAbort "Unable to execute pidin aps"
      fi
   fi

   # -- Info
   on -f $NETNAME pidin info > $BASEPATH/pidin-info-$processor-$usecase.txt
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to execute pidin info"
   fi

   # Dump showmem
   on -f $NETNAME $path_to_showmem -Dlsh > $BASEPATH/mem-$processor-Dslh-$usecase.txt
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to execute $path_to_showmem "
   fi
   # Append(!) /dev/shmem regular files into showmem output
   on -f $NETNAME ls -lad /net/$NETNAME/dev/shmem/* >> $BASEPATH/mem-$processor-Dslh-$usecase.txt
   
   servicebrokermode=Master
   if [[ $processor == "jacinto" ]]
   then
      servicebrokermode=Slave
   fi

   if [[ $processor == "omap" ]]
   then
      servicebrokermode=Master

      # -- software version
      if [[ -e /opt/sys/etc/nbt_version.txt ]]
      then
         cp -f -t /opt/sys/etc/nbt_version.txt $BASEPATH/
      else
         PrintInfo "... nbt_version.txt not found"
      fi

      # -- VRAM 
      pidin_g -n $NETNAME mapinfo > $BASEPATH/vram-$processor-$usecase.txt
      
   fi # if [[ $processor == "omap" ]]

   # Dump servicebroker.cfg
   cp -f -t /etc/servicebroker.cfg               $BASEPATH/servicebroker_omap.cfg
   cp -f -t /net/$NETNAME/etc/servicebroker.cfg  $BASEPATH/servicebroker_jacinto.cfg
   
   cat  /net/$NETNAME/srv/servicebroker  > $BASEPATH/servicebroker-$servicebrokermode-$usecase.txt
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to execute cat on servicebroker"
   fi
   
   # copy text file which contains information about configured memory reserve
   if [[ -e /opt/sys/etc/memory_reserve.txt ]]
   then
      cp -f -t /opt/sys/etc/memory_reserve.txt $BASEPATH/
   else
      PrintInfo "... memory_reserve.txt not found"
   fi
   
   # OMAP VRAM statistics (according to Dennis Fu, QNX, this is purely screen internal debug information)
   if [[ $processor == "omap" ]]
   then
      on -f $NETNAME cat /dev/screen/mem > $BASEPATH/dev-screen-mem-$processor-$usecase.txt
      if [[ $? -ne 0 ]]
      then
         PrintInfo "... error creating $processor VRAM statistics"
      fi
   fi
   
   # Files in shared memory /dev/shmem
   #  R: Recursively list all subdirectories encountered
   #  a: List all files, including hidden ones
   #  g: List in long format, but don't show owner
   #  o: List in long format, but don't show group
   #  S: Don't sort the output (to make it faster)
   on -f $NETNAME ls -RagoS /dev/shmem > $BASEPATH/shmem-$processor-$usecase.txt 2> $BASEPATH/shmem-$processor-$usecase-err.txt
   if [[ $? -ne 0 ]]
   then
      PrintInfo "... error during dump of /dev/shmem on $processor"
   fi      
   
   # OMAP only: heapinfo will be dumped into directory Logs/heapinfo
   #             only in DUMP_FULL mode
   #if [[ $processor == "omap" && $whattodump == $DUMP_FULL ]]
   #then
   #   PrintInfo "... Dump heapinfo on $processor"
   #   HEAPINFOS_PATH=$BASEPATH/heapinfo
   #   mkdir -p $HEAPINFOS_PATH
   #   
   #   # variable contains list of pids (process names may not be unique!)
   #   pids=`on -f $NETNAME pidin -F "%a"`
   #   
   #   for pid in $pids
   #   do       
   #      if [[ $pid != "pid" ]]
   #      then 
   #         # $processname will contain strings like '/procnto-smp-instr', 'boot/bin/sysinit' so we need to find out the short process name
   #         pidinprocessname=`on -f $NETNAME pidin -F "%30N" -p $pid`
   #         for processname in $pidinprocessname
   #         do
   #            if [[ $processname != "name" ]]
   #            then
   #               shortprocessname=`echo "$processname" | sed 's/^\(\/*.*\)\/\(.*\.*\)$/\2/'`  # 'name ' was generated by pidin
   #               if  [[ $shortprocessname != "(Zombie)" ]]
   #               then                     
   #                  # echo "$NETNAME: '$processname' -> '$shortprocessname' ($pid)"
   #                  on -f $NETNAME heapinfo -p $pid > $HEAPINFOS_PATH/heapinfo-$processor-$usecase-$shortprocessname-$pid.txt
   #               fi
   #            fi # [[ $processname != "name" ]]
   #         done
   #      fi  # [[ $pid != "pid" ]]
   #   done
   #fi

}
# signal handler for CTRL-C (SIGINT)
# used for stopping the loop of continous memory logging
# we use this to avoid incomplete log files
function signalHandlerINT
{
   echo "\nPlease wait ..." # use echo (not PrintInfo) to not write to log file
   CONTINUOUS_LOGGING=0
   FOUND=0
}

# CAUTION: This function only returns on CTRL-C !!!!
function DumpMemContinuous # <output-directory> <unittype> <hwtype> <processor> <usecase>
{
   outputdir=$1
   unittype=$2
   hwtype=$3
   processor=$4
   usecase=$5

   PrintInfo "Every $CONTINUOUS_LOGGING_PERIOD sec: reporting memory $unittype, $processor, $usecase ..."
   echo "  Press CTRL-C to stop"
   
   BASEPATH=$outputdir/$hwtype/Logs/continuous
   NETNAME=$unittype-$processor
   
   if [[ ! -e /net/$NETNAME ]]
   then
      ScriptAbort "Unable to find host $unittype-$processor"      
   fi   
   
   mkdir -p $BASEPATH
   if [[ $? -ne 0 ]]
   then
      ScriptAbort "Unable to create target directory"
   fi

   path_to_srm="srm"
   path_to_showmem="showmem"      
   
   # Not needed anymore to start srm because showmem is used from QNX delivery
   # CheckAndRunSRM $NETNAME
   
   typeset -i loopcnt # allow arithmetic calculations for loopcnt
   loopcnt=1
   
   CONTINUOUS_LOGGING=1
   trap signalHandlerINT INT # install the SIGINT handler
   while [ $CONTINUOUS_LOGGING -eq 1 ] # only CTRL-C (which generates SIGINT) can stop this loop
   do      
      echo -n "\rloop: $loopcnt"  # use echo (not PrintInfo) to not write to log file
      echo Creating Showmem mem-$processor-$usecase-$loopcnt.txt > /dev/console
      # showmem of all processes
      on -f $NETNAME $path_to_showmem -Dlsh > $BASEPATH/mem-$processor-$usecase-$loopcnt.txt
      # Free memory
      pidin -n $NETNAME info > $BASEPATH/pidin-info-$processor-$usecase-$loopcnt.txt
      # files in /dev/shmem
      on -f $NETNAME ls -lad /net/$NETNAME/dev/shmem/* >> $BASEPATH/mem-$processor-$usecase-$loopcnt.txt
      # VRAM
      pidin_g -n $NETNAME mapinfo > $BASEPATH/vram-$processor-$usecase-$loopcnt.txt
      
      loopcnt=$loopcnt+1
      sleep $CONTINUOUS_LOGGING_PERIOD
   done
   # delete files from the last loop because very often they are incomplete
   loopcnt=$loopcnt-1
   rm -f $BASEPATH/mem-$processor-$usecase-$loopcnt.txt
   rm -f $BASEPATH/vram-$processor-$usecase-$loopcnt.txt
   PrintInfo "... $loopcnt loops"
   echo "\n"
   
} # end of function DumpMemContinuous

function ShowUseCases
{
   count=1; 
   echo "######################################"
   if [[ $PARAM_CONTINUOUS == "-c" ]] 
   then
   echo "# This script is running continously"
   echo "# every $CONTINUOUS_LOGGING_PERIOD seconds."
   echo "# "
   echo "# Press CTRL+C to interrupt."
   fi
   echo "# Availabe usecases, press"   
   echo "# -----------------------------------"   
   for usecaselement in ${VALID_USECASES[*]}
   do
      echo "# $count for $usecaselement "      
      count=$(( $count + 1 ))
   done
   echo "# -----------------------------------"   
   echo "# or press any other key to exit:"
   echo "> \c"
   
}

function checkForHU35UP
{
    # detection of HU 35up is done by eval of Coding HMI.HMI_VERSION == ID5

    echo "Detecting HU type (hu or hu35up)... please wait... "
    SYSETSHELL=sysetshellevo
    
    type $SYSETSHELL >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
       echo "\n ERROR: Could not find $SYSETSHELL\n"
    else        
        SYSET_OUTPUT=$($SYSETSHELL) <<EOF
   getc HMI.HMI_VERSION
   exit
EOF

        if [ $? -ne 0 ] ; then
            echo "\n Error returned by $SYSETSHELL \n"
        else
            SYSET_OUTPUT=$(echo $SYSET_OUTPUT|grep VALUE) 
            SYSET_OUTPUT=${SYSET_OUTPUT##* VALUE: }
            SYSET_OUTPUT=${SYSET_OUTPUT%% *}
            
            #echo "HMI.HMI_VERSION='$SYSET_OUTPUT'"
            if [[ $SYSET_OUTPUT == "ID5" ]]; then
                HWTYPE=$HWTYPE"35up"
            fi
            #echo $HWTYPE
        fi
    fi
    
    echo "Detected '$HWTYPE'"
}

function runScript
{
   if [[ $OUTPUTDIR != ""  &&  $FOUND == 0 ]]
   then
      ShowUseCases
      read input
      FOUND=1      
      SCRIPT_RUNNING=1
      
      # Exit if user pressed the wrong key
      if [[ !$input -gt 0 && !$input -lt $SIZE_OF_USECASES ]]
      then         
         echo "bye!"
         exit 1
      fi
      
      USECASE=${VALID_USECASES[$input-1]}   
      echo " starting usecase  $USECASE"   

   fi   
      
   if [[ $FOUND -eq 0 ]]
   then
      echo "Usage: <output-directory> [usecase] [-c]" 
      echo "  The usecase description is stored under 'https://confluence.harman.com/confluence/display/NBTEVO/Memory'."
      echo "  Please visit the link for further information."
      echo "   <output-directory>: This directory will be used as a target for all collected informations."
      echo "   [usecase]: Leave usecase blank to get a list of all availabe use cases, else the usecase must be named to ensure the correct naming and later analyse "
      echo "   -c: Optional: Enable periodic memory reporting every $CONTINUOUS_LOGGING_PERIOD seconds"
      exit 1
   fi
      

   LOGFILE=$OUTPUTDIR/DumpInfo_$USECASE.log
   rm -f $LOGFILE
   PrintInfo "Dumping information for usecase $USECASE"

   PrintInfo "... Dump $UNITTYPE"
   
   if [[ $PARAM_CONTINUOUS == "-c" ]]
   then
      # make sure that basic data exists, even if target crashes during continuous measurement
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE omap $USECASE $DUMP_BASIC
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE jacinto $USECASE $DUMP_BASIC

      # continuous periodic reporting of memory usage
      # CAUTION: function DumpMemContinuous returns only if CTRL-C pressed !!!
      DumpMemContinuous $OUTPUTDIR $UNITTYPE $HWTYPE omap $USECASE
      
      # Overwrite the DumpData from before the continous measurement
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE omap $USECASE $DUMP_FULL
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE jacinto $USECASE $DUMP_FULL         
   else
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE omap $USECASE $DUMP_FULL
      DumpData $OUTPUTDIR $UNITTYPE $HWTYPE jacinto $USECASE $DUMP_FULL            
   fi
}

UNITTYPE=${HOSTNAME%%-*}
HWTYPE=$UNITTYPE
if [[ $UNITTYPE == "hu" ]]; then
VALID_USECASES[0]=HU_Startup 
VALID_USECASES[1]=HU_Entertainment
VALID_USECASES[2]=HU_Tuner
VALID_USECASES[3]=HU_Navigation
VALID_USECASES[4]=HU_Speech
VALID_USECASES[5]=HU_Connectivity
VALID_USECASES[6]=HU_Online
VALID_USECASES[7]=HU_FullLoad
SIZE_OF_USECASES=${#VALID_USECASES[*]}
checkForHU35UP
elif [[ $UNITTYPE == "rse" ]]; then
VALID_USECASES[0]=RSE_Startup 
VALID_USECASES[1]=RSE_Entertainment
VALID_USECASES[2]=RSE_Navigation
VALID_USECASES[3]=RSE_Connectivity
VALID_USECASES[4]=RSE_Online
VALID_USECASES[5]=RSE_FullLoad
SIZE_OF_USECASES=${#VALID_USECASES[*]}
else
   echo "\n\n--> failed to detect unit type (hu or rse). Aborted.\n\n"
   exit 1
fi

for usecaselement in ${VALID_USECASES[*]}
do
   if [[ $USECASE == $usecaselement ]]
   then
      FOUND=1
   fi
done

runScript

while [ $SCRIPT_RUNNING -eq 1 ]
do
   FOUND=0
   runScript
done


PrintInfo "Done"
exit 0
