#!/bin/bash
set -xe

gst-launch-1.0 -q udpsrc multicast-iface=lo address=239.192.42.42 port=5004 !\
	application/x-rtp, clock-rate=48000, channels=2 !\
	rtpL24depay !\
	audioconvert !\
	wavenc !\
	fdsink |\
		/opt/ffmpeg-4.1-64bit-static/ffmpeg -i - -filter_complex '
			[0] ebur128=video=1:target=-16:gauge=shortterm:scale=relative [v][a]
		' -map '[v]' -map '[a]' \
		-pix_fmt yuv420p -c:v rawvideo \
		-c:a pcm_s16le -f matroska - |\
			ffplay -
