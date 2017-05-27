#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;

use AnyEvent;
use AnyEvent::MQTT;
use JSON;
use Config::Tiny;

my $cfg = Config::Tiny->read('mqtt.conf');
my $mqtt_server = $cfg->{_}->{mqtt_server};
my $mqtt_user = $cfg->{_}->{mqtt_user};
my $mqtt_password = $cfg->{_}->{mqtt_password};
my $mqtt_topic = $cfg->{_}->{mqtt_topic};
my $mqtt_component = $cfg->{_}->{mqtt_component};

sub on_error_cb {
  my ($fatal, $message) = @_;
  warn "error: $message (fatal: $fatal)";
}

my $mqtt = AnyEvent::MQTT->new(
  host => $mqtt_server,
  user_name => $mqtt_user,
  password => $mqtt_password,
  on_error => \&on_error_cb
  );

$mqtt->connect;

sub alert {
	my ($level, $msg) = @_;

	say $msg;

	my $cv = $mqtt->publish(topic => $mqtt_topic,
		message => encode_json({
				component => $mqtt_component,
				level => $level,
				msg => $msg
			}));
  $cv->recv;
}

my $mqtt_level = shift;
my $MSG = join(" ", @ARGV);
#print "'$MSG'", "\n";
alert($mqtt_level => "$MSG");

