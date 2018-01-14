#!/usr/bin/env python3

import fanout_utils


def fanout_webm(context):
	command = fanout_utils.format_and_strip(context, """
ffmpeg -v warning -nostats -nostdin -y -analyzeduration 3000000
	-i {{ pull_url }}

	{% for audio_track in audio_tracks %}
		{% for video_track in video_tracks %}
			-c:v copy
			-c:a copy

			{% if video_track == 'HD' %}
				-map 0:v:0
			{% elif video_track == 'SD' %}
				-map 0:v:1
			{% elif video_track == 'Slides' %}
				-map 0:v:2
			{% endif %}

			{% if audio_track == 'Native' %}
				-map 0:a:0
			{% elif audio_track == 'Translated' %}
				-map 0:a:1
			{% elif audio_track == 'Translated-2' %}
				-map 0:a:2
			{% endif %}

			-f webm
			-cluster_size_limit 3M
			-cluster_time_limit 3500
			-content_type video/webm
			-password {{ icecast_password }}
			icecast://{{ push_endpoint }}/{{ stream }}_{{ audio_track | lower }}_{{ video_track | lower }}.webm
		{% endfor %}
	{% endfor %}
""")
	fanout_utils.call(command)

if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="webm")

	parser.add_argument("--push_endpoint", metavar="PUSH", type=str,
		help="Icecast-Endpoint to push the faned out Video-Streams to (ie. 'live.ber.c3voc.de:8000/')")

	parser.add_argument("--icecast_password", metavar="PWD", type=str,
		help="Password to login as 'source' on the Icecast-Server")

	args = parser.parse_args()

	fanout_utils.mainloop(name="webm", transcoding_stream="vpx", calback=fanout_webm, args=args)
