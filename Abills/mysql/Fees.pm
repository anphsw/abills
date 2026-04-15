package Fees;

=head1 NAME

  Finance (fees) module DB frontend

=cut

use strict;
use parent qw(dbcore Finance);
use Conf;
use Bills;

my $Bill;
my ($admin, $CONF);

#**********************************************************
=head new($db, $admin,$CONF)

  Arguments:
    $db
    $admin,
    $CONF

  Results:
    $self

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift; 
  ($admin, $CONF) = @_;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 take($user, $sum, $attr) - Take sum from bill account

  Arguments:
    $user
    $sum
    $attr
      SKIP_PRIORITY
      BILL_ID
      DESCRIBE
      INNER_DESCRIBE

  Resturn:
    $self

=cut
#**********************************************************
sub take {
  my ($self, $user, $sum, $attr) = @_;

  if ($sum <= 0) {
    $self->{errno}  = 12;
    $self->{errstr} = 'ERROR_ENTER_SUM';
    return $self;
  }
  elsif ($user->{UID} <= 0) {
    $self->{errno}  = 18;
    $self->{errstr} = 'ERROR_ENTER_UID';
    return $self;
  }

  my $fees_priority = $CONF->{FEES_PRIORITY} || q{};
  if($attr->{SKIP_PRIORITY}) {
    $fees_priority = q{};
    $user->{BILL_ID} = $attr->{BILL_ID} if($attr->{BILL_ID});
  }

  $attr->{UID}     = $user->{UID};
  $attr->{BILL_ID} = $user->{BILL_ID} if(! $attr->{BILL_ID});
  $attr->{DATE}    = ($attr->{DATE}) ? $attr->{DATE} : 'NOW()';
  $attr->{DSC}     = $attr->{DESCRIBE} || '';
  $attr->{IP}      = $admin->{SESSION_IP};
  $attr->{AID}     = $admin->{AID} || 1;
  $attr->{VAT}     = $user->{COMPANY_VAT};

  $sum = sprintf("%.4f", $sum);
  my DBI $db = $self->{db}{db};
  $db->{AutoCommit} = 0;

  $self->{SUM} = $sum;

  if ($attr->{BILL_ID} && ! $user->{BILL_ID}) {
    $user->{BILL_ID} = $attr->{BILL_ID};
  }

  if ($CONF->{FEES_PRIORITY} && ! $attr->{BILL_ID}) {
    $self->_fees_priority($user, $sum, $attr);
    return $self if ($self->{finish});
  }

  if ($user->{BILL_ID} && $user->{BILL_ID} > 0) {
    $Bill->info({ BILL_ID => $user->{BILL_ID} });

    $Bill->action('take', $user->{BILL_ID}, $self->{SUM});
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }

    $self->query_add('fees', {
      %$attr,
      BILL_ID      => $user->{BILL_ID},
      SUM          => $self->{SUM},
      LAST_DEPOSIT => $Bill->{DEPOSIT},
      REG_DATE     => 'NOW()'
    });

    if ($self->{errno}) {
      $db->rollback();
      return $self;
    }
    else {
      $db->commit() if(!$self->{db}->{TRANSACTION});
    }

    $self->{FEES_ID} = $self->{INSERT_ID};

    if(grep { $attr->{$_} } (qw/ START_DATE END_DATE MODULE TP_ID COUNT DISCOUNT /)) {
      #print @{ $attr }{ qw(START_DATE END_DATE MODULE TP_ID UNITS COUNT DISCOUNT ) };
      $attr->{FEES_ID}=$self->{INSERT_ID};
      $self->query_add('fees_extra', $attr);
    }
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  if (! $self->{db}->{TRANSACTION} && !$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    $db->{AutoCommit} = 1 ;
  }

  return $self;
}

#**********************************************************
=head2 _fees_priority($user, $sum, $attr) - Take sum from bill account

  Arguments:
    $user
    $sum
    $attr
      SKIP_PRIORITY
      BILL_ID
      DESCRIBE
      INNER_DESCRIBE

  Resturn:
    $self

=cut
#**********************************************************
sub _fees_priority {
  my ($self, $user, $sum, $attr) = @_;

  my $fees_priority = $CONF->{FEES_PRIORITY} || q{};

  if ($fees_priority =~ /^bonus/xm && $user->{EXT_BILL_ID}) {
    if ($user->{EXT_BILL_ID} && !defined($user->{EXT_BILL_DEPOSIT})) {
      if (! $user->{EXT_BILL_ID} || ! defined($user->{EXT_BILL_DEPOSIT})) {
        my $uid = $user->{UID};
        my $fn  = 'user::info';
        if (! defined( &$fn )) {
          $user = Users->new($self->{db}, $admin, $CONF);
        }
        $user->info($uid);
      }

      $user->info($user->{UID});
    }

    if ($fees_priority =~ /main/xm && $user->{EXT_BILL_DEPOSIT} < $sum) {
      if ($user->{EXT_BILL_DEPOSIT} > 0) {
        $Bill->action('take', $user->{EXT_BILL_ID}, $user->{EXT_BILL_DEPOSIT});
        if ($Bill->{errno}) {
          $self->{errno}  = $Bill->{errno};
          $self->{errstr} = $Bill->{errstr};
          return $self;
        }

        $self->{SUM} = $user->{EXT_BILL_DEPOSIT};
        $self->query_add('fees', {
          %$attr,
          SUM          => $self->{SUM},
          BILL_ID      => $user->{EXT_BILL_ID},
          LAST_DEPOSIT => $user->{EXT_BILL_DEPOSIT},
          METHOD       => $attr->{EXT_BILL_METHOD} || $attr->{METHOD}
        });

        $sum = $sum - $user->{EXT_BILL_DEPOSIT};
      }
    }
    else {
      $user->{BILL_ID} = $user->{EXT_BILL_ID};
      if($attr->{EXT_BILL_METHOD}) {
        $attr->{METHOD} = $attr->{EXT_BILL_METHOD};
      }
    }
  }
  elsif ($fees_priority =~ /^main,bonus/xm) {
    if (! $user->{EXT_BILL_ID} || ! defined($user->{EXT_BILL_DEPOSIT})) {
      my $uid = $user->{UID};
      my $fn  = 'user::info';
      if (! defined( &$fn )) {
        $user = Users->new($self->{db}, $admin, $CONF);
      }
      $user->info($uid);
    }

    if ($user->{EXT_BILL_DEPOSIT} && $user->{DEPOSIT} < $sum) {
      if ($user->{EXT_BILL_DEPOSIT} + $user->{DEPOSIT} > $sum) {
        $self->{SUM} = $user->{DEPOSIT};
      }
      else {
        $self->{SUM} = $sum - $user->{EXT_BILL_DEPOSIT};
      }

      if ($self->{SUM} > 0) {
        $Bill->action('take', $user->{BILL_ID}, $self->{SUM});
        if ($Bill->{errno}) {
          $self->{errno}  = $Bill->{errno};
          $self->{errstr} = $Bill->{errstr};
          return $self;
        }

        $self->query_add('fees', {
          %$attr,
          BILL_ID      => $user->{BILL_ID},
          SUM          => $self->{SUM},
          LAST_DEPOSIT => $Bill->{DEPOSIT},
        });

        $sum = $sum - $self->{SUM};
      }
      $user->{BILL_ID} = $user->{EXT_BILL_ID};
      if($attr->{EXT_BILL_METHOD}) {
        $attr->{METHOD} = $attr->{EXT_BILL_METHOD};
      }
    }
  }

  if ($sum == 0) {
    if (!$attr->{NO_AUTOCOMMIT} && ! $self->{db}->{TRANSACTION}) {
      my DBI $db = $self->{db}{db};
      $db->{AutoCommit} = 1;
    }
    $self->{finish}=1;
  }

  $self->{SUM}=$sum;

  return $self;
}

#**********************************************************
=head2 del($user, $id, $attr)

  Arguments:
    $user,
    $id,
    $attr
  Results:
    $self

=cut
#**********************************************************
sub del {
  my ($self, $user, $id, $attr) = @_;

  $self->query("SELECT sum, bill_id, reg_date from fees WHERE id= ? ;", undef, { Bind => [ $id ] });

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id, $date) = @{ $self->{list}->[0] };

  $Bill->action('add', $bill_id, $sum);

  $self->query_del('fees', { ID => $id });

   my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';

  $admin->{MODULE}=q{};
  $admin->action_add($user->{UID}, "ID:$id, AMOUNT:$sum, FEE DATE:$date / $comments", { TYPE => 17 });

  return $self;
}

#**********************************************************
=head2  list($attr) - Fees list

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = $attr->{_GROUP_BY} || $attr->{GROUP_BY} || 'f.id';

  my $table_name = 'fees';
  if ($attr->{TABLE_SUFIX}) {
    $table_name .= '_' . $attr->{TABLE_SUFIX};
  }

  my @WHERE_RULES = ();
  if ($attr->{FEES_MONTHES}) {
    push @WHERE_RULES, "f.date >= CURDATE() - INTERVAL $attr->{FEES_MONTHES} MONTH";
  }

  if ($attr->{_GROUP_BY}) {
    $attr->{_GROUP_SUM} = '_SHOW';
    $attr->{_GROUP_COUNT} = '_SHOW';
  }

  if ($attr->{TAGS} && $attr->{TAGS} ne '_SHOW' && $attr->{TAG_SEARCH_VAL} && $attr->{TAG_SEARCH_VAL} == 1) {
    my $tags_count = scalar(split /,\s?/x, $attr->{TAGS});
    push @WHERE_RULES, << "WHERE";
u.uid IN (SELECT tu.uid
      FROM tags_users tu
      GROUP BY tu.uid
      HAVING COUNT(DISTINCT CASE WHEN tu.tag_id IN ($attr->{TAGS}) THEN tu.tag_id END) = $tags_count)
WHERE
    $attr->{TAGS} = '_SHOW';
  }
  elsif ($attr->{TAGS} && $attr->{TAGS} ne '_SHOW' && $attr->{TAG_SEARCH_VAL} && $attr->{TAG_SEARCH_VAL} == 2) {
    push @WHERE_RULES, "u.uid NOT IN (SELECT tu.uid FROM tags_users tu WHERE tu.tag_id IN ($attr->{TAGS}))";
    $attr->{TAGS} = '_SHOW';
  }
  $attr->{UID} =~ s/\,/;/xg if ($attr->{UID} && $attr->{UID} =~ /,/xm);

  my @search_params = (
    ['ID',             'INT', 'f.id',                              ],
    ['DATETIME',       'DATE','f.date',        'f.date AS datetime'],
    ['LAST_DATE',      'DATE','MAX(f.date)',  'MAX(f.date) AS date'],
    ['LOGIN',          'STR', 'u.id',              'u.id AS login' ],
    ['FIO',            'STR', 'pi.fio',                            ],
    ['DESCRIBE',       'STR', 'f.dsc',                           1 ],
    ['DSC',            'STR', 'f.dsc',                           1 ],
    ['SUM',            'INT', 'f.sum',                           1 ],
    ['_GROUP_SUM',     'INT', 'f.sum',   'SUM(f.sum) AS _group_sum'],
    ['_GROUP_COUNT',   'INT', '',        'COUNt(*) AS _group_count'],
    ['LAST_DEPOSIT',   'INT', 'f.last_deposit',                  1 ],
    ['AFTER_DEPOSIT',  'INT', '(f.last_deposit-f.sum) AS after_deposit', 1 ],
    ['METHOD',         'INT', 'f.method',                        1 ],
    ['METHOD_ID',      'INT', 'f.method', 'f.method AS method_id'  ],
    ['METHOD_NAME',    'STR', 'ft.name',  'ft.name AS method_name' ],
    ['COMPANY_ID',     'INT', 'u.company_id',                      ],
    ['EDRPOU',         'STR', 'c.edrpou',                        1 ],
    ['A_LOGIN',        'STR', 'a.id', 'a.id as a_login',         1 ],
    # ['ADMIN_NAME',     'STR', 'a.id'                               ],
    ['ADMIN_NAME',     'STR', 'a.name', "IF(a.name is NULL, 'Unknown', a.name) AS admin_name" ],
    ['BILL_ID',        'INT', 'f.bill_id',                       1 ],
    ['IP',             'INT', 'INET_NTOA(f.ip)', 'INET_NTOA(f.ip) AS ip'  ],
    ['AID',            'INT', 'f.aid',                           1 ],
    ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
    ['UID',            'INT', 'f.uid',                           1 ],
    ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
    ['DATE',           'DATE','DATE_FORMAT(f.date, \'%Y-%m-%d\')'  ],
    ['FROM_DATE|TO_DATE','DATE', 'DATE_FORMAT(f.date, \'%Y-%m-%d\')'  ],
    ['FROM_DATE_TIME|TO_DATE_TIME','DATE', "f.date"                   ],
    ['MONTH',          'DATE', "DATE_FORMAT(f.date, '%Y-%m')", "DATE_FORMAT(f.date, '%Y-%m') as month"],
    ['REG_DATE',       'DATE', "f.reg_date", "f.reg_date",       1 ],
    ['TAX',            'INT',  'ft.tax',                         1 ],
    ['TAX_SUM',        'INT',  '', 'IF(ft.tax>0, SUM(f.sum) / 100 * ft.tax, 0) AS tax_sum'],
    ['ADMIN_DISABLE',  'INT',  'a.disable', 'a.disable AS admin_disable',               1 ],
    ['INVOICE_NUM',    'INT',  'invoice.invoice_num',                                   1 ],
    ['INVOICE_ID',     'INT',  'invoice.id',  'invoice.id AS invoice_id'                  ],
    ['SUBCONTO',       'STR',  'ft.subconto',                                           1 ],
    ['START_DATE',     'DATE', 'fe.start_date',         1 ],
    ['END_DATE',       'DATE', 'fe.end_date',           1 ],
    ['MODULE',         'STR',  'fe.module',             1 ],
    ['TP_ID',          'INT',  'fe.tp_id',              1 ],
    ['COUNT',          'INT',  'fe.count',              1 ],
    ['UNITS',          'INT',  'fe.units',              1 ],
    ['DISCOUNT',       'INT',  'fe.discount',           1 ],
    ['PAYMENT_ID',     'INT',  'p2f.payment_id',        1 ],
    ['COMPENSATION',   'INT',  'p.sum',   'p.sum AS compensation' ]
  );

  my $WHERE =  $self->search_former($attr, \@search_params,
    { WHERE             => 1,
      USERS_FIELDS      => 1,
      SKIP_USERS_FIELDS => [ 'BILL_ID', 'UID', 'LOGIN' ],
      USE_USER_PI       => 1,
      WHERE_RULES       => \@WHERE_RULES,
    });

  my $EXT_TABLES  = $self->{EXT_TABLES};

  if(grep { $attr->{$_} } (qw/ START_DATE END_DATE MODULE TP_ID COUNT UNITS DISCOUNT /)) {
    $EXT_TABLES  .= << "EXT_TABLES";
  LEFT JOIN fees_extra fe ON (f.id=fe.fees_id)
EXT_TABLES
  }

  if ($self->{SEARCH_FIELDS} =~ /invoice\./xm) {
    $EXT_TABLES  .= << "EXT_TABLES";
  LEFT JOIN docs_invoice_orders invoice_orders ON (f.id=invoice_orders.fees_id)
  LEFT JOIN docs_invoices invoice ON (invoice.id=invoice_orders.invoice_id)
EXT_TABLES
  }

  if ($self->{SEARCH_FIELDS} =~ /ft\./xm || $WHERE =~ /ft\./xm) {
    $EXT_TABLES .= " LEFT JOIN fees_types ft ON (ft.id=f.method)";
  }

  if($self->{SEARCH_FIELDS} =~ /u\.|pi\./xm || $WHERE =~ /u\.|pi\./xm) {
    $EXT_TABLES = 'LEFT JOIN users u ON (u.uid=f.uid) ' . $EXT_TABLES;
  }

  if($self->{SEARCH_FIELDS} =~ /a\./xm || $WHERE =~ /a\./xm) {
    $EXT_TABLES = 'LEFT JOIN admins a ON (a.aid=f.aid) ' . $EXT_TABLES;
  }

  if($self->{SEARCH_FIELDS} =~ /c\./xm || $WHERE =~ /c\./xm) {
    $EXT_TABLES  .= " LEFT JOIN companies c ON (c.id=u.company_id)";
  }

  if ($attr->{PAYMENT_ID} || $attr->{COMPENSATION}) {
    $EXT_TABLES .= " LEFT JOIN fees2payments p2f ON (p2f.fees_id=f.id) ";
    if($attr->{COMPENSATION}) {
      $EXT_TABLES .= " LEFT JOIN payments p ON (p2f.payment_id=p.id) ";
    }
  }

  my $sql = <<"SQL";
SELECT f.id,
       $self->{SEARCH_FIELDS}
   f.inner_describe,
   f.uid
FROM `$table_name` f
  $EXT_TABLES
  $WHERE
GROUP BY $GROUP_BY
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  $self->{SUM}         = '0.00';
  $self->{TOTAL_USERS} = 0;

  return [] if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  if (! $attr->{_SKIP_TOTAL} && $self->{TOTAL} > 0) {
    $sql = <<"SQL";
SELECT COUNT(*) AS total, SUM(f.sum) AS sum, COUNT(DISTINCT f.uid) AS total_users
  FROM `$table_name` f
  $EXT_TABLES
  $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 report($attr) - Fees reports

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub reports {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  my @WHERE_RULES = ();
  my %EXT_TABLE_JOINS_HASH = ();

  if ($attr->{ADMINS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADMINS}, 'STR', 'a.id') };
  }

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//x, $attr->{INTERVAL}, 2);
  }
  elsif ($attr->{MONTH}) {
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  }
  else {
    $date = "DATE_FORMAT(f.date, '%Y-%m') AS month";
  }

  my $GROUP = 1;
  my $report_type = ($attr->{TYPE}) ? $attr->{TYPE} : q{};

  if ($report_type eq 'HOURS') {
    $date = "DATE_FORMAT(f.date, '%H') AS hour";
  }
  elsif ($report_type eq 'DAYS') {
    $date = "DATE_FORMAT(f.date, '%Y-%m-%d') AS date";
  }
  elsif ($report_type eq 'METHOD') {
    $date = "f.method";
    $EXT_TABLE_JOINS_HASH{fees_types}=1;
    $attr->{TAX_SUM}='_SHOW';
  }
  elsif ($report_type eq 'ADMINS') {
    $date = "a.id AS a_login, a.name AS a_name";
    $EXT_TABLE_JOINS_HASH{admins} = 1;
  }
  elsif ($report_type eq 'PER_MONTH') {
    $date = "DATE_FORMAT(f.date, '%Y-%m') AS date";
  }
  elsif ($report_type eq 'FIO') {
    $EXT_TABLE_JOINS_HASH{users_pi} = 1;
    $date       = "pi.fio";
    $GROUP      = 5;
  }
  elsif ($report_type eq 'COMPANIES') {
    $EXT_TABLE_JOINS_HASH{companies}=1;
    $date       = "company.name AS company_name";
    $attr->{COMPANY_ID}='>0';
  }
  elsif ($report_type eq 'DISTRICT') {
    $date = "districts.name AS district_name";
    $self->{SEARCH_FIELDS} = 'districts.id AS district_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
    $EXT_TABLE_JOINS_HASH{districts}=1;
  }
  elsif ($report_type eq 'STREET') {
    $date = "streets.name AS street_name";
    $self->{SEARCH_FIELDS} = 'streets.id AS street_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
  }
  elsif ($report_type eq 'BUILD') {
    $date = "CONCAT(streets.name, '$CONF->{BUILD_DELIMITER}', builds.number) AS build";
    $self->{SEARCH_FIELDS} = 'builds.id AS location_id,';
    $EXT_TABLE_JOINS_HASH{users}=1;
    $EXT_TABLE_JOINS_HASH{users_pi}=1;
    $EXT_TABLE_JOINS_HASH{builds}=1;
    $EXT_TABLE_JOINS_HASH{streets}=1;
  }
  elsif ($report_type eq 'GID') {
    $date = "u.gid";
    $EXT_TABLE_JOINS_HASH{users}=1;
  }
  elsif($report_type eq 'LOGIN'){
    $date = "u.id AS login";
  }

  if($attr->{GID}) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  $attr->{SKIP_DEL_CHECK}=1;

  my @search_params = (
    ['BILL_ID',           'INT',  'f.bill_id',                     1 ],
    ['METHOD',            'INT',  'f.method'                         ],
    ['MONTH',             'DATE', "DATE_FORMAT(f.date, '%Y-%m')"     ],
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(f.date, '%Y-%m-%d')"  ],
    ['DATE',              'DATE', "DATE_FORMAT(f.date, '%Y-%m-%d')"  ],
    ['TAX_SUM',           'INT',  '', 'IF(ft.tax>0, (SUM(f.sum) / (100 + ft.tax) * ft.tax), 0) AS tax_sum'  ]
  );

  my $WHERE =  $self->search_former($attr, \@search_params,
    {
      WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'UID', 'LOGIN' ],
    }
  );

  if ($self->{EXT_TABLES} || $date =~ /u\.|pi\./xm || $WHERE =~ /u\.|pi\./xm) {
    $EXT_TABLE_JOINS_HASH{users}=1;
  }

  if($WHERE =~ /ft\./xm || $self->{SEARCH_FIELDS} =~ /ft\./xm){
    $EXT_TABLE_JOINS_HASH{fees_types}=1;
    $attr->{TAX_SUM}='_SHOW';
  }

  $EXT_TABLE_JOINS_HASH{users}=1 if ($self->{EXT_TABLES});
  my $EXT_TABLES = $self->mk_ext_tables({
    JOIN_TABLES     => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN  => [
      'users:INNER JOIN users u ON (u.uid=f.uid)',
      'admins:LEFT JOIN admins a ON (a.aid=f.aid)',
      'fees_types:LEFT JOIN fees_types ft ON (ft.id=f.method)'
    ]
  });

  my $sql = <<"SQL";
SELECT $date, COUNT(DISTINCT f.uid) AS login_count, COUNT(*) AS count,  SUM(f.sum) AS sum,
       $self->{SEARCH_FIELDS} f.uid
FROM fees f
  $EXT_TABLES
  $WHERE
GROUP BY $GROUP
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  $self->{SUM}   = '0.00';
  $self->{USERS} = 0;
  $sql = <<"SQL";
SELECT COUNT(DISTINCT f.uid) AS users, COUNT(*) AS total, SUM(f.sum) AS sum
FROM fees f
  $EXT_TABLES
  $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 fees_type_list($attr)

  Arguments:
    $attr
  Results:
    $list

=cut
#**********************************************************
sub fees_type_list {
  my ($self, $attr) = @_;

  delete $attr->{GROUP_BY};
  my @search_params = (
    [ 'ID',        'INT', 'id'           ],
    [ 'NAME',      'STR', 'name'         ],
    [ 'TAX',       'INT', 'tax',       1 ],
    [ 'PARENT_ID', 'INT', 'parent_id', 1 ],
    [ 'SUBCONTO',  'STR', 'subconto',  1 ]
  );

  my $WHERE =  $self->search_former($attr, \@search_params, { WHERE => 1, });

  my $sql = <<"SQL";
SELECT id,
    $self->{SEARCH_FIELDS}
    name,
    default_describe,
    sum
FROM fees_types
$WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};
  $self->query("SELECT COUNT(*) AS total FROM fees_types $WHERE ;",
    undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 fees_types_info($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fees_type_info {
  my ($self, $attr) = @_;

  $self->query("SELECT * FROM fees_types WHERE id = ? ;", undef, {
    INFO => 1,
    Bind => [ $attr->{ID} ]
  });

  return $self;
}

#**********************************************************
=head2 fees_types_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fees_type_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'fees_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 fees_type_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fees_type_add {
  my ($self, $attr) = @_;

  $self->query_add('fees_types', $attr);
  if(! $self->{errno}) {
    $admin->system_action_add("FEES_TYPES:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  }

  return $self;
}

#**********************************************************
=head2 fees_type_del($id)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fees_type_del {
  my ($self, $id) = @_;

  $self->query_del('fees_types', { ID => $id });

  $admin->system_action_add("FEES_TYPES:$id", { TYPE => 10 }) if (!$self->{errno});

  return $self;
}

#**********************************************************
=head2 fees_last_add ($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub fees_last_add {
  my ($self, $attr) = @_;

  $self->query_add('fees_last', $attr, {REPLACE => 1});

  return $self;
}

#**********************************************************
=head2 code_subconto_add () - add code subconto for fees

  Arguments:
    $attr

  Returns:
    $self

=cut
#**********************************************************
sub code_subconto_add {
  my ($self, $attr) = @_;

  $self->query_add('fees_subconto_codes', $attr);

  return $self;
}

#**********************************************************
=head2 code_subconto_info (CODE) - Show code subconto info

  Arguments:
    CODE

  Returns:
    $self

=cut
#**********************************************************
sub code_subconto_info {
  my ($self, $attr) = @_;

  my $sql = << "SQL";
    SELECT * FROM fees_subconto_codes WHERE code = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{CODE} ] });

  return $self;
}

#*******************************************************************
=head2 code_subconto_change($attr) - change code subconto

  Arguments:
   $attr

  Returns:
    $self

=cut
#*******************************************************************
sub code_subconto_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'CODE',
    TABLE        => 'fees_subconto_codes',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2  code_subconto_del(CODE) - delete code subconto

  Arguments:
    $attr

  Returns:
   $self

=cut
#*******************************************************************
sub code_subconto_del {
  my ($self, $attr) = @_;

  $self->query_del('fees_subconto_codes', undef, $attr);

  return $self;
}

#*******************************************************************

=head2  code_subconto_list($attr) - list of code subconto

  Arguments:
    $attr
      HASH_RETURN - return bics as a hash (BANK_BIC => BANK_NAME)

  Returns:
    $list or $list_hash

=cut

#*******************************************************************
sub code_subconto_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'CODE',         'STR', 'cs.code',           1 ],
    [ 'NAME',         'STR', 'cs.name',           1 ],
  ],
    { WHERE => 1 }
  );

  my $sql = << "SQL";
    SELECT *
    FROM fees_subconto_codes cs
    $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  if ($attr->{HASH_RETURN}){
    my %list_hash = ();
    foreach my $line (@$list) {
      $list_hash{$line->{code}} = $line->{name};
    }
    return \%list_hash;
  }

  $sql = << "SQL";
    SELECT COUNT(*) AS total
    FROM fees_subconto_codes
    $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}


1;
