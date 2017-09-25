=head1 NAME

  Internet users function

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(date_diff days_in_month in_array int2byte int2ip ip2int cmd);
require Internet::Stats;

our(
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  @MONTHES_LIT,
  @MONTHES,
  @WEEKDAYS,
  $ui
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Payments = Finance->payments($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);
my $Log      = Log->new($db, \%conf);

#**********************************************************
=head1 internet_user($attr) - Show user information

=cut
#**********************************************************
sub internet_user {
  my ($attr) = @_;

  my $uid = $FORM{UID} || $LIST_PARAMS{UID};
  delete($Internet->{errno});

  if ($FORM{CID} && $FORM{CID} !~ /ANY/i) {
    my $list = $Internet->list({
      LOGIN     => '_SHOW',
      CID       => $FORM{CID},
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]{uid} != $FORM{UID}) {
      $html->message('err', $lang{ERROR}, "CID/MAC: $FORM{CID} $lang{EXIST}. $lang{LOGIN}: " . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]{uid} ));
    }
  }
  if ($FORM{REGISTRATION_INFO}) {
    internet_registration_info();
    return 1;
  }
  elsif ($FORM{PASSWORD}) {
    internet_password_form({ %FORM });
    return 1;
  }
  elsif ($FORM{Shedule}) {

  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0;
    }

    if ((! $FORM{IP} || $FORM{IP} eq '0.0.0.0') && $FORM{STATIC_IP_POOL}) {
      $FORM{IP} = internet_get_static_ip($FORM{STATIC_IP_POOL});
    }
    elsif ($FORM{IP} && $FORM{IP} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && $FORM{IP} ne '0.0.0.0') {
      my $list = $Internet->list({
        LOGIN     => '_SHOW',
        IP        => $FORM{IP},
        COLS_NAME => 1
      });

      if ($Internet->{TOTAL} > 0 && $list->[0]{uid} != $uid) {
        $html->message('err', $lang{ERROR}, "IP: $FORM{IP} $lang{EXIST}. $lang{LOGIN}: " . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]{uid} ));
        return 0;
      }
    }
    $Internet->add(\%FORM);
    if (!$Internet->{errno}) {
      #Make month fee
      $Internet->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE} if ($attr->{USER_INFO});
      $Internet->info($uid);
      service_get_month_fee($Internet, { REGISTRATION => 1 }) if (!$FORM{STATUS});

      if($conf{MSG_REGREQUEST_STATUS} && ! $FORM{STATUS}) {
        msgs_unreg_requests_list({ UID => $uid, NOTIFY_ID => -1 });
      }

      if ($attr->{REGISTRATION}) {
        my $service_status = sel_status({ HASH_RESULT => 1 });
        my ($status, $color) = split( /:/, $service_status->{ $Internet->{STATUS} } );
        $Internet->{STATUS} = $html->color_mark( $status, $color );
        $html->tpl_show(_include('internet_user_info', 'Internet'), $Internet);
        return 1;
      }
      else {
        $html->message('info', $lang{INFO}, "$lang{ADDED}");
      }
    }
  }
  elsif ($FORM{del}) {
    $Internet->del(\%FORM);
    if (!$Internet->{errno}) {
      $html->message('info', $lang{INFO}, $lang{DELETED});
    }
  }
  elsif ($FORM{change} || $FORM{RESET}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    if (!$permissions{0}{18}) {
      delete $FORM{STATUS};
    }

    if ((! $FORM{IP} || $FORM{IP} eq '0.0.0.0') && $FORM{STATIC_IP_POOL}) {
      $FORM{IP} = internet_get_static_ip($FORM{STATIC_IP_POOL});
    }

    if ($FORM{IP} && $FORM{IP} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && $FORM{IP} ne '0.0.0.0') {
      my $list = $Internet->list({ IP => $FORM{IP}, LOGIN => '_SHOW', COLS_NAME => 1 });
      if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} != $uid) {
        $html->message('err', $lang{ERROR}, "IP: $FORM{IP} $lang{EXIST}. $lang{LOGIN}: " . $html->button("$list->[0]{login}", "index=15&UID=" . $list->[0]->{uid}));
        return 0;
      }
    }

    if ($FORM{RESET}) {
      $FORM{PASSWORD}='__RESET__';
      $html->message('info', $lang{INFO}, "$lang{PASSWD} $lang{RESETED}");
    }
    elsif ($FORM{newpassword}) {
      if (! $FORM{RESET_PASSWD} && length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
      }
      elsif ($FORM{newpassword} eq $FORM{confirm}) {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
      elsif ($FORM{newpassword} ne $FORM{confirm}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_CONFIRM}");
      }
    }

    $Internet->change({%FORM,
      DETAIL_STATS => $FORM{DETAIL_STATS} || 0,
      IPN_ACTIVATE => $FORM{IPN_ACTIVATE} || 0
    });

    if (defined($FORM{STATUS}) && $FORM{STATUS} == 0) {
      my $Shedule = Shedule->new($db, $admin, \%conf);
      my $list = $Shedule->list(
        {
          UID       => $uid,
          MODULE    => 'Internet',
          TYPE      => 'status',
          ACTION    => '0',
          COLS_NAME => 1
        }
      );

      if ($Shedule->{TOTAL} == 1) {
        $Shedule->del(
          {
            UID => $uid,
            IDS => $list->[0]->{shedule_id}
          }
        );
      }

      if ( $FORM{IPN_ACTIVATE}
        && $conf{IPN_DHCP_ACTIVE}
        && ($FORM{IP} && $FORM{IP} ne '0.0.0.0')
      ) {
        require Internet::Ipoe_mng;
        $FORM{ACTIVE} = 1;
        $FORM{NAS_ID} = undef;
        internet_ipoe_activate( {
          IP  => $FORM{IP},
          UID => $uid,
          ID  => $Internet->{ID}
        } );
      }

      #change reg request status to active
      if($conf{MSG_REGREQUEST_STATUS}) {
        msgs_unreg_requests_list({ UID => $uid, NOTIFY_ID => -1 });
      }
    }

    if (!$Internet->{errno}) {
      $Internet->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
      if (!$FORM{STATUS} && ($FORM{GET_ABON} || !$FORM{TP_ID})) {
        service_get_month_fee($Internet);
      }

      $FORM{chg} = $FORM{ID};
      $html->message('info', "Internet", "$lang{CHANGED}");
      return 0 if ($attr->{REGISTRATION});
    }
  }

  if (_error_show($Internet, { MODULE_NAME => 'Internet', ID => 901, MESSAGE => $Internet->{errstr} })) {
    return 1 if ($attr->{REGISTRATION});
  }
  elsif($Internet->{errno} && $attr->{REGISTRATION}) {
    return 1;
  }

  my $user_service_count = 0;
  if(! $FORM{add_form}) {
    $Internet->info($uid, {
      DOMAIN_ID => $users->{DOMAIN_ID},
      ID        => $FORM{chg}
    });

    $user_service_count=($FORM{chg}) ? 2 : $Internet->{TOTAL};
    $FORM{chg}=$Internet->{ID};
  }

  if (! $Internet->{TOTAL} || $Internet->{TOTAL} < 1) {
    $Internet->{TP_ADD} = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $Internet->{TP_ID} || $FORM{TP_ID} || '',
        SEL_LIST  => $Tariffs->list({ MODULE => 'Dv;Internet', NEW_MODEL_TP => 1, DOMAIN_ID => $users->{DOMAIN_ID}, COLS_NAME => 1 }),
        SEL_KEY   => 'tp_id'
      }
    );

    $Internet->{TP_DISPLAY_NONE} = "style='display:none'";

    if ($conf{INTERNET_LOGIN}) {
      $Internet->{LOGIN_FORM} .= $html->tpl_show(templates('form_row'), {
          ID => "INTERNET_LOGIN",
          NAME  => $lang{LOGIN},
          VALUE => $html->form_input('INTERNET_LOGIN', $Internet->{INTERNET_LOGIN} ) },
        { OUTPUT2RETURN => 1 });
    }

    if ($attr->{ACTION}) {
      $Internet->{ACTION}     = $attr->{ACTION};
      $Internet->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Internet->{ACTION}     = 'add';
      $Internet->{LNG_ACTION} = $lang{ACTIVATE};
      $html->message('warn', $lang{INFO}, $lang{NOT_ACTIVE});
    }

    #my $list = $Msgs->unreg_requests_list({ UID => $attr->{UID}, STATE => '!2', COLS_NAME => 1 });

    $Internet->{IP} = '0.0.0.0';
  }
  else {
    $Internet->{PASSWORD_BTN} = ($Internet->{PASSWORD}) ? $html->button("", "index=" . get_function_index('internet_user') . "&UID=$uid&PASSWORD=1&ID=$Internet->{ID}",
        { ICON => 'fa fa-key', ex_params => "data-tooltip='$lang{CHANGE} $lang{PASSWD}' data-tooltip-position='top'" }) :
      $html->button("", "index=" . get_function_index('internet_user') . "&UID=$uid&PASSWORD=1&ID=$Internet->{ID}",
        { ICON => 'fa fa-plus text-warning', ex_params => "data-tooltip='$lang{ADD} $lang{PASSWD}' data-tooltip-position='top'" });

    if ($FORM{pay_to}) {
      internet_pay_to({ Internet => $Internet });
      return 0;
    }

    if ($attr->{ACTION}) {
      $Internet->{ACTION}     = 'change';
      $Internet->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Internet->{ACTION}     = 'change';
      $Internet->{LNG_ACTION} = $lang{CHANGE};
    }

    if ($permissions{0}{10}) {
      $Internet->{CHANGE_TP_BUTTON} = $html->button($lang{CHANGE},
        'ID='. $Internet->{ID} .'&UID=' . $uid . '&index=' . get_function_index('internet_chg_tp'), { class => 'change' });
    }

    ($Internet->{NEXT_FEES_WARNING}, $Internet->{NEXT_FEES_MESSAGE_TYPE}) = internet_warning({
      USER     => $users,
      INTERNET => $Internet
    });

    $Internet->{NETMASK_COLOR} = ($Internet->{NETMASK} ne '255.255.255.255') ? 'bg-warning' : '';

    my $shedule_index    = get_function_index('internet_sheduler');
    if ($permissions{0}{4}) {
      $Internet->{SHEDULE} = $html->button( "",
        "UID=$uid&Shedule=status&index=".(($shedule_index) ? $shedule_index : $index + 4),
        { ICON => 'glyphicon glyphicon-calendar', TITLE => $lang{SHEDULE} } );
    }

    $Internet->{ONLINE_TABLE} = internet_user_online($uid);
    if(! $Internet->{ONLINE_TABLE}){
      $Internet->{LAST_LOGIN_MSG} = internet_user_error($Internet);
    }

    my $list = $admin->action_list({
      TYPE      => '4;8;9;14',
      UID       => $uid,
      MODULE    => 'Internet',
      DATETIME  => '_SHOW',
      PAGE_ROWS => 1,
      COLS_NAME => 1,
      SORT      => 'id',
      DESC      => 'desc'
    });

    if ($admin->{TOTAL}) {
      $list->[0]->{datetime} =~ /(\d{4}-\d{2}-\d{2})/;
      my $status_date = $1;

      my $days = ($status_date eq '0000-00-00') ? 0 : date_diff($status_date, $DATE);

      $Internet->{STATUS_INFO} = "$lang{FROM}: $status_date ($lang{DAYS}: $days)";
      if ($conf{INTERNET_REACTIVE_PERIOD}) {
        my ($period, $sum) = split(/:/, $conf{INTERNET_REACTIVE_PERIOD});
        $Internet->{STATUS_DAYS}  = $days if ($period < $days);
        $Internet->{REACTIVE_SUM} = $sum  if ($period < $days);
      }
    }

    $Internet->{DETAIL_STATS}      = ($Internet->{DETAIL_STATS} && $Internet->{DETAIL_STATS} == 1) ? ' checked' : '';
    $Internet->{IPN_ACTIVATE}      = ($Internet->{IPN_ACTIVATE}) ? 'checked' : '';
    $Internet->{REGISTRATION_INFO} = $html->button("", "qindex=$index&UID=$uid&REGISTRATION_INFO=1", { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-print', ex_params => 'target=_new' });

    if ($permissions{0} && $permissions{0}{14}) {
      $Internet->{DEL_BUTTON} =  $html->button( $lang{DEL}, "index=$index&del=1&UID=$uid&ID=$Internet->{ID}",
        {
          MESSAGE => "$lang{DEL} $lang{SERVICE} Internet $lang{FOR} $lang{USER} $uid?",
          class => 'btn btn-danger pull-right'
        });
    }

    if ($conf{INTERNET_TURBO_MODE}) {
      $Internet->{TURBO_MODE_SEL} = $html->form_select('TURBO_MODE',
        {
          SELECTED     => $Internet->{TURBO_MODE} || $FORM{TURBO_MODE},
          SEL_ARRAY    => [ $lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, ],
          ARRAY_NUM_ID => 1
        }
      );

      $Internet->{TURBO_MODE_FORM} = $html->tpl_show(templates('form_row'), {
          ID => "TURBO_MODE",
          NAME  => 'TURBO',
          VALUE => $Internet->{TURBO_MODE_SEL} },
        { OUTPUT2RETURN => 1 });

      $Internet->{TURBO_MODE_FORM} .= $html->tpl_show(templates('form_row'), {
          ID => "FREE_TURBO_MODE",
          NAME  => "TURBO $lang{COUNT}",
          VALUE => $html->form_input('FREE_TURBO_MODE', $Internet->{FREE_TURBO_MODE} ) },
        { OUTPUT2RETURN => 1 });
    }

    if ($conf{INTERNET_LOGIN}) {
      #With password

      #With password
      my $input = $html->element(
        'div',
        $html->form_input('INTERNET_LOGIN', $Internet->{INTERNET_LOGIN}, { OUTPUT2RETURN  => 1  } )
          . $html->element(
          'span',
          $Internet->{PASSWORD_BTN},
          { class => 'input-group-addon' }
        ),
        { class => 'input-group' }
      );

      $Internet->{LOGIN_FORM} .= $html->tpl_show(templates('form_row'), {
          ID    => 'INTERNET_LOGIN',
          NAME  => $lang{LOGIN} || q{},
          VALUE => $input || q{}
        },
        { OUTPUT2RETURN => 1 });
    }

    if ($conf{DOCS_PDF_PRINT}) {
      $Internet->{REGISTRATION_INFO_PDF} = $html->button("", "qindex=$index&UID=$uid&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-print' });
    }
  }

  $Internet->{STATUS_SEL} = sel_status({
    STATUS    => $Internet->{STATUS},
    EX_PARAMS => ( defined($Internet->{STATUS}) && ! $permissions{0}{18}) ? " disabled=disabled" : ''
  });

  my $service_status_colors=sel_status({ COLORS => 1 });

  if ($Internet->{STATUS} && $service_status_colors->[$Internet->{STATUS}]) {
    require Internet::Colors;
    Internet::Colors->import();
    $Internet->{STATUS_COLOR} = $service_status_colors->[$Internet->{STATUS}];
    # Gradient start
    $Internet->{STATUS_COLOR_GR_S} = Internet::Colors::darken_hex($service_status_colors->[$Internet->{STATUS}], 1.2);
    # Gradient finish
    $Internet->{STATUS_COLOR_GR_F} = Internet::Colors::darken_hex($service_status_colors->[$Internet->{STATUS}], 0.9);
  }

  #Join Service
  $Internet->{JOIN_SERVICE_FORM} = internet_join_service($Internet);

  $Internet->{STATIC_IP_POOL} = $html->form_select(
    'STATIC_IP_POOL',
    {
      SELECTED       => $FORM{STATIC_POOL} || 0,
      SEL_LIST       => $Nas->ip_pools_list({ STATIC => 1, COLS_NAME => 1 }),
      SEL_OPTIONS    => { '' => '' },
      MAIN_MENU      => get_function_index('form_ip_pools'),
      #MAIN_MENU_ARGV => "chg=". ($tarif_info->{IPPOOL} || ''),
      NO_ID          => 1
    }
  );

  my $total_fee = ($Internet->{MONTH_ABON} || 0)+($Internet->{DAY_ABON} || 0);

  if ($users->{REDUCTION}) {
    $total_fee = $total_fee * (100 - $users->{REDUCTION}) / 100;
  }

  if ($Internet->{STATUS} && $total_fee > $users->{DEPOSIT}) {
    my $sum=0;
    if ($Internet->{ABON_DISTRIBUTION} && ! $conf{INTERNET_FULL_MONTH}) {
      my $days_in_month = days_in_month({ DATE => $DATE });
      my $month_fee = ($total_fee / $days_in_month); # * ($days_in_month - $d);
      if ($month_fee > $users->{DEPOSIT}) {
        my $full_sum  = abs($month_fee - $users->{DEPOSIT});
        $sum = sprintf("%.2f", $full_sum);
        if($sum - $full_sum < 0) {
          $sum = sprintf("%.2f", int($sum + 1));
        }
      }
    }
    else {
      $sum =  sprintf("%.2f", abs($total_fee - $users->{DEPOSIT}));
      if ($sum < abs($total_fee - $users->{DEPOSIT})) {
        $sum = sprintf("%.2f", int($sum + 1));
      }
    }

    if ( $sum > 0 ) {
      $Internet->{PAYMENT_MESSAGE} = $html->message('warn', '', "$lang{ACTIVATION_PAYMENT} $sum " . $html->button($lang{PAYMENTS},
          "UID=$uid&index=2&SUM=$sum", { class => 'payments'}), { OUTPUT2RETURN => 1 } );
      $Internet->{HAS_PAYMENT_MESSAGE} = 1;
    }
  }

  if ($Internet->{NEXT_FEES_WARNING}) {
    $Internet->{NEXT_FEES_WARNING}=$html->message("$Internet->{NEXT_FEES_MESSAGE_TYPE}", "", $Internet->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 }) ;
  }

  if ($Internet->{INTERNET_EXPIRE} && $Internet->{INTERNET_EXPIRE} ne '0000-00-00') {
    if (date_diff($Internet->{INTERNET_EXPIRE}, $DATE) > 1) {
      $Internet->{EXPIRE_COLOR} = 'bg-danger';
      $Internet->{EXPIRE_COMMENTS}="$lang{EXPIRE}";
    }
  }

  if($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} != 0.00){
    $Internet->{PERSONAL_TP_MSG} = $html->message('info', "$lang{ACTIVE_PERSONAL} $lang{TARIF_PLAN}", '', {OUTPUT2RETURN=>1});
  }

  $Internet->{NAS_SEL} = $html->form_select(
    'NAS_ID',
    {
      SELECTED          => $Internet->{NAS_ID} || $FORM{NAS_ID},
      SEL_KEY           => 'nas_id',
      SEL_VALUE         => 'nas_name',
      SEL_OPTIONS       => { '' => '' },
      MAIN_MENU         => get_function_index( 'form_nas' ),
      MAIN_MENU_ARGV    => ($Internet->{NAS_ID}) ? "NAS_ID=$Internet->{NAS_ID}" : '',
      EXT_BUTTON        => $Internet->{SWITCH_STATUS},
      # Popup window
      POPUP_WINDOW      => 'form_search_nas',
      POPUP_WINDOW_TYPE => 'search',
      SEARCH_STRING     => 'POPUP=1&NAS_SEARCH=0'. (($uid) ? "&UID=$uid" : ''),
      HAS_NAME          => 1
    }
  );

  if ( in_array( 'Equipment', \@MODULES ) ){
    $Internet->{PORT}  = $Internet->{PORTS} if ($Internet->{PORTS});
    $Internet->{PORT_SEL} = $html->form_select(
      'PORT',
      {
        POPUP_WINDOW      => 'form_search_port',
        POPUP_WINDOW_TYPE => 'choose',
        SEARCH_STRING     => 'get_index=equipment_info&visual=0&header=2&PORT_SHOW=1&PORT_INPUT_NAME=PORT',
        VALUE             => $Internet->{PORT} || $FORM{PORT},
        SELECTED          => $Internet->{PORT} || $FORM{PORT},
        PARENT_INPUT      => 'NAS_ID'
      }
    );

    load_module('Equipment', $html);
    require Equipment;
    Equipment->import();
    my $Equipment = Equipment->new($db, $admin, \%conf);
    my $server_vlan_list = $Equipment->vlan_list({ PAGE_ROWS => 2000, COLS_NAME => 1 });

    if($Equipment->{TOTAL}) {
      $Internet->{VLAN_SEL} = $html->form_select(
        'SERVER_VLAN',
        {
          SELECTED       => $Internet->{SERVER_VLAN},
          SEL_LIST       => $server_vlan_list,
          SEL_KEY        => 'number',
          SEL_VALUE      => 'name',
          SEL_OPTIONS    => { '' => '--' },
          MAIN_MENU      => get_function_index('equipment_vlan'),
          MAIN_MENU_ARGV => ($Internet->{SERVER_VLAN}) ? "ID=$Internet->{SERVER_VLAN}" : '',
        }
      );
    }
    else {
      $Internet->{VLAN_SEL} = $html->form_input( 'SERVER_VLAN', ($Internet->{SERVER_VLAN} || q{}), { SIZE => 5 } );
    }

    $Internet->{EQUIPMENT_INFO} = equipment_user_info($Internet);
  }
  else{
    $Internet->{VLAN_SEL} = $html->form_input( 'SERVER_VLAN', ($Internet->{SERVER_VLAN} || q{}), { SIZE => 10 } );
    $Internet->{PORTS} = $html->form_input( 'PORTS', ($Internet->{PORTS} || q{}), { SIZE => 10 } );
  }

  my $nas_index = get_function_index( 'form_nas' );
  if ( $nas_index ){
    $Internet->{NAS_BUTTON} = $html->button( $lang{INFO}, "index=$nas_index&NAS_ID=". ($Internet->{NAS_ID} || ''),
      { class => 'show' } );
  }

  delete $FORM{pdf};

  my $menu = q{};
  if($Internet->{ID}) {
    $menu = user_service_menu({
      SERVICE_FUNC_INDEX => $index,
      PAGES_QS           => "&ID=$Internet->{ID}",
      UID                => $uid
    });
  }

  $html->tpl_show(_include('internet_user', 'Internet'), {
    %$admin,
    %$attr,
    %$Internet,
    UID  => $uid,
    MENU => $menu
    },
    { ID => 'internet_user' });

  if($user_service_count > 1) {
    internet_user_subscribes($Internet);
  }

  return 1;
}


#**********************************************************
=head2 internet_join_service($attr)

=cut
#**********************************************************
sub internet_join_service {
  my ($company_id)=@_;

  my $uid = $Internet->{UID};
  #Join Service
  if ($company_id) {
    my $join_services_users = q{};

    my $list = $Internet->list(
      {
        JOIN_SERVICE => 1,
        COMPANY_ID   => $company_id,
        COLS_NAME    => 1
      }
    );

    my $join_services_sel = $html->form_select(
      'JOIN_SERVICE',
      {
        SELECTED   => $Internet->{JOIN_SERVICE},
        SEL_LIST   => $list,
        SEL_KEY    => 'uid',
        SEL_VALUE  => 'login',
        SEL_OPTIONS=> { 1 => $lang{MAIN} },
        NO_ID      => undef
      }
    );

    if ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} == 1) {
      $list = $Internet->list(
        {
          JOIN_SERVICE => $uid,
          LOGIN        => '_SHOW',
          COMPANY_ID   => $company_id,
          PAGE_ROWS    => 1000,
          COLS_NAME    => 1
        }
      );

      foreach my $line (@$list) {
        $join_services_users .= $html->button("$line->{login}", "&index=15&UID=$line->{uid}", { BUTTON => 1 }). ' ';
      }
    }
    elsif ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) {
      $join_services_users = $html->button($lang{MAIN}, "index=15&UID=$Internet->{JOIN_SERVICE}", { BUTTON => 1 });
    }

    return $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), { ID => '',
        NAME  => $lang{JOIN_SERVICE},
        VALUE => "$join_services_sel $join_services_users"
      },
      { OUTPUT2RETURN => 1 });
  }
  else {
    return '';
  }
}

#**********************************************************
=head2 internet_password_form($attr)

=cut
#**********************************************************
sub internet_password_form {
  my ($attr) = @_;

  if($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  my $uid = $attr->{UID};
  my $password_form;
  $password_form->{PW_CHARS} = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
  $password_form->{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
  $password_form->{ACTION} = 'change';
  $password_form->{LNG_ACTION} = $lang{CHANGE};

  $password_form->{HIDDDEN_INPUT} = $html->form_input(
    'UID',
    $uid,
    {
      TYPE          => 'hidden',
      OUTPUT2RETURN => 1
    }
  );

  $password_form->{HIDDDEN_INPUT} .= $html->form_input(
    'ID',
    $attr->{ID},
    {
      TYPE          => 'hidden',
      OUTPUT2RETURN => 1
    }
  );

  $Internet->info($uid, { ID => $attr->{ID} });
  $password_form->{EXTRA_ROW} =  $html->tpl_show(templates('form_row'), { ID => '',
      NAME  => "$lang{PASSWD}",
      VALUE => $Internet->{PASSWORD}
    },
    { OUTPUT2RETURN => 1 });

  $password_form->{RESET_INPUT_VISIBLE} = 'block; ';
  $password_form->{ID}=$attr->{ID};

  $html->tpl_show(templates('form_password'), $password_form);

  return 1;
}


#**********************************************************
=head2

=cut
#**********************************************************
sub internet_user_online {
  my ($uid) = @_;

  my $list = $Sessions->online({
    UID                => $uid,
    CLIENT_IP          => '_SHOW',
    DURATION_SEC2      => '_SHOW',
    ACCT_INPUT_OCTETS  => '_SHOW',
    ACCT_OUTPUT_OCTETS => '_SHOW',
    NAS_NAME           => '_SHOW',
    NAS_PORT_ID        => '_SHOW',
    ACCT_SESSION_ID    => '_SHOW',
    USER_NAME          => '_SHOW',
    LAST_ALIVE         => '_SHOW',
    GUEST              => '_SHOW'
  });

  if ($Sessions->{TOTAL}) {
    my $online_index = get_function_index('internet_online');

    my $table = $html->table({
      caption => 'Online',
      ID      => 'INTERNET_ONLINE',
    });

    foreach my $line (@$list) {
      my $alive_check = '';

      if($conf{DV_ALIVE_CHECK}) {
        my $title = "$lang{LAST_UPDATE}: $line->{last_alive}";
        if ($line->{last_alive} > $conf{DV_ALIVE_CHECK} * 3) {
          $alive_check = $html->element('span', '', { title => $title, class => 'glyphicon glyphicon-warning-sign text-danger' });
        }
        elsif ($line->{last_alive} > $conf{DV_ALIVE_CHECK}) {
          $alive_check = $html->element('span', '', { title => $title, class => 'glyphicon glyphicon-warning-sign text-warning' });
        }
        else {
          $alive_check = $html->element('span', '', { title => $title, class => 'glyphicon glyphicon-ok-sign text-success' });
        }
      }

      my @row = (
        $alive_check . $line->{client_ip},
        _sec2time_str($line->{duration_sec2}),
        int2byte($line->{acct_input_octets}),
        int2byte($line->{acct_output_octets}),
          ($line->{guest} == 1) ? $html->color_mark($lang{GUEST}, 'bg-danger') : '',
        $html->button($line->{nas_name}, "index=$online_index&NAS_ID=$line->{nas_id}")
      );
      my @function_fields = ();
      if ($conf{INTERNET_EXTERNAL_DIAGNOSTIC}) {
        my @diagnostic_rules = split(/;/, $conf{INTERNET_EXTERNAL_DIAGNOSTIC});
        for (my $diag_num = 0; $diag_num <= $#diagnostic_rules; $diag_num++) {
          my ($name) = split(/:/, $diagnostic_rules[$diag_num]);

          if (!$name) {
            $name = 'Diagnostic ' . $diag_num;
          }
          push @function_fields, $html->button($name,
              "index=$online_index&diagnostic=$diag_num:$line->{client_ip}+$uid+$line->{nas_id}+$line->{nas_port_id}+$line->{acct_session_id}$pages_qs",
              { TITLE => "$name", BUTTON => 1, NO_LINK_FORMER => 1 });
        }
      }

      push @function_fields, $html->button('Z',
          "index=$online_index&zap=$uid+$line->{nas_id}+$line->{nas_port_id}+$line->{acct_session_id}$pages_qs",
          { TITLE => 'Zap', class => 'del', NO_LINK_FORMER => 1 }),
        $html->button('H',
          "index=$online_index&FRAMED_IP_ADDRESS=$line->{client_ip}&hangup=$line->{nas_id}+$line->{nas_port_id}+$line->{acct_session_id}+$line->{user_name}&$pages_qs",
          { TITLE => 'Hangup', class => 'off', NO_LINK_FORMER => 1 });

      $table->addrow(@row, join(' ', @function_fields));
    }

    return $table->show();
  }

  return q{};
}

#**********************************************************
=head2 internet_user_subscribes()

  Arguments:

  Results:

=cut
#**********************************************************
sub internet_user_subscribes {
  my($attr)=@_;

  if($attr->{UID}) {
    $LIST_PARAMS{GROUP_BY}='internet.id';
    my Abills::HTML $table ;
    ($table) = result_former({
      INPUT_DATA      => $Internet,
      FUNCTION        => 'list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => (($conf{INTERNET_LOGIN}) ? 'INTERNET_LOGIN,' : q{}) .'IP,TP_NAME,INTERNET_STATUS,ONLINE,ID',
      HIDDEN_FIELDS   => 'UID',
      FUNCTION_FIELDS => 'change',
      MAP             => 1,
      MAP_FIELDS      => 'ADDRESS_FLAT,LOGIN,DEPOSIT,FIO,TP_NAME,ONLINE',
      MAP_FILTERS     => { id => 'search_link:form_users:UID'
        #online => ''
      },
      #MULTISELECT     => ($permissions{0}{7}) ? 'IDS:uid:internet_users_list' : '',
      EXT_TITLES      => {
        'ip_num'      => 'IP',
        'netmask'     => 'NETMASK',
        'speed'       => $lang{SPEED},
        'port'        => $lang{PORT},
        'cid'         => 'CID',
        'filter_id'   => 'Filter ID',
        'tp_name'     => "$lang{TARIF_PLAN}",
        'internet_status'   => "Internet $lang{STATUS}",
        'internet_status_date' => "$lang{STATUS} $lang{DATE}",
        'online'      => 'Online',
        'online_ip'   => 'Online IP',
        'online_cid'  => 'Online CID',
        'online_duration'=> 'Online '. $lang{DURATION},
        'month_fee'   => $lang{MONTH_FEE},
        'day_fee'     => $lang{DAY_FEE},
        'internet_expire'   => "Internet $lang{EXPIRE}",
        'internet_activate' => "Internet $lang{ACTIVATE}",
        'internet_login'    => "$lang{SERVICE} $lang{LOGIN}",
        'internet_password' => "$lang{SERVICE} $lang{PASSWD}",
        'month_traffic_in'  => "$lang{MONTH} $lang{RECV}",
        'month_traffic_out' => "$lang{MONTH} $lang{SENT}",
        'id',               => 'ID'
      },
      SELECT_VALUE    => {
        #internet_status    => $service_status,
        #login_status => $service_status
      },
      FILTER_COLS  => {
        ip_num   => 'int2ip',
      },
      TABLE           => {
        width      => '100%',
        caption    => "$lang{INTERNET} - $lang{SERVICES}",
        qs         => $pages_qs,
        ID         => 'INTERNET_USERS_SUBSCRIBES',
        #header     => $status_bar,
        #SELECT_ALL => ($permissions{0}{7}) ? "internet_users_list:IDS:$lang{SELECT_ALL}" : undef,
        EXPORT     => 1,
        MENU       => "$lang{ADD}:index=" . get_function_index('internet_user')
          . "&UID=$LIST_PARAMS{UID}&add_form=1"
          . ':add' . ";$lang{SEARCH}:index=$index&search_form=1:search",
      },
      MAKE_ROWS     => 1,
      SEARCH_FORMER => 1,
      MODULE        => 'Internet',
      TOTAL         => 1,
      SHOW_MORE_THEN=>1,
      OUTPUT2RETURN =>1
    });

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 internet_pay_to($attr) - Pay to function

=cut
#**********************************************************
sub internet_pay_to {
  my ($attr) = @_;

  my $Internet_ = $attr->{Internet};

  if ($FORM{DATE}) {
    my ($from_year, $from_month, $from_day) = split(/-/, $DATE,       3);
    my ($to_year,   $to_month,   $to_day)   = split(/-/, $FORM{DATE}, 3);
    $Internet_->{ACTION_LNG} = "$lang{PAYMENTS}";
    $Internet_->{DATE}       = "$DATE - $FORM{DATE}";
    $Internet_->{SUM}        = 0.00;
    $Internet_->{DAYS}       = 0;

    if ($Internet_->{MONTH_ABON} && $Internet_->{ABON_DISTRIBUTION} || $Internet_->{DAY_ABON}) {
      if ($from_year . '-' . $from_month eq $to_year . '-' . $to_month) {
        $Internet_->{DAYS} = $to_day - $from_day + 1;
        my $days_in_month = days_in_month({ DATE => "$from_year-$from_month-01" });
        $Internet_->{SUM} = sprintf("%.2f", ($Internet_->{MONTH_ABON} / $days_in_month) * $Internet_->{DAYS});
      }
      elsif ("$from_year-$from_month" ne "$to_year-$to_month") {
        $from_day--;
        do {
          my $days_in_month = days_in_month({ DATE => "$from_year-$from_month-01" });
          my $month_days = ($from_month == $to_month) ? $to_day : $days_in_month - $from_day;
          $from_day      = 0;
          my $month_sum  = sprintf("%.2f", ($Internet_->{MONTH_ABON} / $days_in_month) * $month_days);

          $Internet_->{SUM}  += $month_sum;
          $Internet_->{DAYS} += $month_days;

          if ($from_month < 12) {
            $from_month = sprintf("%02d", $from_month + 1);
          }
          else {
            $from_month = sprintf("%02d", 1);
            $from_year += 1;
          }
        } while (($from_year < $to_year) || ($from_month <= $to_month && $from_year <= $to_year));
      }

      if($Internet_->{DAY_ABON}) {
        $Internet_->{SUM} += sprintf("%.2f", $Internet_->{DAY_ABON} * $Internet_->{DAYS});
      }
    }
    elsif ($Internet_->{MONTH_ABON}) {
      $Internet_->{SUM} = $Internet_->{MONTH_ABON};
    }
    else {
      $Internet_->{SUM} = 0;
    }
    $index = 2;

    if ($users->{REDUCTION}) {
      $Internet_->{SUM} = $Internet_->{SUM} * (100 - $users->{REDUCTION}) / 100;
    }
  }
  else {
    $Internet_->{ACTION_LNG} = $lang{RECALCULATE};
  }

  $html->tpl_show(_include('internet_pay_to', 'Internet'), $Internet);

  return 1;
}

#***************************************************************
=head2 internet_warning($attr) - Show warning message and tips

  Arguments:
    $attr
      INTERNET    - Dv object
      USER  - User object

=cut
#***************************************************************
sub internet_warning {
  my ($attr) = @_;
  my $warning = '';
  my $message_type = 'info';

  my $users_ = $attr->{USER};
  my $Internet_    = $attr->{INTERNET};

  $users_->{DEPOSIT} = 0 if (! $users_->{DEPOSIT} || $users_->{DEPOSIT} !~ /\d+/);
  $users_->{CREDIT} //= 0;

  if($Internet_->{EXPIRE} && $Internet_->{EXPIRE} ne '0000-00-00') {
    my $expire = date_diff($Internet_->{EXPIRE}, $DATE);
    if($expire >= 0) {
      $warning = "$lang{EXPIRE}: $Internet_->{EXPIRE}";
      $message_type ='err';
      return $warning, $message_type;
    }
  }
  elsif($Internet_->{JOIN_SERVICE} && $Internet_->{JOIN_SERVICE} > 1) {
    $message_type ='warn';
    return "$lang{JOIN_SERVICE}", $message_type;
  }

  if($Internet_->{PERSONAL_TP} && $Internet_->{PERSONAL_TP} > 0) {
    $Internet_->{MONTH_ABON} = $Internet_->{PERSONAL_TP};
  }

  $users_->{REDUCTION} = 0 if (! $Internet_->{REDUCTION_FEE});
  my $reduction_division = ($users_->{REDUCTION} >= 100) ? 0 : ((100 - $users_->{REDUCTION}) / 100);

  #use internet warning expr
  if ($conf{INTERNET_WARNING_EXPR}) {
    if ($conf{INTERNET_WARNING_EXPR}=~/CMD:(.+)/) {
      $warning = cmd($1, {
          PARAMS => {
            language => $html->{language},
            %{ $attr->{USER} },
            %{ $attr->{INTERNET} } }
        });
    }
  }
  elsif(! $reduction_division) {
    return '', $message_type;
  }
  # Get next payment period
  elsif (
    !$Internet_->{STATUS}
      && !$users_->{DISABLE}
      && ( $users_->{DEPOSIT} + (($users_->{CREDIT} > 0) ? $users_->{CREDIT} : ($Internet_->{TP_CREDIT} || 0)) > 0
      || ($Internet_->{POSTPAID_ABON} || 0)
      || ($Internet_->{PAYMENT_TYPE} && $Internet_->{PAYMENT_TYPE} == 1) )
  ){
    my $days_to_fees = 0 ;
    my ($from_year, $from_month, $from_day) = split(/-/, $DATE, 3);

    if ($Internet_->{REDUCTION_FEE} && $users_->{REDUCTION} == 100) {
      $warning = "$lang{NEXT_FEES}: -- $lang{REDUCTION}: 100%";
    }
    elsif ($Internet_->{MONTH_ABON} && $Internet_->{MONTH_ABON} > 0) {
      if ($Internet_->{ABON_DISTRIBUTION} && $Internet_->{MONTH_ABON} > 0) {
        my $days_in_month = 30;

        if ($users_->{ACTIVATE} eq '0000-00-00') {
          my ($y, $m, $d)=split(/-/, $DATE);
          my $rest_days    = 0;
          my $rest_day_sum = 0;
          my $deposit      = $users_->{DEPOSIT} + $users_->{CREDIT};

          while($rest_day_sum < $deposit) {
            $days_in_month   = days_in_month({ DATE => "$y-$m" });
            my $month_day_fee= ($Internet_->{MONTH_ABON} * $reduction_division) / $days_in_month;
            $rest_days    = $days_in_month - $d;
            $rest_day_sum    = $rest_days * $month_day_fee;

            if ($rest_day_sum > $deposit) {
              $days_to_fees += int($deposit / $month_day_fee);
            }
            else {
              $deposit = $deposit - $month_day_fee * $rest_days;
              $days_to_fees += $rest_days;
              $rest_day_sum = 0;
              $d = 1;
              $m++;
              if ($m > 12) {
                $m = 1;
                $y++;
              }
            }
          }
        }
        else {
          $days_to_fees = int(($users_->{DEPOSIT} + $users_->{CREDIT}) / (($Internet_->{MONTH_ABON} * $reduction_division) /  $days_in_month));
        }
        $warning = $lang{SERVICE_ENDED} || q{};
        $warning =~ s/\%DAYS\%/$days_to_fees/g;
      }
      else {
        #$warning = "$lang{NEXT_FEES}: ";
        if ($users_->{ACTIVATE} ne '0000-00-00') {
          my ($Y, $M, $D) = split(/-/, $users_->{ACTIVATE}, 3);
          if($Internet_->{FIXED_FEES_DAY}) {
            if ($M == 12) {
              $M = 0;
              $Y++;
            }

            $Internet_->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime(POSIX::mktime(0, 0, 12, $D, $M, ($Y - 1900), 0, 0, 0)));
          }
          else {
            $M--;
            $Internet_->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 12, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400)));
          }
        }
        else {
          my ($Y, $M, $D) = split(/-/, $DATE, 3);
          if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
          }
          else {
            $M++;
          }

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
          $Internet_->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        }

        $days_to_fees = date_diff($DATE, $Internet_->{ABON_DATE});
        if ($days_to_fees > 0) {
          $warning = $lang{NEXT_FEES_THROUGHT};
          $warning =~ s/\%DAYS\%/$days_to_fees/g;
        }
      }
    }
    elsif ($Internet_->{DAY_ABON} && $Internet_->{DAY_ABON} > 0) {
      $days_to_fees = int(($users_->{DEPOSIT} + $users_->{CREDIT} > 0) ?  ($users_->{DEPOSIT} + $users_->{CREDIT}) / ($Internet_->{DAY_ABON} * $reduction_division) : 0);
      $warning = $lang{SERVICE_ENDED};
      $warning =~ s/\%DAYS\%/$days_to_fees/g;
    }

    if ($days_to_fees && $days_to_fees < 5) {
      $message_type = 'warn'
    }
    if ($days_to_fees eq 0) {
      $message_type = 'err'
    }

    if ($days_to_fees > 0) {
      #Calculate days from net day
      my $expire_date = POSIX::strftime("%Y-%m-%d", localtime(POSIX::mktime(0, 0, 12, $from_day, ($from_month - 1), ($from_year - 1900))
          + 86400 * $days_to_fees + ($Internet_->{DAY_ABON} > 0 ? 86400 : 0)));
      $warning .= " ($expire_date)";
      $warning .= "\n$lang{SUM}: " . sprintf("%.2f", $Internet_->{MONTH_ABON} * $reduction_division) if($Internet_->{MONTH_ABON});
    }
    elsif ($Internet_->{INTERNET_EXPIRE} && $Internet_->{INTERNET_EXPIRE} ne '0000-00-00') {
      $Internet_->{SERVICE_EXPIRE_DATE}=$Internet_->{INTERNET_EXPIRE} if ($FORM{xml});
    }
  }

  return $warning, $message_type;
}

#**********************************************************
=head2 internet_get_static_ip($pool_id) - Get static ip from pool

  Arguments:
    $pool_id   - IP pool ID

  Returns:
    IP address

=cut
#**********************************************************
sub internet_get_static_ip {
  my ($pool_id) = @_;
  my $ip = '0.0.0.0';

  my $Ip_pool = $Nas->ip_pools_info($pool_id);

  if(_error_show($Ip_pool)) {
    return '0.0.0.0';
  }

  my $start_ip = ip2int($Ip_pool->{IP});
  my $end_ip   = $start_ip + $Ip_pool->{COUNTS};

  my %users_ips = ();

  my $list = $Internet->list({
    PAGE_ROWS => 1000000,
    IP        => ">=$Ip_pool->{IP}",
    SKIP_GID  => 1,
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    $users_ips{ $line->{ip_num} } = 1;
  }

  for (my $ip_cur = $start_ip ; $ip_cur <= $end_ip ; $ip_cur++) {
    if (! $users_ips{ $ip_cur }) {
      return int2ip($ip_cur);
    }
  }

  $html->message('err', $lang{ERROR}, "$lang{ERR_NO_FREE_IP_IN_POOL}");

  return $ip;
}

#**********************************************************
=head2 internet_test();

=cut
#**********************************************************
sub internet_test {

  if($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  if($FORM{test}) {
    require Control::Nas_mng;
    $FORM{runtest}=1;
    my $request = qq{User-Name=$ui->{LOGIN}};

    $Internet->info($FORM{UID});
    if ($Internet->{CID}) {
      $request .= "\nCalling-Station-Id=$Internet->{CID}";
    }

    form_nas_test(undef, {
        NAS_ID      => $FORM{NAS_ID},
        USER_TEST   => 1,
        RAD_REQUEST => $request,
      });
  }

  print $html->form_main({
    CONTENT => $html->form_select(
      'NAS_ID',
      {
        SELECTED       => $FORM{NAS_ID} || '',
        SEL_LIST       => $Nas->list({%LIST_PARAMS, COLS_NAME => 1, PAGE_ROWS => 10000}),
        SEL_KEY        => 'nas_id',
        SEL_VALUE      => 'nas_name',
        SEL_OPTIONS    => { '' => '== '. $lang{NAS} .' ==' },
      }
    ),
    HIDDEN => { index => $index,
      UID   => $FORM{UID},
      ID    => $FORM{ID},
    },
    SUBMIT => { test  => $lang{TEST} },
    class  => 'form-inline'
  });

  return 1;
}

#**********************************************************
=head2 internet_registration_info();

=cut
#**********************************************************
sub internet_registration_info {
  my ($uid)=@_;
  my %TRAFFIC_NAMES = ();

  # Info
  load_module('Docs', $html);
  $users    = Users->new($db, $admin, \%conf);
  $Internet = $Internet->info($uid);
  my $pi    = $users->pi({ UID => $uid });
  my $user  = $users->info($uid, { SHOW_PASSWORD => $permissions{0}{3} });
  ($Internet->{Y}, $Internet->{M}, $Internet->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
  $pi->{CONTRACT_DATE_LIT} = "$Internet->{D} " . $MONTHES_LIT[ int($Internet->{M}) - 1 ] . " $Internet->{Y} $lang{YEAR}";

  $Internet->{MONTH_LIT}         = $MONTHES_LIT[ int($Internet->{M}) - 1 ];
  if ($Internet->{Y}=~/(\d{2})$/) {
    $Internet->{YY}=$1;
  }

  my $value_list=$Conf->config_list({
    CUSTOM=> 1,
    COLS_NAME=>1
  });

  foreach my $line (@$value_list){
    $Internet->{"$line->{param}"}=$line->{value};
  }

  if (! $FORM{pdf}) {
    if (in_array('Mail', \@MODULES)) {
      load_module('Mail', $html);
      my $Mail = Mail->new($db, $admin, \%conf);
      my $list = $Mail->mbox_list({ UID => $uid });
      foreach my $line (@$list) {
        $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
        $user->{EMAIL_INFO}.=$html->tpl_show(_include('mail_user_info', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
      }
    }
  }

  #Show rest of prepaid traffic
  if ( $Sessions->prepaid_rest(
    {
      UID  => ($Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid,
      UIDS => $uid
    }
  )
  ) {
    my $list  = $Sessions->{INFO_LIST};

    my $i = 0;
    foreach my $line (@$list) {
      #my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $sessions->{REST}->{ $line->{traffic_class} };
      $Internet->{'PREPAID_TRAFFIC_'. $i .'_NAME'} = (($TRAFFIC_NAMES{ $line->{traffic_class} }) ? $TRAFFIC_NAMES{ $line->{traffic_class} } : '');
      $Internet->{'PREPAID_TRAFFIC_'. $i}          = $line->{prepaid};
      $Internet->{'TRAFFIC_PRICE_IN_'. $i}         = $line->{in_price};
      $Internet->{'TRAFFIC_PRICE_OUT_'. $i}        = $line->{out_price};
      $Internet->{'TRAFFIC_SPEED_IN_'. $i}         = $line->{in_speed};
      $Internet->{'TRAFFIC_SPEED_OUT_'. $i}        = $line->{out_speed};
      $i++;
    }
  }
  print $html->header();
  $Internet->{PASSWORD} = $user->{PASSWORD} if (! $Internet->{PASSWORD}) ;

  return $html->tpl_show(
    _include('internet_user_memo', 'Internet', { pdf => $FORM{pdf} }),
    {
      %$user,
      %$pi,
      DATE => $DATE,
      TIME => $TIME,
      %$Internet,
    }
  );
}

#**********************************************************
=head2 internet_form_shedule() - Shedule form for Internet modules

=cut
#**********************************************************
sub internet_form_shedule {

  if($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  my $Shedule = Shedule->new($db, $admin, \%conf);

  if ($FORM{add} && $permissions{0}{18}) {
    my ($Y, $M, $D) = split(/-/, ($FORM{DATE} || $DATE), 3);

    $Shedule->add(
      {
        UID    => $FORM{UID},
        TYPE   => $FORM{Shedule} || q{},
        ACTION => $FORM{ACTION},
        D      => $D,
        M      => $M,
        Y      => $Y,
        MODULE => 'Internet'
      }
    );

    if (! _error_show($Shedule, { ID => 971 })) {
      $html->message('info', $lang{CHANGED}, "$lang{SHEDULE} $lang{ADDED}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $permissions{0}{18}) {
    $Shedule->del({ ID => $FORM{del} });
    if (! _error_show($Shedule->{errno})) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]");
    }
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });

  if ($FORM{Shedule} && $FORM{Shedule} eq 'status' && $permissions{0}{18}) {
    my @rows = (
      " $lang{FROM}: ",
      $html->date_fld2('DATE', {
          NEXT_DAY  => 1,
          FORM_NAME => 'Shedule',
          MONTHES   => \@MONTHES,
          FORM_NAME => 'Shedule',
          WEEK_DAYS => \@WEEKDAYS }),
      " $lang{STATUS}: ",
      $html->form_select('ACTION', {
          SELECTED   => $FORM{ACTION},
          SEL_HASH   => $service_status,
          USE_COLORS => 1,
          NO_ID      => 1
        }
      ),
      $html->form_input('add', $lang{ADD}, { TYPE => 'submit' })
    );

    my $info = '';
    foreach my $val ( @rows ) {
      $info .= $html->element('div', $val, { class => 'form-group' });
    }

    print $html->form_main(
      {
        CONTENT => $html->element('div', $info, { class => 'well well-sm' }),
        HIDDEN  => {
          sid     => $sid,
          index   => $index,
          Shedule => "status",
          UID     => $FORM{UID},
        },
        NAME  => 'Shedule',
        ID    => 'Shedule',
        class => 'form-inline'
      }
    );
  }

  #my $service_status_colors = sel_status({ COLORS => 1 });
  my $list = $Shedule->list(
    {
      UID    => $FORM{UID},
      MODULE => 'Internet'
    }
  );

  my $table = $html->table({
    width      => '100%',
    title      => [ $lang{HOURS}, $lang{DAY}, $lang{MONTH}, $lang{YEAR}, $lang{COUNT}, $lang{USER}, $lang{TYPE},
      $lang{VALUE}, $lang{MODULES}, $lang{ADMINS}, $lang{CREATED}, "-" ],
    qs         => $pages_qs,
    pages      => $Shedule->{TOTAL},
    ID         => 'INTERNET_SHEDULE'
  });

  foreach my $line (@$list) {
    my $delete = ($permissions{0}{4}) ? $html->button($lang{DEL}, "index=$index&del=$line->[14]&UID=$line->[13]",
        { MESSAGE => "$lang{DEL} [$line->[13]]?", class => 'del', TEXT => $lang{DEL} }) : '-';

    $table->addrow(
      $html->b($line->[0]),
      $line->[1],
      $line->[2],
      $line->[3],
      $line->[4],
      $html->button($line->[5], "index=15&UID=$line->[13]"),
      $line->[6],
        ($line->[6] eq 'status') ? $html->color_mark($service_status->{ $line->[7] }) : $line->[7],
      $line->[8],
      $line->[9],
      $line->[10],
      $delete
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows => [ [ "$lang{TOTAL}:", $html->b($Shedule->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_chg_tp($attr) - Change user tariff plan from admin interface

=cut
#**********************************************************
sub internet_chg_tp {
  my ($attr) = @_;

  my $user;
  my $uid = 0;
  if (defined($attr->{USER_INFO})) {
    $user = $attr->{USER_INFO};
    $uid = $user->{UID};
    $Internet   = $Internet->info($uid,
      { DOMAIN_ID => $user->{DOMAIN_ID}, ID => $FORM{ID} });
    if ($Internet->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}");
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST}");
    return 0;
  }

  if (!$permissions{0}{10}) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
    return 1;
  }

  #my $TARIF_PLAN = $FORM{tarif_plan} || $lang{DEFAULT_TARIF_PLAN};
  my $period  = $FORM{period}     || 0;
  my $Shedule = Shedule->new($db, $admin, \%conf);

  #Get next period
  if (
    ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0)
      && !$Internet->{STATUS}
      && !$users->{DISABLE}
      && ( ($users->{DEPOSIT}?$users->{DEPOSIT}:0) + ($users->{CREDIT}?$users->{CREDIT}:0) > 0
      || $Internet->{POSTPAID_ABON}
      || ($Internet->{PAYMENT_TYPE} && $Internet->{PAYMENT_TYPE} == 1))
  )
  {
    if ($users->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $users->{ACTIVATE}, 3);
      $M--;
      $Internet->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
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
      $Internet->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  my $message='';
  if ($FORM{set}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0;
    }

    my ($year, $month, $day) = split(/-/, $DATE, 3);
    if ($period > 0) {
      if ($period == 1) {
        ($year, $month, $day) = split(/-/, $Internet->{ABON_DATE}, 3);
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

      $Shedule->add(
        {
          UID          => $uid,
          TYPE         => 'tp',
          ACTION       => $FORM{TP_ID},
          D            => $day,
          M            => $month,
          Y            => $year,
          MODULE       => 'Internet',
          COMMENTS     => "$lang{FROM}: $Internet->{TP_ID}:".
            (($Internet->{TP_NAME}) ? "$Internet->{TP_NAME}" : q{})  . ((! $FORM{GET_ABON}) ? "\nGET_ABON=-1" : '' ) . ((! $FORM{RECALCULATE}) ? "\nRECALCULATE=-1" : ''),
          ADMIN_ACTION => 1
        }
      );

      if (! _error_show($Shedule) ) {
        $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $lang{CHANGED}");
        $Internet->info($uid, { ID => $FORM{chg} });
      }
    }
    else {
      $Internet->change({%FORM});
      if (! _error_show($Internet, { RIZE_ERROR => 1 }) ) {
        #Take fees
        #Message
        if (!$Internet->{STATUS} && $FORM{GET_ABON}) {
          $Internet->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
          service_get_month_fee($Internet);
        }
        else {
          $html->message('info', $lang{CHANGED}, "$lang{TARIF_PLAN} $message", { ID => 932 });
        }

        #$Internet->info($uid, { ID => $FORM{ID} });
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del(
      {
        UID => $uid,
        ID  => $FORM{SHEDULE_ID}
      }
    );

    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  $Shedule->info(
    {
      UID      => $uid,
      TYPE     => 'tp',
      MODULE   => 'Internet'
    }
  );

  if ($Shedule->{TOTAL} > 0 && !$conf{INTERNET_TP_MULTISHEDULE}) {
    my $table = $html->table(
      {
        width      => '100%',
        caption    => "$lang{SHEDULE}",
        rows       => [ [ "$lang{TARIF_PLAN}:", "$Shedule->{ACTION}" ],
          [ "$lang{DATE}:", "$Shedule->{D}-$Shedule->{M}-$Shedule->{Y}" ],
          [ "$lang{ADMIN}:", "$Shedule->{ADMIN_NAME}" ],
          [ "$lang{ADDED}:", "$Shedule->{DATE}" ],
          [ "ID:", "$Shedule->{SHEDULE_ID}" ] ]
      }
    );
    $Tariffs->{TARIF_PLAN_SEL} = $table->show() . $html->form_input('SHEDULE_ID', "$Shedule->{SHEDULE_ID}", { TYPE => 'HIDDEN' });
    $Tariffs->{ACTION}         = 'del';
    $Tariffs->{LNG_ACTION}     = $lang{DEL};
  }
  else {
    my $tp_list = $Tariffs->list({
      MODULE        => 'Dv;Internet',
      DOMAIN_ID     => $users->{DOMAIN_ID} || $admin->{DOMAIN_ID},
      COMMENTS      => '_SHOW',
      TP_GROUP_NAME => '_SHOW',
      COLS_NAME     => 1
    });

    my $table;
    #Sheduler fot TP change
    if ($conf{INTERNET_TP_MULTISHEDULE}) {
      if ($FORM{del_Shedule} && $FORM{COMMENTS}) {
        $Shedule->del({ ID => $FORM{del_Shedule} });
        if (! _error_show($Shedule)) {
          $html->message('info', $lang{INFO}, "$lang{SHEDULE} $lang{DELETED} $FORM{del_Shedule}");
        }
        $Shedule->{TOTAL} = 1;
      }

      $table = $html->table({
        width      => '100%',
        caption    => $lang{SHEDULE},
        title      => [ $lang{DATE}, $lang{TARIF_PLAN}, '-' ],
        ID         => 'TP_SHEDULE'
      });

      if ($Shedule->{TOTAL} > 0) {
        my $list = $Shedule->list({
          UID      => $uid,
          TYPE     => 'tp',
          DESCRIBE => '_SHOW',
          MODULE   => 'Internet'
        });

        my %TP_HASH = ();
        foreach my $line (@$tp_list) {
          $TP_HASH{ $line->{tp_id} } = "$line->{id} : $line->{name}";
        }

        foreach my $line (@$list) {
          $table->addrow("$line->[3]-$line->[2]-$line->[1]",
            "$line->[7] : $TP_HASH{$line->[7]}",
            $html->button($lang{DEL}, "index=$index&del_Shedule=$line->[14]&UID=$uid", { MESSAGE => "$lang{DEL} $line->[3]-$line->[2]-$line->[1]?", class => 'del' })
          );
        }

        $Tariffs->{SHEDULE_LIST} .= $table->show();
      }
    }

    # GID:ID=>NAME
    my %TPS_HASH = ();
    foreach my $line (@$tp_list) {
      $TPS_HASH{($line->{tp_group_name} || '')}{ $line->{tp_id} } = "$line->{id} $line->{name}";
    }

    $Tariffs->{TARIF_PLAN_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED          => $Internet->{TP_ID},
        SEL_HASH          => \%TPS_HASH,
        GROUP_COLOR       => 1,
        MAIN_MENU         => ($permissions{0}{10}) ? get_function_index('internet_tp') : undef,
        MAIN_MENU_ARGV    => "TP_ID=". ($Internet->{TP_ID} || '')
      }
    );

    $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Internet->{ABON_DATE} });

    if ($permissions{0}{4}) {
      $Tariffs->{ACTION} = 'set';
    }

    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
  }

  $Tariffs->{UID}     = $uid;
  $Tariffs->{ID}      = $Internet->{ID};
  $Tariffs->{TP_NAME} = ($Internet->{TP_NUM} || q{}).':'. ($Internet->{TP_NAME} || '');

  if($Internet->{ID}) {
    $Tariffs->{MENU}  = user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $uid,
      MK_MAIN            => 1
    });
  }

  $html->tpl_show(templates('form_chg_tp'), $Tariffs);

  return 1;
}

#**********************************************************
=head2 internet_user_del($uid, $attr) Delete user from module

=cut
#**********************************************************
sub internet_user_del {
  my ($uid, $attr) = @_;

  $Internet->{UID} = $uid;
  $Internet->del({ UID => $uid });
  $Log->log_del({ LOGIN => $attr->{LOGIN} });

  return 0;
}

#**********************************************************
=head2 internet_compensation($attr)

=cut
#**********************************************************
sub internet_compensation {
  my ($attr) = @_;

  if($FORM{ID}) {
    print user_service_menu({
      SERVICE_FUNC_INDEX => get_function_index('internet_user'),
      PAGES_QS           => "&ID=$FORM{ID}",
      UID                => $FORM{UID},
      MK_MAIN            => 1
    });
  }

  if ($FORM{add} && $FORM{FROM_DATE}) {
    my ($FROM_Y, $FROM_M, $FROM_D) = split(/-/, $FORM{FROM_DATE}, 3);
    #my $from_date = POSIX::mktime(0, 0, 0, $FROM_D, ($FROM_M - 1), ($FROM_Y - 1900), 0, 0, 0);

    my ($TO_Y, $TO_M, $TO_D) = split(/-/, $FORM{TO_DATE}, 3);

    #my $to_date = POSIX::mktime(0, 0, 0, $TO_D, ($TO_M - 1), ($TO_Y - 1900), 0, 0, 0);
    my $sum = 0.00;
    my $days = 0;
    my $days_in_month = 31;
    my $uid = $users->{UID} || $user->{UID} || $FORM{UID};

    $Internet->info($uid);

    my $table = $html->table(
      {
        width       => '400',
        caption     => "$lang{COMPENSATION} $lang{FROM}: $FORM{FROM_DATE} $lang{TO}: $FORM{TO_DATE}",
        title_plain => [ $lang{MONTH}, $lang{DAYS}, $lang{SUM} ],
        ID          => 'INTERNET_COMPENSATION_DESCRIBE'
      }
    );

    $Internet->{DAY_ABON} //= 0;
    $Internet->{MONTH_ABON} //= 0;

    if ($users->{ACTIVATE} && $users->{ACTIVATE} ne '0000-00-00') {
      $days = date_diff($FORM{FROM_DATE}, $FORM{TO_DATE});
      $sum = $days * ($Internet->{MONTH_ABON} / 30);
      if ($Internet->{DAY_ABON} > 0 && !$attr->{HOLD_UP}) {
        $sum += $days * $Internet->{DAY_ABON};
      }
    }
    else {
      if ("$FROM_Y-$FROM_M" eq "$TO_Y-$TO_M") {
        $days = $TO_D - $FROM_D;
        $days_in_month = days_in_month({ DATE => "$FROM_Y-$FROM_M-01" });
        $sum = sprintf("%.2f", $days * ($Internet->{DAY_ABON}) + $days * (($Internet->{MONTH_ABON} || 0) / $days_in_month));
        $table->addrow("$FROM_Y-$FROM_M", $days, $sum);
      }
      elsif ("$FROM_Y-$FROM_M" ne "$TO_Y-$TO_M") {
        $FROM_D--;
        do {
          $days_in_month = days_in_month({ DATE => "$FROM_Y-$FROM_M-01" });
          my $month_days = ($FROM_M == $TO_M) ? $TO_D : $days_in_month - $FROM_D;
          $FROM_D = 0;
          my $month_sum = sprintf("%.2f",
            $month_days * $Internet->{DAY_ABON} + $month_days * ($Internet->{MONTH_ABON} / $days_in_month));
          $sum += $month_sum;
          $days += $month_days;
          $table->addrow("$FROM_Y-$FROM_M", $month_days, $month_sum);

          if ($FROM_M < 12) {
            $FROM_M = sprintf("%02d", $FROM_M + 1);
          }
          else {
            $FROM_M = sprintf("%02d", 1);
            $FROM_Y += 1;
          }

          if ($attr->{HOLD_UP}) {
            return 1;
          }
        } while (($FROM_Y < $TO_Y) || ($FROM_M <= $TO_M && $FROM_Y == $TO_Y));
      }
    }

    if ($users->{REDUCTION}) {
      $sum = $sum - (($sum / 100) * $users->{REDUCTION});
    }

    $table->{color} = $_COLORS[3];

    $table->addrow($html->b("$lang{TOTAL}:"), $html->b("$days"), $html->b("$sum"));
    $Payments->add(
      {
        BILL_ID => $users->{BILL_ID} || $user->{BILL_ID},
        UID     => $uid
      },
      {
        SUM            => $sum,
        METHOD         => 6,
        DESCRIBE       =>
        "$lang{COMPENSATION}. $lang{DAYS}: $FORM{FROM_DATE}/$FORM{TO_DATE} ($days)".(($FORM{DESCRIBE}) ? ". $FORM{DESCRIBE}" : '')
        ,
        INNER_DESCRIBE => $FORM{INNER_DESCRIBE}
      }
    );

    if (!_error_show($Payments)) {
      $html->message('info', "$lang{COMPENSATION}", "$lang{COMPENSATION} $lang{SUM}: $sum");
      print $table->show();
    }

    if ($attr->{QUITE}) {
      return 0;
    }
  }

  $html->tpl_show(_include('internet_compensation', 'Internet'), { %FORM, %$Internet });

  return 1;
}

#**********************************************************
=head2 internet_user_error($Internet_) - last user auth

=cut
#**********************************************************
sub internet_user_error {
  my ($Internet_) = @_;

  if ($conf{INTERNET_SKIP_SHOW_QUICK_ERRORS}) {
    return '';
  }

  my $message = '';

  my $error_logs = $Log->log_list({
    COLS_NAME => 1,
    LOGIN     => ($conf{INTERNET_LOGIN} && $Internet_->{INTERNET_LOGIN}) ? $Internet_->{INTERNET_LOGIN} : $ui->{LOGIN},
    SORT      => 'date',
    DESC      => 'DESC',
    PAGE_ROWS => 1
  });

  if ($Log->{TOTAL}) {
    if($error_logs->[0]->{log_type} > 4){
      if( $error_logs->[0]->{action} eq 'HANGUP'     ||
        $error_logs->[0]->{action} eq 'LOST_ALIVE' ||
        $error_logs->[0]->{action} eq 'CALCULATIO'){
        $message = $html->message('warning', '', "$error_logs->[0]->{action} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", {OUTPUT2RETURN => 1});
      }
      else{
        $message = $html->message('info', '', "$lang{LAST_AUTH} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", {OUTPUT2RETURN => 1});
      }
    }
    else{

      if( $error_logs->[0]->{action} eq 'HANGUP'     ||
        $error_logs->[0]->{action} eq 'LOST_ALIVE' ||
        $error_logs->[0]->{action} eq 'CALCULATIO' ){
        $message = $html->message('warning', '', "$error_logs->[0]->{action} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", {OUTPUT2RETURN => 1});
      }
      else{
        $message .= $html->message('err', "$lang{LAST_AUTH} $lang{DATE} $error_logs->[0]->{date} $error_logs->[0]->{message}", '', {OUTPUT2RETURN => 1});
        $error_logs = $Log->log_list({
          COLS_NAME => 1,
          LOGIN     => ($conf{INTERNET_LOGIN} && $Internet_->{INTERNET_LOGIN}) ? $Internet_->{INTERNET_LOGIN} : $ui->{LOGIN},
          LOG_TYPE  => 6,
          SORT      => 'date',
          DESC      => 'DESC',
          PAGE_ROWS => 1
        });

        if($Log->{TOTAL}) {
          $message .= $html->message('info', '', "$lang{LAST_SUCCES_AUTH} $error_logs->[0]->{date} $error_logs->[0]->{message}", {OUTPUT2RETURN => 1});
        }
      }
    }
  }

  return $message;
}


1;