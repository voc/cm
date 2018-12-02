#!/usr/bin/env python3

import fanout_utils


def fanout_webm(context):
	command = fanout_utils.format_and_strip(context, """
ffmpeg -v warning -nostats -nostdin -y -analyzeduration 3000000
	-i {{ pull_url }}

	{% for audio_track in audio_tracks %}
		{% for codec in ['mp3', 'opus'] %}
			-c:v copy
			-c:a copy

			{% if audio_track == 'Native' %}
				-map 0:a:{{ 0 if codec == 'mp3' else 1 }}
			{% elif audio_track == 'Translated' %}
				-map 0:a:{{ 2 if codec == 'mp3' else 3 }}
			{% elif audio_track == 'Translated-2' %}
				-map 0:a:{{ 4 if codec == 'mp3' else 5 }}
			{% endif %}


			-f {{ codec }}
			-content_type {{ 'audio/mpeg' if codec == 'mp3' else 'audio/ogg' }}
			-password {{ icecast_password }}
			icecast://{{ push_endpoint }}/{{ stream }}_{{ audio_track | lower }}.{{ codec }}
		{% endfor %}
	{% endfor %}
""")
	fanout_utils.call(command)

if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="audio")

	parser.add_argument("--push_endpoint", metavar="PUSH", type=str,
		help="Icecast-Endpoint to push the faned out Audio-Streams to (ie. 'live.ber.c3voc.de:8000/')")

	parser.add_argument("--icecast_password", metavar="PWD", type=str,
		help="Password to login as 'source' on the Icecast-Server")

	args = parser.parse_args()

	fanout_utils.mainloop(name="audio", transcoding_stream="audio", calback=fanout_webm, args=args)
