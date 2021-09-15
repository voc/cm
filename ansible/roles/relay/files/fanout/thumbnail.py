#!/usr/bin/env python3

import os
import contextlib

import fanout_utils

def fanout_thumbnail(context):
	cleanup(context)
	prepare(context)
	try:
		fanout(context)
	except fanout_utils.ExitException:
		print("Cleaning up")
		cleanup(context)
		raise


def prepare(c):
	with contextlib.suppress(FileExistsError):
		os.mkdir(os.path.join(c.thumbnail_write_path, c.stream))

def cleanup(c):
	with contextlib.suppress(FileNotFoundError):
		fanout_utils.remove_glob(os.path.join(
			c.thumbnail_write_path, "%s/thumb.jpeg" % c.stream))
		fanout_utils.remove_glob(os.path.join(
			c.thumbnail_write_path, "%s/poster.jpeg" % c.stream))

	with contextlib.suppress(OSError):
		os.rmdir(os.path.join(c.thumbnail_write_path, c.stream))


def fanout(context):
	command = fanout_utils.format_and_strip(context, """
ffmpeg -v warning -nostats -nostdin -y
	-i {{ pull_url }}

	-map 0:v:0
	-c:v copy -an
	-f image2 -update 1 {{ thumbnail_write_path }}/{{ stream }}/poster.jpeg

	-map 0:v:1
	-c:v copy -an
	-f image2 -update 1 {{ thumbnail_write_path }}/{{ stream }}/thumb.jpeg
""")
	fanout_utils.call(command)


if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="thumbnails")

	parser.add_argument('--thumbnail_write_path', metavar='PATH', type=str,
		help='Path to write the thumbnails to')

	args = parser.parse_args()

	fanout_utils.mainloop(name="thumbnail", transcoding_stream="thumbnail", calback=fanout_thumbnail, args=args)
