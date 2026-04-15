#!/usr/bin/perl -w
#**********************************************************
=head1 NAME

 Zabbix Users

  Arguments:
    total/disabled/debt/credit

  Exucute: /usr/abills/misc/zabbix/zabbix_users.pl total

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

BEGIN {
  my $libpath = "$Bin/../../";
  my $sql_type = 'mysql';
  do $libpath . 'libexec/config.pl';

  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . '/lib/',
    $libpath . '/Abills/',
    $libpath
  );
}

use Abills::SQL;
use Admins;
use Users;

our (
  %conf
);

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $users = Users->new( $db, $admin, \%conf );
my $debug = 0;

if ($ARGV[0]) {
  users($ARGV[0]);
}

#**********************************************************
=head2 users($attr) -

  Arguments:
    total/disabled/debt/credit

  Result:
    integer

=cut
#**********************************************************
sub users {
  my ($attr) = @_;

  if($attr eq 'license') {
    $users->{PRE_ADD} = 1;
    $users->check_params();

    print $users->{ll} || 0;
    print "\n";

    return 1;
  }

  my %search_params = ();
  $search_params{DISABLE} = '>0' if ($attr eq 'disabled');
  $search_params{DEPOSIT} = '<0' if ($attr eq 'debt');
  $search_params{CREDIT} = '>0'  if ($attr eq 'credit');

  if ($debug) {
    $users->{debug} = 1;
  }

  $users->list({ %search_params });

  print $users->{TOTAL} || 0;
  print "\n";

  return 1;
}

1;