#!/usr/bin/env perl

use v5.12;
use strict;
use warnings;

use File::Slurp;
use JSON;

sub get_relays {
	my ($path) = @_;

	my $content = read_file($path) or die "Reading relay file failed: $@";
	my $json = decode_json($content) or die "Decoding JSON failed: $@";

	return $json;
}

sub has_tag {
	my ($relay, $tag) = @_;

	grep {$_ eq $tag} @{$relay->{tags}};
}

sub generate {
	my ($data, $host) = @_;

	# HACK: filter US relays, those are configured manually
	return if $host =~ /^us[12]\.1und1/;

	my $relay = $data->{$host};
	printf '  "%s": %d,', $host, $relay->{dns_priority};

	say "";
}

if(@ARGV != 1) {
	say STDERR "usage: $0 relays.json > relays";
	exit 1;
}

my $data = get_relays($ARGV[0]);

my $cnt = 0;

foreach my $type (qw(hls relive icecast dash)) {
	say "";
	say "lb_${type}_relays: {";
	foreach my $host (grep { $data->{$_}->{public} and has_tag($data->{$_}, $type)}
		sort keys %$data) {
		generate($data, $host);
	}
	say "}";
}
