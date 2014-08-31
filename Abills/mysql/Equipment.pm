package Equipment;
#Equipment list


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

my $db;
use main;
use Socket;

@ISA = ("main");
my $CONF;
my $admin;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;
  
  return $self;
}



#**********************************************************
# list
#**********************************************************
sub vendor_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2("SELECT id, name, support, site
    FROM equipment_vendors
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub vendor_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  $self->query_add('equipment_vendors', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub vendor_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_vendors',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub vendor_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_vendors WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub vendor_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, 
       name,
       support,
       site       
    FROM equipment_vendors
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub type_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2("SELECT id, name
    FROM equipment_types
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub type_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
  $self->query_add('equipment_types', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_types',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub type_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_types WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub type_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT id, 
       name
    FROM equipment_types
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# model_list
#**********************************************************
sub model_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{GID}) {
    my $value = $self->search_expr($attr->{GID}, 'INT');
    push @WHERE_RULES, "ni.gid$value";
  }

  if ($attr->{IP}) {
    push @WHERE_RULES, "ni.ip=INET_ATON('$attr->{IP}')";
  }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "ni.status='$attr->{STATUS}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
        m.model_name,
        v.name AS vendor_name,
        t.name AS type_name,
        m.ports,
        m.id
    FROM equipment_models m
    LEFT JOIN equipment_types t ON (t.id=m.type_id)
    LEFT JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $WHERE
    GROUP BY m.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM equipment_models m
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
# Add
#**********************************************************
sub model_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_models', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub model_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_models',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub model_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_models WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub model_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT * FROM equipment_models
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub _list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{GID}) {
    my $value = $self->search_expr($attr->{GID}, 'INT');
    push @WHERE_RULES, "ni.gid$value";
  }

  if ($attr->{IP}) {
    push @WHERE_RULES, "ni.ip=INET_ATON('$attr->{IP}')";
  }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "ni.status='$attr->{STATUS}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
        i.nas_id,
        i.system_id,
        i.status,
        m.model_name,
        v.name AS vendor_name,
        t.name AS type_name,
        m.ports,
        m.id
    FROM equipment_infos i
    INNER JOIN equipment_models m ON (m.id=i.model_id)
    INNER JOIN equipment_types t ON (t.id=m.type_id)
    INNER JOIN equipment_vendors v ON (v.id=m.vendor_id)
    $WHERE
    GROUP BY i.nas_id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM equipment_infos m
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
# Add
#**********************************************************
sub _add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_infos', $attr);

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub _change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'NAS_ID',
      TABLE        => 'equipment_infos',
      DATA         => $attr
    }
  );
  return $self;
}

#**********************************************************
# del
#**********************************************************
sub _del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_infos WHERE nas_id='$id';", 'do');

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub _info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT *
    FROM equipment_infos
    WHERE nas_id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}



#**********************************************************
# port_list
#**********************************************************
sub port_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  my $WHERE =  $self->search_former($attr, [
      ['LOGIN',          'STR', 'u.id',               'u.id AS login' ],
      ['FIO',            'STR', 'pi.fio',                           1 ],
      ['MAC',            'STR', 'dhcp.mac',                         1 ],
      ['IP',             'IP',  'dhcp.ip',    'INET_NTOA(dhcp.ip) AS ip' ],
      ['NETMASK',        'IP',  'dhcp.netmask', 'INET_NTOA(dhcp.netmask) AS netmask' ],
      ['TP_ID',          'INT', 'dv.tp_id',                         1 ],
      ['TP_NAME',        'STR', 'tp.name',               'tp.tp_name' ],
      ['UID',            'INT', 'u.uid',                            1 ],
      ['GID',            'INT', 'u.gid',                            1 ],
      ['NAS_ID',         'INT', 'p.nas_id',                           ]
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1,
    }    
    );

  my $EXT_TABLE = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /pi\.|u\.|dv\./) {
   	$EXT_TABLE = "LEFT JOIN users u ON (u.uid=dhcp.uid)
   	LEFT JOIN users_pi pi ON (pi.uid=u.uid)". $EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /dhcp|dv\.|tp\./) {
    $EXT_TABLE = "LEFT JOIN dhcphosts_hosts dhcp ON (dhcp.nas=p.nas_id AND dhcp.ports=p.port)".$EXT_TABLE;
  }

  if ($self->{SEARCH_FIELDS} =~ /dv\.|tp\./) {
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.uid=u.uid)
    LEFT JOIN tariff_plans tp ON (dv.tp_id=tp.id AND tp.modules='Dv') ";
  }


  $self->query2("SELECT p.port, p.status, p.uplink, 
   p.comments, 
   $self->{SEARCH_FIELDS}
   p.nas_id, p.id
    FROM equipment_ports p
    $EXT_TABLE
    $WHERE
    GROUP BY p.port
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM equipment_ports p
    $WHERE;", undef, { INFO => 1 }
    );
  }

  return $list;
}


#**********************************************************
# port_add
#**********************************************************
sub port_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('equipment_ports', $attr);

  return $self;
}

#**********************************************************
# port_change
#**********************************************************
sub port_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'equipment_ports',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# port_del
#**********************************************************
sub port_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM equipment_ports WHERE id='$id';", 'do');

  return $self;
}



#**********************************************************
# port_info
#**********************************************************
sub port_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT *
    FROM equipment_ports
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );

  return $self;
}
1
