#!/bin/sh

ffmpeg \
    -v verbose \
    -nostats \
    -y \
    -i tcp://localhost:${port}} \
    -c:v rawvideo \
    -c:a pcm_s16le \
    -pix_fmt uyvy422 \
    -f decklink \
    '${device}'
