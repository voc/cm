#!/usr/bin/env python3

import os
import sys
import glob
import time
import json
import shlex
import signal
import random
import argparse
import subprocess
import collections
import urllib.parse

import jinja2

class Context(collections.MutableMapping):
	'''
	Mapping that works like both a dict and a mutable object, i.e.
	d = D(foo='bar')
	and 
	d.foo returns 'bar'
	and can also be added upon to update
	'''

	# ``__init__`` method required to create instance from class.
	def __init__(self, *args, **kwargs):
		'''Use the object dict'''
		self.__dict__.update(*args, **kwargs)

	# The next five methods are requirements of the ABC.
	def __setitem__(self, key, value):
		self.__dict__[key] = value
	def __getitem__(self, key):
		return self.__dict__[key]
	def __delitem__(self, key):
		del self.__dict__[key]
	def __iter__(self):
		return iter(self.__dict__)
	def __len__(self):
		return len(self.__dict__)

	# These two methods aren't required, but nice for demo purposes:
	def __str__(self):
		'''returns simple dict representation of the mapping'''
		return str(self.__dict__)
	def __repr__(self):
		'''echoes class, id, & reproducible representation in the REPL'''
		return '{}, Context({})'.format(super(Context, self).__repr__(), 
								  self.__dict__)

	# Allow Adding Contexts together
	def __radd__(self, other):
		return self.__add__(other)

	def __add__(self, other):
		self.__dict__.update(other)
		return self


def setup_argparse(name):
	parser = argparse.ArgumentParser(description='Fans out an %s stream' % name)
	parser.add_argument("--stream", metavar="S", type=str, required=True,
		help="Name of the Stream to fan out (ie. 's4' or 'q1')")

	parser.add_argument('--pull_endpoint', type=str, required=True,
		help="HTTP-Endpoint to pull the Source-Stream from, (ie. 'live.ber.c3voc.de:7999')")

	return parser


def call(command):
	print("Starting command: \n----\n%s\n----\n" % command)
	try:
		subprocess.check_call(shlex.split(command))
	except subprocess.CalledProcessError:
		pass


def remove_glob(pattern):
	for file in glob.glob(pattern):
		os.remove(file)


def analyze_tracks(pull_url):
	cmd = "ffprobe -v quiet -print_format json -show_format -show_streams %s" % pull_url
	response = subprocess.check_output(shlex.split(cmd))

	response_parsed = json.loads(response.decode("utf-8"))
	video_tracks = filter(lambda stream: stream['codec_type'] == "video", response_parsed['streams'])
	audio_tracks = filter(lambda stream: stream['codec_type'] == "audio", response_parsed['streams'])

	video_track_names = map(lambda stream: stream['tags']['title'], video_tracks)
	audio_track_names = map(lambda stream: stream['tags']['title'], audio_tracks)

	return list(set(video_track_names)), list(set(audio_track_names))


def validate_stream_configuration(video_tracks, audio_tracks, audio_only=False, thumbnail=False):
	if thumbnail:
		if "Poster" not in video_tracks:
			raise Exception("Poster Track missing")
		if "Thumbnail" not in video_tracks:
			raise Exception("Thumbnail Track missing")
		return

	if not audio_only:
		if "HD" not in video_tracks:
			raise Exception("HD-Video-Track missing")

		if "Slides" in video_tracks and "SD" not in video_tracks:
			raise Exception("Slides-Track is only supported if SD-Track is also present")

	if "Native" not in audio_tracks:
		raise Exception("HD-Video-Track missing")

	if "Translated-2" in audio_tracks and not "Translated" in audio_tracks:
		raise Exception("Translated-2-Track is only supported if Translated-Track is also present")


def format(context, template_string):
	env = jinja2.Environment(
		autoescape=False,
		trim_blocks=True,
		lstrip_blocks=True)

	template = env.from_string(template_string)
	return template.render(context)


def format_and_strip(context, template_string):
	rendered = format(context, template_string)
	return rendered.lstrip()

class ExitException(Exception):
	def __init__(self, signum):
		super(ExitException, self).__init__(f"Caught signal {signum}")

def signal_handler(signum, frame):
	raise ExitException(signum)

def random_duration():
	return 2 + random.random()

def do_sleep(timer, sleep_time):
	now = time.time()
	if now - timer < 10:
		sleep_time = min(10, sleep_time + random_duration())
	else:
		sleep_time = random_duration()
	print(f"sleeping for {sleep_time:0.1f}s")
	time.sleep(sleep_time)
	return sleep_time

def mainloop(name, transcoding_stream, calback, args=None):
	if args is None:
		parser = fanout_utils.setup_argparse(name=name)
		args = parser.parse_args()

	pull_url = urllib.parse.urljoin(
		'http://' + args.pull_endpoint,
		"%s_%s" % (args.stream, transcoding_stream))

	print("Starting loop for %s-transcoding of Stream %s (%s)" % (name, args.stream, pull_url))

	# install signal handlers
	signal.signal(signal.SIGINT, signal_handler)
	signal.signal(signal.SIGTERM, signal_handler)
	signal.signal(signal.SIGQUIT, signal_handler)

	timer = 0
	sleep_time = 0
	try:
		while True:
			try:
				print("Analyzing Tracks of %s" % pull_url)
				timer = time.time()
				video_tracks, audio_tracks = analyze_tracks(pull_url)
			except subprocess.CalledProcessError:
				print("Analyzing Tracks failed, sleeping")
				sleep_time = do_sleep(timer, sleep_time)
				continue

			print("Found stream with video_tracks=%s and audio_tracks=%s" %
				(str(video_tracks), str(audio_tracks)))

			validate_stream_configuration(video_tracks, audio_tracks, audio_only=(transcoding_stream == 'audio'),
				thumbnail=(transcoding_stream == "thumbnail"))

			print("Starting fanout")
			ctx = Context({
				"pull_url": pull_url,

				"video_tracks": video_tracks,
				"audio_tracks": audio_tracks,
			})
			ctx += args.__dict__

			timer = time.time()
			calback(ctx)
			print("Fanout failed, sleeping")
			sleep_time = do_sleep(timer, sleep_time)

	except ExitException:
		pass

	print("Terminating")
