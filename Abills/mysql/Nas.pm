package Nas;

#Nas Server configuration and managing

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use main;
@ISA = ("main");
my $CONF;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  ($db, $CONF) = @_;

  $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;
  return $self;
}

#**********************************************************
# Nas list
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $EXT_TABLES = '';
  if ($attr->{SHOW_MAPS_GOOGLE}) {
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
  }
  elsif ($attr->{SHOW_MAPS}) {
    $EXT_TABLES = "INNER JOIN builds b ON (b.id=nas.location_id)";
    if ($attr->{DISTRICT_ID}) {
      $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=b.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
  }

  my $WHERE =  $self->search_former($attr, [
      ['TYPE',             'STR', 'nas.nas_type'       ],
      ['DISABLE',          'INT', 'nas.disable'        ],
      ['NAS_ID',           'INT', 'nas.id'             ],
      ['NAS_IDS',          'INT', 'nas.id'             ],
      ['NAS_NAME',         'STR', 'nas.name'           ],
      ['NAS_TYPE',         'STR', 'nas.nas_type'       ],
      ['DOMAIN_ID',        'INT', 'nas.domain_id'      ],
      ['MAC',              'INT', 'nas.mac',         1 ],
      ['NAS_IP',           'STR', 'nas.ip'             ],
      ['GID',              'INT', 'nas.gid',         1 ],
      ['DISTRICT_ID',      'INT', 'streets.district_id', 'districts.name' ],
      ['SHOW_MAPS',        '',    'b.map_x, b.map_y, b.map_x2, b.map_y2, b.map_x3, b.map_y3, b.map_x4, b.map_y4' ], 
      ['SHOW_MAPS_GOOGLE', 'SHOW_MAPS_GOOGLE', 'b.coordx, b.coordy' ]
    ],
    { WHERE => 1,
    }    
    );

  $self->query2("SELECT nas.id AS nas_id, 
  nas.name as nas_name, 
  nas.nas_identifier, 
  nas.ip as nas_ip,   
  nas.nas_type, 
  ng.name as nas_group_name,
  nas.disable as nas_disable, 
  nas.descr, 
  nas.alive as nas_alive,
  nas.mng_host_port as nas_mng_ip_port, 
  nas.mng_user as nas_mng_user,  
  DECODE(nas.mng_password, '$SECRETKEY') as nas_mng_password, 
  nas.rad_pairs as nas_rad_pairs, 
  nas.ext_acct,
  nas.auth_type,
  $self->{SEARCH_FIELDS}
  nas.mac
  FROM nas
  LEFT JOIN nas_groups ng ON (ng.id=nas.gid)
  $EXT_TABLES
  $WHERE
  ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#***************************************************************
# info($attr);
#***************************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';

  if ($attr->{IP}) {
    $WHERE = "ip='$attr->{IP}'";
    if (defined($attr->{NAS_IDENTIFIER})) {
      $WHERE .= " and (nas_identifier='$attr->{NAS_IDENTIFIER}' or nas_identifier='')";
    }
    else {
      $WHERE .= " and nas_identifier=''";
    }
  }
  elsif ($attr->{CALLED_STATION_ID}) {
    $WHERE = "mac='$attr->{CALLED_STATION_ID}'";
  }
  else {    #($attr->{NAS_ID}) {
    $WHERE = "id='$attr->{NAS_ID}'";
  }

  $self->query2("SELECT id as nas_id, 
    name AS nas_name,
    nas_identifier, 
    descr AS nas_describe, 
    ip AS nas_ip, 
    nas_type, 
    auth_type AS nas_auth_type, 
    mng_host_port as nas_mng_ip_port, 
    mng_user AS nas_mng_user, 
    DECODE(mng_password, '$SECRETKEY') AS nas_mng_password, 
    rad_pairs AS nas_rad_pairs, 
    alive AS nas_alive, 
    disable AS nas_disable, 
    ext_acct AS nas_ext_acct, 
    gid, 
    address_build, 
    address_street, 
    address_flat, 
    zip, 
    city, 
    country, 
    domain_id, 
    mac,
    changed, 
    location_id
 FROM nas
 WHERE $WHERE
 ORDER BY nas_identifier DESC;",
 undef,
 { INFO => 1 }
  );

  if (! $self->{errno} && $self->{LOCATION_ID}) {
    $self->query2("select d.id AS district_id, d.city, 
      d.name AS address_district, 
      s.name AS address_street, 
      b.number AS address_build 
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'",
     undef,
     { INFO => 1 }
    );

    if ($self->{errno} && $self->{errno} == 2) {
    	delete $self->{errno};
    }
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $attr->{NAS_DISABLE} = (defined($attr->{NAS_DISABLE})) ? 1 : 0;

  my %FIELDS = (
    NAS_ID           => 'id',
    NAS_NAME         => 'name',
    NAS_IDENTIFIER  => 'nas_identifier',
    NAS_DESCRIBE     => 'descr',
    NAS_IP           => 'ip',
    NAS_TYPE         => 'nas_type',
    NAS_AUTH_TYPE    => 'auth_type',
    NAS_MNG_IP_PORT  => 'mng_host_port',
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
    LOCATION_ID      => 'location_id'
  );

  $attr->{CHANGED} = 1;
  $admin->{MODULE} = '';

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'NAS_ID',
      TABLE           => 'nas',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->info({ NAS_ID => $self->{NAS_ID} }),
      DATA            => $attr,
      EXT_CHANGE_INFO => "NAS_ID:$self->{NAS_ID}"
    }
  );

  $self->info({ NAS_ID => $self->{NAS_ID} });
  return $self;
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query2("INSERT INTO nas (name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 mng_password, rad_pairs, alive, disable, ext_acct, 
 address_build, address_street, address_flat, zip, city, country, domain_id, gid, mac, location_id)
 values ('$DATA{NAS_NAME}', '$DATA{NAS_IDENTIFIER}', '$DATA{NAS_DESCRIBE}', '$DATA{NAS_IP}', '$DATA{NAS_TYPE}', '$DATA{NAS_AUTH_TYPE}',
  '$DATA{NAS_MNG_IP_PORT}', '$DATA{NAS_MNG_USER}', ENCODE('$DATA{NAS_MNG_PASSWORD}', '$SECRETKEY'), '$DATA{NAS_RAD_PAIRS}',
  '$DATA{NAS_ALIVE}', '$DATA{NAS_DISABLE}', '$DATA{NAS_EXT_ACCT}',
  '$DATA{ADDRESS_BUILD}', '$DATA{ADDRESS_STREET}', '$DATA{ADDRESS_FLAT}', '$DATA{ZIP}', '$DATA{CITY}', '$DATA{COUNTRY}', '$DATA{DOMAIN_ID}',
  '$DATA{GID}', '$DATA{MAC}', '$DATA{LOCATION_ID}');", 'do'
  );

  $admin->system_action_add("NAS_ID:$self->{INSERT_ID}", { TYPE => 1 });
  return 0;
}

#**********************************************************
# ADel nas server
# add($self)
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM nas WHERE id='$id'", 'do');
  $self->query2("DELETE FROM nas_ippools WHERE nas_id='$id';", 'do');

  $admin->system_action_add("NAS_ID:$id", { TYPE => 10 });
  return 0;
}

#**********************************************************
# NAS IP Pools
#
#**********************************************************
sub nas_ip_pools_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ('np.pool_id=pool.id');

  my $WHERE_NAS =  $self->search_former($attr, [
      ['NAS_ID',          'INT', 'np.nas_id'      ],
      ['STATIC',          'INT', 'pool.static'    ],
    ],
    { 
    	WHERE_RULES => \@WHERE_RULES
    }    
    );

  $self->query2("SELECT if (np.nas_id IS NULL, 0, np.nas_id) AS active_nas_id,
   n.name as nas_name, pool.name AS pool_name, 
    pool.ip, pool.ip + pool.counts AS last_ip_num, 
    pool.counts AS ip_count,  pool.priority, pool.speed,
    INET_NTOA(pool.ip) as first_ip, 
    INET_NTOA(pool.ip + pool.counts) AS last_ip, 
    pool.id, 
    np.nas_id, 
    pool.static
    FROM ippools pool
    LEFT JOIN nas_ippools np ON ($WHERE_NAS)
    LEFT JOIN nas n ON (n.id=np.nas_id)
      ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  return $self->{list};
}

#**********************************************************
# NAS IP Pools
#
#**********************************************************
sub nas_ip_pools_set {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2("DELETE FROM nas_ippools WHERE nas_id='$self->{NAS_ID}'", 'do');

  foreach my $id (split(/, /, $attr->{ids})) {
    $self->query2("INSERT INTO nas_ippools (pool_id, nas_id) 
    VALUES ('$id', '$attr->{NAS_ID}');", 'do'
    );
  }

  $admin->system_action_add("NAS_ID:$self->{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 2 });
  return $self->{list};
}

#**********************************************************
# NAS IP Pools
#
#**********************************************************
sub ip_pools_info {
  my $self = shift;
  my ($id, $attr) = @_;

  my $WHERE = '';

  my $fields_v6 = ($CONF->{IPV6}) ? ", INET6_NTOA(ipv6_prefix) AS ipv6_prefix" : '';

  $self->query2("SELECT id, 
      INET_NTOA(ip) AS nas_ip_sip, 
      counts AS nas_ip_count, 
      name AS pool_name, 
      priority AS pool_priority, 
      static, 
      speed AS pool_speed $fields_v6
   FROM ippools  WHERE id='$id';",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# NAS IP Pools
#
#**********************************************************
sub ip_pools_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID             => 'id',
    POOL_NAME      => 'name',
    NAS_IP_COUNT   => 'counts',
    POOL_PRIORITY  => 'priority',
    NAS_IP_SIP_INT => 'ip',
    STATIC         => 'static',
    POOL_SPEED     => 'speed',
    IPV6_PREFIX    => ($CONF->{IPV6}) ? 'ipv6_prefix' : undef
  );

  $attr->{STATIC} = ($attr->{STATIC}) ? $attr->{STATIC} : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'ippools',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->ip_pools_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "POOL:$attr->{ID}"
    }
  );

  return $self;
}

#**********************************************************
# IP pools list
# add($self)
#**********************************************************
sub ip_pools_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();

  if (defined($attr->{STATIC})) {
    push @WHERE_RULES, "pool.static='$attr->{STATIC}'";

    my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES) : '';
    $self->query2("SELECT '', pool.name, 
   pool.ip, pool.ip + pool.counts AS last_ip_num, pool.counts, pool.priority,
    INET_NTOA(pool.ip) AS first_ip, INET_NTOA(pool.ip + pool.counts) AS last_ip, 
    pool.id, pool.nas
    FROM ippools pool 
    WHERE $WHERE  ORDER BY $SORT $DESC",
    undef,
    $attr
    );
    return $self->{list};
  }

  if (defined($self->{NAS_ID})) {
    push @WHERE_RULES, "pool.nas='$self->{NAS_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "and " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT nas.name, pool.name, 
   pool.ip, pool.ip + pool.counts AS last_ip_num, pool.counts, pool.priority,
    INET_NTOA(pool.ip) AS first_ip, INET_NTOA(pool.ip + pool.counts) AS last_ip, 
    pool.id, pool.nas
    FROM ippools pool, nas 
    WHERE pool.nas=nas.id
    $WHERE  ORDER BY $SORT $DESC",
   undef,
   $attr
  );

  return $self->{list};
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub ip_pools_add {
  my $self   = shift;
  my ($attr) = @_;
  my %DATA   = $self->get_data($attr);

  $attr->{IPV6_PREFIX}  = undef if (! $CONF->{IPV6});

  $self->query_add('ippools', { %$attr, 
 	                             NAS      => undef, 
 	                             IP       => "$DATA{NAS_IP_SIP}", 
 	                             COUNTS   => $attr->{NAS_IP_COUNT}, 
 	                             NAME     => $attr->{POOL_NAME}, 
 	                             PRIORITY => $attr->{POOL_PRIORITY}, 
 	                             SPEED    => $attr->{POOL_SPEED},
 	                           });

  $admin->system_action_add("NAS_ID:$DATA{NAS_ID} POOLS:" . (join(',', split(/, /, $attr->{ids}))), { TYPE => 1 });
  return 0;
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub ip_pools_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM ippools WHERE id='$id'", 'do');

  $admin->system_action_add("POOL:$id", { TYPE => 10 });
  return 0;
}

#**********************************************************
# Statistic
# stats($self)
#**********************************************************
sub stats {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = "WHERE date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m')";

  $SORT = ($attr->{SORT} == 1) ? "1,2"         : $attr->{SORT};
  $DESC = ($attr->{DESC})      ? $attr->{DESC} : '';

  if (defined($attr->{NAS_ID})) {
    $WHERE .= "and id='$attr->{NAS_ID}'";
  }

  $self->query2("select n.name, l.port_id, count(*),
   if(date_format(max(l.start), '%Y-%m-%d')=curdate(), date_format(max(l.start), '%H-%i-%s'), max(l.start)),
   SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)),
   l.nas_id
   FROM dv_log l
   LEFT JOIN nas n ON (n.id=l.nas_id)
   $WHERE
   GROUP BY l.nas_id, l.port_id 
   ORDER BY $SORT $DESC;"
  );

  return $self->{list};
}

#**********************************************************
# Nas Group list
#**********************************************************
sub nas_group_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOMAIN_ID}, 'INT', 'domain_id') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT id, name, comments, disable
  FROM nas_groups
  $WHERE
  ORDER BY $SORT $DESC;",
  undef, 
  $attr
  );

  return $self->{list};
}

#***************************************************************
# nas_group_info($attr);
#***************************************************************
sub nas_group_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if (defined($attr->{ID})) {
    $WHERE = "id='$attr->{ID}'";
  }

  $self->query2("SELECT * FROM nas_groups WHERE $WHERE;",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub nas_group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DISABLE} = (defined($attr->{DISABLE})) ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'nas_groups',
      DATA            => $attr,
      EXT_CHANGE_INFO => "NAS_GROUP_ID:$self->{ID}"
    }
  );

  $self->nas_group_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub nas_group_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  $self->query_add('nas_groups', $attr);

  $admin->system_action_add("NAS_GROUP_ID:$self->{INSERT_ID}", { TYPE => 1 });
  return 0;
}

#**********************************************************
# ADel nas server
# add($self)
#**********************************************************
sub nas_group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM nas_groups WHERE id='$id'", 'do');

  $admin->system_action_add("NAS_GROUP_ID:$id", { TYPE => 10 });
  return 0;
}

1

