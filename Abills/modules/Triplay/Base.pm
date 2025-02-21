package Triplay::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my %lang;
my Triplay $Triplay;

use Abills::Base qw/days_in_month in_array next_month/;

use Control::Errors;
my Control::Errors $Errors;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if ($attr->{HTML});
  %lang = %{$attr->{LANG}} if ($attr->{LANG});

  my $self = {};

  require Triplay;
  Triplay->import();
  $Triplay = Triplay->new($db, $admin, $CONF);

  $Errors = Control::Errors->new($db, $admin, $CONF, { lang => \%lang || {}, module => 'Triplay' });

  bless($self, $class);

  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head triplay_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID

  Return:

=cut
#**********************************************************
sub triplay_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID};

  $Triplay->user_list({ UID => $uid });

  return ($Triplay->{TOTAL}) ? $Triplay->{TOTAL} : '';
}

#**********************************************************
=head2 triplay_docs($attr) - get services for invoice

  Arguments:
    UID
    FEES_INFO
    SKIP_DISABLED
    FULL_INFO

  Returns:


=cut
#**********************************************************
sub triplay_docs {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};
  my @services = ();
  my %info = ();

  my $service_list = $Triplay->user_list({
    UID               => $uid,
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    SERVICE_STATUS    => '_SHOW',
    ABON_DISTRIBUTION => '_SHOW',
    TP_NAME           => '_SHOW',
    FEES_METHOD       => '_SHOW',
    TP_ID             => '_SHOW',
    TP_NUM            => '_SHOW',
    TP_FIXED_FEES_DAY => '_SHOW',
    TP_REDUCTION_FEE  => '_SHOW',
    PERSONAL_TP       => '_SHOW',
    COLS_NAME         => 1
  });

  if ($attr->{FEES_INFO} || $attr->{FULL_INFO}) {
    foreach my $service_info (@{$service_list}) {
      my %FEES_DSC = (
        MODULE          => 'Triplay',
        SERVICE_NAME    => 'Triplay',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $main::FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
      $info{service_desc} = q{};
      $info{tp_name} = $service_info->{tp_name};
      $info{tp_fixed_fees_day} = $service_info->{tp_fixed_fees_day} || 0;
      $info{status} = $service_info->{service_status};
      $info{tp_reduction_fee} = $service_info->{tp_reduction_fee};
      #print "// $info{tp_reduction_fee} = $service_info->{tp_reduction_fee}; //";
      $info{module_name} = 'Triplay';

      if ($service_info->{service_status} && $service_info->{service_status} != 5 && $attr->{SKIP_DISABLED}) {
        $info{day} = 0;
        $info{month} = 0;
        $info{abon_distribution} = 0;
      }
      else {
        if ($service_info->{personal_tp} && $service_info->{personal_tp} > 0) {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{personal_tp};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
        else {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{month_fee};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
      }

      return \%info if !$attr->{FULL_INFO};

      push @services, { %info };
    }
  }

  return \@services if $attr->{FULL_INFO} || $Triplay->{TOTAL} < 1;

  foreach my $service_info (@$service_list) {
    next if $service_info->{service_status} && $service_info->{service_status} != 5 && !$attr->{SHOW_ALL};

    if ($service_info->{month_fee} && $service_info->{month_fee} > 0) {
      my %FEES_DSC = (
        MODULE          => 'Triplay',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $main::FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      #Fixme / make hash export
      push @services, ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{month_fee}||$service_info->{tp_name}"
        . "|||$service_info->{service_status}";
    }

    if ($service_info->{day_fee} && $service_info->{day_fee} > 0) {
      my $days_in_month = days_in_month({ DATE => next_month({ DATE => $main::DATE }) });
      push @services, "Triplay: $lang{MONTH_FEE_SHORT}: $service_info->{tp_name} ($service_info->{tp_id})|$days_in_month $lang{DAY}|"
        . sprintf("%.2f", ($service_info->{day_fee} * $days_in_month)) . "||$service_info->{tp_name}"
        . "||";
    }
  }

  return \@services;
}

#**********************************************************
=head2 triplay_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub triplay_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user = $attr->{USER_INFO} if ($attr->{USER_INFO});

  $Triplay->user_info({ UID => $user->{UID}, });

  return 1 if (!$Triplay->{UID});

  $Triplay->{MONTH_ABON} //= 0;
  $Triplay->{DAY_ABON} //= 0;

  my $deposit = (defined($user->{DEPOSIT})) ? $user->{DEPOSIT} + (($user->{CREDIT}) ? $user->{CREDIT} : ($Triplay->{TP_CREDIT} || 0)) : 0;
  my $abon_fees = (!$user->{REDUCTION}) ? $Triplay->{MONTH_ABON} + $Triplay->{DAY_ABON} :
    ($Triplay->{MONTH_ABON} + $Triplay->{DAY_ABON}) * (100 - $user->{REDUCTION}) / 100;

  if ($attr->{FORM} && $attr->{FORM}{DISABLE} && !$Triplay->{DISABLE}) {
    $Triplay->user_change({
      UID     => $user->{UID},
      ID      => $Triplay->{ID},
      DISABLE => 1
    });

    $attr->{STATUS} = 1;
    $attr->{DISABLE} = 1;
    $self->triplay_service_activate_web($attr);
    return 1;
  }

  if (in_array($Triplay->{DISABLE}, [ 2, 4, 5 ])) {
    if (in_array($Triplay->{DISABLE}, [ 2 ])) {
      if ($Triplay->{TP_PERIOD_ALIGNMENT}) {
        my $days_in_month = days_in_month({ DATE => $attr->{DATE} });
        my (undef, undef, $d)=split(/\-/, $main::DATE);
        $abon_fees = ($abon_fees / $days_in_month) * ($days_in_month - $d + 1);
      }
    }

    if ($deposit > $abon_fees) {
      my %params = ();
      $Triplay->user_change({
        %params,
        UID     => $user->{UID},
        ID      => $Triplay->{ID},
        DISABLE => 0,
      });

      if ($CONF->{TRIPLAY_FULL_MONTH} && $Triplay->{DISABLE} != 2) {
        $attr->{FULL_MONTH_FEE} = 1;
      }

      $attr->{STATUS} = 0;
      $attr->{DISABLE} = 0;
      $attr->{ACTIVATE_SERVICE} = 1;
      $self->triplay_service_activate_web($attr);
    }
  }

  return 1;
}

#**********************************************************
=head2 triplay_user_del($uid, $attr) - Delete user from module

  Arguments:
    $attr

  Results:
    TRUE or False

=cut
#**********************************************************
sub triplay_user_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Triplay->{UID} = $attr->{USER_INFO}{UID};
  $Triplay->user_del({ UID => $attr->{USER_INFO}{UID}, COMMENTS => $attr->{USER_INFO}{COMMENTS} });

  use Log;
  my $Log = Log->new($db, $CONF);
  $Log->log_del({ LOGIN => $attr->{USER_INFO}{LOGIN} });

  return 1;
}

#**********************************************************
=head2 triplay_service_activate_web($attr) - Service activate

  Arguments:
    $attr
      UID
      TP_ID  - Triplay TP_ID
      STATUS - Default: 0
      USER_INFO
      TP_INFO
      ACTIVATE_SERVICE - ACtivite service after payments

      INTERNET_TP
      IPTV_TP
      ABON_TP
      SKIP_MONTH_FEE

      INTERNET_SERVICE_ID

  Returns:

=cut
#**********************************************************
sub triplay_service_activate_web {
  my $self = shift;
  my ($attr) = @_;

  delete $INC{'Control/Services.pm'};
  eval {
    do 'Control/Services.pm';
  };

  my $user_info = $attr->{USER_INFO};
  my $uid = $attr->{UID} || $user_info->{UID} || 0;
  my $triplay_tp_info = $Triplay->tp_info({ TP_ID => $attr->{TP_ID} });

  $attr->{INTERNET_TP_ID} = $triplay_tp_info->{INTERNET_TP};
  $attr->{IPTV_TP_ID} = $triplay_tp_info->{IPTV_TP};
  $attr->{ABON_TP_ID} = $triplay_tp_info->{ABON_TP};
  my $status = (defined $attr->{STATUS}) ? $attr->{STATUS} : (defined $attr->{DISABLE}) ? $attr->{DISABLE} : 0;
  my $get_services = $attr->{ACTIVATE_SERVICE} || $self->{conf}->{TRIPLAY_REWRITE_SERVICE} || 0;

  if ($get_services) {
    my $services = get_services($user_info, {
      IPTV_SHOW_FREE_TPS     => 1,
      IPTV_SHOW_ALL_SERVICES => 1,
      SKIP_MODULES           => 'Triplay'
    });

    if ($services && $services->{list}) {
      foreach my $service (sort @{$services->{list}}) {
        next if !$service->{ID};

        my $name = uc($service->{MODULE}) . '_SERVICE_ID';
        my $tp_name = uc($service->{MODULE}) . '_TP_ID';

        if ($attr->{TP_INFO_OLD}) {
          next if !$attr->{$tp_name} && $attr->{TP_INFO_OLD}{uc($service->{MODULE}) . '_TP'};
        }

        $attr->{$name} = $service->{ID};
        if (!$attr->{$tp_name}) {
          $attr->{$tp_name} = $service->{TP_ID};
        }
      }
    }
  }

  if ($attr->{INTERNET_TP_ID}) {
    my $service_id = $attr->{INTERNET_SERVICE_ID} || 0;

    if (!$service_id) {
      ::load_module("Internet::Users", { LOAD_PACKAGE => 1 }) if (!exists($INC{"Internet::Users"}));
      $service_id = ::internet_user_add({
        %$attr,
        SERVICE_ADD => 1,
        USER_INFO   => $user_info,
        UID         => $uid,
        STATUS      => $status,
        TP_ID       => $attr->{INTERNET_TP_ID},
        PERSONAL_TP => 0.00
      });
    }
    elsif ($service_id) {
      ::load_module("Internet::Users", { LOAD_PACKAGE => 1 }) if (!exists($INC{"Internet::Users"}));

      ::internet_user_change({
        %$attr,
        USER_INFO => $user_info,
        UID       => $uid,
        STATUS    => (in_array($status, [0, 2])) ? $status : 1,
        ID        => $service_id,
        TP_ID     => $attr->{INTERNET_TP_ID},
        PERSONAL_TP => 0.00,
        QUITE     => 1
      });
    }

    if ($service_id) {
      $Triplay->service_add({
        UID        => $uid,
        SERVICE_ID => $service_id,
        MODULE     => 'Internet',
      });
    }
  }

  if ($attr->{IPTV_TP_ID}) {
    my $service_id = $attr->{IPTV_SERVICE_ID} || 0;

    if (!$service_id) {
      ::load_module("Iptv") if (!exists($INC{"Iptv"}));
      # do not adding if not enough money $Iptv->{user_add} will return errno 15
      $service_id = ::iptv_user_add({
        %$attr,
        SERVICE_ADD => 1,
        USER_INFO   => $user_info,
        UID         => $uid,
        TP_ID       => $attr->{IPTV_TP_ID},
        STATUS      => $status
      });
    }
    elsif ($service_id) {
      ::load_module("Iptv") if (!exists($INC{"Iptv"}));
      ::iptv_user_change({
        %$attr,
        USER_INFO => $user_info,
        UID       => $uid,
        #STATUS    => $attr->{DISABLE} && !in_array($attr->{DISABLE}, [ 5 ]) ? $attr->{DISABLE} : $status,
        STATUS    => (in_array($status, [0, 2])) ? $status : 1,
        ID        => $service_id,
        TP_ID     => $attr->{IPTV_TP_ID},
        QUITE     => 1
      });
    }

    if ($service_id) {
      $Triplay->service_add({
        UID        => $uid,
        SERVICE_ID => $service_id,
        MODULE     => 'Iptv',
      });
    }
  }
  elsif ($attr->{TP_INFO_OLD} && $attr->{TP_INFO_OLD}{IPTV_TP}) {
    #TODO: Added using packages
    ::load_module("Iptv") if (!exists($INC{"Iptv"}));
    ::iptv_user_del({
      %$attr,
      USER_INFO => $user_info,
      UID       => $uid,
      # ID        => $service_id,
      TP_ID     => $attr->{TP_INFO_OLD}{IPTV_TP},
      QUITE     => 1
    });
  }

  if ($attr->{ABON_TP_ID}) {
    my $service_id = $attr->{ABON_SERVICE_ID} || 0;

    if (!$service_id) {
      ::load_module('Abon');
      $service_id = ::abon_user_add({
        %$attr,
        SERVICE_ADD => 1,
        USER_INFO   => $user_info,
        UID         => $uid,
        TP_ID       => $attr->{ABON_TP_ID},
        EXPIRE      => $attr->{EXPIRE}
      });
    }

    $Triplay->service_add({
      UID        => $uid,
      SERVICE_ID => $service_id,
      MODULE     => 'Abon',
    });
  }
  #TODO: auto add voip tariff like internet/iptv/abon
  #TODO: make unification of function names on activation and call dynamically from modules
  #TODO: right now cringe static activation and its bad

  #Make month fee
  $Triplay->user_info({ UID => $uid });
  if (!$attr->{DISABLE} && !$attr->{SKIP_MONTH_FEE}) {
    if (!$Triplay->{TP_INFO} && $attr->{TP_INFO}) {
      $Triplay->{TP_INFO} = $attr->{TP_INFO};
    }

    if ($attr->{TP_INFO_OLD}) {
      $Triplay->{TP_INFO_OLD}=$attr->{TP_INFO_OLD};
    }

    ::service_get_month_fee($Triplay, {
      %$attr,
      REGISTRATION   => 1,
      SERVICE_NAME   => 'Triplay',
      MODULE         => 'Triplay',
      FULL_MONTH_FEE => $attr->{FULL_MONTH_FEE}
    });
  }

  return 1;
}

#**********************************************************
=head2 triplay_service_del($attr)

=cut
#**********************************************************
sub triplay_service_del {
  my $self = shift;
  my ($attr) = @_;

  delete $INC{'Control/Services.pm'};
  eval {
    do 'Control/Services.pm';
  };

  my $user_info = $attr->{USER_INFO} || {};
  my $uid = $attr->{UID} || $user_info->{UID} || 0;
  my $triplay_info = $Triplay->user_info({ UID => $uid, ID => $attr->{ID} });
  return $Errors->throw_error(1130002) if !$Triplay->{TOTAL} || $Triplay->{TOTAL} < 1 || !$Triplay->{TP_ID};

  my $triplay_tp_info = $Triplay->tp_info({ TP_ID => $Triplay->{TP_ID} });

  if ($triplay_tp_info->{IPTV_TP}) {
    ::load_module("Iptv") if (!exists($INC{"Iptv"}));
    ::iptv_user_del({
      %$attr,
      USER_INFO => $user_info,
      UID       => $uid,
      TP_ID     => $triplay_tp_info->{IPTV_TP},
      QUITE     => 1
    });
  }

  $Triplay->user_del({ UID => $uid });
  if ($Triplay->{errno}) {
    $self->{errno} = $Triplay->{errno};
    $self->{errstr} = $Triplay->{errstr};
  }

  return $self;
}

#**********************************************************
=head2 triplay_user_services($attr) - Get user services

=cut
#**********************************************************
sub triplay_user_services {
  my $self = shift;
  my ($attr) = @_;

  return [] if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  my Users $user = $attr->{USER_INFO};

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($db, $admin, $CONF);

  my $tariffs = $Service_control->services_info({
    UID                 => $user->{UID},
    MODULE              => 'Triplay',
    FUNCTION_PARAMS     => {
      SERVICE_STATUS   => '_SHOW',
      INTERNET_TP_NAME => '_SHOW',
      IPTV_TP_NAME     => '_SHOW',
      ABON_TP_NAME     => '_SHOW',
      VOIP_TP_NAME     => '_SHOW',
    },
    UPDATE_SERVICE_INFO => sub {
      my ($service_info, $tariff) = @_;

      ::load_module('Control::Services', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Control/Services.pm'}));

      # a little bit strange logic if we want to get all service info of such tps
      my $user_services = ::get_user_services({
        uid           => $user->{UID},
        skip_services => 'Triplay',
      });

      my $services = $service_info->service_list({
        UID        => $user->{UID},
        MODULE     => '_SHOW',
        SERVICE_ID => '_SHOW',
        COLS_NAME  => 1
      });

      foreach my $service (@$services) {
        foreach my $user_service (@{$user_services->{$service->{module}}}) {
          next if ($service->{service_id} != $user_service->{id});

          # create array because in future maybe will be tp multiselect
          push @{$tariff->{services}->{$service->{module}}}, $user_service;
        }
      }

      return $tariff;
    }
  });

  return $tariffs;
}

1;
