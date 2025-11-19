#!/bin/sh

[ $# -ge 1 ] || {
    cat > /dev/null
    exit 0
}

case $1 in
-P|--provides)
    cat > /dev/null
    exit 0
    ;;
-R|--requires)
    while read f ; do
	bash --rpm-requires $f | grep -v '[`#:]' | sed -e 's,executable(/\(.*\))$,/\1,'
    done | sort -u
    ;;
esac
exit 0
