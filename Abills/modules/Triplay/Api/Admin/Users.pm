package Triplay::Api::Admin::Users;
=head1 NAME

  Triplay Users

  Endpoints:
    /triplay/users/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Triplay;
use Triplay::Services;

my Control::Errors $Errors;
my Triplay $Triplay;
my Triplay::Services $Triplay_services;

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

  $Triplay = Triplay->new($db, $admin, $conf);
  $Triplay_services = Triplay::Services->new($db, $admin, $conf, { HTML => $attr->{html}, LANG => $attr->{lang}, ERRORS => $Errors });

  $Triplay->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_triplay_users($path_params, $query_params)

  Endpoint GET /triplay/users/

=cut
#**********************************************************
sub get_triplay_users {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $users = $Triplay->user_list({
    %$query_params,
    _SHOW_ALL_COLUMNS => 1,
    COLS_NAME         => 1,
  });

  return {
    list  => $users,
    total => $Triplay->{TOTAL},
  };
}

#**********************************************************
=head2 get_triplay_users_uid($path_params, $query_params)

  Endpoint GET /triplay/users/:uid/

=cut
#**********************************************************
sub get_triplay_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Triplay_services->user_info({ UID => $path_params->{uid} });

  delete @{$result}{qw/AFFECTED/};

  return $result;
}

#**********************************************************
=head2 post_triplay_users_uid($path_params, $query_params)

  Endpoint POST /triplay/users/:uid/

=cut
#**********************************************************
sub post_triplay_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{EXPIRE} = $query_params->{SERVICE_EXPIRE} if ($query_params->{SERVICE_EXPIRE});
  if (defined $query_params->{SERVICE_STATUS}) {
    $query_params->{STATUS} = $query_params->{SERVICE_STATUS};
    $query_params->{DISABLE} = $query_params->{SERVICE_STATUS};
  }

  my $result = $Triplay_services->user_add({
    %$query_params,
    USER_INFO => $path_params->{user_object},
    UID       => $path_params->{uid},
    SILENT    => 1,
    QUITE     => 1,
  });

  if ($result && ref $result ne '') {
    return $result;
  }

  # strange solution not unified structure in Services.pm in Triplay
  if (!$result) {
    return {
      errno  => $Triplay_services->{errno},
      errstr => $Triplay_services->{errstr}
    };
  }

  return $Triplay_services->user_info({ UID => $path_params->{uid} });
}

#**********************************************************
=head2 patch_triplay_users_uid($path_params, $query_params)

  Endpoint PATCH /triplay/users/:uid/

=cut
#**********************************************************
sub patch_triplay_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{EXPIRE} = $query_params->{SERVICE_EXPIRE} if ($query_params->{SERVICE_EXPIRE});
  if (defined $query_params->{SERVICE_STATUS}) {
    $query_params->{STATUS} = $query_params->{SERVICE_STATUS};
    $query_params->{DISABLE} = $query_params->{SERVICE_STATUS};
  }

  $Triplay_services->user_change({
    %$query_params,
    USER_INFO => $path_params->{user_object},
    UID       => $path_params->{uid},
    QUITE     => 1,
  });

  return $Triplay_services if ($Triplay_services->{errno});

  return $Triplay_services->user_info({ UID => $path_params->{uid} });
}

#**********************************************************
=head2 delete_triplay_users_uid($path_params, $query_params)

  Endpoint DELETE /triplay/users/:uid/

=cut
#**********************************************************
sub delete_triplay_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Triplay_services->user_del({
    %$query_params,
    USER_INFO => $path_params->{user_object},
    UID       => $path_params->{uid}
  });

  return $result if ($result->{errno});

  #TODO change to direct return of $result when will be returning extra info from it
  return {
    message => 'service deleted',
    uid     => $path_params->{uid},
  };
}

1;
