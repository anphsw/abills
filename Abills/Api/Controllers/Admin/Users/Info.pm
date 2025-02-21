package Api::Controllers::Admin::Users::Info;

=head1 NAME

  ADMIN API Users Info

  Endpoints:
    /users/:uid
    /users/:uid/pi
    /users/all

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;

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

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_users_all($path_params, $query_params)

  Endpoint GET /users/all/

=cut
#**********************************************************
sub get_users_all {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{2};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{DESC} = $query_params->{DESC} || '';
  $query_params->{PG} = $query_params->{PG} || 0;

  my $users = $Users->list({
    %{$query_params},
    COLS_NAME => 1,
  });

  if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
    foreach my $user (@{$users}) {
      my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
      $user->{tags} = \@tags;
    }
  }

  return $users;
}

#**********************************************************
=head2 get_users_uid($path_params, $query_params)

  Endpoint GET /users/:uid/

=cut
#**********************************************************
sub get_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  my @allowed_params = (
    'SHOW_PASSWORD'
  );
  my %PARAMS = ();
  foreach my $param (@allowed_params) {
    next if (!defined($query_params->{$param}));
    $PARAMS{$param} = '_SHOW';
  }

  $Users->info($path_params->{uid}, \%PARAMS);
  delete @{$Users}{qw/list AFFECTED/};
  return $Users;
}

#**********************************************************
=head2 put_users_uid($path_params, $query_params)

  Endpoint PUT /users/:uid/

=cut
#**********************************************************
sub put_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{SKIP_STATUS_CHANGE} = 1 if (!defined $query_params->{DISABLE});

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  if ($query_params->{COMMENTS}) {
    require Encode;
    Encode->import();
    Encode::_utf8_off($query_params->{COMMENTS});
  }

  $Users->change($path_params->{uid}, {
    %$query_params
  });

  if (!$Users->{errno}) {
    if ($query_params->{CREDIT} && $query_params->{CREDIT_DATE}) {
      $Users->info($path_params->{uid});
      ::cross_modules('payments_maked', { USER_INFO => $Users, SUM => $query_params->{CREDIT}, SILENT => 1, CREDIT_NOTIFICATION => 1 });
    }

    $Users->pi_change({
      UID => $path_params->{uid},
      %$query_params
    });
  }

  return $Users;
}

#**********************************************************
=head2 delete_users_uid($path_params, $query_params)

  Endpoint DELETE /users/:uid/

=cut
#**********************************************************
sub delete_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{5};

  my @allowed_params = (
    'COMMENTS',
    'DATE',
  );
  my %PARAMS = ();
  foreach my $param (@allowed_params) {
    next if (!defined($query_params->{$param}));
    $PARAMS{$param} = '_SHOW';
  }

  $Users->del({
    %PARAMS,
    UID => $path_params->{uid}
  });

  if (!$Users->{errno}) {
    return {
      result => "Successfully deleted user with uid $path_params->{uid}",
      uid    => $path_params->{uid},
    };
  }
  else {
    return $Users;
  }
}

#**********************************************************
=head2 get_users_uid_pi($path_params, $query_params)

  Endpoint GET /users/:uid/pi/

=cut
#**********************************************************
sub get_users_uid_pi {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  $Users->pi({ UID => $path_params->{uid} });
}

#**********************************************************
=head2 post_users($path_params, $query_params)

  Endpoint POST /users/

=cut
#**********************************************************
sub post_users {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{1};

  $Users->add({
    %$query_params
  });

  if (!$Users->{errno}) {
    $Users->pi_add({
      UID => $Users->{UID},
      %$query_params
    });
  }

  return $Users;
}

#**********************************************************
=head2 post_users_uid_pi($path_params, $query_params)

  Endpoint POST /users/:uid/pi/

=cut
#**********************************************************
sub post_users_uid_pi {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{1};

  $Users->pi_add({
    %$query_params,
    UID => $path_params->{uid}
  });
}

#**********************************************************
=head2 put_users_uid_pi($path_params, $query_params)

  Endpoint PUT /users/:uid/pi/

=cut
#**********************************************************
sub put_users_uid_pi {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  $Users->pi_change({
    %$query_params,
    UID => $path_params->{uid}
  });
}

1;
