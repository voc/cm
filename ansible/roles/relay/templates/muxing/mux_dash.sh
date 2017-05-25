#!/bin/bash
SRC=""
FFMPEG="ffmpeg-dash"
DASH_PREFIX="/srv/nginx/dash/${STREAM}"

MAP="-map v:0 -map v:1 -map v:2 -map v:3 -map v:4 \
-map a:0 -metadata:s:a:0 bitrate=32k -metadata:s:a:0 language=Native \
-map a:1 -metadata:s:a:1 bitrate=32k -metadata:s:a:1 language=Translated"
SETS="id=v,streams=v:0,v:1,v:2,v:3,v:4 id=a_n,role=Native,streams=a:0 id=a_t,role=Translated,streams=a:1"

mkdir -p ${DASH_PREFIX}

while true; do
  ${FFMPEG} -y -hide_banner \
    -i "http://${SRC}:7999/${STREAM}" \
    -flags +global_header -c copy \
    -metadata title="${STREAM}" \
    \
    ${MAP} \
    -f dash -adaptation_sets "${SETS}" \
    -window_size 15 -extra_window_size 5 -min_seg_duration 3000000 \
    -init_seg_name "init_\$RepresentationID\$" \
    -media_seg_name "\$RepresentationID\$-\$Time%09d\$" \
    ${DASH_PREFIX}/manifest.mpd
  sleep 2
done
