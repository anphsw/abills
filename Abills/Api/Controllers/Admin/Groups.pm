package Api::Controllers::Admin::Groups;

=head1 NAME

  ADMIN API Streets

  Endpoints:
    /groups/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Users;

my Control::Errors $Errors;
my Users $Users;

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
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->{debug} = $self->{debug};

  return $self;
}

#**********************************************************
=head2 get_groups($path_params, $query_params)

  Endpoint GET /groups/

=cut
#**********************************************************
sub get_groups {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28};

  my $groups = $Users->groups_list({
    DOMAIN_ID        => '_SHOW',
    G_NAME           => '_SHOW',
    DISABLE_PAYMENTS => '_SHOW',
    GID              => '_SHOW',
    NAME             => '_SHOW',
    BONUS            => '_SHOW',
    DESCR            => '_SHOW',
    ALLOW_CREDIT     => '_SHOW',
    DISABLE_PAYSYS   => '_SHOW',
    DISABLE_CHG_TP   => '_SHOW',
    USERS_COUNT      => '_SHOW',
    SMS_SERVICE      => '_SHOW',
    DOCUMENTS_ACCESS => '_SHOW',
    DISABLE_ACCESS   => '_SHOW',
    SEPARATE_DOCS    => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list  => $groups,
    total => $Users->{TOTAL},
  };
}

#**********************************************************
=head2 get_groups_id($path_params, $query_params)

  Endpoint GET /groups/:id/

=cut
#**********************************************************
sub get_groups_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28};

  $Users->group_info($path_params->{id});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  $Users->{G_NAME} = $Users->{NAME};

  return $Users;
}

#**********************************************************
=head2 post_groups($path_params, $query_params)

  Endpoint POST /groups/

=cut
#**********************************************************
sub post_groups {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28} || !$self->{admin}->{permissions}{0}{1};

  $Users->group_add($query_params);

  $Users->group_info($query_params->{GID}) if ($Users->{AFFECTED});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 put_groups_id($path_params, $query_params)

  Endpoint PUT /groups/:id/

=cut
#**********************************************************
sub put_groups_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28} || !$self->{admin}->{permissions}{0}{4};

  $Users->group_info($path_params->{id});
  $Users->group_change($path_params->{id}, {
    %$Users,
    %$query_params
  });
  $Users->group_info($path_params->{id});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 delete_groups_id($path_params, $query_params)

  Endpoint DELETE /groups/:id/

=cut
#**********************************************************
sub delete_groups_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{39};

  my $groups = $Users->groups_list({ GID => $path_params->{id}, USERS_COUNT => '_SHOW', COLS_NAME => 1 });

  if (!$Users->{TOTAL} || $Users->{errno}) {
    return {
      errno  => 100056,
      errstr => 'NO_DELETE_GROUPS',
    };
  }
  elsif ($Users->{TOTAL} && $Users->{TOTAL} > 0 && $groups->[0]->{users_count}) {
    return {
      errno  => 100057,
      errstr => 'NO_DELETE_GROUPS_USERS_EXISTS',
    };
  }

  $Users->group_del($path_params->{id});

  return $Users if ($Users->{errno});

  return {
    result => 'Successfully deleted',
    gid    => $path_params->{id},
  };
}

1;
