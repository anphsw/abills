package Internet::Reports2;
=head1 NAME

  Internet Reports functions

=cut

use strict;
use parent qw( dbcore );
use Conf;

our $VERSION = 1.00;
my $MODULE = 'Internet';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

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
=head2 users_switch_list ($attr) - returns list of switches and users

  Arguments:
    $attr - hash_ref

=cut
#**********************************************************
sub users_switch_list {
  my ($self, $attr) = @_;

  my $SORT = $attr->{SORT} ? $attr->{SORT} : 1;
  my $DESC = $attr->{DESC} ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $search_columns = [
    [ 'EQUIPMENT_ID',               'INT', 'nas.id',                1 ],
    [ 'EQUIPMENT_NAME',             'STR', 'nas.name',              1 ],
    [ 'USER_ID',                    'STR', 'users.uid',             1 ],
    [ 'USER_ACTIVE',                'STR', 'internet_main.disable', 1 ],
    [ 'MESSAGES',                   'STR', 'msgs_messages.uid',     1 ],
  ];

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });
  my $sql = <<"SQL";
SELECT nas.id   AS switch_id,
       nas.name AS switch_name,
       (SELECT COUNT(uid)
        FROM internet_main
        WHERE internet_main.nas_id = nas.id
       )        AS switch_users,
       (SELECT COUNT(disable)
        FROM internet_main
        WHERE disable = 1
          AND internet_main.nas_id = nas.id
       )        AS user_off,
       (SELECT COUNT(disable)
        FROM internet_main
        WHERE disable = 0
          AND internet_main.nas_id = nas.id
       )        AS user_on,
       SUM((SELECT COUNT(id)
            FROM msgs_messages
            WHERE msgs_messages.date >= (NOW() - INTERVAL 30 DAY)
              AND msgs_messages.uid = users.uid
              AND users.uid = internet_main.uid
              AND internet_main.nas_id = nas.id
       ))       AS users_request

FROM internet_main
       LEFT JOIN nas           ON internet_main.nas_id = nas.id
       LEFT JOIN users         ON internet_main.uid = users.uid
GROUP BY switch_id
  $WHERE
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head1 users_development_growth($attr)

  Argumnets:
    $attr

  Results:
    $list

=cut
#**********************************************************
sub users_development_growth {
  my ($self, $attr) = @_;

  my $WHERE = '';

  if ($attr->{FROM_DATE} && $attr->{TO_DATE}) {
    if ($attr->{FROM_DATE} eq $attr->{TO_DATE}) {
      $WHERE .= "u.registration = '$attr->{FROM_DATE}'"
    }
    else {
      $WHERE .= "u.registration >= '$attr->{FROM_DATE}' AND u.registration < '$attr->{TO_DATE}'"
    }
  }

  my $sql = <<"SQL";
SELECT COUNT(u.uid) AS users, districts.name
FROM users u
       LEFT JOIN bills b ON (u.bill_id = b.id)
       LEFT JOIN users_pi pi ON (u.uid=pi.uid)
       LEFT JOIN builds ON (builds.id=pi.location_id)
       LEFT JOIN streets ON (streets.id=builds.street_id)
       LEFT JOIN districts ON (districts.id=streets.district_id)

WHERE $WHERE

GROUP BY districts.id
SQL

  $self->query($sql, undef, { COLS_NAME => 1 });

  return $self->{list} || [];
}

#**********************************************************
=head1 users_development_report($date, $attr)

  Arguments:
    $date
    $attr

  Results:
    $list

=cut
#**********************************************************
sub users_development_report {
  my ($self, $date, $attr) = @_;

  $attr->{GROUP_BY} = 'districts.name';
  my $GROUP_BY = !$attr->{TOTAL} ? "GROUP BY $attr->{GROUP_BY}" : '';
  my $WHERE = "WHERE ud.date = DATE_FORMAT(NOW(), '%Y-%m-%d')";
  if ($date && $date =~ '^<(.+)') {
    $WHERE = "WHERE ud.date = (SELECT date FROM users_development WHERE date $date GROUP BY date ORDER BY date DESC LIMIT 1)";
  }
  elsif ($date) {
    $WHERE = "WHERE ud.date = '$date'";
  }

  my @address_filter = ();
  if ($attr->{DISTRICT_ID}) {
    $attr->{DISTRICT_ID} =~ s/;/,/xg;
    push (@address_filter, "districts.id IN ($attr->{DISTRICT_ID})") ;
  }

  $WHERE .= " AND (" . join(' OR ', @address_filter) . ")" if (scalar(@address_filter));

  my $sql = <<"SQL";
SELECT RI.id, RI.name, RI.users_count, GROUP_CONCAT(DISTINCT dfp.name ORDER BY dfp.path SEPARATOR ' / ') AS full_name,
       RI.allowed, RI.sum_allowed, (RI.sum_allowed / RI.allowed) AS allowed_arpu,

       RI.denied, RI.sum_denied, (RI.sum_denied / RI.denied) AS denied_arpu,

       RI.outflow, RI.sum_outflow, (RI.sum_outflow / RI.outflow) AS outflow_arpu,

       RI.outflow_disable, RI.sum_outflow_disable, (RI.sum_outflow_disable / RI.outflow_disable) AS outflow_disable_arpu,

       RI.outflow_neg_deposit, RI.sum_outflow_neg_deposit, (RI.sum_outflow_neg_deposit / RI.outflow_neg_deposit)
                                                                                                         AS outflow_neg_deposit_arpu,

       RI.outflow_holdup, RI.sum_outflow_holdup, (RI.sum_outflow_holdup / RI.outflow_holdup) AS outflow_holdup_arpu,

       (RI.outflow / RI.users_count * 100) AS outflow_percent,
       (RI.outflow_disable / RI.outflow * 100) AS outflow_disable_percent,
       (RI.outflow_neg_deposit / RI.outflow * 100) AS outflow_neg_deposit_percent,
       (RI.outflow_holdup / RI.outflow * 100) AS outflow_holdup_percent,

       (RI.sum_outflow / RI.total_sum * 100) AS sum_outflow_percent,
       (RI.sum_outflow_disable / RI.sum_outflow * 100) AS sum_outflow_disable_percent,
       (RI.sum_outflow_neg_deposit / RI.sum_outflow * 100) AS sum_outflow_neg_deposit_percent,
       (RI.sum_outflow_holdup / RI.sum_outflow * 100) AS sum_outflow_holdup_percent

FROM (
       SELECT districts.id AS id, $attr->{GROUP_BY} AS name, districts.path,
        COUNT(ud.uid) AS users_count, SUM(ud.sum) AS total_sum,
          COUNT(IF(ud.disable = 0 AND b.deposit > -5, ud.id, null)) AS allowed,
          COUNT(IF(ud.disable = 0 AND b.deposit <= -5, ud.id, null)) AS denied,
          COUNT(IF(ud.disable = 1 OR ud.disable = 3 OR ud.disable = 5, ud.id, null)) AS outflow,
          COUNT(IF(ud.disable = 1, ud.id, null)) AS outflow_disable,
          COUNT(IF(ud.disable = 5, ud.id, null)) AS outflow_neg_deposit,
          COUNT(IF(ud.disable = 3, ud.id, null)) AS outflow_holdup,

          SUM(IF(ud.disable = 0 AND b.deposit > -5, ud.sum, 0)) AS sum_allowed,
          SUM(IF(ud.disable = 0 AND b.deposit <= -5, ud.sum, 0)) AS sum_denied,

          SUM(IF(ud.disable = 1 OR ud.disable = 3 OR ud.disable = 5, ud.sum, 0)) AS sum_outflow,
          SUM(IF(ud.disable = 1, ud.sum, 0)) AS sum_outflow_disable,
          SUM(IF(ud.disable = 5, ud.sum, 0)) AS sum_outflow_neg_deposit,
          SUM(IF(ud.disable = 3, ud.sum, 0)) AS sum_outflow_holdup

       FROM users_development ud
         LEFT JOIN users u ON (u.uid = ud.uid)
         LEFT JOIN bills b ON (u.bill_id = b.id)
         LEFT JOIN users_pi pi ON (u.uid=pi.uid)
         LEFT JOIN builds ON (builds.id=pi.location_id)
         LEFT JOIN streets ON (streets.id=builds.street_id)
         LEFT JOIN districts ON (districts.id=streets.district_id)

         $WHERE

         $GROUP_BY
     ) RI
       LEFT JOIN districts AS dfp ON FIND_IN_SET(dfp.id, REPLACE(IF(RI.path, RI.path, RI.id), '/', ',')) > 0
GROUP BY RI.id
ORDER BY name
SQL


  $self->query($sql, undef, { COLS_NAME => 1 });

  return $attr->{TOTAL} ? $self->{list}[0] : $self->{list} || [];
}

#**********************************************************
=head1 users_development_add($attr)

=cut
#**********************************************************
sub users_development_add {
  my ($self, $attr) = @_;

  $self->query_add('users_development', $attr);

  return $self;
}

#**********************************************************
=head2 users_outflow_report ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub users_outflow_by_address {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'GROUP BY b.id';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'UID',          'INT', 'u.uid',                                1 ],
      [ 'LOCATION_ID',  'INT', 'pi.location_id',                       1 ],
      [ 'BUILD_ID',     'INT', 'b.id', 'b.id AS build_id',             1 ],
      [ 'STREET_ID',    'INT', 's.id', 's.id AS street_id',            1 ],
      [ 'BUILD_NUMBER', 'STR', 'b.number', 'b.number AS build_number', 1 ],
      [ 'STREET_NAME',  'STR', 's.name', 's.name AS street_name',      1 ],
      [ 'USERS_COUNT',  'INT', 'COUNT(DISTINCT u.uid) AS users_count', 1 ]
    ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} b.id
FROM users u
  INNER JOIN users_pi pi ON (u.uid=pi.uid)
  LEFT JOIN builds b ON (b.id=pi.location_id)
  LEFT JOIN streets s ON (b.street_id=s.id)
  $WHERE
  $GROUP_BY
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}


#**********************************************************
=head2 users_outflow_report ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub users_outflow_report {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'i.uid';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'i.uid';

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  push @WHERE_RULES, "(t.month_fee <> 0 OR t.day_fee <> 0)";
  push @WHERE_RULES, "f.dsc LIKE 'Internet%'";
  push @WHERE_RULES, "b.deposit < 1";

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "pi.location_id = '$attr->{BUILD_ID}'";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "builds.street_id = '$attr->{STREET_ID}'";
    $EXT_TABLE = 'LEFT JOIN builds ON (builds.id=pi.location_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "streets.district_id = '$attr->{DISTRICT_ID}'";
    $EXT_TABLE = 'LEFT JOIN builds ON (builds.id=pi.location_id)';
    $EXT_TABLE .= 'LEFT JOIN streets ON (streets.id=builds.street_id)';
  }

  $attr->{TO_DATE} = $attr->{TO_DATE} ? "'$attr->{TO_DATE}'" : 'CURDATE()';
  push @WHERE_RULES, "f.date <= $attr->{TO_DATE}";

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LOGIN',    'STR', 'u.id AS login',            1 ],
      [ 'TP_NAME',  'STR', 't.name AS tp_name',        1 ],
      [ 'TP_ID',    'INT', 'i.tp_id AS tp_id',         1 ],
      # [ 'LAST_FEE', 'DATE', 'MAX(f.date) AS last_fee', 1 ],
      [ 'DEPOSIT',  'INT', 'b.deposit AS deposit',     1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} i.uid, MAX(f.date) AS last_fee
FROM internet_main i
  INNER JOIN tarif_plans t ON (t.tp_id=i.tp_id)
  LEFT JOIN users u ON (u.uid = i.uid)
  LEFT JOIN users_pi pi ON (pi.uid = u.uid)
  LEFT JOIN bills b ON (b.id = u.bill_id)
  LEFT JOIN fees f ON (f.uid=i.uid)
  $EXT_TABLE
  $WHERE
GROUP BY $GROUP_BY
HAVING COUNT(f.date)<>0 AND DATEDIFF($attr->{TO_DATE},  last_fee) > 30
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  delete $attr->{GROUP_BY};

  return $self->{list} || [];
}

#**********************************************************
=head2 report_debetors($attr)

  Arguments:
    $attr

 Results:
   $list

=cut
#**********************************************************
sub report_debetors {
  my ($self, $attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    ['UID',             'INT', 'internet.uid',                           1 ],
    ['INTERNET_STATUS', 'INT', 'internet.disable AS internet_status',    1 ],
    ['TP_NAME',         'STR', 'tp.name', 'tp.name AS tp_name' ]
  ],
    {
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    });

  my $EXT_TABLES = $self->{EXT_TABLES};
  $WHERE = " AND ". $WHERE if ($WHERE);

  if (! $attr->{PERIOD}) {
    $attr->{PERIOD} = 1;
  }

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
      u.uid
FROM users u
  INNER JOIN internet_main internet ON (u.uid=internet.uid)
  LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
  $EXT_TABLES
WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD} $WHERE
GROUP BY u.id
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $sql = <<"SQL";
SELECT COUNT(*) AS total, SUM(IF(u.company_id > 0, cb.deposit, b.deposit)) AS total_debetors_sum
FROM users u
       INNER JOIN internet_main internet ON (u.uid=internet.uid)
       LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
  $EXT_TABLES
WHERE IF(u.company_id > 0, cb.deposit, b.deposit) < 0 - tp.month_fee*$attr->{PERIOD}
  $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 report_tp($attr)

  Arguments:
    $attr

  Returns:
    $list

=cut
#**********************************************************
sub report_tp {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $SORT -= 1 if ($SORT > 1);

  $self->{EXT_TABLES}          = '';
  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;
  $attr->{DELETED}             = 0;

  my $WHERE =  $self->search_former($attr, [
    ['DOMAIN_ID',            'INT', 'tp.domain_id',  ],
  ],
    { WHERE       => 1,
      USERS_FIELDS=> 1
    }
  );

  my $sql = <<"SQL";
SELECT tp.id, tp.tp_id, tp.name, COUNT(DISTINCT internet.uid) AS counts,
       COUNT(DISTINCT CASE WHEN internet.disable=0 AND u.disable=0 THEN internet.uid ELSE NULL END) AS active,
       COUNT(DISTINCT CASE WHEN internet.disable!=0 OR u.disable!=0 THEN internet.uid ELSE NULL END) AS disabled,
       SUM(IF(IF(u.company_id > 0, cb.deposit, b.deposit) < 0, 1, 0)) AS debetors,
       SUM(IF(u.reduction = 100, 1, 0)) AS users_reduction,
       ROUND(SUM(p.sum) / COUNT(DISTINCT internet.uid), 2) AS arpu,
       ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
       tp.month_fee AS month_fee,
       tp.day_fee AS day_fee,
       tg.name AS group_name
FROM users u
       INNER JOIN internet_main internet ON (u.uid=internet.uid)
       LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
       LEFT JOIN bills b ON (u.bill_id = b.id)
       LEFT JOIN companies company ON  (u.company_id=company.id)
       LEFT JOIN bills cb ON  (company.bill_id=cb.id)
       LEFT JOIN payments p ON (p.uid=internet.uid
  AND (p.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00')) )
       LEFT JOIN tp_groups tg ON (tp.gid=tg.id)
  $WHERE
GROUP BY tp.tp_id
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return [ ] if ($self->{errno});

  return $self->{list};
}


#**********************************************************
=head2 report_user_statuses($attr) - Get sum deposits, users count for statuses

  Arguments:
    $attr
      STATUS

  Returns:
    $self->{list}->[0]
=cut
#**********************************************************
sub report_user_statuses {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
SELECT COUNT(i.uid) AS COUNT,SUM(i.deposit) AS deposit,i.disable AS status
FROM (SELECT DISTINCT inter.uid, IF(u.company_id = 0, b.deposit, cb.deposit) AS deposit, inter.disable
      FROM internet_main AS inter
             INNER JOIN users u ON (u.uid=inter.uid)
             LEFT JOIN companies company ON (u.company_id=company.id)
             LEFT JOIN bills b ON (u.bill_id = b.id)
             LEFT JOIN bills cb ON (company.bill_id=cb.id)
     ) AS i
WHERE i.disable= ?
GROUP BY status;
SQL

  $self->query($sql, undef,
    { INFO => 1, Bind => [ $attr->{STATUS} ]  }
  );

  return $self;
}

1;