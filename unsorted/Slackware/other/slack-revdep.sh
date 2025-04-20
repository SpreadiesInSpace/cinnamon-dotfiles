#!/bin/sh
#
# script to find broken package for Slackware Linux
#

SEARCH_DIRS="/bin /usr/bin /sbin /usr/sbin /lib /usr/lib /lib64 /usr/lib64 /usr/libexec"
TMPFILE=$(mktemp)

trap 'rm -f $TMPFILE; printf "\033[0K"; exit 1' 1 2 3 15

while read -r line; do
	if [ "$(echo $line | cut -c 1)" = "/" ]; then
		EXTRA_SEARCH_DIRS="$EXTRA_SEARCH_DIRS $line "
	fi
done < /etc/ld.so.conf

if [ -d /etc/ld.so.conf.d/ ]; then
	for dir in $(ls -1 /etc/ld.so.conf.d/*.conf 2>/dev/null); do
		while read -r line; do
			if [ "$(echo $line | cut -c 1)" = "/" ]; then
				EXTRA_SEARCH_DIRS="$EXTRA_SEARCH_DIRS $line "
			fi
		done < $dir
	done
fi

SEARCH_DIRS=$(echo $SEARCH_DIRS $EXTRA_SEARCH_DIRS | tr ' ' '\n' | sort | uniq | tr '\n' ' ')

find $SEARCH_DIRS -type f \( -perm /+u+x -o -name '*.so' -o -name '*.so.*' \) -print 2> /dev/null | sort -u > $TMPFILE

total=$(wc -l $TMPFILE | awk '{print $1}')
count=0
while read -r line; do
	count=$(( count + 1 ))
	libname=${line##*/}
	printf " $(( 100*count/total ))%% $libname\033[0K\r"
	case "$(file -bi "$line")" in
		*application/x-sharedlib* | *application/x-executable* | *application/x-pie-executable*)
			missinglib=$(ldd /$line 2>/dev/null | grep "not found" | awk '{print $1}' | sort | uniq)
			if [ "$missinglib" ]; then
				for i in $missinglib; do
					objdump -p /$line | grep NEEDED | awk '{print $2}' | grep -qx $i && {
						ownby=$(grep -x ${line#/} /var/lib/pkgtools/packages/* | head -n1 | cut -d : -f1 | rev | cut -d / -f1 | rev)
						echo " $ownby: $line (requires $i)"
					}
				done
			fi;;
	esac
done < $TMPFILE
printf "\033[0K"

rm -f $TMPFILE

exit 0
