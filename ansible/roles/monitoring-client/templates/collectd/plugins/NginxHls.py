#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys, os, re, urllib, datetime, itertools, subprocess, collections, logging, urllib2
from os.path import basename, dirname, splitext
from urlparse import urlparse

logging.basicConfig(level=logging.ERROR, format='%(levelname)8s %(name)s: %(message)s')

# path to the access-log containing the nginx-access-logs
nginx_accesslog = '/var/log/nginx/access.log'

# how long should viewers be counted as "live"
# viewer will seem to stay online for that number of seconds, even if they have already switched off
minimum_update_period = 30 # seconds

##### helper methods #####
# see: http://stackoverflow.com/a/260433/1659732
def reversed_lines(file):
	"Generate the lines of file in reverse order."
	part = ''
	for block in reversed_blocks(file):
		for c in reversed(block):
			if c == '\n' and part:
				yield part[::-1]
				part = ''
			part += c
	if part: yield part[::-1]


def reversed_blocks(file, blocksize=4096):
	"Generate blocks of file's contents in reverse order."
	file.seek(0, os.SEEK_END)
	here = file.tell()
	while 0 < here:
		delta = min(blocksize, here)
		here -= delta
		#print "read block from {0} to {1}".format(here, here+delta)
		file.seek(here, os.SEEK_SET)
		yield file.read(delta)


# see: http://stackoverflow.com/a/4080021/1659732
def parse_logdate(datestr):
	"""
	Parse a strictly formatted Date from a Common-Format-Logfile into a
	datetime-object (doing it manuall is faster then strptime)
	"""

	month_abbreviations = {
		'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
		'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
		'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
	}

	year = int(datestr[7:11])
	month = month_abbreviations[datestr[3:6]]
	day = int(datestr[0:2])
	hour = int(datestr[12:14])
	minute = int(datestr[15:17])
	second = int(datestr[18:20])

	return datetime.datetime(year, month, day, hour, minute, second)

##### numbercrunching methods #####
def count_hls_viewers():
	"Count the number of live-viewer for each available hls-playlist"
	# - read all lines from the access-log which concern the last minimum_update_periodx2 seconds,
	#   the ×2 gives us a little buffer because not all players ask exactly
	#	every minimum_update_period-seconds
	# - store each ip + ident which requested the playlist in a set to eliminate duplicates
	# - count the set keys

	# regex to parse interesting parts of ngix access-log
	exp = '^([^ ]+) ([^ ]+) ([^ ]+) \[([^\]]+)\] "([A-Z]+) ([^ "]+) HTTP\/1.[01]" ([0-9]{3})'

	# compare timestamp
	now = datetime.datetime.today()

	# viewer-count per stream
	viewer_counts = collections.Counter()
	counters = {}

	# open the access-log
	logging.debug('reading access-log %s', nginx_accesslog)
	with open(nginx_accesslog) as f:
		for line in reversed_lines(f):
			# parse line by line
			match = re.match(exp, line)
			if not match:
				break

			(ip, ident, username, tstamp, method, path, code) = match.groups()

			# parse date
			tstamp = parse_logdate(tstamp)

			# calculate number of seconds this record is old
			age = int((now - tstamp).total_seconds())

			#print 'parse line:', path, tstamp, method, age, code

			# quit parsing when we reached the end of our window
			# double the update_period to give us some buffer
			if age > minimum_update_period * 2:
				break

			# add successful playlist requests to sets
			if code[0] == "2" and path[-5:] == ".m3u8":
				# ensure unescaped path
				path = dirname(urlparse(path).path)

				# create set
				if not path in counters:
					counters[path] = set()

				# add ip
				counters[path].add(ip)

	# count set lengths
	for path in counters:
                key = basename(path) + "_hls"
                viewer_counts[key] = len(counters[path])

	return viewer_counts

try:
	import collectd

	def read(data=None):
		for stream, viewer in count_hls_viewers().items():
			vl = collectd.Values(plugin='hls', type='users', type_instance=stream, values=[viewer])
			vl.dispatch()

	collectd.register_read(read)

except ImportError:
	print('collectd module not found, assuming test-run')
	viewers = count_hls_viewers().items()

	print('detected the following streams:')
	for stream, viewer in viewers:
		print('  %s: %u' % (stream, viewer))
