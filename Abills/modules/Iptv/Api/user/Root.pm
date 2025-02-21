package Iptv::Api::user::Root;

=head1 NAME

  User Iptv

  Endpoints:
    /user/iptv/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(camelize next_month);
use Iptv::Init qw/init_iptv_service/;

use Control::Errors;
use Iptv;
use Control::Service_control;
use Shedule;

my Iptv $Iptv;
my Control::Service_control $Service_control ;
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

  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});
  $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
  $Iptv->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_iptv($path_params, $query_params)

  Endpoint GET /user/iptv/

=cut
#**********************************************************
sub get_user_iptv {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
  return ::get_user_services({
    uid     => $path_params->{uid},
    service => 'Iptv',
  });
}

#**********************************************************
=head2 get_user_iptv_services($path_params, $query_params)

  Endpoint GET /user/iptv/services/

=cut
#**********************************************************
sub get_user_iptv_services {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $services_list = $Iptv->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => 2,
    COLS_NAME   => 1,
    PAGE_ROWS   => 1,
    SORT        => 's.id'
  });

  foreach my $service (@$services_list) {
    delete @{$service}{qw/status user_portal/};
  }

  return $services_list;
}

#**********************************************************
=head2 get_user_iptv_id_tariffs($path_params, $query_params)

  Endpoint GET /user/iptv/:id/tariffs/

=cut
#**********************************************************
sub get_user_iptv_id_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->available_tariffs({
    SKIP_NOT_AVAILABLE_TARIFFS => 1,
    UID                        => $path_params->{uid},
    MODULE                     => 'Iptv',
    ID                         => $path_params->{id},
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 get_user_iptv_id_warnings($path_params, $query_params)

  Endpoint GET /user/iptv/:id/warnings/

=cut
#**********************************************************
sub get_user_iptv_id_warnings {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Service_control->service_warning({
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
    MODULE => 'Iptv'
  });
}

#**********************************************************
=head2 get_user_iptv_tariffs($path_params, $query_params)

  Endpoint GET /user/iptv/tariffs/

=cut
#**********************************************************
sub get_user_iptv_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $services_list = $Iptv->services_list({
    STATUS      => 0,
    NAME        => '_SHOW',
    USER_PORTAL => 2,
    COLS_NAME   => 1,
    SORT        => 's.id'
  });

  foreach my $service (@$services_list) {
    delete @{$service}{qw/status user_portal/};
    my $tariffs = $Service_control->available_tariffs({
      SKIP_NOT_AVAILABLE_TARIFFS => 1,
      UID                        => $path_params->{uid},
      MODULE                     => 'Iptv',
      SERVICE_ID                 => $service->{id},
      ADD_FIRST_SERVICE          => 1
    });
    $service->{tariffs} = $tariffs;
  }

  return $services_list;
}

#**********************************************************
=head2 get_user_iptv_tariffs_service_id($path_params, $query_params)

  Endpoint GET /user/iptv/tariffs/:service_id/

=cut
#**********************************************************
sub get_user_iptv_tariffs_service_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->available_tariffs({
    SKIP_NOT_AVAILABLE_TARIFFS => 1,
    UID                        => $path_params->{uid},
    MODULE                     => 'Iptv',
    SERVICE_ID                 => $path_params->{service_id},
    ADD_FIRST_SERVICE          => 1
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 get_user_iptv_promotion_tariffs($path_params, $query_params)

  Endpoint GET /user/iptv/promotion/tariffs/

=cut
#**********************************************************
sub get_user_iptv_promotion_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $list = $Iptv->iptv_promotion_tps();

  if (scalar @{$list}) {
    foreach my $tariff (@{$list}) {
      delete @{$tariff}{qw/module/};
    }
  }

  return $list;
}

#**********************************************************
=head2 get_user_iptv_id_holdup($path_params, $query_params)

  Endpoint GET /user/iptv/:id/holdup/

=cut
#**********************************************************
sub get_user_iptv_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->user_holdup({
    MODULE => 'Iptv',
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 post_user_iptv_id_holdup($path_params, $query_params)

  Endpoint POST /user/iptv/:id/holdup/

=cut
#**********************************************************
sub post_user_iptv_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->user_holdup({
    MODULE => 'Iptv',
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
    add    => 1
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 delete_user_iptv_id_holdup($path_params, $query_params)

  Endpoint DELETE /user/iptv/:id/holdup/

=cut
#**********************************************************
sub delete_user_iptv_id_holdup {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->user_holdup({
    MODULE => 'Iptv',
    UID    => $path_params->{uid},
    ID     => $path_params->{id},
    del    => 1
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 post_user_iptv_tariff_add($path_params, $query_params)

  Endpoint POST /user/iptv/tariff/add/

=cut
#**********************************************************
sub post_user_iptv_tariff_add {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my ($subscribe_id) = split(/:/, $self->{conf}->{IPTV_SUBSCRIBE_ID} || q{});
  $subscribe_id = $subscribe_id || 'EMAIL';

  $query_params = {
    TP_ID         => $query_params->{TP_ID} || 0,
    add           => 1,
    $subscribe_id => $query_params->{$subscribe_id} || '',
    SERVICE_ID    => $query_params->{SERVICE_ID},
  };
  %main::FORM = %{$query_params};

  my $uid = $path_params->{uid};

  return {
    errno  => 20204,
    errstr => 'No field tpId',
  } if (!$query_params->{TP_ID});

  return {
    errno  => 20203,
    errstr => "No field " . camelize($subscribe_id),
  } if (!$query_params->{$subscribe_id});

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $Tariffs->info($query_params->{TP_ID});
  $query_params->{SERVICE_ID} = $Tariffs->{SERVICE_ID};

  my $services_list = $Iptv->services_list({
    STATUS          => 0,
    USER_PORTAL     => 2,
    SUBSCRIBE_COUNT => '_SHOW',
    SORT            => 's.id',
    ID              => $query_params->{SERVICE_ID} || '--',
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
  });

  return {
    errno  => 20206,
    errstr => 'Unknown tpId',
  } if (!scalar @{$services_list});

  my $tariffs = $Service_control->available_tariffs({
    SKIP_NOT_AVAILABLE_TARIFFS => 1,
    UID                        => $uid,
    MODULE                     => 'Iptv',
    SERVICE_ID                 => $query_params->{SERVICE_ID},
    ADD_FIRST_SERVICE          => 1
  });

  if ($tariffs) {
    my $allowed = 0;
    foreach my $tariff (@{$tariffs}) {
      next if (!$tariff->{tp_id} || "$tariff->{tp_id}" ne "$query_params->{TP_ID}");
      $allowed = 1;
      last;
    }

    return {
      errno  => 20208,
      errstr => 'Unknown tpId',
    } if (!$allowed);
  }
  else {
    return {
      errno  => 20207,
      errstr => 'Unknown tpId',
    };
  }

  my $service_info = $services_list->[0];
  $Iptv->user_list({
    SERVICE_ID => $query_params->{SERVICE_ID},
    UID        => $uid,
    COLS_NAME  => 1,
    PAGE_ROWS  => 99999,
  });

  if ($service_info && $service_info->{SUBSCRIBE_COUNT} <= $Iptv->{TOTAL}) {
    return {
      errno  => 20200,
      errstr => "Have exceeded the number of subscriptions for this service - $service_info->{SUBSCRIBE_COUNT}",
    };
  }

  if ($self->{conf}->{IPTV_USER_UNIQUE_TP}) {
    $Iptv->user_list({
      SERVICE_ID => $query_params->{SERVICE_ID},
      UID        => $uid,
      TP_ID      => $query_params->{TP_ID},
      COLS_NAME  => 1,
    });

    if ($Iptv->{TOTAL}) {
      return {
        errno  => 20201,
        errstr => 'This tariff plan is already connected',
      };
    }
  }

  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;
  my DBI $db_ = $Iptv->{db}{db};

  $Iptv->user_add({
    $subscribe_id => $query_params->{$subscribe_id},
    UID           => $uid,
    IPTV_ACTIVATE => !$Tariffs->{PERIOD_ALIGNMENT} && $main::DATE ? $main::DATE : '0000-00-00',
    TP_ID         => $query_params->{TP_ID},
    SERVICE_ID    => $query_params->{SERVICE_ID}
  });

  if (!$Iptv->{errno}) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($uid);

    # $Iptv->{ACCOUNT_ACTIVATE} = $Users->{ACTIVATE};
    $Iptv->{TP_INFO}{ABON_DISTRIBUTION} ||= 0;
    $Iptv->{TP_INFO}{PERIOD_ALIGNMENT} ||= 0;

    ::service_get_month_fee($Iptv, { SERVICE_NAME => 'TV', MODULE => 'Iptv' });

    $Iptv->{ID} = $Iptv->{INSERT_ID};
    $Iptv->user_info($Iptv->{ID});
    $Iptv->{SERVICE_ID} //= $query_params->{SERVICE_ID};
    $main::Tv_service = undef;

    if ($Iptv->{SERVICE_ID}) {
      $main::Iptv = $Iptv;
      $main::Tv_service = init_iptv_service($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf}, {
        SERVICE_ID   => $Iptv->{SERVICE_ID},
        RETURN_ERROR => 1
      });
    }

    if ($main::Tv_service) {
      ::load_module('Iptv::Users', { LOAD_PACKAGE => 1 });
      my $result = ::iptv_account_action({
        %{$query_params},
        ID        => $Iptv->{ID},
        SCREEN_ID => undef,
        USER_INFO => $Users,
        UID       => $uid,
        add       => 1
      });

      if ($result) {
        $db_->rollback();
        $db_->{AutoCommit} = 1;
        delete($Iptv->{db}->{TRANSACTION});
        return {
          errno   => 20209,
          errstr  => $Iptv->{errstr},
          service => $main::Tv_service->{SERVICE_NAME},
        };
      }
      else {
        delete($Iptv->{db}->{TRANSACTION});
        $db_->commit();
        $db_->{AutoCommit} = 1;
        return {
          result => "Added ID: $Iptv->{ID}",
          code   => 2,
        };
      }
    }
    else {
      delete($Iptv->{db}->{TRANSACTION});
      $db_->commit();
      $db_->{AutoCommit} = 1;
      return {
        result => "Added ID: $Iptv->{ID}",
        code   => 1
      };
    }
  }
  else {
    delete($Iptv->{db}->{TRANSACTION});
    $db_->rollback();
    $db_->{AutoCommit} = 1;
    return {
      errno  => 20205,
      errstr => "IPTV error $Iptv->{errno}",
    };
  }
}

#**********************************************************
=head2 put_user_iptv_id($path_params, $query_params)

  Endpoint PUT /user/iptv/:id/

=cut
#**********************************************************
sub put_user_iptv_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (
    TP_ID  => $query_params->{TP_ID},
    period => 1
  );

  if ($self->{conf}->{IPTV_USER_CHG_TP_SHEDULE} && !$self->{conf}->{IPTV_USER_CHG_TP_NPERIOD}) {
    $params{DATE} = $query_params->{DATE} || '';
    $params{period} = $query_params->{period} || 1;
  }

  my $result = $Service_control->user_chg_tp({
    %params,
    UID    => $path_params->{uid},
    ID     => $path_params->{id}, #ID from iptv main
    MODULE => 'Iptv'
  });

  return {
    errno  => $result->{error} || $result->{errno},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 delete_user_iptv_id($path_params, $query_params)

  Endpoint DELETE /user/iptv/:id/

=cut
#**********************************************************
sub delete_user_iptv_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Service_control->del_user_chg_shedule({
    UID        => $path_params->{uid},
    SHEDULE_ID => $path_params->{id}
  });

  return {
    errno  => $result->{error} || $result->{errno},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

#**********************************************************
=head2 post_user_iptv_id_activate($path_params, $query_params)

  Endpoint POST /user/iptv/:id/activate/

=cut
#**********************************************************
sub post_user_iptv_id_activate {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  %main::FORM = ();
  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  my $user_info = $Users->info($path_params->{uid});

  $Iptv->user_info($path_params->{id}, { UID => $path_params->{uid} });

  return {
    result => 'Already active'
  } if (defined $Iptv->{STATUS} && $Iptv->{STATUS} == 0);

  return {
    errno  => 20210,
    errstr => 'Can\'t activate, not allowed'
  } unless ($Iptv->{STATUS} && $Iptv->{STATUS} == 5);

  $Iptv->services_list({ USER_PORTAL => '>0', ID => $Iptv->{SERVICE_ID} });

  return {
    errno  => 20215,
    errstr => 'Can\'t activate, not allowed',
  } if (!($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0));

  ::load_module('Iptv::Users', { LOAD_PACKAGE => 1 });
  ::load_module('Iptv', $self->{html});

  my $status = ::iptv_user_activate($Iptv, { USER => $user_info, SILENT => 1 });

  if ($status) {
    return {
      result => 'OK. Success activation'
    }
  }
  else {
    return {
      errno  => 20214,
      errstr => 'Failed activate'
    };
  }
}

#**********************************************************
=head2 get_user_iptv_id_playlist($path_params, $query_params)

  Endpoint GET /user/iptv/:id/playlist/

=cut
#**********************************************************
sub get_user_iptv_id_playlist {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 20211,
    errstr => 'Not enabled',
  } if (!$self->{conf}->{IPTV_CLIENT_M3U});

  $Iptv->user_info($path_params->{id}, { UID => $path_params->{uid} });

  %main::FORM = ();
  $main::Iptv = $Iptv;
  $main::Tv_service = undef;

  $main::Tv_service = init_iptv_service($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf}, {
    SERVICE_ID => $Iptv->{SERVICE_ID}
  });

  if ($main::Tv_service && $main::Tv_service->can('get_playlist_m3u')) {
    my $m3u = $main::Tv_service->get_playlist_m3u($Iptv);
    $m3u =~ s/#EXTM3U//g;
    my @channels_list = $m3u =~ /#EXTINF.+\r?\n.+/gm;
    my @channels;

    foreach my $channel (@channels_list) {
      my ($tvg_id) = $channel =~ /((?<=tvg-id=")(.*)(?=" ))/gm;
      my ($logo) = $channel =~ /((?<=tvg-logo=")(.*)(?="))/gm;
      my ($tv_name) = $channel =~ /(?<=,).+/gm;
      my ($link) = $channel =~ /.+p1\.sweet\.tv.+/gm;

      push @channels, {
        logo  => $logo,
        name  => $tv_name,
        link  => $link,
        tv_id => $tvg_id,
      };
    }

    return \@channels;
  }
  else {
    return {
      errno  => 20212,
      errstr => 'Get playlist link for this service not available',
    };
  }
}

#**********************************************************
=head2 get_user_iptv_id_url($path_params, $query_params)

  Endpoint GET /user/iptv/:id/url/

=cut
#**********************************************************
sub get_user_iptv_id_url {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Iptv->user_info($path_params->{id}, { UID => $path_params->{uid} });

  %main::FORM = ();
  $main::Iptv = $Iptv;
  $main::Tv_service = undef;

  $main::Tv_service = init_iptv_service($Iptv->{db}, $Iptv->{admin}, $Iptv->{conf}, {
    SERVICE_ID => $Iptv->{SERVICE_ID}
  });

  if ($main::Tv_service && $main::Tv_service->can('get_url')) {
    my $result = $main::Tv_service->get_url($Iptv);
    my $url = $result->{result} && $result->{result}{web_url} ? $result->{result}{web_url} : '';
    return {
      result    => 'OK',
      watch_url => $url
    };
  }
  else {
    return {
      errno  => 20213,
      errstr => 'Get url link for this service not available',
    };
  }
}

1;
