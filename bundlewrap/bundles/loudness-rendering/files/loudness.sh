#!/bin/bash

[[ -n "$DEBUG" ]] && set -x

NAME="$1"
SOURCE="$2"
CASE_NUMBER=$(echo $1 | tr -dc "[0-9]")
ENCODER_ADDRESS=${3:-"10.73.${CASE_NUMBER}.3"}

STATE_PATH="/tmp/stream-state/${NAME}.txt"

set -euo pipefail

if ! ffprobe "${SOURCE}"
then
    echo "Source ${SOURCE} not available"
    exit 0
fi

function update-stream-state(){
    while true; do
    RES=$(telnet $ENCODER_ADDRESS "9999" <<EOF
get_stream_status
exit
EOF
)
    STATUS=$(echo $RES | grep stream_status | cut -d " " -f 2-)
    echo $STATUS > $STATE_PATH && sleep 5;
    done
}

/usr/local/sbin/voc2alert "info" "loudness" "Loudness monitoring for ${NAME} started ..."

# Fork child process to write state to file
update-stream-state &

ffmpeg \
    -hide_banner \
    -xerror \
    -y \
    -i "$SOURCE" \
    -filter_complex "
        nullsrc=size=640x720 [base];
        [0:v] scale=640:360, fps=30 [scaled];
        [0:a:0] ebur128=video=1:meter=16:target=-16:size=640x480 [ebur][a1];
        [ebur] scale=640:360, fps=30 [v1];
        [a1] aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [audio];
        [base][v1] overlay=shortest=1 [tmp1];
        [tmp1][scaled] overlay=shortest=1:y=360 [live];
        [live] drawtext='refresh=1:fontcolor=white:x=300:y=50:fontsize=40:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:textfile=${STATE_PATH}' [ov];
        [ov] drawtext='fontcolor=white:x=50:y=50:fontsize=60:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf:text=${NAME}' [out]" \
    -map "[out]" -c:v libx264 -threads 2 -preset veryfast -x264-params keyint=30 -tune zerolatency -crf:0 26 -profile:0 high -level:0 4.1 -c:a aac -strict -2 -pix_fmt yuv420p \
    -map "[audio]" -c:a aac -b:a 128k \
    -f flv \
    "rtmp://ingest2.c3voc.de/relay/${NAME}_loudness"

/usr/local/sbin/voc2alert "info" "loudness" "Loudness monitoring for ${NAME} stopped, ffmpeg exit code $?."
