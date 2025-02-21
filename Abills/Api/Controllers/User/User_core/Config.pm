package Api::Controllers::User::User_core::Config;

=head1 NAME

  User API Config

  Endpoints:
    /user/config/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;

use Control::Errors;
use Users;
use Control::Service_control;
use Abills::Api::Functions;

my Control::Errors $Errors;
my Users $Users;
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

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf},
    { HTML => $self->{html}, LANG => $self->{lang} }
  );

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_config($path_params, $query_params)

  Endpoint GET /user/config/

=cut
#**********************************************************
sub get_user_config {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $Functions = Abills::Api::Functions->new($self->{db}, $self->{admin}, $self->{conf}, {
    modules => \@main::MODULES,
    uid     => $path_params->{uid}
  });

  my $user = $Users->list({
    UID        => $path_params->{uid},
    GID        => '_SHOW',
    COMPANY_ID => '_SHOW',
    _GOOGLE    => '_SHOW',
    _FACEBOOK  => '_SHOW',
    _APPLE     => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  })->[0];

  my %functions = %{$Functions->{functions}};

  if ($functions{internet_user_chg_tp}) {
    my $list = $Service_control->available_tariffs({
      UID    => $path_params->{uid},
      MODULE => 'Internet'
    });

    if (ref $list ne 'ARRAY') {
      delete $functions{internet_user_chg_tp};
    }
    else {
      $functions{internet}{now} = 0 if ($self->{conf}->{INTERNET_USER_CHG_TP_NOW});
      $functions{internet}{next_month} = 1 if ($self->{conf}->{INTERNET_USER_CHG_TP_NEXT_MONTH});
      $functions{internet}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE});
    }
  }

  if ($self->{conf}->{HOLDUP_ALL} || $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP}) {
    my ($type_holdup, $holdup);

    if ($self->{conf}->{HOLDUP_ALL}) {
      $type_holdup = 'user_holdup_all';
      $holdup = $self->{conf}->{HOLDUP_ALL};
    }
    else {
      $type_holdup = 'internet_user_holdup';
      $holdup = $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP};
    }

    my @holdup_rules = split(/;/, $holdup);
    $functions{holdup} = [];

    foreach my $holdup_rule (@holdup_rules) {
      my ($min_period, $max_period, $holdup_period, $daily_fees, undef, $active_fees, $holdup_skip_gids) = split(/:/, $holdup_rule);

      if ($holdup_skip_gids) {
        my @holdup_skip_gids_arr = split(/,\s?/, $holdup_skip_gids);
        next if ($user->{GID} && in_array($user->{GID}, \@holdup_skip_gids_arr));
      }

      my $holdup_rules = {
        min_period    => $min_period,
        max_period    => $max_period,
        holdup_period => $holdup_period,
        daily_fees    => $daily_fees,
        active_fees   => $active_fees
      };

      if (!$functions{$type_holdup}) {
        $functions{$type_holdup} = {%$holdup_rules};
      }

      push @{$functions{holdup}}, $holdup_rules;
    }
  }

  if ($self->{conf}->{AUTH_GOOGLE_ID}) {
    $functions{social_auth}{google} = (($user->{_GOOGLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
  }
  if ($self->{conf}->{AUTH_FACEBOOK_ID}) {
    $functions{social_auth}{facebook} = (($user->{_FACEBOOK} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
  }
  if ($self->{conf}->{AUTH_APPLE_ID}) {
    $functions{social_auth}{apple} = (($user->{_APPLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
  }

  my $credit_info = $Service_control->user_set_credit({ UID => $path_params->{uid} });
  if (!exists($credit_info->{error}) && !exists($credit_info->{errno})) {
    $functions{user_credit} = '1001';
  }

  my %org_params = map { $_ => $self->{conf}{$_} } grep /^ORGANIZATION_/, keys %{$self->{conf}};
  while (my ($param, $value) = each %org_params) {
    next if (!$param || !$value);
    $functions{organization}{$param} = $value;
  }

  # TODO: deprecate in 1.40, remove in 1.50
  $functions{organization}{ORGANIZATION_APP_LINK_GOOGLE_PLAY} ||=
    $self->{conf}{APP_LINK_GOOGLE_PLAY} if ($self->{conf}{APP_LINK_GOOGLE_PLAY});
  $functions{organization}{ORGANIZATION_APP_LINK_APP_STORE} ||=
    $self->{conf}{APP_LINK_APP_STORE} if ($self->{conf}{APP_LINK_APP_STORE});

  if (in_array('Iptv', \@main::MODULES)) {
    my ($subscribe_id, $subscribe_name, $subscribe_describe) = split(/:/, $self->{conf}->{IPTV_SUBSCRIBE_ID} || q{});
    $functions{iptv_config}{subscribe}{id} = $subscribe_id || 'EMAIL';
    $functions{iptv_config}{subscribe}{name} = $subscribe_name || 'E-mail';
    $functions{iptv_config}{subscribe}{describe} = $subscribe_describe || '';

    require Iptv;
    Iptv->import();
    my $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
    $Iptv->iptv_promotion_tps();

    $functions{iptv_config}{promotion_tps} = 1 if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0);
  }

  if (in_array('Cards', \@main::MODULES)) {
    $functions{cards_user_payment}{serial} = ($self->{conf}->{CARDS_PIN_ONLY}) ? 0 : 1;
    delete $functions{cards_user_payment} if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user->{COMPANY_ID});
  }

  if ($functions{iptv_user_chg_tp}) {
    $functions{iptv}{next_month} = 1;
    my $list = $Service_control->available_tariffs({
      UID    => $path_params->{uid},
      MODULE => 'Internet'
    });

    if (ref $list ne 'ARRAY') {
      delete $functions{internet_user_chg_tp};
    }
    else {
      $functions{iptv}{next_month} = 1;
      $functions{iptv}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE} && !$self->{conf}->{IPTV_USER_CHG_TP_NPERIOD});
    }
  }

  $functions{system}{currency} = $self->{conf}->{SYSTEM_CURRENCY} if ($self->{conf}->{SYSTEM_CURRENCY});
  $functions{system}{password}{regex} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
  $functions{system}{password}{symbols} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});

  $functions{bots}{viber} = "viber://pa?chatURI=$self->{conf}->{VIBER_BOT_NAME}&text=/start&context=u_" if ($self->{conf}->{VIBER_TOKEN} && $self->{conf}->{VIBER_BOT_NAME});
  $functions{bots}{telegram} = "https://t.me/$self->{conf}->{TELEGRAM_BOT_NAME}?start=u_" if ($self->{conf}->{TELEGRAM_TOKEN} && $self->{conf}->{TELEGRAM_BOT_NAME});

  $functions{social_networks} = $self->{conf}->{SOCIAL_NETWORKS} if ($self->{conf}->{SOCIAL_NETWORKS});
  $functions{review_pages} = $self->{conf}->{REVIEW_PAGES} if ($self->{conf}->{REVIEW_PAGES});

  $functions{phone}{pattern} = $self->{conf}->{PHONE_NUMBER_PATTERN} if ($self->{conf}->{PHONE_NUMBER_PATTERN});

  if ($self->{conf}->{user_chg_passwd} || ($self->{conf}->{group_chg_passwd} && $self->{conf}->{group_chg_passwd} eq $user->{GID})) {
    $functions{user_chg_passwd} = 1;
  }

  if ($self->{conf}->{user_chg_pi}) {
    $functions{user_chg_pi} = 1;

    if ($self->{conf}->{CHECK_CHANGE_PI}) {
      $functions{user_chg_pi_allowed_params}{($_ || q{})} = 99 for (split ',\s?', ($self->{conf}->{CHECK_CHANGE_PI}));
    }
    else {
      $functions{user_chg_pi_allowed_params} = {
        fio        => 99,
        cell_phone => 99,
        email      => 99,
        phone      => 99,
      };

      if ($self->{conf}->{user_chg_info_fields}) {
        $functions{user_chg_info_fields_types} = [ 'String', 'Integer', 'List', 'Text', 'Flag' ];
        require Info_fields;
        Info_fields->import();

        my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
        my $info_fields = $Info_fields->fields_list({
          SQL_FIELD   => '_SHOW',
          TYPE        => '_SHOW',
          ABON_PORTAL => 1,
          USER_CHG    => 1,
          COLS_NAME   => 1,
        });

        foreach my $info_field (@{$info_fields}) {
          $functions{user_chg_pi_allowed_params}{uc($info_field->{sql_field})} = $info_field->{type};
        }
      }
    }
  }

  $functions{user_send_password} = 1 if ($self->{conf}->{USER_SEND_PASSWORD});
  if ($self->{conf}->{MONEY_UNIT_NAMES}) {
    my ($first, $second) = split(';', $self->{conf}->{MONEY_UNIT_NAMES});
    $functions{money_unit_names} = {
      major_unit => $first,
      minor_unit => $second
    }
  }

  return \%functions;
}

1;
