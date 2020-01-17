#!/usr/bin/env python3

import fanout_utils


def fanout_thumbnail(context):
	cleanup(context)
	fanout(context)

	print("Cleaning up")
	cleanup(context)


def cleanup(c):
	with contextlib.suppress(FileExistsError):
		os.mkdir(os.path.join(c.thumbnail_write_path, c.stream))

	with contextlib.suppress(FileNotFoundError):
		fanout_utils.remove_glob(os.path.join(
			c.thumbnail_write_path, "%s/thumb.jpeg" % c.stream))


def fanout(context):
	command = fanout_utils.format_and_strip(context, """
ffmpeg -v warning -nostats -nostdin -y
	-i {{ pull_url }}
	-c:v copy -an -f image2 -update 1 {{ thumbnail_write_path }}/{{ stream }}/thumb.jpeg
""")
	fanout_utils.call(command)


if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="thumbnails")

	parser.add_argument('--thumbnail_write_path', metavar='PATH', type=str,
		help='Path to write the thumbnails to')

	args = parser.parse_args()

	fanout_utils.mainloop(name="thumbnail", transcoding_stream="thumbnail", calback=fanout_thumbnail, args=args)
