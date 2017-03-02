#!/bin/bash
# Transcodes to Multi-Quality VP8

while getopts "s:h" opt; do
  case $opt in
    s)
      STREAM=${OPTARG}
      ;;
    h)
      SHOW_HELP=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ ${SHOW_HELP} || ! ${STREAM} ]]; then
  NAME=`basename "${0}"`
  echo "usage: ${NAME} -s STREAM
  -s STREAM - Stream name
  -h - Show this help"
  exit 1
fi

ffmpeg -y -hide_banner\
  -i "http://localhost:7999/${STREAM}" \
  -fflags +genpts -flags +global_header -aspect 16:9 -pix_fmt yuv420p -threads 0 \
  \
  -c:v libvpx -threads:v 8 -cpu-used 16 -r 25 -g 50 -keyint_min 50 -deadline realtime \
  -map v:0 -s:v:0 1920x1080 -bufsize:v:0 4.0M -b:v:0 3.5M -maxrate:v:0 4.0M -crf:v:0 10 \
  -map v:0 -s:v:1 1280x720 -bufsize:v:1 2.0M -b:v:1 1.8M -maxrate:v:1 2.0M -crf:v:1 10 \
  -map v:0 -s:v:2 960x540 -bufsize:v:2 1.5M -b:v:2 1.35M -maxrate:v:2 1.5M -crf:v:2 10 \
  -map v:0 -s:v:3 640x360 -bufsize:v:3 1M -b:v:3 0.9M -maxrate:v:3 1M -crf:v:3 10 \
  -map v:0 -s:v:4 320x180 -bufsize:v:4 0.5M -b:v:4 0.45M -maxrate:v:4 0.5M -crf:v:4 10 \
  \
  -metadata:s:v:0 title=1080p \
  -metadata:s:v:1 title=720p \
  -metadata:s:v:2 title=540p \
  -metadata:s:v:3 title=360p \
  -metadata:s:v:4 title=180p \
  \
  -c:a opus -ar 48000 -b:a 128k -ac 1 \
  -map a:0 -map a:1? -map a:2? \
  \
  -f matroska -ice_public 1 -content_type video/webm icecast://source:source@localhost:7999/${STREAM}_vp8
