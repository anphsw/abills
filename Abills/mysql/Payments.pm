package Payments;

# Payments Finance module
#************************************************************

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.05;
@ISA     = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");
use Finance;
@ISA = ("Finance");

use Bills;
my $Bill;

my %FIELDS = (
  UID          => 'uid',
  DATE         => 'date',
  SUM          => 'sum',
  DESCRIBE     => 'dsc',
  IP           => 'ip',
  LAST_DEPOSIT => 'last_deposit',
  AID          => 'aid',
  METHOD       => 'method',
  EXT_ID       => 'ext_id',
  BILL_ID      => 'bill_id',
  AMOUNT       => 'amount',
  CURRENCY     => 'currency'
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift; 

  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
    UID            => 0,
    BILL_ID        => 0,
    SUM            => '0.00',
    DESCRIBE       => '',
    INNER_DESCRIBE => '',
    IP             => '0.0.0.0',
    LAST_DEPOSIT   => '0.00',
    AID            => 0,
    METHOD         => 0,
    ER             => 1,
    EXT_ID         => '',
    AMOUNT         => '0.00',
    CURRENCY       => '0'
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($user, $attr) = @_;

  %DATA = $self->get_data($attr, { default => defaults() });
  if ($DATA{SUM} <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }

  if ($DATA{CHECK_EXT_ID}) {
    $self->query2("SELECT id, date, sum, uid FROM payments WHERE ext_id='$DATA{CHECK_EXT_ID}' LOCK IN SHARE MODE;");
    if ($self->{error}) {
      return $self;
    }
    elsif ($self->{TOTAL} > 0) {
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUBLICATE';
      $self->{ID}     = $self->{list}->[0][0];
      $self->{DATE}   = $self->{list}->[0][1];
      $self->{SUM}    = $self->{list}->[0][2];
      $self->{UID}    = $self->{list}->[0][3];
      return $self;
    }
  }

  if ($self->{db}->{db}) {
    $self->{db}->{db}->{AutoCommit} = 0;
  }
  else {
    $self->{db}->{AutoCommit} = 0;
  }

  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});

  $DATA{AMOUNT} = $DATA{SUM};
  if ($user->{BILL_ID} > 0) {
    if ($DATA{ER} && $DATA{ER} != 1) {
      $DATA{SUM} = sprintf("%.2f", $DATA{SUM} / $DATA{ER});
    }

    $Bill->info({ BILL_ID => $user->{BILL_ID} });
    $Bill->action('add', $user->{BILL_ID}, $DATA{SUM});
    if ($Bill->{errno}) {
      $self->{db}->rollback();
      return $self;
    }

    my $date = ($DATA{DATE}) ? "'$DATA{DATE}'" : 'now()';

    $self->query2("INSERT INTO payments (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
           inner_describe, amount, currency, reg_date) 
           values ('$user->{UID}', '$user->{BILL_ID}', $date, '$DATA{SUM}', '$DATA{DESCRIBE}', INET_ATON('$admin->{SESSION_IP}'), '$Bill->{DEPOSIT}', '$admin->{AID}', '$DATA{METHOD}', 
           '$DATA{EXT_ID}', '$DATA{INNER_DESCRIBE}', '$DATA{AMOUNT}', '$DATA{CURRENCY}', now());", 'do'
    );

    if (!$self->{errno}) {
      if ($CONF->{payment_chg_activate} && $user->{ACTIVATE} ne '0000-00-00') {
        $user->change(
          $user->{UID},
          {
            UID      => $user->{UID},
            ACTIVATE => "$admin->{DATE}",
            EXPIRE   => '0000-00-00'
          }
        );
      }
      $self->{SUM} = $DATA{SUM};
      if (!$attr->{TRANSACTION}) {
        if ($self->{db}->{db}) {
          $self->{db}->{db}->commit() ;
        }
        else {
          $self->{db}->commit() ;
        }
      }
    }
    else {
      if ($self->{db}->{db}) {
        $self->{db}->{db}->rollback() ;
      }
      else {
        $self->{db}->rollback();
      }     
    }

    $self->{PAYMENT_ID} = $self->{INSERT_ID};
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  if (!$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    if ($self->{db}->{db}) {
      $self->{db}->{db}->{AutoCommit} = 1 
    }
    else {
      $self->{db}->{AutoCommit} = 1  
    }
  }

  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id, $attr) = @_;

  $self->query2("SELECT sum, bill_id from payments WHERE id='$id';");

  $self->{db}->{AutoCommit} = 0;
  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('take', $bill_id, $sum);
  if (! $Bill->{errno}) {
    $self->query2("DELETE FROM docs_invoice2payments WHERE payment_id='$id';", 'do');
    $self->query2("DELETE FROM docs_receipt_orders WHERE receipt_id=(SELECT id FROM docs_receipts WHERE payment_id='$id');", 'do');
    $self->query2("DELETE FROM docs_receipts WHERE payment_id='$id';", 'do');    
    $self->query2("DELETE FROM payments WHERE id='$id';", 'do');
    if (! $self->{errno}) {
    	my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';
      $admin->action_add($user->{UID}, "$id $sum $comments", { TYPE => 16 });
      $self->{db}->commit();
    }
    else {
      $self->{db}->rollback();
    }
  }

  $self->{db}->{AutoCommit} = 1;
  return $self;
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

  @WHERE_RULES = ();

  my $login_field = '';
  if (! $attr->{PAYMENT_DAYS}) {
  	$attr->{PAYMENT_DAYS}=0;
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ s/^(<|>)//) {
      $expr = $1;
    }
    push @WHERE_RULES, "p.date $expr curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',       'DATE','p.date',   'p.date AS datetime'], 
      ['SUM',            'INT', 'p.sum',                        ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                     ],
      ['A_LOGIN',        'STR', 'a.id'                          ],
      ['DESCRIBE',       'STR', 'p.dsc'                         ],
      ['INNER_DESCRIBE', 'STR', 'p.inner_describe'              ],
      ['AMOUNT',         'INT', 'p.amount',                    1],
      ['CURRENCY',       'INT', 'p.currency',                  1],
      ['METHOD',         'INT', 'p.method'                      ],
      ['BILL_ID',        'INT', 'p.bill_id',                   1],
      ['AID',            'INT', 'p.aid',                        ],
      ['IP',             'INT', 'INET_NTOA(p.ip)',  'INET_NTOA(p.ip) AS ip'],
      ['EXT_ID',         'STR', 'p.ext_id',                                ],
      ['INVOICE_NUM',    'INT', 'd.invoice_num',                          1],
      ['DATE',           'DATE','date_format(p.date, \'%Y-%m-%d\')'        ], 
      ['REG_DATE',       'DATE','p.reg_date',                             1],      
      ['MONTH',          'DATE','date_format(p.date, \'%Y-%m\') AS month'  ],
      ['ID',             'INT', 'p.id'                                     ],
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

  my $EXT_TABLES  = '';
  $EXT_TABLES  = $self->{EXT_TABLES} if($self->{EXT_TABLES});
  
  if ($attr->{INVOICE_NUM}) {
    $EXT_TABLES  .= '  LEFT JOIN (SELECT payment_id, invoice_id FROM docs_invoice2payments GROUP BY payment_id) i2p ON (p.id=i2p.payment_id)
  LEFT JOIN (SELECT id, invoice_num FROM docs_invoices GROUP BY id) d ON (d.id=i2p.invoice_id) 
';
  }

  if ($WHERE =~ /pi\./ || $self->{SEARCH_FIELDS} =~ /pi\./) {
    $EXT_TABLES  = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)'.$EXT_TABLES ;
  }
  elsif ($EXT_TABLES =~ /builds/ && $EXT_TABLES !~ /users_pi/) {
    $EXT_TABLES = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid) '. $EXT_TABLES;
  }
  
  my $list;
  if (!$attr->{TOTAL_ONLY}) {
    $self->query2("SELECT p.id, 
      u.id AS login, 
      p.date AS datetime, 
      p.dsc, 
      p.sum, 
      p.last_deposit, 
      p.method, 
      p.ext_id, 
      if(a.name is null, 'Unknown', a.name) AS admin_name,  
      $self->{SEARCH_FIELDS}
      p.inner_describe,
      p.uid 
    FROM payments p
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
    $list = $self->{list};
  }

  $self->query2("SELECT count(DISTINCT p.id) AS total, sum(p.sum) AS sum, count(p.uid) AS total_users
    FROM payments p
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
# report
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date       = '';
  my $EXT_TABLES = '';
  my $GROUP      = 1;

  undef @WHERE_RULES;

  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if (defined($attr->{METHOD}) and $attr->{METHOD} ne '') {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{METHOD}", 'INT', 'p.method') };
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, "date_format(p.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);

    push @WHERE_RULES, @{ $self->search_expr(">=$from", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') }, @{ $self->search_expr("<=$to", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') };

    if ($attr->{TYPE} eq 'HOURS') {
      $date = "date_format(p.date, '%H') AS hour";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "date_format(p.date, '%Y-%m-%d') AS date";
    }
    elsif ($attr->{TYPE} eq 'PAYMENT_METHOD') {
      $date = "p.method";
    }
    elsif ($attr->{TYPE} eq 'FIO') {
      $EXT_TABLES = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
      $date       = "pi.fio";
      $GROUP      = 5;
    }
    elsif ($attr->{TYPE} eq 'PER_MONTH') {
      $date = "date_format(p.date, '%Y-%m') AS date";
    }
    elsif ($attr->{TYPE} eq 'ADMINS') {
      $date = "a.id AS admin_name";
    }
    else {
      $date = "u.id AS login";
    }
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(p.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(p.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{PAYMENT_DAYS}) {
    my $expr = '=';
    if ($attr->{PAYMENT_DAYS} =~ /(<|>)/) {
      $expr = $1;
    }
    push @WHERE_RULES, "p.date $expr curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }
  else {
    $date = "date_format(p.date, '%Y-%m') AS month";
  }

  if ($attr->{ADMINS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADMINS}, 'STR', 'a.id') };
    $date = 'u.id AS login';
  }


  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
    $EXT_TABLES = "INNER JOIN users u ON (u.uid=p.uid) ".$EXT_TABLES;
  }
  else {
    $EXT_TABLES = "LEFT JOIN users u ON (u.uid=p.uid)". $EXT_TABLES;
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT $date, count(DISTINCT p.uid) AS login_count, count(*) AS count, sum(p.sum) AS sum, p.uid 
      FROM payments p
      LEFT JOIN admins a ON (a.aid=p.aid)
      $EXT_TABLES
      $WHERE 
      GROUP BY 1
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(DISTINCT p.uid) AS users, count(*) AS total, sum(p.sum) AS sum
      FROM payments p
      LEFT JOIN admins a ON (a.aid=p.aid)
      $EXT_TABLES
      $WHERE;",
      undef,
      { INFO => 1 }
    );
  }
  else {
    $self->{USERS} = 0;
    $self->{TOTAL} = 0;
    $self->{SUM}   = 0.00;
  }

  return $list;
}

1
