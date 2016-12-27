#!/bin/bash

. common.sh

RES="$2"
LANG="$3"

case $RES in
	hd)
		VIDEO_IDX=0
		;;
	sd)
		VIDEO_IDX=1
		;;
	slides)
		VIDEO_IDX=2
		;;
esac

if [ "$LANG" = "native" ]
then
	AUDIO_IDX=0
else
	AUDIO_IDX=1
fi

ffmpeg -f matroska -i - \
	-c:v copy -c:a copy \
	-map 0:v:${VIDEO_IDX} -map 0:a:${AUDIO_IDX} \
	-y -f webm pipe: | \
	\
	mse_webm_remuxer -cm 2000 - - | \
	\
	oggfwd -w ${IC_IP} 8000 "${IC_PASSWD}" /"s${STREAM_ROOM}_${LANG}_${RES}.webm"
