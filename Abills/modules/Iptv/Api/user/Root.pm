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
use Iptv::Services;

my Iptv $Iptv;
my Control::Service_control $Service_control;
my Control::Errors $Errors;
my Iptv::Services $Iptv_services;

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

  $Iptv_services = Iptv::Services->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang                 => $self->{lang},
    ENABLE_FEES_MESSAGES => 1,
    USER_PORTAL          => 1
  });
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

  require Control::Services;
  Control::Services->import();
  my $Services = Control::Services->new($self->{db}, $self->{admin}, $self->{conf});

  return $Services->get_user_services({
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

  my $result = $Iptv_services->user_add({ %{$query_params}, UID => $path_params->{uid} });
  if ($result->{INSERT_ID}) {
    $result->{CODE} = $result->{INSERT_ID};
  }

  return $result;
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
    ID     => $path_params->{id},
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

  $Iptv->user_info($path_params->{id}, { UID => $path_params->{uid} });

  return {
    result => 'Already active'
  } if (defined $Iptv->{STATUS} && $Iptv->{STATUS} == 0);

  my $result = $Iptv_services->user_activate({ ID => $path_params->{id}, UID => $path_params->{uid} });
  if (!$result->{errno}) {
    return {
      result => 'OK. Success activation'
    };
  }
  return $result;
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

  my $can_get_m3u_playlist = $Iptv_services->service_m3u_playlist({ ID => $path_params->{id}, CHECK_METHOD_AVAILABLE => 1 });
  if (!$can_get_m3u_playlist) {
    return {
      errno  => 20212,
      errstr => 'Get playlist link for this service not available',
    };
  }

  my $m3u = $Iptv_services->service_m3u_playlist({ ID => $path_params->{id} });
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

#**********************************************************
=head2 get_user_iptv_id_url($path_params, $query_params)

  Endpoint GET /user/iptv/:id/url/

=cut
#**********************************************************
sub get_user_iptv_id_url {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Iptv->user_info($path_params->{id}, { UID => $path_params->{uid} });

  if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0) {
    my $result = $Iptv_services->user_info({
      ID              => $path_params->{id},
      get_url         => 1,
      ONLY_ACTION_BTN => 1
    });

    if ($result->{errno}) {
      return $result;
    }

    if ($result->{actions} && ref $result->{actions} eq 'ARRAY' && scalar(@{$result->{actions}}) > 0) {
      return {
        result    => 'OK',
        watch_url => $result->{actions}[0]{url}
      };
    }
  }

  return {
    errno  => 20213,
    errstr => 'Get url link for this service not available',
  };
}

1;
