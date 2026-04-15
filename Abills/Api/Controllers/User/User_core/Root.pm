package Api::Controllers::User::User_core::Root;

=head1 NAME

  User API Root (other)

  Endpoints:
    /user/...

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Control::Service_control;

my Control::Errors $Errors;
my Control::Service_control $Service_control;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_services($path_params, $query_params)

  Endpoint GET /user/services/

=cut
#**********************************************************
sub get_user_services {
  my ($self, $path_params, $query_params) = @_;

  require Control::Services;
  Control::Services->import();
  my $Services = Control::Services->new($self->{db}, $self->{admin}, $self->{conf});

  my $services = $Services->get_user_services({
    uid         => $path_params->{uid},
    active_only => $query_params->{ACTIVE_ONLY} ? 1 : 0
  });

  return $services;
}

#**********************************************************
=head2 get_user_services($path_params, $query_params)

  Endpoint GET /user/services/statuses

=cut
#**********************************************************
sub get_user_services_statuses {
  my ($self) = @_;

  require Service;
  Service->import();
  my $Services = Service->new($self->{db}, $self->{admin}, $self->{conf});

  my $list = $Services->status_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    COLS_NAME => 1,
  });

  foreach my $status (@{$list}) {
    $status->{locale_name} = ::_translate($status->{name}) || $status->{name};
  }

  return {
    total => $Services->{TOTAL},
    list  => $list
  };
}

#**********************************************************
=head2 post_user_acceptRules($path_params, $query_params)

  Endpoint POST /user/accept-rules/

=cut
#**********************************************************
sub post_user_acceptRules {
  my ($self, $path_params) = @_;

  return $Errors->throw_error(1001501) if (!$self->{conf}->{ACCEPT_RULES});

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->pi({ UID => $path_params->{uid} });

  if ($Users->{ACCEPT_RULES}) {
    return {
      result           => 'Already accepted',
      already_accepted => 1,
    };
  }

  $Users->pi_change({
    UID          => $path_params->{uid},
    ACCEPT_RULES => 1
  });

  return $Users if ($Users->{errno});

  return {
    result   => 'Successfully accepted',
    accepted => 1,
  }
}

1;
