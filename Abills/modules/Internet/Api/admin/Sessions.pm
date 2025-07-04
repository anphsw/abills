package Internet::Api::admin::Sessions;

=head1 NAME

  Internet online paths

  Endpoints:
    /internet/online/*

=cut

use strict;
use warnings FATAL => 'all';

use Internet::Sessions;

my Internet::Sessions $Sessions;

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

  $Sessions = Internet::Sessions->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 get_internet_sessions_uid($path_params, $query_params)

  Endpoints
   Active
    GET /internet/sessions/:uid/
   Deprecated
    GET /inline/:uid/

=cut
#**********************************************************
sub get_internet_sessions_uid {
  my $self = shift;
  return $self->_sessions_list(@_);
}

#**********************************************************
=head2 get_internet_sessions($path_params, $query_params)

  Endpoints
   Active
    GET /internet/sessions

=cut
#**********************************************************
sub get_internet_sessions {
  my $self = shift;
  return $self->_sessions_list(@_);
}

#**********************************************************
=head2 _sessions_list($path_params, $query_params)

  return list of sessions

=cut
#**********************************************************
sub _sessions_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if ($self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet}) || !$self->{admin}->{permissions}{0}{33};

  my $sessions = $Sessions->online({
    %$query_params,
    UID           => $path_params->{uid} || $query_params->{UID} || '_SHOW',
    NAS_PORT_ID   => $query_params->{NAS_PORT_ID} || '_SHOW',
    CLIENT_IP_NUM => $query_params->{CLIENT_IP_NUM} || '_SHOW',
    NAS_ID        => $query_params->{NAS_ID} || '_SHOW',
    USER_NAME     => $query_params->{USER_NAME} || '_SHOW',
    CLIENT_IP     => $query_params->{CLIENT_IP} || '_SHOW',
    DURATION_SEC  => $query_params->{DURATION_SEC} || '_SHOW',
    STATUS        => $query_params->{STATUS} || '_SHOW',
    GUEST         => $query_params->{GUEST} || '_SHOW',
  });

  foreach my $session (@{$sessions}) {
    $session->{duration} = $session->{duration_sec};
    delete $session->{duration_sec};
  }

  return $sessions;
}

1;
