package Collectd::Plugins::Icecast2;

use strict;
use warnings;

use Collectd qw(:all);
use LWP::UserAgent;
use XML::Simple;
use Data::Dumper;

my $ua;

sub get_viewers {
  my ($out) = @_;

  $ua->credentials(
    'localhost:8000',
    'Icecast2 Server',
    '{{ icecast_admin_user | default('admin') }}' => '{{ icecast_admin_password }}'
  );

  my $response = $ua->get(
    'http://localhost:8000/admin/stats.xml'
  );

  unless ($response->is_success) {
    plugin_log(LOG_ERR, "icecast2 status fetch returned: " . $response->status_line());
    return;
  }

  my $ref = XMLin($response->content, ForceArray => 1);

  foreach my $item (@{$ref->{source}}) {
    $out->{$item->{mount}} = $item->{listeners}[0];
  }
}

sub icecast2_read {
  my $viewers = {};

  get_viewers($viewers);

  foreach my $mount (keys %$viewers) {
    plugin_dispatch_values({
      plugin => 'icecast2',
      type => 'users',
      values => [$viewers->{$mount}],
      type_instance => $mount
    });
  }

  return 1;
}

sub icecast2_init {
  $ua = LWP::UserAgent->new(keep_alive => 1);
  $ua->timeout(3);

  plugin_log(LOG_INFO, "icecast2 module initialized");

  return 1;
}

sub icecast2_config {
}

plugin_register(TYPE_READ, "icecast2", "icecast2_read");
plugin_register(TYPE_INIT, "icecast2", "icecast2_init");
plugin_register(TYPE_CONFIG, "icecast2", "icecast2_config");

1;
