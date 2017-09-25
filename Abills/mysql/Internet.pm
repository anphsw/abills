package Internet;

=head1 NAME

  Internet module managment functions

=cut

use strict;
use parent qw( main );
use Tariffs;
use Users;
use Fees;
use POSIX qw(strftime mktime);

our $VERSION = 1.00;
my $MODULE = 'Internet';

my ($admin, $CONF);

my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    module_name => $MODULE,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 info($uid, $attr) User service information

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE = '';

  if (defined($attr->{LOGIN}) && $attr->{LOGIN} ne '') {
    my $users = Users->new($self->{db}, $admin, $self->{conf});
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE internet.uid='$uid'";
  }

  $WHERE = "WHERE internet.uid='$uid'";

  my $ORDER_BY = '';
  if($attr->{ID}) {
    $WHERE .= " AND internet.id='$attr->{ID}'";
  }
  else {
    $ORDER_BY = 'ORDER BY internet.id DESC';
  }

  if (defined($attr->{IP})) {
    $WHERE = "WHERE internet.ip=INET_ATON('$attr->{IP}')";
  }

  my $domain_id = 0;
  if ($admin->{DOMAIN_ID}) {
    $domain_id = $admin->{DOMAIN_ID};
  }
  elsif ($attr->{DOMAIN_ID}) {
    $domain_id = $attr->{DOMAIN_ID};
  }

  $self->query2("SELECT internet.*,
   internet.login AS internet_login,
   tp.name AS tp_name,
   tp.id AS tp_num,
   INET_NTOA(internet.ip) AS ip,
   INET_NTOA(internet.netmask) AS netmask,
   internet.disable AS status,
   tp.gid AS tp_gid,
   tp.month_fee AS month_abon,
   tp.day_fee AS day_abon,
   tp.postpaid_monthly_fee AS postpaid_abon,
   tp.payment_type,
   internet.activate AS service_activate,
   internet.expire AS service_expire,
   tp.abon_distribution,
   tp.credit AS tp_credit,
   tp.priority AS tp_priority,
   tp.activate_price AS tp_activate_price,
   tp.age AS tp_age,
   tp.filter_id AS tp_filter_id,
   tp.period_alignment AS tp_period_alignment,
   tp.fixed_fees_day,
   tp.comments,
   tp.reduction_fee,
   tp.user_credit_limit,
   DECODE(internet.password, '$self->{conf}->{secretkey}') AS password
     FROM internet_main internet
     LEFT JOIN tarif_plans tp ON (tp.tp_id = internet.tp_id)
   $WHERE
   $ORDER_BY;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    SIMULTANEONSLY => 0,
    STATUS         => 0,
    IP             => '0.0.0.0',
    NETMASK        => '255.255.255.255',
    SPEED          => 0,
    FILTER_ID      => '',
    CID            => '',
    CALLBACK       => 0,
    PORT           => 0,
    JOIN_SERVICE   => 0,
    TURBO_MODE     => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 add($attr) - Add service

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LOGIN} = $attr->{INTERNET_LOGIN} if($attr->{INTERNET_LOGIN});

  if (! $attr->{DV_SKIP_FEE} && $attr->{TP_ID} > 0 && !$attr->{STATUS}) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);

    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID} || undef
    });

    #Take activation price
    if ($Tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $self->{conf});
      $user->info($attr->{UID});

      if ($self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
        $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
      }

      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = "Active price too hight";
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $self->{conf});
      $fees->take($user, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });
      $Tariffs->{ACTIV_PRICE} = 0;
    }
  }

  if(!$attr->{NETMASK}) {
    $attr->{NETMASK}='255.255.255.255';
  }

  $self->query_add('internet_main', {
    %$attr,
    REGISTRATION => 'now()',
    DISABLE      => $attr->{STATUS},
    PASSWORD     => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
  });

  return [ ] if ($self->{errno});

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, '', {
    TYPE    => 1,
    INFO    => ['TP_ID', 'DV_LOGIN', 'STATUS', 'EXPIRE', 'IP', 'CID'],
    REQUEST => $attr
  });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LOGIN} = $attr->{INTERNET_LOGIN} if($attr->{INTERNET_LOGIN});
  if (!$attr->{NAS_ID}) {
    $attr->{NAS_ID} = $attr->{NAS_ID1};
  }
  delete $attr->{ID} if(! $attr->{ID});

  $attr->{DISABLE}=$attr->{STATUS};
  $attr->{EXPIRE}=$attr->{SERVICE_EXPIRE};
  $attr->{ACTIVATE}=$attr->{SERVICE_ACTIVATE};

  my $old_info = $self->info($attr->{UID}, { ID => $attr->{ID} });
  $self->{OLD_STATUS} = $old_info->{STATUS};

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});

    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $Tariffs->info(0, {
      TP_ID     => $old_info->{TP_ID},
      DOMAIN_ID => $user->{DOMAIN_ID} || $admin->{DOMAIN_ID}
    });

    %{ $self->{TP_INFO_OLD} } = %{ $Tariffs };
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $attr->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    if ($self->{conf}->{FEES_PRIORITY} && $self->{conf}->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
      $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
    }

    my $skip_change_fee = 0;
    if ($self->{conf}->{DV_TP_CHG_FREE}) {
      my ($y, $m, $d) = split(/-/, $user->{REGISTRATION}, 3);
      my $cur_date = time();
      my $registration = POSIX::mktime(0, 0, 0, $d, ($m - 1), ($y - 1900));
      if (($cur_date - $registration) / 86400 > $self->{conf}->{DV_TP_CHG_FREE}) {
        $skip_change_fee = 1;
      }
    }

    #Active TP
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $Tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0 && $Tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = "Active price too hight";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});
      $Fees->take($user, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}' });

      $Tariffs->{ACTIV_PRICE} = 0;
    }
    # Change TP
    elsif (!$skip_change_fee
      && $Tariffs->{CHANGE_PRICE} > 0
      && (($self->{TP_INFO_OLD}->{PRIORITY} || 0) - $Tariffs->{PRIORITY} > 0
        || ($self->{TP_INFO_OLD}->{PRIORITY} || 0) + $Tariffs->{PRIORITY} == 0)
      && !$attr->{NO_CHANGE_FEES})
    {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $Tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        $self->{errstr} = "Change price too hight";
        return $self;
      }

      my $Fees = Fees->new($self->{db}, $admin, $self->{conf});
      $Fees->take($user, $Tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE TP" });
    }

    if ($Tariffs->{AGE} > 0) {
      $attr->{EXPIRE} = POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $Tariffs->{AGE}));

      eval { require Date::Calc };
      if (!$@) {
        Date::Calc->import( qw/Add_Delta_Days/ );

        my (undef, undef, undef,$mday,$mon,$year,undef,undef,undef) = localtime(time);
        $year += 1900;
        $mon++;
        ($year,$mon,$mday) = Date::Calc::Add_Delta_Days($year, $mon, $mday, $Tariffs->{AGE});
        $attr->{EXPIRE} ="$year-$mon-$mday";
      }
    }
#    else {
#      $attr->{EXPIRE} = "0000-00-00";
#    }
  }
  elsif (($old_info->{STATUS} && $old_info->{STATUS} == 3)
    && $attr->{STATUS} == 0
    && $attr->{STATUS_DAYS}) {
    my $user = Users->new($self->{db}, $admin, $self->{conf});
    $user->info($attr->{UID});
    my $fees = Fees->new($self->{db}, $admin, $self->{conf});
    #period : sum
    my (undef, $sum) = split(/:/, $self->{conf}->{DV_REACTIVE_PERIOD}, 2);
    $fees->take($user, $sum, { DESCRIBE => "REACTIVE" });
  }
  elsif (($old_info->{STATUS}
         && ($old_info->{STATUS} == 1
           || $old_info->{STATUS} == 2
           || $old_info->{STATUS} == 3
           || $old_info->{STATUS} == 4
           || $old_info->{STATUS} == 5))
         && defined($attr->{STATUS}) && $attr->{STATUS} == 0) {
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $admin);
    $self->{TP_INFO} = $Tariffs->info(0, {
      TP_ID     => $old_info->{TP_ID},
      DOMAIN_ID => $admin->{DOMAIN_ID}
    });

    #Alignment for hold up
    if($old_info->{STATUS} == 3 && ! $self->{TP_INFO}->{PERIOD_ALIGNMENT} && ! $self->{TP_INFO}->{ABON_DISTRIBUTION}) {
      delete ($self->{TP_INFO});
    }
  }

  #$attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes2(
    {
      CHANGE_PARAM => 'UID'. (($attr->{ID}) ? ',ID' : q{}),
      TABLE        => 'internet_main',
      DATA         => $attr
    }
  );

  $self->{TP_INFO}->{ACTIV_PRICE} = 0 if ($self->{OLD_STATUS} != 2);

  if($self->{AFFECTED}) {
    $self->info($attr->{UID}, { ID => $attr->{ID} || undef });
  }

  return $self;
}

#**********************************************************
=head2 del(attr); Delete user service

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('internet_main', $attr, { uid => $self->{UID} });
  $self->query_del('internet_log', undef, { uid => $self->{UID} });

  $admin->action_add($self->{UID}, "$self->{UID} ID: $attr->{ID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
=head2 list($attr) - Internet users list

  Arguments:
    GROUP_BY

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'u.uid';
  if ($attr->{CID}) {
    $attr->{CID}=~s/[\:\-\.]/\*/g;
  }

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my $WHERE =  $self->search_former($attr, [
      ['INTERNET_LOGIN', 'STR', 'internet.login',  'internet.login AS internet_login' ],
      ['IP',             'IP',  'internet.ip',     'internet.ip AS ip_num'        ], #'INET_NTOA(internet.ip) AS ip' ],
      ['IP_NUM',         'IP',  'internet.ip',     'internet.ip AS ip_num'        ],
      ['NETMASK',        'IP',  'internet.netmask', 'INET_NTOA(internet.netmask) AS netmask' ],
      ['CID',            'STR', 'internet.cid',                           1 ],
      ['CPE_MAC',        'STR', 'internet.cpe_mac',                       1 ],
      ['VLAN',           'INT', 'internet.vlan',                          1 ],
      ['SERVER_VLAN',    'INT', 'internet.server_vlan',                   1 ],
      ['JOIN_SERVICE',   'INT', 'internet.join_service',                  1 ],
      ['SIMULTANEONSLY', 'INT', 'internet.logins',                        1 ],
      ['SPEED',          'INT', 'internet.speed',                         1 ],
      ['NAS_ID',         'STR', 'internet.nas_id',                        1 ],
      ['PORT',           'INT', 'internet.port',                          1 ],
      ['ALL_FILTER_ID',  'STR', 'IF(internet.filter_id<>\'\', internet.filter_id, tp.filter_id) AS filter_id', 1 ],
      ['FILTER_ID',      'STR', 'internet.filter_id',                     1 ],
      ['TP_ID',          'INT', 'internet.tp_id',                         1 ],
      ['TP_NAME',        'STR', 'tp.name AS tp_name',                     1 ],
      ['TP_COMMENTS',    'STR', 'tp.comments', 'tp.comments AS tp_comments' ],
      ['TP_CREDIT',      'INT', 'tp.credit',       'tp.credit AS tp_credit' ],
      ['ONLINE',         'INT', 'c.uid',                  'c.uid AS online' ],
      ['ONLINE_IP',      'INT', 'INET_NTOA(c.framed_ip_address)', 'INET_NTOA(c.framed_ip_address) AS online_ip' ],
      ['ONLINE_DURATION','INT', 'c.uid',  'if(c.lupdated>UNIX_TIMESTAMP(c.started), c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS online_duration' ],
      ['ONLINE_CID',     'INT', 'c.CID',              'c.CID AS online_cid' ],
      ['MONTH_FEE',      'INT', 'tp.month_fee',                           1 ],
      ['ABON_DISTRIBUTION', 'INT', 'tp.abon_distribution',                1 ],
      ['DAY_FEE',        'INT', 'tp.day_fee',                             1 ],
      ['PERSONAL_TP',    'INT', 'internet.personal_tp',                   1 ],
      ['PAYMENT_TYPE',   'INT', 'tp.payment_type',                        1 ],
      ['INTERNET_PASSWORD', '', '',  "DECODE(internet.password, '$CONF->{secretkey}') AS internet_password" ],
      ['INTERNET_STATUS','INT', 'internet.disable AS internet_status',    1 ],
      ['DV_STATUS',      'INT', 'internet.disable AS internet_status',    1 ],
      ['DV_STATUS_ID',   'INT', 'internet.disable AS internet_status_id', 1 ],
      ['SERVICE_EXPIRE', 'DATE','internet.expire AS internet_expire',     1 ],
      ['INTERNET_EXPIRE', 'DATE','internet.expire AS internet_expire',    1 ],
      ['INTERNET_ACTIVATE', 'DATE','internet.activate AS internet_activate',1 ],
      ['DV_STATUS_DATE', '',    '', '(SELECT aa.datetime FROM admin_actions aa WHERE aa.uid=internet.uid AND aa.module=\'Internet\' AND aa.action_type=4
       ORDER BY aa.datetime DESC LIMIT 1) AS internet_status_date' ],
      ['MONTH_TRAFFIC_IN',  'INT', '', "SUM(l.recv) AS month_traffic_in"    ],
      ['MONTH_TRAFFIC_OUT', 'INT', '', "SUM(l.sent) AS month_traffic_out"   ],
      ['UID',            'INT', 'internet.uid',                           1 ],
      ['ID',             'INT', 'internet.id',                            1 ],
      ['IPN_ACTIVATE',   'INT', 'internet.ipn_activate',                  1 ]
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

#  my $where_delimeter = ' AND ';
#  if ( $attr->{_MULTI_HIT} ) {
#    $where_delimeter = ' OR ';
#  }
#
#  $WHERE = ($#WHERE_RULES > -1) ? "WHERE (" . join($where_delimeter, @WHERE_RULES) .')' : '';

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  if ($attr->{USERS_WARNINGS}) {
    my $allert_period = '';
    if ($attr->{ALERT_PERIOD}) {
      $allert_period = "OR  (tp.month_fee > 0  AND IF(u.activate='0000-00-00',
      DATEDIFF(DATE_FORMAT(curdate() + INTERVAL 1 MONTH, '%Y-%m-01'), curdate()),
      DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) IN ($attr->{ALERT_PERIOD}))";
    }

    $self->query2("SELECT u.id AS login,
        pi.email,
        internet.tp_id AS tp_num,
        u.credit,
        b.deposit,
        tp.name AS tp_name,
        tp.uplimit,
        pi.phone,
        pi.fio,
        IF(u.activate='0000-00-00',
          DATEDIFF(DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01'), CURDATE()),
          DATEDIFF(u.activate + INTERVAL 30 DAY, CURDATE())) AS to_next_period,
        $self->{SEARCH_FIELDS}
        u.uid
      FROM users u
      INNER JOIN internet_main internet ON (u.uid=internet.uid)
      INNER JOIN tarif_plans tp ON (internet.tp_id = tp.tp_id)
      $EXT_TABLE
      " . (($WHERE) ? $WHERE . ' AND' : q{}) ."
         u.disable  = 0
         AND internet.disable = 0
         AND b.deposit+u.credit>0
         AND (((tp.month_fee=0 OR tp.abon_distribution=1) AND tp.uplimit > 0 AND b.deposit<tp.uplimit)
             $allert_period
              )

      GROUP BY u.id
      ORDER BY u.id;",
      undef,
      $attr
    );

    return [] if ($self->{errno});

    my $list = $self->{list};
    return $list;
  }
  elsif ($attr->{CLOSED}) {
    $self->query2("SELECT u.id, pi.fio,
       IF(company.id IS NULL, b.deposit, b.deposit),
       IF(u.company_id=0, u.credit,
         IF(u.credit=0, company.credit, u.credit)) AS credit,
       tp.name,
       u.disable,
       u.uid,
       u.company_id,
       u.email,
       u.tp_id,
       IF(l.start is NULL, '-', l.start)
     FROM ( users u, bills b )
     LEFT JOIN users_pi pi ON u.uid=internet.uid
     LEFT JOIN tarif_plans tp ON  (tp.tp_id=internet.tp_id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN internet_log l ON  (l.uid=u.uid)
     WHERE
      u.bill_id=b.id
      AND (b.deposit+u.credit-tp.credit_tresshold<=0)
        OR (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
      OR u.disable=1
     GROUP BY u.id
     ORDER BY $SORT $DESC;"
    );

    my $list = $self->{list};
    return $list;
  }

  if($self->{SEARCH_FIELDS} =~ /online/) {
    $EXT_TABLE .= "
     LEFT JOIN internet_online c ON (c.uid=internet.uid) ";
  }

  if ($attr->{MONTH_TRAFFIC_IN} || $attr->{MONTH_TRAFFIC_OUT}) {
    $EXT_TABLE .= "
     LEFT JOIN internet_log l ON (l.uid=internet.uid AND DATE_FORMAT(l.start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')) ";
  }

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      u.uid,
      internet.tp_id,
      internet.id
     FROM users u
     INNER JOIN internet_main internet ON (u.uid=internet.uid)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
     $EXT_TABLE
     $WHERE
     GROUP BY $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT COUNT( DISTINCT u.id) AS total FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    $EXT_TABLE
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 report_debetors($attr)

=cut
#**********************************************************
sub report_debetors {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'internet.uid',                           1 ],
      ['DV_STATUS',      'INT', 'internet.disable as internet_status',          1 ],
    ],
    {
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

  my $EXT_TABLES = $self->{EXT_TABLES};
  $WHERE = " AND ". $WHERE if ($WHERE);

  if (! $attr->{PERIOD}) {
    $attr->{PERIOD} = 1;
  }

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      u.uid
     FROM users u
     INNER JOIN internet_main internet ON (u.uid=internet.uid)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
      $EXT_TABLES
     WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD} $WHERE
     GROUP BY u.id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self->{list} if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT COUNT(*) AS total, SUM(IF(u.company_id > 0, cb.deposit, b.deposit)) AS total_debetors_sum
      FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    $EXT_TABLES
    WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD}
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
=head2 report_tp()

=cut
#**********************************************************
sub report_tp {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;
  $attr->{DELETED}=0;

  my $WHERE =  $self->search_former($attr, [
      ['DOMAIN_ID',            'INT', 'tp.domain_id',  ],
    ],
    { WHERE       => 1,
      USERS_FIELDS=> 1
    }
  );

  $self->query2("SELECT internet.tp_id AS id, tp.id, tp.name, COUNT(DISTINCT internet.uid) AS counts,
      SUM(IF(internet.disable=0 AND u.disable=0, 1, 0)) AS active,
      SUM(IF(internet.disable=1 OR u.disable=1, 1, 0)) AS disabled,
      SUM(IF(IF(u.company_id > 0, cb.deposit, b.deposit) < 0, 1, 0)) AS debetors,
      ROUND(SUM(p.sum) / COUNT(DISTINCT internet.uid), 2) AS arpu,
      ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      tp.tp_id
    FROM users u
    INNER JOIN internet_main internet ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    LEFT JOIN payments p ON (p.uid=internet.uid
       AND (p.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00') AND p.date <= CONCAT(CURDATE(), ' 24:00:00')) )
    $WHERE
     GROUP BY tp.id
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 get_speed($attr) get tp speed

  Arguments:
    $attr
       DOMAIN_ID

=cut
#**********************************************************
sub get_speed {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE    = '';
  my @WHERE_RULES  = ();

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'tp.tp_id, tt.id';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.tp_id = tp.tp_id )
    LEFT JOIN users u ON (internet.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', internet.speed, u.activate, internet.netmask, internet.join_service, internet.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'u.uid') };
    $EXT_TABLE .= "LEFT JOIN internet_main internet ON (internet.tp_id = tp.tp_id )
    LEFT JOIN users u ON (internet.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', internet.speed, u.activate, internet.netmask, internet.join_service, internet.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }

  if ($attr->{BURST}) {
    $self->{SEARCH_FIELDS} = ', tt.burst_limit_dl, tt.burst_limit_ul, tt.burst_threshold_dl, tt.burst_threshold_ul, tt.burst_time_dl, tt.burst_time_ul';
    $self->{SEARCH_FIELDS_COUNT} += 6;
  }

  if(defined($attr->{DOMAIN_ID}) && $attr->{DOMAIN_ID} =~ /^\d+$/) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOMAIN_ID}, 'STR', 'tp.domain_id') };
  }

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'STR', 'tp.tp_id') };
  }

  if ($attr->{TP_NUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_NUM}, 'STR', 'tp.id') };
  }


  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT tp.tp_id, tp.id AS tp_num, tt.id AS tt_id, tt.in_speed,
    tt.out_speed, tt.net_id, tt.expression
  $self->{SEARCH_FIELDS}
FROM trafic_tarifs tt
LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)
$EXT_TABLE
WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' )
 AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
 $WHERE
AND intv.day IN (SELECT IF( intv.day=8,
    (SELECT IF((SELECT COUNT(*) FROM holidays WHERE DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (SELECT IF(intv.day=0, 0, (SELECT intv.day FROM intervals as intv WHERE DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
        (SELECT IF(intv.day=0, 0,
                (SELECT intv.day FROM intervals AS intv WHERE DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
GROUP BY tp.tp_id, tt.id
ORDER BY $SORT $DESC;",
  undef,
  $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 account_check()

=cut
#**********************************************************
sub account_check {
  my $self = shift;

  $self->query2("SELECT COUNT(uid) FROM internet_main;");

  if($self->{TOTAL}) {
    if($self->{list}->[0]->[0] > 0x4B1) {
      $self->{errno} = 0x2BC;
    }
  }

  return $self;
}

1

