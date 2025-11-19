#!/bin/bash

pkgconfig=`which pkg-config`
test -x $pkgconfig || {
    cat > /dev/null
    exit 0
}

[ $# -ge 1 ] || {
    cat > /dev/null
    exit 0
}

case $1 in
-P|--provides)
    while read filename ; do
    case "${filename}" in
    *.pc)
	# Query the dependencies of the package.
	DIR=`dirname ${filename}`
	PKG_CONFIG_PATH="$DIR:$DIR/../../share/pkgconfig"
	export PKG_CONFIG_PATH
	$pkgconfig --print-provides "$filename" 2> /dev/null | while read n r v ; do
	    [ -n "$n" ] || continue
	    # We have a dependency.  Make a note that we need the pkgconfig
	    # tool for this package.
	    if  [ -n "$r" ] && [ -n "$v" ]; then
		echo "pkgconfig($n) $r $v"
	    else
		echo "pkgconfig($n)"
	    fi
	done
	;;
    esac
    done
    ;;
-R|--requires)
    oneshot="pkgconfig"
    while read filename ; do
    case "${filename}" in
    *.pc)
	[ -n "$oneshot" ] && echo "$oneshot"; oneshot=""
	# Query the dependencies of the package.
	DIR=`dirname ${filename}`
	PKG_CONFIG_PATH="$DIR:$DIR/../../share/pkgconfig"
	export PKG_CONFIG_PATH
	$pkgconfig --print-requires "$filename" 2> /dev/null | while read n r v ; do
	    [ -n "$n" ] || continue
	    if  [ -n "$r" ] && [ -n "$v" ]; then
		echo "pkgconfig($n) $r $v"
	    else
		echo "pkgconfig($n)"
	    fi
	    oneshot=""
	done
	;;
    esac
    done
    ;;
esac
exit 0
