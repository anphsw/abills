package Api::Controllers::Admin::Users::Iptv;

=head1 NAME

  ADMIN API Users Iptv

  Endpoints:
    /users/iptv/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Iptv;

my Control::Errors $Errors;
my Iptv $Iptv;

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
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_users_uid_iptv($path_params, $query_params)

  Endpoint GET /users/:uid/iptv/

=cut
#**********************************************************
sub get_users_uid_iptv {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

  $Iptv->user_list({
    %$query_params,
    UID          => $path_params->{uid},
    SERVICE_ID   => '_SHOW',
    TP_FILTER    => '_SHOW',
    MONTH_FEE    => '_SHOW',
    DAY_FEE      => '_SHOW',
    TP_NAME      => '_SHOW',
    SUBSCRIBE_ID => '_SHOW',
    COLS_NAME    => 1
  });
}

#**********************************************************
=head2 get_users_uid_iptv_id($path_params, $query_params)

  Endpoint GET /users/:uid/iptv/:id/

=cut
#**********************************************************
sub get_users_uid_iptv_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

  $Iptv->user_info($path_params->{id}, {
    %$query_params,
    COLS_NAME => 1
  });
}

1;
