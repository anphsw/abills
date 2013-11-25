package Dv;
# Dialup & Vpn  managment functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

use Tariffs;
use Users;
use Fees;

my $uid;
my $MODULE = 'Dv';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);
  
  $self->{db}=$db;
  
  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if (defined($attr->{LOGIN}) && $attr->{LOGIN} ne '') {
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE dv.uid='$uid'";
  }

  $WHERE = "WHERE dv.uid='$uid'";

  if (defined($attr->{IP})) {
    $WHERE = "WHERE dv.ip=INET_ATON('$attr->{IP}')";
  }
  
  my $domain_id = 0;
  if ($admin->{DOMAIN_ID}) {
    $domain_id = $admin->{DOMAIN_ID};
  }
  elsif ($attr->{DOMAIN_ID}) {
    $domain_id = $attr->{DOMAIN_ID};
  }
  

  $self->query2("SELECT dv.uid, 
   dv.tp_id, 
   tp.name AS tp_name, 
   dv.logins as SIMULTANEONSLY, 
   INET_NTOA(dv.ip) AS ip, 
   INET_NTOA(dv.netmask) AS netmask, 
   dv.speed, 
   dv.filter_id, 
   dv.cid,
   dv.disable as status,
   dv.callback,
   dv.port,
   tp.gid AS tp_gid,
   tp.month_fee AS month_abon,
   tp.day_fee AS day_abon,
   tp.postpaid_monthly_fee AS postpaid_abon,
   tp.payment_type,
   dv.join_service,
   dv.turbo_mode,
   dv.free_turbo_mode,
   dv.expire AS dv_expire,
   tp.abon_distribution,
   tp.credit AS tp_credit,
   tp.tp_id AS tp_num,
   tp.priority AS tp_priority,
   tp.activate_price AS tp_activate_price,
   tp.age AS tp_age,
   tp.filter_id AS tp_filter_id,
   tp.period_alignment AS tp_period_alignment,
   tp.fixed_fees_day,
   tp.comments
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON ((tp.module='Dv' or tp.module='') AND dv.tp_id=tp.id and tp.domain_id='$domain_id')
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**************************************
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
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  if ($DATA{TP_ID} > 0 && !$DATA{STATUS}) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);

    $self->{TP_INFO} = $tariffs->info(0, { ID => $DATA{TP_ID}, MODULE => 'Dv' });
      #Take activation price
      if ($tariffs->{ACTIV_PRICE} > 0) {
        my $user = Users->new($self->{db}, $admin, $CONF);
        $user->info($DATA{UID});

        if ($CONF->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
          $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
        }

        if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
          $self->{errno} = 15;
          return $self;
        }

        my $fees = Fees->new($self->{db}, $admin, $CONF);
        $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });

        $tariffs->{ACTIV_PRICE} = 0;
      }
  }

  $self->query2("INSERT INTO dv_main (uid, registration, 
             tp_id, 
             logins, 
             disable, 
             ip, 
             netmask, 
             speed, 
             filter_id, 
             cid,
             callback,
             port,
             join_service,
             turbo_mode,
             free_turbo_mode,
             expire)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TP_ID}', '$DATA{SIMULTANEONSLY}', '$DATA{STATUS}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'),
        '$DATA{CALLBACK}',
        '$DATA{PORT}', '$DATA{JOIN_SERVICE}', '$DATA{TURBO_MODE}', '$DATA{FREE_TURBO_MODE}',
        '$DATA{DV_EXPIRE}');", 'do'
  );

  return $self if ($self->{errno});

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    SIMULTANEONSLY => 'logins',
    STATUS         => 'disable',
    IP             => 'ip',
    NETMASK        => 'netmask',
    TP_ID          => 'tp_id',
    SPEED          => 'speed',
    CID            => 'cid',
    UID            => 'uid',
    FILTER_ID      => 'filter_id',
    CALLBACK       => 'callback',
    PORT           => 'port',
    JOIN_SERVICE   => 'join_service',
    TURBO_MODE     => 'turbo_mode',
    FREE_TURBO_MODE=> 'free_turbo_mode',
    DV_EXPIRE      => 'expire'
  );

  if (!$attr->{CALLBACK}) {
    $attr->{CALLBACK} = 0;
  }

  my $old_info = $self->info($attr->{UID});
  $self->{OLD_STATUS} = $old_info->{STATUS};

  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $tariffs->info(0, { ID => $old_info->{TP_ID}, MODULE => 'Dv' });

    %{ $self->{TP_INFO_OLD} } = %{ $tariffs };
    $self->{TP_INFO}     = $tariffs->info(0, { ID => $attr->{TP_ID}, MODULE => 'Dv' });

    my $user = Users->new($self->{db}, $admin, $CONF);

    $user->info($attr->{UID});
    if ($CONF->{FEES_PRIORITY} && $CONF->{FEES_PRIORITY} =~ /bonus/ && $user->{EXT_BILL_DEPOSIT}) {
      $user->{DEPOSIT} += $user->{EXT_BILL_DEPOSIT};
    }

    my $skip_change_fee = 0;
    if ($CONF->{DV_TP_CHG_FREE}) {
      use POSIX qw(mktime);

      my ($y, $m, $d) = split(/-/, $user->{REGISTRATION}, 3);
      my $cur_date = time();
      my $registration = mktime(0, 0, 0, $d, ($m - 1), ($y - 1900));
      if (($cur_date - $registration) / 86400 > $CONF->{DV_TP_CHG_FREE}) {
        $skip_change_fee = 1;
      }
    }

    #Active TP
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });

      $tariffs->{ACTIV_PRICE} = 0;
    }
    # Change TP
    elsif (!$skip_change_fee
      && $tariffs->{CHANGE_PRICE} > 0
      && ($self->{TP_INFO_OLD}->{PRIORITY} - $tariffs->{PRIORITY} > 0 || $self->{TP_INFO_OLD}->{PRIORITY} + $tariffs->{PRIORITY} == 0)
      && !$attr->{NO_CHANGE_FEES})
    {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE TP" });
    }

    if ($tariffs->{AGE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);

      use POSIX qw(strftime);
      $attr->{EXPITE_DATE} = strftime("%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}));
    }
    else {
      $attr->{EXPITE_DATE} = "0000-00-00";
    }
  }
  elsif (($old_info->{STATUS} == 1 
         || $old_info->{STATUS} == 2 
         || $old_info->{STATUS} == 4 
         || $old_info->{STATUS} == 5) && $attr->{STATUS} == 0) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info(0, { ID => $old_info->{TP_ID}, MODULE => 'Dv' });
  }
  elsif ($old_info->{STATUS} == 3 
        && $attr->{STATUS} == 0 
        && $attr->{STATUS_DAYS}) {
    my $user = Users->new($self->{db}, $admin, $CONF);
    $user->info($attr->{UID});
    my $fees = Fees->new($self->{db}, $admin, $CONF);
    my ($perios, $sum) = split(/:/, $CONF->{DV_REACTIVE_PERIOD}, 2);
    $fees->take($user, $sum, { DESCRIBE => "REACTIVE" });
  }

  #$attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'dv_main',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  $self->{TP_INFO}->{ACTIV_PRICE} = 0;

  $self->info($attr->{UID});

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE from dv_main WHERE uid='$self->{UID}';", 'do');
  $self->query2("DELETE from dv_log WHERE uid='$self->{UID}';",  'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $GROUP_BY = ($attr->{GROUP_BY}) ? $attr->{GROUP_BY} : 'u.uid';

  @WHERE_RULES = ();
  push @WHERE_RULES, @{ $self->search_expr_users({ %$attr, 
                             EXT_FIELDS => [
                                            'PHONE',
                                            'EMAIL',
                                            'ADDRESS_FLAT',
                                            'PASPORT_DATE',
                                            'PASPORT_NUM', 
                                            'PASPORT_GRANT',
                                            'CITY', 
                                            'ZIP',
                                            'GID',
                                            'CONTRACT_ID',
                                            'CONTRACT_SUFIX',
                                            'CONTRACT_DATE',
                                            'EXPIRE',

                                            'CREDIT',
                                            'CREDIT_DATE', 
                                            'REDUCTION',
                                            'REGISTRATION',
                                            'REDUCTION_DATE',
                                            'COMMENTS',
                                            'BILL_ID',
                                            
                                            'ACTIVATE',
                                            'EXPIRE',
                                            'DEPOSIT',
                                            'DOMAIN_ID',
                                             ] }) };

  if ($attr->{USERS_WARNINGS}) {
    my $allert_period = '';
    if ($attr->{ALERT_PERIOD}) {
      $allert_period = "OR  (tp.month_fee > 0  AND if(u.activate='0000-00-00', 
      datediff(DATE_FORMAT(curdate() + interval 1 month, '%Y-%m-01'), curdate()),
      datediff(u.activate + interval 30 day, curdate())) IN ($attr->{ALERT_PERIOD}))";
    }

    $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES).' AND ' : '';

    $self->query2("SELECT u.id AS login, pi.email, dv.tp_id AS tp_num, u.credit, b.deposit, tp.name AS tp_name, tp.uplimit, pi.phone,
      pi.fio,
      if(u.activate='0000-00-00', 
        datediff(DATE_FORMAT(curdate() + interval 1 month, '%Y-%m-01'), curdate()),
        datediff(u.activate + interval 30 day, curdate())) AS to_next_period,
      tp.month_fee,
      u.uid
         FROM users u
         INNER JOIN bills b ON (u.bill_id  = b.id)
         INNER JOIN dv_main dv ON (u.uid=dv.uid)
         INNER JOIN tarif_plans tp ON (dv.tp_id = tp.id)
         LEFT JOIN users_pi pi ON (u.uid = pi.uid)
         WHERE $WHERE  
           u.disable  = 0           
           AND dv.disable = 0
           AND b.deposit+u.credit>0
           AND (((tp.month_fee=0 OR tp.abon_distribution=1) AND tp.uplimit > 0 AND b.deposit<tp.uplimit)
             $allert_period
               )

         GROUP BY u.uid
         ORDER BY u.id;",
         undef,
         $attr
    );

    return $self if ($self->{errno});

    my $list = $self->{list};
    return $list;
  }
  elsif ($attr->{CLOSED}) {
    $self->query2("SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
       if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)) AS credit,
      tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM ( users u, bills b )
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN dv_log l ON  (l.uid=u.uid) 
     WHERE  
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0)
        or (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        or u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;"
    );

    my $list = $self->{list};
    return $list;
  }

  @WHERE_RULES = ();

  if ($attr->{ADDRESS_FULL}) {
    $attr->{BUILD_DELIMITER}=',' if (! $attr->{BUILD_DELIMITER});
    if ($attr->{MANAGERS}) {
      push @WHERE_RULES, @{ $self->search_expr("$attr->{ADDRESS_FULL}*", "STR", "CONCAT(streets.name, '', builds.number, '$attr->{BUILD_DELIMITER}', pi.address_flat)") };
    }
    elsif ($CONF->{ADDRESS_REGISTER}) {
#      push @WHERE_RULES, @{ $self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(streets.name, ' ', builds.number, '$attr->{BUILD_DELIMITER}', pi.address_flat)", { EXT_FIELD => 1 }) };
    }
    else {
       push @WHERE_RULES, @{ $self->search_expr("*$attr->{ADDRESS_FULL}*", "STR", "CONCAT(pi.address_street, ' ', pi.address_build, '$attr->{BUILD_DELIMITER}', pi.address_flat)") };
     }
  }

  if ( !$admin->{permissions}->{0}
    || !$admin->{permissions}->{0}->{8}
    || ($attr->{USER_STATUS} && !$attr->{DELETED}))
  {
    push @WHERE_RULES, @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }
  elsif (defined($attr->{DELETED})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }

  if ($attr->{CID}) {
    $attr->{CID}=~s/[\:\-\.]/\*/g;
  }
  
  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my $WHERE =  $self->search_former($attr, [
      ['FIO',            'STR', 'pi.fio',                           1 ],
      ['IP',             'IP',  'dv.ip',     'INET_NTOA(dv.ip) AS ip' ],
      ['NETMASK',        'IP',  'dv.netmask', 'INET_NTOA(dv.netmask) AS netmask' ],
      ['CID',            'STR', 'dv.cid',                           1 ],
      ['JOIN_SERVICE',   'INT', 'dv.join_service',                  1 ],
      ['SIMULTANEONSLY', 'INT', 'dv.logins',                        1 ],
      ['SPEED',          'INT', 'dv.speed',                         1 ],
      ['PORT',           'INT', 'dv.port',                          1 ],
      ['ALL_FILTER_ID',  'STR', 'if(dv.filter_id<>\'\', dv.filter_id, tp.filter_id) AS filter_id', 1 ],
      ['FILTER_ID',      'STR', 'dv.filter_id',                     1 ],
      ['TP_ID',          'INT', 'dv.tp_id',                         1 ],
      ['TP_NAME',        'STR', 'tp.name AS tp_name',               1 ],
      ['TP_CREDIT',      'INT', 'tp.credit', 'tp.credit AS tp_credit' ],
      ['ONLINE',         'INT', 'c.uid',            'c.uid AS online' ],
      ['PAYMENT_TYPE',   'INT', 'tp.payment_type',                  1 ],
      ['SHOW_PASSWORD',  '',    '',  "DECODE(u.password, '$CONF->{secretkey}') AS password," ],
      ['STATUS',         'INT', 'dv.disable as dv_status',          1 ],
      ['DV_EXPIRE',      'DATE','dv.expire as dv_expire',           1 ],
      ['UID',            'INT', 'dv.uid',                           1 ],
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1,
    	SKIP_USERS_FIELDS=> [ 'FIO', 'UID' ]
    }    
    );

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($attr->{EXT_BILL}) {
    $self->{SEARCH_FIELDS} .= 'if(u.company_id > 0, ext_cb.deposit, ext_b.deposit), ';
    $self->{SEARCH_FIELDS_COUNT}++;
    $EXT_TABLE .= "
     LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
     LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id) ";
  }

  if($attr->{ONLINE}) {
    $EXT_TABLE .= "
     LEFT JOIN dv_calls c ON (c.uid=dv.uid) ";  	
  }

  $self->query2("SELECT u.id AS login, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      dv.tp_id
     FROM users u
     INNER JOIN dv_main dv ON (u.uid=dv.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     $EXT_TABLE
     $WHERE 
     GROUP BY $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT count( DISTINCT u.id) AS total FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN users_pi pi ON (u.uid = pi.uid)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
    $EXT_TABLE
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
  my ($period) = @_;

  if ($period eq 'daily') {
    $self->daily_fees();
  }

  return $self;
}


#**********************************************************
# report_debetors
#**********************************************************
sub report_debetors {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  

  @WHERE_RULES = @{ $self->search_expr_users({ %$attr, 
                             EXT_FIELDS => [
                                            'PHONE',
                                            'EMAIL',
                                            'ADDRESS_FLAT',
                                            'PASPORT_DATE',
                                            'PASPORT_NUM', 
                                            'PASPORT_GRANT',
                                            'CITY', 
                                            'ZIP',
                                            'GID',
                                            'CONTRACT_ID',
                                            'CONTRACT_SUFIX',
                                            'CONTRACT_DATE',

                                            'CREDIT',
                                            'CREDIT_DATE', 
                                            'REDUCTION',
                                            'REGISTRATION',
                                            'REDUCTION_DATE',
                                            'COMMENTS',
                                            'BILL_ID',
                                            
                                            'ACTIVATE',
                                            'EXPIRE',

                                             ] }) };

  my $EXT_TABLE = $self->{EXT_TABLES}; 


  if (! $attr->{PERIOD}) {
    $attr->{PERIOD} = 1;
  }

  $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT u.id, 
      pi.fio, pi.phone,
      tp.name AS tp_name, 
      if(u.company_id > 0, cb.deposit, b.deposit) AS deposit, 
      u.credit, 
      dv.disable AS dv_status, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.company_id, 
      tp.month_fee,
      pi.email, 
      dv.tp_id, 
      u.activate, 
      u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
      u.reduction,
      if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) AS ext_bill_id
     FROM users u
     INNER JOIN dv_main dv ON (u.uid=dv.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLE
     WHERE if(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD} $WHERE 
     GROUP BY u.id
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT count(*) AS total_debetors, sum(if(u.company_id > 0, cb.deposit, b.deposit)) AS total_debetors_sum
      FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN users_pi pi ON (u.uid = pi.uid)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
    LEFT JOIN companies company ON  (u.company_id=company.id) 
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    $EXT_TABLE
    WHERE if(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD}
    $WHERE",
    undef,
    { INFO => 1 }
    );
  }
  
  
  return $list;
}



#**********************************************************
# report_tp
#**********************************************************
sub report_tp {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT tp.id, tp.name, count(DISTINCT dv.uid) AS counts,
      sum(if(dv.disable=0, 1, 0)) AS active,
      sum(if(dv.disable=1, 1, 0)) AS disabled,
      sum(if(if(u.company_id > 0, cb.deposit, b.deposit) <= 0, 1, 0)) AS debetors,
      tp.tp_id
      FROM users u
    INNER JOIN dv_main dv ON (u.uid=dv.uid)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
    LEFT JOIN companies company ON  (u.company_id=company.id) 
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     GROUP BY tp.id
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  return $self->{list};
}

#**********************************************************
# get tp speed
#**********************************************************
sub get_speed {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  @WHERE_RULES  = ();
  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'tp.tp_id, tt.id';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'u.uid') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";

    $self->{SEARCH_FIELDS} = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "tp.id='$attr->{TP_ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT tp.tp_id, tp.id AS tp_num, tt.id AS tt_id, tt.in_speed, 
    tt.out_speed, tt.net_id, tt.expression 
  $self->{SEARCH_FIELDS} 
FROM trafic_tarifs tt
LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)
$EXT_TABLE
WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' ) 
 AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
 AND tp.module='Dv'
 $WHERE
AND intv.day IN (select if ( intv.day=8, 
    (SELECT if ((select count(*) from holidays where     DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (select if (intv.day=0, 0, (select intv.day from intervals as intv where DATE_FORMAT(NOW(), '%w')+1 = intv.day LIMIT 1))))),
        (select if (intv.day=0, 0,
                (select intv.day from intervals as intv where DATE_FORMAT( NOW(), '%w')+1 = intv.day LIMIT 1)))))
GROUP BY tp.tp_id, tt.id
ORDER BY $SORT $DESC;",
  undef,
  $attr  
  );

  return $self->{list};
}

1

