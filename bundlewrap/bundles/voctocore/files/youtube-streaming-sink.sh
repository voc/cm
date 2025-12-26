#!/bin/bash

voc2alert "info" "streaming" "starting youtube stream"


ffmpeg -y -nostdin -hide_banner -re \
% if vaapi_enabled:
    -init_hw_device vaapi=vaapi0:/dev/dri/renderD128 \
    -hwaccel vaapi \
    -hwaccel_output_format vaapi \
% endif
    -thread_queue_size 64 -i tcp://localhost:15000?timeout=3000000 \
% if vaapi_enabled:
    -filter_hw_device vaapi0 \
% endif
    -filter_complex " \
% if vaapi_enabled:
    [0:v] format=nv12,hwupload [v0];\
% endif
    \
[0:a]pan=stereo|c0=c0|c1=c1[s_pgm]\
" \
% if vaapi_enabled:
    -c:v h264_vaapi -bf 0 \
    -flags +cgop -aspect 16:9 \
    -r:v:0 25 -g:v:0 25 -qp:v:0 21 -maxrate:v:0 4M -bufsize:v:0 18M \
% else:
    -c:v libx264 -x264-params keyint=25:min-keyint=25 \
    -flags +cgop -aspect 16:9  -preset veryfast \
    -r:v:0 25 -g:v:0 25 -crf:v:0 21 -maxrate:v:0 6M -bufsize:v:0 1M \
% endif
    -c:a aac -b:a 192k -ar 48000 \
% if vaapi_enabled:
    -map "[hd]" \
% else:
    -map "0:v" \
% endif
-metadata:s:v:0 title="HD" \
-map "[s_pgm]" -metadata:s:a:0 title="native" \
    \
-f flv \
"rtmp://a.rtmp.youtube.com/live2/${streamkey}"

voc2alert "warning" "streaming" "stopping youtube stream"
