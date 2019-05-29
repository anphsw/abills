package Cams;

=name2

  Cams

=VERSION

  VERSION = 0.01

=cut

use strict;
use warnings FATAL => 'all';

use parent qw(dbcore main);

use Tariffs;
my $Tariffs;

my ($SORT, $DESC, $PG, $PAGE_ROWS);
my ($db, $admin, $CONF);

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut

#**********************************************************
sub new {
  my $class = shift;

  ($db, $admin, $CONF) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    MODULE => 'Cams'
  };

  $Tariffs = Tariffs->new($self->{db}, $CONF, $admin);

  bless($self, $class);

  return $self;
}

#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : '';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $search_columns = [
    [ 'UID', 'INT', 'cm.uid', 1 ],
    [ 'LOGIN', 'STR', 'u.id as login', 1 ],
    [ 'ID', 'INT', 'cm.id', 1 ],
    [ 'TARIFF_ID', 'INT', 'tp.id as tariff_id', 1 ],
    [ 'ACTIVATE', 'DATE', 'cm.activate', 1 ],
    [ 'TP_ID', 'INT', 'cm.tp_id', 1 ],
    [ 'STATUS', 'INT', 'cm.status', 1 ],
    [ 'TP_NAME', 'STR', 'tp.name as tp_name', 1 ],
    [ 'TP_STREAMS_COUNT', 'INT', 'ctp.streams_count as tp_streams_count', 1 ],
    [ 'USER_STREAMS_COUNT', 'INT', 'COUNT(*) as user_streams_count', 1 ],
    [ 'SERVICE_ID', 'INT', 'ctp.service_id as service_id', 1 ],
    [ 'SERVICE_NAME', 'STR', 's.name as service_name', 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s   ON (ctp.service_id=s.id)
   $WHERE GROUP BY cm.id;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}


#**********************************************************

=head2 _info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub _info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM cams_main
    WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 _del($id)

=cut
#**********************************************************
sub _del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('cams_main', undef, { id => $id });

  return $self;
}

#**********************************************************

=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub users_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : '';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  if ($attr->{PORTAL}) {
    delete $attr->{SERVICE_ID};
  }

  my $search_columns = [
    [ 'UID', 'INT', 'cm.uid', ],
    [ 'LOGIN', 'STR', 'u.id as login', 1 ],
    [ 'ID', 'INT', 'cm.id', 1 ],
    [ 'TP_ID', 'INT', 'cm.tp_id', 1 ],
    [ 'STATUS', 'INT', 'cm.status', 1 ],
    [ 'TP_NAME', 'STR', 'tp.name as tp_name', 1 ],
    [ 'TP_STREAMS_COUNT', 'INT', 'ctp.streams_count as tp_streams_count', 1 ],
    [ 'USER_STREAMS_COUNT', 'INT', 'COUNT(*) as user_streams_count', 1 ],
    [ 'SERVICE_NAME', 'STR', 's.name as service_name', 1 ],
    [ 'SERVICE_ID', 'INT', 'ctp.service_id', 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_streams cs   ON (cm.uid=cs.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp  ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s ON (tp.service_id=s.id)
   $WHERE LIMIT $PG, $PAGE_ROWS ;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 user_info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->users_list({ COLS_NAME => 1, UID => $uid, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 user_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{ACTIVATE}) {$attr->{ACTIVATE} = 'NOW()'}

  if ( $attr->{TP_ID} && $attr->{TP_ID} > 0 && !$attr->{STATUS} ) {
    $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});
    $self->{TP_NUM} = $Tariffs->{ID};

    #Take activation price
    if ( $Tariffs->{ACTIV_PRICE} > 0 ){
      my $User = Users->new( $self->{db}, $self->{admin}, $self->{conf} );
      $User->info( $attr->{UID} );

      if ( $User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0 ){
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $fees = Fees->new( $self->{db}, $self->{admin}, $self->{conf} );
      $fees->take( $User, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "Cams. Active TP" } );
      $Tariffs->{ACTIV_PRICE} = 0;
    }
  }

  $self->query_add('cams_main', $attr);

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 users_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub users_del {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || $attr->{del};

  $self->query_del('cams_main', $attr, { 'uid' => [ $uid ] });

  return 1;
}

#**********************************************************

=head2 user_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'cams_main',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? 'DESC' : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'TP_ID', 'INT', 'ctp.tp_id', 1 ],
    [ 'ID', 'INT', 'tp.id', 1 ],
    [ 'SERVICE_NAME', 'STR', 's.name as service_name', 1 ],
    [ 'NAME', 'STR', 'tp.name', 1 ],
    [ 'STREAMS_COUNT', 'INT', 'ctp.streams_count', 1 ],
    [ 'PAYMENT_TYPE', 'INT', 'tp.payment_type', 1 ],
    [ 'SERVICE_ID', 'INT', 'tp.service_id', 1 ],
    [ 'MODULE', 'STR', 'tp.module', 1 ],
    [ 'DAY_FEE', 'INT', 'tp.day_fee', 1 ],
    [ 'ACTIVE_DAY_FEE', 'INT', 'tp.active_day_fee', 1 ],
    [ 'POSTPAID_DAY_FEE', 'INT', 'tp.postpaid_daily_fee', 1 ],
    [ 'MONTH_FEE', 'INT', 'tp.month_fee', 1 ],
    [ 'COMMENTS', 'STR', 'tp.comments', 1 ],
    [ 'FEES_METHOD', 'INT', 'tp.fees_method', 1 ],
    [ 'DAY_TIME_LIMIT', 'INT', 'tp.day_time_limit', 1 ],
    [ 'WEEK_TIME_LIMIT', 'INT', 'tp.week_time_limit', 1 ],
    [ 'MONTH_TIME_LIMIT', 'INT', 'tp.month_time_limit', 1 ],
    [ 'TOTAL_TIME_LIMIT', 'INT', 'tp.total_time_limit', 1 ],
    [ 'DAY_TRAF_LIMIT', 'INT', 'tp.day_traf_limit', 1 ],
    [ 'WEEK_TRAF_LIMIT', 'INT', 'tp.week_traf_limit', 1 ],
    [ 'MONTH_TRAF_LIMIT', 'INT', 'tp.month_traf_limit', 1 ],
    [ 'TOTAL_TRAF_LIMIT', 'INT', 'tp.total_traf_limit', 1 ],
    [ 'OCTETS_DIRECTION', 'INT', 'tp.octets_direction', 1 ],
    [ 'ACTIV_PRICE', 'INT', 'tp.activate_price', 1 ],
    [ 'CHANGE_PRICE', 'INT', 'tp.change_price', 1 ],
    [ 'CREDIT_TRESSHOLD', 'INT', 'tp.credit_tresshold', 1 ],
    [ 'CREDIT', 'STR', 'tp.credit', 1 ],
    [ 'DVR', 'INT', 'ctp.dvr', 1 ],
    [ 'PTZ', 'INT', 'ctp.ptz', 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] }} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS} 1
   FROM cams_tp ctp
   LEFT JOIN tarif_plans tp ON (ctp.tp_id=tp.tp_id)
   LEFT JOIN cams_services s ON (ctp.service_id=s.id)
    $WHERE ORDER BY $SORT;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************

=head2 tp_info($id)

  Arguments:
    $id - id for tp

  Returns:
    hash_ref

=cut

#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->tp_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{TP_ID}) {
    $attr->{MODULE} = "Cams";
    $Tariffs->add({ %$attr });

    if (defined($Tariffs->{errno})) {
      $self->{errno} = $Tariffs->{errno};
      return $self;
    }

    $attr->{TP_ID} = $Tariffs->{INSERT_ID};
    $self->{TP_NUM} = $Tariffs->{TP_NUM};
  }

  $self->query("INSERT INTO cams_tp (streams_count, service_id, tp_id)
    VALUES (?, ?, ?);", 'do',
    { Bind => [ $attr->{STREAMS_COUNT}, $attr->{SERVICE_ID}, $attr->{TP_ID} ] }
  );

  $self->{TP_ID} = $attr->{TP_ID};

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 tp_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->del($attr->{TP_ID});
  $self->query_del('cams_tp', undef, { TP_ID => $attr->{TP_ID} });

  return 1;
}

#**********************************************************

=head2 tp_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->change($attr->{TP_ID}, { %$attr });
  if (defined($Tariffs->{errno})) {
    $self->{errno} = $Tariffs->{errno};
    return $self;
  }

  $self->changes(
    {
      CHANGE_PARAM => 'TP_ID',
      TABLE        => 'cams_tp',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 streams_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub streams_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'g.service_id';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : "65000";

  my $search_columns = [
    [ 'ID', 'INT', 'cs.id', 1 ],
    [ 'UID', 'INT', 'cs.uid', 1 ],
    [ 'USER_LOGIN', 'STR', 'u.id AS user_login', 1 ],
    [ 'DISABLED', 'INT', 'cs.disabled', 1 ],
    [ 'NAME', 'STR', 'cs.name', 1 ],
    [ 'TITLE', 'STR', 'cs.title', 1 ],
    [ 'HOST', 'STR', 'cs.host', 1 ],
    [ 'LOGIN', 'STR', 'cs.login', 1 ],
    [ 'PASSWORD', 'STR', 'DECODE(cs.password, "' . $self->{conf}{secretkey} . '") as password', 1 ],
    [ 'RTSP_PORT', 'INT', 'cs.rtsp_port', 1 ],
    [ 'RTSP_PATH', 'STR', 'cs.rtsp_path', 1 ],
    [ 'NAME_HASH', 'STR', qq{CONCAT (MD5( CONCAT (cs.host, cs.login, cs.password) ), '__', cs.id ) AS name_hash}, 1 ],
    [ 'ORIENTATION', 'INT', 'cs.orientation', 1 ],
    [ 'TYPE', 'INT', 'cs.type', 1 ],
    [ 'GROUP_ID', 'INT', 'cs.group_id', 1 ],
    [ 'GROUP_NAME', 'STR', 'g.name as group_name', 1 ],
    [ 'SERVICE_ID', 'INT', 'g.service_id', 1 ],
    [ 'SERVICE_MODULE', 'STR', 's.module', 1 ],
    [ 'SERVICE_NAME', 'STR', 's.name as service_name', 1 ],
    [ 'EXTRA_URL', 'STR', 'cs.extra_url', 1 ],
    [ 'SCREENSHOT_URL', 'STR', 'cs.screenshot_url', 1 ],
    [ 'PRE_IMAGE_URL', 'STR', 'cs.pre_image_url', 1 ],
    [ 'LIMIT_ARCHIVE',  'INT', 'cs.limit_archive', 1 ],
    [ 'ARCHIVE', 'INT', 'cs.archive', 1 ],
    [ 'PRE_IMAGE', 'INT', 'cs.pre_image', 1 ],
    [ 'TRANSPORT', 'INT', 'cs.transport', 1 ],
    [ 'SOUND', 'INT', 'cs.sound', 1 ],
    [ 'CONSTANTLY_WORKING', 'INT', 'cs.constantly_working', 1 ],
    [ 'ONLY_VIDEO', 'INT', 'cs.only_video', 1 ],
    [ 'POINT_ID', 'INT', 'cs.point_id', 1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} cs.id, cs.coordx, cs.coordy
   FROM cams_streams cs
   LEFT JOIN users u ON (cs.uid=u.uid)
   LEFT JOIN cams_groups g ON (cs.group_id=g.id)
   LEFT JOIN cams_services s ON (g.service_id=s.id)
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
    ,
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 stream_info($id)

  Arguments:
    $id - id for streams

  Returns:
    hash_ref

=cut

#**********************************************************
sub stream_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->streams_list(
    {
      COLS_NAME        => 1,
      ID               => $id,
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1
    }
  );

  return $list->[0] || {};
}

#**********************************************************

=head2 stream_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_streams', {
    %{$attr ? $attr : {}},
    PASSWORD => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
  });

  return undef if $self->{errno};
  return $self->{INSERT_ID};
}

#**********************************************************

=head2 stream_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub stream_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_streams', $attr);

  return 1;
}

#**********************************************************

=head2 stream_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub stream_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_streams',
      DATA         => {
        %{$attr ? $attr : {}},
        PASSWORD => ($attr->{PASSWORD}) ? "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" : ''
      },
    }
  );

  return 1;
}


#**********************************************************
=head2 services_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub services_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME', 'STR', 'name', 1 ],
      [ 'MODULE', 'STR', 'module', 1 ],
      [ 'STATUS', 'INT', 'status', 1 ],
      [ 'COMMENT', 'STR', 'comment', 1 ],
      [ 'PROVIDER_PORTAL_URL', 'STR', 'provider_portal_url', 1 ],
      [ 'USER_PORTAL', 'INT', 'user_portal', 1 ],
      [ 'DEBUG', 'INT', 'debug', 1 ],
      [ 'LOGIN',       'INT', 'login',       1 ],
      [ 'PASSWORD',    'INT', '', "DECODE(password, '$CONF->{secretkey}') AS password" ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} s.id
   FROM cams_services s
    $WHERE
    GROUP BY s.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 screen_add($attr)

=cut
#**********************************************************
sub services_add {
  my $self = shift;
  my ($attr) = @_;

  if($attr->{PASSWORD}) {
    $attr->{PASSWORD} = "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')",
  }

  $self->query_add('cams_services', $attr);

  return $self;
}

#**********************************************************
=head2 screen_change($attr)

=cut
#**********************************************************
sub services_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_services',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 screen_del($id, $attr)

=cut
#**********************************************************
sub services_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_services', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 services_info($id)

  Arguments:
    $id  - Service ID

=cut
#**********************************************************
sub services_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM cams_services
    WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 group_list($attr) - list of tp group

  Arguments:
    $attr

=cut
#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME', 'STR', 'g.name', 1 ],
      [ 'LOCATION_ID', 'INT', 'g.location_id', 1 ],
      [ 'DISTRICT_ID', 'INT', 'g.district_id', 1 ],
      [ 'STREET_ID', 'INT', 'g.street_id', 1 ],
      [ 'BUILD_ID', 'INT', 'g.build_id', 1 ],
      [ 'SERVICE_ID', 'INT', 'g.service_id', 1 ],
      [ 'SERVICE_NAME', 'INT', 's.name as service_name', 1 ],
      [ 'MAX_USERS', 'INT', 'g.max_users', 1 ],
      [ 'MAX_CAMERAS', 'INT', 'g.max_cameras', 1 ],
      [ 'COMMENT', 'STR', 'g.comment', 1 ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} g.id
   FROM cams_groups g
   LEFT JOIN cams_services s ON(g.service_id=s.id)
    $WHERE
    GROUP BY g.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 group_add($attr)

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_groups', $attr);

  return $self;
}

#**********************************************************
=head2 group_change($attr)

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_groups',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 group_del($id, $attr)

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_groups', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 group_info($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT *
    FROM cams_groups
    WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 access_group_list($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub access_group_list {
  my $self = shift;
  my ($attr) = @_;

  my $groups;
  my @all_access_groups = ();

  if ($attr->{LOCATION_ID}) {
    $groups = $self->group_list({
      NAME        => "_SHOW",
      STREET_ID   => "_SHOW",
      BUILD_ID    => "_SHOW",
      DISTRICT_ID => "_SHOW",
      LOCATION_ID => $attr->{LOCATION_ID},
      SERVICE_ID  => $attr->{SERVICE_ID},
      COMMENT     => "_SHOW",
      COLS_NAME   => 1,
    });

    @all_access_groups = (@all_access_groups, @$groups);
  }

  if ($attr->{STREET_ID}) {
    $groups = $self->group_list({
      NAME        => "_SHOW",
      STREET_ID   => $attr->{STREET_ID},
      LOCATION_ID => 0,
      BUILD_ID    => "_SHOW",
      DISTRICT_ID => "_SHOW",
      SERVICE_ID  => $attr->{SERVICE_ID},
      COMMENT     => "_SHOW",
      COLS_NAME   => 1,
    });

    @all_access_groups = (@all_access_groups, @$groups);
  }

  if ($attr->{DISTRICT_ID}) {
    $groups = $self->group_list({
      NAME        => "_SHOW",
      DISTRICT_ID => $attr->{DISTRICT_ID},
      STREET_ID   => 0,
      LOCATION_ID => 0,
      BUILD_ID    => "_SHOW",
      SERVICE_ID  => $attr->{SERVICE_ID},
      COMMENT     => "_SHOW",
      COLS_NAME   => 1,
    });

    @all_access_groups = (@all_access_groups, @$groups);
  }

  $groups = $self->group_list({
    NAME        => "_SHOW",
    DISTRICT_ID => 0,
    STREET_ID   => 0,
    LOCATION_ID => 0,
    BUILD_ID    => "_SHOW",
    SERVICE_ID  => $attr->{SERVICE_ID},
    COMMENT     => "_SHOW",
    COLS_NAME   => 1,
  });

  @all_access_groups = (@all_access_groups, @$groups);

  return \@all_access_groups;
}

#**********************************************************
=head2 user_groups($attr) - Users groups

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_groups {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_groups', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/, /, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{ID}, $attr->{TP_ID}, $id ];
  }

  $self->query(
    "INSERT INTO cams_users_groups
     (id, tp_id, group_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}

#**********************************************************
=head2 user_groups_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_groups_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT tp_id, group_id, changed
     FROM cams_users_groups
     WHERE tp_id= ? AND id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
  );

  $self->{USER_GROUPS} = $self->{TOTAL};

  return $self->{list};
}

#**********************************************************
=head2 users_group_count($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub users_group_count {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT COUNT(*)
     FROM cams_users_groups
     WHERE group_id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{GROUP_ID} ] }
  );

  return $self->{list}[0][0];
}

#**********************************************************
=head2 user_cameras($attr) - Users cameras

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_cameras {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_cameras', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/, /, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{TP_ID}, $attr->{ID}, $id ];
  }

  $self->query(
    "INSERT INTO cams_users_cameras
     (tp_id, id, camera_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}


#**********************************************************
=head2 user_cameras_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_cameras_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT uc.tp_id, uc.id, uc.camera_id, uc.changed, c.name as camera_name, c.title, s.name as service_name, s.id as service_id
     FROM cams_users_cameras uc
     LEFT JOIN cams_tp t ON (uc.tp_id=t.tp_id)
     LEFT JOIN cams_streams c ON (uc.camera_id=c.id)
     LEFT JOIN cams_services s ON (s.id=t.service_id)
     WHERE uc.tp_id= ? AND uc.id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
  );

  $self->{USER_CAMERAS} = $self->{TOTAL};

  return $self->{list};
}

1;