package Internet::Api::user::Root;

=head1 NAME

  User Internet Root

  Endpoints:
    /user/internet/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Internet;
use Control::Service_control;

my Internet $Internet;
my Control::Service_control $Service_control;
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
  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_internet_id_activate($path_params, $query_params)

  Endpoint POST /user/internet/:id/activate/

=cut
#**********************************************************
sub post_user_internet_id_activate {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  my $user_info = $Users->info($path_params->{uid});

  $Internet->user_info($path_params->{uid}, {
    ID        => $path_params->{id},
    DOMAIN_ID => $user_info->{DOMAIN_ID}
  });

  return {
    result => 'Already active'
  } if (defined $Internet->{STATUS} && $Internet->{STATUS} == 0);
  return {
    errno  => 200,
    errstr => 'Can\'t activate, not allowed'
  } unless (
    $Internet->{STATUS} &&
      ($Internet->{STATUS} == 2 || $Internet->{STATUS} == 5 ||
        ($Internet->{STATUS} == 3 && $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP})));

  if ($Internet->{STATUS} == 3) {
    my $del_result = $Service_control->user_holdup({ del => 1, UID => $path_params->{uid}, ID => $path_params->{id} });
    return $del_result;
  }

  return {
    errno  => 201,
    errstr => 'Can\'t activate, not enough money'
  } if ($Internet->{MONTH_ABON} != 0 && $Internet->{MONTH_ABON} >= $user_info->{DEPOSIT});

  $Internet->user_change({
    UID      => $path_params->{uid},
    ID       => $path_params->{id},
    STATUS   => 0,
    ACTIVATE => ($self->{conf}->{INTERNET_USER_ACTIVATE_DATE}) ? strftime("%Y-%m-%d", localtime(time)) : undef
  });

  if (!$Internet->{errno}) {
    if (!$Internet->{STATUS}) {
      ::service_get_month_fee($Internet);
    }

    return {
      result => 'OK. Success activation'
    }
  }
  else {
    return {
      errno  => $Internet->{errno},
      errstr => $Internet->{errstr} || "",
    }
  }
}

#**********************************************************
=head2 get_user_internet($path_params, $query_params)

  Endpoint GET /user/internet/

=cut
#**********************************************************
sub get_user_internet {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
  return ::get_user_services({
    uid     => $path_params->{uid},
    service => 'Internet',
  });
}

#**********************************************************
=head2 get_user_internet_tariffs($path_params, $query_params)

  Endpoint GET /user/internet/tariffs/

=cut
#**********************************************************
sub get_user_internet_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->available_tariffs({
    SKIP_NOT_AVAILABLE_TARIFFS => 1,
    UID                        => $path_params->{uid},
    MODULE                     => 'Internet'
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 get_user_internet_tariffs_all($path_params, $query_params)

  Endpoint GET /user/internet/tariffs/all/

=cut
#**********************************************************
sub get_user_internet_tariffs_all {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->available_tariffs({
    UID    => $path_params->{uid},
    MODULE => 'Internet'
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 get_user_internet_id_warnings($path_params, $query_params)

  Endpoint GET /user/internet/:id/warnings/

=cut
#**********************************************************
sub get_user_internet_id_warnings {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Service_control->service_warning({
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
    MODULE => 'Internet'
  });
}

#**********************************************************
=head2 put_user_internet_id($path_params, $query_params)

  Endpoint PUT /user/internet/:id/

=cut
#**********************************************************
sub put_user_internet_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->user_chg_tp({
    %$query_params,
    UID    => $path_params->{uid},
    ID     => $path_params->{id}, #ID from internet main
    MODULE => 'Internet'
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  delete $result->{RESULT};
  $result->{result} = 'Successfully changed';

  return $result;
}

#**********************************************************
=head2 delete_user_internet_id($path_params, $query_params)

  Endpoint DELETE /user/internet/:id/

=cut
#**********************************************************
sub delete_user_internet_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->del_user_chg_shedule({
    UID        => $path_params->{uid},
    SHEDULE_ID => $path_params->{id}
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}


#**********************************************************
=head2 delete_user_internet_id($path_params, $query_params)

  Endpoint DELETE /user/internet/mac/discovery/

=cut
#**********************************************************
sub post_user_internet_mac_discovery {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10124,
    errstr => 'Service not available',
  } if (!$self->{conf}->{INTERNET_MAC_DICOVERY});

  $Internet->user_list({ UID => $path_params->{uid}, ID => $query_params->{ID}, COLS_NAME => 1 });

  return {
    errno  => 10125,
    errstr => "Not found service with id $query_params->{ID}",
  } if (!$Internet->{TOTAL});

  delete $Internet->{TOTAL};
  $Internet->user_list({ CID => $query_params->{CID} });

  return {
    errno  => 10126,
    errstr => 'This mac address already set for another user',
    cid    => $query_params->{CID},
  } if ($Internet->{TOTAL});

  $Internet->user_change({
    ID  => $query_params->{ID},
    UID => $path_params->{uid},
    CID => $query_params->{CID}
  });

  ::load_module('Internet::User_portal', { LOAD_PACKAGE => 1 });

  ::internet_hangup({
    CID   => $query_params->{CID},
    GUEST => 1,
  });

  return {
    result => 'Hangup is done',
  };
}

1;
