=head2 NAME

  Services

=cut

use strict;
use warnings FATAL => 'all';
use Triplay;
use Shedule;
use Triplay::Base;

our (
  $db,
  %conf,
  %lang,
  $admin,
);

our Abills::HTML $html;
my $Triplay = Triplay->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Shedule = Shedule->new($db, $admin, \%conf);
my $Triplay_base = Triplay::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

require Control::Services;

#**********************************************************
=head2 test()

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub triplay_users_services {
  my ($attr) = @_;

  result_former({
    INPUT_DATA     => $Triplay,
    FUNCTION       => 'user_list',
    BASE_FIELDS    => 0,
    DEFAULT_FIELDS => "LOGIN,INTERNET_TP_NAME,IPTV_TP_NAME,ABON_TP_NAME,VOIP_TP_NAME",
    FILTER_COLS    => {
      abonplata => '_triplay_abonplata_count::ABONPLATA'
    },
    #      FUNCTION_FIELDS => 'change, del',
    EXT_TITLES     => {
      'internet_tp_name' => $lang{INTERNET},
      'iptv_tp_name'     => $lang{TV},
      'abon_tp_name'     => $lang{ABON},
      'voip_tp_name'     => $lang{VOIP},
    },
    TABLE          => {
      width   => '100%',
      caption => "Triplay - $lang{USERS}",
      qs      => $pages_qs,
      ID      => 'TRIPLAY_USER_SERVICES',
      header  => '',
      EXPORT  => 1,
      #        MENU    => "$lang{ADD}:index=" . get_function_index( 'triplay_main' ) . ':add' . ";",
    },
    MAKE_ROWS      => 1,
    SEARCH_FORMER  => 1,
    MODULE         => 'Triplay',
    TOTAL          => 1
  });

  return 1;
}

#**********************************************************
=head2 _triplay_abonplata_count() - count amount for all triplay services

  Arguments:
     uid  - user identifier
     attr - {

     }

  Returns:
    total_sum - amount of money to pay for all services

  Example:
    my $total_sum = _triplay_abonplata_count(1, {});

=cut
#**********************************************************
sub _triplay_abonplata_count {
  my ($uid) = @_;

  return 'This user has not services  ' if (!$uid);

  my $user_services_information = cross_modules('docs', { UID => $uid });

  my $total_sum = 0;
  if ($user_services_information->{Internet}) {
    foreach my $internet_service_info (@{$user_services_information->{Internet}}) {
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $internet_service_info);
      $total_sum += $amount;
    }
  }

  if ($user_services_information->{Iptv}) {
    foreach my $iptv_service_info (@{$user_services_information->{Iptv}}) {
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $iptv_service_info);
      $total_sum += $amount;
    }
  }

  if ($user_services_information->{Voip}) {
    foreach my $voip_service_info (@{$user_services_information->{Voip}}) {
      my (undef, undef, $amount, undef, undef, undef, undef) = split('\|', $voip_service_info);
      $total_sum += $amount;
    }
  }

  return sprintf('%.2f', $total_sum);
}

#**********************************************************
=head2 triplay_user($attr) - in menu services

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub triplay_user {
  my ($attr) = @_;

  my $services_info = '';
  $Triplay->{ACTION} = 'add';
  $Triplay->{ACTION_LNG} = $lang{ADD};
  my $uid = $FORM{UID} || 0;

  if ($FORM{TP_ID}) {
    $Triplay->tp_info({ TP_ID => $FORM{TP_ID} });
    if ($Triplay->{AGE}) {
      my $expire = expire_date($Triplay, $Triplay);
      $FORM{EXPIRE} = $Triplay->{EXPIRE};
    }
  }

  if ($FORM{add}) {
    $Triplay->user_add(\%FORM);

    if (!$Triplay->{errno}) {
      $html->message('info', '3Play', $lang{ADDED});
      $Triplay_base->triplay_service_activate_web({
        %FORM,
        USER_INFO => $users,
        TP_INFO   => $Triplay->{TP_INFO}
      });
    }
    else {
      if ($Triplay->{errno} && $Triplay->{errno} == 3) {
        $html->message('err', "$lang{WRONG} $lang{TARIF_PLAN}", "$lang{CHOOSE} $lang{TARIF_PLAN}", { ID => 1301 });
      }
    }
  }
  elsif ($FORM{change}) {
    $Triplay->user_change(\%FORM);

    if (!$Triplay->{errno}) {
      $Triplay->user_info({ UID => $uid });

      my $service_list = $Triplay->service_list({
        UID        => $uid,
        MODULE     => '_SHOW',
        SERVICE_ID => '_SHOW',
        COLS_NAME  => 1
      });

      foreach my $service (@$service_list) {
        $FORM{uc($service->{module}) . '_SERVICE_ID'} = $service->{service_id} if ($service->{service_id});
      }

      $FORM{TP_ID}=$Triplay->{TP_ID};
      if ($FORM{DISABLE}) {
        $FORM{STATUS} = 1;
      }

      $Triplay_base->triplay_service_activate_web({ %FORM, USER_INFO => $users });

      $html->message('info', $lang{SUCCESS}, $lang{CHANGED});
      #service_get_month_fee($Triplay, { SERVICE_NAME => 'Triplay', MODULE => 'Triplay' });
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $admin->{permissions}{0}{18}) {
    $Triplay->user_del({ UID => $uid });
    if (!$Triplay->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{USER} $lang{DELETED}");
    }
  }

  _error_show($Triplay, { ID => 1135001 });

  my $user_info = $Triplay->user_info({ UID => $uid });

  if ($user_info->{TOTAL} && $user_info->{TOTAL} > 0) {
    $Triplay->{ACTION_LNG} = $lang{CHANGE};
    $Triplay->{ACTION} = 'change';

    # Show tooltip COMMENTS for user and admin
    my $tarif_plan_tooltip = '';
    if ($Triplay->{TP_ID}) {
      $tarif_plan_tooltip =
        $html->b($lang{DESCRIBE_FOR_SUBSCRIBER}) . ': ' . ($Triplay->{COMMENTS} || '') . $html->br()
          . $html->b($lang{DESCRIBE_FOR_ADMIN}) . ': ' . ($Triplay->{DESCRIBE_AID} || '') . $html->br();
    }

    $Triplay->{DESCRIBE_AID} = ($Triplay->{DESCRIBE_AID}) ? ('[' . $Triplay->{DESCRIBE_AID} . ']') : '';

    if ($admin->{permissions}{0}{10}) {
      $Triplay->{CHANGE_TP_BUTTON} = $html->button('',
        'ID=' . ($user_info->{ID} || q{}) . '&UID=' . $uid . '&index=' . get_function_index('triplay_chg_tp'),
        { class => 'btn input-group-button hidden-print', TITLE => $lang{CHANGE}, ICON => "fa fa-pencil-alt" });
      $Triplay->{TARIF_PLAN_TOOLTIP} = "data-tooltip='$tarif_plan_tooltip' data-tooltip-position='top'";
    }

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

    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    my $services = ::get_services($user_info, {
      IPTV_SHOW_FREE_TPS     => 1,
      IPTV_SHOW_ALL_SERVICES => 1
    });

    my %real_service = ();
    foreach my $service (sort @{$services->{list}}) {
      if ($service->{ID}) {
        my ($status_name, $color) = split( /:/, $service_status->{ $service->{STATUS} } );
        my $status = $html->color_mark( $status_name, $color );
        $real_service{$service->{MODULE}} = $service->{SERVICE_NAME} . ' ('. $status .')';
      }
    }

    my $tp_info = $Triplay->tp_info({ TP_ID => $user_info->{TP_ID} });

    $services_info = $html->tpl_show(_include('triplay_sevices_info', 'Triplay'), {
      INTERNET_TP   => ($tp_info->{INTERNET_NAME} || q{}),
      INTERNET_REAL =>  ( ( $real_service{Internet} ) ? $real_service{Internet} :  q{} ),
      VOIP_TP       => ($tp_info->{VOIP_NAME} || q{}) ,
      VOIP_REAL     =>  ( ( $real_service{Voip} ) ? $real_service{Voip} :  q{} ),
      IPTV_TP       => ($tp_info->{IPTV_NAME} || q{}),
      IPTV_REAL     =>  ( ( $real_service{Iptv} ) ? $real_service{Iptv} :  q{} ),
      ABON_TP       => ($tp_info->{ABON_NAME} || q{}),
      ABON_REAL     =>  ( ( $real_service{Abon} ) ? $real_service{Abon} :  q{} ),
      INTERNET_LINK => "$SELF_URL?index=" . get_function_index('internet_user') . "&UID=" . $uid . '&chg=' . ($user_services{INTERNET_SERVICE_ID} || q{}),
      VOIP_LINK     => in_array('Voip', \@MODULES) ? "$SELF_URL?index=" . get_function_index('voip_user') . "&UID=" . $uid . '&chg=' . ($user_services{VOIP_SERVICE_ID} || q{}) : q{},
      ABON_LINK     => in_array('Abon', \@MODULES) ? "$SELF_URL?index=" . get_function_index('abon_user') . "&UID=" . $uid . '&chg=' . ($user_services{ABON_SERVICE_ID} || q{}) : q{},
      IPTV_LINK     => "$SELF_URL?index=" . get_function_index('iptv_user') . "&UID=" . $uid . '&chg=' . ($user_services{IPTV_SERVICE_ID} || q{}),
    }, { OUTPUT2RETURN => 1 });
  }
  else {
    my %services_sel = ();
    my @services = ('Internet', 'Iptv', 'Voip');
    foreach my $service (@services) {
      $services_sel{uc($service) . '_TP'} = triplay_get_services({
        MODULE => ucfirst($service),
        UID    => $uid,
        SELECT => uc($service) . '_SERVICE_ID'
      });
    }

    $services_info = $html->tpl_show(_include('triplay_sevices_info', 'Triplay'), {
      INTERNET => '',
      VOIP     => '',
      IPTV     => '',
      %services_sel
    }, { OUTPUT2RETURN => 1 });

    $Triplay->{TP_ADD} = sel_tp({
      CHECK_GROUP_GEOLOCATION => $user_info->{LOCATION_ID} || 0,
      USER_GID                => $user_info->{GID} || 0,
      USER_INFO               => $users,
      MODULE                  => 'Triplay',
      SELECT                  => 'TP_ID',
      GROUP_SORT              => 1,
      EX_PARAMS               => { SORT_KEY => 1 }
    });

    $Triplay->{TP_DISPLAY_NONE} = "style='display:none'";
  }

  # $Triplay->{TP_ADD} = $html->form_select(
  #   'TP_ID',
  #   {
  #     SELECTED      => $user_info->{TP_ID} || $FORM{TP_ID},
  #     SEL_LIST      => $Triplay->tp_list({ COLS_NAME => 1 }),
  #     SEL_KEY       => 'tp_id',
  #     # SEL_VALUE     => 'name',
  #     NO_ID         => 1,
  #     MAIN_MENU     => get_function_index('triplay_tp'),
  #     MAIN_MENU_ARGV=> "chg=". ($Triplay->{TRIPLAY_TP_ID} || q{}),
  #   }
  # );


  $Triplay->{STATUS_SEL} = sel_status({
    DISABLE   => $Triplay->{DISABLE} || $FORM{DISABLE},
    NAME      => 'DISABLE',
    EX_PARAMS => (defined($Triplay->{STATUS}) && (!$attr->{REGISTRATION} && !$admin->{permissions}{0}{18})) ? " disabled=disabled" : ''
  }, $Triplay->{SHEDULE} || {});

  if ($Triplay->{DISABLE}) {
    my $service_status_colors = sel_status({ COLORS => 1 });
    $Triplay->{STATUS_COLOR} = $service_status_colors->[$Triplay->{DISABLE} || 0];
  }

  if ($admin->{permissions}{0} && $admin->{permissions}{0}{14} && $Triplay->{ID}) {
    $Triplay->{DEL_BUTTON} = $html->button($lang{DEL}, "index=$index&del=1&UID=$uid&ID=$Triplay->{ID}",
      {
        MESSAGE => "$lang{DEL} $lang{SERVICE} Triplay $lang{FOR} $lang{USER} $uid?",
        class   => 'btn btn-danger'
      });
  }

  my $result = $html->tpl_show(_include('triplay_user', 'Triplay'), {
    %{$Triplay},
    INDEX         => get_function_index('triplay_user'),
    UID           => $uid,
    SERVICES_INFO => $services_info
  },
    { ID => 'triplay_service', OUTPUT2RETURN => 1 });

  return $result if ($attr->{PROFILE_MODE});

  print $result;

  return 1;
}

#**********************************************************
=head2 triplay_chg_tp($attr) - Change user tariff plan from admin interface

  Arguments:
    $attr
      UID
      USER_INFO

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub triplay_chg_tp {
  my ($attr) = @_;

  my $user;
  my $uid = 0;
  if (defined($attr->{USER_INFO})) {
    $user = $attr->{USER_INFO};
    $uid = $user->{UID};
    $Triplay = $Triplay->user_info({
      DOMAIN_ID => $user->{DOMAIN_ID},
      ID        => $attr->{ID} || $FORM{ID},
      UID       => $uid
    });

    if ($Triplay->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 1130941 });
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 1130942 });
    return 0;
  }

  if (!$admin->{permissions}{0}{4}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { ID => 1130943 });
    return 1;
  }
  elsif (!$admin->{permissions}{0}{10}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY}, { ID => 1130944 });
    return 1;
  }

  if ($FORM{TP_ID} && $FORM{TP_ID} eq ($Triplay->{TP_ID} || '')) {
    $html->message('warn', '', "$lang{TARIF_PLANS} $lang{EXIST}", { ID => 1130945 });
  }

  my $period = $FORM{period} || 0;

  #Get next period
  if (
    ($Triplay->{MONTH_ABON} && $Triplay->{MONTH_ABON} > 0)
      && !$Triplay->{STATUS}
      && !$users->{DISABLE}
      && (($users->{DEPOSIT} ? $users->{DEPOSIT} : 0) + ($users->{CREDIT} ? $users->{CREDIT} : 0) > 0
      || $Triplay->{POSTPAID_ABON}
      || ($Triplay->{PAYMENT_TYPE} && $Triplay->{PAYMENT_TYPE} == 1))
  ) {
    if ($Triplay->{ACTIVATE} && $Triplay->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $Triplay->{ACTIVATE}, 3);
      $M--;
      $Triplay->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      if ($conf{START_PERIOD_DAY}) {
        $D = $conf{START_PERIOD_DAY};
      }
      else {
        $D = '01';
      }
      $Triplay->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  my $message = '';
  if ($FORM{set}) {
    #TODO: use if all good
    # require Internet::Services;
    # Internet::Services->import();
    # my $Triplay_services = Internet::Services->new($db, $admin, \%conf, {
    #   lang        => \%lang,
    #   permissions => \%permissions
    # });
    #
    # my $result = $Triplay_services->internet_user_chg_tp(\%FORM);
    # $Triplay->user_info($uid, { ID => $FORM{ID} });

    if ($Triplay->{DISABLE}) {
      my $service_status = ::sel_status({ HASH_RESULT => 1 });
      my ($status_name, undef) = split( /:/, $service_status->{ $Triplay->{DISABLE} } );
      $html->message('err', $lang{ERROR}, $lang{NOT_ACTIVE}. "\n$lang{STATUS}: $status_name", { ID => 1130947 });
      return 1;
    }

    my ($year, $month, $day) = split(/-/, $DATE, 3);
    if ($period > 0) {
      if ($period == 1) {
        ($year, $month, $day) = split(/-/, $Triplay->{ABON_DATE}, 3);
      }
      else {
        ($year, $month, $day) = split(/-/, $FORM{DATE}, 3);
      }

      my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

      if ($seltime <= time()) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} " . $html->color_mark("$lang{DATE}: $year-$month-$day", $_COLORS[6]));
        return 0;
      }
      elsif ($FORM{date_D} && $FORM{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} " . $html->color_mark("$lang{DATE}: $year-$month-$day", $_COLORS[6]));
        return 0;
      }

      my $comments = "$lang{FROM}: $Triplay->{TP_ID}:" .
        (($Triplay->{TP_NAME}) ? "$Triplay->{TP_NAME}" : q{}) . ((!$FORM{GET_ABON}) ? "\nGET_ABON=-1" : '')
        . ((!$FORM{RECALCULATE}) ? "\nRECALCULATE=-1" : '');

      $Shedule->add({
        UID          => $uid,
        TYPE         => 'tp',
        ACTION       => "$FORM{ID}:$FORM{TP_ID}",
        D            => $day,
        M            => $month,
        Y            => $year,
        MODULE       => 'Triplay',
        COMMENTS     => $comments,
        ADMIN_ACTION => 1
      });

      if (!_error_show($Shedule)) {
        $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $lang{CHANGED}");
        $Triplay->user_info({ UID => $uid, ID => $FORM{chg} });
      }
    }
    else {
      if ($Triplay->{ACTIVATE} && $Triplay->{ACTIVATE} ne '0000-00-00' && !$Triplay->{STATUS}) {
        $FORM{ACTIVATE} = $DATE;
      }

      $Triplay->user_change(\%FORM);

      if ($Triplay->{TP_INFO} && $Triplay->{TP_INFO}->{MONTH_FEE} && $Triplay->{TP_INFO}->{MONTH_FEE} < $users->{DEPOSIT}) {
        $Triplay->{STATUS} = 0;
        #$FORM{GET_ABON}=1;
        $FORM{ACTIVE_SERVICE} = 1;
      }

      if (!_error_show($Triplay, { RIZE_ERROR => 1 })) {
        #Take fees
        if (!$Triplay->{STATUS} && $FORM{GET_ABON}) {
          service_get_month_fee($Triplay, { SERVICE_NAME => 'Triplay', MODULE => 'Triplay' });
          if ($FORM{ACTIVE_SERVICE}) {
            $FORM{STATUS} = 0;
            #$Triplay->user_change(\%FORM);
          }
        }
        else {
          $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $message", { ID => 932 });
        }

        $Triplay_base->triplay_service_activate_web({ %FORM, USER_INFO => $users });
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del({
      UID => $uid,
      ID  => $FORM{SHEDULE_ID}
    });

    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  $Shedule->info({
    UID    => $uid,
    TYPE   => 'tp',
    MODULE => 'Triplay'
  });

  my $table;
  #Sheduler for TP change

  if ($FORM{del_Shedule} && $FORM{COMMENTS}) {
    $Shedule->del({ ID => $FORM{del_Shedule} });
    if (!_error_show($Shedule)) {
      $html->message('info', $lang{INFO}, "$lang{SHEDULE} $lang{DELETED} $FORM{del_Shedule}");
    }
    $Shedule->{TOTAL} = 1;
  }

  $table = $html->table({
    width   => '100%',
    caption => $lang{SHEDULE},
    title   => [ $lang{DATE}, $lang{TARIF_PLAN}, '-' ],
    ID      => 'TP_SHEDULE'
  });

  if ($Shedule->{TOTAL} > 0) {
    my $list = $Shedule->list({
      UID       => $uid,
      TYPE      => 'tp',
      DESCRIBE  => '_SHOW',
      MODULE    => 'Triplay',
      COLS_NAME => 1
    });

    my $TP_HASH = sel_tp({ USER_INFO => $users, MODULE => 'Triplay' });

    foreach my $line (@$list) {
      my $action = $line->{action};
      my $service_id = 0;
      if ($action =~ /:/) {
        ($service_id, $action) = split(/:/, $action);
      }

      $table->addrow("$line->{y}-$line->{m}-$line->{d}",
        "$service_id : " . ($TP_HASH->{$action} || q{$action}),
        $html->button($lang{DEL}, "index=$index&del_Shedule=$line->{id}&UID=$uid",
          { MESSAGE => "$lang{DEL} $line->{y}-$line->{m}-$line->{d}?", class => 'del' })
      );
    }

    $Tariffs->{SHEDULE_LIST} .= $table->show();
  }

  my $user_info = $users->pi({ UID => $uid });

  $Tariffs->{TARIF_PLAN_SEL} = sel_tp({
    CHECK_GROUP_GEOLOCATION => $user_info->{LOCATION_ID} || 0,
    USER_GID                => $user_info->{GID} || 0,
    MODULE                  => 'Triplay',
    USER_INFO               => $users,
    SELECT                  => 'TP_ID',
    SHOW_ALL                => 1,
    TP_ID                   => $Triplay->{TP_ID},
    GROUP_SORT              => 1,
    EX_PARAMS               => {
      SORT_VALUE     => 1, # Sort for sub groups
      SORT_KEY       => 1,
      GROUP_COLOR    => 1,
      MAIN_MENU      => $admin->{permissions}{4} ? get_function_index('triplay_tp') : undef,
      MAIN_MENU_ARGV => "TP_ID=" . ($Triplay->{TP_ID} || '')
    }
  });

  $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Triplay->{ABON_DATE} });

  $Tariffs->{ACTION} = 'set';
  $Tariffs->{LNG_ACTION} = $lang{CHANGE};

  $Tariffs->{UID} = $uid;
  $Tariffs->{ID} = $Triplay->{ID};
  $Tariffs->{TP_NAME} = ($Triplay->{TP_NUM} || q{}) . ': ' . ($Triplay->{TP_NAME} || '');

  if ($Triplay->{ID}) {
    $Tariffs->{MENU} = user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$Triplay->{ID}",
      UID                => $uid,
      MK_MAIN            => 1
    });
  }

  $html->tpl_show(templates('form_chg_tp'), $Tariffs);

  return 1;
}

#**********************************************************
=head2 triplay_get_services($attr) - in menu services

  Arguments:
    MODULE
    UID
    SELECT - SHOW Select form
    FIRST  -

  Returns:
    $service_id

=cut
#**********************************************************
sub triplay_get_services {
  my ($attr) = @_;
  my $service_id = 0 ;

  if (! $attr->{MODULE}) {
    return 0;
  }

  my $module = ucfirst($attr->{MODULE});
  require $module.'.pm';
  $module->import();

  my $Service = $module->new($db, $admin, \%conf);
  my $service_list;
  my $service_fn;
  if ($Service->can('user_list')) {
    $service_fn = 'user_list';
  }
  # elsif ($Service->can('list')) {
  #   $service_fn = 'list';
  # }

  $service_list = $Service->$service_fn({
    UID       => $attr->{UID},
    TP_ID     => '_SHOW',
    TP_NAME   => '_SHOW',
    GROUP_BY  => 'id',
    COLS_NAME => 1
  });

  if ($attr->{SELECT}) {
    my $select_id = $attr->{$attr->{SELECT}} || $FORM{$attr->{SELECT}} || q{};
    return '';
    $html->form_select($attr->{SELECT},
      {
        SELECTED => $select_id,
        SEL_LIST => $service_list,
        SEL_KEY  => 'id',
        SEL_VALUE=> 'tp_name,tp_id',
        MAIN_MENU => get_function_index(lc($attr->{MODULE}).'_user'),
        MAIN_MENU_ARGV => ($select_id) ? "chg=$select_id" : ''
      });
  }

  foreach my $service (@$service_list) {
    $service_id = $service->{id};
    if ($attr->{FIRST}) {
      last;
    }
  }

  return $service_id;
}


1;