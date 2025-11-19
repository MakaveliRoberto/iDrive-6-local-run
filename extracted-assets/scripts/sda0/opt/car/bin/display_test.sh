
#LayerManagerControl set surface 32 visibility 1
#LayerManagerControl set surface 33 visibility 1
# -show <name> [-l] [-r]
# -stop
# -help

argument=''
display_l=''
display_r=''
pic_name=''

if [ $# -eq 0 ]
then
	argument=HELP  
else
	while [ $# -ne 0 ] 
		do
		case $1 in
			-show)
				argument=SHOW_P				
				shift
				pic_name=$1;
				;;
			-l)
				display_l=-l;
				break
				;;    
			-r)
				display_r=-r;
				break
				;;
			-stop)
				argument=STOP;
				break
				;;
			-help|*)
				argument=HELP;
				break
				;;
		esac
		shift
	done
fi

case  ${argument} in

	SHOW_P)
	    echo "LayerManagerControl set surface 32  visibility 1"
	    LayerManagerControl set surface 32  visibility 1
	    echo "LayerManagerControl set surface 33 visibility 1"	  
        LayerManagerControl set surface 33 visibility 1

        display_test ${pic_name} ${display_l} ${display_r}&
		exit 0
		;;
	STOP)
		slay -f display_test
		exit 0
		;;
		
	HELP)
		echo "\nUsage: $0 -show <name> [-l|-r] | -stop | -help\n"		
		exit 2
		;;
		
esac

exit 0
