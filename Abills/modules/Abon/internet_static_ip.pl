#!/usr/bin/perl
=head NAME internet_static_ip

  GIVE STATICK IP FOR USER FORM IP POOL
  ATTRIBUTES:
    POOL_ID= - id of ip pool
    UID= - user uid
    ACTION= - ACTIVE OR ALERT
    FORCE_IP_ASSIGN=1 - change IP if it is not exist in pool
    DEBUG=10
    SKIP_ALERT - Skip remove IP from service
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
use Admins;

my $argv = parse_arguments(\@ARGV);

my $debug = 0;

if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
}

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

my $Nas = Nas->new($db, \%conf);

my $Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, {
  IP    => '127.0.0.3',
  SHORT => 1
});

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
    alert();
  }

  return 1;
}
#********************************************************
=head2 active() - give static ip for user


=cut
#********************************************************
sub active {
  my ($attr) = @_;
  my $pool_id = $argv->{POOL_ID} || $attr->{POOL_ID};

  my $ip_pool = $Nas->ip_pools_info($pool_id);
  my $counts = $ip_pool->{COUNTS} || 0;
  my $next_pool_id = $ip_pool->{NEXT_POOL_ID} || 0;
  my $first_ip = $ip_pool->{IP};
  my $last_ip = int2ip(ip2int($first_ip) + $ip_pool->{COUNTS});

  if ($debug > 7) {
    $Internet->{debug} = 1;
  }

  my $internet_list = $Internet->user_list({
    #ONLINE_IP => '>=' . $first_ip . ';<=' . $last_ip,
    COLS_NAME => 1,
    ID        => '_SHOW',
    IP        => '>=' . $first_ip . ';<=' . $last_ip,
    PAGE_ROWS => 100000,
    GROUP_BY  => 'internet.ip',
  });

  my $service = $Internet->user_list({
    UID       => $argv->{UID},
    COLS_NAME => 1,
    ID        => '_SHOW',
    IP        => '_SHOW'
  });

  my @active = [];
  my $service_id = $service->[0]->{id};
  my $cur_ip = $service->[0]->{ip_num} || 0;

  if ($cur_ip && !$argv->{'FORCE_IP_ASSIGN'}) {
    if ($debug > 0) {
      print "User has IP: " . int2ip($cur_ip) . "\n";
    }

    if ($argv->{'TP_ID'} && $argv->{'UID'}){
      _add_static_ip_to_abon($cur_ip);
    }
    return 0;
  }

  if ($argv->{'FORCE_IP_ASSIGN'}) {
    my $ip_exist_in_pools = _check_cur_ip_in_pools({CURRENT_IP => $cur_ip, POOL_ID =>$argv->{POOL_ID}});
    if ($ip_exist_in_pools) {
      return 0;
    }
  }

  for my $online (@{$internet_list}) {
    push @active, $online->{ip_num};
  }

  my $assigned_ip = '';

  for (my $i = 0; $i <= $counts; $i++) {
    my $ip = ip2int($first_ip) + $i;
    if ($ip ~~ @active) {
      if ($debug > 3) {
        print int2ip($ip) . " exist\n";
      }
    }
    else {
      $assigned_ip = int2ip($ip);

      if ($debug > 0) {
        print "SET IP: " . $assigned_ip . " UID: $argv->{UID}\n";
      }

      $Internet->user_change({
        ID  => $service_id,
        UID => $argv->{UID},
        IP  => $assigned_ip,
      });

      if ($argv->{'TP_ID'} && $argv->{'UID'}){
        _add_static_ip_to_abon($assigned_ip);
      }

      last;
    }
  }

  if (!$assigned_ip && $next_pool_id){
    $argv->{POOL_ID} = '';
    active({POOL_ID => $next_pool_id});
  }

  return 1;
}

#********************************************************
=head2 alert() - remove static ip from user


=cut
#********************************************************
sub alert {

  if ($argv->{SKIP_ALERT}) {
    return 1;
  }

  my $list = $Internet->user_list({
    UID       => $argv->{UID},
    ID        => '_SHOW',
    COLS_NAME => 1,
  });

  my $ip = int2ip(0);
  $Internet->user_change({
    ID  => $list->[0]->{id},
    UID => $argv->{UID},
    IP  => $ip,
  });

  return 1;
}


#********************************************************
=head2 _check_cur_ip_in_pools() - check IP in IP POOL if exist

  Arguments:
    cur_ip - current user ip
    pool_id - IP pool ID

=cut
#********************************************************
sub _check_cur_ip_in_pools {
  my ($attr) = @_;
  my $cur_ip = $attr->{CURRENT_IP};
  my $pool_id = $attr->{POOL_ID};

  my $ip_pool = $Nas->ip_pools_info($pool_id);
  my $next_pool_id = $ip_pool->{NEXT_POOL_ID};

  my $first_ip = ip2int($ip_pool->{IP});
  my $last_ip = $first_ip + $ip_pool->{COUNTS};

  if ($cur_ip >= $first_ip && $cur_ip <= $last_ip) {
    if ($debug > 0) {
      print 'IP: ' . int2ip($cur_ip) . " exists in POOL_ID=$pool_id\n";
    }
    return 1;
  }
  else {
    if ($debug > 0) {
      print 'IP: ' . int2ip($cur_ip) . " does not exist in POOL_ID=$pool_id\n";
    }
  }

  if ($next_pool_id) {
    _check_cur_ip_in_pools({CURRENT_IP => $cur_ip, POOL_ID =>$next_pool_id});
  }
}


#********************************************************
=head2 _add_static_ip_to_abon() - add static IP to Abon comments

  Arguments:
    static_ip - user static ip

=cut
#********************************************************
sub _add_static_ip_to_abon {
  my ($static_ip) = @_;

  require Abon;
  Abon->import();
  my $Abon = Abon->new($db, $Admin, \%conf);

  $Abon->user_tariff_change({
    UID                  => $argv->{UID},
    TP_ID                => $argv->{TP_ID},
    PERSONAL_DESCRIPTION => $static_ip,
    COMMENTS             => $static_ip
  });

}

1;
