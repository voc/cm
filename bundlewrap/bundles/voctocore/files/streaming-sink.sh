#!/bin/bash

### Filter Parameter
## PA
# parameter dynaudnorm
para_pa_leveler="p=0.35:r=1:f=300"

## TRANSLATOR
# parameter compand as gate
para_trans_gate="attacks=0:points=-80/-115|-55.1/-80|-55/-55|20/20"
# parameter compand as limiter
para_trans_limiter="attacks=0:points=-80/-80|-12/-12|20/-12"
# parameter dynaudnorm
para_trans_leveler="p=0.35:r=1:f=300"

## MIX
# parameter volume for both tracks
para_mix_vol_pa="0.2"
para_mix_vol_trans="1.0"
# parameter dynaudnorm
para_mix_leveler="p=0.35:r=1:f=30"
# paramter loudnorm
para_mix_loudnorm="i=-23.0:lra=12.0:tp=-3.0"


if [[ -z "$VOC_STREAMING_AUTH" ]]
then
    voc2alert "error" "streaming" "failed to start stream, credentials missing!"
    exit 1
fi


ffmpeg -y -nostdin -hide_banner -re \
% if vaapi_enabled:
    -init_hw_device vaapi=vaapi0:/dev/dri/renderD128 \
    -hwaccel vaapi \
    -hwaccel_output_format vaapi \
% endif
    -thread_queue_size 512 -i tcp://localhost:15000?timeout=3000000 \
% if parallel_slide_streaming:
    -thread_queue_size 512 -i tcp://localhost:15001?timeout=3000000 \
% endif
% if vaapi_enabled:
    -filter_hw_device vaapi0 \
% endif
    -filter_complex "
[0:v] hqdn3d\
% if vaapi_enabled:
    , format=nv12,hwupload \
% endif
    [hd];\
% if parallel_slide_streaming:
    [1:v] fps=5, hqdn3d\
% if vaapi_enabled:
    , format=nv12,hwupload,scale_vaapi=w=1024:h=576\
% else:
    , scale=1024:576\
% endif
    [slides];\
% endif
    \
    [0:a]pan=stereo|c0=c0|c1=c1[s_pgm];\
    [0:a]pan=stereo|c0=c2|c1=c3[s_trans_1];\
    [0:a]pan=stereo|c0=c4|c1=c5[s_trans_2];\
    \
    [s_pgm] asplit=2 [pgm_1] [pgm_2] ;\
% if dynaudnorm:
    [pgm_2] dynaudnorm=$para_pa_leveler [pgm_lev] ;\
% endif
    \
    [s_trans_1] compand=$para_trans_gate [trans_gate_1] ;\
    [trans_gate_1] compand=$para_trans_limiter [trans_lim_1] ;\
    [trans_lim_1] dynaudnorm=$para_trans_leveler [trans_lev_1] ;\
    \
    [s_trans_2 ] compand=$para_trans_gate [trans_gate_2] ;\
    [trans_gate_2] compand=$para_trans_limiter [trans_lim_2] ;\
    [trans_lim_2] dynaudnorm=$para_trans_leveler [trans_lev_2] ;\
    \
% if dynaudnorm:
    [pgm_lev] volume=$para_mix_vol_pa,asplit [mix_int_1][mix_int_2] ;\
% else:
    [pgm_2] volume=$para_mix_vol_pa,asplit [mix_int_1][mix_int_2] ;\
% endif
    [trans_lev_1] volume=$para_mix_vol_trans [mix_trans_1] ;\
    [trans_lev_2] volume=$para_mix_vol_trans [mix_trans_2] ;\
    [mix_int_1][mix_trans_1] amix=inputs=2:duration=longest [mix_out_1] ;\
    [mix_int_2][mix_trans_2] amix=inputs=2:duration=longest [mix_out_2] \
% if dynaudnorm:
    ;\
    [pgm_1] dynaudnorm=$para_mix_leveler,loudnorm=$para_mix_loudnorm [pgm]; \
    [mix_out_1] dynaudnorm=$para_mix_leveler,loudnorm=$para_mix_loudnorm [duck_out_1]; \
    [mix_out_2] dynaudnorm=$para_mix_leveler,loudnorm=$para_mix_loudnorm [duck_out_2] \
% endif
    " \
% if vaapi_enabled:
    -c:v h264_vaapi \
% else:
    -c:v libx264 \
% endif
    -flags +cgop -aspect 16:9 \
% if parallel_slide_streaming:
              -g:v:1 15 -crf:v:1 25 -maxrate:v:1 100k -bufsize:v:1 750k \
% endif
    -r:v:0 25 -g:v:0 75 -crf:v:0 21 -maxrate:v:0 4M -bufsize:v:0 18M \
    -c:a aac -b:a 192k -ar 48000 \
    -map "[hd]" \
% if parallel_slide_streaming:
    -map "[slides]" \
% endif
    -metadata:s:v:0 title="HD" \
% if parallel_slide_streaming:
    -metadata:s:v:1 title="Slides" \
% endif
% if dynaudnorm:
    -map "[pgm]" -metadata:s:a:0 title="native" \
    -map "[duck_out_1]" -metadata:s:a:1 title="translated" \
    -map "[duck_out_2]" -metadata:s:a:2 title="translated-2" \
% else:
    -map "[pgm_1]" -metadata:s:a:0 title="native" \
    -map "[mix_out_1]" -metadata:s:a:1 title="translated" \
    -map "[mix_out_2]" -metadata:s:a:2 title="translated-2" \
% endif
    \
% if srt_publish:
    -f mpegts \
    "srt://ingest.c3voc.de:1337?streamid=publish/${endpoint}/$VOC_STREAMING_AUTH"
% else:
    -f matroska \
    -password "$VOC_STREAMING_AUTH" \
    -content_type video/webm \
    "icecast://live.ber.c3voc.de:7999/${endpoint}"
% endif
