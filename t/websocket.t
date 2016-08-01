#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

our %conf;
require '../libexec/config.pl'; # assunming we are in /usr/abills/t/
use lib '../lib';
use lib '../Abills/mysql';

my $plans_count = 17;
plan tests => $plans_count;

my $test_aid = 1;

my $ping_request = '{"TYPE":"PING"}';
my $ping_responce = '{"TYPE":"PONG"}';

my $test_notification = <<"TEST_NOTIFICATION";
{
  "TYPE" : "MESSAGE",
  "TITLE" : "Test notification",
  "TEXT" : "Just<br/>some<br/>text"
}
TEST_NOTIFICATION


# Create new Connection
require_ok( 'AnyEvent' );
require_ok( 'AnyEvent::Socket' );
require_ok( 'AnyEvent::Handle' );
require_ok( 'AnyEvent::Impl::Perl' );

SKIP : {
  skip 'No Asterisk::AMI tests required' if (!$conf{EVENTS_ASTERISK});
  require_ok( 'Asterisk::AMI' );
}

require_ok( 'Abills::Sender::Browser' );

my $Browser = new_ok( 'Abills::Sender::Browser' => [ \%conf ] );

can_ok( $Browser, 'is_connected' );
can_ok( $Browser, 'connected_admins' );
can_ok( $Browser, 'has_connected_admin' );
can_ok( $Browser, 'send_message' );
can_ok( $Browser, 'call' );

ok( $Browser->is_connected(), 'Browser connected to backend server' );
ok( $Browser->connected_admins(), 'Should have clients connected to run tests' );

SKIP_BROWSER_CLIENT_CHECK : {
  my $test_admin_connected = $Browser->has_connected_admin( $test_aid );
  skip ( 'No test admin connected', 3 ) unless ($test_admin_connected);
  ok( $test_admin_connected, 'Our test admin ' . $test_aid . ' should be connected' );
  ok( $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification } ), 'Should be able to send message' );
  is_deeply( $Browser->call( $test_aid, $ping_request ), { TYPE => 'PONG' }, "Responce for $ping_request should be $ping_responce" );

  #Extensive ping
  my $count = 10000;
  while($count--){
    ok( $Browser->send_message( { AID => $test_aid, MESSAGE => $test_notification } ), 'Should be able to send message' );
  };
}


# TODO: check asterisk connection

done_testing();