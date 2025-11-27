package Bonus;

=head1 NAME

 Bonus modules

=cut

use strict;
use parent 'dbcore';

use Tariffs;
use Users;
use Fees;
use Bills;

our $VERSION = 2.10;

my $Bill;
my $MODULE = 'Bonus';
my ($admin, $CONF);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  bless($self, $class);

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 info($id) - User information

  Arguments:
    $uid

  Resturn:
    $self

=cut
#**********************************************************
sub info {
  my ($self, $id) = @_;

  my $sql = << 'SQL';
    SELECT * FROM bonus_main
    WHERE uid = ?;
SQL

  $self->query($sql, undef,{ INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 defaults()

=cut
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    PERIOD         => 0,
    RANGE_BEGIN    => 0,
    RANGE_END      => 0,
    SUM            => '0.00',
    COMMENTS       => '',
    EXPIRE         => '0000-00-00',
    DESCRIBE       => '',
    METHOD         => 0,
    EXT_ID         => '',
    INNER_DESCRIBE => ''
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
=head2 change()

=cut
#**********************************************************
sub change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_main',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 list()

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my @WHERE_RULES = ();
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = << "SQL";
     SELECT tp_id, period, range_begin, range_end, sum, comments, id
     FROM bonus_main
     $WHERE
     ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT count(b.id) AS total FROM bonus_main b $WHERE", undef, { INFO => 1 });
  }

  return $list || [];
}

#**********************************************************
=head2 periodic()

=cut
#**********************************************************
sub periodic {
  my ($self, $period) = @_;

  if ($period eq 'daily') {
    #$self->daily_fees();
  }

  return $self;
}

#**********************************************************
=head2 tp_info()

=cut
#**********************************************************
sub tp_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
    SELECT id AS tp_id, name, state
    FROM bonus_tps
    WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 tp_add()

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub tp_add {
  my ($self, $attr) = @_;

  $self->query_add('bonus_tps', $attr);

  return $self;
}

#**********************************************************
=head2 tp_change()

=cut
#**********************************************************
sub tp_change {
  my ($self, $attr) = @_;
  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_tps',
    DATA         => $attr
  });
  return $self;
}

#**********************************************************
=head2 tp_del()

=cut
#**********************************************************
sub tp_del {
  my ($self, $attr) = @_;

  $self->query_del('bonus_tps', $attr);

  return $self;
}

#**********************************************************
=head2 tp_list()

=cut
#**********************************************************
sub tp_list {
  my ($self, $attr) = @_;

  my $SORT  = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC  = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my @WHERE_RULES = ();
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT *
    FROM bonus_tps
    $WHERE
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $sql = <<"SQL";
      SELECT count(b.id) AS total FROM bonus_tps b
      $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list || [];
}

#**********************************************************
=head2 rule_info()

=cut
#**********************************************************
sub rule_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
    SELECT tp_id,
       period,
       rules,
       rule_value,
       actions,
       id
    FROM bonus_rules
    WHERE id = ? ;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 rule_add()

=cut
#**********************************************************
sub rule_add {
  my ($self, $attr) = @_;

  $self->query_add('bonus_rules', $attr);

  return $self;
}

#**********************************************************
=head2 rule_change()

=cut
#**********************************************************
sub rule_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_rules',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 rule_del()

=cut
#**********************************************************
sub rule_del {
  my ($self, $attr) = @_;

  $self->query_del('bonus_rules', $attr);

  return $self;
}

#**********************************************************
=head2 rule_list()

=cut
#**********************************************************
sub rule_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ();

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "tp_id='$attr->{TP_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
     SELECT period, rules, rule_value, actions, id
     FROM bonus_rules
     $WHERE
     ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 user_info()

=cut
#**********************************************************
sub user_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
    SELECT uid,
       tp_id,
       state,
       accept_rules
    FROM bonus_main
    WHERE uid = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 user_add()

=cut
#**********************************************************
sub user_add {
  my ($self, $attr) = @_;

  $attr->{STATE} = 1;

  $self->query_add('bonus_main',  $attr);

  if ($CONF->{BONUS_ACCOMULATION}){
    $self->accomulation_first_rule($attr);
  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 user_change($self, $attr)

=cut
#**********************************************************
sub user_change {
  my ($self, $attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? $attr->{STATE} : 0;
  $admin->{MODULE} = $MODULE;
  $attr->{ACCEPT_RULES} = ($attr->{ACCEPT_RULES}) ? 1 : 0;
 
  $self->changes({
    CHANGE_PARAM => 'UID',
    TABLE        => 'bonus_main',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my ($self, $attr) = @_;

  $self->query_del('bonus_main', undef, { uid => $attr->{UID} });

  return $self;
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub user_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ("bu.uid = u.uid");
  $self->{EXT_TABLES}='';

  my @search_fields = (
    ['TP_ID',          'INT', 'bu.tp_id',  1 ],
    ['DV_TP_ID',       'INT', 'tp.tp_id',  1 ],
    ['TP_NAME',        'STR', 'b_tp.name', 'b_tp.name AS tp_name' ],
    ['STATE',          'INT', 'bu.state',  1 ],
    ['BONUS_ACCOMULATION', '', '', 'ras.cost'],
  );

  my $WHERE =  $self->search_former($attr, \@search_fields,
   { WHERE             => 1,
     WHERE_RULES       => \@WHERE_RULES,
     USERS_FIELDS_PRE  => 1,
     USE_USER_PI       => 1
   });

  my $EXT_TABLE = q{};

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ($CONF->{BONUS_ACCOMULATION}){
    $EXT_TABLE .= <<"EXT";
     LEFT JOIN bonus_rules_accomulation_scores ras ON (ras.uid = u.uid)
EXT
  }

  if ($attr->{DV_TP_ID}) {
    $EXT_TABLE .= <<"EXT";
      LEFT JOIN internet_main internet ON (internet.uid = u.uid)
      LEFT JOIN tarif_plans tp  ON (tp.tp_id = internet.tp_id)
EXT
  }

  my $sql = <<"SQL";
     SELECT $self->{SEARCH_FIELDS}
       bu.uid
     FROM (bonus_main bu, users u)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  $sql = << "SQL";
     SELECT COUNT(DISTINCT bu.uid) AS total
     FROM (bonus_main bu, users u)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 bonus_operation($user, $attr)

=cut
#**********************************************************
sub bonus_operation {
  my ($self, $user, $attr) = @_;

  if ($attr->{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  if ($attr->{CHECK_EXT_ID}) {
    $self->query("SELECT id, date FROM bonus_log WHERE ext_id='$attr->{CHECK_EXT_ID}';");
    if ($self->{TOTAL} > 0) {
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUPLICATE';
      $self->{ID}     = $self->{list}->[0][0];
      $self->{DATE}   = $self->{list}->[0][1];
      return $self;
    }
  }

  $user->{EXT_BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});

  if ($user->{EXT_BILL_ID} > 0) {
    my $bill_action_type = '';
    if ($attr->{ACTION_TYPE}) {
      $bill_action_type = 'take';
    }
    else {
      $bill_action_type = 'add';
    }

    $Bill->info({ BILL_ID => $user->{EXT_BILL_ID} });
    $Bill->action($bill_action_type, $user->{EXT_BILL_ID}, $attr->{SUM});
    if ($Bill->{errno}) {
      return $self;
    }

    my $date = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';

    my $sql = <<'SQL';
      INSERT INTO bonus_log (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
                       inner_describe, action_type, expire)
      VALUES (?, ?, ?, ?, ?, INET_ATON(?), ?, ?, ?, ?, ?, ?, ?);
SQL

    $self->query($sql, 'do',
      { Bind => [
          $user->{UID},
          $user->{EXT_BILL_ID},
          $date,
          $attr->{SUM},
          $attr->{DESCRIBE},
          $admin->{SESSION_IP},
          $Bill->{DEPOSIT},
          $admin->{AID},
          $attr->{METHOD} || 0,
          $attr->{EXT_ID} || '',
          $attr->{INNER_DESCRIBE} || '',
          $attr->{ACTION_TYPE},
          $attr->{EXPIRE} || '0000-00-00'
        ] }
    );

    $self->{BONUS_PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  return $self;
}

#**********************************************************
=head2 bonus_operation_del($user, $id)

=cut
#**********************************************************
sub bonus_operation_del {
  my ($self, $user, $id) = @_;

  my $sql = << "SQL";
    SELECT sum, bill_id, action_type FROM bonus_log WHERE id='$id';
SQL

  $self->query($sql);

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id, $action_type) = @{ $self->{list}->[0] };
  my $bill_action = 'take';
  if ($action_type) {
    $bill_action = 'add';
  }
  $Bill->action($bill_action, $bill_id, $sum);

  $self->query_del('bonus_log', { ID => $id });

  $admin->{MODULE} = $MODULE;
  $admin->action_add($user->{UID}, "BONUS $bill_action:$id SUM:$sum", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 bonus_operation_list($attr)

=cut
#**********************************************************
sub bonus_operation_list {
  my ($self, $attr) = @_;

  $self->{SEARCH_FIELDS} = '';
  my @WHERE_RULES = ();

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my @search_fields = (
    ['LOGIN',          'STR', 'u.id'                                     ],
    ['DATETIME',       'DATE','p.date',   'p.date AS datetime'           ],
    ['SUM',            'INT', 'p.sum',                                   ],
    ['PAYMENT_METHOD', 'INT', 'p.method',                                ],
    ['A_LOGIN',        'STR', 'a.id AS admin_login',                    1],
    ['DESCRIBE',       'STR', 'p.dsc'                                    ],
    ['INNER_DESCRIBE', 'STR', 'p.inner_describe'                         ],
    ['METHOD',         'INT', 'p.method',                               1],
    ['BILL_ID',        'INT', 'p.bill_id',                              1],
    ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'],
    ['EXT_ID',         'STR', 'p.ext_id',                               1],
    ['DATE',           'DATE','DATE_FORMAT(p.date, \'%Y-%m-%d\')'        ],
    ['EXPIRE',         'DATE','DATE_FORMAT(p.expire, \'%Y-%m-%d\')',   'DATE_FORMAT(p.expire, \'%Y-%m-%d\') AS expire' ],
    ['MONTH',          'DATE','DATE_FORMAT(p.date, \'%Y-%m\') AS month'  ],
    ['ID',             'INT', 'p.id'                                     ],
    ['AID',            'INT', 'p.aid',                                   ],
    ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "p.date"                      ],
    ['FROM_DATE|TO_DATE', 'DATE',    'DATE_FORMAT(p.date, \'%Y-%m-%d\')' ],
    ['UID',            'INT', 'p.uid',                                  1],
  );

  my $WHERE =  $self->search_former($attr, \@search_fields, {
    WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES,
    USERS_FIELDS=> 1,
    SKIP_USERS_FIELDS=> [ 'BILL_ID', 'UID' ]
  });

    my $EXT_TABLES = $self->{EXT_TABLES};

    my $sql = <<"SQL";
      SELECT p.id, u.id AS login, $self->{SEARCH_FIELDS}
      p.date,
      p.dsc,
      p.sum,
      p.last_deposit,
      p.expire,
      p.method,
      p.ext_id, p.bill_id, if(a.name is null, 'Unknown', a.name),
      INET_NTOA(p.ip) AS ip,
      p.action_type,
      p.uid,
      p.inner_describe
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY p.id
SQL

  $self->query_list($sql, $attr);

  $self->{SUM} = '0.00';

  return $self->{list} || [] if ($self->{TOTAL} < 1);
  my $list = $self->{list} || [];

  $sql = <<"SQL";
    SELECT COUNT(p.id) AS total, SUM(p.sum) AS sum, COUNT(DISTINCT p.uid) AS total_users
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 service_discount_info($id)

=cut
#**********************************************************
sub service_discount_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
   SELECT * FROM bonus_service_discount
   WHERE id = ?;
SQL

  $self->query($sql, undef,{ INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 service_discount_add($attr)

=cut
#**********************************************************
sub service_discount_add {
  my ($self, $attr) = @_;

  $self->query_add('bonus_service_discount', $attr);

  return $self;
}

#**********************************************************
=head2 service_discount_change($attr)

=cut
#**********************************************************
sub service_discount_change {
  my ($self, $attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;
  $attr->{EXT_ACCOUNT} = ($attr->{EXT_ACCOUNT}) ? 1 : 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_service_discount',
    DATA         => $attr
  });

  $self->service_discount_info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 service_discount_del(attr);

=cut
#**********************************************************
sub service_discount_del {
  my ($self, $attr) = @_;

  $self->query_del('bonus_service_discount', $attr);

  return $self;
}

#**********************************************************
=head2 service_discount_list($attr)

=cut
#**********************************************************
sub service_discount_list {
  my ($self, $attr) = @_;

  $self->{SEARCH_FIELDS}      = '';
  $self->{SEARCH_FIELDS_COUNT}= 0;

  my @search_fields = (
    ['ID',                  'INT',    'id',                    1 ],
    ['NAME',                'STR',    'name',                  1 ],
    ['TP_ID',               'INT',    'tp_id'                    ],
    ['REGISTRATION_DAYS',   'INT',    'registration_days'        ],
    ['PERIODS',             'INT',    'service_period'           ],
    ['TOTAL_PAYMENTS_SUM',  'INT',    'total_payments_sum'       ],
    ['PAY_METHOD',          'INT',    'pay_method'               ],
    ['COMMENTS',            'STR',    'comments',              1 ],
    ['TP_ID',               'STR',    'tp_id',                 1 ],
    ['ONETIME_PAYMENT_SUM', 'INT',    'onetime_payment_sum',   1 ],
  );

  my $WHERE =  $self->search_former($attr, \@search_fields, { WHERE => 1 });

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS}
    service_period,
    registration_days,
    total_payments_sum,
    discount,
    discount_days,
    bonus_sum,
    bonus_percent,
    ext_account,
    pay_method,
    id
    FROM bonus_service_discount
    $WHERE
SQL

  $self->query_list($sql, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 bonus_turbo_info()

=cut
#**********************************************************
sub bonus_turbo_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
     SELECT id,
       service_period,
       registration_days,
       turbo_count,
       comments
     FROM bonus_turbo
     WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 bonus_turbo_add($attr)

=cut
#**********************************************************
sub bonus_turbo_add {
  my ($self, $attr) = @_;

  my $sql = <<"SQL";
    INSERT INTO bonus_turbo (service_period, registration_days, turbo_count, comments)
    VALUES ('$attr->{SERVICE_PERIOD}', '$attr>{REGISTRATION_DAYS}', '$attr->{TURBO_COUNT}', '$attr->{DESCRIBE}');
SQL

  $self->query($sql, 'do');

  return $self;
}

#**********************************************************
=head2 bonus_turbo_change($attr)

=cut
#**********************************************************
sub bonus_turbo_change {
  my ($self, $attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_turbo',
    DATA         => $attr
  });

  $self->bonus_turbo_info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 bonus_turbo_del($attr)

=cut
#**********************************************************
sub bonus_turbo_del {
  my ($self,$attr) = @_;

  $self->query_del('bonus_turbo', $attr);

  return $self;
}

#**********************************************************
=head2 bonus_turbo_list($attr)

=cut
#**********************************************************
sub bonus_turbo_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  my $sql = <<"SQL";
     SELECT service_period, registration_days, turbo_count, id
     FROM bonus_turbo
     $WHERE
SQL

  $self->query_list($sql, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 accomulation_rule_info($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub accomulation_rule_info {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT *
    FROM bonus_rules
    WHERE tp_id= ?;
SQL

  $self->query($sql, undef,{ INFO => 1, Bind => [ $attr->{TP_ID}] });

  return $self;
}

#**********************************************************
=head2 accomulation_rule_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub accomulation_rule_change {
  my ($self, $attr) = @_;

  my @ids = split(/,\s/x, $attr->{DV_TP_ID});

  if ( $#ids > -1 ) {
    my @MULTI_QUERY = ();

    foreach my $id (@ids) {
      push @MULTI_QUERY, [ $attr->{TP_ID} || 0, $id || 0, $attr->{'COST_'.$id} || 0 ];
    }

    my $sql = <<'SQL';
      REPLACE INTO bonus_rules_accomulation (tp_id, dv_tp_id, cost)
      VALUES ( ? , ? , ? );
SQL

    $self->query( $sql, undef,{ MULTI_QUERY => \@MULTI_QUERY });
  }

  return $self;
}

#**********************************************************
=head2 accomulation_rule_list($attr)

=cut
#**********************************************************
sub accomulation_rule_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my @WHERE_RULES = ("tp.module IN ('Internet', 'Dv')");
  my $JOIN_WHERE = '';

  if ($attr->{DV_TP_ID}) {
    push @WHERE_RULES, "br.dv_tp_id='$attr->{DV_TP_ID}'";
    $JOIN_WHERE = "AND br.tp_id='$attr->{TP_ID}'";
  }
  if ($attr->{TP_ID}) {
    $JOIN_WHERE = " AND br.tp_id='$attr->{TP_ID}'";
  }
  if ($attr->{COST}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{COST}, 'INT', 'cost') };
  }
 
  my $WHERE = ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT tp.tp_id AS dv_tp_id, tp.name, br.cost, br.tp_id
    FROM tarif_plans tp
       LEFT JOIN bonus_rules_accomulation br ON (br.dv_tp_id=tp.tp_id $JOIN_WHERE)
    WHERE $WHERE
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql , undef, $attr);

  return [ ] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 accomulation_scores_info($attr)

=cut
#**********************************************************
sub accomulation_scores_info {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT  dv_tp_id, cost, changed
    FROM bonus_rules_accomulation_scores
    WHERE uid = ?;
SQL

  $self->query($sql, undef,{ INFO => 1, Bind => [ $attr->{UID} ] });

  return $self;
}

#**********************************************************
=head2 accomulation_scores_change($attr)

  Arguments:
    $attr
      UID
      DV_TP_ID
      SCORE

=cut
#**********************************************************
sub accomulation_scores_change {
  my ($self, $attr) = @_;

  my $tp_id = $attr->{DV_TP_ID} || 0;

  my $sql = <<"SQL";
    SELECT uid FROM bonus_rules_accomulation_scores WHERE uid = ?
SQL

  $self->query($sql, undef, { Bind => [ $attr->{UID} ] });

  if($self->{TOTAL} && $self->{TOTAL} > 0) {
    $sql = <<"SQL";
     UPDATE bonus_rules_accomulation_scores SET
     cost= ?,
     dv_tp_id= ?
     WHERE uid= ? ;
SQL
  }
  else {
    $sql = <<"SQL";
      INSERT INTO bonus_rules_accomulation_scores (cost, dv_tp_id, uid)
      VALUES (? , ?, ?);
SQL
  }

  $self->query($sql, 'do', { Bind => [ $attr->{SCORE}, $tp_id, $attr->{UID} ] });

  $admin->{MODULE} = $MODULE;
  if ($self->{AFFECTED} && $self->{AFFECTED} > 0) {
    $admin->action_add($attr->{UID}, "SCORE: ". $attr->{SCORE}, { TYPE => 2 });
  }

  return $self;
}


#**********************************************************
=head2 accomulation_scores_add($attr)

  Arguments:
    $attr
      DV_TP_ID
      UID
      SCORE

  Results:
    $self

=cut
#**********************************************************
sub accomulation_scores_add {
  my ($self, $attr) = @_;

  my $tp_value = ($attr->{DV_TP_ID}) ? "dv_tp_id='$attr->{DV_TP_ID}'," : q{};
  my $sql = <<"SQL";
     UPDATE bonus_rules_accomulation_scores SET
       $tp_value
     cost=cost + $attr->{SCORE}
     WHERE uid='$attr->{UID}';
SQL

  $self->query($sql, 'do');

  if ($self->{AFFECTED} == 0 && $CONF->{BONUS_PAYMENTS_AUTO}){
    $self->accomulation_scores_change({ 
      UID      => $attr->{UID},
      SCORE    => $attr->{SCORE},
      DV_TP_ID => 0
    });
  }

  $admin->{MODULE} = $MODULE;
  if ($self->{AFFECTED} && $self->{AFFECTED} > 0) {
    $admin->action_add($attr->{UID}, "SCORE:$attr->{SCORE} BONUS_ID:$attr->{BONUS_ID}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 accomulation_scores_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub accomulation_scores_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{REGISTRATION_DAYS}, 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PERIODS}, 'INT', 'service_period') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : q{};
  my $sql = <<"SQL";
     SELECT service_period, registration_days, turbo_count, id
     FROM bonus_rules_accomulation_scores bs
     INNER JOIN users u ON (u.uid=bs.uid)
     $WHERE
SQL

  $self->query_list($sql, $attr);

  return [ ] if ($self->{errno});

  return $self->{list} || [];
}


#**********************************************************
=head2 accomulation_first_rule()

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub accomulation_first_rule {
  my ($self, $attr) = @_;

  $CONF->{BONUS_ACCOMULATION_FIRST_BONUS}=0 if (! $CONF->{BONUS_ACCOMULATION_FIRST_BONUS});
  $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}=3 if (! defined($CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}));

  my $sql = <<"SQL";
    SELECT PERIOD_DIFF(DATE_FORMAT(max(date), '%Y%m'),
    DATE_FORMAT(MIN(date), '%Y%m')) FROM fees WHERE uid='$attr->{UID}' AND
    date>=CURDATE() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH
SQL

  $self->query($sql);

  if ($self->{list}->[0]->[0]>=$CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}) {
    $sql = <<"SQL";
      REPLACE INTO bonus_rules_accomulation_scores (uid, cost, changed)
      SELECT $attr->{UID},
       IF(
         (SELECT \@A := MIN(last_deposit)
          FROM fees
          WHERE uid = ?
            AND date >= CURDATE() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH
         ) >= 0
         OR \@A IS NULL,
         $CONF->{BONUS_ACCOMULATION_FIRST_BONUS},
         0
       ),
       CURDATE();
SQL

    $self->query($sql, 'do', { Bind => [ $attr->{UID} ] });
  }

  return $self;
}

#**********************************************************
=head2 accomulation_reset_list($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub accomulation_reset_list {
  my ($self, $attr) = @_;

  my $sql = << "SQL";
    SELECT b.cost, MAX(l.start) AS last_connect, b.uid, COUNT(online.uid) AS online
    FROM bonus_rules_accomulation_scores b
    LEFT JOIN internet_log l ON (l.uid=b.uid)
    LEFT JOIN internet_online online ON (online.uid=b.uid)
    WHERE b.cost > 0
    GROUP BY b.uid
    HAVING last_connect < CURDATE() - INTERVAL $attr->{RESET_PERIOD} DAY AND online < 1;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}


#**********************************************************
=head2 tp_using_info($id)

=cut
#**********************************************************
sub tp_using_info {
  my ($self, $id) = @_;

  $self->query('SELECT * FROM bonus_tp_using  WHERE id = ?', undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 tp_using_add($attr)

=cut
#**********************************************************
sub tp_using_add {
  my ($self, $attr) = @_;

  $self->query_add('bonus_tp_using', $attr);

  return $self;
}

#**********************************************************
=head2 tp_using_change($attr)

=cut
#**********************************************************
sub tp_using_change {
  my ($self, $attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'bonus_tp_using',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 tp_using_del(attr);

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub tp_using_del {
  my ($self, $attr) = @_;

  $self->query_del('bonus_tp_using', $attr);

  return $self;
}

#**********************************************************
=head2 tp_using_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub tp_using_list {
  my ($self, $attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $age = <<'AGE';
    (SELECT DATEDIFF(curdate(), max(datetime)) FROM admin_actions
    WHERE uid=internet.uid AND action_type=3 GROUP BY uid ORDER BY 1) AS age
AGE

  my @search_fields = (
    ['LOGIN',          'STR', 'u.id',               'u.id AS login'          ],
    ['TP_ID',          'INT', 'internet.tp_id',                            1 ],
    ['AGE',            'INT', 'aa.date',                                $age ],
    ['MONTH_FEE',      'INT', 'tp.month_fee',                              1 ],
    ['FROM_DATE|TO_DATE','INT',       "DATE_FORMAT(aa.datetime, '%Y-%m-%d')" ],
    ['UID',            'INT', 'internet.uid',                              1 ],
  );

  my $WHERE =  $self->search_former($attr, \@search_fields, {
    WHERE        => 1,
    USERS_FIELDS => 1,
    USE_USER_PI  => 1
  });

  my $EXT_TABLES = '';

  if ($self->{SEARCH_FIELDS} =~ /internet\./xm) {
    $EXT_TABLES = qq{ LEFT JOIN internet_main internet ON (internet.tp_id=bonus.tp_id_bonus) };

    if ($self->{SEARCH_FIELDS} =~ /u\./xm) {
      $EXT_TABLES .= qq{ LEFT JOIN users u ON (u.uid=internet.uid) }
    }
    if ($self->{SEARCH_FIELDS} =~ /tp\./xm) {
      $EXT_TABLES .= qq{LEFT JOIN tarif_plans tp ON (tp.id=internet.tp_id) };
    }
  }

  if ($self->{SEARCH_FIELDS} =~ /aa\./xm || $WHERE =~ /aa\./xm) {
    $EXT_TABLES .= q{ LEFT JOIN admin_actions aa ON (aa.uid=internet.uid) };
  }

  $EXT_TABLES .= $self->{EXT_TABLES};

  my $sql = <<"SQL";
     SELECT bonus.*, $self->{SEARCH_FIELDS} bonus.id
     FROM bonus_tp_using bonus
     $EXT_TABLES
     $WHERE
     ORDER BY $SORT $DESC;
SQL

  $self->query($sql , undef, $attr);

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $sql = <<"SQL";
      SELECT count(bonus.id) AS total FROM bonus_tp_using bonus $EXT_TABLES $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}


1;

