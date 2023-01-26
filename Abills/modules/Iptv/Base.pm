package Iptv::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Iptv $Iptv;

use Abills::Base qw/days_in_month in_array/;

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

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Iptv;
  Iptv->import();
  $Iptv = Iptv->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 iptv_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO

=cut
#**********************************************************
sub iptv_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user;
  $user = $attr->{USER_INFO} if ($attr->{USER_INFO});

  my $list = $Iptv->user_list({
    UID             => $user->{UID},
    SERVICE_STATUS  => '_SHOW',
    SERVICE_ID      => '_SHOW',
    TV_SERVICE_NAME => '_SHOW',
    COLS_NAME       => 1,
  });

  return 0 if ($Iptv->{TOTAL} < 1);

  my $form = $attr->{FORM} || {};

  ::load_module('Iptv', $html);

  my $users_disable = $main::users->{DISABLE};
  foreach my $service_user (@{$list}) {
    if ($form->{newpassword} && !in_array($service_user->{service_status}, [ 4, 5 ])) {
      $Iptv->{SERVICE_ID} = $service_user->{service_id};
      ::iptv_account_action({
        %{($Iptv && ref $Iptv eq 'HASH') ? $Iptv : {}},
        PASSWORD  => $form->{newpassword},
        change    => 1,
        USER_INFO => $user,
        SILENT    => 1
      });

      next;
    }

    next if defined $service_user->{service_status} && !in_array($service_user->{service_status}, [ 4, 5 ]);

    $Iptv->user_info($service_user->{id});

    next if !$Iptv->{TP_NUM};

    if ($form->{DISABLE} && !$users_disable) {
      $Iptv->{STATUS} = 1;
      ::iptv_account_action({
        %{($Iptv && ref $Iptv eq 'HASH') ? $Iptv : {}},
        change    => 1,
        USER_INFO => $user,
        STATUS    => 1,
        SILENT    => 1
      });
    }
    elsif (!$form->{DISABLE}) {
      #Fixme: call iptv_account_action when activate user
      ::iptv_user_activate($Iptv, {
        USER       => $user,
        SILENT     => 1,
        REACTIVATE => $users_disable ? 1 : 0,
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 promotional_tp($attr)

  Arguments:
    $attr
      USER

=cut
#**********************************************************
sub iptv_promotional_tp {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $attr->{USER};
  return if !$user_info || !$user_info->{UID} || $user_info->{DISABLE};

  $Iptv->user_list({ UID => $user_info->{UID}, COLS_NAME => 1 });
  return 0 if $Iptv->{TOTAL} > 0;

  my $promotion_tps = $Iptv->iptv_promotion_tps();
  my $items = '';

  foreach my $tp (@{$promotion_tps}) {
    next if !$tp->{tp_id} || !$tp->{service_id};

    my $price = $tp->{month_fee} || $tp->{day_fee} || 0;
    next if ($user_info->{DEPOSIT} + $user_info->{CREDIT} < $price * (100 - $user_info->{REDUCTION}) / 100);

    $items .= $html->tpl_show(::_include('iptv_promotion_tp_carousel_item', 'Iptv'), {
      TP_NAME => $tp->{name},
      ACTIVE  => !$items ? 'active' : '',
      PRICE   => $price,
      PERIOD  => $tp->{month_fee} ? "/$lang->{MONTH}" : $tp->{day_fee} ? "/$lang->{DAY}" : '',
      HREF    => '?index=' . main::get_function_index('iptv_user_info') . "&add_form=1&add=1&TP_ID=$tp->{tp_id}&SERVICE_ID=$tp->{service_id}",
    }, { OUTPUT2RETURN => 1 });
  }

  return if !$items;

  $html->message('callout', $html->tpl_show(main::_include('iptv_promotion_tp_carousel', 'Iptv'),
    { ITEMS => $items }, { OUTPUT2RETURN => 1 }), '', { class => 'info mb-0 p-0' });
}

#**********************************************************
=head iptv_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID
      LOGIN

=cut
#**********************************************************
sub iptv_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};

  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Iptv->user_list({
      UID         => $uid,
      TP_NAME     => '_SHOW',
      MONTH_FEE   => '_SHOW',
      DAY_FEE     => '_SHOW',
      CID         => '_SHOW',
      TP_COMMENTS => '_SHOW',
      STATUS      => '_SHOW',
      IP          => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });

    $result = $list->[0];
    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $result->{STATUS} = (defined($result->{SERVICE_STATUS})) ? $service_status->{ $result->{SERVICE_STATUS} } : '';
    ($result->{STATUS}, undef) = split(/:/, $result->{STATUS});
    $result->{PERIOD} = $lang->{MONTH};
    
    if (!$result->{MONTH_FEE} && $result->{DAY_FEE}) {
      $result->{MONTH_FEE} = $result->{DAY_FEE};
      $result->{PERIOD} = $lang->{DAY};
    }
    
    return $result;
  }
  elsif ($attr->{GET_PARAMS}) {
    $result = {
      HEADER    => $lang->{TV},
      QUICK_TPL => 'iptv_qi_box',
      FIELDS    => {
        TP_NAME     => $lang->{TARIF_PLAN},
        IP          => 'IP',
        STATUS      => $lang->{STATUS},
        MONTH_FEE   => $lang->{MONTH_FEE},
        TP_COMMENTS => $lang->{COMMENTS},
        PERIOD      => $lang->{MONTH}
      }
    };

    return $result;
  }

  $Iptv->user_list({
    UID         => $uid,
    LOGIN       => (! $uid && $attr->{LOGIN}) ? $attr->{LOGIN} : undef,
    TP_NAME     => '_SHOW',
    COLS_NAME   => 1,
    COLS_UPPER  => 1
  });

  return ($Iptv->{TOTAL} > 0) ? $Iptv->{TOTAL} : '';
}

#**********************************************************
=head2 iptv_docs($attr) - get services for invoice

  Arguments:
    UID
  Results:

=cut
#**********************************************************
sub iptv_docs {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID};
  my @services = ();
  my %info = ();

  my $list = $Iptv->user_list({
    UID               => $uid,
    ACCOUNT_DISABLE   => 0,
    IPTV_ACTIVATE     => '_SHOW',
    IPTV_EXPIRE       => '_SHOW',
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    TP_ID             => '_SHOW',
    TP_NAME           => '_SHOW',
    FEES_METHOD       => '_SHOW',
    SERVICE_STATUS    => '_SHOW',
    TP_REDUCTION_FEE  => '_SHOW',
    SERVICE_STATUS    => $CONF->{IPTV_SHOW_ALL_SERVICES} ? '_SHOW' : '0',
    COLS_NAME         => 1,
    ABON_DISTRIBUTION => '_SHOW'
  });

  foreach my $service_info (@{$list}) {
    next if (!defined($service_info->{month_fee}));

    my $monthly_fee_info = $self->_iptv_docs_monthly_fee($service_info, $attr);
    push @services, $monthly_fee_info if $monthly_fee_info;

    my $daily_fee_info = $self->_iptv_docs_daily_fee($service_info, $attr);

    push @services, $daily_fee_info if $daily_fee_info;
  }

  #Channels
  my %services_info = (UID => $uid);
  $self->iptv_channels_fees(\%services_info);

  if ($services_info{USERS_SERVICES} && $uid) {
    foreach my $service (@{$services_info{USERS_SERVICES}->{ $uid }}) {
      $info{service_name} = $service->{DESCRIBE};
      $info{service_desc} = q{};
      $info{tp_name} = $service->{DESCRIBE};
      $info{month} = $service->{SUM};

      push @services, $attr->{FULL_INFO} ? { %info } : "Tv: $service->{DESCRIBE}||$service->{SUM}||$service->{DESCRIBE}";
    }
  }

  %services_info = (UID => $uid);
  $self->iptv_screen_fees(\%services_info);

  if ($services_info{USERS_SERVICES} && $uid) {
    foreach my $service (@{$services_info{USERS_SERVICES}->{ $uid }}) {
      $info{service_name} = $service->{DESCRIBE};
      $info{service_desc} = q{};
      $info{tp_name} = $service->{DESCRIBE};
      $info{month} = $service->{SUM};

      push @services, $attr->{FULL_INFO} ? { %info } : "Tv: $service->{DESCRIBE}||$service->{SUM}||$service->{DESCRIBE}";
    }
  }

  return \%info if ($attr->{FEES_INFO});

  return \@services;
}

#**********************************************************
=head2 _iptv_docs_monthly_fee($attr)

=cut
#**********************************************************
sub _iptv_docs_monthly_fee {
  my $self = shift;
  my ($service_info, $attr) = @_;

  return if $service_info->{month_fee} <= 0 && !$CONF->{IPTV_SHOW_FREE_TPS};

  my %info = ();
  my %FEES_DSC = (
    MODULE          => "Iptv",
    SERVICE_NAME    => $lang->{TV},
    TP_ID           => $service_info->{tp_id},
    TP_NAME         => $service_info->{tp_name},
    FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
  );

  $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
  $info{service_desc} = q{};
  $info{tp_name} = $service_info->{tp_name};
  $info{service_activate} = $service_info->{iptv_activate};
  $info{service_expire} = $service_info->{iptv_expire};
  $info{tp_fixed_fees_day} = $service_info->{tp_fixed_fees_day} || 0;
  $info{status} = $service_info->{iptv_status} || $service_info->{service_status};
  $info{day} = $service_info->{day_fee};
  $info{month} = $service_info->{month_fee};
  $info{abon_distribution} = $service_info->{abon_distribution};
  $info{tp_reduction_fee} = $service_info->{tp_reduction_fee};
  $info{module_name} = $lang->{TV};

  if ($service_info->{iptv_status} && $service_info->{iptv_status} != 5 && $attr->{SKIP_DISABLED}) {
    $info{day} = 0;
    $info{month} = 0;
    $info{abon_distribution} = 0;
  }

  return { %info } if $attr->{FULL_INFO};
  return ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{month_fee}||$service_info->{tp_name}";
}

#**********************************************************
=head2 _iptv_docs_month_fee($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_docs_daily_fee {
  my $self = shift;
  my ($service_info, $attr) = @_;

  return if !$service_info->{day_fee} || $service_info->{day_fee} <= 0;

  my %info = ();
  my %FEES_DSC = (
    MODULE          => "Iptv",
    SERVICE_NAME    => $lang->{TV},
    TP_ID           => $service_info->{tp_id},
    TP_NAME         => $service_info->{tp_name},
    FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
  );

  $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
  $info{service_desc} = q{};
  $info{tp_name} = $service_info->{tp_name};
  $info{service_activate} = $service_info->{iptv_activate};
  $info{service_expire} = $service_info->{iptv_expire};
  $info{status} = $service_info->{iptv_status} || $service_info->{service_status};
  $info{day} = $service_info->{day_fee};
  $info{abon_distribution} = $service_info->{abon_distribution};
  $info{tp_reduction_fee} = $service_info->{tp_reduction_fee};
  $info{module_name} = $lang->{TV};

  if ($service_info->{iptv_status} && $service_info->{iptv_status} != 5 && $attr->{SKIP_DISABLED}) {
    $info{day} = 0;
    $info{month} = 0;
    $info{abon_distribution} = 0;
  }

  return { %info } if $attr->{FULL_INFO};
  return ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{day_fee}||$service_info->{tp_name}";
}

#**********************************************************
=head2 iptv_channels_fees($attr)

  Arguments:
    $attr
      USERS_SERVICES - Services hash_ref
      ID             -
      TP             - Tp info
      TP_ID          -
      SKIP_MONTH_PRICE
      DATE
      DEBUG
      UID

  Results:
    DEBUG output

=cut
#**********************************************************
sub iptv_channels_fees {
  my $self = shift;
  my ($attr) = @_;

  my $debug = $attr->{DEBUG};
  my $tp = $attr->{TP};
  my $days_in_month = days_in_month();
  my $debug_output = '';

  #Channels Fees
  my $ulist = $Iptv->user_list({
    LOGIN            => '_SHOW',
    ID               => $attr->{ID} || '_SHOW',
    LOGIN_STATUS     => 0,
    TP_ID            => $tp->{tp_id} || $attr->{TP_ID},
    SORT             => 1,
    TP_REDUCTION_FEE => '_SHOW',
    SHOW_CHANNELS    => 1,
    MONTH_PRICE      => ($attr->{SKIP_MONTH_PRICE}) ? undef : '>0',
    COLS_NAME        => 1,
    REDUCTION        => '_SHOW',
    %{$attr}
  });

  foreach my $u (@{$ulist}) {
    next if (!$u->{uid});

    $u->{reduction} = $u->{tp_reduction_fee} ? $u->{reduction} ? $u->{reduction} : 0 : 0;
    my $channel_num = $u->{channel_id};
    my $sum = $u->{month_price};

    $sum = ($u->{reduction} && $u->{reduction} > 0) ? $sum * (100 - $u->{reduction}) / 100 : $sum;
    $sum = $sum = sprintf("%.6f", $sum / $days_in_month) if ($tp->{abon_distribution});

    $debug_output .= " Login: $u->{login} ($u->{uid}) TP_ID: $u->{tp_id} Channel: $channel_num Month Price: " .
      "$sum REDUCTION: $u->{reduction}\n" if ($debug && $debug > 3);

    my %FEES_DSC = (
      MODULE            => "Iptv",
      SERVICE_NAME      => $lang->{TV},
      TP_ID             => $tp->{id} || $attr->{TP_NUM} || $channel_num,
      TP_NAME           => "$lang->{CHANNELS}:$channel_num $u->{channel_name}",
      FEES_PERIOD_MONTH => $lang->{MONTH_FEE_SHORT},
      FEES_METHOD       => ($tp->{fees_method}) ? $main::FEES_METHODS{ $tp->{fees_method} } : 2
    );

    push @{$attr->{USERS_SERVICES}->{ $u->{uid} }}, {
      SUM       => $sum,
      DESCRIBE  => ::fees_dsc_former(\%FEES_DSC),
      FILTER_ID => $u->{channel_filter},
      ID        => $channel_num,
    };
  }

  return $debug_output;
}

#**********************************************************
=head2 iptv_screen_fees($attr)

  Arguments:
    $attr
      USERS_SERVICES - Services hash_ref
      TP             - Tp info
      TP_NUM         -
      DATE
      DEBUG

  Results:
    DEBUG output

=cut
#**********************************************************
sub iptv_screen_fees {
  my $self = shift;
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $tp = $attr->{TP};

  #Screen Fees
  my $ulist = $Iptv->users_screens_list({
    LOGIN            => '_SHOW',
    LOGIN_STATUS     => 0,
    SERVICE_TP_ID    => $tp->{tp_id} || $attr->{TP_ID},
    MONTH_FEE        => '>0',
    NUM              => '_SHOW',
    NAME             => '_SHOW',
    FILTER_ID        => '_SHOW',
    REDUCTION        => '_SHOW',
    TP_REDUCTION_FEE => '_SHOW',
    COLS_NAME        => 1,
    %{$attr},
    SORT             => 's.num'
  });

  my $debug_output = '';
  foreach my $u (@{$ulist}) {
    next if (!$u->{uid});

    $u->{reduction} = $u->{tp_reduction_fee} ? $u->{reduction} ? $u->{reduction} : 0 : 0;
    my $sum = $u->{month_fee};
    $sum = ($u->{reduction} && $u->{reduction} > 0) ? $sum * (100 - $u->{reduction}) / 100 : $sum;

    $u->{login} ||= "";
    $debug_output .= " Login: $u->{login} ($u->{uid})  TP_ID: $u->{tp_id} Screen: $u->{num} $u->{name} " .
      "Month Price: $sum REDUCTION: $u->{reduction}\n" if ($debug > 3);

    my %FEES_DSC = (
      MODULE            => "Iptv",
      SERVICE_NAME      => $lang->{TV},
      TP_ID             => $tp->{id} || $attr->{TP_NUM},
      TP_NAME           => "$lang->{SCREENS}:$u->{num} $u->{name}",
      FEES_PERIOD_MONTH => $lang->{MONTH_FEE_SHORT},
      FEES_METHOD       => ($tp->{fees_method}) ? $main::FEES_METHODS{ $tp->{fees_method} } : 2
    );

    push @{$attr->{USERS_SERVICES}->{ $u->{uid} }}, {
      SUM       => $sum,
      DESCRIBE  => ::fees_dsc_former(\%FEES_DSC) . '/' . $u->{uid},
      SCREEN_ID => $u->{num},
      FILTER_ID => $u->{filter_id}
    };
  }

  return $debug_output;
}

1;