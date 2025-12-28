#!/bin/bash

if [[ -z "$VOC_LL_STREAMING_SERVER" ]]
then
    voc2alert "error" "streaming" "failed to start low latency stream, low latency streaming server missing!"
    exit 1
fi

voc2alert "info" "streaming" "Low latency stream started…"


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
[0:a]pan=stereo|c0=c0|c1=c1[s_pgm];\
[0:a]pan=stereo|c0=c2|c1=c3[s_trans_1];\
[0:a]pan=stereo|c0=c4|c1=c5[s_trans_2] \
" \
% if vaapi_enabled:
    -c:v h264_vaapi -bf 0 \
    -flags +cgop -aspect 16:9 \
    -r:v:0 25 -g:v:0 25 -qp:v:0 21 -maxrate:v:0 4M -bufsize:v:0 18M \
% else:
    -c:v libx264 -x264-params keyint=25:min-keyint=25 \
    -flags +cgop -aspect 16:9  -preset ultrafast -tune zerolatency \
    -r:v:0 25 -g:v:0 25 -crf:v:0 24 -maxrate:v:0 8M \
% endif
    -c:a aac -b:a 192k -ar 48000 \
% if vaapi_enabled:
    -map "[hd]" \
% else:
    -map "0:v" \
% endif
-metadata:s:v:0 title="HD" \
-map "[s_pgm]" -metadata:s:a:0 title="native" \
-map "[s_trans_1]" -metadata:s:a:1 title="translated" \
-map "[s_trans_2]" -metadata:s:a:2 title="translated-2" \
    \
-f mpegts \
"srt://$VOC_LL_STREAMING_SERVER?streamid=publish:ll/${endpoint}"
