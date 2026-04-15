package Internet::User_ips;

=head1 NAME

  User IP managment

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(ip2int int2ip in_array);
use Control::Errors;
use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  get_static_ip
  get_static_ipv6
  get_internet_ips
);

our @EXPORT_OK = qw(
  get_static_ip
  get_static_ipv6
  get_internet_ips
);

my Control::Errors $Errors;

#**********************************************************
=head2 internet_get_static_ip($pool_id) - Get static ip from pool

  Arguments:
    $pool_id   - IP pool ID
    $attr
      SILENT
      IPV6

  Returns:
    IP address

=cut
#**********************************************************
sub get_static_ip {
  my ($self, $pool_id, $attr) = @_;
  my $ip = '0.0.0.0';

  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang   => $self->{lang},
    parent => $self
  });

  require Nas;
  Nas->import();
  my $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});
  my $ip_pool = $Nas->ip_pools_info($pool_id);

  if ($attr->{IPV6}) {
    # return $ip_pool->{IPV6_PREFIX}, $ip_pool->{IPV6_MASK}, $ip_pool->{IPV6_TEMPLATE},
    #   $ip_pool->{IPV6_PD}, $ip_pool->{IPV6_PD_MASK}, $ip_pool->{IPV6_PD_TEMPLATE};
    return $self->get_static_ipv6($ip_pool);
  }

  if ($Nas->{error}) {
    $Errors->throw_error(1360017);
    return '0.0.0.0';
  }

  my @arr_ip_skip = $ip_pool->{IP_SKIP} ? split(/,\s?|;\s?/xm, $ip_pool->{IP_SKIP}) : ();

  my $start_ip = ip2int($ip_pool->{IP});
  my $end_ip = $start_ip + $ip_pool->{COUNTS};

  my $users_ips = $self->get_internet_ips({ START_IP => ">=$ip_pool->{IP}" });

  for (my $ip_cur = $start_ip; $ip_cur < $end_ip; $ip_cur++) {
    if (!$users_ips->{ $ip_cur }) {
      my $ip_ = int2ip($ip_cur);
      if (!in_array($ip_, \@arr_ip_skip)) {
        return $ip_;
      }
    }
  }

  if ($ip_pool->{NEXT_POOL_ID}) {
    return $self->get_static_ip($ip_pool->{NEXT_POOL_ID});
  }

  $Errors->throw_error(1360005);

  return $ip;
}

#**********************************************************
=head2 get_static_ipv6($pool_ips, $attr)

  Arguments:
    $attr
      IPV6_PREFIX
      IPV6_NET_MASK
      IPV6_MASK
      IPV6_PD
      IPV6_PD_NET_MASK
      IPV6_PD_MASK

  Results:
    \@ipv6_pool

=cut
#**********************************************************
sub get_static_ipv6 {
  my ($self, $attr) = @_;

  require Netlist::Tools;
  Netlist::Tools->import();

  my ($pool_ips, $wan_ips) = ipv6_pools({
    IP          => $attr->{IPV6_PREFIX},
    NET_MASK    => $attr->{IPV6_NET_MASK},
    MASK        => $attr->{IPV6_MASK},
    PD          => $attr->{IPV6_PD},
    PD_NET_MASK => $attr->{IPV6_PD_NET_MASK},
    PD_MASK     => $attr->{IPV6_PD_MASK}
  });

  my $used_ips = $self->get_internet_ips({ TYPE => 'IPV6' });
  my $debug = 0;
  foreach my $ip (@$wan_ips) {
    if (!$used_ips->{$ip}) {
      if ($debug > 1) {
        print "WAN: $ip / $pool_ips->{$ip}{IPV6_MASK} <br>\n"
          . "PD: $pool_ips->{$ip}{PD} / $pool_ips->{$ip}{PD_MASK}";
      }

      $attr->{IPV6_PREFIX} = $ip;
      $attr->{IPV6_MASK} = $pool_ips->{$ip}{IPV6_MASK};
      $attr->{IPV6_PD} = $pool_ips->{$ip}{PD};
      $attr->{IPV6_PD_MASK} = $pool_ips->{$ip}{PD_MASK};

      return $attr->{IPV6_PREFIX}, $attr->{IPV6_MASK}, $attr->{IPV6_PD}, $attr->{IPV6_PD_MASK};
    }
  }

  return 0;
}

#**********************************************************
=head2 get_internet_ipv($attr)

  Arguments:
    $attr
      TYPE IP (Default) or IPV6
      START_IP - Start IP from IPv4 (Default: empty)

  Results:
    \%used_ips

=cut
#**********************************************************
sub get_internet_ips {
  my ($self, $attr) = @_;

  my %used_ips = ();
  my $type = $attr->{TYPE} || 'IP';
  my %search_params = ();
  my $field = 'ip_num';

  if ($attr->{TYPE} && $attr->{TYPE} eq 'IPV6') {
    $search_params{$type} = '!';
    $field = 'ipv6';
  }
  else {
    $search_params{$type} = $attr->{START_IP} || '!';
  }

  require Internet;
  Internet->import();
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  my $users_list = $Internet->user_list({
    %search_params,
    SKIP_GID       => 1,
    GROUP_BY       => 'internet.id',
    SKIP_DEL_CHECK => 1,
    PAGE_ROWS      => 100000
  });

  foreach my $user (@$users_list) {
    $used_ips{$user->{$field}} = $user->{uid};
  }

  return \%used_ips;
}

1;