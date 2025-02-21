package Internet::Api::admin::Users;

=head1 NAME

  Internet Users Manage

  Endpoints:
    /internet/:uid/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array mk_unique_value/;
use Control::Errors;
use Internet;
use Internet::Services;

my Internet $Internet;
my Internet::Services $Internet_services;
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

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};
  $Internet_services = Internet::Services->new($db, $admin, $conf, {
    lang        => $self->{lang},
  });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_internet_uid_activate($path_params, $query_params)

  Endpoint POST /internet/:uid/activate/

=cut
#**********************************************************
sub post_internet_uid_activate {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{18};

  # make empty before call not isolated function
  %main::FORM = ();

  ::load_module('Internet::Users', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Internet/Users.pm'}));
  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->pi({ UID => $path_params->{uid} });

  ::internet_user_add({
    %$query_params,
    API        => 1,
    UID        => $path_params->{uid},
    USERS_INFO => $Users,
  });
}

#**********************************************************
=head2 put_internet_uid_activate($path_params, $query_params)

  Endpoint PUT /internet/:uid/activate/

=cut
#**********************************************************
sub put_internet_uid_activate {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{18};

  # make empty before call not isolated function
  %main::FORM = ();

  ::load_module('Internet::Users', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Internet/Users.pm'}));
  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->pi({ UID => $path_params->{uid} });

  ::internet_user_change({
    %$query_params,
    API        => 1,
    UID        => $path_params->{uid},
    USERS_INFO => $Users,
  });
}

#**********************************************************
=head2 get_internet_uid_id_warnings($path_params, $query_params)

  Endpoint GET /internet/:uid/:id/warnings/

=cut
#**********************************************************
sub get_internet_uid_id_warnings {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

  $Service_control->service_warning({
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
    MODULE => 'Internet'
  });
}

#**********************************************************
=head2 post_internet_uid_session_hangup($path_params, $query_params)

  Endpoint POST /internet/:uid/session/hangup/

=cut
#**********************************************************
sub post_internet_uid_session_hangup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{5};

  ::load_module('Internet::Monitoring', { LOAD_PACKAGE => 1 });
  ::_internet_hangup({ %$query_params, UID => $path_params->{uid} });
}

#**********************************************************
=head2 put_internet_uid($path_params, $query_params)

  Endpoint PUT /internet/:uid/

=cut
#**********************************************************
sub put_internet_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # clear global form
  %main::FORM = ();

  return $Internet_services->internet_user_chg_tp({
    %$query_params,
    UID => $path_params->{uid},
  });
}

1;
