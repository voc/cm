#!/bin/bash

. common.sh

# consumes: sX_sd_multiaudio

ffmpeg -y -i "rtmp://${RTMP_SERVER}/stream/${STREAM}" -aspect 16:9 -threads:0 0 \
	-fflags +genpts -flags +global_header \
	-map 0:v:0 -c:v libvpx -g 75 -keyint_min 75 -deadline realtime -b:v 400k -crf 10 \
	-ac 1 -c:a libopus -vbr:a off -b:a 32k \
	-map 0:a:0 -filter:a:0 pan=mono:c0=FL \
	-map 0:a:0 -filter:a:1 pan=mono:c0=FR \
	-y -f webm pipe:
