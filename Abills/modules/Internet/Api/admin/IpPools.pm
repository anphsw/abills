package Internet::Api::admin::IpPools;

=head1 NAME

  Internet IP Pools paths

  Endpoints:
    /internet/ip-pools/*

=cut

use strict;
use warnings FATAL => 'all';

use Nas;

my Nas $Nas;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr
  };

  bless($self, $class);

  $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});

  return $self;
}

#**********************************************************
=head2 get_internet_ip_pools_static($path_params, $query_params)

  Endpoints
   Active
    GET /internet/ip-pools/static

=cut
#**********************************************************
sub get_internet_ip_pools_static {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if ($self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet});

  my $static_ip_pools = $Nas->ip_pools_list({
    DOMAIN_ID => ($self->{admin}->{DOMAIN_ID}) ? $self->{admin}->{DOMAIN_ID} : undef,
    STATIC    => 1,
    NETMASK   => '_SHOW',
    COLS_NAME => 1,
    %$query_params
  });

  return {
    list  => $static_ip_pools,
    total => $Nas->{TOTAL},
  };
}

1;

