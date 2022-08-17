#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use lib '../../../';

if (use_ok ('Abills::Backend::Plugin::Websocket::Admin')) {
  require Abills::Backend::Plugin::Websocket::Admin;
  Abills::Backend::API->import()
}

my $test_aid = 1;
my $test_chunk = qq{
Cookie: sid=testadmin1
};

my $authentication = Abills::Backend::Plugin::Websocket::Admin::authenticate($test_chunk);
ok($authentication == $test_aid, "Authenticated $test_aid as aid : $authentication");

done_testing();
