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

	my $relay = $data->{$host};

	return unless $relay->{cm_deploy};

	printf '  "%s": %d,', $host, $relay->{dns_priority};

	say "";
}

if(@ARGV != 1) {
	say STDERR "usage: $0 relays.json > relays";
	exit 1;
}

my $data = get_relays($ARGV[0]);

my $tags;
foreach my $host (grep {$data->{$_}->{public}} keys %$data) {
	foreach my $tag (@{$data->{$host}{tags}}) {
		push @{$tags->{$tag}}, $host;
	}
}

foreach my $tag (keys %$tags) {
	say "";
	say "lb_${tag}_relays: {";
	foreach my $host (sort @{$tags->{$tag}}) {
		generate($data, $host);
	}
	say "}";
}
