package Nas;

=head1 NAME

  NAS Server configuration and managing

=cut

use strict;
use parent 'dbcore';
my $SECRETKEY = '';
my $IPV6 = 0;

#**********************************************************
=head2 new($db, \%conf, $admin)

=cut
#**********************************************************
sub new {
  my ($class, $db, $CONF, $admin) = @_;

  $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';

  if($CONF->{IPV6}) {
    $IPV6 = 1;
  }

  my $self = {
    db   => $db,
    conf => $CONF
  };
  bless($self, $class);

  $self->{admin} = $admin if ($admin);

  $CONF->{BUILD_DELIMITER} = ', ' if (!defined($CONF->{BUILD_DELIMITER}));

  return $self;
}

#**********************************************************
=head2 list($attr)

  Arguments:
    $attr
  Results:
    $list

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  delete($self->{COL_NAMES_ARR});

  if ($SECRETKEY eq q{}) {
    $SECRETKEY = $self->{conf}{secretkey} || q{};
  }

  my $EXT_TABLES = '';
  my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';

  my @search_params = (
    ['NAS_ID',           'INT', 'nas.id',      'nas.id AS nas_id'      ],
    ['NAS_NAME',         'STR', 'nas.name',    'nas.name AS nas_name'  ],
    ['NAS_IDENTIFIER',   'STR', 'nas.nas_identifier',                1 ],
    ['NAS_IP',           'IP',  'nas.ip',      'INET_NTOA(ip) AS ip'   ],
    ['NAS_TYPE',         'STR', 'nas.nas_type',                      1 ],
    ['DISABLE',          'INT', 'nas.disable',                       1 ],
    ['DESCR',            'STR', 'nas.descr',                         1 ],
    ['NAS_GROUP_NAME',   'STR', 'ng.name',  'ng.name AS nas_group_name'],
    ['ALIVE',            'INT', 'nas.alive',                         1 ],
    ['DOMAIN_ID',        'INT', 'nas.domain_id',                     1 ],
    ['MAC',              'STR', 'nas.mac',                           1 ],
    ['GID',              'INT', 'nas.gid',                           1 ],
    ['DISTRICT_ID',      'INT', 'streets.district_id', 'districts.name'],
    ['LOCATION_ID',      'INT', 'nas.location_id',                   1 ],
    ['MNG_HOST_PORT',    'STR', 'nas.mng_host_port',                 1 ],
    ['MNG_USER',         'STR', 'nas.mng_user',                      1 ],
    ['MNG_PASSWORD',      'STR', '',  "DECODE(nas.mng_password, '$SECRETKEY') AS mng_password"],
    ['NAS_MNG_HOST_PORT','STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port'   ],
    ['NAS_MNG_USER',     'STR', 'nas.mng_user', 'nas.mng_user AS nas_mng_user',       ],
    ['NAS_MNG_PASSWORD', 'STR', '',    "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password"],
    ['NAS_RAD_PAIRS',    'STR', 'nas.rad_pairs', 'nas.rad_pairs AS nas_rad_pairs'     ],
    ['SHOW_MAPS_GOOGLE', 'SHOW_MAPS_GOOGLE', 'builds.coordx, builds.coordy'           ],
    ['NAS_IDS',          'INT', 'nas.id'                                              ],
    ['NAS_FLOOR',        'STR', 'nas.floor',          'nas.floor AS nas_floor'        ],
    ['NAS_ENTRANCE',     'STR', 'nas.entrance',      'nas.entrance AS nas_entrance'   ],
    ['ADDRESS_FULL',     'STR', "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
      "streets.name, '$build_delimiter', builds.number, '$build_delimiter', nas.address_flat)",
      "CONCAT(" . ($self->{conf}{ADDRESS_FULL_SHOW_DISTRICT} ? "districts.name, '$build_delimiter'," : "") .
        "streets.name, '$build_delimiter', builds.number, '$build_delimiter', nas.address_flat) AS address_full" ],
    ['ZABBIX_HOSTID',  'INT', 'nas.zabbix_hostid', 1 ]
  );

  my $WHERE =  $self->search_former($attr, \@search_params, { WHERE => 1 });

  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $EXT_TABLES = "INNER JOIN builds ON (builds.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES =<< "EXT_TABLES";
    LEFT JOIN streets ON (streets.id=builds.street_id)
    LEFT JOIN districts ON (districts.id=streets.district_id)
EXT_TABLES
    }
  }
  elsif ($attr->{DISTRICT_ID} || $attr->{ADDRESS_FULL}) {
    $EXT_TABLES =<< "EXT_TABLES";
    LEFT JOIN builds ON (builds.id=nas.location_id)
    LEFT JOIN streets ON (streets.id=builds.street_id)
    LEFT JOIN districts ON (districts.id=streets.district_id)
EXT_TABLES
  }

  my $ext_fields = '';

#   if (! $attr->{SHORT}) {
#     $ext_fields = <<"FIELDS";
#     nas.id AS nas_id,
#     nas.name AS nas_name,
#     nas.nas_identifier,
#     INET_NTOA(nas.ip) AS nas_ip,
#     nas.nas_type,
#     ng.name as nas_group_name,
#     nas.disable as nas_disable,
#     nas.descr,
#     nas.alive as nas_alive,
#     nas.mng_host_port as nas_mng_ip_port,
#     nas.mng_user as nas_mng_user,
#     DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password,
#     nas.rad_pairs as nas_rad_pairs,
#     nas.ext_acct,
#     nas.auth_type,
# FIELDS
#   }

  my $sql = <<"SQL";
  SELECT
  $ext_fields
  $self->{SEARCH_FIELDS}
  nas.mac,
  nas.id
  FROM nas
  LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
  $EXT_TABLES
  $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};
  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $sql = <<"SQL";
SELECT COUNT(*) AS total
FROM nas
  LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
  $EXT_TABLES
  $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list || [];
}

#***************************************************************
=head2 info($attr)

  Arguments:
    NAS_ID
    IP
    CALLED_STATION_ID

  Returns:
    NAS_INFO

=cut
#***************************************************************
sub info {
  my ($self, $attr) = @_;

  my $WHERE = '';

  if ($attr->{IP}) {
    $WHERE = "ip=INET_ATON('$attr->{IP}')";
    if ($attr->{NAS_IDENTIFIER}) {
      $WHERE .= " AND (nas_identifier='$attr->{NAS_IDENTIFIER}' or nas_identifier='')";
    }
    else {
      $WHERE .= " AND nas_identifier=''";
    }
  }
  elsif ($attr->{CALLED_STATION_ID}) {
    $WHERE = "mac='$attr->{CALLED_STATION_ID}'";
  }
  else {
    $WHERE = "id='$attr->{NAS_ID}'";
  }

  my $fields = '';

  if ( ! $attr->{SHORT}) {
    $fields = << "FIELDS";
 ,name AS nas_name,
    descr AS nas_describe,
    mng_host_port AS nas_mng_ip_port,
    mng_host_port AS nas_mng_host_port,
    mng_user AS nas_mng_user,
    nas.*,
    INET_NTOA(ip) AS ip,
    DECODE(mng_password, '$SECRETKEY') AS nas_mng_password,
    DECODE(mng_password, '$SECRETKEY') AS mng_password
FIELDS
  }

  my $sql = <<"SQL";
SELECT id as nas_id,
       nas_identifier,
       INET_NTOA(ip) AS nas_ip,
       nas_type,
       auth_type AS nas_auth_type,
       alive AS nas_alive,
       disable AS nas_disable,
       ext_acct AS nas_ext_acct,
       rad_pairs AS nas_rad_pairs,
       mac,
       domain_id
         $fields
FROM nas
WHERE $WHERE;
SQL



  $self->query($sql, undef, { INFO => 1 });

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    $sql = <<'SQL';
SELECT
  d.id AS district_id,
  d.name AS address_district,
  s.name AS address_street,
  b.number AS address_build
FROM builds b
       LEFT JOIN streets s ON (s.id=b.street_id)
       LEFT JOIN districts d ON (d.id=s.district_id)
WHERE b.id= ?
SQL

    $self->query($sql, undef,
      { INFO => 1, Bind => [ $self->{LOCATION_ID} ] }
    );

    if ($self->{errno} && $self->{errno} == 2) {
      delete $self->{errno};
    }
  }

  return $self;
}

#**********************************************************
=head2 change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub change {
  my ($self, $attr) = @_;

  $attr->{NAS_DISABLE} = ($attr->{NAS_DISABLE}) ? 1 : 0;

  my %FIELDS = (
    NAS_ID           => 'id',
    NAS_NAME         => 'name',
    NAS_IDENTIFIER   => 'nas_identifier',
    NAS_DESCRIBE     => 'descr',
    IP               => 'ip',
    NAS_TYPE         => 'nas_type',
    NAS_AUTH_TYPE    => 'auth_type',
    NAS_MNG_IP_PORT  => 'mng_host_port',
    NAS_MNG_HOST_PORT=> 'mng_host_port',
    NAS_MNG_USER     => 'mng_user',
    NAS_MNG_PASSWORD => 'mng_password',
    NAS_RAD_PAIRS    => 'rad_pairs',
    NAS_ALIVE        => 'alive',
    NAS_DISABLE      => 'disable',
    NAS_EXT_ACCT     => 'ext_acct',
    ADDRESS_BUILD    => 'address_build',
    ADDRESS_STREET   => 'address_street',
    ADDRESS_FLAT     => 'address_flat',
    ZIP              => 'zip',
    CITY             => 'city',
    COUNTRY          => 'country',
    DOMAIN_ID        => 'domain_id',
    GID              => 'gid',
    MAC              => 'mac',
    CHANGED          => 'changed',
    LOCATION_ID      => 'location_id',
    FLOOR            => 'floor',
    ENTRANCE         => 'entrance',
    ZABBIX_HOSTID    => 'zabbix_hostid',
  );

  $attr->{CHANGED} = 1;
  $self->{admin}->{MODULE} = '';

  if(! $attr->{NAS_MNG_PASSWORD}) {
    delete $attr->{NAS_MNG_PASSWORD};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});

    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->changes({
    CHANGE_PARAM    => 'NAS_ID',
    TABLE           => 'nas',
    FIELDS          => \%FIELDS,
    OLD_INFO        => $self->info({ NAS_ID => $self->{NAS_ID} || $attr->{NAS_ID} }),
    DATA            => $attr,
    EXT_CHANGE_INFO => "NAS_ID:$self->{NAS_ID}"
  });

  if (! $self->{errno}) {
    $self->info({ NAS_ID => $self->{NAS_ID} });
  }

  return $self;
}

#**********************************************************
=head2 add($attr) - Add nas server

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub add {
  my ($self, $attr) = @_;

  if($self->{admin} && $self->{admin}->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $self->{admin}->{DOMAIN_ID};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD} && ! $attr->{LOCATION_ID}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});

    $Address->build_add($attr);
    $attr->{LOCATION_ID}=$Address->{LOCATION_ID};
  }

  $self->query_add('nas', {
    %$attr,
    NAME           => $attr->{NAS_NAME},
    DESCR          => $attr->{NAS_DESCRIBE},
    AUTH_TYPE      => $attr->{NAS_AUTH_TYPE},
    MNG_HOST_PORT  => $attr->{NAS_MNG_HOST_PORT},
    MNG_USER       => $attr->{NAS_MNG_USER},
    MNG_PASSWORD   => ($attr->{NAS_MNG_PASSWORD}) ? "ENCODE('$attr->{NAS_MNG_PASSWORD}', '$SECRETKEY')" : undef,
    RAD_PAIRS      => $attr->{NAS_RAD_PAIRS} || '',
    ALIVE          => $attr->{NAS_ALIVE} || 0,
    DISABLE        => $attr->{NAS_DISABLE},
    EXT_ACCT       => $attr->{NAS_EXT_ACCT},
  });

  $self->{NAS_ID}=$self->{INSERT_ID};

  if ($attr->{ACTION_ADMIN}) {
    return $self;
  }

  $self->{admin}->system_action_add("NAS_ID: $self->{NAS_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 del($id) - Del nas server

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub del {
  my ($self, $id) = @_;

  $self->query_del('nas', undef,  { id => $id });
  $self->{nas_deleted} = $self->{AFFECTED};
  $self->query_del('nas_ippools', undef, { nas_id => $id });

  $self->{admin}->system_action_add("NAS_ID:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 users_list($nas_id, $attr) - retrieves users bound to this $nas_id

  Arguments:
    - $nas_id
    - $attr

  Returns:
    list

=cut
#**********************************************************
sub users_list {
  my ( $self, $nas_id, $attr ) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',  'INT', 'nas_id'],
      ['UID',     'INT', 'uid'   ],
    ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT uid, nas_id
FROM users_nas
$WHERE
ORDER BY $SORT $DESC
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 nas_ip_pools_list($attr)

  Arguments:
    $attr

  Results:
    $list

=cut
#**********************************************************
sub nas_ip_pools_list {
  my ($self, $attr) = @_;

  # This should go first to keep internal global flags for $self
  my @WHERE_NAS_RULES = ('np.pool_id=pool.id');
  my $WHERE_NAS = $self->search_former($attr, [
      ['NAS_ID', 'INT', 'np.nas_id'  ],
      ['STATIC', 'INT', 'pool.static'],
    ],
    {
      WHERE_RULES => \@WHERE_NAS_RULES
    }
  );

  my @search_columns = (
    [ 'ID',                 'INT', 'pool.id',                                               1],
    [ 'NAS_NAME',           'STR', 'n.name AS nas_name',                                    1],
    [ 'POOL_NAME',          'STR', 'pool.name AS pool_name',                                1],
    [ 'FIRST_IP',           'IP',  'INET_NTOA(pool.ip) AS first_ip',                        1],
    [ 'LAST_IP',            'IP',  'INET_NTOA(pool.ip + if(pool.counts > 0, pool.counts - 1, 0)) AS last_ip',     1],
    [ 'IP',                 'INT', 'pool.ip',                                               1],
    [ 'LAST_IP_NUM',        'INT', '(pool.ip + if(pool.counts > 0, pool.counts - 1, 0)) AS last_ip_num',          1],
    [ 'IP_COUNT',           'INT', 'pool.counts AS ip_count',                               1],
    [ 'INTERNET_IP_FREE',   'INT', '(pool.counts - (SELECT if(COUNT(*) > pool.counts, pool.counts, COUNT(*)) FROM internet_main internet '
      . 'WHERE internet.ip >= pool.ip AND internet.ip < pool.ip + pool.counts AND uid > 0)) AS internet_ip_free', 1],
    [ 'INTERNET_DYNAMIC_IP_FREE',   'INT', '(pool.counts - (SELECT if(COUNT(*) > pool.counts, pool.counts, COUNT(*)) FROM internet_online online '
      . 'WHERE online.framed_ip_address >= pool.ip AND online.framed_ip_address < pool.ip + pool.counts )) AS internet_dynamic_ip_free', 1],
    [ 'PRIORITY',           'INT', 'pool.priority',                                         1],
    [ 'SPEED',              'INT', 'pool.speed',                                            1],
    [ 'NAME',               'STR', 'pool.name AS name',                                     1],
    [ 'NAS',                'INT', 'np.nas_id',                                             1],
#    [ 'NAS_ID',             'INT', 'np.nas_id',                                             1],
    [ 'NETMASK',            'IP',  'pool.netmask',                                          1],
    [ 'GATEWAY',            'IP',  'pool.gateway',                                          1],
    [ 'STATIC',             'INT', 'pool.static',                                           1],
    [ 'ACTIVE_NAS_ID',      'INT', 'IF(np.nas_id IS NULL, 0, np.nas_id) AS active_nas_id',  1],
    [ 'IP_SKIP',            'STR', 'pool.ip_skip',                                          1],
    [ 'COMMENTS',           'STR', 'pool.comments',                                         1],
    [ 'DNS',                'STR', 'pool.dns',                                              1],
    [ 'VLAN',               'INT', 'pool.vlan',                                             1],
    [ 'GUEST',              'INT', 'pool.guest',                                            1],
    [ 'NEXT_POOL',          'INT', 'pool.next_pool_id AS next_pool',                        1]
  );

  if ($IPV6) {
    push @search_columns, (
      [ 'IPV6_PREFIX',        'STR', 'INET6_NTOA(pool.ipv6_prefix) AS ipv6_prefix',           1],
      [ 'IPV6_NET_MASK',      'INT', 'pool.ipv6_net_mask',                                    1],
      [ 'IPV6_MASK',          'IP',  'pool.ipv6_mask',                                        1],
      [ 'IPV6_TEMP',          'STR', 'pool.ipv6_template AS ipv6_temp',                       1],
      [ 'IPV6_PD',            'STR', 'INET6_NTOA(pool.ipv6_pd) AS ipv6_pd',                   1],
      [ 'IPV6_PD_NET_MASK',   'INT', 'pool.ipv6_pd_net_mask',                                 1],
      [ 'IPV6_PD_MASK',       'STR', 'pool.ipv6_pd_mask',                                     1],
      [ 'IPV6_PD_TEMP',       'STR', 'pool.ipv6_pd_template AS ipv6_pd_temp',                 1],
    );
  }

  my $WHERE = $self->search_former($attr, \@search_columns, {WHERE => 1});

  my $sql = <<"SQL";
   SELECT $self->{SEARCH_FIELDS} pool.id
   FROM ippools pool
   LEFT JOIN nas_ippools np ON ($WHERE_NAS)
   LEFT JOIN nas n ON (n.id=np.nas_id)
   $WHERE
   GROUP BY pool.id
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $sql = <<"SQL";
   SELECT COUNT(*) AS total
   FROM ippools pool
   LEFT JOIN nas_ippools np ON ($WHERE_NAS)
   $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 nas_ip_pools_add($attr) add NAS IP Pools

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub nas_ip_pools_add {
  my ($self, $attr) = @_;

  $self->query_add('nas_ippools', $attr, { REPLACE => 1 });

  $self->{admin}->system_action_add(
    "NAS_IP_POOL_ADD:$self->{INSERT_ID}",
    { TYPE => 1 }
  );

  return $self;
}

#**********************************************************
=head2 nas_ip_pools_del($attr) delete NAS IP Pools

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub nas_ip_pools_del {
  my ($self, $attr) = @_;

  $self->query_del('nas_ippools', undef, $attr);

  $self->{admin}->system_action_add(
    "NAS_IP_POOL_DELETE:NAS_ID" . ($attr->{NAS_ID} || q{}) . ",POOL_ID" . ($attr->{POOL_ID} || q{}),
    { TYPE => 10 }
  );

  return $self;
}

#**********************************************************
=head2 nas_ip_pools_set($attr) NAS IP Pools

  Arguments:
    $attr

  Resukts:
    $self

=cut
#**********************************************************
sub nas_ip_pools_set {
  my ($self, $attr) = @_;

  my $ids = $attr->{ids_remove} || q{};
  $self->query("DELETE FROM nas_ippools WHERE nas_id = ? AND pool_id IN ($ids);", 'do', {
    Bind => [ $self->{NAS_ID} ]
  });

  my @MULTI_QUERY = ();
  my @ids = split(/,\s?/x, $attr->{ids});

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id, $attr->{NAS_ID} ] if ($id);
  }

  $self->query("INSERT INTO nas_ippools (pool_id, nas_id) VALUES (?, ?);",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY });

  if ($self->{admin}) {
    $self->{admin}->system_action_add("NAS_ID:$self->{NAS_ID} POOLS:" . (join(',', @ids)), { TYPE => 2 });
  }

  return $self;
}

#**********************************************************
=head2 ip_pools_info($id)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub ip_pools_info {
  my ($self, $id, $attr) = @_;

  my $EXT_FIELDS = ($IPV6) ? ", INET6_NTOA(ipv6_prefix) AS ipv6_prefix, INET6_NTOA(ipv6_pd) AS ipv6_pd" : '';

  if ($attr->{INTERNET_IP_FREE}) {
    $EXT_FIELDS .= <<"FIELDS";
, (ippools.counts - (SELECT if(COUNT(*) > ippools.counts, ippools.counts, COUNT(*)) FROM internet_main internet
      WHERE internet.ip >= ippools.ip AND internet.ip < ippools.ip + ippools.counts )) AS internet_ip_free
FIELDS
  }

  my $sql = <<"SQL";
SELECT *,
  INET_NTOA(ip) AS ip
  $EXT_FIELDS
  FROM ippools
  WHERE id= ?
SQL


  $self->query($sql,  undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 ip_pools_change($attr) - NAS IP Pools change

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub ip_pools_change {
  my ($self, $attr) = @_;

  $attr->{STATIC} = ($attr->{STATIC}) ? $attr->{STATIC} : 0;
  $attr->{GUEST} = ($attr->{GUEST}) ? $attr->{GUEST} : 0;

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'ippools',
    DATA            => $attr,
    EXT_CHANGE_INFO => "POOL:$attr->{ID}"
  });

  return $self;
}

#**********************************************************
=head2 ip_pools_list($attr)

  Arguments:
    $attr
      STATIC  - Show static pools
      IPV6    - Show ipv6 prefix

  Results:

=cut
#**********************************************************
sub ip_pools_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, "pool.domain_id='$attr->{DOMAIN_ID}'";
  }

  my $sql = {};
  if (defined($attr->{STATIC})) {
    my $fields = q{INET6_NTOA(pool.ipv6_prefix) AS ipv6_prefix,};
    if ($attr->{IPV6}) {
      push @WHERE_RULES, "pool.ipv6_prefix<>''";
    }

    push @WHERE_RULES, "pool.static IN ($attr->{STATIC})";

    my $WHERE = ($#WHERE_RULES > -1) ? join(' AND ', @WHERE_RULES) : '';

    $sql = <<"SQL";
SELECT
  '',
  pool.name,
  pool.ip,
  pool.ip + pool.counts AS last_ip_num,
  pool.counts,
  pool.priority,
  INET_NTOA(pool.ip) AS first_ip,
  INET_NTOA(pool.ip + pool.counts) AS last_ip,
  pool.id,
  pool.nas,
  pool.netmask as netmask,
  pool.gateway,
  $fields
  pool.dns
FROM ippools pool
WHERE $WHERE
ORDER BY $SORT $DESC
SQL

  }
  else {
    if (defined($self->{NAS_ID})) {
      push @WHERE_RULES, "pool.nas='$self->{NAS_ID}'";
    }

    my $WHERE = ($#WHERE_RULES > -1) ? "and " . join(' AND ', @WHERE_RULES) : '';

    $sql = <<"SQL";
SELECT
  nas.name,
  pool.name,
  pool.ip,
  pool.ip + pool.counts AS last_ip_num,
  pool.counts, pool.priority,
  INET_NTOA(pool.ip) AS first_ip,
  INET_NTOA(pool.ip + pool.counts - 1) AS last_ip,
  pool.id,
  pool.nas,
  pool.gateway,
  pool.netmask as netmask
FROM ippools pool, nas
WHERE pool.nas=nas.id
  $WHERE  ORDER BY $SORT $DESC
SQL
  }

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 ip_pools_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub ip_pools_add {
  my ($self, $attr) = @_;

  delete $attr->{IPV6_PREFIX} if (! $IPV6);

  $self->query_add('ippools', {
    %$attr,
    NAS => undef,
  });

  if($self->{admin}) {
    $self->{admin}->system_action_add("NAS_ID:$attr->{NAS_ID} POOLS:" . (join(',', split(/,\s?/x, $attr->{ids}))), { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 ip_pools_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub ip_pools_del {
  my ($self, $id) = @_;

  $self->query_del('ippools', { ID => $id });

  $self->{admin}->system_action_add("POOL:$id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 stats($attr) - Statistic

  Arguments:
    $attr
      INTERNET

  Returns:
    $list

=cut
#**********************************************************
sub stats {
  my ($self, $attr) = @_;

  my $WHERE = "WHERE DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(CURDATE(), '%Y-%m')";
  my $SORT  = ($attr->{SORT} && $attr->{SORT} == 1) ? "1,2" : ($attr->{SORT} || 1);
  my $DESC  = ($attr->{DESC})      ? $attr->{DESC} : '';

  if (defined($attr->{NAS_ID})) {
    $WHERE .= "AND id='$attr->{NAS_ID}'";
  }

  my $internet_log_table = 'internet_log';

  my $sql = <<"SQL";
SELECT
  n.name,
  l.port_id,
  COUNT(*),
  IF(DATE_FORMAT(MAX(l.start), '%Y-%m-%d')=CURDATE(), DATE_FORMAT(MAX(l.start), '%H-%i-%s'), MAX(l.start)),
  SEC_TO_TIME(AVG(l.duration)), SEC_TO_TIME(MIN(l.duration)), SEC_TO_TIME(MAX(l.duration)),
  l.nas_id
FROM $internet_log_table l
LEFT JOIN nas n ON (n.id=l.nas_id)
$WHERE
GROUP BY l.nas_id, l.port_id
ORDER BY $SORT $DESC;
SQL

  $self->query($sql);

  return $self->{list} || [];
}

#**********************************************************
=head2 nas_group_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub nas_group_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'DOMAIN_ID',  'INT', 'g.domain_id'                ],
    [ 'NAME',       'STR', 'g.name',                  1 ],
    [ 'COUNTS',     'INT', '', 'COUNT(*) AS counts'     ],
  ], { WHERE => 1 });

  my $EXT_TABLES = '';
  if ($attr->{COUNTS}) {
    $EXT_TABLES =  'LEFT JOIN nas n ON (n.gid=g.id)';
  }

  my $sql = <<"SQL";
SELECT
  g.id, g.name,
  g.comments,
  g.disable,
  $self->{SEARCH_FIELDS} g.id AS gid
FROM nas_groups g
  $EXT_TABLES
  $WHERE
GROUP BY g.id
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}

#***************************************************************
=head2 nas_group_info($attr);

  Arguments:
    $attr
  Results:
    $self

=cut
#***************************************************************
sub nas_group_info {
  my ($self, $attr) = @_;

  $self->query("SELECT * FROM nas_groups WHERE id = ?;",
  undef,
  { INFO => 1,
    Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 nas_group_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub nas_group_change {
  my ($self, $attr) = @_;

  $attr->{DISABLE} = (defined($attr->{DISABLE})) ? 1 : 0;

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'nas_groups',
    DATA            => $attr,
    EXT_CHANGE_INFO => "NAS_GROUP_ID:$self->{ID}"
  });

  $self->nas_group_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
=head2 nas_group_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub nas_group_add {
  my ($self, $attr) = @_;

  $self->query_add('nas_groups', $attr);

  $self->{admin}->system_action_add(
    "NAS_GROUP_ID:$self->{INSERT_ID}",
    { TYPE => 1 }
  );

  return $self;
}

#**********************************************************
=head2 nas_group_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub nas_group_del {
  my ($self, $id) = @_;

  $self->query_del('nas_groups', { ID => $id });

  $self->{admin}->system_action_add("NAS_GROUP_ID:$id", { TYPE => 10 });

  return $self;
}

#*******************************************************************
=head2 divide_ips($attr) - divide ip pool to ips

  Arguments:
   $attr:
    FIRST - start of ip pool
    COUNT - count of ips
    POOL_ID - id of ip pool

  Returns:
    1
=cut
#*******************************************************************
sub divide_ips{
  my ($self, $attr) = @_;

  my $sql = <<"SQL";
INSERT INTO ippools_ips (ip, ippool_id)
SELECT
  (?+TWO_1.SeqValue + TWO_2.SeqValue + TWO_4.SeqValue + TWO_8.SeqValue + TWO_16.SeqValue + TWO_32.SeqValue + TWO_64.SeqValue + TWO_128.SeqValue + TWO_256.SeqValue + TWO_512.SeqValue + TWO_1024.SeqValue + TWO_2048.SeqValue + TWO_4096.SeqValue + TWO_8192.SeqValue + TWO_16384.SeqValue + TWO_32768.SeqValue+ TWO_65536.SeqValue) AS SeqValue, ?
FROM
  (SELECT 0 SeqValue UNION ALL SELECT 1 SeqValue) TWO_1
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 2 SeqValue) TWO_2
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 4 SeqValue) TWO_4
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 8 SeqValue) TWO_8
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 16 SeqValue) TWO_16
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 32 SeqValue) TWO_32
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 64 SeqValue) TWO_64
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 128 SeqValue) TWO_128
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 256 SeqValue) TWO_256
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 512 SeqValue) TWO_512
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 1024 SeqValue) TWO_1024
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 2048 SeqValue) TWO_2048
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 4096 SeqValue) TWO_4096
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 8192 SeqValue) TWO_8192
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 16384 SeqValue) TWO_16384
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 32768 SeqValue) TWO_32768
    CROSS JOIN (SELECT 0 SeqValue UNION ALL SELECT 65536 SeqValue) TWO_65536
ORDER BY 1 LIMIT ?;
SQL

  $self->query($sql, 'do', {
    Bind => [
      $attr->{FIRST},
      $attr->{POOL_ID},
      $attr->{COUNT}
    ],
  });

  return 1;
}


#*******************************************************************
=head2 remove_ippools_ips($POLL_ID) - remove ippools_ips

  Arguments:
    POOL_ID - id of ip pool

  Returns:
    $self

=cut
#*******************************************************************
sub remove_ippools_ips {
  my ($self, $attr) = @_;

  $self->query_del('ippools_ips', undef,  { ippool_id => $attr->{POOL_ID} || $attr->{DEL}, IP => $attr->{IP} });

  return $self;
}

#*******************************************************************
=head2 ippools_ips_list($attr) - list of ippools ips

  Arguments:
    $attr

  Returns:
    $list

=cut
#*******************************************************************
sub ippools_ips_list{
  my ($self, $attr) = @_;

  $attr->{PAGE_ROWS} //= 1000;

  my @search_params = (
    [ 'IP_POOL_ID',           'INT', 'ii.ippool_id',              1 ],
    [ 'IP',                   'INT', 'ii.ip',                     1 ],
    [ 'STATUS',               'INT', 'ii.status',                 1 ]
  );

  my $WHERE =  $self->search_former($attr, \@search_params, { WHERE => 1  });

  my $sql = <<"SQL";
    SELECT
      ii.ippool_id,
      ii.ip,
      ii.status
    FROM ippools_ips ii
    $WHERE
SQL

  $self->query_list($sql, $attr);

  return $self->{list} || [];
}


1;
