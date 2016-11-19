#!/usr/bin/env perl

use v5.12;
use strict;
use warnings;

use File::Slurp;

sub get_edid {
	my $ret;

	opendir(my $dh, '/sys/class/drm');

	while(my $port = readdir $dh) {
		next unless $port =~ /^card\d+-/;

		my $enabled = read_file("/sys/class/drm/$port/enabled") =~ 'enabled';
		$ret->{$port}{enabled} = $enabled;

		if($enabled) {
			$ret->{$port}{edid} = read_file("/sys/class/drm/$port/edid");
		}
	}

	return $ret;
}

if(@ARGV < 1) {

	say STDERR "usage:";
	say STDERR " list ports: $0 -l";
	say STDERR " create epiphan EDID from port: $0 port";

	exit 1;
}

say STDERR "reading EDIDs";
my $edids = get_edid;

if($ARGV[0] eq '-l') {
	say STDERR "available ports:";

	for my $port (sort keys %$edids) {
		say STDERR " - $port (" . ($edids->{$port}{enabled} ? 'enabled' : 'disabled') . ")";
	}
} else {
	my $port = shift @ARGV;

	if(not exists $edids->{$port}) {
		say STDERR "unknown port: $port";
		exit 1;
	}

	print "EDID BYTES:\r\n";

	print "0x   00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\r\n";
	print "    ------------------------------------------------";

	my @bytes = unpack 'C*', $edids->{$port}{edid};
	my $cnt = 0;
	for my $byte (@bytes) {
		if($cnt % 16 == 0) {
			printf("\r\n%02X |", $cnt);
		}

		printf(" %02X", $byte);

		$cnt++;
	}

	print "\r\n";
}
