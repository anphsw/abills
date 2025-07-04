=head1 NAME

  BDCOM

=cut

use strict;
use warnings;
use Abills::Base qw(in_array);
use Abills::Filters qw(bin2mac _mac_former dec2hex);
use Equipment::Misc qw(equipment_get_telnet_tpl);
require Equipment::Snmp_cmd;

our (
  %lang,
  $html,
  %conf,
  %ONU_STATUS_TEXT_CODES
);

#**********************************************************
=head2 _bdcom_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _bdcom_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    VERSION  => $attr->{SNMP_VERSION} || 2,
    TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
    %{$attr},
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1 && $ports_info->{$key}{PORT_NAME} =~ /(.PON)(\d+\/\d+)$/i) {
      my $type = lc($1);
      #my $branch = decode_port($key);
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _bdcom_onu_list($port_list, $attr)

  Arguments:
    $port_list  - OLT ports list
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      QUERY_OIDS
      NAS_ID
      TIMEOUT

  Returns:
    $onu_list [arra_of_hash]

=cut
#**********************************************************
sub _bdcom_onu_list {
  my ($port_list, $attr) = @_;

  #my $cols = ['PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT'];
  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
    VERSION  => $attr->{SNMP_VERSION} || 2,
    %{$attr},
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

  my $ether_ports = $snmp_info->{PORTS};

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
    VERSION  => $attr->{SNMP_VERSION} || 2,
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  my @onu_indexes = ();
  foreach my $line (@$ports_descr) {
    next if (!$line);
    my ($interface_index, $type) = split(/:/, $line, 2);
    if ($type && $type =~ /(.+):(.+)/) {
      push @onu_indexes, $interface_index;
    }
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _bdcom({ TYPE => $pon_type, MODEL => $attr->{MODEL_NAME} });
    if ($attr->{QUERY_OIDS} && @{$attr->{QUERY_OIDS}}) {
      %$snmp = map { $_ => $snmp->{$_} } @{$attr->{QUERY_OIDS}};
    }

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    #Get info
    my %onu_snmp_info = ();
    foreach my $oid_name (keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
      next if ($pon_type eq 'epon' && $oid_name eq 'ONU_MAC_SERIAL'); #look to the comment below for the explaination

      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};

        print "$oid_name -- " . ($snmp->{$oid_name}->{NAME} || 'Unknown oid') . '--' . ($snmp->{$oid_name}->{OIDS} || 'unknown') . " \n" if ($debug > 1);

        my $result = snmp_get({
          TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
          VERSION  => $attr->{SNMP_VERSION} || 2,
          %{$attr},
          OID     => $oid,
          WALK    => 1
        });

        foreach my $line (@$result) {
          next if (!$line);
          my ($interface_index, $value) = split(/:/, $line, 2);
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$interface_index}{$oid_name} = $value;
        }
      }
    }

    #after OID onuMacAddr(1.3.6.1.4.1.3320.101.10.4.1.1) there are OID onuIpAddr(1.3.6.1.4.1.3320.101.10.4.1.2)
    #if we will use snmpwalk (using getbulk, as default) on onuMacAddr, we will eventually request several lines from onuIpAddr
    #and that is the problem, because BDCOMs often responds to onuIpAddr very slowly, and request often timeouts because of that, and we may not get last response with some MACs in it
    #if we will use snmpwalk without getbulk, we still request one line from onuIpAddr, and snmpwalk without bulk is slow
    #so, as we know all ONU IDs from other requests, we use snmp_get only for onuMacAddr with these OIDs, not touching slow onuIpAddr, with multiple OIDs per request for speed
    my $profile;
    if ($pon_type eq 'epon') {
      my $oid_name = 'ONU_MAC_SERIAL';
      my $oid = $snmp->{$oid_name}->{OIDS};
      my $function = $snmp->{$oid_name}->{PARSER};
      my $macs_per_request = 40;

      print "$oid_name -- " . ($snmp->{$oid_name}->{NAME} || 'Unknown oid') . '--' . ($snmp->{$oid_name}->{OIDS} || 'unknown') . " \n" if ($debug > 1);

      while (my @part = splice @onu_indexes, 0, $macs_per_request) {
        my @oids = map { $oid . '.' . $_ } @part;

        my $result = snmp_get({
          VERSION  => $attr->{SNMP_VERSION} || 2,
          TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
          %{$attr},
          OID     => \@oids,
        });

        while (@$result) {
          my $interface_index = shift @part;
          my $result_ = shift @$result;
          if ($function && defined(&{$function})) {
            ($result_) = &{\&$function}($result_);
          }

          $onu_snmp_info{$interface_index}{$oid_name} = $result_;
        }
      }
    }
    elsif ($pon_type eq 'gpon') {
      $profile = _bdcom_get_profiles($attr);
    }

    foreach my $line (@$ports_descr) {
      next if (!$line);
      my ($interface_index, $type) = split(/:/, $line, 2);
      if ($type && $type =~ /(.+):(.+)/) {
        $type =~ /(\d+)\/(\d+):(\d+)/;
        my $device_index = $3;
        my $branch_index = $2;
        my %onu_info = ();

        if ($onu_snmp_info{$interface_index}) {
          %onu_info = %{$onu_snmp_info{$interface_index}};
        }

        $onu_info{PORT_ID} = $port_ids{$1 . '/' . $branch_index};
        $onu_info{ONU_ID} = $device_index;
        $onu_info{ONU_SNMP_ID} = $interface_index;
        $onu_info{PON_TYPE} = $pon_type;

        $type =~ /\/(\d+)/;
        my $olt_num = $1 + $ether_ports;
        my $port_id = sprintf("%02x%02x", $olt_num, $device_index);
        $onu_info{ONU_DHCP_PORT} = $port_id;

        foreach my $oid_name (keys %{$snmp}) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info') {
            next;
          }
          elsif ($oid_name =~ /POWER|TEMPERATURE/
            && defined($onu_snmp_info{$interface_index}{ONU_STATUS})
            && $onu_snmp_info{$interface_index}{ONU_STATUS} ne '3') {
            $onu_info{$oid_name} = 0;
            next;
          }
          elsif ($oid_name eq 'VLAN') {
            my $onu_status = $onu_snmp_info{$interface_index}{ONU_STATUS} || 0;
            if ($onu_status) {
              if ($pon_type eq 'gpon') {
                my $onu_profile = $onu_snmp_info{$interface_index. '.1'}{'PROFILE'};
                if ($onu_profile) {
                  $onu_info{$oid_name} = $profile->{$onu_profile}{VLAN} || 0;
                }
              }
              elsif ($onu_status == 3 || $onu_status == 4 || $onu_status == 5) {
                $onu_info{$oid_name} = $onu_snmp_info{$interface_index . ".1"}{VLAN} || 0;
              }
            }
            next;
          }
        }
        push @onu_list, { %onu_info };
      }
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _bdcom($attr)

  Arguments:
    $attr
      TYPE - PON type (epon, gpon)
      MODEL - OLT model

=cut
#**********************************************************
sub _bdcom {
  my ($attr) = @_;

  my $snmp = _get_snmp('bdcom');

  # P3616-2TE need test
  if ($attr->{MODEL}) {
    if ($attr->{MODEL} =~ /OLT P3310|P3310C|P3310D|P3608$|P3612-2TE/i) {
      $snmp->{epon}->{OLT_RX_POWER}->{OIDS} = '.1.3.6.1.4.1.3320.101.108.1.3';
    }

    if ($attr->{MODEL} =~ /P3310D/i) {
      delete $snmp->{epon}->{catv_port_manage};
    }
  }

  if ($attr->{TYPE}) {
    return $snmp->{$attr->{TYPE}};
  }

  return $snmp;
}


#**********************************************************
=head2 _bdcom_get_profiles($attr)

  Arguments:
    $attr

  Results:
    \%profiles{$index}{PARAMETERS}=$value

=cut
#**********************************************************
sub _bdcom_get_profiles {
  my ($attr)=@_;

  my %profiles = ();
  my $profile_info = snmp_get({
    VERSION  => $attr->{SNMP_VERSION} || 2,
    TIMEOUT  => $attr->{SNMP_TIMEOUT} || 2,
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.4.1.3320.10.6.1.1.1.4'
  });

  foreach my $profile ( @$profile_info ) {
    my ($index, $value)=split(/:/, $profile);
    $profiles{$index}{VLAN}=$value;
  }

  return \%profiles;
}

#**********************************************************
=head2 _bdcom_pon_vlan() - Tempory VLAN function

=cut
#**********************************************************
sub _bdcom_pon_vlan {

  return q{};
}

#**********************************************************
=head2 _bdcom_sec2time($sec)

=cut
#**********************************************************
sub _bdcom_sec2time {
  my ($sec)=@_;

  return sec2time($sec, { str => 1 });
}

#**********************************************************
=head2 _bdcom_mac_behind_onu($value) - parse FDB SNMP line to MAC and VLAN

=cut
#**********************************************************
# sub _bdcom_mac_behind_onu {
#   my ($value) = @_;
#
#   my ($vlan, $mac) = split(/:/, $value, 2);
#   ($vlan) = split(/\./, $vlan);
#   $mac = bin2mac($mac);
#
#   return $value, { mac => $mac, vlan => $vlan };
# }

#**********************************************************
=head2 _bdcom_onu_status()

=cut
#**********************************************************
sub _bdcom_onu_status {
  my ($pon_type) = @_;

  my %status = ();
  if ($pon_type eq 'epon') {
    %status = (
      0 => $ONU_STATUS_TEXT_CODES{AUTHENTICATED},
      1 => $ONU_STATUS_TEXT_CODES{REGISTERED},
      2 => $ONU_STATUS_TEXT_CODES{DEREGISTERED},
      3 => $ONU_STATUS_TEXT_CODES{AUTO_CONFIG},
      4 => $ONU_STATUS_TEXT_CODES{LOST},
      5 => $ONU_STATUS_TEXT_CODES{STANDBY},
    );
  }
  elsif ($pon_type eq 'gpon') {
    %status = (
      0 => $ONU_STATUS_TEXT_CODES{OFFLINE},  #off-line
      1 => $ONU_STATUS_TEXT_CODES{INACTIVE}, #inactive
      2 => $ONU_STATUS_TEXT_CODES{DISABLED}, #disable
      3 => $ONU_STATUS_TEXT_CODES{ONLINE},   #active
    );
  }

  return \%status;
}

#**********************************************************
=head2 _bdcom_set_desc($attr) - Set Description to OLT ports

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _bdcom_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    $oid = '1.3.6.1.2.1.31.1.1.1.18.' . $attr->{PORT};
  }

  my $result = snmp_set({
    %$attr,
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return $result;
}

#**********************************************************
=head2 _bdcom_convert_power();

=cut
#**********************************************************
sub _bdcom_convert_power {
  my ($power) = @_;
  $power //= 0;

  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = $power * 0.1;
  }

  return $power;
}

#**********************************************************
=head2 _bdcom_convert_temperature();

=cut
#**********************************************************
sub _bdcom_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _bdcom_convert_voltage();

=cut
#**********************************************************
sub _bdcom_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.0001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _bdcom_convert_distance_epon();

=cut
#**********************************************************
sub _bdcom_convert_distance_epon {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _bdcom_convert_distance_gpon();

=cut
#**********************************************************
sub _bdcom_convert_distance_gpon {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.0001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _bdcom_convert_onu_last_down_cause($last_down_cause_code)

=cut
#**********************************************************
sub _bdcom_convert_onu_last_down_cause {
  my ($last_down_cause_code) = @_;

  my %last_down_cause_hash = (
    0  => 'none',
    1  => 'dying-gasp',
    2  => 'laser-always-on',
    3  => 'admin-down',
    4  => 'omcc-down',
    5  => 'unknown',
    6  => 'pon-los',
    7  => 'lcdg',
    8  => 'wire-down',
    9  => 'omci-mismatch',
    10 => 'password-mismatch',
    11 => 'reboot',
    12 => 'ranging-failed'
  );

  return $last_down_cause_hash{$last_down_cause_code};
}

#**********************************************************
=head2 _bdcom_get_fdb($attr);

  Arguments:
    $attr
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      NAS_INFO       => $attr->{NAS_INFO},
      SNMP_TPL       => $attr->{SNMP_TPL},

  Results:
    $fdb_list (hash)
       { mac } -> { params }

=cut
#**********************************************************
sub _bdcom_get_fdb {
  my ($attr) = @_;
  my %fdb_list = ();

  my $debug = $attr->{DEBUG} || 0;

  my $system_descr = snmp_get({
    %$attr,
    OID => '1.3.6.1.2.1.1.1.0'
  });

  #on new versions of firmwares BDCOM supports OID dot1qTpFdbPort(1.3.6.1.2.1.17.7.1.2.2.1.2)
  #BDCOM's FDB OID (ifFdbReadByPortMacAddress, 1.3.6.1.4.1.3320.152.1.1.3) on these versions works very slowly, it's unusable
  #source: https://forum.nag.ru/index.php?/topic/154618-bdcom-p3310c-mac-adresa-za-onu-cherez-snmp-proshivka-1010f-66461/
  #firmware versions known to support dot1qTpFdbTable and respond slowly to ifFdbReadByPortMacAddress:
  #Version 10.1.0D
  #Version 10.1.0E
  #Version 10.1.0F
  #firmware versions known to not support dot1qTpFdbTable (ifFdbReadByPortMacAddress is working):
  #Version 10.1.0B
  if ($system_descr && $system_descr !~ /Version 10\.1\.0B/) {
    return default_get_fdb($attr);
  }

  #TODO: FDB getting for Version 10.1.0B is slow and can be optimized
  #there are slow to respond ports without FDB data, and, when using snmpwalk (bulk) for every port, we are querying them multiple times
  #simple snmpwalk 1.3.6.1.4.1.3320.152.1.1.3 from console works few times faster than this code
  print "BDCOM mac " if ($debug > 1);
  my $perl_scalar = _get_snmp_oid($attr->{SNMP_TPL} || 'bdcom.snmp', $attr);

  my ($expr_, $values, $attribute);
  my @EXPR_IDS = ();

  if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
    $perl_scalar->{FDB_EXPR} =~ s/\%\%/\\/g;
    ($expr_, $values, $attribute) = split(/\|/, $perl_scalar->{FDB_EXPR} || '');
    @EXPR_IDS = split(/,/, $values);
  }

  #Get port name list
  my $ports_name;
  my $port_name_oid = $perl_scalar->{ports}->{PORT_NAME}->{OIDS} || '';
  if ($port_name_oid) {
    $ports_name = snmp_get({
      VERSION  => $attr->{SNMP_VERSION} || 2,
      TIMEOUT  => $attr->{SNMP_TIMEOUT} || 5,
      %$attr,
      OID     => $port_name_oid,
      WALK    => 1
    });
  }

  return 1 if (!$ports_name);

  my $count = 0;
  foreach my $iface (@$ports_name) {
    next if (!$iface);
    print "Iface: $iface \n" if ($debug > 1);
    my ($id, $port_name) = split(/:/, $iface, 2);

    #get macs
    my $mac_list = snmp_get({
      VERSION  => $attr->{SNMP_VERSION} || 2,
      TIMEOUT  => $attr->{SNMP_TIMEOUT} || 4,
      %$attr,
      WALK    => 1,
      OID     => '.1.3.6.1.4.1.3320.152.1.1.3.' . $id,
    });

    foreach my $line (@$mac_list) {
      #print "$line <br>";
      next if (!$line);
      my $vlan;
      my $mac_dec;
      my $port = $id;

      if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
        my %result = ();

        if (my @res = ($line =~ /$expr_/g)) {
          for (my $i = 0; $i <= $#res; $i++) {
            $result{$EXPR_IDS[$i]} = $res[$i];
          }
        }

        if ($result{MAC_HEX}) {
          $result{MAC} = _mac_former($result{MAC_HEX}, { BIN => 1 });
        }

        if ($result{PORT_DEC}) {
          $result{PORT} = dec2hex($result{PORT_DEC});
        }

        $vlan = $result{VLAN} || 0;
        $mac_dec = $result{MAC} || '';
      }

      my $mac = _mac_former($mac_dec);

      $mac_dec //= $count;

      # 1 mac
      $fdb_list{$mac_dec}{1} = $mac;
      # 2 port
      $fdb_list{$mac_dec}{2} = $port;
      # 3 status
      # 4 vlan
      $fdb_list{$mac_dec}{4} = $vlan;
      # 5 port name
      $fdb_list{$mac_dec}{5} = $port_name;
      $count++;
    }

    #    if($count > 3) {
    #      last;
    #    }
  }

  return %fdb_list;
}

#**********************************************************
=head2 _bdcom_unregister($attr) - get unregistered (rejected) ONUs

  Needed only when there are manual registration (gpon onu-authen-method sn, epon onu-authen-method mac)
  Uses Telnet, because there are no known SNMP OIDs for unregistered data

  Arguments:
    $attr
      NAS_INFO
        NAS_MNG_USER
        NAS_MNG_PASSWORD
        NAS_MNG_IP_PORT
        MODEL_NAME
      DEBUG

  Returns:
    \@unregister - arrayref of unregistered ONUs:
    [
      {
        pon_type   => ...
        mac_serial => ...
        branch     => ...
      },
      ...
    ]

=cut
#**********************************************************
sub _bdcom_unregister {
  my ($attr) = @_;

  if (!$conf{EQUIPMENT_BDCOM_ENABLE_ONU_REGISTRATION}) {
    return [];
  }

  my $debug = $attr->{DEBUG} || 0;

  my $load_data = load_pmodule('Net::Telnet', { SHOW_RETURN => 1 });
  if ($load_data) {
    print "$load_data";
    return [];
  }

  my $user_name = $attr->{NAS_INFO}->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}->{NAS_MNG_PASSWORD};
  my $enable_password = $conf{EQUIPMENT_BDCOM_ENABLE_PASSWORD} || $password;

  my $Telnet = Net::Telnet->new(
    Prompt  => '/.*(#|>)$/',
    Timeout => 15,
    Errmode => 'return'
  );

  my ($ip) = split(/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT});

  $Telnet->open(
    Host => $ip
  );

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->login($user_name, $password);

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->print('enable');
  my ($waitfor_prematch, $waitfor_match) = $Telnet->waitfor(Match => '/(#|>)$/', String => 'password:');
  if ($waitfor_match eq 'password:') {
    $Telnet->print($enable_password);
    ($waitfor_prematch, $waitfor_match) = $Telnet->waitfor('/.*(#|>)$/');
  }

  if ($waitfor_match =~ />$/) {
    print "enable failed: $waitfor_prematch\n";
    return [];
  }

  my @unregister = ();
  if ($attr->{NAS_INFO}->{MODEL_NAME} =~ /\bGP/i) { #seems that model_name of GPON OLT always starts with GP
    my @rejected_onus = $Telnet->cmd('show gpon onu-rejected-information');
    foreach my $line (@rejected_onus) {
      if ($line =~ /\d+\s+([0-9A-F]{16})\s+GPON(\d+\/\d+)/) {
        push @unregister,
          {
            pon_type   => 'gpon',
            mac_serial => $1,
            branch     => $2
          };
      }
    }
  }
  else { #EPON
    my @rejected_onus = $Telnet->cmd('show epon rejected-onu');

    my $current_branch = '';
    foreach my $line (@rejected_onus) {
      if ($debug > 6) {
        print $line."\n";
      }

      if ($line =~ /ONU rejected to register on interface EPON(\d+\/\d+):/) {
        $current_branch = $1;
      }

      if ($line =~ /\s*([0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4})\s*/) {
        my $mac_serial = $1;
        $mac_serial =~ s/([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})/$1:$2:$3:$4:$5:$6/;
        push @unregister,
          {
            pon_type   => 'epon',
            mac_serial => $mac_serial,
            branch     => $current_branch
          };
      }
    }
  }

  if ($Telnet->errmsg) {
    print "Telnet error: " . $Telnet->errmsg;
    return [];
  }

  $Telnet->close();

  return \@unregister;
}

#**********************************************************
=head2 _bdcom_get_onu_config($attr) - Connect to OLT over telnet and get ONU config

  Arguments:
    $attr
      NAS_INFO
        NAS_MNG_IP_PORT
        NAS_MNG_USER
        NAS_MNG_PASSWORD
      PON_TYPE
      BRANCH
      ONU_ID

  Returns:
    @result - array of [cmd, cmd_result]

  commands (EPON):
    enable
    show running-config interface EPON %BRANCH%:%ONU_ID%

  commands (GPON):
    enable
    show running-config interface GPON %BRANCH%:%ONU_ID%


=cut
#**********************************************************
sub _bdcom_get_onu_config {
  my ($attr) = @_;

  my $pon_type = $attr->{PON_TYPE};
  my $branch = $attr->{BRANCH};
  my $onu_id = $attr->{ONU_ID};

  my $username = $attr->{NAS_INFO}->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}->{NAS_MNG_PASSWORD};
  my $enable_password = $conf{EQUIPMENT_BDCOM_ENABLE_PASSWORD} || $password;

  my ($ip, undef) = split (/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}, 2);

  my @cmds = @{equipment_get_telnet_tpl({
    TEMPLATE => "bdcom_get_onu_config_$pon_type.tpl",
    BRANCH   => $branch,
    ONU_ID   => $onu_id
  })};

  if (!@cmds) {
    @cmds = @{equipment_get_telnet_tpl({
      TEMPLATE => "bdcom_get_onu_config_$pon_type.tpl.example",
      BRANCH   => $branch,
      ONU_ID   => $onu_id
    })};
  }

  if (!@cmds) {
    return ([$lang{ERROR}, $lang{FAILED_TO_GET_TELNET_CMDS_FROM_FILE} . " bdcom_get_onu_config_$pon_type.tpl"]);
  }

  use Abills::Telnet;

  my $t = Abills::Telnet->new();

  $t->set_terminal_size(256, 1000); #if terminal size is small, BDCOM does not print all of command output, but prints first *terminal_height* lines, prints '--More--' and lets user scroll it manually
  $t->prompt('\n.*(#|>)$');

  if (!$t->open($ip)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  if (!$t->login($username, $password)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  my @result = ();

  foreach my $cmd (@cmds) {
    if ($cmd eq 'enable') {
      $t->print('enable');
      my $waitfor_prematch = $t->waitfor('(\n.*(#|>)$)|password:$');
      my $waitfor_match = $t->{LAST_PROMPT};
      if ($waitfor_match eq 'password:') {
        $t->print($enable_password);
        $waitfor_prematch = $t->waitfor('\n.*(#|>)$');
        $waitfor_match = $t->{LAST_PROMPT};
      }

      if ($waitfor_match =~ />$/) {
        return [$lang{ERROR}, "enable failed: " . join("\n", @$waitfor_prematch)];
      }
      next;
    }

    my $cmd_result = $t->cmd($cmd);
    if ($cmd_result) {
      push @result, [$cmd, join("\n", @$cmd_result)];
    }
    else {
      push @result, [$cmd, $lang{ERROR} . ' Telnet: ' . $t->errstr()];
    }
  }

  if ($t->errstr()) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
  }

  return @result;
}

#**********************************************************
=head2 _bdcom_convert_catv_port_admin_status($status_code);

=cut
#**********************************************************
sub _bdcom_convert_catv_port_admin_status {
  my ($status_code) = @_;

  my $status = 'Unknown';

  my %status_hash = (
    1 => 'Enable',
    2 => 'Disable',
  );

  if ($status_code && $status_hash{ $status_code }) {
    $status = $status_hash{ $status_code };
  }

  return $status;
}

#**********************************************************
=head2 _bdcom_convert_video_power($video_power);

=cut
#**********************************************************
sub _bdcom_convert_video_power {
  my ($video_power) = @_;

  return 0 if (!defined $video_power || $video_power == 0);

  return $video_power * 0.1;
}

1
