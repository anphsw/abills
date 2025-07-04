package Triplay::Services;

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Triplay;
use Triplay::Base;

my (%lang, $html);

my Control::Errors $Errors;

my Triplay $Triplay;
my Triplay::Base $Triplay_base;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  my $admin = shift;
  my $CONF = shift;
  my $attr = shift;

  %lang = %{$attr->{LANG}} if $attr->{LANG};
  $html = $attr->{HTML} if $attr->{HTML};

  my $self = {};

  $Triplay = Triplay->new($db, $admin, $CONF);
  $Triplay_base = Triplay::Base->new($db, $admin, $CONF, { HTML => $html, LANG => \%lang });

  if ($attr->{ERRORS}) {
    $Errors = $attr->{ERRORS};
  }
  else {
    $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, { module => 'Triplay' });
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 user_info($attr) - in menu services

  Arguments:
    $attr
      UID

  Returns:

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my $user_info = $Triplay->user_info({ UID => $uid });

  if ($Triplay->{TOTAL}) {
    my $service_list = $Triplay->service_list({
      UID        => $uid,
      MODULE     => '_SHOW',
      SERVICE_ID => '_SHOW',
      COLS_NAME  => 1
    });

    my %user_services = ();
    foreach my $service (@$service_list) {
      $user_services{uc($service->{module}) . '_SERVICE_ID'} = $service->{service_id};
    }

    $user_info->{user_services} = \%user_services;
    $user_info->{TOTAL} = 1;
  }

  return $user_info;
}

#**********************************************************
=head2 user_add ($attr) - User add

  Arguments:
    $attr
      USER_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $users = $attr->{USER_INFO};

  $Triplay->user_add($attr);

  if (!$Triplay->{errno}) {
    $Triplay_base->triplay_service_activate({
      %$attr,
      USER_INFO => $users,
      TP_INFO   => $Triplay->{TP_INFO}
    });
  }
  else {
    if ($Triplay->{errno}) {
      if ($Triplay->{errno} == 3) {
        return $Errors->throw_error(1130003);
      }
      else {
        $self->{errno} = $Triplay->{errno};
        $self->{errstr} = $Triplay->{errstr};
      }
    }

    return 0;
  }

  #TODO: maybe return more extended information as object with services which added, like ids from iptv_main, internet_main and etc?

  return 1;
}

#**********************************************************
=head2 user_change($attr) - in menu services

  Arguments:
    $attr
      UID
      USER_INFO

  Returns:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || q{};
  my $users = $attr->{USER_INFO};

  $Triplay->user_change($attr);

  if (!$Triplay->{errno}) {
    my $changed = $Triplay->{AFFECTED};
    $Triplay->user_info({ UID => $uid });

    my $service_list = $Triplay->service_list({
      UID        => $uid,
      MODULE     => '_SHOW',
      SERVICE_ID => '_SHOW',
      COLS_NAME  => 1
    });

    foreach my $service (@$service_list) {
      $attr->{uc($service->{module}) . '_SERVICE_ID'} = $service->{service_id} if ($service->{service_id});
    }

    if ($changed) {
      $attr->{TP_ID} = $Triplay->{TP_ID};
      if ($attr->{DISABLE}) {
        $attr->{STATUS} = $attr->{DISABLE};
      }

      $Triplay_base->triplay_service_activate({
        %$attr,
        USER_INFO => $users,
        TP_INFO   => $Triplay->{TP_INFO}
      });
    }
  }
  else {
    $self->{errno} = $Triplay->{errno};
    $self->{errstr} = $Triplay->{errstr};
  }

  return 1;
}

#**********************************************************
=head2 user_del($attr)

  Argumnets:
    $attr
      UID

  Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  delete $INC{'Control/Services.pm'};
  eval {
    do 'Control/Services.pm';
  };

  my $user_info = $attr->{USER_INFO} || {};
  my $uid = $attr->{UID} || $user_info->{UID} || 0;
  $Triplay->user_info({ UID => $uid, ID => $attr->{ID} });
  if (!$Triplay->{TOTAL} || $Triplay->{TOTAL} < 1 || !$Triplay->{TP_ID}) {
    return $Errors->throw_error(1130002);
  }

  my $triplay_tp_info = $Triplay->tp_info({ TP_ID => $Triplay->{TP_ID} });

  # if ($triplay_tp_info->{INTERNET_TP}) {
  #   ::load_module("Internet") if (!exists($INC{"Internet"}));
  #   ::internet_user_del({
  #     %$attr,
  #     USER_INFO => $user_info,
  #     UID       => $uid,
  #     TP_ID     => $triplay_tp_info->{INTERNET_TP},
  #     QUITE     => 1
  #   });
  # }

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

  #TODO add extra info about status of deletion of subservices

  return $self;
}

1;
