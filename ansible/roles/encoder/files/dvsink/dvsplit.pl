#!/usr/bin/perl

# FFMPEG-Output splitten
#
# # ffmpeg [a_lot_options] -f dv pipe:1 | ./split.pl [filename_prefix] [frames_per_file]
#
# # ffmpeg -i inputfile -s 720x576 -aspect 16:9 -pix_fmt yuv420p -vcodec dvvideo -acodec pcm_s16le -ac 2 -ar 48000 -f dv pipe:1 | ./split.pl
#
# by cosrahn


use Fcntl;
use strict;

binmode(STDIN);

my $filename_prefix = $ARGV[0] || "splitfile";
my $filename_suffix = ".dv";
my $max_frames_per_file = $ARGV[1] || 4500;
my $frame_size_in_byte = 144000;

my $buff;
my $count = 0;

my ($seconds, $minutes, $hours, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
my $timestamp = sprintf("%04d.%02d.%02d-%02d_%02d_%02d", $year+1900, $month+1, $day, $hours, $minutes, $seconds);

my $path = sprintf("%s-%s%s", $filename_prefix, $timestamp, $filename_suffix);
printf "$filename_prefix\n";

sysopen(SINK, $path,  O_CREAT | O_WRONLY | O_TRUNC) or die "Couldn't open $path for writing: $!\n";

while (read(STDIN, $buff, $frame_size_in_byte)) {
    if($max_frames_per_file == $count) {
	$count = 0;
	close(SINK);

	($seconds, $minutes, $hours, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
	$timestamp = sprintf("%04d.%02d.%02d-%02d_%02d_%02d", $year+1900, $month+1, $day, $hours, $minutes, $seconds);
	$path = sprintf("%s-%s%s", $filename_prefix, $timestamp, $filename_suffix);

	print "\nCreate New File $path\n";
	sysopen(SINK, $path,  O_CREAT | O_WRONLY | O_TRUNC) or die "Couldn't open $path for writing: $!\n";
    }
    print SINK $buff;
    $count++;
}
close(SINK);
