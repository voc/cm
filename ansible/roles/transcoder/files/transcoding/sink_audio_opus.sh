#!/bin/bash

. common.sh

STREAM_IDX="$2"
STREAM_LANG="$3"

ffmpeg -f matroska -i - \
	-c:a copy -map "0:a:${STREAM_IDX}" \
	-y -f ogg pipe: | \
	\
	oggfwd ${IC_IP} 8000 "$IC_PASSWD" /s${STREAM_ROOM}_${STREAM_LANG}.opus
