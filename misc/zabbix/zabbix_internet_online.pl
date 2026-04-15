#!/usr/bin/perl -w
#**********************************************************
=head1 NAME

 Zabbix internet online

  Arguments:
    online/reconnect/recovery/zapped

  Example: /usr/abills/misc/zabbix/zabbix_internet_online.pl zapped

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

BEGIN {
  my $libpath = "$Bin/../../";
  my $sql_type = 'mysql';
  require $libpath . 'libexec/config.pl';

  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'Abills/modules/',
    $libpath . '/lib/',
    $libpath . '/Abills/',
    $libpath
  );
}

use Abills::SQL;
use Abills::Base qw(in_array);
use Admins;
use Internet::Sessions;

our (
  %conf,
);

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

if ($ARGV[0]){
  internet_online($ARGV[0]);
}


#**********************************************************
=head2 internet_online($attr) -

  Arguments:
    online/reconnect/recovery/zapped

  Result:
    integer

=cut
#**********************************************************
sub internet_online {
  my ($attr) = @_;

  $Sessions->online({ STATUS_COUNT => 1  });

  print $Sessions->{ONLINE_COUNT}    || 0 if ($attr eq 'online');
  print $Sessions->{RECONNECT_COUNT} || 0 if ($attr eq 'reconnect');
  print $Sessions->{RECOVER_COUNT}   || 0 if ($attr eq 'recovery');
  print $Sessions->{ZAPPED_COUNT}    || 0 if ($attr eq 'zapped');
  print $Sessions->{GUEST_COUNT}    || 0 if ($attr eq 'guest');
  print $Sessions->{UNKNOWN_COUNT}    || 0 if ($attr eq 'unknown');

  print "\n";

  return 1;
}

1;