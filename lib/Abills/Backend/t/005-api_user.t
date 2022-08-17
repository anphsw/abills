#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

use lib '../../../';

use Abills::Base qw(parse_arguments);

our %conf;
my $ARGS = parse_arguments(\@ARGV);

my $test_user = $ARGS->{user} || 1;

if (use_ok('Abills::Backend::API')) {
  require Abills::Backend::API;
  Abills::Backend::API->import()
}

my Abills::Backend::API $api = new_ok('Abills::Backend::API', [ \%conf ]);

SKIP :{
  skip("Can't connect to Internal server", 1) unless ($api->is_connected);

  # Check we have 1 admin connected
  my $is_admin_connected = $api->is_receiver_connected($test_user, 'USER');
  skip("No test user online", 1) unless $is_admin_connected;

  ok($is_admin_connected, "Have user 1 online");
  # Try to ping user 1
  ok($api->call($test_user, '{"TYPE":"PING"}'), 'Ping admin 1');

  ok(!$api->is_receiver_connected(1000000, 'USER'), "User 1000000 should not be online");

  # Try intensive ping
  for (1 ... 100) {
    $api->is_receiver_connected(1, 'USER');
  }
  ok($test_user, "Alive after 100 pings");
}

done_testing();

1;
