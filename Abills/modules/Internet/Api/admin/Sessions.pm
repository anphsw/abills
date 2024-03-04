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
=head2 get_portal_articles_id($path_params, $query_params)

  Endpoints
   Active
    GET /internet/sessions/:uid/
   Deprecated
    GET /inline/:uid/

=cut
#**********************************************************
sub get_sessions_uid {
  my $self = shift;
  my ($path_params, $query_params);

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if ($self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet}) || !$self->{admin}->{permissions}{0}{33};

  my $sessions = $Sessions->online({
    UID           => $path_params->{uid},
    NAS_PORT_ID   => '_SHOW',
    CLIENT_IP_NUM => '_SHOW',
    NAS_ID        => '_SHOW',
    USER_NAME     => '_SHOW',
    CLIENT_IP     => '_SHOW',
    DURATION_SEC  => '_SHOW',
    STATUS        => '_SHOW',
    GUEST         => '_SHOW',
  });

  foreach my $session (@{$sessions}) {
    $session->{duration} = $session->{duration_sec};
    delete $session->{duration_sec};
  }

  return $sessions;
}

1;
