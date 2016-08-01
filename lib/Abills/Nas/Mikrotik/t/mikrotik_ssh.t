#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;

my $debug = 0;
my $test_host = '192.168.0.11';

my $test_comment = "ABills test. you can remove this";

my $test_add_lease_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=dhcp1 disabled=yes comment=\"$test_comment\"";
my $test_add_lease_bad_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=dhasdsdfcp1 disabled=yes comment=\"$test_comment\"";
my $remove_lease_command = "/ip dhcp-server lease remove numbers=[find comment=\"$test_comment\"]";

require_ok( 'Abills::Base' );
require_ok( 'Abills::Nas::Mikrotik::SSH' );

my $mikrotik = Abills::Nas::Mikrotik::SSH->new( { nas_mng_ip_port => "$test_host:0:22", nas_type => 'mikrotik' },
  undef,
  { DEBUG => $debug } );

ok( ref $mikrotik eq 'Abills::Nas::Mikrotik::SSH', "Constructor returned Abills::Nas::Mikrotik::SSH object" );
if ( !ok( $mikrotik->check_access(), "Has access to $test_host" ) ){
  die ( "Host is not accesible\n" );
}
ok( $mikrotik->execute( "/system identity print" ), "Execute single" );
ok( $mikrotik->execute( [ "/system identity print", "system resource cpu print" ] ), "Execute 2 commands" );
ok( !$mikrotik->execute( [ "/some undefined command" ] ), "Holding errors (Executing bad command)" );

my $ip_addresses = $mikrotik->get_list( 'ip_a' );
ok( scalar ( @{$ip_addresses} ) > 0, "Got non-empty list of IP addresses" );
ok ( ref $ip_addresses->[0] eq 'HASH', "List contains hashes" );

my $dhcp_servers_list = $mikrotik->get_list( 'dhcp_servers' );
ok( scalar ( @{$dhcp_servers_list} ) > 0, "Got non-empty list of DHCP-Servers" );
ok ( ref $dhcp_servers_list->[0] eq 'HASH', "List contains hashes" );

ok( $mikrotik->execute( $test_add_lease_command ), "Added lease" );

my $leases_list = $mikrotik->get_list( 'dhcp_leases' );
ok( scalar ( @{$leases_list} ) > 0, "Got non-empty list of leases" );
ok ( ref $leases_list->[0] eq 'HASH', "List contains hashes" );

ok( $mikrotik->execute( $remove_lease_command ), "Removed test lease" );
#ok( $mikrotik->execute( $test_add_lease_bad_command ) == 0, "Added lease with bad dhcp-server name throws error" );

done_testing();

