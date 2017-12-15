#!/usr/bin/perl -w
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "1.00";

my $CHAN_NAME = '#voc-mixer';

%IRSSI = (
    authors     => 'dedeibel',
    contact     => 'dedeibel@arcor.de',
    name        => 'selwin.pl',
    description => 'Select a channel window when joined: '. $CHAN_NAME,
    license     => 'GNU General Public License',
    url         => 'https://c3voc.de',
    changed     => 'Do 14. Dez 23:47:45 CET 2017',
);

Irssi::theme_register([
    'active_notice_loaded', '%R>>%n %_Scriptinfo:%_ Loaded $0 version $1 - automatically selecting win '. $CHAN_NAME
]);

sub on_joined {
    my ($channel_ref) = @_;

    my $joined       = $channel_ref->{'joined'};
    my $channel_name = $channel_ref->{'name'};

    return unless $channel_name eq $CHAN_NAME;

    foreach my $window (Irssi::windows()) {
      next unless defined $window->{'active'};
      next unless $window->{'active'}{'type'} eq 'CHANNEL';
      next unless $window->{'active'}{'name'} eq $CHAN_NAME;
      $window->set_active();
      last;
    }
}

Irssi::signal_add('channel joined', 'on_joined');
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'active_notice_loaded', $IRSSI{name}, $VERSION, $IRSSI{authors});

