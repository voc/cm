#!/usr/bin/env /bin/bash
set -e
IDENTIFIER=$1
shift
TIMEOUT_SECONDS=$1
shift
# command in $*

function usage() {
	echo "ratelimit IDENTIFIER TIMEOUT_SECONDS COMMAND..."
	exit
}

if [ -z "$IDENTIFIER" -o -z "$TIMEOUT_SECONDS" -o -z $ARGV[0] ]; then
	usage
fi

NOW_S=`date +%s`
NOT_UNTIL_S=$(expr "$NOW_S" + "$TIMEOUT_SECONDS")
DIR=/tmp/`whoami`-ratelmit
TIME_FILE=$DIR/${IDENTIFIER}_not_until

mkdir -p $DIR

if [ -e "$TIME_FILE" ]; then
	NOT_UNTIL_S_STORED=`cat $TIME_FILE`
	if [ -n "$NOT_UNTIL_S_STORED" ]; then
		if [ "$NOW_S" -le "$NOT_UNTIL_S_STORED" ]; then
			# timeout not reached, exit
			exit
		fi
	fi
fi

echo "$NOT_UNTIL_S" > "$TIME_FILE"

exec $*
