package Abon::Services;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my %lang;
my $html;
my $DATE;
my Abon $Abon;
my $Fees;
my $Abon_base;

use POSIX qw(strftime mktime);
use Abills::Base qw/days_in_month date_diff get_period_dates cmd sendmail/;
use Abills::Loader;
use Users;

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

  %lang = %{$attr->{LANG}} if ($attr->{LANG});
  $html = $attr->{HTML} if ($attr->{HTML});

  my $self = {};

  require Abon;
  Abon->import();
  $Abon = Abon->new($db, $admin, $CONF);

  require Abon::Base;
  $Abon_base = Abon::Base->new($db, $admin, $CONF, { HTML => $html, LANG => \%lang });

  use Fees;
  $Fees = Fees->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 abon_user_tariff_activate($attr)

  Arguments:
    $attr
      ID
      USER_INFO
        UID
      DEBUG
      DATE
      SERVICE_RECOVERY

  Returns:
    $service_inf_hash_ref

=cut
#**********************************************************
sub abon_user_tariff_activate {
  my ($self, $attr) = @_;

  my $user_info = $attr->{USER_INFO};
  if (!$user_info && $attr->{UID}) {
    my $Users = Users->new($db, $admin, $CONF);
    $Users->info($attr->{UID});
    $Users->pi({ UID => $attr->{UID} });
    $user_info = $Users;
  }

  $user_info->{UID} ||= $attr->{UID};
  #my $debug = $attr->{DEBUG} || 0;
  my @messages = ();

  return { errno => 20001, errstr => 'ERR_ACTIVATE_UID' } if !$user_info->{UID};
  return { errno => 20002, errstr => 'ERR_TARIFF_ID' } if !$attr->{ID};

  return { errno => 240, errstr => 'ERR_SMALL_DEPOSIT' } if (!defined $user_info->{DEPOSIT});

  my $user_tariffs = $Abon->user_tariff_list($user_info->{UID},
    { GID => $user_info->{GID} || 0, ID => $attr->{ID}, COLS_NAME => 1 }
  );

  return { errno => 20003, errstr => 'ERR_USER_TARIFF_INFO' } if !$Abon->{TOTAL} || $Abon->{TOTAL} < 1;

  my $user_tariff = $user_tariffs->[0];
  if ($user_tariff->{date} && ! $attr->{ACTIVATE}) {
    return { errno => 20004, errstr => 'ERR_TARIFF_ALREADY_ACTIVATED' };
  }

  my $tariff_info = $Abon->tariff_info($user_tariff->{id});
  return { errno => 20005, errstr => 'ERR_TARIFF_INFO' } if !$Abon->{TOTAL} || $Abon->{TOTAL} < 1;

  if ($tariff_info->{PROMO_PERIOD} && !$tariff_info->{PERIOD}) {
    $attr->{DATE} = strftime('%Y-%m-%d', localtime(time + int($tariff_info->{PROMO_PERIOD}) * 86400));
  }

  my $select_time = 0;
  if ($attr->{DATE} && $attr->{DATE} ne '0000-00-00') {
    my ($Y, $M, $D) = split('-', $attr->{DATE}, 3);
    $select_time = mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));
  }

  $attr->{TP_ID} = $tariff_info->{ID};
  $Abon->{TP_INFO}{TP_ID} = $tariff_info->{ID};
  $Abon->{TP_INFO}{DISCOUNT} = $tariff_info->{DISCOUNT};
  $Abon->{TP_INFO}{PRICE} = $tariff_info->{PRICE};
  $Abon->{TP_INFO}{EXT_BILL_ACCOUNT} = $tariff_info->{EXT_BILL_ACCOUNT};
  $Abon->{TP_INFO}{ACTIVATE_PRICE} = $tariff_info->{ACTIVATE_PRICE};

  if ($attr->{ACTIVATE}) {
    my $ai_list = $Abon->periodic_list({
      UID        => $user_info->{UID},
      DELETED    => 0,
      TP_ID      => $tariff_info->{id},
      COLS_NAME  => 1,
      COLS_UPPER => 1
    });

    if ($Abon->{TOTAL} && $Abon->{TOTAL} > 0) {
      $Abon->{COMMENTS} = $ai_list->[0]->{COMMENTS};
      $Abon->{NEXT_ABON_DATE} = $ai_list->[0]->{NEXT_ABON_DATE};
      $Abon->{SERVICE_COUNT} = $ai_list->[0]->{SERVICE_COUNT};
    }
  }

  if ($Abon->{SERVICE_COUNT} && $Abon->{SERVICE_COUNT} > 1) {
    $Abon->{TP_INFO}{PRICE} = $Abon->{TP_INFO}{PRICE} * $Abon->{SERVICE_COUNT};
  }

  my $user_deposit = $user_info->{CREDIT} + $user_info->{DEPOSIT};

  if (!$attr->{SKIP_FEE} && !$tariff_info->{PAYMENT_TYPE} && $user_deposit < $Abon->{TP_INFO}{PRICE} && time() >= $select_time) {
    return { errno => 240, errstr => 'ERR_SMALL_DEPOSIT' };
  }

  my $period = $tariff_info->{PERIOD} == 1 ? get_period_dates({
    TYPE             => $tariff_info->{PERIOD},
    PERIOD_ALIGNMENT => $Abon->{TP_INFO}{PERIOD_ALIGNMENT},
    ACCOUNT_ACTIVATE => $user_info->{ACTIVATE}
  }) : '';

  my $cur_date = strftime('%Y-%m-%d', localtime(time));
  $Abon->{TP_INFO}{PERIOD_ALIGNMENT} = $tariff_info->{PERIOD_ALIGNMENT} || 0;
  $Abon->{TP_INFO}{TP_NAME} = $tariff_info->{NAME};
  $Abon->{COMMENTS} = $attr->{COMMENTS};
  $Abon->{TP_INFO}{FEES_TYPE} = $tariff_info->{FEES_TYPE} || 1;
  $Abon->{TP_INFO}{CREATE_ACCOUNT} = $tariff_info->{CREATE_ACCOUNT};
  $Abon->{PLUGIN} = $tariff_info->{PLUGIN};
  my $ext_cmd = $tariff_info->{EXT_CMD};
  my $activate_notification = $tariff_info->{ACTIVATE_NOTIFICATION};
  $Abon->{NEXT_ABON_DATE} = $tariff_info->{NEXT_ABON_DATE};
  $Abon->{SERVICE_COUNT} = $attr->{SERVICE_COUNT} || 1;
  $Abon->{DATE} = $cur_date;
  $Abon->{DATETIME} = "$cur_date " . strftime('%H:%M:%S', localtime(time));
  $Abon->{PERSONAL_DESCRIPTION} = $tariff_info->{PERSONAL_DESCRIPTION} || q{};

  my $active_period = date_diff($cur_date, $attr->{DATE});

  $attr->{ACTIVATE} = $attr->{DATE};

  if ($attr->{DATE} && $attr->{DATE} ne '0000-00-00' && $active_period > -30) {
    #print "simle form: $tariff_info->{PERIOD_ALIGNMENT} /DATE: $attr->{DATE} ";
    if (! $tariff_info->{PERIOD_ALIGNMENT}) {
      $attr->{PERIOD} = $tariff_info->{PERIOD};
      return $Abon->user_tariff_add($attr);
    }
  }

  if ($tariff_info->{PLUGIN}) {
    $Abon->{EXT_SERVICE_ID} = $tariff_info->{EXT_SERVICE_ID};
    $attr->{EXT_SERVICE_ID} = $tariff_info->{EXT_SERVICE_ID};

    my $plugin = load_plugin('Abon::Plugins::'.$tariff_info->{PLUGIN}, {
      SERVICE      => $tariff_info,
      HTML         => $html,
      LANG         => \%lang,
      RETURN_ERROR => 1
    });

    return { errno => $plugin->{errno}, errstr => $plugin->{errstr} } if ($plugin && $plugin->{errno});

    if ($attr->{ACTIVATE_ONLY} && !$attr->{ACCEPT_LICENSE}) {
      if ($plugin->can('license')) {
        my $license = $plugin->license({ %{$attr}, USER_INFO => $user_info });

        return { LICENSE => $license };
      }
    }

    if ($plugin->can('activate')) {
      $plugin->activate({ %{$attr}, USER_INFO => $user_info });
      return { errno => $plugin->{errno}, errstr => $plugin->{errstr} } if $plugin->{errno};

      if ($plugin->{INFO}) {
        $Abon->{PERSONAL_DESCRIPTION} = $plugin->{INFO} || q{};
        $attr->{PERSONAL_DESCRIPTION} = $Abon->{PERSONAL_DESCRIPTION};

        if ($plugin->{FEES_PERIOD}) {
          $Abon->{FEES_PERIOD} = $plugin->{FEES_PERIOD} || $Abon->{FEES_PERIOD};
          $attr->{FEES_PERIOD} = $Abon->{FEES_PERIOD};
        }
      }
    }
  }

  delete $self->{OPERATION_SUM};
  delete $self->{OPERATION_DESCRIBE};

  if (time() >= $select_time) {
    if ($tariff_info->{PERIOD} == 1 && $Abon->{TP_INFO}{PERIOD_ALIGNMENT} == 1) {
      $Abon->{ACTIVATE} = $user_info->{ACTIVATE};
      my $fee_result = $self->abon_get_month_fee($Abon, {
        %$attr,
        DATE      => $attr->{DATE} || $cur_date,
        USER_INFO => $user_info,
        DISCOUNT  => $attr->{DISCOUNT}
      });

      return $fee_result if ($fee_result->{errno});

      if ($fee_result->{MESSAGES} && ref $fee_result->{MESSAGES} eq 'ARRAY') {
        map push(@messages, $_), @{$fee_result->{MESSAGES}};
      }

      #$attr->{ACTIVATE} = $attr->{DATE};
      if ($active_period < -30) {
        delete $attr->{DATE};
      }
    }
    elsif (!$attr->{DISCOUNT} || $attr->{DISCOUNT} < 100) {
      my $fee_result = $self->abon_get_month_fee($Abon, {
        %$attr,
        DATE      => $cur_date,
        USER_INFO => $user_info,
        DISCOUNT  => $attr->{DISCOUNT}
      });
      return $fee_result if ($fee_result->{errno});

      if ($fee_result->{MESSAGES} && ref $fee_result->{MESSAGES} eq 'ARRAY') {
        map push(@messages, $_), @{$fee_result->{MESSAGES}};
      }
    }
  }

  if ($activate_notification && $user_info->{EMAIL} && $html) {
    my $email_message = $html->tpl_show(main::_include('abon_notification3', 'Abon'), {
      OPERATION_SUM => $self->{OPERATION_SUM},
      PERIOD        => $period,
      %{$user_info},
      %{$Abon->{TP_INFO}},
      %{$Abon}
    }, { OUTPUT2RETURN => 1 });

    sendmail($CONF->{ADMIN_MAIL}, $user_info->{EMAIL}, "$CONF->{WEB_TITLE} - $Abon->{TP_INFO}{TP_NAME} "
      . ($Abon->{COMMENTS} || q{}), $email_message, $CONF->{MAIL_CHARSET}, '', {});
  }

  #Don't add service if end date expire
  if ($attr->{END_DATE} && date_diff($cur_date, $attr->{END_DATE}) > 0) {
  }
  else {
    if ($attr->{END_DATE} && date_diff($cur_date, $attr->{END_DATE}) < 30) {
      $attr->{DATE} = $attr->{END_DATE};
    }
    $Abon->user_tariff_add($attr);
  }

  if ($ext_cmd) {
    my $cmd = $ext_cmd;
    $cmd .= " ACTION=ACTIVE UID=$user_info->{UID} TP_ID=$Abon->{TP_INFO}{TP_ID} COMMENTS=\""
      . ($Abon->{COMMENTS} || q{}) . "\" SUM=" . sprintf("%.2f", $Abon->{TP_INFO}{PRICE});
    cmd($cmd);
  }
  return $Abon if ($Abon->{errno});

  $Abon->{COMMENTS} ||= '';

  return {
    %{$Abon},
    MESSAGES    => \@messages,
    CREATE_DOCS => $Abon->{TP_INFO}{CREATE_ACCOUNT} && $attr->{CREATE_DOCS},
    DOCS_SUM    => $self->{OPERATION_SUM} ? $self->{OPERATION_SUM} : $Abon->{TP_INFO}{PRICE} ? ($Abon->{TP_INFO}{PRICE} / $Abon->{SERVICE_COUNT}) : 0,
    DOCS_ORDER  => $self->{OPERATION_DESCRIBE} ? $self->{OPERATION_DESCRIBE} : "[$Abon->{TP_INFO}{TP_ID}] $Abon->{TP_INFO}{TP_NAME} $Abon->{COMMENTS}",
  };
}

#**********************************************************
=head2 abon_user_tariff_deactivate($attr)

  Arguments:
    $attr
      ID
      USER_INFO
        UID

=cut
#**********************************************************
sub abon_user_tariff_deactivate {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};
  if (!$user_info && $attr->{UID}) {
    my $Users = Users->new($db, $admin, $CONF);
    $Users->info($attr->{UID});
    $Users->pi({ UID => $attr->{UID} });
    $user_info = $Users;
  }

  $user_info->{UID} ||= $attr->{UID};

  return { errno => 20001, errstr => 'ERR_ACTIVATE_UID' } if (!$user_info->{UID});
  return { errno => 20002, errstr => 'ERR_TARIFF_ID' } if (!$attr->{ID});

  my $user_tariffs = $Abon->user_tariff_list($user_info->{UID}, { ID => $attr->{ID}, COLS_NAME => 1 });
  return { errno => 20006, errstr => 'ERR_TARIFF_ALREADY_DEACTIVATED' } if (!$Abon->{TOTAL} || $Abon->{TOTAL} < 1);

  my $user_tariff = $user_tariffs->[0];
  return { errno => 20006, errstr => 'ERR_TARIFF_ALREADY_DEACTIVATED' } if (!$user_tariff->{active_service});

  my $tariff_info = $Abon->tariff_info($user_tariff->{id});
  return { errno => 20005, errstr => 'ERR_TARIFF_INFO' } if (!$Abon->{TOTAL} || $Abon->{TOTAL} < 1);

  my $ext_cmd = $tariff_info->{EXT_CMD};
  if ($ext_cmd) {
    my $cmd = $ext_cmd;
    $cmd .= " ACTION=ALERT UID=$user_info->{UID} TP_ID=$tariff_info->{ID}";
    cmd($cmd);
  }

  if ($tariff_info->{PLUGIN}) {
    $Abon->{PLUGIN} = $tariff_info->{PLUGIN};
    $Abon->{TP_ID}  = $tariff_info->{ID};

    $Abon->{PERSONAL_DESCRIPTION} = $user_tariff->{personal_description} || 'NO_PERSONAL_DESCRIPTION';

    my $plugin = load_plugin('Abon::Plugins::'.$tariff_info->{PLUGIN}, {
      SERVICE      => $tariff_info,
      HTML         => $html,
      LANG         => \%lang,
      RETURN_ERROR => 1
    });

    return { errno => $plugin->{errno}, errstr => $plugin->{errstr} } if ($plugin && $plugin->{errno});

    if ($plugin->can('deactivate')) {
      $plugin->deactivate({ %{$attr}, USER_INFO => $user_info, PERSONAL_DESCRIPTION => $Abon->{PERSONAL_DESCRIPTION} });
      return { errno => $plugin->{errno}, errstr => $plugin->{errstr} } if $plugin->{errno};

      if ($plugin->{INFO}) {
        $Abon->{PERSONAL_DESCRIPTION} = $plugin->{INFO} || q{};
        $attr->{PERSONAL_DESCRIPTION} = $Abon->{PERSONAL_DESCRIPTION};
      }
    }
  }

  $Abon->user_tariff_del({ UID => $user_info->{UID}, TP_ID => $attr->{ID} });
  return $Abon;
}

#**********************************************************
=head2 abon_service_activate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
        UID
        ID
      DEBUG
      DATE
      SERVICE_RECOVERY

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub abon_service_activate {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};
  my $debug = $attr->{DEBUG} || 0;
  my $date = $attr->{DATE} || $DATE;

  my $user_tariff_list = $Abon->user_tariff_list($user_info->{UID}, {
    PERIOD_ALIGNMENT => '_SHOW',
    COLS_NAME        => 1,
    SERVICE_RECOVERY => (defined($attr->{SERVICE_RECOVERY})) ? $attr->{SERVICE_RECOVERY} : '_SHOW',
  });

  foreach my $service (@$user_tariff_list) {
    if (!$service->{date}) { # || ! $user->{period}) { #day activate too
      next;
    }
    elsif ($service->{next_abon} && date_diff($service->{next_abon}, $date) < 0) {
      next;
    }

    $service->{TP_INFO}->{PERIOD_ALIGNMENT} = $service->{period_alignment} || 0;
    $service->{TP_INFO}->{TP_ID} = $service->{id};
    $service->{TP_INFO}->{TP_NAME} = $service->{tp_name};
    $service->{TP_INFO}->{PRICE} = $service->{price};
    $service->{UID} = $user_info->{UID};
    $service->{BILL_ID} = $user_info->{BILL_ID};
    $service->{ACTIVATE} = ($service->{service_recovery} && $service->{service_recovery} == 1) ? q{0000-00-00} : $service->{next_abon}; #Last abon fee

    my $message = $self->abon_get_month_fee($service, {
      SHOW_SUM  => $debug,
      USER_INFO => $user_info,
      DATE      => $date
    });

    $Abon->user_tariff_activate({ UID => $service->{UID}, ABON_DATE => $date, TP_ID => $service->{TP_INFO}{TP_ID} });

    print $message if ($debug > 1);
  }

  return 1;
}

#**********************************************************
=head2 abon_service_deactivate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
      DEBUG
      STATUS - Disable status

=cut
#**********************************************************
sub abon_service_deactivate {
  my $self = shift;
  my ($attr) = @_;

  my $debug_output = q{};
  my $user_info = $attr->{USER_INFO};
  #my $debug = $attr->{DEBUG} || 0;
  my $date = $attr->{DATE} || $DATE;
  my (undef, undef, $d) = split('-', $date);
  my $user_tariff_list = $Abon->user_tariff_list($user_info->{UID}, {
    SERVICE_RECOVERY => '_SHOW',
    COLS_NAME        => 1
  });

  foreach my $user (@$user_tariff_list) {
    next if (!$user->{date} || !$user->{period});

    my $days_in_month = days_in_month({ DATE => $date });
    my $days = $days_in_month - $d + 1;

    my $sum = $user->{price} / $days_in_month * $days;
    if ($sum > 0) {
      require Payments;
      my $Payments = Payments->new($db, $admin, $CONF);
      $Payments->add({ BILL_ID => $user_info->{BILL_ID}, UID => $user_info->{UID} }, {
        SUM            => $sum,
        METHOD         => 6,
        DESCRIBE       => "$lang{COMPENSATION}. $lang{DAYS}:" .
          "$date/$user->{next_abon} ($days)" . (($attr->{DESCRIBE}) ? ". $attr->{DESCRIBE}" : ''),
        INNER_DESCRIBE => $attr->{INNER_DESCRIBE}
      });
    }
  }

  return $debug_output;
}

#**********************************************************
=head2 abon_get_month_fee($Abon, $attr)

  Arguments:
    $Abon
    $attr
       SHOW_SUM
       USER_INFO
       DATE
       SERVICE_ACTIVATE
       END_DATE

  Results:
    { MESSAGE => $message }

=cut
#**********************************************************
sub abon_get_month_fee {
  my $self = shift;
  my Abon $Service = shift;
  my ($attr) = @_;

  my $TIME = "00:00:00";

  my @messages = ();
  my $users = $attr->{USER_INFO};
  my $user = $users->info($Service->{UID});
  my $DATE_ = strftime('%Y-%m-%d', localtime(time));
  #my $cur_date = $attr->{DATE} || $DATE_;
  my $cur_date = $attr->{END_DATE} || $DATE_;
  my $discount = $attr->{DISCOUNT} || 0;

  if ($attr->{SERVICE_ACTIVATE} && $attr->{SERVICE_ACTIVATE} ne '0000-00-00') {
    $Service->{ACTIVATE}=$attr->{SERVICE_ACTIVATE};
  }
  else {
    $Service->{ACTIVATE} = $DATE_;
  }

  my %FEES_DSC = (
    MODULE            => 'Abon',
    TEMPLATE_KEY_NAME => 'ABON_FEES_DSC',
    TEMPLATE          => $CONF->{ABON_FEES_DSC},
    SERVICE_NAME      => $lang{EXT_SERVICES},
    TP_ID             => $Service->{TP_INFO}{TP_ID},
    TP_NAME           => $Service->{TP_INFO}{TP_NAME},
    EXTRA             => '',
  );

  #Get active price
  if ($Service->{TP_INFO}{ACTIVATE_PRICE} && $Service->{TP_INFO}{ACTIVATE_PRICE} > 0) {
    $Fees->take($user, $Service->{TP_INFO}{ACTIVATE_PRICE}, {
      DESCRIBE => 'ACTIVATE_TARIF_PLAN',
      DATE     => "$cur_date $TIME"
    });

    push @messages, abon_fees_dsc_former({ %FEES_DSC, EXTRA => "$lang{ACTIVATE_TARIF_PLAN}: $Service->{TP_INFO}{ACTIVATE_PRICE}" })
  }

  # If zero price, should do nothing
  if (!$Service->{TP_INFO}{PRICE} || $Service->{TP_INFO}{PRICE} <= 0) {
    return { MESSAGES => \@messages };
  }

  #Get month fee
  my $sum = $Service->{TP_INFO}{PRICE};

  if ($Service->{TP_INFO}{EXT_BILL_ACCOUNT}) {
    $user->{BILL_ID} = $user->{EXT_BILL_ID};
    $user->{DEPOSIT} = $user->{EXT_DEPOSIT};
  }

  #Current Month
  my ($y, $m, $d) = split('-', $cur_date, 3);
  my ($active_y, $active_m, $active_d) = split('-', $Service->{ACTIVATE} || '0000-00-00', 3);

  if (date_diff($cur_date, $Service->{ACTIVATE} || '0000-00-00') > 0) {
    return { MESSAGES => \@messages };
  }

  return { MESSAGES => \@messages } if ($sum == 0);

  my $periods = 0;
  if (int($active_m) > 0 && int($active_m) < int($m) && int($active_y) < ($y)) {
    $periods = $m - $active_m;
    if (int($active_d) > int($d)) {
      $periods--;
    }

    if ($y - $active_y) {
      $periods += 12 * ($y - $active_y) - 12;
    }
  }
  elsif (int($active_m) > 0 && (int($active_m) >= int($m) && int($active_y) < int($y))) {
    $periods = 12 - $active_m + $m;
    if (int($active_d) > int($d)) {
      $periods--;
    }

    if ($y - $active_y) {
      $periods += 12 * ($y - $active_y) - 12;
    }
  }
  #Cur year
  elsif ((int($active_m) < int($m) && int($active_y) == int($y))) {
    $periods = (int($m) - int($active_m));
  }

  $CONF->{START_PERIOD_DAY} = 1 if (!$CONF->{START_PERIOD_DAY});

  for (my $i = 0; $i <= $periods; $i++) {
    $FEES_DSC{EXTRA} = q{};

    if ($active_m > 12) {
      $active_m = 1;
      $active_y = $active_y + 1;
    }

    $active_m = sprintf("%.2d", $active_m);

    my $days_in_month = days_in_month({ DATE => "$active_y-$active_m" });

    if ($i > 0) {
      $sum   = $Service->{TP_INFO}->{PRICE};
      $DATE_ = "$active_y-$active_m-01";
      $TIME  = "00:00:00";
      $active_d = 1;
    }
    elsif ($Service->{ACTIVATE} && $Service->{ACTIVATE} ne '0000-00-00') {
      $DATE_ = "$active_y-$active_m-$active_d";
      $TIME  = "00:00:00";
    }

    my %period_params = (
      TYPE             => 1,
      START_DATE       => $DATE_ || $cur_date,
      PERIOD_ALIGNMENT => $Service->{TP_INFO}{PERIOD_ALIGNMENT},
      ACCOUNT_ACTIVATE => $DATE_ #$Service->{ACTIVATE}
    );

    my $work_days = 0;
    if ($Service->{TP_INFO}{PERIOD_ALIGNMENT} && $active_d != $CONF->{START_PERIOD_DAY}) {
      if ($Service->{ACTIVATE} && $Service->{ACTIVATE} ne '0000-00-00') {
        $days_in_month = days_in_month({ DATE => "$active_y-$active_m" });
      }
      $FEES_DSC{EXTRA} = " $lang{PERIOD_ALIGNMENT}\n";
      my ($end_y, $end_m, $end_d) = split('-', $attr->{END_DATE} || q{});
      $work_days = $days_in_month - $active_d;

      if ($i == $periods && $attr->{END_DATE} && $end_y == $y && $end_m == $m) {
        $work_days = $end_d - $active_d;
        $period_params{END_DATE} = $attr->{END_DATE};
      }

      $work_days += $CONF->{START_PERIOD_DAY};
      $sum = sprintf("%.2f", ($sum / $days_in_month) * $work_days);
    }
    elsif ($i == $periods && $attr->{END_DATE}) {
      my (undef, undef, $end_d) = split('-', $attr->{END_DATE} || q{}, 3);
      if ($days_in_month > $end_d) {
        $work_days = $end_d;

        # if ($active_d != $CONF->{START_PERIOD_DAY}) {
        #   $work_days += $CONF->{START_PERIOD_DAY};
        # }

        $sum = sprintf("%.2f", ($sum / $days_in_month) * $work_days);
        $period_params{END_DATE} = $attr->{END_DATE};
      }
    }

    if ($discount > 0) {
      if ($attr->{DISCOUNT_ACTIVATE} && date_diff($period_params{START_DATE}, $attr->{DISCOUNT_ACTIVATE}) > 0) {
        #print " Wrong activate" if ($debug);
      }
      elsif($attr->{DISCOUNT_EXPIRE} && date_diff($period_params{START_DATE}, $attr->{DISCOUNT_EXPIRE}) < 0){
        #print " Wrong expire $DATE_, $attr->{DISCOUNT_EXPIRE}: " . date_diff($DATE_, $attr->{DISCOUNT_EXPIRE}) if ($debug);
      }
      else {
        $sum = $sum * ((100 - $discount) / 100);
      }
    }
    elsif ($Service->{TP_INFO}{DISCOUNT} && $user->{REDUCTION} > 0) {
      $sum = $sum * ((100 - $user->{REDUCTION}) / 100);
    }

    if ($Service->{SERVICE_COUNT} && $Service->{SERVICE_COUNT} > 1) {
      $sum = $sum * $Service->{SERVICE_COUNT};
    }

    if ($Service->{COMMENTS}) {
      $FEES_DSC{EXTRA} .= $Service->{COMMENTS};
    }

    #add period
    $FEES_DSC{PERIOD} = get_period_dates(\%period_params);

    my $fees_message = abon_fees_dsc_former(\%FEES_DSC);
    $fees_message =~ s/\n//gx;
    $active_m++;

    if ($attr->{TEST}) {
      push @{ $self->{SUM} }, sprintf('%.2f', $sum);
      push @{ $self->{DAYS}}, $work_days;
      push @{ $self->{PERIOD}}, "$period_params{START_DATE} - ". ($period_params{END_DATE} || q{}); # ."\n";
      if ($attr->{DEBUG}) {
        print "PERIOD_: $self->{PERIOD} DAYS_: $self->{DAYS} SUM_: $self->{SUM}<br>\n";
      }
      next;
      #return $self;
    }

    $Fees->take($users, $sum, {
      DESCRIBE => $fees_message,
      METHOD   => $Service->{TP_INFO}->{FEES_TYPE},
      DATE     => "$cur_date $TIME"
    });

    if ($attr->{SHOW_SUM}) {
      $attr->{FORM}{OPERATION_SUM} = $sum;
      $attr->{FORM}{OPERATION_DESCRIBE} = $fees_message;
    }

    $self->{OPERATION_SUM} = sprintf("%.2f", $sum || 0);
    $self->{OPERATION_DESCRIBE} .= $fees_message . " $self->{OPERATION_SUM} \n";
    $self->{OPERATION_TOTAL_SUM} += sprintf("%.2f", $sum || 0);

    if (!$Fees->{errno}) {
      $fees_message .= ($lang{SUM} ? " $lang{SUM}" : ' SUM') . ": $self->{OPERATION_SUM}";
      push @messages, $fees_message;
    }
    else {
      return { MESSAGES => \@messages, errno => $Fees->{errno}, errstr => $Fees->{errstr} };
    }
  }

  return { MESSAGES => \@messages };
}

#**********************************************************
=head2 abon_fees_dsc_former($attr) - Make fees describe

  Arguments:
    $attr
      SERVICE_NAME       - Service name
      TEMPLATE_KEY_NAME  - name for %conf key (ABON_FEES_DSC)
      TEMPLATE           - Template

  Results:
    $formed_string

=cut
#**********************************************************
sub abon_fees_dsc_former {
  my ($attr) = @_;

  my $template_key_name = $attr->{TEMPLATE_KEY_NAME} || 'ABON_FEES_DSC';

  if (!defined($attr->{SERVICE_NAME})) {
    $attr->{SERVICE_NAME} = 'Abon';
  }

  my $text = '%SERVICE_NAME%: %FEES_PERIOD_MONTH%%FEES_PERIOD_DAY% %TP_NAME% (%TP_ID%)%ID%%EXTRA%%PERIOD%';

  if($CONF->{$template_key_name}) {
    $text = $CONF->{$template_key_name}
  }
  elsif($attr->{TEMPLATE}) {
    $text = $attr->{TEMPLATE};
  }

  while ($text =~ m/\%(\w+)\%/gx) {
    my $var = $1;
    if (!defined($attr->{$var})) {
      $attr->{$var} = q{};
    }
    $text =~ s/\%$var\%/$attr->{$var}/gx;
  }

  while ($text =~ /\$lang\{([A-Z_]+)\}/x) {
    my $lang_name = $1;
    if ($lang_name && defined $lang{$lang_name}) {
      $text =~ s/\$lang\{$lang_name\}/$lang{$lang_name}/x;
    }
  }

  return $text;
}

1;