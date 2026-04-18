#!/usr/bin/env perl

use v5.12;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::MQTT;
use JSON;
use Text::Glob qw(match_glob);

##########
# config #
##########

foreach my $var (qw(MQTT_SERVER MQTT_USER MQTT_PASSWORD)) {
	die "environment variable $var is missing" unless defined $ENV{$var};
}

my $mqtt = AnyEvent::MQTT->new(host => $ENV{MQTT_SERVER}, user_name => $ENV{MQTT_USER}, password => $ENV{MQTT_PASSWORD});

my $hosts;

sub alert {
	my ($level, $msg, $component) = @_;

	say $msg;

	$mqtt->publish(topic => "/voc/alert",
		message => encode_json({
				component => $component //= "watchdog",
				level => $level,
				msg => $msg
			}));
}

sub expire {
	my ($hostname) = @_;

	alert(ERROR => "expiring host" => "watchdog/$hostname");
	delete $hosts->{$hostname};
}

sub match_host {
	my ($hostname, $pattern) = @_;

	local $Text::Glob::seperator = '.';

	return match_glob($pattern, $hostname);
}

alert(INFO => "checkin watchdog restarted, supressing checkin messages for 90 seconds");
my $suppress = 1;
my $startup = time;

$mqtt->subscribe(topic => "/voc/shutdown", callback =>
	sub {
		my (undef, $data) = @_;
		my $now = time;
		my $json;

		eval {
			$json = decode_json($data);
		};

		return unless defined $json;
		return unless defined $json->{name};

		my $hostname = $json->{name};
		my $host = $hosts->{$hostname};

		printf("%d: received shutdown from %s\n", $now, $hostname);
		alert(WARN => "host is shutting down" => "watchdog/$hostname");
		if ($host) {
		        delete $hosts->{$hostname};
		}
	}
);

$mqtt->subscribe(topic => "/voc/checkin", callback =>
	sub {
		my (undef, $data) = @_;
		my $now = time;
		my $json;

		eval {
			$json = decode_json($data);
		};

		return unless defined $json;
		return unless defined $json->{name};

		my $hostname = $json->{name};
		my $host = $hosts->{$hostname};

		printf("%d: checkin from %s", $now, $hostname);
		if ($host and defined $host->{last_checkin}) {
			printf(", last checkin %d seconds ago\n", $now - $host->{last_checkin});
		} else {
			printf(", first checkin\n");
		}

		if (not exists $hosts->{$hostname}) {
			$hosts->{$hostname} = {
				last_checkin => $now,
				interval => $json->{interval} // 60,
				slacking => 0,
			};

			alert(INFO => "new host checked in" => "watchdog/$hostname") unless $suppress;

			return;
		}

		my $was_rebooted = 0;

		# check if uptime went backwards
		if (exists $host->{last_uptime}) {
			if (not exists $json->{additional_data}{uptime}) {
				alert(ERROR => "host stopped reporting uptime" => "watchdog/$hostname");
			} elsif($json->{additional_data}{uptime} < $host->{last_uptime}) {
				$was_rebooted = 1;
				alert(ERROR => "host was rebooted" => "watchdog/$hostname");
			}
		}

		if (exists $json->{additional_data}{uptime}) {
			$host->{last_uptime} = $json->{additional_data}{uptime};
		}

		# handle slacking recovery
		if ($host->{slacking} and not $was_rebooted) {
			alert(INFO => "host is no longer slacking" => "watchdog/$hostname");
		}

		$host->{last_checkin} = $now;
		delete $host->{last_missed};
		$host->{slacking} = 0;
	});

$mqtt->subscribe(topic => "/voc/ircbot/command", callback =>
	sub {
		my (undef, $data) = @_;
		my $json;

		eval {
			$json = decode_json($data);
		};

		return unless defined $json;
		return unless $json->{component} eq 'watchdog';

		my $cmd = $json->{msg};
		if ($cmd =~ /^expire (.*)/) {
			my $pattern = $1;
			my $matched = 0;

			for my $hostname (keys %$hosts) {
				 if (match_host($hostname, $pattern)) {
					 expire($hostname);
					 $matched = 1;
				 }
			}

			if (not $matched) {
				alert(ERROR => "no matches found");
			}
		} elsif ($cmd eq 'list') {
			alert(INFO => 'currently watching hosts:');

			my $list;
			foreach my $hostname (sort keys %$hosts) {
				$list .= " $hostname";
				if (length($list) > 160) {
					alert(INFO => " $list");
					$list = "";
				}
			}

			if (length($list) > 0) {
				alert(INFO => " $list");
			}
		}
	});

my $timer = AnyEvent->timer(after => 0, interval => 10, cb =>
	sub {
		my $now = time;

		if ($suppress and ($now - $startup) > 90) {
			printf("%d: ending initial suppression\n", $now);
			$suppress = 0;
		}

		foreach my $hostname (keys %$hosts) {
			my $host = $hosts->{$hostname};

			my $missed = int(($now - $host->{last_checkin}) / $host->{interval});
			next if $missed == 0;
			next if $missed == 1 and ($now - $host->{last_checkin}) < $host->{interval} * 1.2; # allow some jitter

			$host->{slacking} = 1;

			if (not defined $host->{last_missed} or $missed != $host->{last_missed}) {
				$host->{last_missed} = $missed;

				alert(WARN => "host missed " .
					(($missed == 1) ? "a checkin" : "$missed checkins") => "watchdog/$hostname"
				);

				if ($missed >= 4) {
					expire($hostname);
				}
			}
		}
	});

AnyEvent->condvar->recv;
