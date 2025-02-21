package Api::Controllers::Admin::Users::Contracts;

=head1 NAME

  ADMIN API Users Contracts

  Endpoints:
    /users/contracts/*

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

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_users_contracts_types($path_params, $query_params)

  Endpoint GET /users/contracts/types/

=cut
#**********************************************************
sub get_users_contracts_types {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  return $Users->contracts_type_list({
    %$query_params,
  });
}

#**********************************************************
=head2 get_users_contracts($path_params, $query_params)

  Endpoint GET /users/contracts/

=cut
#**********************************************************
sub get_users_contracts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $contracts_list = $Users->contracts_list({
    %$query_params,
  });

  foreach my $contract (@{$contracts_list}) {
    delete $contract->{signature} if (!$query_params->{SIGNATURE});
  }

  return $contracts_list;
}

#**********************************************************
=head2 post_users_contracts($path_params, $query_params)

  Endpoint POST /users/contracts/

=cut
#**********************************************************
sub post_users_contracts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{1};

  $query_params->{DATE} = $main::DATE if (!$query_params->{DATE});

  $Users->contracts_add($query_params);

  delete @{$Users}{qw/list TOTAL AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 put_users_contracts_id($path_params, $query_params)

  Endpoint PUT /users/contracts/:id/

=cut
#**********************************************************
sub put_users_contracts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  $Users->contracts_change($path_params->{id}, $query_params);

  delete @{$Users}{qw/list TOTAL AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 delete_users_contracts_id($path_params, $query_params)

  Endpoint PUT /users/contracts/:id/

=cut
#**********************************************************
sub delete_users_contracts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  $Users->contracts_del({ ID => $path_params->{id} });

  if (!$Users->{errno}) {
    if ($Users->{AFFECTED} && $Users->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
        id     => $path_params->{id}
      };
    }
    else {
      return {
        errno       => 10225,
        errstr      => 'ERROR_NOT_EXIST',
        err_message => 'No exists',
      };
    }
  }
  return $Users;
}

#**********************************************************
=head2 get_users_contracts_id($path_params, $query_params)

  Endpoint GET /users/contracts/:id/

=cut
#**********************************************************
sub get_users_contracts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  ::load_module('Control::Contracts_mng', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Control/Contracts_mng.pm'}));

  my $document = ::_print_user_contract({
    ID            => $path_params->{id},
    USER_OBJ      => $Users,
    pdf           => 1,
    OUTPUT2RETURN => 1
  });

  return $document;
}

1;
