#!/bin/bash

[[ -n "$DEBUG" ]] && set -x

NAME="$1"
SOURCE="$2"
OUTPUT="$3"
ROOM="$4"

set -uo pipefail

if ! ffprobe -hide_banner "${SOURCE}"
then
    echo "Source ${SOURCE} not available"
    exit 0
fi

mkdir -p "/opt/loudness-rendering/data/${NAME}"
touch "/opt/loudness-rendering/data/${NAME}/line1.txt"
touch "/opt/loudness-rendering/data/${NAME}/line2.txt"

/usr/local/sbin/voc2alert "info" "loudness" "Loudness monitoring for ${NAME} started ..."

ffmpeg \
    -hide_banner \
    -xerror \
    -y \
    -i "$SOURCE" \
    -filter_complex "
        nullsrc=size=640x720 [base];
        [0:v] scale=640:360, fps=30 [scaled];
        [0:a:0] ebur128=video=1:meter=16:target=-16:size=640x480 [ebur][a1];
        [0:a:0] avectorscope=size=640x480:zoom=2:r=30[vec];
        [ebur][vec] blend=all_mode='addition':all_opacity=0.8 [scope];
        [scope] scale=640:360, fps=30 [v1];
        [a1] aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [audio];
        [base][v1] overlay=shortest=1 [tmp1];
        [tmp1][scaled] overlay=shortest=1:y=360 [ov];
        [ov] drawtext='fontcolor=white:x=45:y=36:fontsize=50:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:textfile=/opt/loudness-rendering/data/${NAME}/line1.txt:reload=1' [ov1];
        [ov1] drawtext='fontcolor=white:x=45:y=86:fontsize=20:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:textfile=/opt/loudness-rendering/data/${NAME}/line2.txt:reload=1' [ov2];
        [ov2] drawtext='fontcolor=white:x=45:y=111:fontsize=20:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:text=${ROOM} - ${NAME}' [out]" \
    -map "[out]" -c:v libx264 -threads 2 -preset veryfast -x264-params keyint=30 -tune zerolatency -crf:0 26 -profile:0 high -level:0 4.1 -c:a aac -strict -2 -pix_fmt yuv420p \
    -map "[audio]" -c:a aac -b:a 128k \
    -f flv \
    "$OUTPUT"

/usr/local/sbin/voc2alert "info" "loudness" "Loudness monitoring for ${NAME} stopped, ffmpeg exit code $?."
