package Equipment::Users;

use strict;
use warnings FATAL => 'all';

use Equipment;
my Equipment $Equipment;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    conf  => $CONF,
    db    => $db,
    admin => $admin
  };

  $Equipment = Equipment->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#********************************************************
=head2 cpe_info($attr) - Device information

  Arguments:
    $attr
      NAS_INFO - Nas info obj
      PORT     - Internet port
      NAS_ID   - NAS_ID
      RUN_CABLE_TEST - Run cable test
      FIELDS   - Show fields
      SILENT   - Silent mode
      SIMPLE   - Only CPE info

  Return
    $self
      CPE_INFO arr_hash_ref

=cut
#********************************************************
sub cpe_info {
  my $self = shift;
  my ($attr) = @_;

  $self->{CPE_INFO} = [];

  my $Nas_info = $attr->{NAS_INFO} || '';

  return $self if (!$attr->{NAS_ID} && !$Nas_info);

  if (!$attr->{NAS_INFO}) {
    my $nas_list = $Equipment->_list({
      NAS_MNG_HOST_PORT=> '_SHOW',
      NAS_MNG_USER     => '_SHOW',
      NAS_NAME         => '_SHOW',
      NAS_MNG_PASSWORD => '_SHOW',
      NAS_IP           => '_SHOW',
      TYPE_ID          => '_SHOW',
      MODEL_ID         => '_SHOW',
      MODEL_NAME       => '_SHOW',
      TYPE_NAME        => '_SHOW',
      VENDOR_ID        => '_SHOW',
      VENDOR_NAME      => '_SHOW',
      SNMP_TPL         => '_SHOW',
      SNMP_VERSION     => '_SHOW',
      PORT_SHIFT       => '_SHOW',
      PORTS            => '_SHOW',
      AUTO_PORT_SHIFT  => '_SHOW',
      STATUS           => '_SHOW',
      PORTS_WITH_EXTRA => '_SHOW',
      NAS_ID           => $attr->{NAS_ID},
      COLS_NAME        => 1
    });

    return $self if (!$nas_list || !scalar(@{$nas_list}));

    $Nas_info = $nas_list->[0];
  }

  my $nas_id = $Nas_info->{nas_id} || 0;
  my $fields = $attr->{FIELDS};

  my $SNMP_COMMUNITY = ($Nas_info->{nas_mng_password} || '')
    . '@'
    . ($Nas_info->{nas_mng_ip_port} || $Nas_info->{nas_ip} || '');

  # Type
  my $cpe_info;
  if ($Nas_info->{type_id} && $Nas_info->{type_id} == 4 && $attr->{PORT}) {
    ::load_module('Equipment::Pon_mng', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Equipment/Pon_mng'}));

    my $onu_id = 0; #$onu_list->[0]->{onu_snmp_id};
    my $onu_info_fields = $fields->{ONU}
      // $self->{conf}{EQUIPMENT_ONU_INFO_FIELDS}
      || 'CATV_PORTS_ADMIN_STATUS,CATV_PORTS_STATUS,DISTANCE,OLT_RX_POWER,ONU_DESC,ONU_IN_BYTE,ONU_LAST_DOWN_CAUSE,ONU_MAC_SERIAL,ONU_OUT_BYTE,ONU_PORTS_STATUS,ONU_RX_POWER,ONU_STATUS,TEMPERATURE,UPTIME';

    $cpe_info = main::pon_onu_state($onu_id, {
      VENDOR_ID      => $Nas_info->{vendor_id},
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      #ONU_SNMP_ID      => $snmp_onu_id,
      VERSION        => $Nas_info->{snmp_version},
      NAS_ID         => $nas_id || '',
      MODEL_NAME     => $Nas_info->{model_name},
      SHOW_FIELDS    => $onu_info_fields,
      ONU_DHCP_PORT  => $attr->{PORT},
      EQUIPMENT      => $Equipment,
      OUTPUT2RETURN  => 1,
      %$attr
    });
  }
  else {
    ::load_module('Equipment::Ports', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Equipment/Ports'}));

    #Stacking port
    if ($attr->{PORT} && $attr->{PORT} =~ /^(\d{2})(\d{2})$/) {
      my $stack = $1;
      my $port = $2;
      my ($sw_port, $sw_extra_ports) = split(/\+/, $Nas_info->{ports_with_extra});
      my $all_ports = $sw_port + ($sw_extra_ports || 0);
      $attr->{PORT} = ($stack + 1) * $all_ports + $port;
    }

    my $port_info_fields = $fields->{PORT}
      // $self->{conf}{EQUIPMENT_PORT_INFO_FIELDS}
      || 'PORT_STATUS,ADMIN_PORT_STATUS,PORT_IN,PORT_OUT,PORT_IN_ERR,PORT_OUT_ERR,PORT_IN_DISCARDS,PORT_OUT_DISCARDS,PORT_UPTIME,CABLE_TESTER';
    $port_info_fields =~ s/ //g;

    $cpe_info = main::equipment_port_info({
      SNMP_COMMUNITY  => $SNMP_COMMUNITY,
      VERSION         => $Nas_info->{snmp_version},
      PORT            => $attr->{PORT},
      RUN_CABLE_TEST  => $attr->{RUN_CABLE_TEST},
      PORT_SHIFT      => $Nas_info->{port_shift},
      AUTO_PORT_SHIFT => $Nas_info->{auto_port_shift},
      SNMP_TPL        => $Nas_info->{snmp_tpl},
      INFO_FIELDS     => $port_info_fields,
      SIMPLE          => $attr->{SIMPLE} || 0,
      %$attr
    });
  }

  if (ref $cpe_info eq 'ARRAY' && $attr->{SIMPLE}) {
    $cpe_info = {};
  }

  $self->{CPE_INFO} = $cpe_info;

  return $self;
}

#********************************************************
=head2 devices($attr) - User devices

  Arguments:
    $attr
      UID - Uid

  Return
    $user_list
      or
    $self->{DEVICES} arr_hash_ref

=cut
#********************************************************
sub devices {
  my $self = shift;
  my ($attr) = @_;

  my $devices = [];
  $self->{DEVICES} = $devices;

  return $devices if (!$attr->{UID});

  require Internet;
  Internet->import();
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  $devices = $Internet->user_list({
    UID         => $attr->{UID} || 1,
    NAS_ID      => '_SHOW',
    PORT        => '_SHOW',
    VLAN        => '_SHOW',
    SERVER_VLAN => '_SHOW',
    GROUP_BY    => 'internet.id',
    COLS_NAME   => 1,
  });

  $self->{DEVICES} = $devices;

  return $devices;
}

#********************************************************
=head2 devices_info($attr) - User devices

  Arguments:
    $attr
      UID: - UID

  Return
    $user_list
      or
    $self->{DEVICES} arr_hash_ref

=cut
#********************************************************
sub devices_info {
  my $self = shift;
  my ($attr) = @_;

  my %result = ();

  return \%result if (!$attr->{UID});

  my $devices = $self->devices({
    UID => $attr->{UID},
  });

  foreach my $device (@{$devices}) {
    my $info = $self->cpe_info({
      NAS_ID => $device->{nas_id},
      PORT   => $device->{port},
      SIMPLE => 1,
      SILENT => 1,
    });
    next if !$info->{CPE_INFO} || ref $info->{CPE_INFO} ne 'HASH';

    my $id = (sort keys %{$info->{CPE_INFO}})[0];
    $result{$id} = $info->{CPE_INFO}{$id} if ($id);
  }

  return \%result;
}

1;
