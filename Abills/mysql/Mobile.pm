package Mobile;

=head1 NAME

 Mobile

=cut

use strict;
use parent 'dbcore';

our $VERSION = 0.01;

my $MODULE = 'Mobile';
my ($db, $admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    MODULE => $MODULE
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 category_add() - add mobile categories

=cut
#**********************************************************
sub category_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('mobile_categories', $attr);

  return $self;
}

#**********************************************************
=head2 category_list() - get mobile categories list

=cut
#**********************************************************
sub category_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT',   'mc.id',            1 ],
    [ 'NAME',          'STR',   'mc.name',          1 ],
    [ 'DESCRIPTION',   'STR',   'mc.description',   1 ],
    [ 'MANDATORY',     'INT',   'mc.mandatory',     1 ],
    [ 'MAIN_CATEGORY', 'INT',   'mc.main_category', 1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} mc.id
      FROM mobile_categories mc
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM mobile_categories mc
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 category_del() - delete mobile category

=cut
#**********************************************************
sub category_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('mobile_categories', $attr);

  return $self;
}

#**********************************************************
=head2 category_info() - get information about mobile category

=cut
#**********************************************************
sub category_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM mobile_categories WHERE id = ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 category_change() - change section information in database

=cut
#**********************************************************
sub category_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{MANDATORY} //= 0;
  $attr->{MAIN_CATEGORY} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'mobile_categories',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 service_add() - add mobile service

=cut
#**********************************************************
sub service_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('mobile_services', $attr);

  return $self;
}

#**********************************************************
=head2 service_list() - get mobile services list

=cut
#**********************************************************
sub service_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',               'INT',   'ms.id',                              1 ],
    [ 'NAME',             'STR',   'ms.name',                            1 ],
    [ 'DESCRIPTION',      'STR',   'ms.description',                     1 ],
    [ 'MANDATORY',        'INT',   'ms.mandatory',                       1 ],
    [ 'CATEGORY_ID',      'INT',   'ms.category_id',                     1 ],
    [ 'CATEGORY_NAME',    'STR',   'mc.name', 'mc.name AS category_name'   ],
    [ 'PAYMENT_TYPE',     'INT',   'ms.payment_type',                    1 ],
    [ 'USER_DESCRIPTION', 'STR',   'ms.user_description',                1 ],
    [ 'PRICE',            'INT',   'ms.price',                           1 ],
    [ 'PERIOD',           'INT',   'ms.period',                          1 ],
    [ 'FILTER_ID',        'STR',   'ms.filter_id',                       1 ],
    [ 'PRIORITY',         'INT',   'ms.priority',                        1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} ms.id
      FROM mobile_services ms
      LEFT JOIN mobile_categories mc ON (mc.id = ms.category_id)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM mobile_services ms
    LEFT JOIN mobile_categories mc ON (mc.id = ms.category_id)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 service_del() - delete mobile service

=cut
#**********************************************************
sub service_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('mobile_services', $attr);

  return $self;
}

#**********************************************************
=head2 service_info() - get information about mobile service

=cut
#**********************************************************
sub service_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM mobile_services WHERE id = ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 service_change() - change section information in database

=cut
#**********************************************************
sub service_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{MANDATORY} //= 0;
  $attr->{PAYMENT_TYPE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'mobile_services',
    DATA         => $attr
  });

  return $self;
}

sub tp_services_add {
  my $self = shift;
  my ($attr) = @_;

  $self->tp_services_del({ TP_ID => $attr->{TP_ID }});

  my @ids = split(/;\s?/, $attr->{SERVICE_ID});
  my $tp_id = $attr->{TP_ID};

  my @MULTI_QUERY = ();
  map push(@MULTI_QUERY, [ $tp_id, $_ ]), @ids;

  $self->query("INSERT INTO mobile_tariff_services(tp_id, service_id) VALUES (?, ?);", undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}

sub tp_services_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('mobile_tariff_services', {}, { TP_ID => $attr->{TP_ID} });

  return $self;
}

#**********************************************************
=head2 tariff_add()

=cut
#**********************************************************
# sub tariff_add {
#   my $self = shift;
#   my ($attr) = @_;
#
#   $self->query_add('mobile_tariffs', $attr);
#   return $self if $self->{errno} || !$self->{INSERT_ID};
#
#   my $tp_id = $self->{INSERT_ID};
#   if ($attr->{SERVICE_ID}) {
#     my @ids = split(/;\s?/, $attr->{SERVICE_ID});
#
#     my @MULTI_QUERY = ();
#     map push(@MULTI_QUERY, [ $tp_id, $_ ]), @ids;
#
#     $self->query("INSERT INTO mobile_tariff_services(tp_id, service_id) VALUES (?, ?);", undef,
#       { MULTI_QUERY => \@MULTI_QUERY }
#     );
#   }
#   $self->{INSERT_ID} = $tp_id;
#
#   return $self;
# }

#**********************************************************
=head2 tariff_list()

=cut
#**********************************************************
sub tariff_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = $attr->{GROUP_BY} ? "GROUP BY $attr->{GROUP_BY}" : 'GROUP BY tp.tp_id';
  my @WHERE_RULES = ("tp.module='$MODULE'");

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT', 'tp.id',                                               1 ],
    [ 'NAME',          'STR', 'tp.name',                                             1 ],
    [ 'COMMENTS',      'STR', 'tp.comments',                                         1 ],
    [ 'COMMENTS',      'STR', 'tp.comments',                                         1 ],
    [ 'DESCRIBE_AID',  'STR', 'tp.describe_aid',                                     1 ],
    [ 'MONTH_FEE',     'INT', 'tp.month_fee',                                        1 ],
    [ 'FEES_METHOD',   'INT', 'tp.fees_method',                                      1 ],
    [ 'PAYMENT_TYPE',  'INT', 'tp.payment_type',                                     1 ],
    [ 'REDUCTION_FEE', 'INT', 'tp.reduction_fee',                                    1 ],
    [ 'TOTAL_SUM',     'INT', 'SUM(ms.price) AS total_sum',                          1 ],
    [ 'SERVICE_ID',    'STR', 'GROUP_CONCAT(DISTINCT mts.service_id) AS service_id', 1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} tp.tp_id AS id
      FROM tarif_plans tp
      LEFT JOIN mobile_tariff_services mts ON (mts.tp_id = tp.tp_id)
      LEFT JOIN mobile_services ms ON (mts.service_id = ms.id)
      $WHERE
      $GROUP_BY
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM tarif_plans tp
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 tariff_del()

=cut
#**********************************************************
# sub tariff_del {
#   my $self = shift;
#   my ($attr) = @_;
#
#   $self->query_del('mobile_tariffs', $attr);
#   return $self if $self->{errno};
#
#   $self->query_del('mobile_tariff_services', {}, { TP_ID => $attr->{ID} });
#
#   return $self;
# }

#**********************************************************
=head2 tariff_info()

=cut
#**********************************************************
sub tariff_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT tp.*, GROUP_CONCAT(DISTINCT tps.service_id) AS service_id, tp.tp_id AS id
    FROM tarif_plans tp
    LEFT JOIN mobile_tariff_services tps ON (tps.tp_id = tp.tp_id)
    WHERE tp.tp_id = ? AND tp.module = '$MODULE'
    GROUP BY tp.tp_id;",
    undef, {
    INFO => 1,
    Bind => [ $attr->{ID} ]
  });

  return $self;
}

# #**********************************************************
# =head2 tariff_change()
#
# =cut
# #**********************************************************
# sub tariff_change {
#   my $self = shift;
#   my ($attr) = @_;
#
#   $self->changes({
#     CHANGE_PARAM => 'ID',
#     TABLE        => 'mobile_tariffs',
#     DATA         => $attr
#   });
#
#   if ($attr->{SERVICE_ID}) {
#     $self->query_del('mobile_tariff_services', {}, { TP_ID => $attr->{ID} });
#     my @ids = split(/;\s?/, $attr->{SERVICE_ID});
#
#     my @MULTI_QUERY = ();
#     map push(@MULTI_QUERY, [ $attr->{ID}, $_ ]), @ids;
#
#     $self->query("INSERT INTO mobile_tariff_services(tp_id, service_id) VALUES (?, ?);", undef,
#       { MULTI_QUERY => \@MULTI_QUERY }
#     );
#   }
#
#   return $self;
# }


#**********************************************************
=head2 user_add()

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('mobile_main', $attr);

  $admin->{MODULE} = $MODULE;

  my @info = ('PHONE', 'ID');
  my @actions_history = ();

  foreach my $param (@info) {
    next if !defined($attr->{$param});
    push @actions_history, join(':', ($param, $attr->{$param}));
  }
  $self->{ID} = $self->{INSERT_ID};

  $admin->action_add($attr->{UID}, "ID: $self->{INSERT_ID} ".  join(', ', @actions_history), { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 user_list()

=cut
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'mm.id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{USERS_ACTIVE_SINCE_30_DAYS_AGO}) {
    push @WHERE_RULES, "DATEDIFF('$attr->{USERS_ACTIVE_SINCE_30_DAYS_AGO}', mm.tp_activate) >= 30";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID',                         'INT',   'mm.id',                                                            1 ],
    [ 'UID',                        'INT',   'mm.uid',                                                            1 ],
    [ 'PHONE',                      'STR',   'mm.phone',                                                         1 ],
    [ 'TRANSACTION_ID',             'STR',   'mm.transaction_id',                                                1 ],
    [ 'DISABLE',                    'INT',   'mm.disable',                                                       1 ],
    [ 'TP_ID',                      'INT',   'mm.tp_id',                                                         1 ],
    [ 'DATE',                       'DATE',  'mm.date',                                                          1 ],
    [ 'TP_NAME',                    'STR',   'tp.name AS tp_name',                                               1 ],
    [ 'EXTERNAL_METHOD',            'STR',   'mm.external_method',                                               1 ],
    [ 'TP_DISABLE',                 'INT',   'mm.tp_disable',                                                    1 ],
    [ 'SERVICE_STATUS',             'INT',   'mm.tp_disable AS service_status',                                  1 ],
    [ 'TP_ACTIVATE',                'DATE',  'mm.tp_activate',                                                   1 ],
    [ 'MONTH_FEE',                  'INT',   'tp.month_fee',                                                     1 ],
    [ 'PAYMENT_TYPE',               'INT',   'tp.payment_type',                                                  1 ],
    [ 'REDUCTION_FEE',              'INT',   'tp.reduction_fee',                                                 1 ],
    [ 'DESCRIPTION',                'STR',   'mm.description',                                                   1 ],
    [ 'COMMENTS',                   'STR',   'mm.comments',                                                      1 ],
    [ 'DAYS_SINCE_LAST_ACTIVATION', 'INT',   'DATEDIFF(NOW(), mm.tp_activate) AS days_since_last_activation',      ],
  ], {
    WHERE             => 1,
    WHERE_RULES       => \@WHERE_RULES,
    USE_USER_PI       => 1,
    USERS_FIELDS_PRE  => 1,
    SKIP_USERS_FIELDS => [ 'UID', 'ACTIVE', 'EXPIRE', 'PHONE' ]
  });

  my $EXT_TABLES = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} mm.id
      FROM mobile_main mm
      LEFT JOIN users u ON (mm.uid=u.uid)
      LEFT JOIN tarif_plans tp ON (tp.tp_id = mm.tp_id)
      $EXT_TABLES
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total, COUNT(CASE WHEN mm.disable <> 0 THEN 1 END) AS disabled_count
    FROM mobile_main mm
    LEFT JOIN users u ON (mm.uid=u.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id = mm.tp_id)
    $EXT_TABLES
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 user_del()

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('mobile_main', $attr);

  my @del_descr = ();
  if($attr->{UID}) {
    push @del_descr, "UID: $attr->{UID}";
  }
  if ($attr->{ID}) {
    push @del_descr, "ID: $attr->{ID}";
  }
  if($attr->{COMMENTS}) {
    push @del_descr, "COMMENTS: $attr->{COMMENTS}";
  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, join(' ', @del_descr), { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 user_info()

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query(
    "SELECT
   tp.name AS tp_name,
   service.disable AS status,
   service.tp_disable AS tp_status,
   service.tp_disable AS service_status,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.month_fee AS month_abon,
   tp.abon_distribution,
   tp.day_fee,
   tp.day_fee AS day_abon,
   tp.activate_price,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id AS tp_num,
   tp.filter_id AS tp_filter_id,
   tp.credit AS tp_credit,
   tp.age AS tp_age,
   tp.activate_price AS tp_activate_price,
   tp.change_price AS tp_change_price,
   tp.period_alignment AS tp_period_alignment,
   tp.reduction_fee AS reduction_fee,
   tp.fees_method as fees_method,
   tp.describe_aid as describe_aid,
   tp.comments as comments,
   service.*,
   service.activate AS phone_activate,
   service.tp_activate AS activate
     FROM mobile_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
   WHERE service.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 user_change() - change section information in database

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  # $attr->{MANDATORY} //= 0;
  # $attr->{PAYMENT_TYPE} //= 0;

  $self->user_info($attr->{ID});

  $admin->{MODULE} = $MODULE;
  $attr->{UID} ||= $self->{UID};
  $attr->{TP_DISABLE} = defined $attr->{TP_DISABLE} ? $attr->{TP_DISABLE} : $attr->{TP_STATUS};
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'mobile_main',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 log_add($attr) - add data to the mobile_log table;

  Arguments:

  attr
    UID               - user identifier;
    TRANSACTION_ID    - unique identifier for the transaction;
    EXTERNAL_METHOD   - name of the external method used in the request;
    USER_SUBSCRIBE_ID - identifier of the user's subscription;
    RESPONSE          - response data received from the external service;
    CALLBACK_DATE     - date and time when the callback was received;
    CALLBACK          - callback data from the external service;

  Returns:
    self object;

  Examples:
    $Mobile->log_add(
          {
            UID               => 1,
            TRANSACTION_ID    => 'txn_123456789',
            EXTERNAL_METHOD   => 'subscribeUser',
            USER_SUBSCRIBE_ID => 101,
            RESPONSE          => "{ "status": "success", "message": "Subscription active" }",
            CALLBACK_DATE     => '2024-10-01 14:00:00',
            CALLBACK          => "{ "status": "notified" }",
          }
      );
=cut
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('mobile_log', $attr);

  return $self;
}

#**********************************************************
=head2 log_change()

=cut
#**********************************************************
sub log_change {
  my $self = shift;
  my ($attr) = @_;

  my $change_param = $attr->{CHANGE_BY_TRANSACTION_ID} ? 'TRANSACTION_ID' : 'ID';

  $self->changes({
    CHANGE_PARAM => $change_param,
    TABLE        => 'mobile_log',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 log_list($attr

  Arguments:

  attr
    SORT            - sort column;
    DESC            - DESC / ASC;
    PG              - page id;
    PAGE_ROWS       - count of raws returned
  Returns:
    list of raws;

=cut
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  my $WHERE = $self->search_former($attr, [
    [ 'ID',                'INT',    'ml.id',              1 ],
    [ 'UID',               'INT',    'ml.uid',             1 ],
    [ 'TRANSACTION_ID',    'STR',    'ml.transaction_id',  1 ],
    [ 'DATE',              'DATE',   'ml.date',            1 ],
    [ 'RESPONSE',          'STR',    'ml.response',        1 ],
    [ 'CALLBACK',          'STR',    'ml.callback',        1 ],
    [ 'CALLBACK_DATE',     'DATE',   'ml.callback_date',   1 ],
    [ 'EXTERNAL_METHOD',   'STR',    'ml.external_method', 1 ],
    [ 'USER_SUBSCRIBE_ID', 'INT',    'ml.user_subscribe_id', 1 ],
    [ 'TIME_SINCE_EVENT',  'INT',    'TIMESTAMPDIFF(SECOND, ml.date, NOW()) AS time_since_event', 1 ],
  ], { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  $self->query("
    SELECT
      $self->{SEARCH_FIELDS}
      ml.id
    FROM mobile_log ml
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,{ %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1
    }
  );

  my $list = $self->{list} || [];

  return [] if ($self->{errno} || $self->{TOTAL} < 1);

  $self->query("SELECT COUNT(ml.id) AS total
   FROM mobile_log ml
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 mobile_tp_report() - report of tariff plans

=cut
#**********************************************************
sub mobile_tp_report {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $SORT -= 1 if ($SORT > 1);

  $self->{EXT_TABLES}          = '';
  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;
  $attr->{DELETED}             = 0;

  my $WHERE = $self->search_former($attr, [
    [ 'DOMAIN_ID', 'INT', 'tp.domain_id', ],
  ], { WHERE => 1, USERS_FIELDS => 1 });

  $self->query("SELECT tp.id, tp.tp_id, tp.name, COUNT(DISTINCT mm.uid) AS counts,
      COUNT(DISTINCT CASE WHEN mm.tp_disable=0 AND u.disable=0 THEN mm.uid ELSE NULL END) AS active,
      COUNT(DISTINCT CASE WHEN mm.tp_disable!=0 OR u.disable!=0 THEN mm.uid ELSE NULL END) AS disabled,
      COUNT(DISTINCT CASE WHEN IF(u.company_id > 0, cb.deposit, b.deposit) < 0 THEN mm.uid ELSE NULL END) AS debetors,
      COUNT(DISTINCT CASE WHEN u.reduction = 100 THEN mm.uid ELSE NULL END) AS users_reduction,
      ROUND(SUM(p.sum) / COUNT(DISTINCT mm.id), 2) AS arpu,
      ROUND(SUM(p.sum) / COUNT(DISTINCT p.uid), 2) AS arppu,
      tp.month_fee AS month_fee,
      tp.day_fee AS day_fee
		FROM mobile_main mm
    LEFT JOIN users u ON mm.uid = u.uid
		LEFT JOIN tarif_plans tp ON (tp.tp_id = mm.tp_id)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    LEFT JOIN companies company ON  (u.company_id=company.id)
    LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    LEFT JOIN payments p ON (p.uid=mm.uid
      AND (p.date >= DATE_FORMAT(CURDATE(), '%Y-%m-01 00:00:00')) )
    $WHERE
    GROUP BY tp.tp_id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

1;
