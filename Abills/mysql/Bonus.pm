package Bonus;

# Bonus modules
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.04;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

use Tariffs;
use Users;
use Fees;
use Bills;

my $Bill;
my $uid;
my $MODULE = 'Bonus';

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
  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE id='$id'";

  $self->query2("SELECT tp_id, 
    period,
    range_begin, 
    range_end,
    sum,
    comments,
    id
     FROM bonus_main 
   $WHERE;",
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
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_main',
      DATA         => $attr
    }
  );

  return $self->{result};
}


#**********************************************************
# list()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT tp_id, period, range_begin, range_end, sum, comments, id
     FROM bonus_main
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(b.id) AS total FROM bonus_main b $WHERE", undef, { INFO => 1 });
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
# User information
# info()
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE id='$id'";

  $self->query2("SELECT id AS tp_id, 
    name,
    state
     FROM bonus_tps 
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# tp_add()
#**********************************************************
sub tp_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $self->query2("INSERT INTO bonus_tps (name, state)
        VALUES ('$DATA{NAME}', '$DATA{STATE}');", 'do'
  );

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_tps',
      DATA         => $attr
    }
  );
  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from bonus_tps WHERE id='$attr->{ID}';", 'do');
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT id, name, state
     FROM bonus_tps
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(b.id) AS total FROM bonus_tps b $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# User information
# rule_info()
#**********************************************************
sub rule_info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE id='$id'";

  $self->query2("SELECT tp_id,
    period,
    rules,
    rule_value,
    actions,
    id
     FROM bonus_rules 
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# tp_add()
#**********************************************************
sub rule_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $self->query2("INSERT INTO bonus_rules (tp_id,
    period,
    rules,
    rule_value,
    actions)
        VALUES ('$DATA{TP_ID}', '$DATA{PERIOD}', '$DATA{RULE}', '$DATA{RULE_VALUE}', '$DATA{ACTIONS}');", 'do'
  );

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub rule_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_rules',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub rule_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from bonus_rules WHERE id='$attr->{ID}';", 'do');
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub rule_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  undef @WHERE_RULES;
  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "tp_id='$attr->{TP_ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT period, rules, rule_value, actions, id
     FROM bonus_rules
     $WHERE 
     ORDER BY $SORT $DESC;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE uid='$id'";

  $self->query2("SELECT uid,
    tp_id,
    state,
    accept_rules
     FROM bonus_main
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# tp_add()
#**********************************************************
sub user_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $DATA{STATE} = 1;

  $self->query2("INSERT INTO bonus_main (uid, tp_id, state, accept_rules)
        VALUES ('$DATA{UID}', '$DATA{TP_ID}', '$DATA{STATE}', '$DATA{ACCEPT_RULES}');", 'do'
  );

  if ($CONF->{BONUS_ACCOMULATION}){
    $self->accomulation_first_rule($attr);
  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? $attr->{STATE} : 0;

  $admin->{MODULE} = $MODULE;

  $attr->{ACCEPT_RULES} = ($attr->{ACCEPT_RULES}) ? 1 : 0;
 
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'bonus_main',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from bonus_main WHERE uid='$attr->{UID}';", 'do');

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ("bu.uid = u.uid");
  $self->{EXT_TABLES}='';

  my $WHERE =  $self->search_former($attr, [
      ['TP_ID',          'INT', 'bu.tp_id',  1 ],
      ['DV_TP_ID',       'INT', 'tp.tp_id',  1 ],
      ['BONUS_ACCOMULATION', '', '', 'ras.cost'],
    ],
    { WHERE             => 1,
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS      => 1,
    }
    );

  my $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ($CONF->{BONUS_ACCOMULATION}){
    $EXT_TABLE .= "LEFT JOIN bonus_rules_accomulation_scores ras ON (ras.uid = u.uid)";
  }

  if ($attr->{DV_TP_ID}) {
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.uid = u.uid)
      LEFT JOIN tarif_plans tp  ON (tp.id = dv.tp_id)
    ";
  }

  $self->query2("SELECT u.id AS login, pi.fio, b_tp.name AS tp_name, bu.state, 
      if(company.id IS NULL, b.deposit, cb.deposit) AS deposit, 
      if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)) AS credit, u.disable, 
     $self->{SEARCH_FIELDS}     
     bu.uid
      
     FROM (bonus_main bu, users u)
     LEFT JOIN users_pi pi ON (u.uid=pi.uid)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  my $list = $self->{list};

  $self->query2("SELECT count(DISTINCT bu.uid) AS total      
     FROM (bonus_main bu, users u)
     LEFT JOIN users_pi pi ON (u.uid=pi.uid)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     $EXT_TABLE
     $WHERE;",
     undef,
     { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# add()
#**********************************************************
sub bonus_operation {
  my $self = shift;
  my ($user, $attr) = @_;

  %DATA = $self->get_data($attr, { default => defaults() });

  if ($DATA{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  if ($DATA{CHECK_EXT_ID}) {
    $self->query2("SELECT id, date FROM bonus_log WHERE ext_id='$DATA{CHECK_EXT_ID}';");
    if ($self->{TOTAL} > 0) {
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUBLICATE';
      $self->{ID}     = $self->{list}->[0][0];
      $self->{DATE}   = $self->{list}->[0][1];
      return $self;
    }
  }

  #$self->{db}->{AutoCommit}=0;
  $user->{EXT_BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});


  if ($user->{EXT_BILL_ID} > 0) {
    my $bill_action_type = '';
    if ($DATA{ACTION_TYPE}) {
      $bill_action_type = 'take';
    }
    else {
      $bill_action_type = 'add';
    }

    $Bill->info({ BILL_ID => $user->{EXT_BILL_ID} });
    $Bill->action($bill_action_type, $user->{EXT_BILL_ID}, $DATA{SUM});
    if ($Bill->{errno}) {
      return $self;
    }

    my $date = ($DATA{DATE}) ? "'$DATA{DATE}'" : 'now()';
    $self->query2("INSERT INTO bonus_log (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
           inner_describe, action_type, expire) 
           values ('$user->{UID}', '$user->{EXT_BILL_ID}', $date, '$DATA{SUM}', '$DATA{DESCRIBE}', INET_ATON('$admin->{SESSION_IP}'), 
           '$Bill->{DEPOSIT}', '$admin->{AID}', '$DATA{METHOD}', 
           '$DATA{EXT_ID}', '$DATA{INNER_DESCRIBE}', '$DATA{ACTION_TYPE}', '$DATA{EXPIRE}');", 'do'
    );

    $self->{BONUS_PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  #$self->{db}->commit;
  #$self->{db}->rollback;

  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub bonus_operation_del {
  my $self = shift;
  my ($user, $id) = @_;

  $self->query2("SELECT sum, bill_id, action_type from bonus_log WHERE id='$id';");

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

  $self->query2("DELETE FROM bonus_log WHERE id='$id';", 'do');
  $admin->action_add($user->{UID}, "BONUS $bill_action:$id SUM:$sum", { TYPE => 10 });

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub bonus_operation_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $self->{SEARCH_FIELDS} = '';
  undef @WHERE_RULES;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  my $WHERE =  $self->search_former($attr, [
      ['LOGIN',          'STR', 'u.id'                          ], 
      ['DATETIME',       'DATE','p.date',   'p.date AS datetime'], 
      ['SUM',            'INT', 'p.sum',                        ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                     ],
      ['A_LOGIN',        'STR', 'a.id AS admin_login',        1 ],
      ['DESCRIBE',       'STR', 'p.dsc'                         ],
      ['INNER_DESCRIBE', 'STR', 'p.inner_describe'              ],
      ['AMOUNT',         'INT', 'p.amount',                    1],
      ['CURRENCY',       'INT', 'p.currency',                  1],
      ['METHOD',         'INT', 'p.method',                    1],
      ['BILL_ID',        'INT', 'p.bill_id',                   1],
      ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'],
      ['EXT_ID',         'STR', 'p.ext_id',                               1],
      ['INVOICE_NUM',    'INT', 'd.invoice_num',                          1],
      ['DATE',           'DATE','date_format(p.date, \'%Y-%m-%d\')'        ], 
      ['EXPIRE',         'DATE','date_format(p.expire, \'%Y-%m-%d\')',   'date_format(p.expire, \'%Y-%m-%d\') AS expire' ], 
      ['REG_DATE',       'DATE','p.reg_date',                             1],      
      ['MONTH',          'DATE','date_format(p.date, \'%Y-%m\') AS month'  ],
      ['ID',             'INT', 'p.id'                                     ],
      ['AID',            'INT', 'p.aid',                                   ],
      ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "p.date"                      ],
      ['FROM_DATE|TO_DATE', 'DATE',    'date_format(p.date, \'%Y-%m-%d\')' ],
      ['UID',            'INT', 'p.uid',                                  1],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
      USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS=> [ 'BILL_ID', 'UID' ]
    }    
    );

    my $EXT_TABLES = $self->{EXT_TABLES};

    $self->query2("SELECT p.id, u.id AS login, $self->{SEARCH_FIELDS} 
      p.date, p.dsc, p.sum, p.last_deposit, p.expire, p.method, 
      p.ext_id, p.bill_id, if(a.name is null, 'Unknown', a.name),
      INET_NTOA(p.ip) AS ip, p.action_type, p.uid, p.inner_describe
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE 
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = '0.00';

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query2("SELECT count(p.id) AS total, sum(p.sum) AS sum, count(DISTINCT p.uid) AS total_users FROM bonus_log p
  LEFT JOIN users u ON (u.uid=p.uid)
  LEFT JOIN admins a ON (a.aid=p.aid)
  $EXT_TABLES
   $WHERE",
  undef,
  { INFO => 1 }
  );
  return $list;
}

#**********************************************************
#
# service_discount_info()
#**********************************************************
sub service_discount_info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE id='$id'";

  $self->query2("SELECT * FROM bonus_service_discount
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# service_discount_add()
#**********************************************************
sub service_discount_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $self->query_add('bonus_service_discount', \%DATA);

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub service_discount_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_service_discount',
      DATA         => $attr
    }
  );

  $self->service_discount_info($attr->{ID});

  return $self;
}

#**********************************************************
#
# service_discount_del(attr);
#**********************************************************
sub service_discount_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from bonus_service_discount WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
# service_discount_list()
#**********************************************************
sub service_discount_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  @WHERE_RULES = ();
  $self->{SEARCH_FIELDS}      = '';
  $self->{SEARCH_FIELDS_COUNT}= 0;

  my $WHERE =  $self->search_former($attr, [
      ['TP_ID',             'INT', 'tp_id'                ], 
      ['REGISTRATION_DAYS', 'INT', 'registration_days'    ], 
      ['PERIODS',           'INT', 'service_period'       ],
      ['TOTAL_PAYMENTS_SUM','INT', 'total_payments_sum'   ],
      ['PAY_METHOD',        'INT', 'pay_method'           ],
    ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES,
    }    
    );

  $self->query2("SELECT service_period, registration_days, total_payments_sum,
  discount, discount_days,  bonus_sum,  bonus_percent, ext_account, pay_method, id
     FROM bonus_service_discount
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
#
# bonus_turbo_info()
#**********************************************************
sub bonus_turbo_info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE = "WHERE id='$id'";

  $self->query2("SELECT id,
    service_period,
    registration_days,
    turbo_count,
    comments
     FROM bonus_turbo
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# bonus_turbo_add()
#**********************************************************
sub bonus_turbo_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $self->query2("INSERT INTO bonus_turbo (service_period, registration_days, turbo_count, comments)
        VALUES ('$DATA{SERVICE_PERIOD}', '$DATA{REGISTRATION_DAYS}', '$DATA{TURBO_COUNT}', '$DATA{DESCRIBE}');", 'do'
  );

  return $self;
}

#**********************************************************
# bonus_turbo_change()
#**********************************************************
sub bonus_turbo_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'bonus_turbo',
      DATA         => $attr
    }
  );

  $self->bonus_turbo_info($attr->{ID});

  return $self;
}

#**********************************************************
#
# bonus_turbo_del(attr);
#**********************************************************
sub bonus_turbo_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query2("DELETE from bonus_turbo WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
# bonus_turbo_list()
#**********************************************************
sub bonus_turbo_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT service_period, registration_days, turbo_count, id
     FROM bonus_turbo
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# 
# accomulation_rule_info()
#**********************************************************
sub accomulation_rule_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "WHERE id='$attr->{TP_ID} AND dv_tp_id='$attr->{DV_TP_ID}'";

  $self->query2("SELECT tp_id,
    dv_tp_id,
    cost
     FROM bonus_rules 
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# accomulation_rule_add()
#**********************************************************
sub accomulation_rule_change {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  my @ids = split(/, /, $attr->{DV_TP_ID});

  foreach my $id (@ids) {
    $self->query2("REPLACE INTO bonus_rules_accomulation (tp_id, dv_tp_id, cost)
        VALUES ('$DATA{TP_ID}', '$id', '". $DATA{'COST_'.$id} ."');", 'do'
    );
  }

  return $self;
}



#**********************************************************
# accomulation_rule_list()
#**********************************************************
sub accomulation_rule_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ("tp.module='Dv'");
  
  
  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "br.tp_id='$attr->{TP_ID}'";
  }

  my $JOIN_WHERE = '';
  if ($attr->{DV_TP_ID}) {
    push @WHERE_RULES, "br.dv_tp_id='$attr->{DV_TP_ID}'";
    $JOIN_WHERE = "AND br.tp_id='$attr->{TP_ID}'";
  }

  if ($attr->{COST}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{COST}", 'INT', 'cost') };
  }
 
  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT br.tp_id, tp.name, tp.tp_id AS dv_tp_id, br.cost
     FROM tarif_plans tp
     LEFT JOIN bonus_rules_accomulation br ON (br.dv_tp_id=tp.tp_id $JOIN_WHERE)
     WHERE $WHERE 
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}



#**********************************************************
#
# accomulation_scores_info()
#**********************************************************
sub accomulation_scores_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "WHERE uid='$attr->{UID}'";

  $self->query2("SELECT  dv_tp_id, cost, changed
     FROM bonus_rules_accomulation_scores
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# accomulation_scores_change()
#**********************************************************
sub accomulation_scores_change {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $self->query2("REPLACE INTO bonus_rules_accomulation_scores (uid, dv_tp_id, cost)
        VALUES ('$DATA{UID}', '$DATA{DV_TP_ID}', '$DATA{SCORE}');", 'do'
  );

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$DATA{UID}", "SCORE:$DATA{SCORE}", { TYPE => 2 });

  return $self;
}


#**********************************************************
# accomulation_scores_add()
#**********************************************************
sub accomulation_scores_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $DATA{DV_TP_ID}=0 if (! $DATA{DV_TP_ID});

  $self->query2("UPDATE bonus_rules_accomulation_scores SET  
        dv_tp_id='$DATA{DV_TP_ID}', 
        cost=cost + $DATA{SCORE}
      WHERE uid='$attr->{UID}';", 'do'
  );

  if ($self->{AFFECTED} == 0 && $CONF->{BONUS_PAYMENTS_AUTO}){
    $self->accomulation_scores_change({ 
           UID      => $attr->{UID}, 
           SCORE    => $attr->{SCORE},
           DV_TP_ID => 0  });

  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add("$DATA{UID}", "SCORE:$DATA{SCORE}", { TYPE => 1 });

  return $self;
}


#**********************************************************
# accomulation_scores_list()
#**********************************************************
sub accomulation_scores_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;

  if ($attr->{REGISTRATION_DAYS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

  if ($attr->{PERIODS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT service_period, registration_days, turbo_count, id
     FROM bonus_rules_accomulation_scores bs
     INNER JOIN users u ON (u.uid=bs.uid)
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
     undef, $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}


#**********************************************************
#
#**********************************************************
sub accomulation_first_rule {
  my $self   = shift;
  my ($attr) = @_;
  
  $CONF->{BONUS_ACCOMULATION_FIRST_BONUS}=0 if (! $CONF->{BONUS_ACCOMULATION_FIRST_BONUS});
  $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}=3 if (! defined($CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}));

  $self->query2( "SELECT PERIOD_DIFF(DATE_FORMAT(max(date), '%Y%m'), 
DATE_FORMAT(min(date), '%Y%m')) FROM fees where uid='$attr->{UID}' AND
    date>=curdate() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH");
    
  if ($self->{list}->[0]->[0]>=$CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL}) { 
    $self->query2("REPLACE INTO bonus_rules_accomulation_scores (uid, cost, changed)
SELECT $attr->{UID}, IF((SELECT \@A:=min(last_deposit) FROM fees WHERE uid='$attr->{UID}' AND date>=curdate() - INTERVAL $CONF->{BONUS_ACCOMULATION_FIRST_INTERVAL} MONTH) >= 0 OR \@A is null , $CONF->{BONUS_ACCOMULATION_FIRST_BONUS}, 0), curdate();", 'do');
  }

  return $self;
}



1

