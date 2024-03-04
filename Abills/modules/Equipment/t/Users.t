#!/usr/bin/perl

use strict;
use warnings;

use FindBin '$Bin';
use lib '../../',
  $Bin . '/../../../mysql/',
  $Bin . '/../../../module/',
  $Bin . '/../../../../lib/';

use Test::More qw/no_plan/;
use Abills::SQL;
use Abills::Base qw(parse_arguments show_hash);
require Abills::Misc;

my $argv = parse_arguments(\@ARGV);
my $uid = $argv->{UID} || 651128905;

our (%conf, $admin);
require_ok($Bin . '/../../../' . "../libexec/config.pl");
require_ok('Equipment::Users');

my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  });

use Equipment::Users;
my Equipment::Users $Equipment_user = new_ok('Equipment::Users', [ $db, $admin, \%conf ]);

ok(my $devices = $Equipment_user->devices({ UID => $uid }), 'Get divices');

foreach my $d (@{$devices}) {
  print "UID: $d->{uid} NAS_ID: $d->{nas_id} PORT: $d->{port}\n";

  ok($Equipment_user->cpe_info({ NAS_ID => $d->{nas_id}, PORT => $d->{port}, SIMPLE => 1 }), 'Get equipment info');

  if ($Equipment_user->{CPE_INFO} && ref $Equipment_user->{CPE_INFO} eq 'HASH') {
    show_hash($Equipment_user->{CPE_INFO}, { DELIMITER => "\n" });
  }

  ok($Equipment_user->cpe_info({ NAS_ID => $d->{nas_id}, PORT => $d->{dhcp_port}, SIMPLE => 1 }), 'Get simple equipment info');
}

1