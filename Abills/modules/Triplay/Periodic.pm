=head1

  Tripaly periodic

=cut

use strict;
use warnings;

our(
  $db,
  %conf,
  $admin,
  %ADMIN_REPORT,
  %lang,
  $html
);

use Triplay;
use Fees;
use Triplay::Base;

my $Triplay      = Triplay->new($db, $admin, \%conf);
my $Fees         = Fees->new($db, $admin, \%conf);
my $Triplay_base = Triplay::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

#**********************************************************
=head2 triplay_daily_fees($attr) - Daily fees

  Arguments:
    $attr
      DATE

=cut
#**********************************************************
sub triplay_daily_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  return $debug_output if ($attr->{LOGON_ACTIVE_USERS} || $attr->{SRESTART});

  #my $fees_priority = $conf{FEES_PRIORITY} || q{};
  $debug_output .= "Triplay: Daily periodic payments\n" if ($debug > 1);

  my $date = $attr->{DATE} || $ADMIN_REPORT{DATE};
  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{UID} = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$date";
  $USERS_LIST_PARAMS{GID} = $attr->{GID} if ($attr->{GID});

  my $FEES_METHODS = get_fees_types({ SHORT => 1 });

  $Triplay->{debug} = 1 if ($debug > 5);

  my $tariff_plans = $Triplay->tp_list({
    %LIST_PARAMS,
    NAME         => '_SHOW',
    MODULE       => 'Triplay',
    DOMAIN_ID    => '_SHOW',
    FEES_METHOD  => '_SHOW',
    DAY_FEE      => '>0',
    CREDIT       => '_SHOW',
    MODULES      => 'Triplay',
    PAYMENT_TYPE => '_SHOW',
    COLS_NAME    => 1,
    COLS_UPPER   => 1,
    PAGE_ROWS    => 10000
  });

  foreach my $tariff (@{$tariff_plans}) {
    next if !$tariff->{DAY_FEE};

    if ($debug > 1) {
      $debug_output .= "TP ID: $tariff->{ID} DF: $tariff->{DAY_FEE}\n";
    }

    $USERS_LIST_PARAMS{DOMAIN_ID} = $tariff->{DOMAIN_ID};

    my $user_list = $Triplay->user_list({
      SERVICE_STATUS => '0',
      LOGIN_STATUS   => 0,
      TP_ID          => $tariff->{TP_ID},
      TP_CREDIT      => '_SHOW',
      DELETED        => 0,
      LOGIN          => '_SHOW',
      BILL_ID        => '_SHOW',
      REDUCTION      => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      COMPANY_ID     => '_SHOW',
      PERSONAL_TP    => '_SHOW',
      EXT_DEPOSIT    => '_SHOW',
      PAGE_ROWS      => 1000000,
      SORT           => 1,
      COLS_NAME      => 1,
      %USERS_LIST_PARAMS
    });

    foreach my $u (@$user_list) {
      my %user = (
        LOGIN          => $u->{login},
        UID            => $u->{uid},
        ID             => $u->{id},
        BILL_ID        => $u->{bill_id},
        REDUCTION      => $u->{reduction},
        DEPOSIT        => $u->{deposit},
        SERVICE_STATUS => $u->{service_status},
        CREDIT         => ($u->{credit} > 0) ? $u->{credit} : ($tariff->{CREDIT} || 0),
        COMPANY_ID     => $u->{company_id},
        STATUS         => $u->{service_status},
        TP_ID          => $tariff->{TP_ID}
      );

      my %FEES_DSC = (
        MODULE          => 'Triplay',
        TP_ID           => $tariff->{TP_ID},
        TP_NAME         => $tariff->{NAME},
        SERVICE_NAME    => 'Triplay',
        FEES_PERIOD_DAY => $lang{DAY_FEE_SHORT},
        FEES_METHOD     => $FEES_METHODS->{$tariff->{FEES_METHOD}},
        DATE            => $date,
        METHOD          => $tariff->{FEES_METHOD} ? $tariff->{FEES_METHOD} : 1,
      );


      my %PARAMS = (
        DESCRIBE => fees_dsc_former(\%FEES_DSC),
        DATE     => "$date $TIME",
        METHOD   => $tariff->{fees_method} ? $tariff->{fees_method} : 1
      );

      if ($tariff->{payment_type} || $user{DEPOSIT} + $user{CREDIT} > 0) {
        $Fees->take(\%user, $tariff->{DAY_FEE}, \%PARAMS);
        $debug_output .= "UID: $user{UID} SUM: $tariff->{DAY_FEE} REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 triplay_monthly_fees($attr) - Monthly fees

  Arguments:
    $attr
      DEBUG
      DATE
      TP_ID

  Returns:

=cut
#**********************************************************
sub triplay_monthly_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  if ($attr->{LOGON_ACTIVE_USERS} || $attr->{SRESTART}) {
    return $debug_output;
  }

  #my $fees_priority = $conf{FEES_PRIORITY} || q{};

  $debug_output .= "Triplay: Monthly periodic payments\n" if ($debug > 1);

  #$ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my $date = $attr->{DATE} || $ADMIN_REPORT{DATE};

  if ($attr->{TP_ID}) {
    $LIST_PARAMS{INNER_TP_ID} = $attr->{TP_ID};
    delete $LIST_PARAMS{TP_ID};
  }

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{UID} = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$date";
  $USERS_LIST_PARAMS{GID} = $attr->{GID} if ($attr->{GID});

  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my ($y, $m, $d) = split(/-/, $date, 3);

  $debug_output .= triplay_monthly_next_tp($attr);

  if ($d != $START_PERIOD_DAY) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  my $days_in_month = days_in_month({ DATE => $date });
  my $cure_month_begin = "$y-$m-01";
  my $cure_month_end   = "$y-$m-$days_in_month";
  $m--;
  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, $m, $y - 1900, 0, 0, 0);

  #Get Preview month begin end days
  if ($m == 0) {
    $m = 12;
    $y--;
  }

  $m = sprintf("%02d", $m);
  my $days_in_pre_month = days_in_month({ DATE => "$y-$m-01" });

  my $pre_month_begin = "$y-$m-01";
  my $pre_month_end   = "$y-$m-$days_in_pre_month";

  my $FEES_METHODS = get_fees_types({ SHORT => 1 });

  $Triplay->{debug} = 1 if ($debug > 5);

  my $list = $Triplay->tp_list({
    %LIST_PARAMS,
    NAME          => '_SHOW',
    MODULE        => 'Triplay',
    DOMAIN_ID     => '_SHOW',
    FEES_METHOD   => '_SHOW',
    MONTH_FEE     => '>0',
    CREDIT        => '_SHOW',
    MODULES       => 'Triplay',
    PAYMENT_TYPE  => '_SHOW',
    REDUCTION_FEE => '_SHOW',
    COLS_NAME     => 1,
    COLS_UPPER    => 1,
    PAGE_ROWS     => 1000
  });

  foreach my $TP_INFO (@$list) {
    my $month_fee = $TP_INFO->{MONTH_FEE} || 0;
    #my $activate_date = "<=$ADMIN_REPORT{DATE}";
    my $postpaid = $TP_INFO->{POSTPAID_MONTHLY_FEE} || $TP_INFO->{PAYMENT_TYPE} || 0;
    $USERS_LIST_PARAMS{DOMAIN_ID} = $TP_INFO->{DOMAIN_ID};

    if ($month_fee > 0) {
      $debug_output .= "TP ID: $TP_INFO->{ID} MF: $TP_INFO->{MONTH_FEE} POSTPAID: $postpaid "
        . "CREDIT: $TP_INFO->{CREDIT} "
        . "\n" if ($debug > 1);

      my $user_list = $Triplay->user_list({
        SERVICE_STATUS => "0;5",
        LOGIN_STATUS => 0,
        TP_ID        => $TP_INFO->{TP_ID},
        SORT         => 1,
        PAGE_ROWS    => 1000000,
        TP_CREDIT    => '_SHOW',
        DELETED      => 0,
        LOGIN        => '_SHOW',
        BILL_ID      => '_SHOW',
        REDUCTION    => '_SHOW',
        DEPOSIT      => '_SHOW',
        CREDIT       => '_SHOW',
        COMPANY_ID   => '_SHOW',
        PERSONAL_TP  => '_SHOW',
        EXT_DEPOSIT  => '_SHOW',
        COLS_NAME    => 1,
        %USERS_LIST_PARAMS
      });

      foreach my $u (@$user_list) {
        my %user = (
          LOGIN          => $u->{login},
          UID            => $u->{uid},
          ID             => $u->{id},
          BILL_ID        => $u->{bill_id},
          REDUCTION      => $u->{reduction} || 0,
          DEPOSIT        => $u->{deposit},
          SERVICE_STATUS => $u->{service_status},
          CREDIT         => ($u->{credit} > 0) ? $u->{credit} : ($TP_INFO->{CREDIT} || 0),
          COMPANY_ID     => $u->{company_id},
          STATUS         => $u->{service_status},
          TP_ID          => $TP_INFO->{TP_ID}
        );

        my %FEES_DSC = (
          MODULE            => 'Triplay',
          TP_ID             => $TP_INFO->{TP_ID},
          TP_NAME           => $TP_INFO->{NAME},
          SERVICE_NAME      => 'Triplay',
          FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
          FEES_METHOD       => $FEES_METHODS->{$TP_INFO->{FEES_METHOD}},
          DATE              => $date,
          METHOD            => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
        );

        if ($debug > 3) {
          $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: $u->{tp_id} Fees: $TP_INFO->{MONTH_FEE}"
            . "REDUCTION: $user{REDUCTION} DEPOSIT: $user{DEPOSIT} CREDIT $user{CREDIT} TP: $user{TP_ID}\n";
        }

        if (! $user{BILL_ID} && ! defined($user{DEPOSIT})) {
          print "ERROR: UID: $user{UID} LOGIN: $user{LOGIN} Don't have money account\n";
          next;
        }

        my $sum =  $month_fee;
        if ($u->{personal_tp} && $u->{personal_tp} > 0) {
          if($TP_INFO->{ABON_DISTRIBUTION}) {
            $sum = $u->{personal_tp} / $days_in_month;
          }
          else {
            $sum = $u->{personal_tp};
          }
        }

        if ($TP_INFO->{REDUCTION_FEE} && $user{REDUCTION} > 0) {
          $sum = $sum * (100 - $user{REDUCTION}) / 100;
          if ($user{REDUCTION} == 100) {
            $debug_output .= " REDUCTION: $user{REDUCTION}\n";
            next;
          }
        }

        if (! $postpaid && $user{DEPOSIT} + $user{CREDIT} < $sum) {
          #Block services
          $debug_output .= "$user{LOGIN} deactivate";
          triplay_service_deactivate({
            TP_INFO   => $TP_INFO,
            USER_INFO => \%user,
            DATE      => $date,
            DEBUG     => $debug
          });
          next;
        }

        if ($user{SERVICE_STATUS} == 5) {
          $debug_output .= "$user{LOGIN} activate";
          triplay_service_activate({
            TP_INFO   => $TP_INFO,
            USER_INFO => \%user,
            DEBUG     => $debug
          });
        }

        if ($debug < 8) {
          if ($sum <= 0) {
            $debug_output .= "!!REDUCTION!! $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
            next;
          }

          my %PARAMS = (
            DATE     => "$date $TIME",
            METHOD   => ($TP_INFO->{FEES_METHOD}) ? $TP_INFO->{FEES_METHOD} : 1,
            DESCRIBE => fees_dsc_former(\%FEES_DSC),
          );
          $PARAMS{DESCRIBE} .= " ($cure_month_begin-$cure_month_end)";

          $Fees->take(\%user, $sum, \%PARAMS);
          if ($Fees->{errno}) {
            print "Triplay Error: [ $user{UID} ] $user{LOGIN} SUM: $sum [$Fees->{errno}] $Fees->{errstr} ";
            if ($Fees->{errno} == 14) {
              print "[ $user{UID} ] $user{LOGIN} - Don't have money account";
            }
            print "\n";
          }
          elsif ($debug > 0) {
            $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
          }
        }
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 triplay_service_activate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
        UID
        ID
      DEBUG

  Result:
    TRUE or FALSE

=cut
#**********************************************************
sub triplay_service_activate {
  my ($attr)=@_;

  my $debug = $attr->{DEBUG} || 0;

  $Triplay->user_change({
    UID     => $attr->{USER_INFO}->{UID},
    DISABLE => 0
  });

  my $service_list = $Triplay->service_list({
    UID        => $attr->{USER_INFO}->{UID},
    MODULE     => '_SHOW',
    SERVICE_ID => '_SHOW'
  });

  foreach my $service  (@$service_list) {
    if ($debug > 1) {
      print "UID: $service->{uid} SERVICE_ID: $service->{service_id} MODULE: $service->{module}\n";
    }
    my $fn = lc($service->{module}) .'_service_activate';
    if (defined(&$fn)) {
      if ($debug > 3) {
        print "run: $fn\n";
      }

      &{ \&$fn }({
        USER_INFO => {
          UID => $service->{uid},
          ID  => $service->{service_id},
        },
        TP_INFO  => {
          SMALL_DEPOSIT_ACTION => -1
        },
        STATUS    => 0
      });
    }
  }

  #_external('', { EXTERNAL_CMD => 'Internet', %{ $attr->{USER_INFO} }, QUITE => 1 });

  return 1;
}

#**********************************************************
=head2 triplay_service_deactivate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
      DEBUG

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub triplay_service_deactivate {
  my ($attr)=@_;

  my $debug_output = q{};
  #my $TP_INFO = $attr->{TP_INFO};
  my $user_info = $attr->{USER_INFO};
  my $debug = $attr->{DEBUG} || 0;
  my $action = 0;

  if (defined($user_info->{SERVICE_STATUS}) && $user_info->{SERVICE_STATUS} != 5) {
    $Triplay->user_change({
      UID    => $user_info->{UID},
      DISABLE => 5
    });
  }

  $Triplay->{debug}=1 if ($debug > 6);
  my $service_list = $Triplay->service_list({
    UID        => $attr->{USER_INFO}->{UID},
    MODULE     => '_SHOW',
    SERVICE_ID => '_SHOW'
  });

  foreach my $service  (@$service_list) {
    if ($debug > 1) {
      print "UID: $service->{uid} SERVICE_ID: $service->{service_id} MODULE: $service->{module}\n";
    }
    my $fn = lc($service->{module}) .'_service_deactivate';

    if (defined(&$fn)) {
      if ($debug > 3) {
        print "run: $fn\n";
      }

      &{ \&$fn }({
        USER_INFO => {
          UID => $service->{uid},
          ID  => $service->{service_id},
        },
        TP_INFO   => {
          #SMALL_DEPOSIT_ACTION => -1
          small_deposit_action => -1
        },
        STATUS    => 1,
        DATE      => $attr->{DATE}
      });
    }
  }

  if ($action) {
    _external('', { EXTERNAL_CMD => 'Triplay', %{$attr->{USER_INFO}}, QUITE => 1 });
  }

  return $debug_output;
}

#***********************************************************
=head2 triplay_sheduler($type, $action, $uid, $attr)

  Arguments:
    $type
    $action
    $uid
    $attr

  Returns:
    TRUE or FALSE

=cut
#***********************************************************
sub triplay_sheduler {
  my ($type, $action, $uid, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  $action //= q{};
  my $date = $attr->{DATE} || $ADMIN_REPORT{DATE};
  my $d  = (split(/-/, $date, 3))[2];
  my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;
  my $users = Users->new($db, $admin, \%conf);
  my $user = $users->info($uid);

  if ($type eq 'tp') {
    my $service_id;
    my $tp_id = 0;
    if($action =~ /(\d{0,16}):(\d+)/) {
      $service_id = $1;
      $tp_id      = $2;
    }

    my %params = ();
    $Triplay->user_info({ UID => $uid, ID => $service_id });

    #Change activation date after change TP
    #Date must change after tp fees
    #if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00' && !$Internet->{STATUS}) {
    #  $params{ACTIVATE} = $ADMIN_REPORT{DATE};
    #}

    $Triplay->user_change({
      UID         => $uid,
      TP_ID       => $tp_id,
      ID          => $service_id,
      %params
    });

    if ($Triplay->{errno}) {
      return $Triplay->{errno};
    }
    elsif ($Triplay->{DISABLE}) {
      if ($debug > 1) {
        print "WARNING: Skip not active service\n";
      }
      return 1;
    }
    else {

      if ($attr->{GET_ABON} && $attr->{GET_ABON} eq '-1' && $attr->{RECALCULATE} && $attr->{RECALCULATE} eq '-1') {
        print "Skip: GET_ABON, RECALCULATE\n" if ($debug > 1);
        #return 0;
      }
      else {
        if ($Triplay->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
          $Triplay->{TP_INFO}->{MONTH_FEE} = 0;
        }

        service_get_month_fee($Triplay, {
          QUITE       => 1,
          SHEDULER    => 1,
          DATE        => $attr->{DATE},
          RECALCULATE => 1,
          USER_INFO   => $user
        });
      }

      $Triplay_base->triplay_service_activate_web({ UID => $uid, USER_INFO => $user, TP_ID => $tp_id });
    }
  }
  elsif ($type eq 'status') {
    my $service_id;

    if($action =~ /:/) {
      ($service_id, $action)=split(/:/, $action);
    }

    $Triplay->user_change({
      UID        => $uid,
      STATUS     => $action,
      SERVICE_ID => $service_id
    });

    #Get fee for holdup service
    if ($action == 3) {
      my $active_fees = 0;

      #@deprecated
      if (! $conf{INTERNET_USER_SERVICE_HOLDUP} && $conf{HOLDUP_ALL}) {
        $conf{INTERNET_USER_SERVICE_HOLDUP} = $conf{HOLDUP_ALL};
      }

      if ($conf{INTERNET_USER_SERVICE_HOLDUP}) {
        $active_fees =  (split(/:/, $conf{INTERNET_USER_SERVICE_HOLDUP}))[5];
      }

      if ($active_fees && $active_fees > 0) {
        #$user = $users->info($uid);
        $Fees->take(
          $user,
          $active_fees,
          {
            DESCRIBE => $lang{HOLD_UP},
            DATE     => "$date $TIME",
          }
        );

        if ($Fees->{errno}) {
          print "Error: Holdup fees: $Fees->{errno} $Fees->{errstr}\n";
        }
      }

      # if ($conf{INTERNET_HOLDUP_COMPENSATE}) {
      #   $Triplay->{TP_INFO_OLD} = $Tariffs->info(0, { TP_ID => $Triplay->{TP_ID} });
      #   if ($Triplay->{TP_INFO_OLD}->{PERIOD_ALIGNMENT}) {
      #     #$Triplay->{TP_INFO}->{MONTH_FEE} = 0;
      #     service_recalculate($Triplay,
      #       { RECALCULATE => 1,
      #         QUITE       => 1,
      #         SHEDULER    => 1,
      #         USER_INFO   => $user,
      #         DATE        => $ADMIN_REPORT{DATE}
      #       });
      #   }
      # }

      if ($action) {
        _external('', { EXTERNAL_CMD => 'Triplay', %{$Triplay} });
      }
    }
    elsif ($action == 0) {
      if ($Triplay->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
        $Triplay->{TP_INFO}->{MONTH_FEE} = 0;
      }

      service_get_month_fee($Triplay, {
        QUITE    => 1,
        SHEDULER => 1,
        DATE     => $attr->{DATE},
        USER_INFO=> $user
      });

      $Triplay_base->triplay_service_activate_web({ UID => $uid, USER_INFO => $user });
    }

    if ($Triplay->{errno} && $Triplay->{errno} == 15) {
      return $Triplay->{errno};
    }
  }

  return 1;
}

#**********************************************************
=head2 triplay_monthly_next_tp($attr) Change tp in next period

  Argumnets:
    $attr
      DEBUG
      DATE

  Returns:
    $debug_output

=cut
#**********************************************************
sub triplay_monthly_next_tp {
  my ($attr) = @_;

  my $Tariffs      = Tariffs->new($db, \%conf, $admin);
  my $debug        = $attr->{DEBUG} || 0;
  my $debug_output = '';
  my $date         = $attr->{DATE} || $ADMIN_REPORT{DATE};

  $debug_output  = "Triplay: Next tp\n" if ($debug > 1);

  if ($debug > 5) {
    $Tariffs->{debug} = 1;
    $Triplay->{debug} = 1;
  }

  my %USERS_LIST_PARAMS = ();
  $USERS_LIST_PARAMS{LOGIN}        = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL}     = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  $USERS_LIST_PARAMS{REGISTRATION} = "<$date";
  $USERS_LIST_PARAMS{GID}          = $attr->{GID} if ($attr->{GID});

  #Get all TPS
  my $tp_new_list = $Tariffs->list({
    NEXT_TARIF_PLAN => '_SHOW',
    CREDIT          => '_SHOW',
    AGE             => '_SHOW',
    NEXT_TP_ID      => '_SHOW',
    CHANGE_PRICE    => '_SHOW',
    PERIOD_ALIGNMENT=> '_SHOW',
    NEW_MODEL_TP    => 1,
    MODULE          => 'Triplay',
    COLS_NAME       => 1
  });

  my %tp_new = ();
  foreach my $tp_info (@$tp_new_list) {
    $tp_new{$tp_info->{tp_id}}=$tp_info;
  }

  #Get base list
  my $tp_list = $Tariffs->list({
    %LIST_PARAMS,
    NEXT_TARIF_PLAN => '>0',
    CREDIT          => '_SHOW',
    AGE             => '_SHOW',
    NEXT_TP_ID      => '_SHOW',
    CHANGE_PRICE    => '_SHOW',
    NEW_MODEL_TP    => 1,
    MODULE          => 'Triplay',
    COLS_NAME       => 1
  });

  my ($y, $m, $d)   = split(/-/, $date, 3);
  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0);
  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my %CHANGED_TPS = ();

  # my %tp_ages = ();
  # foreach my $tp_info (@$tp_list) {
  #   $tp_ages{$tp_info->{tp_id}}=$tp_info->{age};
  # }

  foreach my $tp_info (@$tp_list) {
    my $triplay_list = $Triplay->user_list({
      TRIPLAY_ACTIVATE  => "<=$date",
      TRIPLAY_EXPIRE    => "0000-00-00,>$date",
      TRIPLAY_STATUS    => "0;5",
      LOGIN_STATUS       => 0,
      TP_ID              => $tp_info->{tp_id},
      SORT               => 1,
      PAGE_ROWS          => 1000000,
      DELETED            => 0,
      LOGIN              => '_SHOW',
      REDUCTION          => '_SHOW',
      DEPOSIT            => '_SHOW',
      CREDIT             => '_SHOW',
      COMPANY_ID         => '_SHOW',
      TRIPLAY_EXPIRE     => '_SHOW',
      BILL_ID            => '_SHOW',
      COLS_NAME          => 1,
      %USERS_LIST_PARAMS
    });

    foreach my $u (@$triplay_list) {
      my %user_info = (
        ID         => $u->{id},
        LOGIN      => $u->{login},
        UID        => $u->{uid},
        BILL_ID    => $u->{bill_id},
        REDUCTION  => $u->{reduction},
        ACTIVATE   => $u->{triplay_activate} || '0000-00-00',
        EXPIRE     => $u->{triplay_expire},
        DEPOSIT    => $u->{deposit},
        CREDIT     => ($u->{credit} > 0) ? $u->{credit} :  $tp_info->{credit},
        COMPANY_ID => $u->{company_id},
        TRIPLAY_STATUS => $u->{triplay_status},
        TRIPLAY_EXPIRE => $u->{triplay_expire},
        EXT_BILL_DEPOSIT=> ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      );

      my $expire = undef;
      if (!$CHANGED_TPS{ $user_info{UID} }
        && ((!$tp_info->{age} && ($d == $START_PERIOD_DAY) || $user_info{ACTIVATE} ne '0000-00-00')
        || ($tp_info->{age} && $user_info{EXPIRE} eq $date) )) {

        if($user_info{EXPIRE} ne '0000-00-00') {
          if($user_info{EXPIRE} eq $date) {
            # if (!$tp_ages{$tp_info->{tp_id}}) {
            #   $expire = '0000-00-00';
            # }
            # els
            if(!$tp_new{$tp_info->{next_tp_id}}->{age}) {
              $expire = '0000-00-00';
            }
            else {
              my $next_age = $tp_new{$tp_info->{next_tp_id}}->{age};
              $expire = POSIX::strftime("%Y-%m-%d",
                localtime(POSIX::mktime(0, 0, 0, $d, ($m-1), ($y - 1900), 0, 0, 0) + $next_age * 86400));
            }
          }
          else {
            next;
          }
        }
        elsif ($user_info{ACTIVATE} ne '0000-00-00') {
          my ($activate_y, $activate_m, $activate_d) = split(/-/, $user_info{ACTIVATE}, 3);
          my $active_unixtime = POSIX::mktime(0, 0, 0, $activate_d, $activate_m - 1, $activate_y - 1900, 0, 0, 0);
          if ($date_unixtime - $active_unixtime < 31 * 86400) {
            next;
          }
        }

        $debug_output .= " Login: $user_info{LOGIN} ($user_info{UID}) ACTIVATE $user_info{ACTIVATE} TP_ID: $tp_info->{tp_id} -> $tp_info->{next_tp_id}\n";
        $CHANGED_TPS{ $user_info{UID} } = 1;

        my  %user_change_params = ();
        if($conf{TRIPLAY_CUSTOM_PERIOD} && $u->{deposit} < $tp_info->{change_price}) {
          $user_change_params{STATUS} = 5;
          $expire = $date;
        }
        elsif ($tp_new{$tp_info->{next_tp_id}}->{period_alignment}) {
          $expire = '0000-00-00';
          $user_info{ACTIVATE}='0000-00-00';
        }

        if($debug < 8) {
          $Triplay->user_change({
            ID             => $user_info{ID},
            UID            => $user_info{UID},
            #STATUS         => $status,
            TP_ID          => $tp_info->{next_tp_id},
            EXPIRE         => $expire,
            %user_change_params
          });
        }

        if($tp_info->{change_price}
          && $tp_info->{change_price} > 0
          && $tp_info->{next_tp_id} == $tp_info->{tp_id}
          #&& ! $status
        ) {
          $Fees->take(\%user_info, $tp_info->{change_price}, { DESCRIBE => $lang{ACTIVATE_TARIF_PLAN} });
          if($Fees->{errno}) {
            print "ERROR: $Fees->{errno} $Fees->{errstr}\n";
          }
        }
        else {
          $Tariffs->info(0, { TP_ID => $tp_info->{next_tp_id} });
          if ($Tariffs->{MONTH_FEE} && $Tariffs->{MONTH_FEE} > 0
            && $d > 1
            && $user_info{ACTIVATE} eq '0000-00-00'
            && ! $Triplay->{TP_INFO}->{ABON_DISTRIBUTION}) {

            $Triplay->{TP_INFO}->{MONTH_FEE}           = $Tariffs->{MONTH_FEE};
            $Triplay->{TP_INFO_OLD}->{PERIOD_ALIGNMENT}= $Tariffs->{PERIOD_ALIGNMENT};

            if ($conf{TRIPLAY_DEBUG}) {
              `echo "$DATE $TIME $user_info{LOGIN}: ACTIVATE: $user_info{ACTIVATE} TP_ID: $tp_info->{next_tp_id}" >> /tmp/triplay.log`;
            }

            service_get_month_fee($Triplay, {
              QUITE       => 1,
              DATE        => $date,
              MODULE      => 'Triplay',
              SERVICE_NAME=> 'Triplay',
              USER_INFO   => \%user_info
            });
          }
        }
      }
    }
  }

  return $debug_output;
}


1;