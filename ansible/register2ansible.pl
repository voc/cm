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

	foreach my $relay (values %$json) {
		$relay->{ips}{ipv4} = [
			grep(!/^10/, @{$relay->{ips}{ipv4}})
		];
	}

	return $json;
}

sub yesno {
	return shift(@_) ? 'yes' : 'no';
}

sub get_ip {
	my ($data, $name) = @_;

	my $relay = $data->{$name};

	my $ip;

	if($relay->{ips}{register} =~ /^[0-9.]+$/) {
		$ip = $relay->{ips}{register};
	} elsif(@{$relay->{ips}{ipv4}} == 1) {
		$ip = $relay->{ips}{ipv4}[0];
	} else {
		warn "could not find a safe ip for relay " . $name;
		$ip = $relay->{ips}{register};
	}

	$ip =~ s!^([0-9a-f:.]+).*!$1!;

	return $ip;
}

sub has_tag {
	my ($relay, $tag) = @_;

	grep {$_ eq $tag} @{$relay->{tags}};
}

sub generate {
	my ($data, $host) = @_;

	my $relay = $data->{$host};

	return if not $relay->{cm_deploy};
	return if has_tag($relay, 'voc');

	my $icecast = has_tag($relay, 'icecast');
	my $hls = has_tag($relay, 'hls');
	my $dash = has_tag($relay, 'dash');
	my $relive = has_tag($relay, 'relive');
	my $nginx = $hls || $relive || $dash || $icecast; # icecast needs an SSL proxy

	return unless $nginx or $icecast;

	my $master = $relay->{master};

	printf "%-30s nginx=%s icecast=%s", $host, yesno($nginx), yesno($icecast);

	if($icecast) {
		if($master) {
			printf " icecast_master_ip=%s", get_ip($data, $master);
		}
	}

	if($master) {
		#printf ' nginx_hls_relive_masters=\'["%s"]\'', get_ip($data, $master);
		printf ' nginx_stream_masters=\'["%s"]\'', get_ip($data, $master);
	}

	say "";
}

if(@ARGV != 1) {
	say STDERR "usage: $0 relays.json > inventory/relays.yml";
	exit 1;
}

my $data = get_relays($ARGV[0]);

my $cnt = 0;

print <<EOF;
# managed by register2ansible.pl
[relays:children]
master_relays
edge_relays

EOF

say "[master_relays]";
foreach my $host (grep { not $data->{$_}->{public}}
	sort keys %$data) {
	generate($data, $host);

	$cnt++;
}
say "";

say "[edge_relays]";
foreach my $host (grep { $data->{$_}->{public}}
	sort keys %$data) {
	generate($data, $host);

	$cnt++;
}

say STDERR "Generated records for $cnt of " . scalar(keys %$data) . " relays";
