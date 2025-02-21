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
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{0}{30});

  my $history = $self->{admin}->action_list({
    UID           => $path_params->{uid},
    LOGIN         => '_SHOW',
    DATETIME      => '_SHOW',
    ACTIONS       => '_SHOW',
    ADMIN_LOGIN   => '_SHOW',
    IP            => '_SHOW',
    MODULE        => '_SHOW',
    TYPE          => '_SHOW',
    ADMIN_DISABLE => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => $query_params->{PAGE_ROWS} || 25,
    SORT          => $query_params->{SORT} || 1,
    DESC          => $query_params->{DESC} || '',
    PG            => $query_params->{PG} || 0
  });

  return {
    list  => $history,
    total => $self->{admin}->{TOTAL},
  };
}

1;
