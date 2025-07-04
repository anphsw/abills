#!/usr/bin/perl
=head1 DESCRIPTION

LDAP test

perl Ldap.t user password

=cut

use lib '../../../';
use lib '../../../../Abills/mysql';
use strict;
use Abills::Base;

require '../../../../libexec/config.pl';

our %conf;

my $login = $ARGV[0] || 'test';
my $password = $ARGV[1] || 'test';

require Abills::Auth::Core;
Abills::Auth::Core->import();
my $Auth = Abills::Auth::Core->new({
  CONF      => \%conf,
  AUTH_TYPE => 'Ldap'
});

$Auth->{debug} = 6;
my $result = $Auth->check_access({
  LOGIN    => $login,
  PASSWORD => $password
});

if (!$result) {
  print "!!!!!!!!!!!!!!! Failed\n";
  print "ERROR: $Auth->{errno}";
  print " $Auth->{errstr}\n";
}
else {
  print "Auth OK\n";
}

1;
