package Equipment::Api::admin::Nas;

=head1 NAME

  Equipment Nas

  Endpoints:
    /equipment/nas/*
    /equipment/used/ports/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(cmd in_array);

use Control::Errors;

use Equipment;
use Nas;

my Equipment $Equipment;
my Nas $Nas;
my Control::Errors $Errors;

# TODO: remove crutch, marked at this file below
our (
  $db,
  $admin,
  %conf
);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $Db, $Admin, $conf, $attr) = @_;

  my $self = {
    db    => $Db,
    admin => $Admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  # TODO: remove crutch, marked
  $db = $self->{db};
  $admin = $self->{admin};
  %conf = %{$self->{conf}};

  bless($self, $class);

  $Equipment = Equipment->new($db, $admin, $conf);
  $Equipment->{debug} = $self->{debug};
  $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});
  $Nas->{debug} = $self->{debug} || 0;

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_equipment_nas_types($path_params, $query_params)

  Endpoint GET /equipment/nas/types/

=cut
#**********************************************************
sub get_equipment_nas_types {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # TODO: remove crutch, marked
  require Control::Nas_mng;
  my $types = nas_types_list() || {};
  my @types_list = ();

  foreach my $type (sort keys %{$types}) {
    push @types_list, {
      name => $types->{$type} || '',
      id   => $type || ''
    };
  }

  return \@types_list;
}

#**********************************************************
=head2 get_equipment_nas_list_extra($path_params, $query_params)

  Endpoint GET /equipment/nas/list/extra/

=cut
#**********************************************************
sub get_equipment_nas_list_extra {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  my @address_params = ('DISTRICT_ID', 'STREET_ID', 'LOCATION_ID', 'COORDX', 'COORDY');

  foreach my $param (keys %{$query_params}) {
    $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
    $PARAMS{ADDRESS_FULL} = 1 if (in_array($param, \@address_params))
  }

  $PARAMS{TYPE} = $PARAMS{TYPE_ID} if (defined $PARAMS{TYPE_ID});
  $PARAMS{TR_069_VLAN} = $PARAMS{TR069_VLAN} if (defined $PARAMS{TR069_VLAN});

  if (in_array('Multidoms', \@main::MODULES)) {
    $PARAMS{DOMAIN_ID} = $self->{admin}->{DOMAIN_ID} || 0 if (defined $PARAMS{DOMAIN_NAME});
  }
  else {
    delete $PARAMS{DOMAIN_NAME};
  }

  my $result = $Equipment->_list({
    %PARAMS
  });

  foreach my $equipment (@{$result}) {
    if (exists($equipment->{name})) {
      $equipment->{district_id} = $equipment->{name};
      delete $equipment->{name};
    }

    if ((exists $query_params->{DOMAIN_ID} || exists $query_params->{DOMAIN_NAME}) && !in_array('Multidoms', \@main::MODULES)) {
      $equipment->{domain_id} = 'null';
      $equipment->{domain_name} = 'Error. Module Multidoms disabled';
    }
  }

  my $res = $query_params->{RETURN_TOTAL} ? { list => $result, total => $Equipment->{TOTAL} } : $result;
  return $res;
}

#**********************************************************
=head2 get_equipment_nas_list($path_params, $query_params)

  Endpoint GET /equipment/nas/list/

=cut
#**********************************************************
sub get_equipment_nas_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  foreach my $param (keys %{$query_params}) {
    $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $PARAMS{MNG_HOST_PORT} = $PARAMS{NAS_MNG_IP_PORT} if (defined $PARAMS{MNG_HOST_PORT});

  $Nas->list({
    %PARAMS
  });
}

#**********************************************************
=head2 post_equipment_nas($path_params, $query_params)

  Endpoint POST /equipment/nas/

=cut
#**********************************************************
sub post_equipment_nas {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 200201,
    errstr => 'No field ip'
  } if !$query_params->{IP};

  return {
    errno  => 200202,
    errstr => 'No field nasName'
  } if !$query_params->{NAS_NAME};

  return {
    errno  => 200203,
    errstr => 'No field nas_type'
  } if !defined $query_params->{NAS_TYPE};

  my $result = $Nas->add($query_params);

  if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
    cmd($conf{RESTART_RADIUS});
  }

  return $result;
}

#**********************************************************
=head2 delete_equipment_nas($path_params, $query_params)

  Endpoint DELETE /equipment/nas/:id/

=cut
#**********************************************************
sub delete_equipment_nas {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Nas->del($path_params->{id});

  if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
    cmd($conf{RESTART_RADIUS});
  }

  return ($result->{nas_deleted} eq 1) ? 1 : 0;
}

#**********************************************************
=head2 put_equipment_nas($path_params, $query_params)

  Endpoint PUT /equipment/nas/:id/

=cut
#**********************************************************
sub put_equipment_nas {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 200204,
    errstr => 'No field nasId'
  } if !$path_params->{id};

  return {
    errno  => 200205,
    errstr => 'No field ip'
  } if !$query_params->{IP};

  return {
    errno  => 200206,
    errstr => 'No field nasName'
  } if !$query_params->{NAS_NAME};

  return {
    errno  => 200207,
    errstr => 'No field nasType'
  } if !defined $query_params->{NAS_TYPE};

  my $result = $Nas->change({ NAS_ID => $path_params->{id}, %$query_params });

  if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API} && !$Nas->{errno}) {
    cmd($conf{RESTART_RADIUS});
  }

  return $result;
}

#**********************************************************
=head2 get_equipment_nas_groups_list($path_params, $query_params)

  Endpoint GET /equipment/nas/groups/list/

=cut
#**********************************************************
sub get_equipment_nas_groups_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  $Nas->nas_group_list({
    %PARAMS
  });
}

#**********************************************************
=head2 post_equipment_nas_groups_add($path_params, $query_params)

  Endpoint POST /equipment/nas/groups/add/

=cut
#**********************************************************
sub post_equipment_nas_groups_add {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $validation_result = $self->_validate_nas_group_add($query_params);
  return $validation_result if ($validation_result->{errno});

  $Nas->nas_group_add({
    NAME     => $query_params->{NAME} || '',
    COMMENTS => $query_params->{COMMENTS} || '',
    DISABLE  => $query_params->{DISABLE} ? 1 : undef,
  });
}

#**********************************************************
=head2 put_equipment_nas_groups_id($path_params, $query_params)

  Endpoint PUT /equipment/nas/groups/:id/

=cut
#**********************************************************
sub put_equipment_nas_groups_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $validation_result = $self->_validate_nas_group_add($query_params);
  return $validation_result if ($validation_result->{errno});

  $Nas->nas_group_change({
    ID       => $path_params->{id} || '--',
    NAME     => $query_params->{NAME} || '',
    COMMENTS => $query_params->{COMMENTS} || '',
    DISABLE  => $query_params->{DISABLE} ? 1 : undef,
  });

  delete @{$Nas}{qw/AFFECTED TOTAL list/};
  return $Nas;
}

#**********************************************************
=head2 delete_equipment_nas_groups_id($path_params, $query_params)

  Endpoint DELETE /equipment/nas/groups/:id/

=cut
#**********************************************************
sub delete_equipment_nas_groups_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Nas->nas_group_del($path_params->{id});

  if (!$Nas->{errno}) {
    if ($Nas->{AFFECTED} && $Nas->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30031,
        errstr => "nasGroup with id $path_params->{id} not exists",
      };
    }
  }

  return $Nas;
}

#**********************************************************
=head2 get_equipment_nas_ip_pools($path_params, $query_params)

  Endpoint GET /equipment/nas/ip/pools/

=cut
#**********************************************************
sub get_equipment_nas_ip_pools {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  foreach my $param (keys %{$query_params}) {
    $PARAMS{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Nas->nas_ip_pools_list({
    %PARAMS
  });
}

#**********************************************************
=head2 post_equipment_nas_ip_pools($path_params, $query_params)

  Endpoint POST /equipment/nas/ip/pools/

=cut
#**********************************************************
sub post_equipment_nas_ip_pools {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 200208,
    errstr => 'No field poolId'
  } if !$query_params->{POOL_ID};

  return {
    errno  => 200209,
    errstr => 'No field nasId'
  } if !$query_params->{NAS_ID};

  $Nas->nas_ip_pools_add({
    NAS_ID  => $query_params->{NAS_ID},
    POOL_ID => $query_params->{POOL_ID},
  });
}

#**********************************************************
=head2 delete_equipment_nas_ip_pools_nasId_poolId($path_params, $query_params)

  Endpoint DELETE /equipment/nas/ip/pools/:nasId/:poolId/

=cut
#**********************************************************
sub delete_equipment_nas_ip_pools_nasId_poolId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Nas->nas_ip_pools_del({
    NAS_ID  => $path_params->{nasId},
    POOL_ID => $path_params->{poolId}
  });

  if (!$Nas->{errno}) {
    if ($Nas->{AFFECTED} && $Nas->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30032,
        errstr => "nasIpPool with id $path_params->{nasId} and poolId $path_params->{poolId} not exists",
      };
    }
  }

  return $Nas;
}

#**********************************************************
=head2 get_equipment_used_ports($path_params, $query_params)

  Endpoint DELETE /equipment/used/ports/

=cut
#**********************************************************
sub get_equipment_used_ports {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 200212,
    errstr => 'No parameter nasId and fullList. Required during using portsOnly parameter.',
  } if ($query_params->{PORTS_ONLY} && !$query_params->{NAS_ID});

  return {
    errno  => 200213,
    errstr => 'No parameter portsOnly. Required during using nasId parameter.',
  } if ($query_params->{NAS_ID} && !$query_params->{PORTS_ONLY});

  my @allowed_params = (
    'NAS_ID',
    'GET_MAC',
    'FULL_LIST',
    'PORTS_ONLY'
  );

  my %PARAMS = (
    COLS_UPPER => 1
  );
  foreach my $param (@allowed_params) {
    next if (!defined($query_params->{$param}));
    $PARAMS{$param} = $query_params->{$param};
  }

  # TODO: remove crutch, marked
  require Equipment::Ports;
  equipments_get_used_ports({
    %PARAMS
  });
}

#**********************************************************
=head2 post_equipment_nas_details($path_params, $query_params)

  Endpoint POST /equipment/nas/:id/details/

=cut
#**********************************************************
sub post_equipment_nas_details {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $nas_id = $path_params->{id};

  $Nas->info({ NAS_ID => $nas_id });

  if (!$Nas->{TOTAL} || $Nas->{TOTAL} < 1) {
    return $Errors->throw_error(1040001);
  }

  my $result = $Equipment->_add({ %{$query_params}, NAS_ID => $nas_id });
  return $result;
}

#**********************************************************
=head2 post_equipment_nas_details($path_params, $query_params)

  Endpoint POST /equipment/nas/netmap/positions/

=cut
#**********************************************************
sub post_equipment_nas_netmap_positions {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Equipment->equipment_netmap_position_add($query_params);
  return $result;
}

#**********************************************************
=head2 _validate_nas_group_add()

=cut
#**********************************************************
sub _validate_nas_group_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{NAME}) {
    my $groups = $Nas->nas_group_list({
      NAME      => $attr->{NAME} || '--',
      COLS_NAME => 1
    });

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno    => 21,
        errstr   => 'name is not valid',
        param    => 'name',
        type     => 'string',
        group_id => $groups->[0]->{id},
        name     => $attr->{NAME},
        reason   => "name already exists in group with id $groups->[0]->{id}"
      } ],
    } if (scalar @{$groups});
  }

  return {
    result => 'OK',
  };
}

1;
