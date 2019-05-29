#!/usr/bin/perl
=head NAME internet_static_ip

  GIVE STATICK IP FOR USER FORM IP POOL
  ATTRIBUTES:
    POOL_ID - id of ip pool
    UID - user uid
    ACTION - ACTIVE OR ALERT
  USEGE:
    static_ip POOL_ID=3 UID=1  ACTION=ACTIVE

=cut
use warnings FATAL => 'all';
use strict;

our $libpath;
BEGIN {
  use FindBin '$Bin';

  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../';
  if ($Bin =~ m/\/abills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift(@INC, $libpath,
    $libpath . '/Abills/',
    $libpath . '/Abills/mysql/',
    $libpath . '/Abills/Control/',
    $libpath . '/lib/'
  );
}
do "libexec/config.pl";
our (%conf);

use Abills::SQL;
use Abills::Base qw/_bp parse_arguments ip2int int2ip/;
use Nas;
use Internet;

my $argv = parse_arguments(\@ARGV);

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

my $Nas = Nas->new($db, \%conf);
my $Internet = Internet->new($db, undef, \%conf);

main();

#********************************************************
=head2 main() - main function


=cut
#********************************************************
sub main {
  if ($argv->{'ACTION'} eq 'ACTIVE') {
    active();
  }
  elsif ($argv->{ACTION} eq 'ALERT') {
    alert()
  }

  return 1;
}
#********************************************************
=head2 active() - give static ip for user


=cut
#********************************************************
sub active {
  my $ip_pool = $Nas->ip_pools_info($argv->{POOL_ID});

  my $first_ip = $ip_pool->{IP};
  my $last_ip = int2ip(ip2int($first_ip) + $ip_pool->{COUNTS});

  my $onlines = $Internet->list({
    ONLINE_IP => '>=' . $first_ip . ';<=' . $last_ip,
    COLS_NAME => 1,
    ID        => '_SHOW',
    IP        => '_SHOW',
  });

  my $service = $Internet->list({
    UID       => 1,
    COLS_NAME => 1,
    ID        => '_SHOW',
  });

  my @active = [];
  my $service_id = $service->[0]->{id};

  for my $online (@{$onlines}) {
    push @active, $online->{online_ip};
  }

  for my $i ($ip_pool->{COUNTS}) {
    my $ip = int2ip(ip2int($first_ip) + $i);
    if (grep $_ eq $ip, @active) {}
    else {
      $Internet->change({
        ID  => $service_id,
        UID => $argv->{UID},
        IP  => $ip,
      });
      last;
    }
  }

  return 1;
}

#********************************************************
=head2 alert() - remove static ip from user


=cut
#********************************************************
sub alert {
  my $list = $Internet->list({
    UID       => $argv->{UID},
    ID        => '_SHOW',
    COLS_NAME => 1,
  });

  my $ip = int2ip(0);
  $Internet->change({
    ID  => $list->[0]->{id},
    UID => $argv->{UID},
    IP  => $ip,
  });

  return 1;
}


1;