=head2 NAME

  Dv User portal

=cut

use warnings;
use strict;
use Abills::Base qw(sec2time in_array convert int2byte ip2int int2ip date_diff show_hash);
use Abills::Filters qw(_mac_former);

require Internet::Stats;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  @WEEKDAYS,
  @MONTHES
);

our Users $user;

my $Internet = Internet->new($db, $admin, \%conf);
my $Fees     = Fees->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Log      = Log->new($db, \%conf);


#**********************************************************
=head2 internet_user_info()

=cut
#**********************************************************
sub internet_user_info {

  my $service_status = sel_status({ HASH_RESULT => 1 });
  our $Isg;
  if ($conf{INTERNET_ISG}) {
    require Dv::Cisco_isg;
    #Check deposit and disable STATUS
    my $list = $Internet->list(
      {
        LOGIN          => $user->{LOGIN},
        CREDIT         => '_SHOW',
        DEPOSIT        => '_SHOW',
        INTERNET_STATUS=> '_SHOW',
        TP_NAME        => '_SHOW',
        TP_CREDIT      => '>0',
        PAYMENTS_TYPE  => 0,
        COLS_NAME      => 1
      }
    );

    if ($Internet->{TOTAL} < 1) {

    }
    elsif (($list->[0]->{credit} > 0 && ($list->[0]->{deposit} + $list->[0]->{credit} < 0))
      || ($list->[0]->{credit} == 0 && $list->[0]->{deposit} + $list->[0]->{credit}) < 0)
    {
      form_neg_deposit($user);
      return 0;
    }
    elsif ($list->[0]->{internet_status} && $list->[0]->{internet_status} == 1) {
      $html->message('err', $lang{ERROR}, "$lang{SERVICES} '$list->[0]->{tp_name}' $lang{DISABLE}", { ID => 15 });
      return 0;
    }

    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-status-query", { USER_NAME => $user->{LOGIN} })) {
      return 0;
    }

    if ($Isg->{ISG_CID_CUR}) {
      #change speed (active turbo mode)
      if ($FORM{SPEED}) {
        if ($Isg->{CURE_SERVICE} =~ /TP/ || !$Isg->{TURBO_MODE_RUN}) {
          my $service_name = 'TURBO_SPEED' . $FORM{SPEED};

          #Deactive cure service (TP Service)
          if ($Isg->{CURE_SERVICE} =~ /TP/) {
            if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "deactivate-service", { USER_NAME    => $user->{LOGIN},
                CURE_SERVICE => $Isg->{CURE_SERVICE},
                SERVICE_NAME => $service_name  })) {

            }
          }

          #Activate service
          if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "deactivate-service", { USER_NAME => $user->{LOGIN}, SERVICE_NAME => $service_name })) {
            return 0;
          }
        }
        elsif ($Isg->{TURBO_MODE_RUN}) {
          $html->message('info', $lang{INFO}, "TURBO $lang{MODE} $lang{ENABLE}");
        }
      }
    }
  }
  # Users autoregistrations
  elsif ($conf{INTERNET_IP_DISCOVERY}) {
    if(! internet_discovery($user->{REMOTE_ADDR})) {
      return 0;
    }
  }

  my $uid = $LIST_PARAMS{UID};

  $Internet->info($uid, { DOMAIN_ID => $user->{DOMAIN_ID} });

  if ($FORM{activate}) {
    #my $old_status = $Internet->{STATUS};
    $Internet->change({
      UID    => $uid,
      STATUS => 0,
      CID    => ($Isg->{ISG_CID_CUR}) ? $Isg->{ISG_CID_CUR} : undef,
      ACTIVATE => ($conf{INTERNET_USER_ACTIVATE_DATE}) ? $DATE : undef
    });

    if (!$Internet->{errno}) {
      $Internet->{ACCOUNT_ACTIVATE}=$user->{ACTIVATE};
      $html->message('info', $lang{INFO}, "$lang{ACTIVATE} CID: $Isg->{ISG_CID_CUR}") if ($Isg->{ISG_CID_CUR});
      if (!$Internet->{STATUS}) {
        service_get_month_fee($Internet);
      }
    }
    else {
      $html->message('err', $lang{ACTIVATE}, "$lang{ERROR} CID: $Isg->{ISG_CID_CUR}", { ID => 102 });
    }

    #Log on
    if($conf{INTERNET_ISG}) {
      if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
        { USER_NAME => $user->{LOGIN},
          #'User-Password' => '123456'
        })) {
        return 0;
      }
    }
  }
  elsif ($FORM{logon}) {
    #Logon
    if (!cisco_isg_cmd($user->{REMOTE_ADDR}, "account-logoff",
      { USER_NAME => $user->{LOGIN},
      })) {
      return 0;
    }
  }
  #  elsif ($FORM{discovery}) {
  #    if (internet_dhcp_get_mac_add($user->{REMOTE_ADDR}, $DHCP_INFO)) {
  #      $html->message('info', $lang{INFO}, "$lang{ACTIVATE}\n\n IP: $Dv->{NEW_IP}\n CID: $DHCP_INFO->{MAC}");
  #    }
  #  }
  elsif ($FORM{hangup}) {
    require Abills::Nas::Control;
    Abills::Nas::Control->import();
    my $Nas_cmd = Abills::Nas::Control->new($db, \%conf);

    $Nas_cmd->hangup(
      $Nas,
      0,
      $user->{LOGIN},
      {
        ACCT_SESSION_ID      => '',
        FRAMED_IP_ADDRESS    => $user->{REMOTE_ADDR},
        UID                  => $user->{UID},
        USER_INFO            => $user->{LOGIN},
        CID                  => 'User hangup',
        ACCT_TERMINATE_CAUSE => 1
      }
    );
  }

  $user->{INTERNET_STATUS} = $Internet->{STATUS};

  if ($Internet->{TOTAL} < 1) {
    $html->message('info', "Internet $lang{SERVICE}", "$lang{NOT_ACTIVE}", { ID => 17 });
    return 0;
  }

  ($Internet->{NEXT_FEES_WARNING}, $Internet->{NEXT_FEES_MESSAGE_TYPE}) = internet_warning({
    USER     => $user,
    INTERNET => $Internet
  });

  if ($Internet->{NEXT_FEES_WARNING}) {
    $Internet->{NEXT_FEES_WARNING}=$html->message("$Internet->{NEXT_FEES_MESSAGE_TYPE}", "", $Internet->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 }) ;
  }

  # Check for sheduled tp change
  my $sheduled_tp_actions_list = $Shedule->list({
    UID       => $user->{UID},
    TYPE      => 'tp',
    MODULE    => 'Internet',
    COLS_NAME => 1
  });

  if ($sheduled_tp_actions_list && ref $sheduled_tp_actions_list eq 'ARRAY' && scalar @$sheduled_tp_actions_list){
    my $next_tp_action = $sheduled_tp_actions_list->[0];
    my $next_tp_id = $next_tp_action->{action};
    my $next_tp_date = "$next_tp_action->{y}-$next_tp_action->{m}-$next_tp_action->{d}";

    # Get info about next TP
    my $tp_list = $Tariffs->list({
      TP_ID     => $next_tp_id,
      NAME      => '_SHOW',
      COLS_NAME => 1
    });

    if ($tp_list && ref $tp_list eq 'ARRAY' && scalar @$tp_list){
      my $next_tp_name = $tp_list->[0]{name};
      $Internet->{TP_CHANGE_WARNING} = $html->reminder($lang{TP_CHANGE_SHEDULED}, "$next_tp_name ($next_tp_date)", {
        OUTPUT2RETURN => 1,
        class         => 'info'
      });
    }
  }

  my ($status, $color) = split(/:/, $service_status->{ $Internet->{STATUS} });
  $user->{SERVICE_STATUS} = $Internet->{STATUS};

  if ($Internet->{STATUS} == 2) {
    $Internet->{STATUS_VALUE} = $html->color_mark($status, $color) . ' ';
    $Internet->{STATUS_VALUE} .= ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                                  : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ID=>'ACTIVATE', class=> 'btn btn-xs btn-success pull-right' });
  }
  elsif ($Internet->{STATUS} == 5) {
    $Internet->{STATUS_VALUE} = $html->color_mark($status, $color) . ' ';

    if ($Internet->{MONTH_ABON} && $user->{DEPOSIT} && $Internet->{MONTH_ABON} <= $user->{DEPOSIT}) {
      $Internet->{STATUS_VALUE} .= ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
                                                    : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ex_params => ' ID="ACTIVATE"', BUTTON => 1 });
    }
    else {
      if ($functions{$index} && $functions{$index} eq 'internet_user_info') {
        form_neg_deposit($user);
      }
    }
  }
  else {
    $Internet->{STATUS_VALUE} = $html->color_mark($status, $color);
  }

  $index = get_function_index('internet_user_info');
  if ($index && $index =~ /sub(\d+)/){
    $index = $1;
  }

  if ($conf{INTERNET_USER_CHG_TP}) {
    $Internet->{TP_CHANGE} = $html->button("$lang{CHANGE}", 'index=' . get_function_index('internet_user_chg_tp') . '&sid=' . $sid, { class => 'change pull-right' });
  }

  #Activate Cisco ISG Account
  if ($conf{INTERNET_ISG}) {
    if ($user->{DISABLE}) {
      $html->message('err', $lang{ERROR}, "$lang{USER}  $lang{DISABLE}", { ID => 16 });
    }
    elsif ($Internet->{CID} ne $Isg->{ISG_CID_CUR} || $Internet->{CID} eq '') {
      $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}\n\n CID: $Isg->{ISG_CID_CUR}\n IP: $user->{REMOTE_ADDR} ", { ID => 121  });
      $html->form_main(
        {
          CONTENT => '',
          HIDDEN  => {
            index => $index,
            CID   => $Isg->{ISG_CID_CUR},
            sid   => $sid
          },
          SUBMIT => { activate => "$lang{ACTIVATE}" }
        }
      );

      $Internet->{CID} = $Isg->{ISG_CID_CUR};
      $Internet->{IP}  = $user->{REMOTE_ADDR};
      $Internet->{CID} .= ' ' . $html->color_mark($lang{NOT_ACTIVE}, $_COLORS[6]);
    }

    #Self hangup
    elsif ($Internet->{CID} eq $Isg->{ISG_CID_CUR}) {
      my $table = $html->table(
        {
          width    => '600',
          rowcolor => 'row_active',
          rows     => [
            [
                ($Isg->{ISG_SESSION_DURATION}) ? "$lang{SESSIONS} $lang{DURATION}: " . sec2time($Isg->{ISG_SESSION_DURATION}, { str => 1 }) : '',
                ($Isg->{CURE_SERVICE} && $Isg->{CURE_SERVICE} !~ /TP/ && !$Isg->{TURBO_MODE_RUN}) ? $html->form_input('logon', "$lang{LOGON} ", { TYPE => 'submit', OUTPUT2RETURN => 1 }) : '',
              #$html->form_input('hangup', $lang{HANGUP}, { TYPE => 'submit', OUTPUT2RETURN => 1 })
            ]
          ],
        }
      );

      print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
          HIDDEN  => {
            index => $index,
            CID   => $Isg->{ISG_CID_CUR},
            sid   => $sid
          },
        }
      );
    }
  }

  #Turbo mode Enable function
  if ($conf{INTERNET_TURBO_MODE}) {
    require Internet::Turbo_mode;
    internet_turbo_control($Internet);
  }

  if ($Internet->{IP} eq '0.0.0.0') {
    $Internet->{IP} = $lang{NO};
  }

  if ($conf{INTERNET_USER_SERVICE_HOLDUP}) {
    $Internet->{HOLDUP_BTN} = internet_holdup_service($Internet);
  }

  if($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} != 0.00){
    $Internet->{MONTH_ABON} = $Internet->{PERSONAL_TP};
  }

  if($Internet->{REDUCTION_FEE} && $user->{REDUCTION} > 0) {
    if ($user->{REDUCTION} < 100) {
      $Internet->{DAY_ABON}   = sprintf('%.2f', $Internet->{DAY_ABON} * (100 - $user->{REDUCTION}) / 100) if ($Internet->{DAY_ABON} > 0);
      $Internet->{MONTH_ABON} = sprintf('%.2f', $Internet->{MONTH_ABON} * (100 - $user->{REDUCTION}) / 100) if($Internet->{MONTH_ABON} > 0);
    }
  }

  my $money_name = '';
  if (exists $conf{MONEY_UNIT_NAMES} && defined $conf{MONEY_UNIT_NAMES} && ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY'){
    $money_name = $conf{MONEY_UNIT_NAMES}->[0] || '';
  }

  #Extra fields
  $Internet->{EXTRA_FIELDS} = '';
  my @check_fields = (
    "MONTH_ABON:0.00:\$_MONTH_FEE:$money_name",
    "DAY_ABON:0.00:\$_DAY_FEE:$money_name",
    "TP_ACTIVATE_PRICE:0.00:\$_ACTIVATE_TARIF_PLAN:$money_name",
    "INTERNET_EXPIRE:0000-00-00:\$_EXPIRE",
    "TP_AGE:0:\$_AGE",
    #'ACTIVATE_CHANGE_PRICE:0.00:\$_ACTIVE',
    "IP:0.0.0.0:\$_STATIC IP",
    "CID::MAC",
  );

  foreach my $param ( @check_fields ) {
    my($id, $default_value, $lang_, $value_prefix )=split(/:/, $param);
    if(! defined($Internet->{$id}) || $Internet->{$id} eq $default_value) {
      next;
    }

    $Internet->{EXTRA_FIELDS} .= $html->tpl_show(templates('form_row_client'), {
        ID    => '$id',
        NAME  => _translate($lang_),
        VALUE => $Internet->{$id} . ( $value_prefix ? (' ' . $value_prefix) : '' ),
      }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('internet_user_info', 'Internet'), $Internet,
    {  ID => 'internet_user_info' });

  if($conf{INTERNET_ALERT_REDIRECT_FILTER} && $conf{INTERNET_ALERT_REDIRECT_FILTER} eq $Internet->{FILTER_ID}) {
    $Internet->change({
      UID       => $user->{UID},
      FILTER_ID => ''
    });
  }

  return 1;
}


#**********************************************************
=head2 internet_discovery($attr)

=cut
#**********************************************************
sub internet_discovery {
  my ($user_ip)=@_;

  $conf{INTERNET_IP_DISCOVERY}=~s/[\r\n ]//g;
  my @dhcp_nets         = split(/;/, $conf{INTERNET_IP_DISCOVERY});

  my $discovery_ip = 0;
  foreach my $nets (@dhcp_nets) {
    my (undef, $net_ips, undef) = split(/:/, $nets);
    if(check_ip($user_ip, $net_ips) ) {
      $discovery_ip = 1;
      last;
    }
  }

  if(! $discovery_ip) {
    return 1;
  }

  my $session_list = $Sessions->online(
    {
      CLIENT_IP => $user_ip,
      #USER_NAME => $user->{LOGIN},
      ACCT_SESSION_ID => '_SHOW',
      NAS_ID    => '_SHOW',
      GUEST     => '_SHOW'
    }
  );

  if ($Sessions->{TOTAL} < 1 || $session_list->[0]->{guest} ) {
    my $DHCP_INFO = internet_dhcp_get_mac($user_ip, { CHECK_STATIC => 1 });
    if (!$DHCP_INFO->{MAC}) {
      my $log_type = 'LOG_WARNING';
      my $error_id = 112;

      $html->message('err', $lang{ERROR}, "DHCP $lang{ERROR}\n MAC: $lang{NOT_EXIST}\n IP: '$user_ip'", { ID => 112 });
      $Log->log_print($log_type, $user->{LOGIN},
        show_hash($DHCP_INFO, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
        { ACTION => 'REG', NAS => { NAS_ID => $session_list->[0]->{nas_id} } });

      return 0;
    }
    elsif ($DHCP_INFO->{STATIC}) {
      if ($DHCP_INFO->{IP} ne $user_ip) {
        my $log_type = 'LOG_WARNING';
        my $error_id = 114;

        $html->message('err', $lang{ERROR}, "$lang{ERR_IP_ADDRESS_CONFLICT}\n MAC: $lang{NOT_EXIST}\n IP: '$user_ip' ", { ID => 114 });

        $Log->log_print($log_type, $user->{LOGIN},
          show_hash($DHCP_INFO, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
          { ACTION => 'REG', NAS => { NAS_ID => $session_list->[0]->{nas_id} } });
      }
    }
    else {
      if($FORM{discovery}) {
        if (internet_dhcp_get_mac_add($user_ip, $DHCP_INFO, { NAS_ID => $session_list->[0]->{nas_id} })) {
          $html->message('info', $lang{INFO}, "$lang{ACTIVATE}\n\n "
              . (($Internet->{NEW_IP} && $Internet->{NEW_IP} ne '0.0.0.0') ? "IP: $Internet->{NEW_IP}\n" : q{})
              .  "CID: $DHCP_INFO->{MAC}");

          if ($session_list->[0]->{acct_session_id}) {
            $Nas->info({ NAS_ID => $session_list->[0]->{nas_id} });
            $Sessions->online_info( { ACCT_SESSION_ID  => $session_list->[0]->{acct_session_id}, NAS_ID => $session_list->[0]->{nas_id} });

            #              END {
            require Abills::Nas::Control;
            Abills::Nas::Control->import();

            my $Nas_cmd = Abills::Nas::Control->new($db, \%conf);
            sleep 1;
            $Nas_cmd->hangup($Nas, 0, '',
              {
                #DEBUG  => $FORM{DEBUG} || undef,
                %$Sessions
              }
            );
            `echo "hangup" >> /tmp/hagup`;
            #              }
            #              if ($ret == 0) {
            #                $message = "$lang{NAS} ID:  $nas_id\n $lang{NAS} IP: $Nas->{NAS_IP}\n $lang{PORT}: $nas_port_id\n SESSION_ID: $acct_session_id\n\n  $ret";
            #                sleep 3;
            #                $admin->action_add($FORM{UID}, "$user_name", { MODULE => 'Internet', TYPE => 15 });
            #              }
          }
        }
      }

      if (! $Internet->{NEW_IP}) {
        $html->tpl_show(_include('internet_guest_mode', 'Internet'), {
            %$Internet,
            %$DHCP_INFO,
            IP => $user_ip,
            ID => 'internet_guest_mode'
          });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 internet_user_chg_tp($attr)

=cut
#**********************************************************
sub internet_user_chg_tp {
  my ($attr) = @_;

  my $period = $FORM{period} || 0;

  if (!$conf{INTERNET_USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", "$lang{NOT_ALLOW}", { ID => 140 });
    return 0;
  }

  my $uid = $LIST_PARAMS{UID};

  if ($uid) {
    $Internet = $Internet->info($uid, { DOMAIN_ID => $user->{DOMAIN_ID} });
    if ($Internet->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 22 });
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 19 });
    return 0;
  }

  if ($conf{FEES_PRIORITY} && $conf{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
    $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
  }
  my %CHANGE_PARAMS = ();

  if ($user->{GID}) {
    #Get user groups
    $user->group_info($user->{GID});
    if ($user->{DISABLE_CHG_TP}) {
      $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", "$lang{NOT_ALLOW}", { ID => 143 });
      return 0;
    }
  }

  #Get TP groups
  $Tariffs->tp_group_info($Internet->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    $html->message('err', "$lang{CHANGE} $lang{TARIF_PLAN}", $lang{NOT_ALLOW}, { ID => 140 });
    return 0;
  }

  #Get next abon day
  if (
    $Internet->{MONTH_ABON} > 0
      && !$Internet->{STATUS}
      && !$user->{DISABLE}
      && ( $user->{DEPOSIT} + $user->{CREDIT} > 0
      || $Internet->{POSTPAID_ABON}
      || $Internet->{PAYMENT_TYPE} == 1)
  )
  {
    if ($user->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
      $M--;
      $Internet->{ABON_DATE} = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $DATE, 3);

      if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
        $D = $conf{START_PERIOD_DAY};
      }
      else {
        $M++;
        $D = '01';
      }

      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      $Internet->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  if ($FORM{set} && $FORM{ACCEPT_RULES}) {
    if (!$FORM{TP_ID} || $FORM{TP_ID} < 1) {
      $html->message('err', "$lang{ERROR}", "$lang{ERR_WRONG_DATA}: $lang{TARIF_PLAN}", { ID => 141 });
    }
    elsif ($conf{INTERNET_USER_CHG_TP_NPERIOD}) {
      my ($CUR_Y, $CUR_M, $CUR_D) = split(/-/, $DATE);

      # Get next month
      my ($Y, $M, $D);
      if ($user->{ACTIVATE} eq '0000-00-00') {
        # Get next month
        ($Y, $M, $D) = split(/-/, $DATE, 3);
      }
      else {
        ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
      }

      # Renew expired accounts
      if ($user->{EXPIRE} ne '0000-00-00' && $Internet->{TP_AGE} > 0) {
        ($Y, $M, $D) = split(/-/, $user->{EXPIRE});
        my $seltime = POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));
        my $tp_age = $Internet->{TP_INFO}->{AGE};
        # REnew expire tarif
        if ($seltime < time()) {
          my ($EXPIRE_Y, $EXPIRE_M, $EXPIRE_D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $CUR_D, ($CUR_M), ($CUR_Y - 1900), 0, 0, 0) + $tp_age * 86400))));
          $CHANGE_PARAMS{EXPIRE} = "$EXPIRE_Y-$EXPIRE_M-$EXPIRE_D";
          ($Y, $M, $D) = split(/-/, $DATE, 3);
          $Internet->{TP_INFO} = $Tariffs->info($FORM{TP_ID});
          goto CHG_TP;
        }
        else {
          ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M), ($Y - 1900), 0, 0, 0) + $tp_age * 86400))));
        }
      }

      if ($Internet->{STATUS} == 5) {

      }
      # For daily fees or moth distribution next day fees
      elsif (!$conf{INTERNET_USER_CHG_TP_NEXT_MONTH} && ($Internet->{MONTH_ABON} == 0 || $Internet->{ABON_DISTRIBUTION})) {
        ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));
      }
      else {
        if ($user->{ACTIVATE} ne '0000-00-00') {
          ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 30 * 86400))));
        }
        else {
          if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
            $D = $conf{START_PERIOD_DAY};
          }
          else {
            $M++;
            if ($M == 13) {
              $M = 1;
              $Y++;
            }
            $D = '01';
          }
        }
      }

      CHG_TP:
      $M = sprintf("%02d", $M);
      $D = sprintf("%02d", $D);
      my $seltime = POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900));

      if ($seltime > time()) {
        $Shedule->add({
          UID      => $uid,
          TYPE     => 'tp',
          ACTION   => $FORM{TP_ID},
          D        => $D,
          M        => $M,
          Y        => $Y,
          MODULE   => 'Internet',
          COMMENTS => "$lang{FROM}: $Internet->{TP_ID}:$Internet->{TP_NAME}"
        });
      }
      else {
        $FORM{UID} = $uid;
        $FORM{STATUS} = 0 if ($Internet->{STATUS} == 5);
        $Internet->change({%FORM});
        $user->change(
          $uid,
          {
            ACTIVATE => ($user->{ACTIVATE} ne '0000-00-00') ? "$DATE" : undef,
            UID => $uid,
            %CHANGE_PARAMS
          }
        );

        if (! _error_show($user)) {
          $html->message('info', $lang{CHANGED}, $lang{CHANGED});
          $Internet->info($user->{UID});
          service_get_month_fee($Internet) if (!$FORM{INTERNET_NO_ABON});
        }
      }
    }
    elsif ($period == 1 && $conf{INTERNET_USER_CHG_TP_SHEDULE}) {
      my ($year, $month, $day) = split(/-/, $FORM{DATE}, 3);
      my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

      if ($seltime <= time()) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}");
        return 0;
      }

      $Shedule->add({
        UID      => $uid,
        TYPE     => 'tp',
        ACTION   => $FORM{TP_ID},
        D        => sprintf("%02d", $day),
        M        => sprintf("%02d", $month),
        Y        => $year,
        MODULE   => 'Internet',
        COMMENTS => "$lang{FROM}: $Internet->{TP_ID}:$Internet->{TP_NAME}"
      });

      if (! _error_show($Shedule)) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        $Internet->info($user->{UID});
      }
    }

    #Imidiatly change TP
    else {
      if ($user->{CREDIT} + $user->{DEPOSIT} < 0) {
        $html->message('err', "$lang{ERROR}", "$lang{ERR_SMALL_DEPOSIT} - $lang{DEPOSIT}: $user->{DEPOSIT} $lang{CREDIT}: $user->{CREDIT}", { ID => 15 });
        return 0;
      }
      $FORM{UID} = $uid;

      $Internet->{ABON_DATE} = undef;
      if ($Internet->{MONTH_ABON} > 0 && !$Internet->{STATUS} && !$user->{DISABLE}) {
        if ($user->{ACTIVATE} ne '0000-00-00') {
          my ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
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
            $D = sprintf("%02d", $conf{START_PERIOD_DAY});
          }
          else {
            $D = '01';
          }
          $Internet->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        }
      }

      if ($Internet->{ABON_DATE}) {
        my ($year, $month, $day) = split(/-/, $Internet->{ABON_DATE}, 3);
        my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

        if ($seltime <= time()) {
          $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} ($year, $month, $day)/" . $seltime . "-" . time());
          return 0;
        }
        elsif ($FORM{date_D} && $FORM{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
          $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA} ($year-$month-$day)");
          return 0;
        }

        $Shedule->add({
          UID      => $uid,
          TYPE     => 'tp',
          ACTION   => $FORM{TP_ID},
          D        => $day,
          M        => $month,
          Y        => $year,
          MODULE   => 'Internet',
          COMMENTS => "$lang{FROM}: $Internet->{TP_ID}:$Internet->{TP_NAME}"
        });

        if (! _error_show($Shedule->{errno})) {
          $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        }
      }
      else {
        $Internet->change({
          %FORM,
          UID => $user->{UID}
        });

        if (! _error_show($Internet)) {
          #Take fees
          if (!$Internet->{STATUS}) {
            service_get_month_fee($Internet) if (!$FORM{INTERNET_NO_ABON});
            $user->change(
              $user->{UID},
              {
                ACTIVATE => "$DATE",
                UID      => $user->{UID}
              }
            );
          }

          $html->message('info', $lang{CHANGED}, $lang{CHANGED});
          $Internet->info($Internet->{UID});
        }
      }

      $Internet->info($Internet->{UID});
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del({
      UID => $uid || '-',
      ID  => $FORM{SHEDULE_ID}
    });

    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  my $message='';
  my $date_ = ($FORM{date_y} || ''). '-' . ($FORM{date_m} || '') .'-'. ($FORM{date_d} || '');
  $Shedule->info({
    UID      => $user->{UID},
    TYPE     => 'tp',
    DESCRIBE => "$message\n$lang{FROM}: '$date_'",
    MODULE   => 'Internet'
  });

  my $table;
  if ($Shedule->{TOTAL} > 0) {
    $Tariffs->info(0, {
       TP_ID  => $Shedule->{ACTION},
       #MODULE => 'Internet'
    });

    $table = $html->table({
      width      => '100%',
      caption    => $lang{SHEDULE},
      rows       => [
        [ "$lang{TARIF_PLAN}:", "$Tariffs->{ID} : $Tariffs->{NAME}" ],
        [ "$lang{DATE}:", "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}" ],
        [ "$lang{ADDED}:", "$Shedule->{DATE}" ],
        [ "ID:", "$Shedule->{SHEDULE_ID}" ] ]
    });

    $Tariffs->{TARIF_PLAN_SEL} = $table->show({ OUTPUT2RETURN => 1 }) . $html->form_input('SHEDULE_ID', "$Shedule->{SHEDULE_ID}", { TYPE => 'HIDDEN', OUTPUT2RETURN => 1 });
    $Tariffs->{TARIF_PLAN_TABLE} = $Tariffs->{TARIF_PLAN_SEL};
    if (!$Shedule->{ADMIN_ACTION}) {
      $Tariffs->{ACTION}     = 'del';
      $Tariffs->{LNG_ACTION} = "$lang{DEL}  $lang{SHEDULE}";
      #$Tariffs->{ACTION_FLAG}= $html->form_input('del', "1", { TYPE => 'text', OUTPUT2RETURN => 1 });
    }
  }
  else {
    $Tariffs->{TARIF_PLAN_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED   => $Internet->{TP_ID},
        SEL_LIST   => $Tariffs->list(
          {
            TP_GID       => $Internet->{TP_GID},
            CHANGE_PRICE => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
            MODULE       => 'Dv;Internet',
            NEW_MODEL_TP => 1,
            TP_CHG_PRIORITY => $Internet->{TP_PRIORITY},
            COLS_NAME    => 1
          }
        ),
      }
    );

    $table = $html->table({
      width      => '100%',
      caption    => $lang{TARIF_PLANS},
    });

    my $tp_list = $Tariffs->list({
      TP_GID       => $Internet->{TP_GID},
      CHANGE_PRICE => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
      MODULE       => 'Dv;Internet',
      MONTH_FEE    => '_SHOW',
      DAY_FEE      => '_SHOW',
      CREDIT       => '_SHOW',
      COMMENTS     => '_SHOW',
      TP_CHG_PRIORITY => $Internet->{TP_PRIORITY},
      REDUCTION_FEE=> '_SHOW',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      DOMAIN_ID    => $user->{DOMAIN_ID}
    });

    my @skip_tp_changes = ();
    if ($conf{INTERNET_SKIP_CHG_TPS}) {
      @skip_tp_changes = split(/,\s?/, $conf{INTERNET_SKIP_CHG_TPS});
    }

    foreach my $tp (@$tp_list) {
      next if (in_array($tp->{id}, \@skip_tp_changes));
      next if ($tp->{tp_id} == $Internet->{TP_ID} && $user->{EXPIRE} eq '0000-00-00');
      #   $table->{rowcolor} = ($table->{rowcolor} && $table->{rowcolor} eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
      my $radio_but = '';

      my $tp_fee = $tp->{day_fee} + $tp->{month_fee};

      if($tp->{reduction_fee} && $user->{REDUCTION} && $user->{REDUCTION} > 0) {
        $tp_fee = $tp_fee - (($tp_fee / 100) *  $user->{REDUCTION});
      }

      $user->{CREDIT}=($user->{CREDIT}>0)? $user->{CREDIT}  : (($tp->{credit} > 0) ? $tp->{credit} : 0);

      if ($tp_fee < $user->{DEPOSIT} + $user->{CREDIT} || $tp->{abon_distribution}) {
        $radio_but = $html->form_input('TP_ID', "$tp->{tp_id}", { TYPE => 'radio', OUTPUT2RETURN => 1 });
      }
      else {
        $radio_but = $conf{INTERNET_USER_CHG_TP_SMALL_DEPOSIT} || $lang{ERR_SMALL_DEPOSIT};
      }

      $table->addrow($tp->{id}, $html->b($tp->{name}) . $html->br() . convert($tp->{comments}, { text2html => 1 }), $radio_but);
    }
    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 });

    if ($Tariffs->{TOTAL} == 0) {
      $html->message('info', $lang{INFO}, $lang{ERR_SMALL_DEPOSIT}, { ID => 142 });
      return 0;
    }

    $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Internet->{ABON_DATE}, TP => $Tariffs }) if ($conf{INTERNET_USER_CHG_TP_SHEDULE} && !$conf{INTERNET_USER_CHG_TP_NPERIOD});
    $Tariffs->{ACTION} = 'set';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
    #$html->form_input('hold_up_window', '--'.$lang{CHANGE}, { TYPE          => 'submit',
    #                                 OUTPUT2RETURN => 1 });
  }

  $Tariffs->{UID}     = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID}   = $Internet->{TP_ID};
  $Tariffs->{TP_NAME} = "$Internet->{TP_ID}:$Internet->{TP_NAME}";
  $html->tpl_show(templates('form_client_chg_tp'),
    { %$Tariffs, ID => $Internet->{ID} });

  return 1;
}

#**********************************************************
=head2 form_stats($attr)

  Arguments:
    $attr
      UID

=cut
#**********************************************************
sub internet_user_stats {
  my ($attr) = @_;

  my $uid = $LIST_PARAMS{UID} || $user->{UID} || $attr->{UID};
  if (defined($FORM{SESSION_ID})) {
    $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
    internet_session_detail({ LOGIN => $LIST_PARAMS{LOGIN} });
    return 0;
  }

  _error_show($Sessions);

  #Join Service
  if ($user->{COMPANY_ID}) {
    if ($FORM{COMPANY_ID}) {
      $users = Users->new($db, $admin, \%conf);
      internet_report_use();
      return 0;
    }

    require Customers;
    Customers->import();
    my $customer = Customers->new($db, $admin, \%conf);
    my $company  = $customer->company();
    my $ulist    = $company->admins_list(
      {
        COMPANY_ID => $user->{COMPANY_ID},
        UID        => $uid
      }
    );

    if ($company->{TOTAL} > 0 && $ulist->[0]->[0] > 0) {
      $Internet->{JOIN_SERVICES_USERS} = $html->button($lang{COMPANY}, "&sid=$sid&index=$index&COMPANY_ID=$user->{COMPANY_ID}", { BUTTON => 1 }) . ' ';
    }

    $Internet->info($uid);

    if ($Internet->{JOIN_SERVICE}) {
      my @uids = ();
      my $list = $Internet->list(
        {
          JOIN_SERVICE => ($Internet->{JOIN_SERVICE}==1) ? $uid : $Internet->{JOIN_SERVICE},
          COMPANY_ID   => $attr->{USER_INFO}->{COMPANY_ID},
          LOGIN        => '_SHOW',
          PAGE_ROWS    => 1000,
          COLS_NAME    => 1
        }
      );

      if ($Internet->{JOIN_SERVICE} == 1) {
        $Internet->{JOIN_SERVICES_USERS} .= (!$FORM{JOIN_STATS}) ? $html->b("$lang{ALL} $lang{USERS}") . ' :: '
                                                           : $html->button("$lang{ALL}", "&sid=$sid&index=$index&JOIN_STATS=" . $uid, { BUTTON => 1 }) . ' ';
      }
      #elsif ($Internet->{JOIN_SERVICE} > 1) {
      #  $Internet->{JOIN_SERVICES_USERS} .= $html->button("$lang{MAIN}", "index=$index&UID=$Internet->{JOIN_SERVICE}", { BUTTON => 1 });
      #}

      foreach my $line (@$list) {
        if ($FORM{JOIN_STATS} && $FORM{JOIN_STATS} == $line->{uid}) {
          $Internet->{JOIN_SERVICES_USERS} .= $html->b($line->{login}) . ' ';
          $uid = $FORM{JOIN_STATS};
        }
        elsif($Internet->{JOIN_SERVICE} == 1) {
          $Internet->{JOIN_SERVICES_USERS} .= $html->button($line->{login}, "&sid=$sid&index=$index&JOIN_STATS=" . $line->{uid}, { BUTTON => 1 }) . ' ';
        }

        push @uids, $line->{uid};
      }

      $LIST_PARAMS{UIDS}  = ($Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid;
      $LIST_PARAMS{UIDS} .= ',' . join(', ', @uids) if ($#uids > -1 && !$FORM{JOIN_STATS});
    }

    my $table = $html->table(
      {
        width => '100%',
        rows  => [ [ "$lang{JOIN_SERVICE}: ", $Internet->{JOIN_SERVICES_USERS} ] ]
      }
    );
    $Sessions->{JOIN_SERVICE_STATS} .= $table->show();
  }

  if ($FORM{rows}) {
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
    $LIST_PARAMS{PG}        = $FORM{pg};
    $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE};
    $LIST_PARAMS{TO_DATE}   = $FORM{TO_DATE};
    $conf{list_max_recs}    = $FORM{rows} if($FORM{rows} && $FORM{rows} =~ /^\d+$/);
    $pages_qs .= "&rows=$conf{list_max_recs}";
  }

  #online sessions
  my $list = $Sessions->online(
    {
      CLIENT_IP          => '_SHOW',
      CID                => '_SHOW',
      DURATION_SEC2      => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      UID                => $uid
    }
  );

  if ($Sessions->{TOTAL} > 0) {
    my $table = $html->table(
      {
        caption     => 'Online',
        width       => '100%',
        title_plain => [ "IP", "CID", $lang{DURATION}, $lang{RECV}, $lang{SENT} ],
        ID          => 'ONLINE'
      }
    );

    foreach my $line (@$list) {
      $table->addrow($line->{client_ip},
        $line->{CID},
        _sec2time_str($line->{duration_sec2}),
        int2byte($line->{acct_input_octets}),
        int2byte($line->{acct_output_octets})
      );
    }
    $Sessions->{ONLINE} = $table->show({ OUTPUT2RETURN => 1 });
  }

  #PEriods totals
  $Sessions->{PERIOD_STATS} = internet_stats_periods({ UID => $uid });
  $Sessions->{PERIOD_SELECT}= internet_period_select({ UID => $uid });

  $Internet->info($uid);

  my $TRAFFIC_NAMES = internet_traffic_names($Internet->{TP_ID});

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }
  elsif (defined($FORM{PERIOD}) && $FORM{PERIOD}=~/^\d+$/) {
    $LIST_PARAMS{PERIOD} = $FORM{PERIOD};
    $pages_qs .= "&PERIOD=$FORM{PERIOD}";
  }

  #Show rest of prepaid traffic
  if (
    $Sessions->prepaid_rest({
      UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $uid,
      UIDS => $uid
    })
  )
  {
    $list  = $Sessions->{INFO_LIST};
    my $table = $html->table(
      {
        caption     => $lang{PREPAID},
        width       => '100%',
        title_plain => [ "$lang{TRAFFIC} $lang{TYPE}", $lang{BEGIN}, $lang{END}, $lang{START}, "$lang{TOTAL} (MB)", "$lang{REST} (MB)", "$lang{OVERQUOTA} (MB)" ],
        ID          => 'INTERNET_STATS_PREPAID'
      }
    );

    foreach my $line (@$list) {
      my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $Sessions->{REST}->{ $line->{traffic_class} };

      $table->addrow(
        $line->{traffic_class} . ':' . (($TRAFFIC_NAMES->{ $line->{traffic_class} }) ? $TRAFFIC_NAMES->{ $line->{traffic_class} } : '').
          ($conf{INTERNET_INTERVAL_PREPAID} ? "/ $line->{interval_id}" : '') ,
        $line->{interval_begin},
        $line->{interval_end},
        $line->{activate},
        $line->{prepaid},
          ($line->{prepaid} > 0 && $traffic_rest > 0) ? $traffic_rest      : 0,
          ($line->{prepaid} > 0 && $traffic_rest < 0) ? $html->color_mark(abs($traffic_rest), 'red') : 0,
      );
    }

    $Sessions->{PREPAID_INFO} = $table->show({ OUTPUT2RETURN => 1 });
  }

  $pages_qs .= "&DIMENSION=$FORM{DIMENSION}" if ($FORM{DIMENSION});

  #Session List
  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $list  = $Sessions->list({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      caption     => $lang{SUM},
      width       => '100%',
      title_plain => [
        $lang{SESSIONS},
        $lang{DURATION},
        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES->{0}) ? $TRAFFIC_NAMES->{0} : $lang{TRAFFIC}) . " $lang{SUM}",

        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{RECV}",
        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{SENT}",

        (($TRAFFIC_NAMES->{1}) ? $TRAFFIC_NAMES->{1} : $lang{TRAFFIC}) . " $lang{SUM}",
        "$lang{SUM}"
      ],
      rows       => [
        [
          $Sessions->{TOTAL},
          _sec2time_str($Sessions->{DURATION}),
          int2byte($Sessions->{TRAFFIC_OUT},                             { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC_IN},                              { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC_OUT} || 0) + ($Sessions->{TRAFFIC_IN} || 0),   { DIMENSION => $FORM{DIMENSION} }),

          int2byte($Sessions->{TRAFFIC2_OUT},                            { DIMENSION => $FORM{DIMENSION} }),
          int2byte($Sessions->{TRAFFIC2_IN},                             { DIMENSION => $FORM{DIMENSION} }),

          int2byte(($Sessions->{TRAFFIC2_OUT} || 0) + ($Sessions->{TRAFFIC2_IN}  || 0), { DIMENSION => $FORM{DIMENSION} }),
          $Sessions->{SUM}
        ]
      ]
    }
  );

  $Sessions->{TOTALS_FULL} = $table->show({ OUTPUT2RETURN => 1 });

  if (-f '../charts.cgi' || -f 'charts.cgi') {
    if($user->{UID}) {
      $Sessions->{GRAPHS} = internet_get_chart_iframe("UID=$uid", '1,2');
    }
  }

  $Sessions->{SESSIONS} = internet_sessions($list, $Sessions, { OUTPUT2RETURN => 1 }) if ($Sessions->{TOTAL} > 0);

  $html->tpl_show(_include('internet_user_stats', 'Internet'), $Sessions);

  return 1;
}

#**********************************************************
=head2 internet_dhcp_get_mac_add($ip, $DHCP_INFO, $attr) - Add discovery mac to Dhcphosts

  Arguments:
    $ip
    $DHCP_INFO
    $attr

    $conf{INTERNET_IP_DISCOVERY}

  Returns:

=cut
#**********************************************************
sub internet_dhcp_get_mac_add {
  my ($ip, $DHCP_INFO, $attr) = @_;

  #require Dhcphosts;
  #Dhcphosts->import();
  #my $Dhcphosts         = Dhcphosts->new($db, $admin, \%conf);

  $conf{INTERNET_IP_DISCOVERY}=~s/[\r\n ]//g;
  my @dhcp_nets         = split(/;/, $conf{INTERNET_IP_DISCOVERY});
  my $default_params    = "IP,MAC";
  #load_module('Dhcphosts', $html);

  foreach my $nets (@dhcp_nets) {
    my %PARAMS_HASH = ();

    my ($net_id, $net_ips, $params) = split(/:/, $nets);
    $params                 = $default_params if (!$params);
    my @params_arr          = split(/,/, $params);

    for(my $i=0; $i<=$#params_arr; $i++) {
      my ($param, $value)=split(/=/, $params_arr[$i]);
      $PARAMS_HASH{$param} = $value || $DHCP_INFO->{$param};
    }

    my $start_ip           = '0.0.0.0';
    my $bit_mask           = 0;
    ($start_ip, $bit_mask) = split(/\//, $net_ips) if ($net_ips);
    my $mask               = 0b0000000000000000000000000000001;
    my $address_count      = sprintf("%d", $mask << (32 - $bit_mask));

    if (ip2int($ip) >= ip2int($start_ip) && ip2int($ip) <= ip2int($start_ip) + $address_count) {
      $PARAMS_HASH{IP} = dhcphosts_get_static_ip($net_id);

      if($PARAMS_HASH{IP} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        if ($PARAMS_HASH{IP} == -1) {
          return 0;
        }
        elsif ($PARAMS_HASH{IP} == 0) {
          $PARAMS_HASH{IP} = '0.0.0.0';
        }
      }

      my $list = $Internet->list({
        NAS_ID    => $PARAMS_HASH{NAS_ID},
        UID       => $user->{UID},
        PORTS     => $PARAMS_HASH{PORTS},
        COLS_NAME => 1,
        PAGE_ROWS => 1
      });

      if ($Internet->{TOTAL} > 0) {
        $Internet->change(
          {
            %PARAMS_HASH,
            ID     => $list->[0]->{id},
            NETWORK=> $net_id,
            #MAC    => $PARAMS_HASH{MAC}
          }
        );
      }
      else {
        $Internet->add({
          NETWORK     => $net_id,
          HOSTNAME    => "$user->{LOGIN}_$net_id",
          UID         => $user->{UID},
          %PARAMS_HASH
        });
      }

      my $log_type = 'LOG_INFO';
      my $error_id = 0;
      if ($Internet->{errno}) {
        $log_type = 'LOG_WARNING';
        if ($Internet->{errno} == 7) {
          $html->message('err', $lang{ERROR} . ' ' . $lang{ACTIVATE},
            $html->b($lang{ERR_HOST_REGISTRED})
              . "\n $lang{RENEW_IP}\n\n MAC: '$DHCP_INFO->{MAC}'\n IP: '$DHCP_INFO->{IP}'\n HOST: '$user->{LOGIN}_$net_id'",
            { ID => 118 });
          $error_id = 118;
        }
        else {
          $html->message('err', $lang{ACTIVATE}, "$lang{ERROR}: DHCP add hosts error", { ID => 119 });
          $error_id = 119;
        }
      }
      else {
        dhcphosts_config({
          NETWORKS => $net_id,
          reconfig => 1,
          QUITE    => 1,
          %PARAMS_HASH
        });
        $Internet->{NEW_IP} = $PARAMS_HASH{IP};
      }

      $Log->log_print($log_type, $user->{LOGIN},
        show_hash(\%PARAMS_HASH, { OUTPUT2RETURN => 1 }). (($error_id) ? "Error: $error_id" : ''),
        { ACTION => 'REG', NAS => { NAS_ID => $attr->{NAS_ID} } });

      return ($log_type eq 'LOG_INFO') ? 1 : 0;
    }
  }

  $html->message('err', $lang{ACTIVATE}, "$lang{ERROR}: Can't find assign network IP: '$ip' ", { ID => 120 });

  return 0;
}

#**********************************************************
=head2 internet_dhcp_get_mac($ip, $attr) - Get MAC from dhcp leaseds

IP discovery function

  Arguments:
    $ip     - User IP
    $attr   - Extra attributes
      CHECK_STATIC - Check static IP in dhcphosts

  Returns:
    Hash_ref
      IP
      MAC
      NAS_ID
      PORTS
      VLAN

=cut
#**********************************************************
sub internet_dhcp_get_mac {
  my ($ip, $attr) = @_;

  require Dhcphosts;
  Dhcphosts->import();
  my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);

  $Dhcphosts->host_info(0, { IP => $ip });
  #my $MAC    = '';
  my %PARAMS = ();

  if ($Dhcphosts->{TOTAL} > 0) {
    %PARAMS = (
      IP     => $Dhcphosts->{IP},
      MAC    => $Dhcphosts->{MAC},
      NAS_ID => $Dhcphosts->{NAS_ID},
      PORTS  => $Dhcphosts->{PORTS},
      VID    => $Dhcphosts->{VID},
      UID    => $Dhcphosts->{UID},
      SERVER_VID => $Dhcphosts->{SERVER_VID}
    );

    if ($attr->{CHECK_STATIC}) {
      $PARAMS{STATIC} = 1;
    }
    if ($PARAMS{MAC} ne '00:00:00:00:00:00') {
      return \%PARAMS;
    }
  }

  #Get mac from DB
  if ($conf{DHCPHOSTS_LEASES} && $conf{DHCPHOSTS_LEASES} eq 'db') {
    my $list = $Dhcphosts->leases_list({
      IP          => $ip,
      VLAN        => '_SHOW',
      SERVER_VLAN => '_SHOW',
      UID         => '_SHOW',
      STATE       => 2,
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });

    if ($Dhcphosts->{TOTAL} > 0) {
      %PARAMS        = %{ $list->[0] };
      $PARAMS{MAC}   = _mac_former($list->[0]->{HARDWARE});
      $PARAMS{PORTS} = $list->[0]->{PORT};
      $PARAMS{VID}   = $list->[0]->{VLAN};
      $PARAMS{UID}   = $list->[0]->{UID};
      $PARAMS{IP}    = int2ip($list->[0]->{IP});
      $PARAMS{SERVER_VID} = $list->[0]->{SERVER_VLAN};
    }

    load_module('Dhcphosts', $html);
    $PARAMS{CUR_IP}=$ip;
    if (defined($PARAMS{NAS_ID}) && $PARAMS{NAS_ID} == 0 && $PARAMS{CIRCUIT_ID} ) {
      ($PARAMS{NAS_ID}, $PARAMS{PORTS}, $PARAMS{VLAN}, $PARAMS{NAS_MAC})=dhcphosts_o82_info({ %PARAMS });
    }

    return \%PARAMS;
  }

  #Get mac from leases file
  else {
    my $logfile = $conf{DHCPHOSTS_LEASES} || '/var/db/dhcpd/dhcpd.leases';
    my %list    = ();
    my $l_ip    = '';

    if(open(my $fh, '<', $logfile)) {
      while (<$fh>) {
        next if /^#|^$/;

        if (/^lease (\d+\.\d+\.\d+\.\d+)/) {
          $l_ip = $1;
          $list{$ip}{ip} = sprintf("%-17s", $ip);
        }
        elsif (/^\s*hardware ethernet (.*);/) {
          my $mac = $1;
          if ($ip eq $l_ip) {
            $list{$ip}{hardware} = sprintf("%s", $mac);
            if ($list{$ip}{active}) {
              $PARAMS{MAC} = $list{$ip}{hardware};
              return \%PARAMS;
            }
          }
        }
        elsif (/^\s+binding state active/) {
          $list{$ip}{active} = 1;
        }
      }
      close($fh);
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't read file '$logfile' $!")
    }
    $PARAMS{MAC} = ($list{$ip} && $list{$ip}{hardware}) ? $list{$ip}{hardware} : '';
  }

  $PARAMS{CUR_IP}=$ip;
  return \%PARAMS;
}

#**********************************************************
=head2 internet_holdup_service($attr) - Hold up user service

=cut
#**********************************************************
sub internet_holdup_service {

  my ($hold_up_min_period, $hold_up_max_period, $hold_up_period, $hold_up_day_fee,
    undef, $active_fees, $holdup_skip_gids) = split(/:/, $conf{INTERNET_USER_SERVICE_HOLDUP});

  if ($holdup_skip_gids) {
    my @holdup_skip_gids_arr = split(/,\s?/, $holdup_skip_gids);
    if (in_array($user->{GID}, \@holdup_skip_gids_arr)) {
      return '';
    }
  }

  if ($hold_up_day_fee && $hold_up_day_fee > 0) {
    $Internet->{DAY_FEES}="$lang{DAY_FEE}: ". sprintf("%.2f", $hold_up_day_fee);
  }

  if ($FORM{del}) {
    $Shedule->del(
      {
        UID => $user->{UID},
        IDS => $FORM{del},
      }
    );

    $Internet->{STATUS_DAYS}=1;

    if ( $user->{INTERNET_STATUS} == 3) {
      $Internet->change(
        {
          UID    => $user->{UID},
          STATUS => 0,
        }
      );

      service_get_month_fee($Internet, { QUITE => 1 });
      $html->message('info', $lang{SERVICE}, "$lang{ACTIVATE}");
      return '';
    }
    elsif($conf{INTERNET_HOLDUP_COMPENSATE}) {
      $Internet->{TP_INFO} = $Tariffs->info(0, { ID => $Internet->{TP_ID} });
      service_get_month_fee($Internet, { QUITE => 1 });
    }

    $html->message('info', $lang{HOLD_UP}, "$lang{DELETED}");
  }

  my $list = $Shedule->list(
    {
      UID    => $user->{UID},
      MODULE => 'Internet',
      TYPE   => 'status',
      COLS_NAME=>1
    }
  );

  my %Shedule_val = ();
  my @del_arr     = ();

  foreach my $line (@$list) {
    $Shedule_val{ $line->{action} } = ($line->{y} || '*') .'-'. ($line->{m} || '*') .'-'. ($line->{d} || '*');
    push @del_arr, $line->{id};
  }

  my $del_ids = join(', ', @del_arr);

  if ($Shedule->{TOTAL}) {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP} ". ($Shedule_val{3} || '-') ." $lang{TO} ". ($Shedule_val{0} || '-') .
        (($Shedule->{TOTAL} > 1) ? $html->br() . $html->button($lang{DEL}, "index=$index&del=$del_ids". (($sid) ? "&sid=$sid" : q{}), { class => 'btn btn-primary', MESSAGE => "$lang{DEL} $lang{HOLD_UP}?" }) : ''));
    return '';
  }

  if ($FORM{add} && $FORM{ACCEPT_RULES}) {
    my ($from_year, $from_month, $from_day) = split(/-/, $FORM{FROM_DATE}, 3);
    my ($to_year,   $to_month,   $to_day)   = split(/-/, $FORM{TO_DATE},   3);
    my $block_days = date_diff($FORM{FROM_DATE}, $FORM{TO_DATE});

    if ($block_days < $hold_up_min_period) {
      $html->message('err', "$lang{ERR_WRONG_DATA}", "$lang{MIN} $lang{HOLD_UP}   $hold_up_min_period $lang{DAYS}");
    }
    elsif ($block_days > $hold_up_max_period) {
      $html->message('err', "$lang{ERR_WRONG_DATA}", "$lang{MAX} $lang{HOLD_UP}   $hold_up_max_period $lang{DAYS}");
    }
    elsif (date_diff($DATE, $FORM{FROM_DATE}) < 1) {
      $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}\n $lang{FROM}: $FORM{FROM_DATE}");
    }
    elsif ($block_days < 1) {
      $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}\n $lang{TO}: $FORM{TO_DATE}");
    }
    else {
      $Shedule->add(
        {
          UID    => $user->{UID},
          TYPE   => 'status',
          ACTION => '3',
          D      => $from_day,
          M      => $from_month,
          Y      => $from_year,
          MODULE => 'Internet'
        }
      );

      $Shedule->add(
        {
          UID    => $user->{UID},
          TYPE   => 'status',
          ACTION => '0',
          D      => $to_day,
          M      => $to_month,
          Y      => $to_year,
          MODULE => 'Internet'
        }
      );

      if (!_error_show($Shedule)) {
        #compensate period
        if ($conf{INTERNET_HOLDUP_COMPENSATE}) {
          internet_compensation({ QUITE => 1, HOLD_UP => 1 });
        }

        if($active_fees) {
          $Fees->take($user, $active_fees, { DESCRIBE => $lang{HOLD_UP} });
        }

        $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n $lang{DATE}: $FORM{FROM_DATE} -> $FORM{TO_DATE}\n  $lang{DAYS}: " . sprintf("%d", $block_days));
        return '';
      }
    }
  }

  if ($hold_up_period) {
    $admin->action_list(
      {
        UID       => $user->{UID},
        TYPE      => 14,
        FROM_DATE => POSIX::strftime("%Y-%m-%d", localtime(time - 86400 * $hold_up_period)),
        TO_DATE   => "$DATE",
      }
    );

    if ($admin->{TOTAL} > 0) {
      return '';
    }
  }

  if (($user->{INTERNET_STATUS} && $user->{INTERNET_STATUS} == 3) || $user->{DISABLE}) {
    $html->message('info', $lang{INFO}, "$lang{HOLD_UP}\n " . $html->button("$lang{ACTIVATE}", "index=$index&del=1&sid=$sid", { BUTTON => 1, MESSAGE => "$lang{ACTIVATE}?" }) );
    return '';
  }

  $Internet->{DATE_FROM} = $html->date_fld2(
    'FROM_DATE',
    {
      FORM_NAME => 'holdup',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      NEXT_DAY  => 1
    }
  );

  $Internet->{DATE_TO} = $html->date_fld2(
    'TO_DATE',
    {
      FORM_NAME => 'holdup',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
    }
  );

  return (! $user->{INTERNET_STATUS}) ? $html->tpl_show(_include('internet_hold_up', 'Internet'), $Internet, { OUTPUT2RETURN => 1 }) : q{};
}


1;