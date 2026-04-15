package Api::Controllers::Admin::Users::Documents;

=head1 NAME

  ADMIN API Users Documents

  Endpoints:
    /users/documents/*

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
=head2 get_users_documents($path_params, $query_params)

  Endpoint GET /users/documents/

=cut
#**********************************************************
sub get_users_documents {
  my ($self, $path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}{permissions}{0} || !$self->{admin}{permissions}{0}{44});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $pi_docs_list = $Users->pi_docs_list({ %$query_params });

  return {
    list  => $pi_docs_list,
    total => $Users->{TOTAL}
  };
}

#**********************************************************
=head2 post_users_documents($path_params, $query_params)

  Endpoint POST /users/documents/

=cut
#**********************************************************
sub post_users_documents {
  my ($self, $path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}{permissions}{0} || !$self->{admin}{permissions}{0}{44});

  $Users->pi_docs_add($query_params);

  delete @{$Users}{qw/list TOTAL AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 put_users_documents_id($path_params, $query_params)

  Endpoint PUT /users/documents/:id/

=cut
#**********************************************************
sub put_users_documents_id {
  my ($self, $path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}{permissions}{0} || !$self->{admin}{permissions}{0}{44});

  $Users->pi_docs_change({ ID => $path_params->{id}, %$query_params });

  delete @{$Users}{qw/list TOTAL AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 delete_users_documents_id($path_params, $query_params)

  Endpoint PUT /users/documents/:id/

=cut
#**********************************************************
sub delete_users_documents_id {
  my ($self, $path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}{permissions}{0} || !$self->{admin}{permissions}{0}{44});

  $Users->pi_docs_del({ ID => $path_params->{id} });

  if (!$Users->{errno}) {
    if ($Users->{AFFECTED} && $Users->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
        id     => $path_params->{id}
      };
    }
    else {
      return {
        errno       => 10226,
        errstr      => 'ERROR_NOT_EXIST',
        err_message => 'No exists',
      };
    }
  }
  return $Users;
}

#**********************************************************
=head2 get_users_documents_id($path_params, $query_params)

  Endpoint GET /users/documents/:id/

=cut
#**********************************************************
sub get_users_documents_id {
  my ($self, $path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}{permissions}{0} || !$self->{admin}{permissions}{0}{44});

  $Users->pi_docs_info({ ID => $path_params->{id} });

  return $Users;
}

1;
