package Sms;
=head1 NAME

  Sms  managment functions

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(dbcore);

my $MODULE = 'Sms';
my ($admin, $CONF);

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

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 info($attr) - Sms status info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM sms_log
   WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]}
  );

  return $self;
}

#**********************************************************
=head2 add($attr) - Add sms log records

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sms_log', { %$attr });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'sms_log',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 del(attr) - Del log record

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sms_log',$attr);

  return $self;
}

#**********************************************************
=head2 list($attr) - Sms log list

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  my $skip_fields = 'UID';
  if ($attr->{NO_SKIP}) {
    $skip_fields = '';
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',         'DATE','sms.datetime',               1 ],
      ['SMS_STATUS',       'INT', 'sms.status as sms_status',   1 ],
      ['SMS_PHONE',        'STR', 'sms.phone as sms_phone',     1 ],
      ['MESSAGE',          'STR', 'sms.message',                1 ],
      ['EXT_ID',           'STR', 'sms.ext_id',                 1 ],
      ['EXT_STATUS',       'STR', 'sms.ext_status',             1 ],
      ['STATUS_DATE',      'DATE','sms.status_date',            1 ],
      ['FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(sms.datetime, '%Y-%m-%d')"],
      ['ID',               'INT', 'sms.id'                       ],
      ['UID',              'INT', 'u.uid'                        ],
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ $skip_fields ]
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES};

  $self->query("SELECT
      $self->{SEARCH_FIELDS}
      sms.uid,
      sms.id,
      sms.ext_id
     FROM sms_log sms
     LEFT JOIN users u ON (u.uid=sms.uid)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count( DISTINCT sms.id) AS total FROM sms_log sms
    LEFT JOIN users u ON (u.uid=sms.uid)
    $EXT_TABLE
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 service_info($attr) - Sms service info

=cut
#**********************************************************
sub service_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM sms_services WHERE id = ?;",
    undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  if ($self->{TOTAL} && $self->{TOTAL} > 0) {
    $self->{SERVICE_PARAMS} = $self->service_params({ SERVICE_ID => $attr->{ID}, COLS_NAME => 1, COLS_UPPER => 1 });
  }
  
  return $self;
}


#**********************************************************
=head2 service_add($attr) - Add sms service

=cut
#**********************************************************
sub service_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sms_services', { %$attr });

  return $self;
}

#**********************************************************
=head2 service_change($attr) - Change sms service

=cut
#**********************************************************
sub service_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATUS} //= 0;
  $attr->{BY_DEFAULT} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'sms_services',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 service_del(attr) - Del sms service

=cut
#**********************************************************
sub service_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sms_services', $attr);

  return $self;
}

#**********************************************************
=head2 service_params_change($attr)

=cut
#**********************************************************
sub service_params_change {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{SERVICE_ID} || !$attr->{PARAMS} || ref($attr->{PARAMS}) ne 'ARRAY';

  $self->query_del('sms_service_params', undef, { SERVICE_ID => $attr->{SERVICE_ID} });

  $self->query("INSERT INTO sms_service_params(service_id, param, value) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => $attr->{PARAMS} });

  return $self;
}

#**********************************************************
=head2 service_params($attr) - Sms service params

=cut
#**********************************************************
sub service_params {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM sms_service_params WHERE service_id = ?;",
    undef, { %{$attr}, Bind => [ $attr->{SERVICE_ID} ] });

  return $self->{list} || [];
}

#**********************************************************
=head2 service_list($attr) - Sms services list

=cut
#**********************************************************
sub service_list {
  my $self   = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
    [ 'ID',         'INT', 'smss.id',         1 ],
    [ 'NAME',       'STR', 'smss.name',       1 ],
    [ 'PLUGIN',     'STR', 'smss.plugin',     1 ],
    [ 'STATUS',     'INT', 'smss.status',     1 ],
    [ 'BY_DEFAULT', 'INT', 'smss.by_default', 1 ],
    [ 'COMMENT',    'STR', 'smss.comment',    1 ],
    [ 'DEBUG',      'INT', 'smss.debug',      1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} smss.id
     FROM sms_services smss
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count(DISTINCT smss.id) AS total FROM sms_services smss $WHERE",
      undef, { INFO => 1 });
  }

  if($attr->{HASH}) {
    my %service_hash = ();
    foreach my $service (@{$list}) {
      $service_hash{$service->{id}} = $service;
    }
    return \%service_hash;
  }

  return $list;
}

1;
