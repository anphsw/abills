#!/usr/bin/perl
=head NAME internet_static_ip

  GIVE STATICK IP FOR USER FORM IP POOL
  ATTRIBUTES:
    POOL_ID= - id of ip pool
    UID= - user uid
    ACTION= - ACTIVE OR ALERT
    DEBUG=10
  USEGE:
    internet_static_ip POOL_ID=3 UID=1  ACTION=ACTIVE

=cut
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
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

my $debug = 0;

if ($argv->{DEBUG}) {
  $debug=$argv->{DEBUG};
}

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

my $Nas = Nas->new($db, \%conf);

my $Admin = Admins->new( $db, \%conf );
$Admin->info( $conf{SYSTEM_ADMIN_ID}, {
  IP    => '127.0.0.3',
  SHORT => 1
} );

my $Internet = Internet->new($db, $Admin, \%conf);

main();

#********************************************************
=head2 main() - main function


=cut
#********************************************************
sub main {
  if (!$argv->{'ACTION'}) {
    print <<"[END]";
Please select action
    internet_static_ip.pl ACTIVE|ALERT
      UID=
      POOL_ID=
[END]
  }
  elsif ($argv->{ACTION} eq 'ACTIVE') {
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

  if ($debug > 7) {
    $Internet->{debug} = 1;
  }

  my $internet_list = $Internet->list({
    #ONLINE_IP => '>=' . $first_ip . ';<=' . $last_ip,
    COLS_NAME => 1,
    ID        => '_SHOW',
    IP        => '>=' . $first_ip . ';<=' . $last_ip,
    PAGE_ROWS => 100000,
  });

  my $service = $Internet->list({
    UID       => $argv->{UID},
    COLS_NAME => 1,
    ID        => '_SHOW',
    IP        => '_SHOW',
  });

  my @active = [];
  my $service_id = $service->[0]->{id};
  my $cur_ip     = $service->[0]->{ip_num} || 0;

  if ($cur_ip) {
    if ($debug > 0) {
      print "User have IP: ". int2ip($cur_ip)."\n";
    }
    return 0;
  }

  for my $online (@{$internet_list}) {
    push @active, $online->{ip_num};
  }

  for (my $i = 0; $i <= $ip_pool->{COUNTS}; $i++) {
    my $ip = ip2int($first_ip) + $i;
    if ($ip ~~ @active) {
      if ($debug > 3) {
        print int2ip($ip) . " exist\n";
      }
    }
    else {
      if ($debug > 0) {
        print "SET IP: " . int2ip($ip) . " UID: $argv->{UID}\n";
      }

      $Internet->change({
        ID  => $service_id,
        UID => $argv->{UID},
        IP  => int2ip($ip),
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