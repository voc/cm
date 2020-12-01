#!/usr/bin/env python3

import os
import time
import itertools
import contextlib

import fanout_utils


def fanout_hls(context):
	context += {
		"starttime": int(time.time()),
	}

	cleanup(context)
	prepare(context)
	context += calculate_map_and_varmap(context)
	generate_master_playlists(context)

	try:
		fanout(context)
	except fanout_utils.ExitException:
		print("Cleaning up")
		cleanup(context)
		raise

	cleanup(context)

def prepare(c):
	with contextlib.suppress(FileExistsError):
		os.mkdir(os.path.join(c.hls_write_path, c.stream))

def cleanup(c):
	with contextlib.suppress(FileNotFoundError):
		fanout_utils.remove_glob(os.path.join(
			c.hls_write_path, c.stream, "*.ts"))
		fanout_utils.remove_glob(os.path.join(
			c.hls_write_path, "%s/*.m3u8" % c.stream))

	with contextlib.suppress(OSError):
		os.rmdir(os.path.join(c.hls_write_path, c.stream))

def calculate_map_and_varmap(c):
	first_audio_stream_index = len(c.video_tracks)

	# HD+Native
	maps = ["-map 0:v:0 -map 0:a:0"]
	varmaps = ["v:0,a:0"]

	if 'SD' in c.video_tracks:
		 # SD+Native
		maps += ["-map 0:v:1 -map 0:a:0"]
		varmaps += ["v:1,a:1"]

	if 'Slides' in c.video_tracks:
		# Slides+Native
		maps += ["-map 0:v:2 -map 0:a:0"]
		varmaps += ["v:2,a:2"]

	if 'Translated' in c.audio_tracks:
		# Translated
		maps += ["-map 0:a:1"]
		varmaps += ["a:%d" % (first_audio_stream_index+0)]

	if 'Translated-2' in c.audio_tracks:
		# Translated-2
		maps += ["-map 0:a:2"]
		varmaps += ["a:%d" % (first_audio_stream_index+1)]


	return {
		"maps": maps,
		"varmaps": varmaps,

		"first_audio_stream_index": first_audio_stream_index,
	}


def generate_master_playlists(c):
	for video_track, audio_track in itertools.product(c.video_tracks, c.audio_tracks):
		playlist_context = c + {
			"video_track": video_track,
			"audio_track": audio_track,
		}

		master_playlist = fanout_utils.format_and_strip(playlist_context, """
#EXTM3U
#EXT-X-VERSION:3

#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Untranslated",DEFAULT={{ 'YES' if audio_track == 'Native' else 'NO' }}

{% if 'Translated' in audio_tracks %}
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Translation 1",DEFAULT={{ 'YES' if audio_track == 'Translated' else 'NO' }},URI="chunks_{{ first_audio_stream_index+0 }}.m3u8"
{% endif %}
{% if 'Translated-2' in audio_tracks %}
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Translation 2",DEFAULT={{ 'YES' if audio_track == 'Translated-2' else 'NO' }},URI="chunks_{{ first_audio_stream_index+1 }}.m3u8"
{% endif %}

{% if video_track in ['HD'] %}
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=5000000,RESOLUTION=1920x1080,CODECS="avc1.4d0028,mp4a.40.2",AUDIO="audio"
chunks_0.m3u8
{% endif %}
{% if 'SD' in video_tracks and video_track in ['HD', 'SD'] %}
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1024x576,CODECS="avc1.4d0028,mp4a.40.2",AUDIO="audio"
chunks_1.m3u8
{% endif %}
{% if 'Slides' in video_tracks and video_track in ['HD', 'SD', 'Slides'] %}
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=100000,RESOLUTION=1024x576,CODECS="avc1.4d0028,mp4a.40.2",AUDIO="audio"
chunks_2.m3u8
{% endif %}
""")

		master_playlist_file = os.path.join(
			c.hls_write_path,
			c.stream,
			"%s_%s.m3u8" % (audio_track.lower(), video_track.lower())
		)

		print("Writing Master Playlist-File %s" % master_playlist_file)
		with open(master_playlist_file, "w") as f:
			f.write(master_playlist)


def fanout(c):
	command = fanout_utils.format_and_strip(c, """
ffmpeg -v warning -nostats -nostdin -y -analyzeduration 3000000
	-i {{ pull_url }}
	-c:v copy
	-c:a copy

	{{ maps | join("\n\t") }}

	-hls_time 6
	-hls_list_size 100
	-hls_segment_filename "{{ hls_write_path }}/{{ stream }}/{{ starttime }}-%d_%v.ts"
	-hls_flags +delete_segments+omit_endlist+independent_segments
	-var_stream_map '{{ varmaps | join(" ") }}'
	"{{ hls_write_path }}/{{ stream }}/chunks_%v.m3u8"
""")
	fanout_utils.call(command)



if __name__ == "__main__":
	parser = fanout_utils.setup_argparse(name="hls")

	parser.add_argument('--hls_write_path', metavar='PATH', type=str,
		help='Path to write the HLS-Pieces and Master-Playlists to')

	args = parser.parse_args()

	fanout_utils.mainloop(name="hls", transcoding_stream="h264", calback=fanout_hls, args=args)
