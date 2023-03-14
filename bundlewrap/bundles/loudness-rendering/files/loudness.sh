#!/bin/bash

[[ -n "$DEBUG" ]] && set -x

if ! ffprobe ${source_url}
then
    echo "Source ${source_url} not available"
    exit 0
fi

/usr/local/bin/voc2alert "info" "loudness" "Loudness monitoring for ${stream_name} started ..."

ffmpeg \
    -hide_banner \
    -xerror \
    -y \
    -i "${source_url}" \
    -filter_complex "
        nullsrc=size=640x720 [base];
        [0:v] scale=640:360, fps=30 [scaled];
        [0:a] ebur128=video=1:meter=16:target=-16:size=640x480 [ebur][a1];
        [ebur] scale=640:360, fps=30 [v1];
        [a1] aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [audio];
        [base][v1] overlay=shortest=1 [tmp1];
        [tmp1][scaled] overlay=shortest=1:y=360 [ov];
        [ov] drawtext='fontcolor=white:x=50:y=50:fontsize=60:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:text=${stream_name}' [out]" \
    -map "[out]" -c:v libx264 -threads 2 -preset veryfast -x264-params keyint=30 -tune zerolatency -crf:0 26 -profile:0 high -level:0 4.1 -c:a aac -strict -2 -pix_fmt yuv420p \
    -map "[audio]" -c:a aac -b:a 128k \
    -f flv \
    "rtmp://rtmp-relay.video.smedia.cloud/relay/${stream_name}_loudness"

/usr/local/bin/voc2alert "info" "loudness" "Loudness monitoring for ${stream_name} stopped, ffmpeg exit code $?."
