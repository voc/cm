package Collectd::Plugins::NginxRtmp;

use strict;
use warnings;

use Collectd qw( :all );
use LWP::UserAgent;
use XML::Simple;

my $ua;

sub get_viewers {
	my ($url, $out) = @_;

	my $resp = $ua->get($url);

	if(not $resp->is_success) {
		plugin_log(LOG_ERR, "rtmp status fetch on ${url} returned: " . $resp->status_line());
		return;
	}

	my $xml = $resp->decoded_content;
	my $status = XMLin($xml, ForceArray => 1);

	my $streams = $status->{server}[0]{application}[0]{live}[0]{stream};
	foreach my $stream (@$streams) {
		next if $stream->{name}[0] !~ /^s/;

		my $viewers = 0;
		foreach my $client (@{$stream->{client}}) {
			next if ($client->{flashver}[0] // '') eq 'ngx-local-relay'; #autopush client
			next if defined $client->{publishing};

			$viewers++;
		}

		$out->{$stream->{name}[0]} += $viewers;
	}
}

my @urls = qw(
{% for id in range(0,(nginx_worker_processes | default('2'))) %}
  http://127.0.0.1:900{{ id }}/stats/rtmp
{% endfor %}
);

sub rtmp_read {
	my $viewers = {};
	foreach my $url (@urls) {
		get_viewers($url, $viewers);
	}

	foreach my $stream (keys %$viewers) {
		plugin_dispatch_values({
			plugin => 'rtmp',
			type => 'users',
			values => [$viewers->{$stream}],
			type_instance => $stream
		});
	}

	return 1;
}

sub rtmp_init {
	$ua = LWP::UserAgent->new(keep_alive => 1);
	$ua->timeout(3);

	plugin_log(LOG_INFO, "rtmp module initialized");

	return 1;
}

sub rtmp_config {
}

plugin_register(TYPE_READ, "rtmp", "rtmp_read");
plugin_register(TYPE_INIT, "rtmp", "rtmp_init");
plugin_register(TYPE_CONFIG, "rtmp", "rtmp_config");

1;
