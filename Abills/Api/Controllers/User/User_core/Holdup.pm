package Api::Controllers::User::User_core::Holdup;

=head1 NAME

  User API Holdup

  Endpoints:
    /user/:id/holdup/*

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
=head2 get_user_id_holdup($path_params, $query_params)

  Endpoint GET /user/:id/holdup/

=cut
#**********************************************************
sub get_user_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (
    UID          => $path_params->{uid},
    ACCEPT_RULES => 1,
  );

  $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

  my $result = $Service_control->user_holdup(\%params);

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 post_user_id_holdup($path_params, $query_params)

  Endpoint POST /user/:id/holdup/

=cut
#**********************************************************
sub post_user_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (
    UID          => $path_params->{uid},
    add          => 1,
    ACCEPT_RULES => 1,
    FROM_DATE    => $query_params->{FROM_DATE},
    TO_DATE      => $query_params->{TO_DATE},
  );

  $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

  my $result = $Service_control->user_holdup(\%params);

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 delete_user_id_holdup($path_params, $query_params)

  Endpoint DELETE /user/:id/holdup/

=cut
#**********************************************************
sub delete_user_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (
    UID => $path_params->{uid},
    del => 1,
  );

  $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

  my $result = $Service_control->user_holdup(\%params);

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

1;
