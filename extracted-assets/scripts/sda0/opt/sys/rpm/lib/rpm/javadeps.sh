#!/bin/sh -e

mode="-P"

case $1 in
-P|--provides)
	mode="$1"
	shift
	;;
-R|--requires)
	mode="$1"
	shift
	;;
esac

JCFDUMP=${1:-jcf-dump}
JAR=${2:-jar}

dump=`mktemp ${TMPDIR:-/tmp}/classdepXXXXXX`
if test -z "$dump"; then
	echo Error creating temporary file.
	exit 1
fi

classdir=`mktemp -d ${TMPDIR:-/tmp}/classdepXXXXXX`
if test -z "$classdir"; then
	echo Error creating temporary directory.
	rm -f $dump
	exit 1
fi

cleanup() {
	rm -f $dump
	rm -fr $classdir
}

trap cleanup EXIT

Pscandeps()
{
	$JCFDUMP -c -v "$1" > $dump 2> /dev/null
	awk '
	/^This class:/ {
		gsub(",", "", $3);
		gsub("^[0123456789]+=", "", $3);
		print "java(" $3 ")";
	}
	' $dump
}

Rscandeps()
{
	$JCFDUMP -c -v "$1" > $dump 2> /dev/null
	awk '
	/InterfaceMethodref class:/ {
		gsub("^[0123456789]+=", "", $4);
		print "java(" $4 ")"
	}
	/Methodref class:/ {
		gsub("^[0123456789]+=", "", $4);
		print "java(" $4 ")"
	}
	/InterfaceFieldref class:/ {
		gsub("^[0123456789]+=", "", $4);
		print "java(" $4 ")"
	}
	/Fieldref class:/ {
		gsub("^[0123456789]+=", "", $4);
		print "java(" $4 ")"
	}
	' $dump
}

case $mode in
-P|--provides)
    while read filename ; do
	case "$filename" in
	*.class)
		Pscandeps "$filename"
		;;
	*.jar) 
		if ! $JAR tf "$filename" | grep -q -e '(^..|^/|^\\)' ; then
			pushd $classdir > /dev/null
			$JAR xf "$filename"
			popd > /dev/null
			$JAR tf "$filename" | sed "s|^|$classdir/|g" | $0 "$@"
			rm -fr $classdir/*
		fi
		;;
	*)
		;;
	esac
    done
    ;;
-R|--requires)
    while read filename ; do
	case "$filename" in
	*.class)
		Rscandeps "$filename"
		;;
	*.jar) 
		if ! $JAR tf "$filename" | grep -q -e '(^..|^/|^\\)' ; then
			pushd $classdir > /dev/null
			$JAR xf "$filename"
			popd > /dev/null
			$JAR tf "$filename" | sed "s|^|$classdir/|g" | $0 "$@"
			rm -fr $classdir/*
		fi
		;;
	*)
		;;
	esac
    done
    ;;
esac
