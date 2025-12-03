package Equipment;

=head1 NAME

  Equipment managment system

=cut

use strict;
use parent 'dbcore';
use warnings FATAL => 'all';
use Abills::Base qw(int2ip);

my $admin;
my $CONF;

#**********************************************************
# New
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 vendor_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub vendor_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',   'INT', 'id',   1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'SITE', 'STR', 'site', 1 ]
  ],
    { WHERE => 1, });

  my $sql = <<"SQL";
SELECT name, site, support, id
FROM equipment_vendors
$WHERE
SQL

  $self->query_list($sql, $attr);
  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM equipment_vendors $WHERE;", undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 vendor_add($attr)

=cut
#**********************************************************
sub vendor_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_vendors', $attr);

  return $self;
}

#**********************************************************
=head2 vendor_info($id) - Vendor info

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub vendor_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_vendors WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 vendor_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub vendor_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_vendors',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 vendor_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub vendor_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_vendors', { ID => $id });

  return $self;
}

#**********************************************************
=head2 type_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_params = (
    [ 'ID',   'INT', 'id',   1 ],
    [ 'NAME', 'STR', 'name', 1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1, });

  my $sql = <<"SQL";
SELECT name, id
FROM equipment_types
       $WHERE
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 type_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_types', $attr);

  return $self;
}

#**********************************************************
=head2 type_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 type_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub type_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_types', { ID => $id });

  return $self;
}

#**********************************************************
=head2 type_info($id)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_types WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 model_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub model_list {
  my ($self, $attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my $ports_with_extra = << "FIELD";
IF(
        (SELECT
          \@extra_ports := COUNT(*) FROM equipment_extra_ports
          WHERE model_id = m.id
        ) > 0,
        CONCAT(m.ports, "+", \@extra_ports),
        m.ports
      ) AS ports_with_extra
FIELD


  my @search_params = (
    [ 'MODEL_NAME', 'STR', 'm.model_name', 1 ],
    [ 'TYPE_ID', 'INT', 'm.type_id', 1 ],
    [ 'TYPE_NAME', 'STR', 't.name AS type_name', 1 ],
    [ 'VENDOR_ID', 'INT', 'm.vendor_id', 'v.name AS vendor_name' ],
    [ 'PORTS', 'INT', 'm.ports', 1 ],
    [ 'SNMP_TPL', 'STR', 'm.snmp_tpl', 1 ],
    [ 'SYS_OID', 'STR', 'm.sys_oid', 1 ],
    [ 'SITE', 'INT', 'm.site', 1 ],
    [ 'MANAGE_WEB', 'STR', 'm.manage_web', 1 ],
    [ 'MANAGE_SSH', 'STR', 'm.manage_ssh', 1 ],
    [ 'COMMENTS', 'STR', 'm.comments', 1 ],
    [ 'MODEL_ID', 'INT', 'm.id', 1 ],
    [ 'ELECTRIC_POWER', 'INT', 'm.electric_power',   1  ],
    [ 'PORTS_WITH_EXTRA', 'STR', $ports_with_extra,  1  ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $sql = <<"SQL";
SELECT
  m.model_name,
  v.name AS vendor_name,
  $self->{SEARCH_FIELDS}
        m.id
FROM equipment_models m
  LEFT JOIN equipment_types t ON (t.id=m.type_id)
  LEFT JOIN equipment_vendors v ON (v.id=m.vendor_id)
  $WHERE
GROUP BY m.id
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total  FROM equipment_models m  $WHERE;",
      undef, { INFO => 1 }
    );
  }

  return $list || [];
}

#**********************************************************
=head2 model_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub model_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_models', $attr);

  if (!$self->{errno} && $attr->{EXTRA_PORT_TYPES}) {
    $self->extra_port_update({
      MODEL_ID              => $self->{INSERT_ID},
      EXTRA_PORT_TYPES      => $attr->{EXTRA_PORT_TYPES},
      EXTRA_PORT_ROWS       => $attr->{EXTRA_PORT_ROWS},
      EXTRA_PORT_COMBO_WITH => $attr->{EXTRA_PORT_COMBO_WITH}
    });
  }

  return $self;
}

#**********************************************************
=head2 model_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub model_change {
  my ($self, $attr) = @_;

  $attr->{AUTO_PORT_SHIFT} = ($attr->{AUTO_PORT_SHIFT}) ? $attr->{AUTO_PORT_SHIFT} : 0;
  $attr->{FDB_USES_PORT_NUMBER_INDEX} = ($attr->{FDB_USES_PORT_NUMBER_INDEX}) ? $attr->{FDB_USES_PORT_NUMBER_INDEX} : 0;
  $attr->{CONT_NUM_EXTRA_PORTS} = ($attr->{CONT_NUM_EXTRA_PORTS}) ? $attr->{CONT_NUM_EXTRA_PORTS} : 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_models',
    DATA         => $attr
  });

  if (!$self->{errno} && $attr->{EXTRA_PORT_TYPES}) {
    $self->extra_port_update({
      MODEL_ID              => $attr->{ID},
      EXTRA_PORT_TYPES      => $attr->{EXTRA_PORT_TYPES},
      EXTRA_PORT_ROWS       => $attr->{EXTRA_PORT_ROWS},
      EXTRA_PORT_COMBO_WITH => $attr->{EXTRA_PORT_COMBO_WITH}
    });
  }

  return $self;
}

#**********************************************************
=head2 model_del($id)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub model_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_models', { ID => $id });

  return $self;
}

#**********************************************************
=head2 model_info($id) - Get model information

  Arguments:
    $id

  Returns:
    Object
=cut
#**********************************************************
sub model_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_models WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 list($attr) - Equipment list

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my $SECRETKEY = $CONF->{secretkey} || '';

  $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID} if $admin->{DOMAIN_ID};

  my $ports_with_extra = << "FIELD";
IF(
        (SELECT
          \@extra_ports := COUNT(*) FROM equipment_extra_ports
          WHERE model_id = m.id
        ) > 0,
        CONCAT(m.ports, "+", \@extra_ports),
        m.ports
      ) AS ports_with_extra
FIELD

  my @search_params = (
    [ 'TYPE',                          'STR',  't.id',                            1 ],
    [ 'NAS_NAME',                      'STR',  'nas.name', 'nas.name AS nas_name'   ],
    [ 'SYSTEM_ID',                     'STR',  'i.system_id',                     1 ],
    #TYPE_NAME,PORTS
    [ 'TYPE_ID',                       'INT',  'm.type_id',                       1 ],
    [ 'VENDOR_ID',                     'INT',  'm.vendor_id',                     1 ],
    [ 'NAS_TYPE',                      'STR',  'nas.nas_type',                    1 ],
    [ 'MODEL_NAME',                    'STR',  'm.model_name',                    1 ],
    [ 'SNMP_TPL',                      'STR',  'm.snmp_tpl',                      1 ],
    [ 'MODEL_ID',                      'INT',  'i.model_id',                      1 ],
    [ 'VENDOR_NAME',                   'STR',  'v.name', 'v.name AS vendor_name'    ],
    [ 'STATUS',                        'INT',  'i.status',                        1 ],
    [ 'DISABLE',                       'INT',  'nas.disable',                     1 ],
    [ 'TYPE_NAME',                     'INT',  'm.type_id', 't.name AS type_name'   ],
    [ 'PORTS',                         'INT',  'm.ports',                         1 ],
    [ 'PORTS_WITH_EXTRA',              'STR',  $ports_with_extra,                 1 ],
    [ 'MAC',                           'STR',  'nas.mac',                         1 ],
    [ 'PORT_SHIFT',                    'INT',  'm.port_shift',                    1 ],
    [ 'AUTO_PORT_SHIFT',               'INT',  'm.auto_port_shift',               1 ],
    [ 'FDB_USES_PORT_NUMBER_INDEX',    'INT',  'm.fdb_uses_port_number_index',    1 ],
    [ 'EPON_SUPPORTED_ONUS',           'INT',  'm.epon_supported_onus',           1 ],
    [ 'GPON_SUPPORTED_ONUS',           'INT',  'm.gpon_supported_onus',           1 ],
    [ 'GEPON_SUPPORTED_ONUS',          'INT',  'm.gepon_supported_onus',          1 ],
    [ 'DEFAULT_ONU_REG_TEMPLATE_EPON', 'INT',  'm.default_onu_reg_template_epon', 1 ],
    [ 'DEFAULT_ONU_REG_TEMPLATE_GPON', 'INT',  'm.default_onu_reg_template_gpon', 1 ],
    [ 'NAS_IP',                        'IP',   'nas.ip', 'nas.ip AS nas_ip' ],
    [ 'NAS_MNG_HOST_PORT',             'STR',  'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port', ],
    [ 'NAS_MNG_HOST_PORT',             'STR',  'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_host_port', ],
    #['MNG_USER',                      'STR',  'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_USER',                  'STR',  'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_PASSWORD',              'STR',  '', "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password" ],
    [ 'NAS_ID',                        'INT',  'i.nas_id',                        1 ],
    [ 'NAS_GID',                       'INT',  'nas.gid',                         1 ],
    [ 'NAS_GROUP_NAME',                'STR',  'ng.name', 'ng.name AS nas_group_name' ],
    [ 'DISTRICT_ID',                   'INT',  'streets.district_id', 'districts.name' ],
    [ 'STREET_ID',                     'INT',  'streets.id', 'streets.id AS street_id' ],
    [ 'LOCATION_ID',                   'INT',  'nas.location_id',                 1 ],
    [ 'DOMAIN_ID',                     'INT',  'nas.domain_id',                   1 ],
    [ 'DOMAIN_NAME',                   'INT',  'domains.name', 'domains.name AS domain_name' ],
    [ 'COORDX',                        'INT',  'builds.coordx',                   1 ],
    [ 'COORDY',                        'INT',  'builds.coordy',                   1 ],
    [ 'REVISION',                      'STR',  'i.revision',                      1 ],
    [ 'SNMP_VERSION',                  'STR',  'i.snmp_version',                  1 ],
    [ 'SERVER_VLAN',                   'STR',  'i.server_vlan',                   1 ],
    [ 'LAST_ACTIVITY',                 'DATE', 'i.last_activity',                 1 ],
    [ 'INTERNET_VLAN',                 'STR',  'i.internet_vlan',                 1 ],
    [ 'TR_069_VLAN',                   'STR',  'i.tr_069_vlan',                   1 ],
    [ 'IPTV_VLAN',                     'STR',  'i.iptv_vlan',                     1 ],
    [ 'NAS_DESCR',                     'STR',  'nas.descr AS nas_descr',          1 ],
    [ 'NAS_IDENTIFIER',                'STR',  'nas.nas_identifier',              1 ],
    [ 'NAS_ALIVE',                     'INT',  'nas.alive AS nas_alive',          1 ],
    [ 'NAS_RAD_PAIRS',                 'STR',  'nas.rad_pairs', 'nas.rad_pairs AS nas_rad_pairs', 1 ],
    [ 'NAS_ENTRANCE',                  'STR',  'nas.entrance', 'nas.entrance AS nas_entrance',    1 ],
    [ 'ZABBIX_HOSTID',                 'INT',  'nas.zabbix_hostid',               1 ],
    [ 'WIDTH',                         'INT',  'm.width',                         1 ],
    [ 'HEIGHT',                        'INT',  'm.height',                        1 ],
    [ 'CONT_NUM_EXTRA_PORTS',          'INT',  'm.cont_num_extra_ports',          1 ],
    [ 'USERS',                         'INT',  'COUNT(im.uid)',            'COUNT(im.uid) AS users' ],
    [ 'USERS_ONLINE',                  'INT',  'COUNT(io.uid)',     'COUNT(io.uid) AS users_online' ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my %EXT_TABLE_JOINS_HASH = ();

  if ($WHERE . $self->{SEARCH_FIELDS} =~ /nas\./xm) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
  }

  if ($attr->{COORDX} || $attr->{COORDY}) {
    $EXT_TABLE_JOINS_HASH{builds} = 1;
  }

  if ($attr->{ADDRESS_FULL}) {
    my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
    my @fields = @{$self->search_expr($attr->{ADDRESS_FULL}, "STR", "CONCAT(districts.name, '$build_delimiter', streets.name, '$build_delimiter', builds.number) AS address_full", { EXT_FIELD => 1 })};

    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $EXT_TABLE_JOINS_HASH{disctrict} = 1;
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
    $self->{SEARCH_FIELDS} .= $self->{SEARCH_FIELDS} =~ /\s?,\s?$/xgm ? '' : ', ';
  }

  if ($attr->{NAS_GROUP_NAME}) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{nas_gid} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN                                    => [ 'nas:LEFT JOIN nas ON (nas.id=i.nas_id)',
      'nas_gid:LEFT JOIN nas_groups ng ON (ng.id=nas.gid)',
      'builds:LEFT JOIN builds ON (builds.id=nas.location_id)',
      'streets:LEFT JOIN streets ON (streets.id=builds.street_id)',
      'disctrict:LEFT JOIN districts ON (districts.id=streets.district_id)',
    ],
    EXTRA_PRE_ONLY                                    => 1,
  });

  $EXT_TABLES .= "LEFT JOIN domains on (domains.id=nas.domain_id)" if $attr->{DOMAIN_NAME};
  $EXT_TABLES .= "LEFT JOIN internet_main im ON (im.nas_id=i.nas_id)" if $attr->{USERS};
  $EXT_TABLES .= "LEFT JOIN internet_online io ON (io.uid=im.uid)" if $attr->{USERS};

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
        m.id,
        i.nas_id
FROM equipment_infos i
  INNER JOIN equipment_models m ON (m.id=i.model_id)
  INNER JOIN equipment_types t ON (t.id=m.type_id)
  INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
  $EXT_TABLES
  $WHERE
GROUP BY i.nas_id
SQL

  $self->query_list($sql, $attr);

  if ($self->{TOTAL} > 0) {
    foreach my $eq (@{$self->{list}}) {
      if (ref $eq eq 'HASH' && $eq->{nas_ip}) {
        my $nas_ip = int2ip($eq->{nas_ip});
        $eq->{nas_ip} = $nas_ip;
        $eq->{NAS_IP} = $nas_ip if ($attr->{COLS_UPPER});
      }
    }
  }

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $sql = <<"SQL";
    SELECT COUNT( DISTINCT i.nas_id) AS total
      FROM equipment_infos i
      INNER JOIN equipment_models m ON (m.id=i.model_id)
      INNER JOIN equipment_types t ON (t.id=m.type_id)
      INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
      $EXT_TABLES
      $WHERE;
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list || [];
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_infos', $attr);

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

  $self->changes({
    CHANGE_PARAM => 'NAS_ID',
    TABLE        => 'equipment_infos',
    DATA         => $attr,
    SKIP_LOG     => ($attr->{SKIP_LOG} ? 1 : 0),
  });

  return $self;
}

#**********************************************************
=head2 del($id) - delete equipment and its data from all equipment tables

  Arguments:
    $id - NAS_ID

  Returns:
    $self

=cut
#**********************************************************
sub del {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
DELETE tr_069
FROM equipment_tr_069_settings tr_069
       INNER JOIN equipment_pon_onu onu ON tr_069.onu_id = onu.id
       INNER JOIN equipment_pon_ports p ON onu.port_id = p.id
WHERE p.nas_id = ?;
SQL

  $self->query($sql, undef, { Bind => [ $id ] });

  $sql = <<'SQL';
DELETE onu
FROM equipment_pon_onu onu
       INNER JOIN equipment_pon_ports p ON onu.port_id = p.id
WHERE p.nas_id = ?;
SQL


  $self->query($sql, undef, { Bind => [ $id ] });

  $self->query_del('equipment_pon_ports', undef, { nas_id => $id });

  $self->query_del('equipment_ports', undef, { nas_id => $id });
  $self->query('UPDATE equipment_ports SET uplink = 0 WHERE uplink = ?', undef,
    { Bind => [ $id ] }
  );

  $self->query_del('equipment_mac_log', undef, { nas_id => $id });

  $self->query_del('equipment_ping_log', undef, { nas_id => $id });

  $self->query_del('equipment_graphs', undef, { nas_id => $id });

  $self->query_del('equipment_backup', undef, { nas_id => $id });

  $self->query_del('equipment_infos', undef, { nas_id => $id });

  return $self;
}

#**********************************************************
=head2 info($id, $attr) - Equipment unit information

  Arguments:
    $id
    $attr

  Returns:
    Object

=cut
#**********************************************************
sub info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
SELECT equipment_infos.*,
       IF(
         (SELECT
            @extra_ports := COUNT(*) FROM equipment_extra_ports
          WHERE equipment_infos.model_id = equipment_extra_ports.model_id
         ) > 0,
         CONCAT(m.ports, '+', @extra_ports),
         m.ports
       ) AS ports_with_extra
FROM equipment_infos
       LEFT JOIN equipment_models m ON (m.id=equipment_infos.model_id)
WHERE equipment_infos.nas_id= ? ;
SQL

  $self->query($sql,
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 port_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_list {
  my ($self, $attr) = @_;

  $self->{SEARCH_FIELDS} = '';
  $self->{EXT_TABLES} = '';

  my @search_params = (
    [ 'ADMIN_PORT_STATUS', 'INT', 'p.status', 'p.status AS admin_port_status' ],
    [ 'UPLINK',   'INT', 'p.uplink', 1 ],
    [ 'STATUS',   'INT', 'p.status', 1 ],
    [ 'PORT_COMMENTS', 'INT', 'p.comments', 'p.comments AS port_comments' ],
    [ 'PORT',     'INT', 'p.port', 1 ],
    [ 'VLAN',     'INT', 'p.vlan', 1 ],
    [ 'DATETIME', 'DATE','p.datetime',  1 ],
    [ 'NAS_ID',   'INT', 'p.nas_id', ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1 });

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\.|u\.|tp\.|internet\./xm || $WHERE =~ /pi\.|u\.|tp\.|internet\./xm) {
    $EXT_TABLE = "LEFT JOIN users u ON (u.uid=dhcp.uid)" . $EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /internet\./xm || $WHERE =~ /internet\./xm) {
    $EXT_TABLE .= << "EXT_TABLE";
  LEFT JOIN internet_main internet ON (internet.uid=u.uid)
  LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
EXT_TABLE
  }

  my $sql = <<"SQL";
SELECT p.port,
       $self->{SEARCH_FIELDS}
   p.nas_id,
   p.id
FROM equipment_ports p
  $EXT_TABLE
  $WHERE
GROUP BY p.port
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0 && !$attr->{_SKIP_TOTAL}) {
    $sql = <<"SQL";
    SELECT COUNT(*) AS total
    FROM equipment_ports p
    $EXT_TABLE
    $WHERE;
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 port_list_without_group_by($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_list_without_group_by {
  my ($self, $attr) = @_;

  $self->{SEARCH_FIELDS} = '';
  $self->{EXT_TABLES} = '';

  my @search_params = (
    [ 'ADMIN_PORT_STATUS', 'INT', 'p.status', 'p.status AS admin_port_status' ],
    [ 'UPLINK', 'INT', 'p.uplink', 1 ],
    [ 'STATUS', 'INT', 'p.status', 1 ],
    [ 'PORT_COMMENTS', 'INT', 'p.comments', 'p.comments AS port_comments' ],
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'NAS_ID', 'INT', 'p.nas_id', ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\.|u\.|tp\.|internet\./xm || $WHERE =~ /pi\.|u\.|tp\.|internet\./xm) {
    $EXT_TABLE = "LEFT JOIN users u ON (u.uid=dhcp.uid)" . $EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /internet\./xm || $WHERE =~ /internet\./xm) {
    $EXT_TABLE .= << "EXT_TABLES";
   LEFT JOIN internet_main internet ON (internet.uid=u.uid)
   LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
EXT_TABLES
  }

  my $sql = <<"SQL";
SELECT p.port,
       $self->{SEARCH_FIELDS}
   p.nas_id,
   p.id
FROM equipment_ports p
  $EXT_TABLE
  $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0 && !$attr->{_SKIP_TOTAL}) {
    $sql = <<"SQL";
SELECT COUNT(*) AS total  FROM equipment_ports p
  $EXT_TABLE
  $WHERE;
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2  port_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_add {
  my ($self, $attr) = @_;

  delete $attr->{ID};
  $self->query_add('equipment_ports', $attr);

  return $self;
}

#**********************************************************
=head2 port_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_ports',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 port_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub port_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_ports', { ID => $id });

  return $self;
}

#**********************************************************
=head2 port_del_nas($id)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_del_nas {
  my ($self, $attr) = @_;

  $self->query_del('equipment_ports', {}, { NAS_ID => $attr->{NAS_ID} });

  return $self;
}

#**********************************************************
=head2 port_info($attr)

  Argumnets:
    $attr
      NAS_ID
      PORT

  Results:
    $self

=cut
#**********************************************************
sub port_info {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
SELECT *
FROM equipment_ports
WHERE nas_id = ? AND port = ? ;
SQL

  $self->query($sql,
    undef,
    { INFO => 1,
      Bind => [
        $attr->{NAS_ID},
        $attr->{PORT}
      ]
    }
  );

  return $self;
}

#**********************************************************
=head2 equipment_box_type_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_type_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_box_types', $attr);
  return [] if ($self->{errno});

  $admin->system_action_add("card TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 equipment_box_type_info()

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_type_info {
  my ($self, $id) = @_;

  $self->query('SELECT * FROM equipment_box_types WHERE id= ? ;',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 equipment_box_type_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_type_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_box_types', { ID => $id });

  return [] if ($self->{errno});

  $admin->system_action_add("card TYPES: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 equipment_box_type_change($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_type_change {
  my ($self, $attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_box_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 equipment_box_type_list($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_type_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'MARKING', 'STR', 'marking', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT marking, vendor, units, width, hieght, length, diameter, id
FROM equipment_box_types
$WHERE
SQL

  $self->query_list($sql, $attr);

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_box_types $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 equipment_box_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_boxes', $attr);
  return [] if ($self->{errno});

  $admin->system_action_add("card TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 equipment_box_info($attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_boxes WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 equipment_box_del($attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_boxes', { ID => $id });

  return [] if ($self->{errno});

  $admin->system_action_add("card: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 equipment_box_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_change {
  my ($self, $attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_boxes',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 equipment_box_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_box_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'SERIAL', 'STR', 'serial', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT b.serial, bt.marking, b.datetime, b.id
FROM equipment_boxes b
LEFT JOIN equipment_box_types bt ON (b.type_id=bt.id)
$WHERE
SQL


  $self->query_list($sql, $attr);

  return [] if ($self->{errno});

  my $list = $self->{list} || [];

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_box_types $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 extra_port_update($attr)

  Arguments:
    $attr
      MODEL_ID              - Model ID to change ports
      EXTRA_PORT_TYPES      - hash_ref  port number => type
      EXTRA_PORT_ROWS       - hash_ref  port_number => row
      EXTRA_PORT_COMBO_WITH - hash_ref  port_number => combo_with

  Returns:
    $self

=cut
#**********************************************************
sub extra_port_update {
  my ($self, $attr) = @_;

  #clear and update
  $self->{db}{AutoCommit} = 0;
  $self->query_del('equipment_extra_ports', undef,
    {
      MODEL_ID => $attr->{MODEL_ID}
    }
  );

  while (my ($port_number, $port_type) = each %{$attr->{EXTRA_PORT_TYPES}}) {
    $self->query_add('equipment_extra_ports',
      {
        MODEL_ID        => $attr->{MODEL_ID},
        PORT_NUMBER     => $port_number,
        PORT_TYPE       => $port_type,
        ROW             => $attr->{EXTRA_PORT_ROWS}->{$port_number},
        PORT_COMBO_WITH => $attr->{EXTRA_PORT_COMBO_WITH}->{$port_number}
      }
    );
  }

  $self->{db}{AutoCommit} = 1;

  return $self;
}

#**********************************************************
=head2 extra_ports_list($id)

  Arguments:
    $id - Id of model

  Returns:
    DB_LIST

=cut
#**********************************************************
sub extra_ports_list {
  my ($self, $id) = @_;

  $self->query_list("SELECT * FROM equipment_extra_ports WHERE model_id= ?", { Bind => [ $id ] });

  return $self->{list} || [];
}

#**********************************************************
=head2 vlan_add($attr) - add vlan to db

  Arguments:
     $attr

  Returns:

  Example:
    $Equipment->vlan_add({%FORM});

=cut
#**********************************************************
sub vlan_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_vlans', $attr);

  return $self;
}

#**********************************************************
=head2 vlan_change($attr) - change info about vlan

  Arguments:

  Returns:

  Example:
    $Equipment->vlan_change({ID => $FORM{id}, %FORM});

=cut
#**********************************************************
sub vlan_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_vlans',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 vlan_del($attr) - delete vlan from db

  Arguments:
    $attr

  Returns:

  Example:
    $Equipment->vlan_del({ID => $FORM{del}});

=cut
#**********************************************************
sub vlan_del {
  my ($self, $attr) = @_;

  $self->query_del('equipment_vlans', $attr);

  return $self;
}

#**********************************************************
=head2 vlan_info($attr) - get vlan info

  Arguments:
    $attr

  Returns:
    $self

  Example:
    $vlan_info = $Equipment->vlan_info({ID => $FORM{chg}});

=cut
#**********************************************************
sub vlan_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    $self->query("SELECT * FROM equipment_vlans  WHERE id = ?;", undef,
      { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 vlan_list($attr) - get vlans list

  Arguments:
    $attr

  Returns:
    $list
  Example:
    my $vlan_list = $Equipment->vlan_list({COLS_NAME => 1});

=cut
#**********************************************************
sub vlan_list {
  my ($self, $attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
SELECT *
FROM equipment_vlans
$WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  if($self->{TOTAL} && $self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM equipment_vlans",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 trap_add

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub trap_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_traps', {
    %$attr,
    TRAPTIME => 'NOW()',
  });

  return $self;
}

#**********************************************************
=head2 traps_del($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub traps_del {
  my ($self, $attr) = @_;

  $self->query("DELETE FROM equipment_traps WHERE traptime < CURDATE() - INTERVAL ? day;", 'do',
    { Bind => $attr->{PERIOD} || 30 });

  return $self;
}

#**********************************************************
=head2 trap_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub trap_list {
  my ($self, $attr) = @_;
  my $GROUP = ($attr->{GROUP}) ? "GROUP BY $attr->{GROUP}" : '';

  my @search_params = (
    [ 'TRAP_ID', 'STR', 'e.id', ],
    [ 'TRAPTIME', 'STR', 'traptime', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'NAS_IP', 'STR', 'nas_ip', 'INET_NTOA(e.ip) AS nas_ip', ],
    [ 'EVENTNAME', 'STR', 'eventname', 1 ],
    [ 'VARBINDS', 'STR', 'varbinds', 1 ],
    [ 'TRAPOID', 'STR', 'trapoid', 1 ],
    [ 'NAS_ID', 'STR', 'nas.id', 'nas.id AS nas_id', ],
    [ 'DOMAIN_ID', 'STR', 'nas.domain_id', ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} e.id AS trap_id
FROM equipment_traps e
  INNER JOIN nas ON (nas.ip=e.ip)
  $WHERE
  $GROUP
SQL

  $self->query_list($sql, $attr);

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{MONIT}) {
    $sql = <<"SQL";
SELECT COUNT(e.id) AS total
FROM equipment_traps e
       INNER JOIN nas ON (nas.ip=e.ip)
  $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }
  return $self->{list_hash} if ($attr->{LIST2HASH});

  return $list;
}

#**********************************************************
=head2 cvlan_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub cvlan_list {
  my ($self, $attr) = @_;

  my $SECRETKEY = $CONF->{secretkey} || '';

  if ($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my @search_params = (
    [ 'TYPE', 'STR', 't.id', 1 ],
    [ 'NAS_NAME', 'STR', 'nas.name', 'nas.name AS nas_name' ],
    [ 'SYSTEM_ID', 'STR', 'i.system_id', 1 ],
    [ 'TYPE_ID', 'INT', 'm.type_id', 1 ],
    [ 'VENDOR_ID', 'INT', 'm.vendor_id', 1 ],
    [ 'NAS_TYPE', 'STR', 'nas.nas_type', 1 ],
    [ 'MODEL_NAME', 'STR', 'm.model_name', 1 ],
    [ 'SNMP_TPL', 'STR', 'm.snmp_tpl', 1 ],
    [ 'MODEL_ID', 'INT', 'i.model_id', 1 ],
    [ 'VENDOR_NAME', 'STR', 'v.name', 'v.name AS vendor_name' ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id' ],
    [ 'STATUS', 'INT', 'i.status', 1 ],
    [ 'DISABLE', 'INT', 'nas.disable', 1 ],
    [ 'TYPE_NAME', 'INT', 'm.type_id', 't.name AS type_name', 1 ],
    [ 'NAME_TYPE', 'STR', 't.name', 1 ],
    [ 'PORTS', 'INT', 'm.ports', 1 ],
    [ 'MAC', 'INT', 'nas.mac', 1 ],
    [ 'PORT_SHIFT', 'INT', 'm.port_shift', 1 ],
    [ 'NAS_IP', 'IP', 'nas.ip', 'INET_NTOA(nas.ip) AS nas_ip' ],
    [ 'NAS_MNG_HOST_PORT', 'STR', 'nas.mng_host_port', 'nas.mng_host_port AS nas_mng_ip_port', ],
    #['MNG_USER',         'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_USER', 'STR', 'nas.mng_user', 'nas.mng_user as nas_mng_user', ],
    [ 'NAS_MNG_PASSWORD', 'STR', '', "DECODE(nas.mng_password, '$SECRETKEY') AS nas_mng_password" ],
    [ 'NAS_ID', 'INT', 'i.nas_id', 1 ],
    [ 'NAS_GID', 'INT', 'nas.gid', 1 ],
    [ 'NAS_GROUP_NAME', 'STR', 'ng.name', 'ng.name AS nas_group_name' ],
    [ 'DISTRICT_ID', 'INT', 'streets.district_id', 'districts.name' ],
    [ 'LOCATION_ID', 'INT', 'nas.location_id', 1 ],
    [ 'DOMAIN_ID', 'INT', 'nas.domain_id', 1 ],
    [ 'COORDX', 'INT', 'builds.coordx', 1 ],
    [ 'COORDY', 'INT', 'builds.coordy', 1 ],
    [ 'REVISION', 'STR', 'i.revision', 1 ],
    [ 'SNMP_VERSION', 'STR', 'i.snmp_version', 1 ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan', 1 ],
    [ 'LAST_ACTIVITY', 'DATE', 'i.last_activity', 1 ],
    [ 'INTERNET_VLAN', 'STR', 'i.internet_vlan', 1 ],
    [ 'TR_069_VLAN', 'STR', 'i.tr_069_vlan', 1 ],
    [ 'IPTV_VLAN', 'STR', 'i.iptv_vlan', 1 ],
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'STATUS', 'INT', 'p.status', 1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my %EXT_TABLE_JOINS_HASH = ();

  if ($WHERE . $self->{SEARCH_FIELDS} =~ /nas\./xm) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
  }

  if ($attr->{COORDX} || $attr->{COORDY}) {
    $EXT_TABLE_JOINS_HASH{builds} = 1;
  }

  if ($attr->{ADDRESS_FULL}) {
    my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
    my @fields = @{$self->search_expr($attr->{ADDRESS_FULL}, "STR", "CONCAT(streets.name, '$build_delimiter', builds.number) AS address_full", { EXT_FIELD => 1 })};

    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{builds} = 1;
    $EXT_TABLE_JOINS_HASH{streets} = 1;
    $EXT_TABLE_JOINS_HASH{disctrict} = 1;
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  if ($attr->{NAS_GROUP_NAME}) {
    $EXT_TABLE_JOINS_HASH{nas} = 1;
    $EXT_TABLE_JOINS_HASH{nas_gid} = 1;
  }

  my $EXT_TABLES = $self->mk_ext_tables({ JOIN_TABLES => \%EXT_TABLE_JOINS_HASH,
    EXTRA_PRE_JOIN                                    => [ 'nas:LEFT JOIN nas ON (nas.id=i.nas_id)',
      'nas_gid:LEFT JOIN nas_groups ng ON (ng.id=nas.gid)',
      'builds:LEFT JOIN builds ON (builds.id=nas.location_id)',
      'streets:LEFT JOIN streets ON (streets.id=builds.street_id)',
      'disctrict:LEFT JOIN districts ON (districts.id=streets.district_id)',
    ],
    EXTRA_PRE_ONLY                                    => 1,
  });

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
        m.id,
        i.nas_id
FROM equipment_infos i
  INNER JOIN equipment_models m ON (m.id=i.model_id)
  INNER JOIN equipment_types t ON (t.id=m.type_id)
  INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
  INNER JOIN equipment_ports p ON (i.nas_id=p.nas_id)
  $EXT_TABLES
  $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $sql = <<"SQL";
SELECT COUNT(*) AS total
FROM equipment_infos i
       INNER JOIN equipment_models m ON (m.id=i.model_id)
       INNER JOIN equipment_types t ON (t.id=m.type_id)
       INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
  $EXT_TABLES
  $WHERE;
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 cvlan_svlan_list($attr)

  Arguments:
    $attr
  Results:
    $self
  
=cut
#**********************************************************
sub cvlan_svlan_list {
  my ($self, $attr) = @_;

  my @search_params = (
    [ 'PORT', 'INT', 'p.port', 1 ],
    [ 'NAS_NAME', 'STR', 'n.name', 1 ],
    [ 'VLAN', 'INT', 'p.vlan', 1 ],
    [ 'NAS_ID', 'INT', 'i.nas_id', ],
    [ 'SERVER_VLAN', 'STR', 'i.server_vlan', 1 ],
    [ 'ONU_VLAN', 'STR', 'onu.vlan', 1 ],
    [ 'ONU_DHCP_PORT', 'STR', 'onu.onu_dhcp_port', 1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  if ($attr->{ONU}) {
    my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
      i.nas_id,
      onu.onu_dhcp_port,
      onu.vlan,
      i.server_vlan
FROM equipment_pon_onu onu
  INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
  INNER JOIN nas n ON (n.id=p.nas_id)
  LEFT JOIN equipment_infos i ON (i.nas_id=n.id)
  $WHERE;
SQL

    $self->query($sql, undef, { COLS_NAME => 1, COLS_UPPER => 1 });
  }
  else {
    my $sql = <<"SQL";
    SELECT
      $self->{SEARCH_FIELDS}
      i.nas_id,
      p.port,
      p.vlan,
      i.server_vlan
      FROM equipment_ports p
      INNER JOIN nas n ON (n.id=p.nas_id)
      LEFT JOIN equipment_infos i ON (i.nas_id=n.id)
      $WHERE;
SQL

    $self->query($sql, undef, { COLS_NAME => 1, COLS_UPPER => 1 });
  }

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 graph_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub graph_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_params = (
    [ 'OBJ_ID',   'INT', 'obj_id', 1 ],
    [ 'PORT',     'STR', 'port',   1 ],
    [ 'PARAM',    'STR', 'param',  1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],
    [ 'DATE',     'STR', 'date',   1 ],
    [ 'NAS_ID',   'INT', 'nas_id', 1 ],
    [ 'MEASURE_TYPE', 'STR', 'measure_type', 1 ],
    [ 'NAME',     'STR', 'name',   1 ],
    [ 'TYPE',     'STR', 'type',   1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} g.id, nas_id
FROM equipment_graphs g
  INNER JOIN equipment_snmp_params p ON (p.id=g.param)
  $WHERE
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list};
}

#**********************************************************
=head2 graph_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub graph_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_graphs', {
    %$attr,
    DATE => 'NOW()',
  });

  return $self;
}

#**********************************************************
=head2 graph_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub graph_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_graphs',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 graph_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub graph_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_graphs', { ID => $id });

  return $self;
}

#**********************************************************
=head2 graph_info($id, $attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub graph_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_graphs WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 mac_log_list($attr)

  Arguments:
    $attr
      ONLY_CURRENT - return only MAC's that are currently on Equipment, i. e. datetime > rem_time
      SKIP_ORDER - Skip order in SQL

  Returns:
    $mac_list

=cut
#**********************************************************
sub mac_log_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 50;

  my $GROUP_BY = '';
  if ($attr->{GROUP_BY}) {
    $GROUP_BY = 'GROUP BY ' . $attr->{GROUP_BY};
  }

  if ($attr->{NAS_ID} && $attr->{SORT} && $attr->{SORT} == 1) {
    $SORT = 'LPAD(port, 6, 0)';
  }

  my @search_params = (
    [ 'PORT',         'STR', 'ml.port',      1 ],
    [ 'PORT_NAME',    'STR', 'ml.port_name', 1 ],
    [ 'MAC',          'STR', 'ml.mac',    1 ],
    [ 'IP',           'IP',  'ml.ip', 'INET_NTOA(ml.ip) AS ip' ],
    [ 'VLAN',         'INT', 'ml.vlan',      1 ],
    [ 'DATETIME',     'STR', 'ml.datetime',  1 ],
    [ 'REM_TIME',     'STR', 'ml.rem_time',  1 ],
    [ 'UNIX_DATETIME','STR', 'ml.datetime', 'unix_timestamp(ml.datetime) AS unix_datetime' ],
    [ 'UNIX_REM_TIME','STR', 'ml.rem_time', 'unix_timestamp(ml.rem_time) AS unix_rem_time' ],
    [ 'NAS_ID',       'INT', 'ml.nas_id',    1 ],
    [ 'NAS_NAME',     'STR', 'nas.name',  'nas.name AS nas_name' ],
    [ 'MAC_UNIQ_COUNT','STR', '', 'COUNT(DISTINCT ml.mac) AS mac_uniq_count' ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1 });

  my $EXT_TABLES = q{};

  if($attr->{NAS_NAME}) {
    $EXT_TABLES = "LEFT JOIN nas ON (nas.id=ml.nas_id)";
  }

  if ($attr->{ONLY_CURRENT}) {
    $WHERE .= ' AND datetime > rem_time';
  }

  if ($attr->{USER_NAS}) {
    my @fields = @{$self->search_expr("$attr->{USER_NAS}", "STR", "CONCAT('--') AS user_nas", { EXT_FIELD => 1 })};
    $self->{SEARCH_FIELDS} .= join(', ', @fields);
  }

  my $ORDER = "ORDER BY $SORT $DESC";
  if ($attr->{SKIP_ORDER}) {
    $ORDER = '';
  }

  my $sql = <<"SQL";
  SELECT
    $self->{SEARCH_FIELDS} ml.id AS id
    FROM equipment_mac_log ml
    $EXT_TABLES
    $WHERE
    $GROUP_BY
    $ORDER
    LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM equipment_mac_log ml $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 mac_flood_search($attr)

  Arguments:
    MIN_COUNT

  Results:
    $list

=cut
#**********************************************************
sub mac_flood_search {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
SELECT PORT, NAS_ID, NAME, COUNT(port) as CNT
FROM equipment_mac_log
       LEFT JOIN nas n ON (n.id=nas_id)
WHERE rem_time < datetime
GROUP BY port, nas_id HAVING CNT >= ? ;
SQL


  $self->query($sql,
    undef,
    { Bind => [ $attr->{MIN_COUNT} ] }
  );

  my $list = $self->{list};
  return $list || [];
}

#**********************************************************
=head2 mac_log_add($attr)

  Arguments:
    $attr

  Results:
    $slf

=cut
#**********************************************************
sub mac_log_add {
  my ($self, $attr) = @_;

  if ($attr->{MULTI_QUERY}) {
    #REPLACE - if there will be duplicates, don't raise UNIQUE KEY error
    my $sql = <<'SQL';
REPLACE INTO equipment_mac_log (
  mac,
  nas_id,
  vlan,
  port,
  port_name,
  datetime
) VALUES (?, ?, ?, ?, ?, NOW());
SQL

    $self->query($sql,
      undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} });
  }

  return $self;
}

#**********************************************************
=head2 mac_log_change($attr) - change mac_log's entry rem_time or port_name/datetime

  Arguments:
    $attr
      REM_TIME - update rem_time with current time instead of datetime
      MULTI_QUERY - array of arrays:
                    [ [ $id ], ... ] - if REM_TIME is set
                    or
                    [ [ $port_name, $id ], ... ] - if REM_TIME is not set

  Results:
    $self

=cut
#**********************************************************
sub mac_log_change {
  my ($self, $attr) = @_;

  my $time = ($attr->{REM_TIME}) ? "rem_time" : "datetime";
  my $port_name = (($attr->{REM_TIME}) ? '' : ', port_name = ? ');

  if ($attr->{MULTI_QUERY}) {
    my $sql = <<"SQL";
UPDATE equipment_mac_log SET
  $time = NOW()
      $port_name
      WHERE id= ? ;
SQL

    $self->query($sql, undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} }
    );
  }

  return $self;
}

#**********************************************************
=head2 mac_notif_add($attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub mac_notif_add {
  my ($self, $attr) = @_;

  my $time = ($attr->{DATETIME}) ? 'datetime' : 'rem_time';

  my $sql = <<"SQL";
INSERT INTO equipment_mac_log (mac, nas_id, vlan, port, port_name $time) VALUES
  ('$attr->{MAC}', '$attr->{NAS_ID}', '$attr->{VLAN}', '$attr->{PORT}', '$attr->{PORT_NAME}', NOW())
ON DUPLICATE KEY UPDATE $time=NOW();
SQL

  $self->query($sql, 'do');

  return $self;
}

#**********************************************************
=head2 mac_log_del($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub mac_log_del {
  my ($self, $attr) = @_;

  if ($attr->{DEL_PERIOD}) {
    $self->query("DELETE FROM equipment_mac_log WHERE datetime < CURDATE() - INTERVAL ? DAY; ",
      "do", { Bind => [ $attr->{DEL_PERIOD} ] });
  }
  else {
    $self->query_del('equipment_mac_log', $attr, (($attr->{NAS_ID}) ? $attr : undef), { CLEAR_TABLE => $attr->{ALL} });
  }

  return $self;
}

#**********************************************************
=head2 onu_list($attr) -
 Pay attention to DELETED param - you may want only ONUs without DELETED flag

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{RX_POWER_SIGNAL}){
    my $level_max_bad = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MAX} : -8;
    my $level_min_bad = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MIN} : -30;
    my $level_max_worth = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{WORTH}{MAX} : -10;
    my $level_min_worth = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{WORTH}{MIN} : -27;

    if ($attr->{RX_POWER_SIGNAL} eq 'BAD'){
    push @WHERE_RULES, "(onu.onu_rx_power < 0 AND (onu.onu_rx_power > $level_max_bad OR onu.onu_rx_power < $level_min_bad))";
    }
    elsif ($attr->{RX_POWER_SIGNAL} eq 'WORTH') {
      push @WHERE_RULES, << "WHERE";
(onu.onu_rx_power < 0 AND (
      onu.onu_rx_power > $level_max_worth AND onu.onu_rx_power < $level_max_bad
      OR onu.onu_rx_power < $level_min_worth AND onu.onu_rx_power > $level_min_bad))
WHERE
    }
  }

  $self->{SEARCH_FIELDS} = '';
  $attr->{SKIP_DEL_CHECK}= 1;
  $attr->{SKIP_GID} = 1;

  my @search_params = (
    [ 'BRANCH',           'STR', 'p.branch',                      1 ],
    [ 'BRANCH_DESC',      'STR', 'p.branch_desc',                 1 ],
    [ 'VLAN_ID',          'STR', 'p.vlan_id',                     1 ],
    #    [ 'VLAN_ID',      'STR', 'onu.vlan', 1 ],
    [ 'ONU_ID',           'STR', 'onu.onu_id',                    1 ],
    [ 'ID',               'STR', 'onu.id',  'onu.id AS ID'          ],
    [ 'ONU_VLAN',         'STR', 'onu.vlan',                      1 ],
    [ 'MAC_SERIAL',       'STR', 'onu.onu_mac_serial', 'onu.onu_mac_serial AS mac_serial' ],
    [ 'ONU_DESC',         'STR', 'onu.onu_desc', 'onu.onu_desc AS onu_desc' ],
    [ 'ONU_BILLING_DESC', 'STR', 'onu.onu_billing_desc',          1 ],
    [ 'OLT_RX_POWER',     'STR', 'onu.olt_rx_power',              1 ],
    [ 'RX_POWER',         'STR', 'onu.onu_rx_power', 'onu.onu_rx_power AS rx_power' ],
    [ 'TX_POWER',         'STR', 'onu.onu_tx_power', 'onu.onu_tx_power AS tx_power' ],
    [ 'STATUS',           'INT', 'onu.onu_status', 'onu.onu_status AS status' ],
    [ 'ONU_DHCP_PORT',    'STR', 'onu.onu_dhcp_port',             1 ],
    [ 'ONU_GRAPH',        'STR', 'onu.onu_graph',                 1 ],
    [ 'NAS_ID',           'STR', 'p.nas_id',                      0 ],
    [ 'NAS_NAME',         'STR', 'n.name', 'n.name AS nas_name'     ],
    [ 'NAS_IP',           'STR', 'INET_NTOA(n.ip) AS nas_ip',     1 ],
    [ 'PON_TYPE',         'STR', 'p.pon_type',                    0 ],
    [ 'OLT_PORT',         'STR', 'p.id',                          0 ],
    [ 'ONU_SNMP_ID',      'INT', 'onu.onu_snmp_id',               1 ],
    [ 'DATETIME',         'DATE','onu.datetime',                  1 ],
    [ 'DELETED',          'INT', 'onu.deleted',                   1 ],
    [ 'SERVER_VLAN',      'STR', 'i.server_vlan',                 1 ],
    [ 'TARIFF_PLAN',      'STR', 'tp.name AS tariff_plan',        1 ],
    [ 'ONU_TYPE',         'STR', 'onu.onu_type',                  1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, {
    WHERE             => 1,
    USERS_FIELDS      => ($attr->{SKIP_USER_INFO}) ? undef : 1,
    USE_USER_PI       => 1,
    SKIP_USERS_FIELDS => [ 'LOGIN', 'DOMAIN_ID' ],
    WHERE_RULES       => \@WHERE_RULES,
  });

  if ($attr->{GID}) {
    $WHERE .= ' AND (' . (join ' OR ', @{$self->search_expr($attr->{GID}, 'INT', 'u.gid')}, 'u.gid IS NULL') . ')';
  }

  my %reserved_fields = (
    TRAFFIC              => "CONCAT(onu.onu_in_byte, ',', onu.onu_out_byte) AS traffic",
    LOGIN                => "CONCAT('--') AS login",
    USER_MAC             => "CONCAT('--') AS user_mac",
    MAC_BEHIND_ONU       => "CONCAT('--') AS mac_behind_onu",
    DISTANCE             => "CONCAT('--') AS distance",
    EXTERNAL_SYSTEM_LINK => "CONCAT('--') AS external_system_link",
    ONU_NAME             => "CONCAT('--') AS onu_name"
  );

  foreach my $key (keys %reserved_fields) {
    if ($attr->{$key}) {
      my @fields = @{$self->search_expr($attr->{$key}, "STR", $reserved_fields{$key}, { EXT_FIELD => 1 })};
      $self->{SEARCH_FIELDS} .= join(', ', @fields);
    }
  }

  my $EXT_TABLES = q{};

  if($self->{EXT_TABLES} || $self->{SEARCH_FIELDS} =~ /\bu\./xm || $WHERE =~ /\bu\./xm || $attr->{TARIFF_PLAN}) {
    $EXT_TABLES = << "EXT_TABLE";
      LEFT JOIN internet_main internet FORCE INDEX FOR JOIN (`port`) ON (onu.onu_dhcp_port=internet.port AND p.nas_id=internet.nas_id)
      LEFT JOIN users u ON (u.uid=internet.uid)
      LEFT JOIN tarif_plans tp ON (internet.tp_id = tp.tp_id)
EXT_TABLE

    $EXT_TABLES .= $self->{EXT_TABLES};
  }

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
      onu.id,
      p.id AS port_id,
      p.nas_id,
      p.pon_type,
      p.snmp_id,
      onu.onu_id,
      onu.onu_snmp_id,
      onu.vlan AS vlan,
      onu.onu_dhcp_port AS dhcp_port
FROM equipment_pon_ports p
  INNER JOIN equipment_pon_onu onu FORCE INDEX FOR JOIN (`port_id`) ON (onu.port_id=p.id)
  INNER JOIN nas n ON (n.id=p.nas_id)
  INNER JOIN equipment_infos i ON (i.nas_id = n.id)
  $EXT_TABLES
  $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $sql = <<"SQL";
    SELECT COUNT(*) AS total
    FROM equipment_pon_ports p
    INNER JOIN equipment_pon_onu onu FORCE INDEX FOR JOIN (`port_id`) ON (onu.port_id=p.id)
    $EXT_TABLES
    $WHERE;
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list || [];
}

#**********************************************************
=head2 onu_date_status($attr) -  Uploads date, status

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_date_status {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{RX_POWER_SIGNAL} && $attr->{RX_POWER_SIGNAL} eq 'BAD'){
    my $level_max = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MAX} : -8;
    my $level_min = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MIN} : -30;
    push @WHERE_RULES, "(onu.onu_rx_power < 0 AND (onu.onu_rx_power > $level_max OR onu.onu_rx_power < $level_min))";
  }
  elsif ($attr->{RX_POWER_SIGNAL} && $attr->{RX_POWER_SIGNAL} eq 'WORTH'){
    my $level_max = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{WORTH}{MAX} : -10;
    my $level_min = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{WORTH}{MIN} : -27;
    push @WHERE_RULES, "(onu.onu_rx_power < 0 AND (onu.onu_rx_power > $level_max OR onu.onu_rx_power < $level_min))";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'NAS_ID',   'INT', 'p.nas_id',    1 ],
    [ 'OLT_PORT', 'INT', 'p.id',        1 ],
  ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  my $sql = <<"SQL";
SELECT
  onu.id AS ID,
  onu.datetime,
  onu.onu_status
FROM equipment_pon_onu onu
       INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
       INNER JOIN nas n ON (n.id=p.nas_id)
  $WHERE
SQL

  $self->query($sql, undef, $attr);
  my $list = $self->{list};

  return $list || [];
}

#**********************************************************
=head2 pon_onus_report($attr) - returns total ONUs count, active ONUs count, count of ONUs with bad signal

  Arguments:
    $attr
      ONU_ONLINE_STATUS - string with ONU online statuses, delimited by ';'
      STATUS - Equipment (OLT) status
      DELETED - ONU's deleted status
      dbcore's query attrs

  Returns:
    $result - hashref
      onu_count        - total ONUs count
      active_onu_count - active ONUs count
      bad_onu_count    - count of ONUs with bad signal

=cut
#**********************************************************
sub pon_onus_report {
  my ($self, $attr) = @_;

  my $onu_status_where = $self->search_former($attr, [
    [ 'ONU_ONLINE_STATUS', 'INT', 'onu.onu_status', 1 ],
  ]);

  my $WHERE = $self->search_former($attr, [
      [ 'STATUS',  'INT', 'i.status',    1 ],
      [ 'DELETED', 'INT', 'onu.deleted', 1 ],
    ],
    { WHERE => 1 }
  );

  my $level_max = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MAX} : -8;
  my $level_min = ($self->{conf}{PON_LEVELS_ALERT}) ? $self->{conf}{PON_LEVELS_ALERT}{BAD}{MIN} : -30;

  my $sql = <<"SQL";
SELECT
  COUNT(*) onu_count,
  SUM($onu_status_where) active_onu_count,
  SUM($onu_status_where AND onu.onu_rx_power < 0 AND (onu.onu_rx_power > $level_max OR onu.onu_rx_power < $level_min)) bad_onu_count
FROM equipment_pon_onu onu
       LEFT JOIN equipment_pon_ports p ON (onu.port_id=p.id)
       LEFT JOIN equipment_infos i ON (p.nas_id = i.nas_id)
  $WHERE;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list}->[0];
}

#**********************************************************
=head2 onu_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_add {
  my ($self, $attr) = @_;

  if ($attr->{MULTI_QUERY}) {
    my $sql = <<'SQL';
INSERT INTO equipment_pon_onu (
  olt_rx_power,
  onu_rx_power,
  onu_tx_power,
  onu_status,
  onu_in_byte,
  onu_out_byte,
  onu_dhcp_port,
  port_id,
  onu_mac_serial,
  vlan,
  onu_desc,
  onu_id,
  onu_snmp_id,
  line_profile,
  srv_profile,
  datetime,
  onu_type
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?);
SQL

    $self->query($sql, undef,
      { MULTI_QUERY => $attr->{MULTI_QUERY} });
  }
  else {
    $self->query_add('equipment_pon_onu', $attr);
    $self->{admin}->{MODULE} = 'Equipment';
    $self->{admin}->system_action_add("NAS_ID: $attr->{NAS_ID} ONU: $attr->{ONU_MAC_SERIAL}", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 onu_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_change {
  my ($self, $attr) = @_;
  #MULTI_QUERY
  #`olt_rx_power`, `onu_rx_power`, `onu_tx_power`, `onu_status`, `onu_in_byte`, `onu_out_byte`, `onu_dhcp_port`

  if ($attr->{MULTI_QUERY}) {
    my $sql = <<'SQL';
UPDATE equipment_pon_onu
SET
  olt_rx_power  = ? ,
  onu_rx_power  = ? ,
  onu_tx_power  = ? ,
  onu_status    = ? ,
  onu_in_byte   = ? ,
  onu_out_byte  = ? ,
  onu_dhcp_port = ? ,
  port_id       = ? ,
  onu_mac_serial= ? ,
  vlan          = ?,
  onu_desc      = ? ,
  onu_id        = ? ,
  line_profile  = ?,
  srv_profile   = ?,
  deleted       = ?,
  datetime      = NOW()
WHERE id= ? ;
SQL

    $self->query($sql, undef, { MULTI_QUERY => $attr->{MULTI_QUERY} });
  }
  else {
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_pon_onu',
      DATA         => $attr,
      SKIP_LOG     => $self->{conf}{EQUIPMENT_PON_ONU_SKIP_LOG}
    });
  }

  return $self;
}

#**********************************************************
=head2 onu_del($id, $attr) - delete ONU's from DB (table equipment_pon_onu)

  Arguments:
    $id - ONU ID's. comma-separated string
    $attr
      PORT_ID - delete ONU's with port_id's. array ref
      ALL - delete all ONU's
      COMMENTS

  Results:
    $self

=cut
#**********************************************************
sub onu_del {
  my ($self, $id, $attr) = @_;

  my $del_info = '';
  if ($attr->{ALL}) {
    $del_info = "DELETED ALL ONU's";
  }
  elsif ($id) {
    my $onu_info = $self->onu_info($id);
    $del_info = "NAS_ID: $onu_info->{NAS_ID} ONU: ". ($onu_info->{ONU_MAC_SERIAL} || q{});
  }
  elsif ($attr->{PORT_ID}) {
    if (ref $attr->{PORT_ID} eq 'ARRAY') {
      $del_info = "ONU DEL PORT IDS: " . join(', ', @{$attr->{PORT_ID}});
    }
    else {
      $del_info = "ONU DEL PORT ID: $attr->{PORT_ID}";
    }
  }
  $del_info .= " COMMENTS: $attr->{COMMENTS}" if ($attr->{COMMENTS});

  $self->query_del('equipment_pon_onu', { ID => $id }, { port_id => $attr->{PORT_ID} }, { CLEAR_TABLE => $attr->{ALL} });
  $admin->{MODULE} = 'Equipment';

  $admin->system_action_add($del_info, { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 onu_info($id, $attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub onu_info {
  my ($self, $id) = @_;

  my $sql = <<'SQL';
SELECT *
FROM equipment_pon_onu onu
       INNER JOIN equipment_pon_ports p ON (p.id=onu.port_id)
WHERE onu.id=  ? ;
SQL


  $self->query($sql,
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 pon_port_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub pon_port_list {
  my ($self, $attr) = @_;

  my @search_params = (
    [ 'NAS_ID',      'STR', 'p.nas_id',                    1 ],
    [ 'ONU_COUNT',   'STR', '', 'COUNT(onu.id) AS onu_count' ],
    [ 'BRANCH',      'STR', 'p.branch',                    1 ],
    [ 'BRANCH_DESC', 'STR', 'p.branch_desc',               1 ],
    [ 'SNMP_ID',     'STR', 'p.snmp_id',                   1 ],
    [ 'STATUS',      'INT', 'i.status',                    1 ],
    [ 'PON_TYPE',    'STR', 'p.pon_type',                  1 ],
    [ 'ID',          'INT', 'p.id',                        1 ],
    [ 'VLAN_ID',     'INT', 'p.vlan_id',                   1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $EXT_TABLE = q{};
  $attr->{GROUP_BY} = q{};
  if ($attr->{ONU_COUNT}) {
    $EXT_TABLE = "LEFT JOIN equipment_pon_onu onu ON (onu.port_id=p.id AND onu.deleted = 0)";
    $attr->{GROUP_BY} = 'p.id';
  }

  if (defined $attr->{STATUS}) {
    $EXT_TABLE .= " LEFT JOIN equipment_infos i ON (p.nas_id = i.nas_id)";
  }

  my $sql = <<"SQL";
  SELECT
    p.snmp_id,
    p.nas_id,
    p.pon_type,
    p.branch,
    p.branch_desc,
    p.vlan_id,
    $self->{SEARCH_FIELDS}
    p.id
    FROM equipment_pon_ports p
    $EXT_TABLE
    $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  $sql = <<"SQL";
  SELECT COUNT(*) AS total
    FROM equipment_pon_ports p
    $EXT_TABLE
    $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 pon_port_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub pon_port_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_pon_ports', $attr);

  return $self;
}

#**********************************************************
=head2 pon_port_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub pon_port_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_pon_ports',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 pon_port_del($id, $attr) - delete PON ports from DB (table equipment_pon_ports)

  Arguments:
    $id - port ID's. comma-separated string
    $attr
      ALL - delete all ports

=cut
#**********************************************************
sub pon_port_del {
  my ($self, $id, $attr) = @_;

  $self->onu_list({ OLT_PORT => $id });

  if ($self->{TOTAL}) {
    $self->{errno} = 1;
    $self->{ONU_TOTAL} = $self->{TOTAL};
  }
  else {
    $self->query_del('equipment_pon_ports', { ID => $id }, undef, { CLEAR_TABLE => $attr->{ALL} });
  }

  return $self;
}

#**********************************************************
=head2 type_info($id, $attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub pon_port_info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_pon_ports WHERE id=  ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 trap_type_add($attr) -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_trap_types', $attr);

  return $self;
}

#**********************************************************
=head2 trap_type_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_params = (
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'OBJECT_ID', 'STR', 'object_id', 1 ],
    [ 'TYPE', 'INT', 'type', 1 ],
    [ 'EVENT', 'INT', 'event', 1 ],
    [ 'SKIP', 'INT', 'skip', 1 ],
    [ 'COLOR', 'INT', 'color', 1 ],
    [ 'VARBIND', 'STR', 'varbind', 1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1 });

  my $sql = <<"SQL";
  SELECT
    $self->{SEARCH_FIELDS}
    id
    FROM equipment_trap_types
    $WHERE
    ORDER BY $SORT $DESC;
SQL


  $self->query($sql, undef, $attr);

  return [] if ($self->{errno});
  return $self->{list_hash} if ($attr->{LIST2HASH});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 trap_type_del($id) -

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub trap_type_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_trap_types', { ID => $id });

  return $self;
}

#**********************************************************
=head2 trap_type_change($attr) -

  Arguments:
    $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub trap_type_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_trap_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 graphs_clean($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
# sub graphs_clean {
#   my ($self, $attr) = @_;
#
#   $self->query("DELETE FROM equipment_counter64_stats WHERE datetime < CURDATE() - INTERVAL ? day;",
#     'do', { Bind => [ $attr->{PERIOD} || 30 ] });
#
#   return $self;
# }

#**********************************************************
=head2 ping_log_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub ping_log_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_ping_log', $attr);

  return $self;
}
#**********************************************************
=head2 tr_069_settings_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub tr_069_settings_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_params = (
    [ 'ID',          'INT', 'id', 1 ],
    [ 'ONU_ID',      'INT', 'tr.onu_id', 1 ],
    [ 'NAS_NAME',    'STR', 'n.name', 'n.name AS nas_name' ],
    [ 'UPDATETIME',  'STR', 'tr.updatetime', 1 ],
    [ 'CHANGETIME',  'STR', 'tr.changetime', 1 ],
    [ 'UNIX_UPDATETIME', 'STR', 'tr.updatetime', 'UNIX_TIMESTAMP(tr.updatetime) AS unix_updatetime' ],
    [ 'UNIX_CHANGETIME', 'STR', 'tr.changetime', 'UNIX_TIMESTAMP(tr.changetime) AS unix_changetime' ],
    [ 'SETTINGS',    'STR', 'tr.settings', 1 ],
    [ 'SERIAL',      'STR', 'o.onu_mac_serial', 1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1 });

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
    tr.id
FROM equipment_pon_onu o
  LEFT JOIN equipment_pon_ports p ON (p.id=o.port_id)
  LEFT JOIN nas n ON (n.id=p.nas_id)
  LEFT JOIN equipment_tr_069_settings tr ON (tr.onu_id=o.id)
  $WHERE
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return [] if ($self->{errno});
  return $self->{list_hash} if ($attr->{LIST2HASH});

  return $self->{list} || [];
}

#**********************************************************
=head2 tr_069_settings_del($attr) -

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub tr_069_settings_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_tr_069_settings', { ONU_ID => $id });

  return $self;
}

#**********************************************************
=head2 tr_069_settings_change($id, $attr) -

  Arguments:
    $id
    $attr

  Returns:

  Examples:

=cut
#**********************************************************
sub tr_069_settings_change {
  my ($self, $id, $attr) = @_;

  $self->query("SELECT id FROM equipment_tr_069_settings WHERE onu_id= ? ", undef, { Bind => [ $id ] });
  if ($self->{TOTAL}) {
    my $time = ($attr->{UPDATE}) ? 'updatetime' : 'changetime';
    my $settings = ($attr->{SETTINGS}) ? ", settings='$attr->{SETTINGS}'" : '';
    my $sql = <<"SQL";
UPDATE equipment_tr_069_settings SET $time=NOW() $settings WHERE onu_id='$id'
SQL

    $self->query($sql, 'do');
  }
  else {
    $self->query("INSERT INTO equipment_tr_069_settings (onu_id, changetime, settings) VALUES ('$id', NOW(), '$attr->{SETTINGS}');",
      'do');
  }

  return $self;
}

#**********************************************************
=head2 onu_and_internet_cpe_list() - return information about ONUs and abonents joined by CPE MAC

  Arguments:
    $attr
      NAS_IDS - search only for this NAS_IDS. string, NAS IDs separated by ';'
      DELETED - ONU's deleted status

  Results:
    $list

=cut
#**********************************************************
sub onu_and_internet_cpe_list {
  my ($self, $attr) = @_;

  $attr->{PG} //= 0;
  $attr->{PAGE_ROWS} //= 10000;

  my $WHERE = '';

  my @ids = ();
  if ($attr->{NAS_IDS}) {
    @ids = split (';', $attr->{NAS_IDS} || '');
  }

  if (@ids) {
    $WHERE .= " AND p.nas_id IN (" . join(",", (map { $self->{db}->{db}->quote($_) } @ids)) . ")";
  }

  if (defined $attr->{DELETED}) {
    $WHERE .= 'AND onu.deleted = ' . int($attr->{DELETED});
  }

  my $EXT_TABLE = qq{ INNER JOIN internet_main i ON (onu.onu_mac_serial=i.cpe_mac AND i.cpe_mac<>'') };
  if ($attr->{CPE_UNIFY}) {
    $EXT_TABLE = qq{ INNER JOIN internet_main i ON (REPLACE(REPLACE(onu.onu_mac_serial, ':', ''),'.','')=REPLACE(REPLACE(i.cpe_mac, ':', ''),'.','') AND i.cpe_mac<>'') };
  }

  my $sql = <<"SQL";
SELECT
  onu.id,
  onu.onu_dhcp_port AS onu_port,
  p.nas_id AS onu_nas,
  onu.onu_mac_serial AS cpe,
  onu.onu_status,
  onu.vlan AS onu_vlan,
  ei.server_vlan AS onu_server_vlan,
  i.nas_id AS user_nas,
  i.port AS user_port,
  i.id AS service_id,
  i.vlan AS user_vlan,
  i.server_vlan AS user_server_vlan,
  i.uid,
  p.vlan_id AS pon_port_vlan,
  REPLACE(REPLACE(onu.onu_mac_serial, ':', ''),'.','') AS cpe_unify
FROM equipment_pon_onu onu
  LEFT JOIN equipment_pon_ports p ON (p.id=onu.port_id)
  LEFT JOIN equipment_infos ei ON (ei.nas_id=p.nas_id)
  $EXT_TABLE
  $WHERE
SQL

  $self->query_list($sql, $attr);

  return $self->{list} || [ ];
}

#**********************************************************
=head2 mac_duplicate_list($attr) -

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub mac_duplicate_list {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
SELECT
  el.mac,
  el.ip,
  el.vlan,
  el.port,
  el.port_name,
  el.datetime,
  el.rem_time
FROM equipment_mac_log el
WHERE el.mac IN (
  SELECT mac
  FROM equipment_mac_log
  WHERE nas_id = ?
  GROUP BY mac
  HAVING COUNT(*) > 1
)
ORDER BY el.mac;
SQL

  $self->query_list($sql, { Bind => [ $attr->{NAS_ID} ], COLS_UPPER => 1 });

  return $self->{list} || [];
}

#**********************************************************
=head2 _list_with_coords($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#@deprecated change to list
#**********************************************************
sub _list_with_coords {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 10000;

  if ($admin->{DOMAIN_ID}) {
    $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};
  }

  my @search_params = (
    [ 'TYPE',           'STR', 't.id',                                     1 ],
    [ 'NAS_NAME',       'STR', 'nas.name', 'nas.name AS nas_name'            ],
    [ 'SYSTEM_ID',      'STR', 'i.system_id',                              1 ],
    [ 'TYPE_ID',        'INT', 'm.type_id',                                1 ],
    [ 'VENDOR_ID',      'INT', 'm.vendor_id',                              1 ],
    [ 'NAS_TYPE',       'STR', 'nas.nas_type',                             1 ],
    [ 'MODEL_NAME',     'STR', 'm.model_name',                             1 ],
    [ 'SNMP_TPL',       'STR', 'm.snmp_tpl',                               1 ],
    [ 'MODEL_ID',       'INT', 'i.model_id',                               1 ],
    [ 'VENDOR_NAME',    'STR', 'v.name', 'v.name AS vendor_name'             ],
    [ 'STATUS',         'INT', 'i.status',                                 1 ],
    [ 'DISABLE',        'INT', 'nas.disable',                              1 ],
    [ 'TYPE_NAME',      'INT', 'm.type_id', 't.name AS type_name',           ],
    [ 'PORTS',          'INT', 'm.ports',                                  1 ],
    [ 'MAC',            'INT', 'nas.mac',                                  1 ],
    [ 'NAS_IP',         'IP', 'nas.ip', 'INET_NTOA(nas.ip) AS nas_ip'        ],
    [ 'NAS_ID',         'INT', 'i.nas_id',                                 1 ],
    [ 'NAS_GID',        'INT', 'nas.gid',                                  1 ],
    [ 'NAS_GROUP_NAME', 'STR', 'ng.name', 'ng.name AS nas_group_name'        ],
    [ 'DISTRICT_ID',    'INT', 'streets.district_id', 'districts.name'       ],
    [ 'LOCATION_ID',    'INT', 'nas.location_id',                          1 ],
    [ 'DOMAIN_ID',      'INT', 'nas.domain_id',                            1 ],
    [ 'DOMAIN_NAME',    'INT', 'domains.name', 'domains.name AS domain_name' ],
    [ 'COORDX',         'INT', 'builds.coordx',                            1 ],
    [ 'COORDY',         'INT', 'builds.coordy',                            1 ],
    [ 'LAST_ACTIVITY',  'DATE', 'i.last_activity',                         1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1, }
  );

  my $EXT_TABLES = '';

  if($attr->{DOMAIN_NAME}) {
    $EXT_TABLES .= "LEFT JOIN domains on (domains.id=nas.domain_id)"
  }

  my $sql = <<"SQL";
SELECT
  $self->{SEARCH_FIELDS}
        i.nas_id, nas.location_id, builds.coordx, builds.coordy,
        mp.created,
        m.id,
        i.nas_id,
        SUM(plpoints.coordx)/COUNT(plpoints.coordx) AS coordx_2,
        SUM(plpoints.coordy)/COUNT(plpoints.coordy) AS coordy_2
FROM equipment_infos i
  INNER JOIN equipment_models m ON (m.id=i.model_id)
  INNER JOIN equipment_types t ON (t.id=m.type_id)
  INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
  LEFT JOIN nas ON (nas.id=i.nas_id)
  LEFT JOIN builds ON (builds.id=nas.location_id)
  LEFT JOIN maps_points mp ON (builds.id=mp.location_id)
  LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
  LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
  LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
  LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
  $EXT_TABLES
  $WHERE
GROUP BY nas.location_id HAVING (coordx <> 0 AND coordy <> 0) OR (coordx_2 <> 0 AND coordy_2 <> 0)
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 calculator_list($attr) - List of calculator data

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub calculator_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'TYPE',       'STR', 'c.type',        1 ],
    [ 'NAME',       'STR', 'c.name',        1 ],
    [ 'VALUE',      'STR', 'c.value',       1 ],
  ],
    { WHERE => 1, }
  );

  my $sql = <<"SQL";
SELECT
  c.type,
  c.name,
  c.value
FROM equipment_calculator c
  $WHERE
SQL

  $self->query_list($sql, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 calculator_delete($attr) - delete from calculator by type

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub calculator_delete {
  my ($self, $type) = @_;

  $self->query_del('equipment_calculator', undef,{ TYPE => $type });

  return $self;
}

#**********************************************************
=head2 calculator_add($attr) - add to calculator types

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub calculator_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_calculator', $attr);

  return $self;
}

#**********************************************************
=head2 port_errors_add ($attr) - add port errors

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_errors_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_ports_errors', $attr);

  return $self;
}

#**********************************************************
=head2 port_errors_list($attr) - list port errors

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub port_errors_list {
  my ($self, $attr) = @_;

  my @search_params = (
    [ 'DATE',            'INT', 'epe.date',                       1 ],
    [ 'NAS_NAME',        'STR', 'nas.name',  'nas.name AS nas_name' ],
    [ 'NAS_ID',          'INT', 'epe.nas_id',                     1 ],
    [ 'PORT_ID',         'STR', 'epe.port_id',                    1 ],
    [ 'IN_ERRORS',       'INT', 'epe.in_errors',                  1 ],
    [ 'OUT_ERRORS',      'INT', 'epe.out_errors',                 1 ],
    ['FROM_DATE|TO_DATE','INT', "DATE_FORMAT(epe.date, '%Y-%m-%d')" ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} id
FROM equipment_ports_errors epe
  LEFT JOIN nas ON (nas.id=epe.nas_id)
  $WHERE
SQL

  $self->query_list($sql, undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 onu_log_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_model_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_onu_models', $attr);

  return $self;
}

#**********************************************************
=head2 onu_model_info (ID)

  Arguments:
    ID

  Returns:
    $self

=cut
#**********************************************************
sub onu_model_info {
  my ($self, $attr) = @_;

  $self->query("SELECT * FROM equipment_onu_models WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 onu_model_change($attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub onu_model_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_onu_models',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 onu_model_del($attr)

  Arguments:
    ID

  Returns:
    $self

=cut
#**********************************************************
sub onu_model_del {
  my ($self, $attr) = @_;

  $self->query_del('equipment_onu_models', $attr);

  return $self;
}

#**********************************************************
=head2 onu_model_list($attr) - onu log list

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub onu_model_list {
  my ($self, $attr) = @_;

  my @search_params = (
    [ 'ID',                  'INT', 'eom.id',                           1 ],
    [ 'PON_TYPE',            'INT', 'eom.pon_type',                     1 ],
    [ 'ONU_TYPE',            'STR', 'eom.onu_type',                     1 ],
    [ 'WIFI_SSIDS',          'STR', 'eom.wifi_ssids',                   1 ],
    [ 'ETHERNET_PORTS',      'INT', 'eom.ethernet_ports',               1 ],
    [ 'VOIP_PORTS',          'INT', 'eom.voip_ports',                   1 ],
    [ 'CATV',                'INT', 'eom.catv',                         1 ],
    [ 'CUSTOM_PROFILES',     'STR', 'eom.custom_profiles',              1 ],
    [ 'CAPABILITY',          'INT', 'eom.capability',                   1 ],
    [ 'IMAGE',               'INT', 'eom.image',                        1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} id
FROM equipment_onu_models eom
  $WHERE
SQL

  $self->query_list($sql, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 equipment_netmap_position_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_netmap_position_add {
  my ($self, $attr) = @_;

  return $self if !$attr->{POSITIONS} || ref $attr->{POSITIONS} ne 'ARRAY';

  my @MULTI_QUERY = ();
  foreach my $position (@{$attr->{POSITIONS}}) {
    next if !$position->{NAS_ID};
    push @MULTI_QUERY, [ $position->{NAS_ID}, $position->{COORDX}, $position->{COORDY} ];
  }

  $self->query("REPLACE INTO equipment_netmap_positions (nas_id, coordx, coordy) VALUES (?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 equipment_netmap_positions_list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_netmap_positions_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'NAS_ID', 'INT', 'enp.nas_id', 1 ],
    [ 'COORDX', 'INT', 'enp.coordx', 1 ],
    [ 'COORDY', 'STR', 'enp.coordy', 1 ],
  ], { WHERE => 1 });

  my $sql = <<"SQL";
SELECT $self->{SEARCH_FIELDS} enp.nas_id
FROM equipment_netmap_positions enp
  $WHERE
SQL

  $self->query_list($sql, $attr);

  return $self->{list} || [];
}

1;
