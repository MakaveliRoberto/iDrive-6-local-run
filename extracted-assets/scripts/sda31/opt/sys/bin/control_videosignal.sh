#!/bin/ksh

echo "\nEVO Control_videosignal 2014-01-15 \n"

# -fbas 1..4 [ -right | -left ]
# -mhl [ -right | -left ]
# -restore
# -help

argument=''
parameter=''
display=0;
vp_in=0;

display_left=0;
display_right=0;

if [ $# -eq 0 ]
then
	argument=HELP  
else
	while [ $# -ne 0 ] 
		do
		case $1 in
			-fbas)
				argument=FBAS
				shift
				case $1 in
					1)
						parameter=0
						;;
					2)
						parameter=1
						;;
					3)
						parameter=2
						;;
					4)
						parameter=3
						;;                  
					*)
						argument=HELP
						break
						;;
				esac
				;;
			-restore)
				argument=RESTORE
				break
				;;
			-mhl)
				argument=MHL
				;;
			-left)
				display=0;
				vp_in=0;
				display_left=1;
				;;    
			-right)
				display=1;
				vp_in=1;
				display_right=1;
				;;             
			-help|*)
				argument=HELP
				break
				;;
		esac
		shift
	done
fi     
      
case  ${argument} in

	FBAS)
	  echo "\nRouting videosignal from FBAS ${parameter}  to display ${display} \n"
      videocapturetest -p0 -s4 -mNONE -g1 -u 
      videocapturetest -p1 -s ${parameter} -mNONE -g1 -u 
	  
		if [ $display_left -eq 0 -a $display_right -eq 0 ]
		then
		    LayerManagerControl set surface 256 visibility 0
		    LayerManagerControl set surface 0 visibility 1 
            LayerManagerControl set surface 0 source region 0 0 720 240
		    LayerManagerControl set surface 257 visibility 0
		    LayerManagerControl set surface 1 visibility 1 
            LayerManagerControl set surface 1 source region 0 0 720 240
		fi
	    if [ $display_left -eq 1 ]
		then
		    LayerManagerControl set surface 256 visibility 0
		    LayerManagerControl set surface 0 visibility 1 
            LayerManagerControl set surface 0 source region 0 0 720 240
		fi		
		if [ $display_right -eq 1 ]
		then
	        LayerManagerControl set surface 257 visibility 0
		    LayerManagerControl set surface 1 visibility 1 
            LayerManagerControl set surface 1 source region 0 0 720 240
		fi
		;;
	MHL)
		videocapturetest -p6 -s0 -mNONE -g1 -u
		videocapturetest -p7 -s0 -mNONE -g1 -u	

		if [ $display_left -eq 0 -a $display_right -eq 0 ]
		then
			echo "\nMHL left and right on\n"
			LayerManagerControl set surface 256 visibility 0
			LayerManagerControl set surface 4 visibility 1
			LayerManagerControl set surface 4 source region 0 0 640 480
			LayerManagerControl set surface 4 destination region 0 0 640 480
			
			LayerManagerControl set surface 257 visibility 0
			LayerManagerControl set surface 5 visibility 1
			LayerManagerControl set surface 5 source region 0 0 640 480
			LayerManagerControl set surface 5 destination region 0 0 640 480
		fi
	    if [ $display_left -eq 1 ]
		then
		    echo "\nMHL left on\n"
		    LayerManagerControl set surface 256 visibility 0
			LayerManagerControl set surface 4 visibility 1
			LayerManagerControl set surface 4 source region 0 0 640 480
			LayerManagerControl set surface 4 destination region 0 0 640 480
		fi		
		if [ $display_right -eq 1 ]
		then
		    echo "\nMHL right on\n"
			LayerManagerControl set surface 257 visibility 0		
			LayerManagerControl set surface 5 visibility 1
			LayerManagerControl set surface 5 destination region 0 0 640 480
		fi
		;;

	RESTORE)
		echo "\nRestore normal vidoesystem status\n"
		LayerManagerControl set surface 0 visibility 0
		LayerManagerControl set surface 1 visibility 0
		# off MHL layer
		LayerManagerControl set surface 4 visibility 0
		LayerManagerControl set surface 5 visibility 0
		# on HMI layer
		LayerManagerControl set surface 256  visibility 1
		LayerManagerControl set surface 257  visibility 1
	
        videocapturetest -p0 -g0 -u 
	    videocapturetest -p1 -g0 -u 
	    videocapturetest -p6 -g0 -u
        videocapturetest -p7 -g0 –u
	   
      sleep 1
	  ;;
		
	HELP)
		echo "\nUsage: $0 -fbas 1..4 [-left|-right]\n"
		echo "\nUsage: $0 -mhl [-left|-right]\n"
		echo "\nUsage: $0 -restore | -help\n"
		exit 1
		;;
		
esac

exit 0
