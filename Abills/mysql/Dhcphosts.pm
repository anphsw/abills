package Dhcphosts;

#
# DHCP server managment and user control
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT      = qw();
@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my $MODULE = 'Dhcphosts';

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

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# routes_list()
#**********************************************************
sub routes_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['NET_ID',    'INT', 'r.network' ],
      ['RID',       'INT', 'r.id'      ],
    ],
    { WHERE => 1,
    }    
  );

  $self->query2("SELECT 
    r.id, r.network, inet_ntoa(r.src),
    INET_NTOA(r.mask) AS netmask,
    inet_ntoa(r.router) AS router,
    n.name
     FROM dhcphosts_routes r
     left join dhcphosts_networks n on r.network=n.id
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr  
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM dhcphosts_routes r $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# host_defaults()
#**********************************************************
sub network_defaults {
  my $self = shift;

  my %DATA = (
    ID                   => '0',
    NAME                 => 'DHCP_NET',
    NETWORK              => '0.0.0.0',
    MASK                 => '255.255.255.0',
    BLOCK_NETWORK        => 0,
    BLOCK_MASK           => 0,
    DOMAINNAME           => '',
    DNS                  => '',
    COORDINATOR          => '',
    PHONE                => '',
    ROUTERS              => '',
    DISABLE              => 0,
    OPTION_82            => 0,
    IP_RANGE_FIRST       => '0.0.0.0',
    IP_RANGE_LAST        => '0.0.0.0',
    COMMENTS             => '',
    DENY_UNKNOWN_CLIENTS => 0,
    AUTHORITATIVE        => 0,
    GUEST_VLAN           => 0,
    STATIC               => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# network_add()
#**********************************************************
sub network_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => network_defaults() });

  $self->query2("INSERT INTO dhcphosts_networks 
     (name,network,mask, routers, coordinator, phone, dns, dns2, ntp,
      suffix, disable,
      ip_range_first, ip_range_last, comments,  deny_unknown_clients,  authoritative, net_parent, guest_vlan, static) 
     VALUES('$DATA{NAME}', INET_ATON('$DATA{NETWORK}'), INET_ATON('$DATA{MASK}'), INET_ATON('$DATA{ROUTERS}'),
       '$DATA{COORDINATOR}', '$DATA{PHONE}', '$DATA{DNS}', '$DATA{DNS2}',  '$DATA{NTP}', 
       '$DATA{DOMAINNAME}',
       '$DATA{DISABLE}',
       INET_ATON('$DATA{IP_RANGE_FIRST}'),
       INET_ATON('$DATA{IP_RANGE_LAST}'),
       '$DATA{COMMENTS}',
       '$DATA{DENY_UNKNOWN_CLIENTS}',
       '$DATA{AUTHORITATIVE}',
       '$DATA{NET_PARENT}',
       '$DATA{GUEST_VLAN}',
       '$DATA{STATIC}'
       )", 'do'
  );

  $admin->system_action_add("DHCPHOSTS_NET:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
# network_delete()
#**********************************************************
sub network_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM dhcphosts_networks where id='$id';",   'do');
  $self->query2("DELETE FROM dhcphosts_hosts where network='$id';", 'do');

  $admin->system_action_add("DHCPHOSTS_NET:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
# network_update()
#**********************************************************sub change {
sub network_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID                   => 'id',
    NAME                 => 'name',
    NETWORK              => 'network',
    MASK                 => 'mask',
    BLOCK_NETWORK        => 'block_network',
    BLOCK_MASK           => 'block_mask',
    DOMAINNAME           => 'suffix',
    DNS                  => 'dns',
    DNS2                 => 'dns2',
    NTP                  => 'ntp',
    COORDINATOR          => 'coordinator',
    PHONE                => 'phone',
    ROUTERS              => 'routers',
    DISABLE              => 'disable',
    IP_RANGE_FIRST       => 'ip_range_first',
    IP_RANGE_LAST        => 'ip_range_last',
    COMMENTS             => 'comments',
    DENY_UNKNOWN_CLIENTS => 'deny_unknown_clients',
    AUTHORITATIVE        => 'authoritative',
    NET_PARENT           => 'net_parent',
    GUEST_VLAN           => 'guest_vlan',
    STATIC               => 'static'
  );

  $attr->{DENY_UNKNOWN_CLIENTS} = (defined($attr->{DENY_UNKNOWN_CLIENTS})) ? 1 : 0;
  $attr->{AUTHORITATIVE}        = (defined($attr->{AUTHORITATIVE}))        ? 1 : 0;
  $attr->{DISABLE}              = (defined($attr->{DISABLE}))              ? 1 : 0;
  $attr->{STATIC}               = (defined($attr->{STATIC}))               ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'dhcphosts_networks',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->network_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "DHCPHOSTS_NET:$attr->{ID}"
    }
  );

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub network_info {
  my $self = shift;
  my ($id) = @_;

  $self->query2("SELECT
   id,
   name,
   INET_NTOA(network) AS network,
   INET_NTOA(mask) AS mask,
   INET_NTOA(routers) AS ROUTERS,
   INET_NTOA(block_network) AS blocK_network,
   INET_NTOA(block_mask) AS block_mask,
   suffix AS domainname,
   dns,
   dns2,
   ntp,
   coordinator,
   phone,
   disable,
   INET_NTOA(ip_range_first) AS ip_range_first,
   INET_NTOA(ip_range_last) AS ip_range_last,
   static,
   comments,
   deny_unknown_clients,
   authoritative,
   net_parent,
   guest_vlan
  FROM dhcphosts_networks

  WHERE id='$id';",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# networks_list()
#**********************************************************
sub networks_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['DISABLE',        'INT', 'disable'   ],
      ['PARENT',         'INT', 'net_parent'],
    ],
    { WHERE => 1,
    }    
  );

  $self->query2("SELECT 
    id, name, INET_NTOA(network) AS network,
     INET_NTOA(mask) AS netmask,
     coordinator,
     phone,
     disable,
     net_parent,
     guest_vlan,
     static     
     FROM dhcphosts_networks
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM dhcphosts_networks $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
# host_defaults()
#**********************************************************
sub host_defaults {
  my $self = shift;

  my %DATA = (
    MAC          => '00:00:00:00:00:00',
    EXPIRE       => '0000-00-00',
    IP           => '0.0.0.0',
    COMMENTS     => '',
    VID          => 0,
    NAS_ID       => 0,
    OPTION_82    => 0,
    HOSTNAME     => '',
    NETWORK      => 0,
    BLOCKTIME    => '',
    FORCED       => '',
    DISABLE      => '',
    EXPIRE       => '',
    PORTS        => '',
    BOOT_FILE    => '',
    NEXT_SERVER  => '',
    IPN_ACTIVATE => ''
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# host_add()
#**********************************************************
sub host_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => host_defaults() });

  $self->query2("INSERT INTO dhcphosts_hosts (uid, hostname, network, ip, mac, blocktime, 
    forced, disable, expire, comments, option_82, vid, nas, ports, boot_file, next_server, ipn_activate,
    server_vid) 
    VALUES('$DATA{UID}', '$DATA{HOSTNAME}', '$DATA{NETWORK}',
      INET_ATON('$DATA{IP}'), '$DATA{MAC}', '$DATA{BLOCKTIME}', '$DATA{FORCED}', '$DATA{DISABLE}',
      '$DATA{EXPIRE}',
      '$DATA{COMMENTS}', '$DATA{OPTION_82}', '$DATA{VID}', '$DATA{NAS_ID}', '$DATA{PORTS}',
      '$DATA{BOOT_FILE}',
      '$DATA{NEXT_SERVER}',
      '$DATA{IPN_ACTIVATE}',
      '$DATA{SERVER_VID}'
      );", 'do'
  );

  $admin->action_add($DATA{UID}, "$DATA{IP}/$DATA{MAC} NAS: $DATA{NAS_ID}/$DATA{PORTS}", {  TYPE => 1 });

  return $self;
}

#**********************************************************
# host_del()
#**********************************************************
sub host_del {
  my $self = shift;
  my ($attr) = @_;
  my $uid;
  my $action;
  my $host;

  if ($attr->{UID}) {
    $WHERE  = "uid='$attr->{UID}'";
    $action = "DELETE ALL HOSTS";
    $uid    = $attr->{UID};
  }
  else {
    $WHERE = "id='$attr->{ID}'";
    $host = $self->host_info($attr->{ID});
    $uid    = $host->{UID};
    $action = "DELETE HOST $host->{HOSTNAME} ($host->{IP}/$host->{MAC}) $host->{NAS_ID}:$host->{PORTS}";
  }

  $self->query2("DELETE FROM dhcphosts_hosts where $WHERE", 'do');
  $self->query2("DELETE FROM dhcphosts_leases where uid='$uid' or hardware='$host->{MAC}'", 'do');

  $admin->action_add($uid, "$action", { TYPE => 10 });

  return $self;
}

#**********************************************************
# host_check()
#**********************************************************
sub host_check {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  my $net = $self->network_info($DATA{NETWORK});

  $self->{errno} = 17 if ($self->{TOTAL} == 0);

  my $ip   = unpack("N", pack("C4", split(/\./, $DATA{IP})));
  my $mask = unpack("N", pack("C4", split(/\./, $net->{MASK})));
  if (unpack("N", pack("C4", split(/\./, $net->{NETWORK}))) != ($ip & $mask)) {
    $self->{errno} = 17 if ($ip != 0);
  }

  return $self;
}

#**********************************************************
#host_info()
#**********************************************************
sub host_info {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($attr->{IP}) {
    $WHERE = "ip=INET_ATON('$attr->{IP}')";
  }
  else {
    $WHERE = "id='$id'";
  }

  $self->query2("SELECT
   uid, 
   hostname, 
   network, 
   INET_NTOA(ip) AS ip, 
   mac, 
   blocktime, 
   forced,
   disable,
   expire,
   option_82,
   vid,
   server_vid,
   comments,
   nas AS nas_id,
   ports,
   boot_file, 
   changed,
   next_server,
   ipn_activate
  FROM dhcphosts_hosts
  WHERE $WHERE;",
  undef,
  { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#host_change()
#**********************************************************
sub host_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{NAS}          = $attr->{NAS_ID};
  $attr->{OPTION_82}    = ($attr->{OPTION_82})    ? 1 : 0;
  $attr->{IPN_ACTIVATE} = ($attr->{IPN_ACTIVATE}) ? 1 : 0;
  $attr->{DISABLE}      = ($attr->{DISABLE})      ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'dhcphosts_hosts',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# route_add()
#**********************************************************
sub route_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);
  $self->query2("INSERT INTO dhcphosts_routes 
       (network, src, mask, router) 
    values($DATA{NET_ID},INET_ATON('$DATA{SRC}'), INET_ATON('$DATA{MASK}'), INET_ATON('$DATA{ROUTER}'))", 'do'
  );

  $admin->system_action_add("DHCPHOSTS_NET:$DATA{NET_ID} ROUTE:$self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# route_delete()
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id) = @_;
  $self->query2("DELETE FROM dhcphosts_routes where id='$id'", 'do');

  $admin->system_action_add("DHCPHOSTS_NET: ROUTE:$id", { TYPE => 10 });
  return $self;
}

#**********************************************************
# route_update()
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID     => 'id',
    NET_ID => 'network',
    SRC    => 'src',
    MASK   => 'mask',
    ROUTER => 'router'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'dhcphosts_routes',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $self->route_info($attr->{ID}),
      DATA            => $attr,
      EXT_CHANGE_INFO => "DHCPHOSTS_ROUTE:$attr->{ID}"
    }
  );

  return $self if ($self->{errno});
}

#**********************************************************
# route_update()
#**********************************************************
sub route_info {
  my $self = shift;
  my ($id) = @_;

  $self->query2("SELECT 
   id AS net_id,
   network,
   INET_NTOA(src) AS src,
   INET_NTOA(mask) AS mask ,
   INET_NTOA(router) AS router
    FROM dhcphosts_routes WHERE id='$id';",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# hosts_list()
#**********************************************************
sub hosts_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();
  my $EXT_TABLES = '';
  $self->{EXT_TABLES} = '';

  if ($attr->{NAS_IP}) {
    $EXT_TABLES .= "LEFT JOIN nas  ON  (h.nas=nas.id) ";
  }

  my $WHERE =  $self->search_former($attr, [
     ['ID',              'INT', 'h.id'                         ],
     ['LOGIN',           'INT', 'u.id',   'u.id AS login'      ],
     ['IP',              'IP',  'h.ip', 'INET_NTOA(h.ip) AS ip'],
     ['HOSTNAME',        'STR', 'h.hostname',     1            ],
     ['NETWORK_NAME',    'STR', 'n.name AS netwirk_name', 1    ],
     ['NETWORK',         'INT', 'h.network',      1],
     ['MAC',             'STR', 'h.mac',          1],  
     ['STATUS',          'INT', 'h.disable',      'h.disable AS status'],
     ['IPN_ACTIVATE',    'INT', 'h.ipn_activate', 1],
     ['EXPIRE',          'DATE','h.expire',       1],
     ['USER_DISABLE',    'INT', 'u.disable',      1],
     ['OPTION_82',       'INT', 'h.option_82',    1],
     ['PORTS',           'STR', 'h.ports',        1],
     ['VID',             'INT', 'h.vid',          1],
     ['SERVER_VID',      'INT', 'h.server_vid',   1],
     ['NAS_ID',          'INT', 'h.nas AS nas_id',1],
     ['NAS_IP',          'STR', 'nas.ip',  'nas.ip AS nas_ip'],
     ['DHCPHOSTS_EXT_DEPOSITCHECK', '', '', 'if(company.id IS NULL,ext_b.deposit,ext_cb.deposit) AS ext_deposit' ],
     ['BOOT_FILE',       'STR', 'h.boot_file',   1],
     ['NEXT_SERVER',     'STR', 'h.next_server', 1],
     ['UID',             'INT', 'h.uid'          ],
     ['SHOW_NAS_MNG_INFO','',   '', "nas.mng_host_port, nas.mng_user, DECODE(nas.mng_password, '$CONF->{secretkey}') AS mng_password, " ]
    ],
    { WHERE            => 1,
    	WHERE_RULES      => \@WHERE_RULES,
    	USERS_FIELDS     => 1,
    	SKIP_USERS_FIELDS=> [ 'UID' ]
    }    
    );

  if ($CONF->{DHCPHOSTS_USE_DV_STATUS}) {
    if (defined($attr->{STATUS})) {
      push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', 'dv.disable', { EXT_FIELD => 'dv.disable dv_status' }) };
    }
    
    $EXT_TABLES .= " LEFT JOIN dv_main dv ON  (dv.uid=u.uid) ";
  }

  if (defined($attr->{DHCPHOSTS_EXT_DEPOSITCHECK}) && $attr->{DHCPHOSTS_EXT_DEPOSITCHECK} ne '') {
    $EXT_TABLES .= "
            LEFT JOIN companies ext_company ON  (u.company_id=ext_company.id) 
            LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
            LEFT JOIN bills ext_cb ON  (ext_company.ext_bill_id=ext_cb.id) ";
  }

  $EXT_TABLES .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  $SORT =~ s/ip/h.ip/;

  $self->query2("SELECT 
       h.id, 
       $self->{SEARCH_FIELDS} 
       h.uid,
       h.network AS network_id, 
       if ((u.expire <> '0000-00-00' && curdate() > u.expire) || (h.expire <> '0000-00-00' && curdate() > h.expire), 1, 0) AS expire
     FROM (dhcphosts_hosts h)
     left join dhcphosts_networks n on h.network=n.id
     left join users u on (h.uid=u.uid)
     left join users_pi pi on (pi.uid=u.uid)
     $EXT_TABLES
     $WHERE
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
  );

  return $self if ($self->{errno});
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM dhcphosts_hosts h
     left join users u on h.uid=u.uid
     left join users_pi pi on (pi.uid=u.uid)
     $EXT_TABLES
     $WHERE",
     undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# host_defaults()
#**********************************************************
sub leases_defaults {
  my $self = shift;

  my %DATA = (
    STARTS     => '',
    ENDS       => '',
    STATE      => 0,
    NEXT_STATE => 0,
    HARDWARE   => '',
    UID        => '',
    CIRCUIT_ID => '',
    REMOTE_ID  => '',
    HOSTNAME   => '',
    NAS_ID     => 0,
    IP         => '0.0.0.0'
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# leases_update()
#**********************************************************
sub leases_update {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => leases_defaults() });

  $self->query2("INSERT INTO dhcphosts_leases 
     (  start,  ends,
  state,
  next_state,
  hardware,
  uid,
  circuit_id,
  remote_id,
  hostname,
  nas_id,
  ip ) 
     VALUES('$DATA{STARTS}', '$DATA{ENDS}', '$DATA{STATE}', '$DATA{NEXT_STATE}',
       '$DATA{HARDWARE}', '$DATA{UID}', '$DATA{CIRCUIT_ID}', '$DATA{REMOTE_ID}',
       '$DATA{HOSTNAME}',
       '$DATA{NAS_ID}',
       INET_ATON('$DATA{IP}') )", 'do'
  );

  return $self;
}

#**********************************************************
# leases_list()
#**********************************************************
sub leases_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if (defined($attr->{STATE})) {
    if ($attr->{STATE}==4) {
      push @WHERE_RULES, "l.ends < now()";
    }
    if ($attr->{STATE}==2) {
      push @WHERE_RULES, "l.ends > now()";
    }
    else {
      push @WHERE_RULES, "state='$attr->{STATE}'";
    }
  }


  my $WHERE = $self->search_former($attr, [
     ['NEXT_STATE',      'INT', 'next_state'   ],
     ['NAS_ID',          'INT', 'nas_id'       ],
     ['REMOTE_ID',       'STR', 'remote_id'    ],
     ['CIRCUIT_ID',      'STR', 'circuit_id'   ],
     ['ENDS',            'DATE','ends'         ],
     ['STARTS',          'DATE','starts'       ],
     ['LOGIN',           'STR', 'u.id'         ],
     ['UID',             'INT', 'l.uid'        ],
     ['HOSTNAME',        'STR', 'hostname'     ],
     ['HARDWARE',        'STR', 'l.hardware'   ],
     ['IP',              'IP',  'l.ip'         ],
     ['USER_DISABLE',    'INT', 'u.disable'    ],
     ['PORTS',           'STR', 'l.port',       1],
     ['VID',             'INT', 'l.vlan',       1],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }    
    );

  $self->query2("SELECT if (l.uid > 0, u.id, '') AS login, 
  INET_NTOA(l.ip) AS ip, 
  l.start, l.hardware, l.hostname, 
  l.ends,
  if (l.ends < now(), 4, l.state) AS state,
  l.port,
  l.vlan,
  l.flag,
  l.nas_id,
  l.remote_id,
  l.circuit_id,
  l.next_state,
  l.uid
  FROM dhcphosts_leases  l
  LEFT JOIN users u ON (u.uid=l.uid)
   $WHERE 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS; ",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query2("SELECT count(*) AS total FROM dhcphosts_leases l 
    LEFT JOIN users u ON (u.uid=l.uid)
  $WHERE;", undef, {INFO => 1 });

  return $list;
}

#**********************************************************
# leases_update()
#**********************************************************
sub leases_clear {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES=();
  if ($attr->{ENDED}) {
    push @WHERE_RULES, "ends < now()";
  }

  my $WHERE = $self->search_former($attr, [
     ['NAS_ID', 'INT', 'nas_id' ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
  );

  $self->query2("DELETE FROM dhcphosts_leases $WHERE;", 'do');
  return $self;
}

#**********************************************************
# host_add()
#**********************************************************
sub log_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query2("INSERT INTO dhcphosts_log (datetime, hostname, message_type, message) 
    VALUES('$DATA{DATETIME}', '$DATA{HOSTNAME}', '$DATA{MESSAGE_TYPE}', '$DATA{MESSAGE}');", 'do'
  );

  return $self;
}

#**********************************************************
# host_delete()
#**********************************************************
sub log_del {
  my $self = shift;
  my ($attr) = @_;
  my $uid;
  my $action;

  if ($attr->{DAYS_OLD}) {
    $WHERE = "datetime < curdate() - INTERVAL $attr->{DAYS_OLD} day";
  }
  elsif ($attr->{DATE}) {
    $WHERE = "datetime='$attr->{DATETIME}'";
  }

  $self->query2("DELETE FROM dhcphosts_log where $WHERE", 'do');

  return $self;
}

#**********************************************************
# hosts_list()
#**********************************************************
sub log_list {
  my $self = shift;
  my ($attr) = @_;

  my @ids = ();
  if ($attr->{UID}) {
    my $line = $self->hosts_list({ UID => $attr->{UID}, COLS_NAME => 1 });

    if ($self->{TOTAL} > 0) {
      foreach my $line (@{$line}) {
        push @ids, $line->{ip}, $line->{mac};
      }
    }
    if ($#ids > -1) {
      $attr->{MESSAGE} = '* ' . join(" *,* ", @ids) . ' *';
    }
    $self->{IDS} = \@ids;
  }

  @WHERE_RULES = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
     ['MESSAGE',     'STR', 'l.message' ],
     ['MAC',         'STR', 'l.mac'     ],
     ['HOSTNAME',    'STR', 'l.hostname'],
     ['ID',          'INT', 'l.id'      ],
     ['NAS_ID',      'INT', 'nas_id'    ],
     ['FROM_DATE|TO_DATE', 'DATE', "(date_format(l.datetime, '%Y-%m-%d')" ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
  );

  my $EXT_TABLES = $self->{EXT_TABLES};
  
  if ($WHERE =~ / u\./) {
    $EXT_TABLES .= "LEFT JOIN users u ON  (u.uid=l.uid)"; 
  }
  
  $self->query2("SELECT l.datetime, l.hostname, l.message_type, l.message
     FROM (dhcphosts_log l)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr);

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total FROM dhcphosts_log l $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

1

