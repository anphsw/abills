package Internet::Services;

=head1 NAME

  Internet users function

  ERROR ID: 136ХХХХ

=cut

use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use Abills::Base qw(in_array ip2int int2ip);
use Control::Errors;
use Internet;
use Users;

my Control::Errors $Errors;
my Internet $Internet;
my Users $Users;

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  $self->{MODULES} = $attr->{MODULES};
  if ($admin->{MODULES}) {
    $self->{MODULES} = [ keys %{ $admin->{MODULES} } ];
  }

  bless($self, $class);
  $Internet = Internet->new($db, $admin, $conf);
  $Users = Users->new($db, $admin, $conf);
  $Errors = Control::Errors->new($db, $admin, $conf, {
    lang   => $self->{lang},
    module => 'Internet',
    parent => $self
  });

  return $self;
}

#**********************************************************
=head2 internet_user_chg_tp($attr) internet user change tp

  UID: int          - user for whom change tariff
  ID: int           - id of tariff from internet_main table
  TP_ID: int        - id of tp on which need to change
  PERIOD: int       - type of period of change tp
  DATE: str         - if used period equals 2
  TP_ID: int        - id of tp on which need to change
  GET_ABON: int     - make fee for user
  RECALCULATE: int  - recalculate of fees for user

=cut
#**********************************************************
sub internet_user_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  #TODO: move it to the API schema validation can not right now
  #TODO: because the same function used in two different places
  if (!$attr->{UID}) {
    return $Errors->throw_error(1360001, { lang_vars => { FIELD => 'uid' } });
  }
  elsif (!$attr->{ID}) {
    return $Errors->throw_error(1360002, { lang_vars => { FIELD => 'id' } });
  }
  elsif (!$self->{admin}->{permissions}{0}{4}) {
    return $Errors->throw_error(1360004);
  }
  elsif (!$self->{admin}->{permissions}{0}{10}) {
    return $Errors->throw_error(1360005);
  }

  if (!$attr->{TP_ID}) {
    return $Errors->throw_error(1360003, { lang_vars => { FIELD => 'tpId' } });
  }
  else {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
    $Tariffs->info($attr->{TP_ID});

    if (!$Tariffs->{MODULE} || $Tariffs->{MODULE} ne 'Internet') {
      return $Errors->throw_error(1360015);
    }
  }

  $Users->info($attr->{UID});

  if ($Users->{errno}) {
    return $Errors->throw_error(1360006);
  }

  $Internet->user_info($Users->{UID}, {
    DOMAIN_ID => $Users->{DOMAIN_ID},
    ID        => $attr->{ID}
  });

  if ($Internet->{errno} || $Internet->{TOTAL} < 1) {
    return $Errors->throw_error(1360007);
  }

  if ($attr->{TP_ID} && "$attr->{TP_ID}" eq ("$Internet->{TP_ID}" || '')) {
    return $Errors->throw_error(1360008);
  }

  $Internet->{ABON_DATE} = $self->service_get_abon_date({
    SERVICE   => $Internet,
    USER_INFO => $Users
  });

  my $period = $attr->{PERIOD} || $attr->{period} || 0;
  my ($year, $month, $day) = split('-', $main::DATE, 3);

  if ($period > 0) {
    if ($period == 1) {
      ($year, $month, $day) = split('-', $Internet->{ABON_DATE}, 3);
    }
    else {
      if (!$attr->{DATE}) {
        return $Errors->throw_error(1360009, { lang_vars => { FIELD => 'id' } });
      }
      ($year, $month, $day) = split('-', $attr->{DATE}, 3);

      if (!$year || !$month || !$day) {
        return $Errors->throw_error(1360010);
      }
    }
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

    if ($seltime <= time()) {
      return $Errors->throw_error(1360011);
    }
    # what is it?
    elsif ($attr->{date_D} && $attr->{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
      return $Errors->throw_error(1360012);
    }

    my $comments = ($self->{lang}->{FROM} || 'from') . ": $Internet->{TP_ID}:" .
      (($Internet->{TP_NAME}) ? "$Internet->{TP_NAME}" : q{}) . ((!$attr->{GET_ABON}) ? "\nGET_ABON=-1" : '')
      . ((!$attr->{RECALCULATE}) ? "\nRECALCULATE=-1" : '');

    require Shedule;
    Shedule->import();
    my $Schedule = Shedule->new($self->{db}, $self->{admin});

    $Schedule->add({
      UID          => $Users->{UID},
      TYPE         => 'tp',
      ACTION       => "$attr->{ID}:$attr->{TP_ID}",
      D            => $day,
      M            => $month,
      Y            => $year,
      MODULE       => 'Internet',
      COMMENTS     => $comments,
      ADMIN_ACTION => 1
    });

    if ($Schedule->{errno}) {
      return $Errors->throw_error(1360013);
    }
    else {
      return {
        result  => 'OK',
        message => 'TARIFF_SCHEDULE_SET',
      };
    }
  }
  else {
    if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00' && !$Internet->{STATUS}) {
      $attr->{ACTIVATE} = $main::DATE;
    }

    $attr->{PERSONAL_TP} = 0.00;
    $Internet->user_change($attr);

    if ($Internet->{TP_INFO} && $Internet->{TP_INFO}->{MONTH_FEE} && $Internet->{TP_INFO}->{MONTH_FEE} < $Users->{DEPOSIT}) {
      $Internet->{STATUS} = 0;
      $attr->{ACTIVE_SERVICE} = 1;
    }

    if (!$Internet->{errno}) {
      if (!$Internet->{STATUS} && $attr->{GET_ABON}) {
        ::service_get_month_fee($Internet, {
          QUITE       => 1,
          RECALCULATE => $attr->{RECALCULATE} || 0,
          #USER_INFO   =>
        });
        if ($attr->{ACTIVE_SERVICE}) {
          $attr->{STATUS} = 0;
          $Internet->user_change($attr);
        }
      }

      return {
        result  => 'OK',
        message => 'TARIFF_CHANGED',
      };
    }
    else {
      return $Internet;
    }
  }
}

#**********************************************************
=head2 service_get_abon_date($attr) internet get abon date for user

  Arguments:
    $attr
      SERVICE - Internet Service obj
      USER_INFO - User obj

  Returns:
    $abon_date: string - date of user fee

=cut
#**********************************************************
sub service_get_abon_date {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};
  my $user_info = $attr->{USER_INFO};

  my $abon_date = '';

  if (
    ($Service->{MONTH_ABON} && $Service->{MONTH_ABON} > 0)
      && !$Service->{STATUS}
      && !$user_info->{DISABLE}
      && (($user_info->{DEPOSIT} ? $user_info->{DEPOSIT} : 0) + ($user_info->{CREDIT} ? $user_info->{CREDIT} : 0) > 0
      || $Service->{POSTPAID_ABON}
      || ($Service->{PAYMENT_TYPE} && $Service->{PAYMENT_TYPE} == 1))
  ) {
    if ($Service->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split('-', $Service->{ACTIVATE}, 3);
      $M--;
      $abon_date = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 +
        (($self->{conf}->{START_PERIOD_DAY}) ? $self->{conf}->{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split('-', $main::DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      if ($self->{conf}->{START_PERIOD_DAY}) {
        $D = $self->{conf}->{START_PERIOD_DAY};
      }
      else {
        $D = '01';
      }
      $abon_date = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  return $abon_date;
}

#**********************************************************
=head2 user_preproccess($uid, $attr)

  Arguments:
    $uid
    $attr
      SKIP_ERRORS
      STATIC_IPV6_POOL
      STATUS
      REGISTRATION

  Results:
    $attr

=cut
#**********************************************************
sub user_preproccess {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $web_admin_id = $self->{conf}{USERS_WEB_ADMIN_ID} || 3;
  my $system_aid = $self->{conf}{SYSTEM_ADMIN_ID} || 2;

  if (!in_array($self->{admin}->{AID}, [ $web_admin_id, $system_aid ]) && $self->{admin}->{permissions}{0}) {
    my $permits = $self->{admin}->{permissions}{0};
    delete($attr->{TP_ID}) if (!$permits->{10} && !$attr->{REGISTRATION});
    delete($attr->{STATUS}) if (!$permits->{18} && !$attr->{REGISTRATION});
    delete($attr->{SERVICE_ACTIVATE}) if (!$permits->{19} && !$attr->{REGISTRATION});
    delete($attr->{SERVICE_EXPIRE}) if (!$permits->{20} && !$attr->{REGISTRATION});
    delete($attr->{PERSONAL_TP}) if (!$permits->{25});
  }

  if ((!$attr->{IP} || $attr->{IP} eq '0.0.0.0') && $attr->{STATIC_IP_POOL}) {
    #require Internet::User_ips;
    $attr->{IP} = $self->get_static_ip($attr->{STATIC_IP_POOL});
    if ($self->{error}) {
      return $attr;
    }
  }

  if ($attr->{SERVER_VLAN} && !$attr->{VLAN}) {
    $attr->{VLAN} = $self->get_vlan($attr);
  }

  if ($attr->{STATIC_IPV6_POOL}) {
    ($attr->{IPV6}, $attr->{IPV6_MASK}, $attr->{IPV6_TEMPLATE},
      $attr->{IPV6_PD}, $attr->{IPV6_PREFIX_MASK}, $attr->{IPV6_PD_TEMPLATE}) = $self->get_static_ip($attr->{STATIC_IPV6_POOL}, { IPV6 => 1 });

    if ($uid > 65000) {
      $Errors->throw_error(1360019);
      #$html->message('warn', "UID too high $uid for IPv6");
    }

    my $uid_hex = sprintf("%x", $uid);
    my $id_hex = sprintf("%x", $attr->{ID} || 0);
    $attr->{IPV6} = $attr->{IPV6_TEMPLATE};
    $attr->{IPV6} =~ s/\{UID\}/$uid_hex/xg;
    $attr->{IPV6} =~ s/\{ID\}/$id_hex/gx;

    $attr->{IPV6_PREFIX} = $attr->{IPV6_PD_TEMPLATE};
    $attr->{IPV6_PREFIX} =~ s/\{UID\}/$uid_hex/xg;
    $attr->{IPV6_PREFIX} =~ s/\{ID\}/$id_hex/gx;
  }

  #Check duplicate CID & format CID
  if ($attr->{CID} && $attr->{CID} !~ m/ANY/xi) {
    require Abills::Filters;
    Abills::Filters->import('_mac_former');
    if (!$self->{conf}{INTERNET_CID_FORMAT}) {
      $attr->{CID} = Abills::Filters::_mac_former($attr->{CID});
    }
    my $list = $Internet->user_list({
      LOGIN     => '_SHOW',
      CID       => $attr->{CID},
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]{uid} && $list->[0]{uid} != $uid) {
      #$message = "CID/MAC: $attr->{CID} $lang{EXIST}. $lang{LOGIN}: " . $html->button($list->[0]->{login},
      #  "index=15&UID=" . $list->[0]{uid});
      $Errors->throw_error(1360020, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });
      $attr->{RETURN} = 1360020;
    }
  }

  #Format CPE_MAC
  if ($attr->{CPE_MAC} && $self->{conf}{INTERNET_CPE_FORMAT}) {
    require Abills::Filters;
    Abills::Filters->import('_mac_former');
    $attr->{CPE_MAC} = Abills::Filters::_mac_former($attr->{CPE_MAC});
  }

  #Check dublicate IP
  if ($attr->{IP} && $attr->{IP} =~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/x && $attr->{IP} ne '0.0.0.0') {
    my $list = $Internet->user_list({
      IP        => $attr->{IP},
      LOGIN     => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} != $uid) {
      $Errors->throw_error(1360018, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });

      if (!$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  #Check duplicate SVLAN ans CVLAN
  if ($self->{conf}{INTERNET_CHECK_VLANS} && $attr->{SERVER_VLAN} && $attr->{VLAN}) {
    my $list = $Internet->user_list({
      SERVER_VLAN => $attr->{SERVER_VLAN},
      VLAN        => $attr->{VLAN},
      CID         => $self->{conf}{INTERNET_CHECK_VLANS_WITHOUT_CID} ? '_SHOW' : ($attr->{CID} || "_SHOW"),
      LOGIN       => '_SHOW',
      COLS_NAME   => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $Errors->throw_error(1360021, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });

      if (!$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }
  }

  if ($attr->{NAS_ID} && $attr->{PORT}) {
    my $list = $Internet->user_list({
      NAS_ID    => $attr->{NAS_ID},
      PORT      => $attr->{PORT},
      LOGIN     => "_SHOW",
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $Errors->throw_error(1360022, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });

      if ($self->{conf}{INTERNET_PROHIBIT_DUPLICATE_NAS_PORT} && !$attr->{SKIP_ERRORS}) {
        $attr->{RETURN} = 1;
        return $attr;
      }
    }

    if ($attr->{PORT} =~ m/^\d+&/x) {
      require Equipment;
      Equipment->import();
      my $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});

      my $equipment_info = $Equipment->_info($attr->{NAS_ID});
      if ($equipment_info->{PORTS_WITH_EXTRA} < $attr->{PORT}) {
        $Errors->throw_error(1360023, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });
        ##$html->message('warn', $lang{WARNING}, $lang{ERR_NO_WRONG_PORT_SELECTED});

        if (!$attr->{SKIP_ERRORS}) {
          $attr->{RETURN} = 1;
          return $attr;
        }
      }
    }
  }

  #Check duplicate CPE MAC
  if ($attr->{CPE_MAC} && $attr->{CPE_MAC} !~ m/ANY/xi) {
    my $list = $Internet->user_list({
      CPE_MAC   => $attr->{CPE_MAC},
      LOGIN     => "_SHOW",
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} > 0 && $list->[0]->{uid} && $list->[0]->{uid} != $uid) {
      $Errors->throw_error(1360024, { errextra => { UID => $list->[0]->{uid}, LOGIN => $list->[0]{login} } });

      if (!$attr->{SKIP_ERRORS} && !$self->{conf}{INTERNET_ALLOW_MAC_DUPS}) {
        $attr->{RETURN} = 1360024;
        return $attr;
      }
    }
  }

  if ($attr->{RESET}) {
    $attr->{PASSWORD} = '__RESET__';
  }
  elsif ($attr->{newpassword}) {
    if (!$attr->{RESET_PASSWD} && length($attr->{newpassword}) < $self->{conf}{PASSWD_LENGTH}) {
      $attr->{RETURN} = 1360027;
    }
    elsif ($attr->{newpassword} eq $attr->{confirm}) {
      $attr->{PASSWORD} = $attr->{newpassword};
    }
    elsif ($attr->{newpassword} ne $attr->{confirm}) {
      $attr->{RETURN} = 1360026;
    }
  }

  if ($attr->{add} && !$attr->{TP_ID}) {
    if (!$attr->{SKIP_ERRORS}) {
      $attr->{RETURN} = 1360025;
    }
  }

  if ($attr->{RETURN}) {
    $Errors->throw_error($attr->{RETURN});
  }

  return $attr;
}

#**********************************************************
=head2 user_add($attr)

  Arguments:
    $attr
      SKIP_MONTH_FEE
      QUITE
      UID
      ID
      STATUS
      USER_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || 0;
  $attr = $self->user_preproccess($uid, $attr);

  # if ($attr->{RETURN}) {
  #   return 0;
  # }
  if ($self->{errno}) {
    return 0;
  }

  $Internet->user_add($attr);
  my $service_id = $Internet->{ID} || 0;
  if (!$Internet->{errno}) {
    #Make month fee
    $Internet->user_info($uid, { ID => $service_id });
    if (!$attr->{STATUS} && !$attr->{SKIP_MONTH_FEE}) {
      ::service_get_month_fee($Internet, {
        REGISTRATION               => 1,
        DO_NOT_USE_GLOBAL_USER_PLS => $attr->{DO_NOT_USE_GLOBAL_USER_PLS} || 0,
        USER_INFO                  => $attr->{USER_INFO}
      });
    }
    else {
      ::_external('', { EXTERNAL_CMD => 'Internet', %{$Internet} });
    }

    $attr->{ID} = $service_id;

    if ($attr->{REGISTRATION}) {
      $self->{INTERNET} = $Internet;

      return $service_id;
    }
    else {
      if ($attr->{API}) {
        return {
          result => 'Successfully added',
          id     => $service_id,
          uid    => $uid,
        }
      }
      else {
        $self->{ACTION} = 'ADDED';
        #return 1;
        #$html->message('info', $lang{INTERNET}, $lang{ADDED}) if (!$attr->{QUITE});
      }
    }

    ipoe_activate_manual($attr);
  }

  if (!$service_id) {
    if ($attr->{API}) {
      return {
        errno  => $Internet->{errno},
        error  => 961,
        errstr => $Internet->{errstr},
      }
    }
    else {
      $Errors->throw_error(1360002);
      ##_error_show($Internet, { ID => 961, MODULE => 'Internet' });
    }
    return 0;
  }

  return $service_id;
}


#**********************************************************
=head2 user_del($attr)

  Arguments:
    UID
    ID
    DOMAIN_ID

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $Internet->user_del($attr);

  $self->{errno} = $Internet->{errno};
  $self->{errstr} = $Internet->{errstr};
  $self->{affected} = $Internet->{_SERVICE_DELETED};

  return (!$Internet->{errno}) ? 1 : 0;
}


#**********************************************************
=head2 user_info($attr)

  Arguments:
    UID
    ID
    DOMAIN_ID

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  $Internet->user_info($attr->{UID}, {
    DOMAIN_ID => $attr->{DOMAIN_ID},
    ID        => $attr->{ID}
  });

  return $Internet;
}

#**********************************************************
=head2 user_change($attr)

  Arguments:
    UID
    ID
    QUITE
    USER_INFO
    GET_ABON

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || 0; # $LIST_PARAMS{UID} || 0;
  my $web_admin_id = $self->{conf}{USERS_WEB_ADMIN_ID} || 3;
  my $system_aid = $self->{conf}{SYSTEM_ADMIN_ID} || 2;
  my $user_info = $attr->{USER_INFO};

  if (!in_array($self->{admin}->{AID}, [ $web_admin_id, $system_aid ]) && !$self->{admin}->{permissions}{0}{4}) {
    return {
      errno  => 950,
      errstr => 'ACCESS DENIED',
    } if ($attr->{API});
    ##$html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { ID => 1360950 });
    $Errors->throw_error(1360950);
    return 0;
  }

  $attr = $self->user_preproccess($uid, $attr);
  if ($attr->{RETURN}) {
    return 0;
  }

  if (in_array('Equipment', @{$self->{MODULES}})) {
    $self->user_change_nas($attr);
  }

  $Internet->user_change({
    %$attr,
    DETAIL_STATS => $attr->{DETAIL_STATS} || 0,
    IPN_ACTIVATE => $attr->{IPN_ACTIVATE} || 0
  });

  if (!$attr->{STATUS}
    || (defined($attr->{STATUS}) && in_array($attr->{STATUS}, [ 0, 3, 5 ]))) {
    require Shedule;
    Shedule->import();
    my $Shedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
    my $list = $Shedule->list({
      UID       => $uid,
      MODULE    => 'Internet',
      TYPE      => 'status',
      ACTION    => '0',
      COLS_NAME => 1
    });

    if ($Shedule->{TOTAL} == 1) {
      $Shedule->del({
        UID => $uid,
        IDS => $list->[0]->{shedule_id}
      });
    }

    ipoe_activate_manual($attr);
  }

  if (!$Internet->{errno}) {
    my $month_fee = 0;
    if (!$attr->{STATUS} && ($attr->{GET_ABON} || !$attr->{TP_ID})) {
      if ($self->{conf}{INTERNET_SKIP_FIRST_DAY_FEE} && !$Internet->{STATUS} && $Internet->{TP_INFO}{ABON_DISTRIBUTION}) {
        #print "Skip fee / $Internet->{TP_INFO}{ABON_DISTRIBUTION}";
      }
      elsif ((!$self->{admin}->{permissions}{0}{25} && $Internet->{OLD_PERSONAL_TP} > 0) ||
        ($attr->{PERSONAL_TP} && $attr->{PERSONAL_TP} > 0
          && $Internet->{OLD_PERSONAL_TP} == $attr->{PERSONAL_TP}
          && $Internet->{OLD_STATUS} == ($attr->{STATUS} || 0))) {

        my $external_cmd = '_EXTERNAL_CMD';
        my $module = 'Internet';
        $external_cmd = uc($module) . $external_cmd;
        if ($self->{conf}{$external_cmd}) {
          if (!_external($self->{conf}{$external_cmd}, { %{ ($user_info) ? $user_info : {} }, %$Internet, %$attr })) {
            $Errors->throw_error(1360028);
            #print "Error: external cmd '$self->{conf}{$external_cmd}'\n";
          }
        }
      }
      else {
        # if (!$permissions{0}{25}) {
        #   delete $Internet->{PERSONAL_TP};
        # }
        $month_fee = 1;
        if ($self->{conf}{INTERNET_SKIP_CURMONTH_ACTIVATE_FEE}) {
          our $DATE   = strftime("%Y-%m-%d", localtime(time));
          my ($Y, $M) = split('-', $DATE, 3);

          $self->{admin}->action_list({
            TYPE      => '14',
            #ACTION    => '0->3',
            UID       => $uid,
            MODULE    => 'Internet',
            MONTH     => "$Y-$M",
            PAGE_ROWS => 1,
            COLS_NAME => 1,
            SORT      => 'id',
            DESC      => 'desc'
          });

          if ($self->{admin}->{TOTAL} && $self->{admin}->{TOTAL} > 0) {
            $month_fee = 0;
          }
        }

        if ($month_fee) {
          ::service_get_month_fee($Internet, { USER_INFO => $attr->{USER_INFO} });
        }
      }
    }

    if ($attr->{STATUS}) {
      ::_external('', { EXTERNAL_CMD => 'Internet', %{$Internet} });
    }
    elsif (! $attr->{GET_ABON}) {
      ::_external('', { EXTERNAL_CMD => 'Internet', %{$Internet} });
    }

    if ($Internet->{CHG_STATUS} && $Internet->{CHG_STATUS} eq '0->3' && $self->{conf}{INTERNET_HOLDUP_COMPENSATE}) {
      my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
      $Internet->{TP_INFO_OLD} = $Tariffs->info(0, { TP_ID => $Internet->{TP_ID} });
      if ($Internet->{TP_INFO_OLD}->{PERIOD_ALIGNMENT}) {
        $Internet->{TP_INFO}->{MONTH_FEE} = 0;
        ::service_get_month_fee($Internet, { RECALCULATE => 1, USER_INFO => $attr->{USER_INFO} });
      }
    }

    #$FORM{chg} = $attr->{ID};
    if ($attr->{API}) {
      return {
        result => 'Successfully changed'
      }
    }
    else {
      ## $html->message('info', $lang{INTERNET}, $lang{CHANGED}) if (! $attr->{QUITE});
    }

    return 0 if ($attr->{REGISTRATION});
  }

  return 1;
}

#**********************************************************
=head2 ipoe_activate_manual($attr)

  Arguments:
    $attr
      IPN_ACTIVATE
      IP
      ID
      USER_INFO

  Result:
    TRUE or FALSE

=cut
#**********************************************************
sub ipoe_activate_manual {
  my ($attr) = @_;

  if ($attr->{IPN_ACTIVATE}
    && ($attr->{IP} && $attr->{IP} ne '0.0.0.0')
  ) {
    require Internet::Ipoe_mng;

    ::internet_ipoe_activate({
      %$attr,
      ADMIN_ACTIVATE => 1,
      IP             => $attr->{IP},
      UID            => $attr->{UID},
      ID             => $attr->{ID},
      ACTIVE         => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 get_static_ip($pool_id) - Get static ip from pool

  Arguments:
    $pool_id   - IP pool ID
    $attr
      SILENT
      IPV6

  Returns:
    IP address

=cut
#**********************************************************
sub get_static_ip {
  my $self = shift;
  my ($pool_id, $attr) = @_;
  my $ip = '0.0.0.0';

  require Nas;
  Nas->import();
  my $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});
  my $Ip_pool = $Nas->ip_pools_info($pool_id);

  if ($attr->{IPV6}) {
    return $Ip_pool->{IPV6_PREFIX}, $Ip_pool->{IPV6_MASK}, $Ip_pool->{IPV6_TEMPLATE},
      $Ip_pool->{IPV6_PD}, $Ip_pool->{IPV6_PD_MASK}, $Ip_pool->{IPV6_PD_TEMPLATE};
  }

  #if(_error_show($Ip_pool, { ID => 117, MESSAGE => 'IP POOL:'. ($pool_id || '') })) {
  if ($Ip_pool->{error}) {
    $Errors->throw_error(1360017);
    return '0.0.0.0';
  }

  my @arr_ip_skip = $Ip_pool->{IP_SKIP} ? split(/,\s?|;\s?/x, $Ip_pool->{IP_SKIP}) : ();

  my $start_ip = ip2int($Ip_pool->{IP});
  my $end_ip = $start_ip + $Ip_pool->{COUNTS};

  my %users_ips = ();

  my $Internet_list = $Internet->user_list({
    PAGE_ROWS => 1000000,
    IP        => ">=$Ip_pool->{IP}",
    SKIP_GID  => 1,
    GROUP_BY  => 'internet.id',
    COLS_NAME => 1
  });

  foreach my $line (@$Internet_list) {
    $users_ips{ $line->{ip_num} } = 1;
  }

  for (my $ip_cur = $start_ip; $ip_cur < $end_ip; $ip_cur++) {
    if (!$users_ips{ $ip_cur }) {
      my $ip_ = int2ip($ip_cur);

      if (!in_array($ip_, \@arr_ip_skip)) {
        return $ip_;
      }
    }
  }

  if ($Ip_pool->{NEXT_POOL_ID}) {
    return $self->get_static_ip($Ip_pool->{NEXT_POOL_ID});
  }

  #$html->message('err', $lang{ERROR}, $lang{ERR_NO_FREE_IP_IN_POOL});
  $Errors->throw_error(1360005);

  return $ip;
}

#**********************************************************
=head2 get_vlan($attr)

  Arguments:
    $attr
      SERVER_VLAN
      VLAN

  Results:
    $free_vlan

=cut
#**********************************************************
sub get_vlan {
  my $self = shift;
  my ($attr) = @_;

  my $vlan = 0;

  my $internet_users = $Internet->user_list({
    SERVER_VLAN => $attr->{SERVER_VLAN},
    VLAN        => '!',
    GROUP_BY    => 'internet.id',
    SORT        => 'MAX(internet.vlan)',
    DESC        => 'DESC',
    SKIP_GID    => 1,
    PAGE_ROWS   => 1,
    COLS_NAME   => 1
  });

  if (!$Internet->{errno}) {
    if ($Internet->{TOTAL} && $Internet->{TOTAL} > 0) {
      my $last_vlan = $internet_users->[0]{vlan};
      $vlan = ($last_vlan && $last_vlan < 4098) ? ($last_vlan + 1) : $attr->{VLAN};
    }
    else {
      $vlan = 1;
    }
  }

  return $vlan;
}

#**********************************************************
=head2 user_change_nas($attr)

  Arguments:
    $attr
      EQUIPMENT
      SERVER_VLAN
      VLAN
      NAS_ID
      PORT

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub user_change_nas {
  my $self = shift;
  my ($attr) = @_;

  #load_module('Equipment');
  require Equipment;
  Equipment->import();
  my $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});

  if ($attr->{SERVER_VLAN} && $attr->{VLAN} && (!$attr->{NAS_ID} || !$attr->{PORT})) {
    my $Equipment_list = $Equipment->cvlan_svlan_list({
      NAS_ID      => '_SHOW',
      NAS_NAME    => '_SHOW',
      VLAN        => $attr->{VLAN},
      SERVER_VLAN => $attr->{SERVER_VLAN},
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      PAGE_ROWS   => 100000,
    });

    if ($Equipment->{TOTAL} == 1) {
      $attr->{NAS_ID} = $Equipment_list->[0]{NAS_ID};
      $attr->{NAS_ID1} = $Equipment_list->[0]{NAME};
      $attr->{PORT} = $Equipment_list->[0]{PORT};
    }
    else {
      $Equipment_list = $Equipment->cvlan_svlan_list({
        NAS_ID      => '_SHOW',
        ONU_VLAN    => $attr->{VLAN},
        SERVER_VLAN => $attr->{SERVER_VLAN},
        ONU         => 1,
        COLS_NAME   => 1,
        COLS_UPPER  => 1,
        PAGE_ROWS   => 100000,
      });

      if ($Equipment->{TOTAL} == 1) {
        $attr->{NAS_ID} = $Equipment_list->[0]{NAS_ID};
        $attr->{NAS_ID1} = $Equipment_list->[0]{NAME};
        $attr->{PORT} = $Equipment_list->[0]{ONU_DHCP_PORT};
      }
      else {
        $attr->{NAS_ID} = 0;
        $attr->{NAS_ID1} = 0;
        $attr->{PORT} = 0;
      }
    }
  }
  elsif ($attr->{NAS_ID} && $attr->{PORT}) {
    my $Equipment_server_vlan = $Equipment->_list({
      NAS_ID      => $attr->{NAS_ID},
      TYPE_NAME   => '_SHOW',
      SERVER_VLAN => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      PAGE_ROWS   => 100000,
    });

    if ($Equipment->{TOTAL}) {
      if ($Equipment_server_vlan->[0] && $Equipment_server_vlan->[0]{type_name} && $Equipment_server_vlan->[0]{type_name} eq "Switch") {
        my $Equipment_list = $Equipment->port_list({
          NAS_ID     => $attr->{NAS_ID},
          PORT       => $attr->{PORT},
          VLAN       => '_SHOW',
          COLS_NAME  => 1,
          COLS_UPPER => 1,
          PAGE_ROWS  => 100000,
        });
        if ($Equipment->{TOTAL}) {
          $attr->{VLAN} = $Equipment_list->[0]{VLAN};

          if ($Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
      }

      if ($Equipment_server_vlan->[0] &&
        $Equipment_server_vlan->[0]{type_name} eq "PON") {
        my $Equipment_list = $Equipment->onu_list({
          ONU_DHCP_PORT => $attr->{PORT},
          NAS_ID        => $attr->{NAS_ID},
          VLAN          => '_SHOW',
          COLS_NAME     => 1,
          COLS_UPPER    => 1,
          PAGE_ROWS     => 100000,
        });

        if ($Equipment->{TOTAL}) {
          $attr->{VLAN} = $Equipment_list->[0]{VLAN};

          if ($attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
        else {
          $attr->{VLAN} = 0;

          if ($Equipment_server_vlan->[0]{SERVER_VLAN}) {
            $attr->{SERVER_VLAN} = $Equipment_server_vlan->[0]{SERVER_VLAN};
          }
        }
      }
    }
  }

  return 1;
}


1;
