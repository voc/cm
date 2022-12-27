#!/bin/sh

% if device == 'fb':
fbset -g 1920 1080 1920 1080 32
echo 0 > /sys/class/graphics/fbcon/cursor_blink
% endif

ffmpeg \
    -v verbose \
    -nostats \
    -y \
    -i tcp://localhost:${port} \
% if device == 'fb':
    -map 0:v \
% endif
    -c:v rawvideo \
% if device == 'fb':
    -pix_fmt bgra \
    -f fbdev \
    /dev/fb0
% else:
    -c:a pcm_s16le \
    -pix_fmt uyvy422 \
    -f decklink \
    '${device}'
% endif
