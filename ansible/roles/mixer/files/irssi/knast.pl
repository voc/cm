#!/usr/bin/perl -w
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "1.00";

# Not a perfect solution but it is not intended to be bullet proof
# anyway. You should still be able to reconnect, join the channel
# and disable this script for full access.
my @allowed_commands = (
  qr(^[^/]),
  qr(^/join #voc-mixer$)i,
  qr(^/connect hackint$)i,
  qr(^/reconnect hackint$)i,
  qr(^/server list$)i,
  qr(^/names$)i,
  qr(^/help$)i,
  qr(^/info$)i,
  qr(^/script (load|unload) knast$)i,
);

%IRSSI = (
    authors     => 'dedeibel',
    contact     => 'dedeibel@arcor.de',
    name        => 'knast.pl',
    description => 'Disallow most commands that could cause trouble',
    license     => 'GNU General Public License',
    url         => 'https://c3voc.de',
    changed     => 'Fr 15. Dez 01:06:11 CET 2017',
);

Irssi::theme_register([
    'active_notice_loaded', '%R>>%n %_Scriptinfo:%_ Loaded $0 version $1 - disable disallowed commands'
]);

sub on_cmd {
  my ($args, $server, $window_item) = @_;

  my $ok = 0;
  for my $allowed_re (@allowed_commands) {
    if ($args =~ $allowed_re) {
      $ok = 1;
      last;
    }
  }

  if (! $ok) {
    my $awin = Irssi::active_win();
    $awin->print('Please do not do that', MSGLEVEL_NOTICES);
    Irssi::signal_stop();
  }
}

Irssi::signal_add('send command', 'on_cmd');
Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'active_notice_loaded', $IRSSI{name}, $VERSION, $IRSSI{authors});

