#!/bin/bash
# consumes 2-video, 3-audio integrated mkv

. common.sh

ffmpeg -y -i "http://${SRC}:7999/${STREAM}" -aspect 16:9 -threads:0 0 \
	-fflags +genpts -flags +global_header \
	-c:v libvpx -g 75 -keyint_min 75 -deadline realtime \
	-map 0:v:0 -threads:v:0 4 -b:v:0 3500k -crf:v:0 22 \
	-map 0:v:1 -threads:v:1 4 -b:v:1 1000k -crf:v:1 22 \
	\
	-ac 1 \
	-map 0:a:0 -c:a:0 libopus -vbr:a:0 off -b:a:0 32k \
	-map 0:a:1 -c:a:1 libopus -vbr:a:1 off -b:a:1 32k \
	-map 0:a:2 -c:a:2 libopus -vbr:a:2 off -b:a:2 32k \
	\
	-map 0:a:0 -c:a:3 libmp3lame -b:a:3 96k \
	-map 0:a:1 -c:a:4 libmp3lame -b:a:4 96k \
	-map 0:a:2 -c:a:5 libmp3lame -b:a:5 96k \
	-y -f matroska pipe:
