#!/bin/ksh

# Documentation are available at http://confluence.hbi.ad.harman.com/confluence/display/BMWNBT/Collect+information+from+cars
if [ $# -ne 1 ]
then
	echo "Usage: collect_cardata.sh <target directory>"
	echo "Script aborted"
	exit 1
fi

NODE=`uname -n`
NODE=${NODE%%-*}
CPU=`uname -n`
CPU=${CPU##*-}

SERIALNUMBER=`adjinfo --get=E2P.ProdLogistic.SerialNo 2> /dev/null`
if [[ $? != 0 ]] 
then
	echo "collect_cardata.sh: no adjustblock found"
	echo "Script aborted"
	exit 1
fi

# strip down to sn
SERIALNUMBER=`echo $SERIALNUMBER | cut -c27-46`



OUTPUTDIR=$1/${SERIALNUMBER}
mkdir -p ${OUTPUTDIR}
if [ $? -ne 0 ]
then
	echo "collect_cardata.sh: Error: Unable to create directory ${OUTPUTDIR}"
	echo "collect_cardata.sh: Script aborted"
	exit 1
fi

# Correct path name to have a fully qualified network path
OUTPUTDIR=`fullpath ${OUTPUTDIR}`
OUTPUTDIR=/net/${NODE}-${CPU}/${OUTPUTDIR}
RUNLOG=${OUTPUTDIR}/protocol.txt

echo "collect_cardata.sh started" > ${RUNLOG}

function runOn
{
   targetCPU=$1
   outputFile=$2
   shift
   shift
   commandLine=$*
   
   echo "runOn: $CPU required $targetCPU command $commandLine" >> ${RUNLOG}
   
   if [[ $CPU != $targetCPU ]]
   then
      # prepend the on statement
      commandLine="on -f $NODE-$targetCPU $commandLine"
   fi

   echo "runOn: > $commandLine <" >> ${RUNLOG}
   $commandLine > $OUTPUTDIR/$outputFile 2> /dev/null
   echo "runOn: finished with exit code $?" >> ${RUNLOG}
}

if [[ $NODE == "hu" ]]
then
   # Headunit specific
   runOn omap     readsmart.txt                    /bin/readsmart -v -d /dev/hd0
   runOn omap     conEventLogging.bin              cat /mnt/share/conn/conEventLogging.bin
fi   

if [[ $NODE == "rse" ]]
then
   runOn omap     conEventLogging_RSE.bin          cat /mnt/share/conn/conEventLogging_RSE.bin
fi   

# General part
runOn jacinto  nbt_version_jacinto.txt    cat /etc/nbt_version.txt
runOn omap     nbt_version_omap.txt       cat /opt/sys/etc/nbt_version.txt
runOn $CPU     device_type.txt            echo $NODE

# Clocks
runOn jacinto  car_date_jacnito.txt       date
runOn omap     car_date_omap.txt          date

# Open ports
runOn jacinto  sockstat_ln_jacinto.txt    sockstat -ln
runOn omap     sockstat_ln_omap.txt       sockstat -ln

# Increasing files?
runOn jacinto  ls_lR_var_jacinto.txt      ls -lR /var/
runOn omap     ls_lR_var_omap.txt         ls -lR /var/

runOn jacinto  filesize_jacinto_nor.txt   find /var/  -printf "%p;%s\n"
runOn omap     filesize_omap_nand.txt     find /var/  -printf "%p;%s\n"

if [[ $NODE == "hu" ]]
then
   runOn omap  filesize_omap_hdd_share.txt      find /mnt/share/  -printf "%p;%s\n"
   runOn omap  filesize_omap_hdd_quota.txt      find /mnt/quota/  -printf "%p;%s\n"
   runOn omap  filesize_omap_hdd_data.txt       find /mnt/data/  -printf "%p;%s\n"
fi   

runOn jacinto  df_jacinto.txt             df -k
runOn omap     df_omap.txt                df -k

# Navigation
runOn omap     nav_db.ini                 cat /mnt/data/nav/nav_db.ini

runOn omap     pidin_omap.txt             pidin -F '%a;%b;%65h;%40N;%p;%J;%B;%H'
runOn jacinto  pidin_jacinto.txt          pidin -F '%a;%b;%65h;%40N;%p;%J;%B'

# Reclaim Infos
runOn jacinto  flashctl_i_jacinto_var.txt flashctl -i -p /var/
echo "getresets\nexit\n" | sysetshell --connect   > ${OUTPUTDIR}/sysetshell_getresets_count.txt    2> /dev/null 


runOn jacinto adjinfo_dump.txt            adjinfo --dump

echo "collect_cardata.sh completed" >> ${RUNLOG}
echo "collect_cardata.sh: Finished."
exit 0
