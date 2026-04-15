package Api::Controllers::Admin::Users::Root;

=head1 NAME

  ADMIN API Users Root

  Endpoints:
    /users/:uid/history

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

my Control::Errors $Errors;

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

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_users_uid_history($path_params, $query_params)

  Endpoint GET /users/:uid/history/

=cut
#**********************************************************
sub get_users_uid_history {
  my ($self, $path_params, $query_params) = @_;

  if (!$self->{admin}->{permissions}{0}{30}) {
    $self->{errno} = 10;
    $self->{errstr} = 'Access denied';
    return $self;
  }

  my Admins $admin = $self->{admin};
  my $action_list = $admin->action_list({
    UID           => $path_params->{uid},
    LOGIN         => '_SHOW',
    DATETIME      => '_SHOW',
    ACTIONS       => '_SHOW',
    ADMIN_LOGIN   => '_SHOW',
    IP            => '_SHOW',
    MODULE        => '_SHOW',
    TYPE          => '_SHOW',
    ADMIN_DISABLE => '_SHOW',
    %$query_params
  });

  return {
    list => $action_list,
    total => $admin->{TOTAL}
  }
}

1;
