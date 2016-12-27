#!/bin/bash

. common.sh

IDX="$2"
LANG="$3"

ffmpeg -f matroska -i - \
	-c:a copy -map "0:a:${IDX}" \
	-y -f mp3 pipe: | \
	\
	oggfwd -3 ${IC_IP} 8000 "$IC_PASSWD" /s${STREAM_ROOM}_${LANG}.mp3
