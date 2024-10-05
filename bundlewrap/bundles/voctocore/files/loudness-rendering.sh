#!/bin/bash

[[ -n "$DEBUG" ]] && set -x

set -uo pipefail

mkdir -p "/opt/loudness-rendering/data/"
touch "/opt/loudness-rendering/data/line1.txt"
touch "/opt/loudness-rendering/data/line2.txt"
touch "/opt/loudness-rendering/data/line3.txt"

<%
    width_per_scope = int(1024/len(node.metadata.get('voctocore/audio')))
    label_padding_left = int(45*(width_per_scope/640))
%>\

ffmpeg \
    -hide_banner \
    -xerror \
    -y \
    -i "tcp://127.0.0.1:15100" \
    -filter_complex "
        color=size=1024x1056:color=black [base];
        [0:v] fps=30 [streamvideo];
% for idx, audio_name in enumerate(sorted(node.metadata.get('voctocore/audio').keys())):
        [0:a:0] pan=stereo|c0=c${idx*2}|c1=c${idx*2+1},asplit [audioin_${audio_name}_ebur][audioin_${audio_name}_vec];
        [audioin_${audio_name}_ebur] ebur128=video=1:meter=16:target=-16:size=640x480 [ebur_${audio_name}][a_${audio_name}];
        [audioin_${audio_name}_vec] avectorscope=size=640x480:zoom=2:r=30[vec_${audio_name}];
        [ebur_${audio_name}][vec_${audio_name}] blend=all_mode='addition':all_opacity=0.8 [scope_${audio_name}];
        [scope_${audio_name}] scale=${width_per_scope}:480, fps=30 [scope_scaled_${audio_name}];
        [a_${audio_name}] anullsink;
% endfor
        [0:a:0] aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo [audio];
        [base][streamvideo] overlay=shortest=1:y=480 [tmp0];
% for idx, audio_name in enumerate(sorted(node.metadata.get('voctocore/audio').keys())):
        [tmp${idx}][scope_scaled_${audio_name}] overlay=shortest=1:x=${idx*width_per_scope} [temp_${audio_name}];
        [temp_${audio_name}] drawtext='fontcolor=white:x=${idx*width_per_scope+label_padding_left}:y=136:fontsize=20:fontfile=/usr/share/fonts/freesans.ttf:text=${audio_name}' [tmp${idx+1}];
% endfor
        [tmp${idx+1}] drawtext='fontcolor=white:x=${label_padding_left}:y=46:fontsize=50:fontfile=/usr/share/fonts/freesans.ttf:textfile=/opt/loudness-rendering/data/line1.txt:reload=30' [ov1];
        [ov1] drawtext='fontcolor=white:x=${label_padding_left}:y=106:fontsize=20:fontfile=/usr/share/fonts/freesans.ttf:textfile=/opt/loudness-rendering/data/line2.txt:reload=30' [ov2];
        [ov2] drawtext='fontcolor=white:x=${label_padding_left}:y=417:fontsize=50:fontfile=/usr/share/fonts/freesans.ttf:textfile=/opt/loudness-rendering/data/line3.txt:reload=30' [ov3];
        [ov3] drawtext='fontcolor=white:x=${label_padding_left}:y=387:fontsize=20:text=${node.name}' [out]" \
    -map "[out]" -c:v libx264 -threads 2 -preset veryfast -x264-params keyint=30 -tune zerolatency -crf:0 26 -profile:0 high -level:0 4.1 -strict -2 -pix_fmt yuv420p \
    -map "[audio]" -c:a aac -b:a 128k \
    -f flv \
    "rtmp://ingest2.c3voc.de/relay/${node.name}_loudness"
