package Fees;

=head1 NAME

  Finance (fees) module DB frontend

=cut

use strict;
use parent qw(main Finance);
use Bills;

my $Bill;
my ($admin, $CONF);

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
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  $Bill = Bills->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 take($user, $sum, $attr) - Take sum from bill account

=cut
#**********************************************************
sub take {
  my $self = shift;
  my ($user, $sum, $attr) = @_;

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

  $attr->{UID}     = $user->{UID};
  $attr->{BILL_ID} = $user->{BILL_ID};
  $attr->{DATE}    = ($attr->{DATE}) ? $attr->{DATE} : 'NOW()';
  $attr->{DSC}     = $attr->{DESCRIBE} || '';
  $attr->{IP}      = $admin->{SESSION_IP};
  $attr->{AID}     = $admin->{AID};
  $attr->{VAT}     = $user->{COMPANY_VAT};

  $sum = sprintf("%.4f", $sum);
  $self->{db}{db}->{AutoCommit} = 0;
  if ($attr->{BILL_ID}) {
    $user->{BILL_ID} = $attr->{BILL_ID};
  }
  elsif ($CONF->{FEES_PRIORITY}) {
    if ($CONF->{FEES_PRIORITY} =~ /^bonus/ && $user->{EXT_BILL_ID}) {
      if ($user->{EXT_BILL_ID} && !defined($self->{EXT_BILL_DEPOSIT})) {
        $user->info($user->{UID});
      }

      if ($CONF->{FEES_PRIORITY} =~ /main/ && $user->{EXT_BILL_DEPOSIT} < $sum) {
        if ($user->{EXT_BILL_DEPOSIT} > 0) {
          $Bill->action('take', $user->{EXT_BILL_ID}, $user->{EXT_BILL_DEPOSIT});
          if ($Bill->{errno}) {
            $self->{errno}  = $Bill->{errno};
            $self->{errstr} = $Bill->{errstr};
            return $self;
          }

          $self->{SUM} = $self->{EXT_BILL_DEPOSIT};

          $self->query_add('fees', {
            %$attr,
            SUM          => $self->{SUM},
            LAST_DEPOSIT => $Bill->{DEPOSIT},
          });

          $sum = $sum - $user->{EXT_BILL_DEPOSIT};
        }
      }
      else {
        $user->{BILL_ID} = $user->{EXT_BILL_ID};
      }
    }
    elsif ($CONF->{FEES_PRIORITY} =~ /^main,bonus/) {
      if (! $user->{EXT_BILL_ID} || ! defined($self->{EXT_BILL_DEPOSIT})) {
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
            SUM          => $self->{SUM},
            LAST_DEPOSIT => $Bill->{DEPOSIT},
          });

          $sum = $sum - $self->{SUM};
        }
        $user->{BILL_ID} = $user->{EXT_BILL_ID};
      }
    }

    if ($sum == 0) {
      if (!$attr->{NO_AUTOCOMMIT} && ! $self->{db}->{TRANSACTION}) {
        $self->{db}{db}->{AutoCommit} = 1;
      }
      return $self;
    }
  }

  if ($user->{BILL_ID} && $user->{BILL_ID} > 0) {
    $Bill->info({ BILL_ID => $user->{BILL_ID} });

#    if ($user->{COMPANY_VAT}) {
#      $sum = $sum * ((100 + $user->{COMPANY_VAT}) / 100);
#    }
#    else {
#      $user->{COMPANY_VAT} = 0;
#    }
    $Bill->action('take', $user->{BILL_ID}, $sum);
    if ($Bill->{errno}) {
      $self->{errno}  = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }

    $self->{SUM} = $sum;
    $self->query_add('fees', {
      %$attr,
      SUM          => $self->{SUM},
      LAST_DEPOSIT => $Bill->{DEPOSIT},
    });

    if ($self->{errno}) {
      $self->{db}{db}->rollback();
      return $self;
    }
    else {
      $self->{db}{db}->commit() if(! $self->{db}->{TRANSACTION});
    }
  }
  else {
    $self->{errno}  = 14;
    $self->{errstr} = 'No Bill';
  }

  if (! $self->{db}->{TRANSACTION} && !$attr->{NO_AUTOCOMMIT} && !$attr->{TRANSACTION}) {
    $self->{db}{db}->{AutoCommit} = 1 ;
  }

  return $self;
}

#**********************************************************
=head2 del($user, $id, $attr)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id, $attr) = @_;

  $self->query2("SELECT sum, bill_id from fees WHERE id= ? ;", undef, { Bind => [ $id ] });

  if ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }
  elsif ($self->{errno}) {
    return $self;
  }

  my ($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('add', $bill_id, $sum);

  $self->query_del('fees', { ID => $id });

   my $comments = ($attr->{COMMENTS}) ? $attr->{COMMENTS} : '';

  $admin->action_add($user->{UID}, "$id $sum $comments", { TYPE => 17 });

  return $self->{result};
}

#**********************************************************
=head2  list($attr) - Fees list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',             'INT', 'f.id',                              ],
      ['DATETIME',       'DATE','f.date',        'f.date AS datetime'],
      ['LOGIN',          'STR', 'u.id AS login',                   1 ],
      ['FIO',            'STR', 'pi.fio',                          1 ],
      ['DESCRIBE',       'STR', 'f.dsc',                           1 ],
      ['DSC',            'STR', 'f.dsc',                           1 ],
      ['SUM',            'INT', 'f.sum',                           1 ],
      ['LAST_DEPOSIT',   'INT', 'f.last_deposit',                  1 ],
      ['METHOD',         'INT', 'f.method',                        1 ],
      ['COMPANY_ID',     'INT', 'u.company_id',                      ],
      ['A_LOGIN',        'STR', 'a.id',                            1 ],
      ['ADMIN_NAME',     'STR', "if(a.name is NULL, 'Unknown', a.name) AS admin_name", 1 ],
      ['BILL_ID',        'INT', 'f.bill_id',                       1 ],
      ['IP',             'INT', 'f.ip',      'INET_NTOA(f.ip) AS ip' ],
      ['AID',            'INT', 'f.aid',                             ],
      ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
      ['UID',            'INT', 'f.uid',                           1 ],
      ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                 ],
      ['DATE',           'DATE','date_format(f.date, \'%Y-%m-%d\')'  ],
      ['FROM_DATE|TO_DATE','DATE', 'date_format(f.date, \'%Y-%m-%d\')'  ],
      ['MONTH',          'DATE', "date_format(f.date, '%Y-%m')"   ],
    ],
    { WHERE       => 1,
      USERS_FIELDS=> 1,
      SKIP_USERS_FIELDS=> [ 'BILL_ID', 'UID', 'LOGIN' ],
      USE_USER_PI => 1
    }
    );

  my $EXT_TABLES  = $self->{EXT_TABLES};

  $self->query2("SELECT f.id,
     $self->{SEARCH_FIELDS}
   f.inner_describe,
   f.uid
    FROM fees f
    LEFT JOIN users u ON (u.uid=f.uid)
    LEFT JOIN admins a ON (a.aid=f.aid)
    $EXT_TABLES
    $WHERE 
    GROUP BY f.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM}         = '0.00';
  $self->{TOTAL_USERS} = 0;

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(*) AS total, sum(f.sum) AS sum, count(DISTINCT f.uid) AS total_users FROM fees f 
  LEFT JOIN users u ON (u.uid=f.uid) 
  LEFT JOIN admins a ON (a.aid=f.aid)
  $EXT_TABLES
  $WHERE",
  undef,
  { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 report()

=cut
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $PG   = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $date = '';
  my @WHERE_RULES = ();

  if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid IN ( $attr->{GID} )";
  }

  if ($attr->{BILL_ID}) {
    push @WHERE_RULES, "f.bill_id IN ( $attr->{BILL_ID} )";
  }

  if ($attr->{ADMINS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADMINS}, 'STR', 'a.id') };
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, @{ $self->search_expr(">=$from", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') }, @{ $self->search_expr("<=$to", 'DATE', 'date_format(f.date, \'%Y-%m-%d\')') };
  }
  elsif (defined($attr->{MONTH})) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(f.date, '%Y-%m-%d') AS date";
  }
  else {
    $date = "date_format(f.date, '%Y-%m') AS month";
  }

  my $GROUP = 1;
  $attr->{TYPE} = '' if (!$attr->{TYPE});
  my $EXT_TABLES = '';

  if ($attr->{TYPE} eq 'HOURS') {
    $date = "date_format(f.date, '%H') AS hour";
  }
  elsif ($attr->{TYPE} eq 'DAYS') {
    $date = "date_format(f.date, '%Y-%m-%d') AS date";
  }
  elsif ($attr->{TYPE} eq 'METHOD') {
    $date = "f.method";
  }
  elsif ($attr->{TYPE} eq 'ADMINS') {
    $date = "a.id AS admin_login";
  }
  elsif ($attr->{TYPE} eq 'PER_MONTH') {
    $date = "date_format(f.date, '%Y-%m') AS date";
  }
  elsif ($attr->{TYPE} eq 'FIO') {
    $EXT_TABLES = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
    $date       = "pi.fio";
    $GROUP      = 5;
  }
  elsif ($attr->{TYPE} eq 'COMPANIES') {
    $EXT_TABLES = 'LEFT JOIN companies c ON (u.company_id=c.id)';
    $date       = "c.name AS company_name";
  }
  elsif ($date eq '') {
    $date = "u.id AS login";
  }

  if (defined($attr->{METHODS}) and $attr->{METHODS} ne '') {
    push @WHERE_RULES, "f.method IN ($attr->{METHODS}) ";
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
    $EXT_TABLES = "INNER JOIN users u ON (u.uid=f.uid) ". $EXT_TABLES;
  }
  else {
    $EXT_TABLES = "LEFT JOIN users u ON (u.uid=f.uid) ". $EXT_TABLES;
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT $date, count(DISTINCT f.uid) AS login_count, count(*) AS count,  sum(f.sum) AS sum, f.uid, u.company_id 
      FROM fees f
      LEFT JOIN admins a ON (f.aid=a.aid)
      $EXT_TABLES
      $WHERE 
      GROUP BY $GROUP
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->{SUM}   = '0.00';
  $self->{USERS} = 0;
  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(DISTINCT f.uid) AS users, count(*) AS total, sum(f.sum) AS sum 
      FROM fees f
      LEFT JOIN admins a ON (f.aid=a.aid)
      $EXT_TABLES
      $WHERE;",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 fees_type_list($attr)

=cut
#**********************************************************
sub fees_type_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['ID',           'INT', 'id'      ],
      ['NAME',         'STR', 'name'    ],
    ],
  { WHERE => 1, });

  $self->query2("SELECT id, name, default_describe, sum FROM fees_types
  $WHERE 
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};
  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM fees_types $WHERE ;",
    undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 fees_types_info($attr)

=cut
#**********************************************************
sub fees_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT id, name, default_describe, sum FROM fees_types WHERE id = ? ;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
# fees_types_change()
#**********************************************************
sub fees_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'fees_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 fees_type_add()

=cut
#**********************************************************
sub fees_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('fees_types', $attr);

  $admin->system_action_add("FEES_TYPES:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (!$self->{errno});
  return $self;
}

#**********************************************************
=head2 fees_type_del()

=cut
#**********************************************************
sub fees_type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('fees_types', { ID => $id });

  $admin->system_action_add("FEES_TYPES:$id", { TYPE => 10 }) if (!$self->{errno});
  return $self;
}

1
