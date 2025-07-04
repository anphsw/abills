package Api::Controllers::Admin::Users::Statuses;

=head1 NAME

  ADMIN API Users Statuses

  Endpoints:
    /users/statuses/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Users;

my Control::Errors $Errors;
my Users $Users;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

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

  $Users  = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_users_statuses($path_params, $query_params)

  POST /users/statuses/

=cut
#**********************************************************
sub post_users_statuses {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Users->user_status_add({
    %$query_params,
    ID => $path_params->{id}
  });

  return $Users if ($Users->{errno});

  $Users->user_status_info({ ID => $path_params->{id} });

  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 put_users_statuses_id($path_params, $query_params)

  PUT /users/statuses/:id/

=cut
#**********************************************************
sub put_users_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Users->user_status_change({
    %$query_params,
    ID => $path_params->{id}
  });

  return $Users if ($Users->{errno});

  $Users->user_status_info({ ID => $path_params->{id} });

  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 get_users_statuses($path_params, $query_params)

  GET /users/statuses/

=cut
#**********************************************************
sub get_users_statuses {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{0}{0});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $statuses = $Users->user_status_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    DESCR     => '_SHOW',
    COLOR     => '_SHOW',
    %$query_params,
    COLS_NAME => 1
  });

  foreach my $status (@{$statuses}) {
    $status->{locale_name} = ::_translate($status->{name}) || $status->{name};
  }

  return {
    total => $Users->{TOTAL},
    list  => $statuses
  };
}

#**********************************************************
=head2 get_users_statuses_id($path_params, $query_params)

  GET /users/statuses/:id/

=cut
#**********************************************************
sub get_users_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  $Users->user_status_info({ ID => $path_params->{id} });

  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 delete_users_statuses_id($path_params, $query_params)

  DELETE /users/statuses/:id/

=cut
#**********************************************************
sub delete_users_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Users->user_status_del({ ID => $path_params->{id} });

  return $Users if ($Users->{errno});

  if ($Users->{AFFECTED} && $Users->{AFFECTED} =~ /^[0-9]$/) {
    return {
      result  => 'Successfully deleted',
    }
  }

  return $Errors->throw_error(1001030, { errstr => "Status with id $path_params->{id} not exists" });
}

1;
