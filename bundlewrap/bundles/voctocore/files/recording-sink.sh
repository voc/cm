#!/bin/sh
<%
    from re import sub
%>\

voc2alert "info" "recording" "Recording to /video/capture/${event['slug']}/ started…"

ffmpeg \
    -v verbose \
    -nostats \
    -y \
    -analyzeduration 10000 \
    -thread_queue_size 512 -i tcp://localhost:11000?timeout=3000000 \
% if parallel_slide_recording and slides_port > 0:
    -thread_queue_size 512 -i tcp://localhost:${slides_port}?timeout=3000000 \
% endif
    -aspect 16:9 \
    -filter_complex \
       "[0:a]pan=stereo|c0=c0|c1=c1[s_native]; \
        [0:a]pan=stereo|c0=c2|c1=c2[s_trans_1]; \
        [0:a]pan=stereo|c0=c3|c1=c3[s_trans_2]" \
    -map 0:v -c:v:0 mpeg2video -pix_fmt:v:0 yuv420p -qscale:v:0 4 -qmin:v:0 4 -qmax:v:0 4 -keyint_min:v:0 5 -bf:v:0 0 -g:v:0 5 -me_method:v:0 dia -metadata:s:v:0 title="HD" \
% if parallel_slide_recording and slides_port > 0:
    -map 1:v -c:v:1 mpeg2video -pix_fmt:v:1 yuv420p -qscale:v:1 4 -qmin:v:1 4 -qmax:v:1 4 -keyint_min:v:1 5 -bf:v:1 0 -g:v:1 5 -me_method:v:1 dia -metadata:s:v:0 title="Slides" \
% endif
        -map "[s_native]"  -c:a s302m -metadata:s:a:0 title="Native" \
        -map "[s_trans_1]" -c:a s302m -metadata:s:a:1 title="Translated" \
        -map "[s_trans_2]" -c:a s302m -metadata:s:a:1 title="Translated-2" \
        -strict -2 \
    -flags +global_header \
    -f segment \
    -segment_time 180 \
    -strftime 1 \
    -segment_format mpegts \
    "/video/capture/${event['slug']}/${sub('[^a-z0-9-_]+', '_', event['room_name'].lower())}-%Y-%m-%d_%H-%M-%S-$$.ts"

ffmpeg_error_code=$?
if [ "0" -ne "$ffmpeg_error_code" ]; then
    voc2alert "error" "recording" "Recording failed, ffmpeg exited $ffmpeg_error_code"
else
    voc2alert "warn" "recording" "Recording stopped!"
fi

exit $ffmpeg_error_code
