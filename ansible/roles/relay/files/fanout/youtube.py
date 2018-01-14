#!/usr/bin/env python3

import fanout_utils


def fanout_youtube(context):
	command = """
	ffmpeg -v warning -nostats -nostdin -y -analyzeduration 3000000
		-i {{ pull_url }}
		-c:v copy
		-c:a copy

		-map 0:v:0
		-map 0:a:0

		-f flv
		rtmp://a.rtmp.youtube.com/live2/{{ youtube_stream_key }}
	"""

if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="youtube")

	parser.add_argument("--youtube_stream_key", metavar="KEY", type=str,
		help="Stream-Key creatd in the YouTube Creator Studio Web-UI")

	args = parser.parse_args()

	fanout_utils.mainloop(name="youtube", transcoding_stream="h264", calback=fanout_youtube, args=args)
