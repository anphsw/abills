=head1 NAME

  ZTE snmp monitoring and managment

  VERSION: 0.02

=head1 MODELS

  C300
  C320
  C320

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(_bp in_array int2byte convert);
use Abills::Filters qw(bin2mac bin2hex _mac_former);
use Equipment::Misc qw(equipment_get_telnet_tpl);

our (
  %lang,
  $html,
  %conf,
  %html_color,
  $base_dir,
  %ONU_STATUS_TEXT_CODES
);

my %type_name = (
  1  => 'epon_olt_virtualIfBER', # gpon on C300
  3  => 'epon-onu',
  4  => 'pon_onu', #can be either epon or gpon
  6  => 'type6',
  9  => 'epon_onu',
  10 => 'gpon_onu'
);

#**********************************************************
=head2 _zte_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _zte_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT,PORT_IN_ERR,PORT_OUT_ERR',
  });

  my $ports_info_hash = ();

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key} && $ports_info->{$key}{PORT_TYPE}
      && $ports_info->{$key}{PORT_TYPE} =~ /^300|250$/
      && $ports_info->{$key}{PORT_NAME} =~ /(.pon)_(.+)$/) {

      my $type = $1;
      my $branch = $2;
      my ($shelf, $slot, $olt) = $branch =~ /^(\d+)\/(\d+)\/(\d+)/;
      $shelf++ if ($shelf eq '0');
      my $port_snmp_id = _zte_encode_port(1, $shelf, $slot, $olt);
      my $port_descr;

      $ports_info_hash->{$port_snmp_id} = $ports_info->{$key};
      $ports_info_hash->{$port_snmp_id}{BRANCH} = $branch;
      $ports_info_hash->{$port_snmp_id}{PON_TYPE} = $type;

      $ports_info_hash->{$port_snmp_id}{SNMP_ID} = $port_snmp_id;
      if ($type eq 'gpon') {
        $port_descr = snmp_get({ %{$attr},
          OID => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1.' . $port_snmp_id,
        });
      }
      else {
        $port_descr = snmp_get({ %{$attr},
          OID => '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1.' . $port_snmp_id,
        });
      }

      $ports_info_hash->{$port_snmp_id}{BRANCH_DESC} = $port_descr;
    }
  }

  return \%{$ports_info_hash};
}

#**********************************************************
=head2 _zte_onu_list($attr) -

  Arguments:
    $port_list
    $attr
      MODEL_NAME

  Results:


=cut
#**********************************************************
sub _zte_onu_list {
  my ($port_list, $attr) = @_;

  my @all_rows = ();
  my %pon_types = ();
  my %port_ids = ();

  foreach my $snmp_id (keys %{$port_list}) {
    $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
  }

  foreach my $type (keys %pon_types) {
    my $snmp = _zte({ TYPE => $type });
    if ($attr->{QUERY_OIDS} && @{$attr->{QUERY_OIDS}}) {
      %$snmp = map { $_ => $snmp->{$_} } @{$attr->{QUERY_OIDS}};
    }

    if ($type eq 'epon') {
      my $onu_status_list = snmp_get({
        %$attr,
        WALK => 1,
        OID  => $snmp->{ONU_STATUS}->{OIDS},
      });

      if (ref $onu_status_list ne 'ARRAY') {
        next;
      }

      foreach my $line (@{$onu_status_list}) {
        next if (!$line);
        my ($interface_index, $status) = split(/:/, $line, 2);
        my $port_id = _zte_decode_onu($interface_index, {
          MODEL_NAME => $attr->{MODEL_NAME},
        });

        my $port_dhcp_id = _zte_dhcp_port({
          PORT_ID => $interface_index,
          PON_TYPE => 'epon',
          MODEL_NAME => $attr->{MODEL_NAME}
        });

        $port_id =~ /^(\d+)\/(\d+)\/(\d+):(\d+)/;
        my $onu_id = $4;
        my $olt_port = $1 . '/' . $2 . '/' . $3;
        my %onu_info = ();

        $onu_info{PORT_ID} = $port_ids{$olt_port};
        $onu_info{ONU_ID} = $onu_id;
        $onu_info{ONU_SNMP_ID} = $interface_index;
        $onu_info{PON_TYPE} = $type;
        $onu_info{ONU_DHCP_PORT} = $port_dhcp_id;

        foreach my $oid_name (keys %{$snmp}) {

          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'catv_port_manage' || $oid_name eq 'LLID' || $snmp->{$oid_name}->{SKIP}) { #XXX add SKIP for all these oids?
            next;
          }
          elsif ($oid_name =~ /POWER|TEMPERATURE/ && $status ne '3') {
            $onu_info{$oid_name} = '';
            next;
          }
          elsif ($oid_name eq 'ONU_STATUS') {
            $onu_info{$oid_name} = $status;
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "epon $oid_name  NAME: " . ($snmp->{$oid_name}->{NAME} || q{-}) . " OID: " . ($snmp->{$oid_name}->{OIDS} || q{}) . "\n";
          }

          my $oid_value = '';
          if ($snmp->{$oid_name}->{OIDS}) {
            my $oid = $snmp->{$oid_name}->{OIDS} . '.' . $interface_index;
            $oid_value = snmp_get({ %{$attr}, OID => $oid, SILENT => 1, WALK => $snmp->{$oid_name}->{WALK} });

            # if ($oid_value && ref $oid_value eq 'ARRAY') {
            #   $oid_value = join(', ', @$oid_value);
            # }
          }

          my $function = $snmp->{$oid_name}->{PARSER};
          if ($function && defined(&{$function})) {
            my $secocond_value = q{};
            ($oid_value, $secocond_value) = &{\&$function}($oid_value);
            if($secocond_value) {
              $oid_value = $secocond_value;
            }
          }
          $onu_info{$oid_name} = $oid_value;

          # if ($oid_name eq 'VLAN') {
          #   print " -- $oid_name ->  ";
          #   print $oid_value;
          #   print "// \n";
          # }

        }
        push @all_rows, { %onu_info };
      }
    }
    #Gpon
    else {
      foreach my $snmp_id (keys %{$port_list}) {
        my %total_info = ();
        next if ($port_list->{$snmp_id}{PON_TYPE} ne $type);
        my $cols = [ 'PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT' ];
        foreach my $oid_name (keys %{$snmp}) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'catv_port_manage' || $snmp->{$oid_name}->{SKIP}) {
            next;
          }

          push @{$cols}, $oid_name;
          my $oid = $snmp->{$oid_name}->{OIDS};
          if (!$oid) {
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "gpon $oid_name NAME: $snmp->{$oid_name}->{NAME} OID: $snmp->{$oid_name}->{OIDS}.$snmp_id \n";
          }

          my $values = snmp_get({ %{$attr},
            WALK    => 1,
            OID     => $oid . '.' . $snmp_id,
            TIMEOUT => 25
          });

          if (!$values) {
            next;
          }

          foreach my $line (@{$values}) {
            next if (!$line || $line !~ /\d+:.+/);
            my ($onu_id, $oid_value) = split(/:/, $line, 2);
            $onu_id =~ s/\.\d+//;
            if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
              print $oid . ' -> ' . "$onu_id, $oid_value \n";
            }
            my $function = $snmp->{$oid_name}->{PARSER};
            if ($function && defined(&{$function})) {
              ($oid_value) = &{\&$function}($oid_value);
            }
            $total_info{$oid_name}{$snmp_id . '.' . $onu_id} = $oid_value;
          }
        }

        foreach my $key (keys %{$total_info{ONU_STATUS}}) {
          my %onu_info = ();
          my ($branch, $onu_id) = split(/\./, $key, 2);
          my $port_dhcp_id = _zte_dhcp_port({
            PORT_ID => $branch,
            ONU => $onu_id,
            PON_TYPE => 'gpon',
            MODEL_NAME => $attr->{MODEL_NAME}
          });

          for (my $i = 0; $i <= $#{$cols}; $i++) {
            my $value = '';
            my $oid_name = $cols->[$i];

            if ($oid_name eq 'ONU_ID') {
              $value = $onu_id;
            }
            elsif ($oid_name eq 'PORT_ID') {
              $value = $port_list->{$snmp_id}->{ID};
            }
            elsif ($oid_name eq 'PON_TYPE') {
              $value = $type;
            }
            elsif ($oid_name eq 'ONU_DHCP_PORT') {
              $value = $port_dhcp_id;
            }
            elsif ($oid_name eq 'ONU_SNMP_ID') {
              $value = $key;
            }
            #            elsif($oid_name eq 'MAC_SERIAL') {
            #              $value = uc(join('', unpack("AAAAH*", $value)));
            #            }
            else {
              $value = $total_info{$cols->[$i]}{$key};
            }
            $onu_info{$oid_name} = $value;
          }
          push @all_rows, { %onu_info };
        }
      }
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _zte_onu_list2($attr) -

=cut
#**********************************************************
sub _zte_onu_list2 { #TODO: delete?
  my ($port_list, $attr) = @_;

  my @all_rows = ();
  my %pon_types = ();
  my %port_ids = ();

  foreach my $snmp_id (keys %{$port_list}) {
    $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
  }

  foreach my $type (keys %pon_types) {
    my $snmp = _zte({ TYPE => $type });
    if ($type eq 'epon') {
      my $onu_status_list = snmp_get({
        %$attr,
        WALK => 1,
        OID  => $snmp->{ONU_STATUS}->{OIDS},
      });

      foreach my $line (@{$onu_status_list}) {
        my ($interface_index, $status) = split(/:/, $line, 2);
        my $port_id = _zte_decode_onu($interface_index, { MODEL_NAME => $attr->{MODEL_NAME} });
        my $port_dhcp_id = _zte_decode_onu($interface_index, { TYPE => 'dhcp', MODEL_NAME => $attr->{MODEL_NAME} });
        $port_id =~ /^(\d+)\/(\d+)\/(\d+):(\d+)/;
        my $onu_id = $4;
        my $olt_port = $1 . '/' . $2 . '/' . $3;
        my %onu_info = ();

        $onu_info{PORT_ID} = $port_ids{$olt_port};
        $onu_info{ONU_ID} = $onu_id;
        $onu_info{ONU_SNMP_ID} = $interface_index;
        $onu_info{PON_TYPE} = $type;
        $onu_info{ONU_DHCP_PORT} = $port_dhcp_id;

        foreach my $oid_name (keys %{$snmp}) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'catv_port_manage' || $snmp->{$oid_name}->{SKIP}) {
            next;
          }
          elsif ($oid_name =~ /POWER|TEMPERATURE/ && $status ne '3') {
            $onu_info{$oid_name} = '';
            next;
          }
          elsif ($oid_name eq 'ONU_STATUS') {
            $onu_info{$oid_name} = $status;
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "epon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS} \n";
          }

          my $oid_value = '';
          if ($snmp->{$oid_name}->{OIDS}) {
            my $oid = $snmp->{$oid_name}->{OIDS} . '.' . $interface_index;
            $oid_value = snmp_get({ %{$attr}, OID => $oid, SILENT => 1 });
          }

          my $function = $snmp->{$oid_name}->{PARSER};
          if ($function && defined(&{$function})) {
            ($oid_value) = &{\&$function}($oid_value);
          }
          $onu_info{$oid_name} = $oid_value;
        }
        push @all_rows, { %onu_info };
      }
    }
    else {
      foreach my $snmp_id (keys %{$port_list}) {
        my %total_info = ();
        next if ($port_list->{$snmp_id}{PON_TYPE} ne $type);
        my $cols = [ 'PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT' ];
        foreach my $oid_name (keys %{$snmp}) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'catv_port_manage' || $snmp->{$oid_name}->{SKIP}) {
            next;
          }

          push @{$cols}, $oid_name;
          my $oid = $snmp->{$oid_name}->{OIDS};
          if (!$oid) {
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "gpon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS}.$snmp_id \n";
          }

          my $values = snmp_get({ %{$attr},
            WALK    => 1,
            OID     => $oid . '.' . $snmp_id,
            TIMEOUT => 25
          });

          foreach my $line (@{$values}) {
            next if (!$line || $line !~ /\d+:.+/);
            my ($onu_id, $oid_value) = split(/:/, $line, 2);
            $onu_id =~ s/\.\d+//;
            if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
              print $oid . '->' . "$onu_id, $oid_value \n";
            }
            my $function = $snmp->{$oid_name}->{PARSER};
            if ($function && defined(&{$function})) {
              ($oid_value) = &{\&$function}($oid_value);
            }
            $total_info{$oid_name}{$snmp_id . '.' . $onu_id} = $oid_value;
          }
        }

        foreach my $key (keys %{$total_info{ONU_STATUS}}) {
          my %onu_info = ();
          my ($branch, $onu_id) = split(/\./, $key, 2);
          my $port_dhcp_id = _zte_decode_onu($branch, { TYPE => 'dhcp' });
          for (my $i = 0; $i <= $#{$cols}; $i++) {
            my $value = '';
            my $oid_name = $cols->[$i];
            my $num = sprintf("%03d", $onu_id);
            if ($oid_name eq 'ONU_ID') {
              $value = $onu_id;
            }
            elsif ($oid_name eq 'PORT_ID') {
              $value = $port_list->{$snmp_id}->{ID};
            }
            elsif ($oid_name eq 'PON_TYPE') {
              $value = $type;
            }
            elsif ($oid_name eq 'ONU_DHCP_PORT') {
              $value = $port_dhcp_id . '/' . $num;
            }
            elsif ($oid_name eq 'ONU_SNMP_ID') {
              $value = $key;
            }
            else {
              $value = $total_info{$cols->[$i]}{$key};
            }
            $onu_info{$oid_name} = $value;
          }
          push @all_rows, { %onu_info };
        }
      }
    }
  }

  return \@all_rows;
}


#**********************************************************
=head2 _zte($attr) - Snmp recovery

  Arguments:
    $attr
      TYPE
      EPON

  Returns:
    OID hash_ref

=cut
#**********************************************************
sub _zte {
  my ($attr) = @_;

  my %snmp = (
    epon            => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.4',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.17',
      },
      'ONU_TX_POWER'   => {
        NAME   => 'ONU_TX_POWER',
        OIDS   => '', #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.4
        PARSER => '_zte_convert_epon_power'
      },
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.5',
        PARSER => '_zte_convert_epon_power'
      },
      'OLT_RX_POWER'   => {
        NAME   => 'OLT_RX_POWER',
        OIDS   => '',
      },
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.1',
        PARSER => '_zte_convert_epon_description'
      },
      'ONU_IN_BYTE'    => {
        NAME => 'ONU_IN_BYTE',
        #OIDS   => '.1.3.6.1.4.1.3902.1015.1010.5.5.1.2',
      },
      'ONU_OUT_BYTE'   => {
        NAME => 'ONU_OUT_BYTE',
        #OIDS   => '.1.3.6.1.4.1.3902.1015.1010.5.5.1.2',
      },
      'TEMPERATURE'    => {
        NAME   => 'TEMPERATURE',
        OIDS   => '', #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.1
        PARSER => '_zte_convert_epon_temperature'
      },
      'VLAN'           => {
        NAME   => 'VLAN',
        OIDS   => '1.3.6.1.4.1.3902.1015.1010.1.1.1.10.2.1.1',
        PARSER => '_zte_convert_eth_vlan',
        WALK   => 1
      },
      'reset'          => {
        NAME        => '',
        OIDS        => '.1.3.6.1.4.1.3902.1015.1010.1.1.2.1.1.1', #tested on ZTE C220, system description: ZXR10 ROS Version V4.8.01A ZXPON C220 Software, Version V2.8.01A.21
        RESET_VALUE => 1,
        PARSER      => ''
      },
      main_onu_info    => {
        'VLAN'           => {
          NAME   => 'VLAN',
          OIDS   => '1.3.6.1.4.1.3902.1015.1010.1.1.1.10.2.1.1',
          PARSER => '_zte_convert_eth_vlan',
          WALK   => 1
        },
        'HARD_VERSION' => {
          NAME   => 'Hard_Version',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.5',
          PARSER => ''
        },
        'SOFT_VERSION' => {
          NAME   => 'Soft_Version',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.6',
          PARSER => ''
        },
        'MODEL'        => {
          NAME   => 'VERSION',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.5',
          PARSER => ''
        },
        'VENDOR'       => {
          NAME   => 'VENDOR',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.2',
          PARSER => ''
        },
        'VOLTAGE'      => {
          NAME   => 'VOLTAGE',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.2',
          PARSER => '_zte_convert_epon_voltage'
        },
        'DISTANCE'     => {
          NAME   => 'DISTANCE',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.2.1.1.10',
          PARSER => '_zte_convert_distance',
        },
        'TEMPERATURE'  => {
          NAME   => 'TEMPERATURE',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.1',
          PARSER => '_zte_convert_epon_temperature'
        },
        'ONU_TX_POWER' => {
          NAME   => 'ONU_TX_POWER',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.4',
          PARSER => '_zte_convert_epon_power'
        },
        'MAC_BEHIND_ONU' => {
          NAME                        => 'MAC_BEHIND_ONU',
          USE_MAC_LOG                 => 1,
          MAC_LOG_SEARCH_BY_PORT_NAME => 'no_pon_type'
        },
        'ONU_PORTS_STATUS' => {
          NAME   => 'ONU_PORTS_STATUS',
          OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.5.1.2 ',
          PARSER => '_zte_eth_status',
          WALK   => 1
        }
      }
    },
    gpon            => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5',
        #PARSER => 'bin2hex'
        PARSER => '_zte_mac_serial'
      },
      'ONU_STATUS'     => {
        NAME => 'STATUS',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
      },
      'ONU_TX_POWER'   => {
        NAME      => 'ONU_TX_POWER',
        OIDS      => '', #.1.3.6.1.4.1.3902.1012.3.50.12.1.1.14
        PARSER    => '_zte_convert_power',
        ADD_2_OID => '.1'
      }, # tx_power = tx_power * 0.002 - 30.0;
      'ONU_RX_POWER'   => {
        NAME      => 'ONU_RX_POWER',
        OIDS      => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.10',
        PARSER    => '_zte_convert_power',
        ADD_2_OID => '.1'
      }, # rx_power = rx_power * 0.002 - 30.0;
      'OLT_RX_POWER'   => {
        NAME   => 'OLT_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', #enabled only for c320
        PARSER => '_zte_convert_olt_power'
      }, # olt_rx_power = olt_rx_power * 0.001;
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
        PARSER => '_zte_convert_description'
      },
      'ONU_IN_BYTE'    => {
        NAME => 'ONU_IN_BYTE',
        #OIDS   => '.1.3.6.1.4.1.3902.1015.1010.5.5.1.3',
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'ONU_OUT_BYTE',
        #OIDS   => '.1.3.6.1.4.1.3902.1015.1010.5.5.1.2',
        PARSER => ''
      },
      'TEMPERATURE'    => {
        NAME      => 'TEMPERATURE',
        OIDS      => '', #.1.3.6.1.4.1.3902.1012.3.50.12.1.1.19
        PARSER    => '_zte_convert_temperature',
        ADD_2_OID => '.1'
      },
      'reset'          => { #there are different OID on firmware V2
        NAME        => '',
        OIDS        => '.1.3.6.1.4.1.3902.1012.3.50.11.3.1.1',
        RESET_VALUE => 1,
        PARSER      => ''
      },
      'catv_port_manage' => {
        NAME               => '',
        OIDS               => '.1.3.6.1.4.1.3902.1012.3.50.19.1.1.1',
        ENABLE_VALUE       => 1,
        DISABLE_VALUE      => 2,
        USING_CATV_PORT_ID => 1,
        PARSER             => ''
      },
      'disable_onu_manage' => {
        OIDS               => '1.3.6.1.4.1.3902.1012.3.28.1.1.17',
        SKIP               => 1,
        ENABLE_VALUE       => 1,
        DISABLE_VALUE      => 2,
      },
      'LLID'           => {
        NAME   => 'LLID',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8',
        PARSER => ''
      },
      main_onu_info    => {
        'VERSION_ID'   => {
          NAME   => 'VERSION',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.2',
          PARSER => ''
        },
        'VENDOR'    => {
          NAME   => 'VENDOR',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.1',
          PARSER => ''
        },
        'EQUIPMENT_ID' => {
          NAME   => 'Equipment_ID',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
          PARSER => ''
        },
        'VOLTAGE'      => {
          NAME      => 'VOLTAGE',
          OIDS      => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.17',
          PARSER    => '_zte_convert_voltage',
          ADD_2_OID => '.1'
        },
        'DISTANCE'     => {
          NAME   => 'DISTANCE',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
          PARSER => '_zte_convert_distance'
        },
        'TEMPERATURE'  => {
          NAME      => 'TEMPERATURE',
          OIDS      => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.19',
          PARSER    => '_zte_convert_temperature',
          ADD_2_OID => '.1'
        },
        'ONU_TX_POWER' => {
          NAME      => 'ONU_TX_POWER',
          OIDS      => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.14',
          PARSER    => '_zte_convert_power',
          ADD_2_OID => '.1'
        },
        'ONU_NAME'       => {
          NAME   => 'Onu name',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
          PARSER => '_zte_convert_description'
        },
        'CATV_PORTS_STATUS' => {
          NAME   => 'CATV_PORTS_STATUS',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.19.1.1.2',
          WALK   => 1
        },
        'CATV_PORTS_COUNT' => {
          NAME   => 'CATV_PORTS_COUNT',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.11.14.1.14',
        },
        'CATV_PORTS_ADMIN_STATUS' => {
          NAME   => 'CATV_PORTS_ADMIN_STATUS',
          OIDS   => '1.3.6.1.4.1.3902.1012.3.50.19.1.1.1',
          PARSER => '_zte_convert_catv_port_admin_status',
          WALK   => 1
        },
        'VIDEO_RX_POWER' => {
          NAME   => 'VIDEO_RX_POWER',
          OIDS   => '.1.3.6.1.4.1.3902.1012.3.50.19.3.1.8',
          PARSER => '_zte_convert_video_power'
        },
        'MAC_BEHIND_ONU' => {
          NAME                        => 'MAC_BEHIND_ONU',
          USE_MAC_LOG                 => 1,
          MAC_LOG_SEARCH_BY_PORT_NAME => 'no_pon_type'
        }
      },
    },
    #  1015 -  EPON unreg 220 epon
    #  Unregister epon count
    #  OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14',
    unregister      => {
      UNREGISTER => {
        NAME   => 'UNREGISTER',
        OIDS   => '.1.3.6.1.4.1.3902.1015.1010.1.7.14.1',
        TYPE   => 'epon',
        PARSER => '',
        WALK   => '1'
      }
    },
    #1012. - GPON 320/220
    unregister_gpon => {
      UNREGISTER       => {
        NAME   => 'UNREGISTER',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.3.1.2',
        TYPE   => 'gpon',
        PARSER => '',
        WALK   => '1'
      },
      sn               => {
        NAME   => 'SN',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.3.1.2',
        PARSER => '',
        WALK   => '1'
      },
      mac              => {
        NAME   => 'MAC',
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.3.1.3',
        PARSER => '',
        WALK   => '1'
      },
      # Online time
      RTD              => {
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.3.1.4',
        WALK   => '1'
      },
      ONU_PASSWORD     => {
        OIDS   => '.1.3.6.1.4.1.3902.1012.3.13.3.1.5',
        WALK   => '1'
      },
      #      ??? RTD \ Online time
      #        .1.3.6.1.4.1.3902.1012.3.13.3.1.6.268501504.1=0
      #      ???
      #    .1.3.6.1.4.1.3902.1012.3.13.3.1.7.268501504.1=07_e1_02_09_0e_16_28_00
      #      LOID
      #        .1.3.6.1.4.1.3902.1012.3.13.3.1.8.268501504.1="C4C9EC01012F"
      #    LOID password
      #        .1.3.6.1.4.1.3902.1012.3.13.3.1.9.268501504.1="C4C9EC01012F"
      ONU_TYPE         => {
        NAME => 'ONU_TYPE',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.13.3.1.10',
        WALK => '1'
      },
      SOFTWARE_VERSION => {
        NAME => 'SOFTWARE_VERSION',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.13.3.1.11',
        WALK => '1'
      }

      #    'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
      #    'unreg_onu_count' => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
      #    'onu_type'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.1',
      #    'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
      #    'onu_vlan'    => '1.3.6.1.4.1.3902.1012.3.50.13.3.1.1',
      #    'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
      #    'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
      #    'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
      #    'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
      #    'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
      #    'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
      #    'onu_distance'=> '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
      #    'onu_Reset'   => '.1.3.6.1.4.1.3320.101.10.1.1.29',
      #    'onu_load'    => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
      #    'onu_uptime'  => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.20',
      #    'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.5'
      #.1.3.6.1.4.1.3902.1012.3.13.1.1.1 - gpon port descr
      #.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1 - epon port descr
      #.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7 - MAC-адреса ОНУ
      #.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.8 - !!! MAC-адреса ОНУ
      #.1.3.6.1.4.1.3902.1015.1010.1.2.1.1.10 - расстояние до ОНУ
      #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.5.ID - уровень сигнала (только через snmpget)
      #.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.5 - модель ОНУ
      #.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.2 - производитель ОНУ
      #.1.3.6.1.4.1.3902.1015.1010.1.1.1.19.1.1 - Vlan
    },
    "FDB_OID"       => ".1.3.6.1.4.1.3902.1015.6.1.3.1.5.1",
  );

  if ($attr->{MODEL} && $attr->{MODEL} !~ /C320/i) {
    delete $snmp{gpon}->{OLT_RX_POWER};
  }

  if ($attr->{MODEL} && $attr->{MODEL} =~ /_V2$|C300/i) {
    $snmp{gpon}->{reset} = {
      NAME        => '',
      OIDS        => '1.3.6.1.4.1.3902.1082.500.20.2.1.10.1.1',
      RESET_VALUE => 1,
      RESET_FN    => '_zte_reset_v2'
    }
  }

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _zte_convert_eth_vlan();

=cut
#**********************************************************
sub _zte_convert_eth_vlan {
  my ($data) = @_;

  if (! $data) {
    return '';
  }

  my $result =  join('', @$data);

  my ($port, $vlan) = split(/:/, $result, 2);

  return ($port, $vlan);
}

#**********************************************************
=head2 _zte_eth_status($data);

  1 - down
  2 - up

=cut
#**********************************************************
sub _zte_eth_status {
  my ($data)=@_;

  my ($port, $status)=split(/:/, $data);
  $status--;

  return($port, $status);
}

#**********************************************************
=head2 _zte_onu_status();

  Arguments:
    $attr
      EPON - Show epon status describe

  Returns:
    Status hash_ref

=cut
#**********************************************************
sub _zte_onu_status {
  my ($pon_type) = @_;

  my %status = (
    0 => $ONU_STATUS_TEXT_CODES{UNKNOWN},
    1 => $ONU_STATUS_TEXT_CODES{LOS},
    2 => $ONU_STATUS_TEXT_CODES{SYNC},
    3 => $ONU_STATUS_TEXT_CODES{ONLINE},
    4 => $ONU_STATUS_TEXT_CODES{DYING_GASP},
    5 => $ONU_STATUS_TEXT_CODES{POWER_OFF},
    6 => $ONU_STATUS_TEXT_CODES{OFFLINE}
  );

  if ($pon_type eq 'epon') {
    %status = (
      1 => $ONU_STATUS_TEXT_CODES{POWER_OFF},
      2 => $ONU_STATUS_TEXT_CODES{OFFLINE},
      3 => $ONU_STATUS_TEXT_CODES{ONLINE},
    );
  }

  return \%status;
}
#**********************************************************
=head2 _zte_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _zte_set_desc {
  my ($attr) = @_;
  my $oid = $attr->{OID} || '';
  if ($attr->{PORT}) {
    if ($attr->{PORT_TYPE} eq 'gpon') {
      $oid = '1.3.6.1.4.1.3902.1012.3.13.1.1.1.' . $attr->{PORT};
    }
    else {
      $oid = '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1.' . $attr->{PORT};
    }
  }
  #$attr->{DESC} = convert($attr->{DESC}, {utf82win => 1});
  if ($attr->{PON_TYPE} && $attr->{PON_TYPE} eq 'epon') {
    $attr->{DESC} = $attr->{ONU_ID} . '$$' . $attr->{DESC} . '$$';
  }
  Encode::_utf8_off($attr->{DESC});
  Encode::from_to($attr->{DESC}, 'utf-8', 'windows-1251');
  snmp_set(
    {
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      OID            => [ $oid, "string", $attr->{DESC} ]
    }
  );
}

#**********************************************************
=head2 _zte_decode_onu($dec, $attr) - Decode onu int

  Arguments:
    $dec    - Decimal port ID
    $attr
       MODEL_NAME  - ZTE model name
       TYPE        - result format. 'dhcp' or empty
       HASH_RESULT - Return result as hash
       DEBUG

  Returns:
    result string
    or
    %result - if $attr->{HASH_RESULT} is set
      type
      shelf
      slot
      olt
      onu
      result_string

=cut
#**********************************************************
sub _zte_decode_onu {
  my ($dec, $attr) = @_;

  $dec =~ s/\.\d+//;

  my %result = ();
  my $bin = sprintf("%032b", $dec);
  my ($bin_type) = $bin =~ /^(\d{4})/;
  my $type = oct("0b$bin_type");
  my $model_name = $attr->{MODEL_NAME} || q{};
  my $i = ($model_name =~ /C220/i) ? 0 : 1;
  my $result_type = $attr->{TYPE} || q{};

  #epon-onu
  if ($type == 3) {
    @result{'type', 'shelf', 'slot', 'olt',
      'onu'} = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{5})(\d{3})(\d{8})(\d{8})/;

    if ($result_type eq 'dhcp') {
      #$result{slot} = ($model_name =~ /C220|C320/i) ? sprintf("%02d", $result{slot}) : sprintf("%02d", $result{slot});
      $result{slot} = sprintf("%02d", $result{slot});
      $result{onu} = ($model_name =~ /C220|C320|C300/i) ? sprintf("%02d", $result{onu}) : sprintf("%03d", $result{onu});
      if ($model_name =~ /C220/i) {
        $result{slot} =~ s/^0/ /g;
        $result{onu} =~ s/^0/ /g;
      }
      elsif ($model_name =~ /C320/i) {
        if ($conf{EQUIPMENT_ZTE_O82} && $conf{EQUIPMENT_ZTE_O82} eq 'dsl-forum') {
          $result{slot} =~ s/^0/ /g;
          $result{onu} =~ s/^0/ /g;
          $i = 0;
        }
      }
    }

    $result{shelf} += $i;
    $result{olt}   += 1;

    $result{result_string} = (($attr->{DEBUG}) ? $type . '#' . $type_name{$result{type}} . '_' : '')
      . ($result{shelf})
      . '/' . $result{slot}
      . '/' . ($result{olt})
      . (($result_type eq 'dhcp') ? '/' : ':')
      . $result{onu};
  }
  elsif ($type == 1) {
    @result{'type', 'shelf', 'slot', 'olt'} = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{8})(\d{8})(\d{8})/;
    my $shelf_inc = 0;

    if ($result_type eq 'dhcp') {
      $result{slot} = ($model_name =~ /C220/i) ? sprintf("%02d", $result{slot}) : sprintf("%02d", $result{slot});

      if ($model_name =~ /C300/i || $model_name =~ /_V2$/i) {
        $shelf_inc = 1;
      }

      if ($model_name =~ /C220|C320/i && $model_name !~ /_V2$/i) {
        if ($conf{EQUIPMENT_ZTE_O82} && $conf{EQUIPMENT_ZTE_O82} eq 'dsl-forum') {
          $result{slot} =~ s/^0/ /g;
        }
      }
    }
    elsif ($model_name =~ /C3/i) {
      $shelf_inc = 1;
    }

    $result{shelf} += $shelf_inc;

    $result{result_string} = (($attr->{DEBUG}) ? $type . '#' . $type_name{$result{type}} . '_' : '')
      . ($result{shelf})
      . '/' . $result{slot}
      . '/' . $result{olt};
  }
  elsif ($type == 6) {
    @result{'type', 'shelf', 'slot'} = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{8})/;

    $result{result_string} = $type . '#' . $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot};
  }
  #epon-onu
  elsif ($type == 9) { #probably is used only on firmware V2
    @result{'type', 'shelf', 'slot', 'olt', 'onu', } = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{4})(\d{4})(\d{8})/;

    $result{shelf} += 1;
    $result{olt}   += 1;

    if ($result_type eq 'dhcp') {
      $result{slot} = sprintf("%02d", $result{slot});
      $result{onu} = ($model_name =~ /C220|C320|C300/i) ? sprintf("%02d", $result{onu}) : sprintf("%03d", $result{onu}); #XXX copied from type == 3, tested only on C320_V2
    }

    $result{result_string} = (($attr->{DEBUG}) ? $type_name{$result{type}} . '_' : '')
      . ($result{shelf})
      . '/' . ($result{slot})
      . '/' . ($result{olt})
      . (($result_type eq 'dhcp') ? '/' : ':')
      . $result{onu};
  }
  #gpon_onu
  elsif ($type == 4 || $type == 10) {
    if ($type == 4) {
      @result{'type', 'shelf', 'slot', 'olt', 'onu', } = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{5})(\d{3})(\d{8})/;
    }
    elsif ($type == 10) {
      @result{'type', 'shelf', 'slot', 'olt', 'onu', } = map {oct("0b$_")} $bin =~ /^(\d{4})(\d{4})(\d{4})(\d{4})(\d{8})/;
    }

    $result{shelf} += 1;
    $result{slot}  += ($model_name =~ /C300|C301/) ? 2 : 1;
    $result{olt}   += 1;
    $result{onu}   += 1;

    $result{result_string} = $type_name{$result{type}}
      . '_'
      . ($result{shelf})
      . '/' . ($result{slot})
      . '/' . ($result{olt})
      . ':' . ($result{onu});
  }
  else {
    print "Unknown type: $type\n" if ($attr->{DEBUG});
    return 0;
  }

  if ($attr->{HASH_RESULT}) {
    return \%result;
  }
  else {
    return $result{result_string};
  }
}

#**********************************************************
=head2 _zte_encode_port($type, $shelf, $slot, $olt) - encode port

  It seems port always use $type == 1

  Arguments:
    $type
    $shelf
    $slot
    $olt

  Returns:
    encoded decimal

=cut
#**********************************************************
sub _zte_encode_port {
  my ($type, $shelf, $slot, $olt) = @_;

  my $bin = sprintf("%04b", $type)
    . sprintf("%04b", $shelf - 1)
    . sprintf("%08b", $slot)
    . sprintf("%08b", $olt)
    . '00000000';

  return oct("0b$bin");
}

#**********************************************************
=head2 _zte_encode_onu($type, $shelf, $slot, $olt, $onu, $model_name) - encode ONU's SNMP ID

  Used to create SNMP ID for newly registered EPON ONUs.
  May work incorrectly with $type is not 3 or 9, but it seems we don't need
  this function for other types.

  Arguments:
    $type
    $shelf
    $slot
    $olt
    $onu
    $model_name

  Returns:
    encoded decimal

=cut
#**********************************************************
sub _zte_encode_onu {
  my ($type, $shelf, $slot, $olt, $onu, $model_name) = @_;

  my $bin;
  if ($type == 9) {
    $bin = sprintf("%04b", $type)
      . sprintf("%04b", $shelf - 1)
      . sprintf("%04b", $slot)
      . sprintf("%04b", $olt - 1)
      . sprintf('%08b', $onu)
      . '00000000';
  }
  else {
    my $shelf_decrement = ($model_name =~ /C220/i) ? 0 : 1;

    $bin = sprintf("%04b", $type)
      . sprintf("%04b", $shelf - $shelf_decrement)
      . sprintf("%05b", $slot)
      . sprintf("%03b", $olt - 1)
      . sprintf('%08b', $onu)
      . '00000000';
  }

  return oct("0b$bin");
}

#**********************************************************
=head2 _zte_dhcp_port($attr) - returns dhcp (option 82) port

  Arguments:
    $attr
      PORT_ID
      ONU - ONU number should be provided with PORT_ID only on GPON
        or
      SHELF
      SLOT
      OLT
      ONU

      PON_TYPE - epon or gpon
      MODEL_NAME

  Returns:
    $result - string, dhcp (option 82) port

=cut
#**********************************************************
sub _zte_dhcp_port {
  my ($attr) = @_;

  my $shelf = $attr->{SHELF};
  my $slot  = $attr->{SLOT};
  my $olt   = $attr->{OLT};
  my $onu   = $attr->{ONU};

  my $port_id = $attr->{PORT_ID};

  my $pon_type   = $attr->{PON_TYPE};
  my $model_name = $attr->{MODEL_NAME};

  my $result;

  if ($pon_type eq 'gpon') {
    $shelf++ if ($shelf && $shelf eq '0'); #XXX needed for ZTE C2xx, not tested on real hardware. move to _zte_encode_port?
    my $encoded_port = ($port_id) ? $port_id : _zte_encode_port(1, $shelf, $slot, $olt);

    my $num = (($model_name && $model_name =~ /C220|C300/i) || ($conf{EQUIPMENT_ZTE_O82} && $conf{EQUIPMENT_ZTE_O82} eq 'dsl-forum')) ? sprintf("%02d", $onu) : sprintf("%03d", $onu);
    if ($model_name && ($model_name =~ /C220|C320/i)
      && ($conf{EQUIPMENT_ZTE_O82} && $conf{EQUIPMENT_ZTE_O82} eq 'dsl-forum')
      && ($model_name !~ /_V2$/i)) {
      $num =~ s/^0+/ /g;
    }

    $result = _zte_decode_onu($encoded_port, {TYPE => 'dhcp', MODEL_NAME => $model_name}) . '/' . $num;
  }
  elsif ($pon_type eq 'epon') {
    my $encoded_onu = ($port_id) ? $port_id : _zte_encode_onu(($model_name =~ /_V2$/i) ? 9 : 3, $shelf, $slot, $olt, $onu, $model_name);
    $result = _zte_decode_onu($encoded_onu, {TYPE => 'dhcp', MODEL_NAME => $model_name});
  }

  return $result;
}

#**********************************************************
=head2 _zte_convert_epon_power($power) - Convert power

=cut
#**********************************************************
sub _zte_convert_epon_power {
  my ($power) = @_;

  $power //= 0;

  if ($power) {
    if ($power eq 'N/A' || $power =~ /65535/ || $power && $power > 0) {
      $power = '0';
    }
    else {
      $power = sprintf("%.2f", $power);
    }
  }

  return $power;
}

#**********************************************************
=head2 _zte_convert_power($power);

=cut
#**********************************************************
sub _zte_convert_power {
  my ($power) = @_;

  $power //= 0;

  if ($power eq '0' || $power > 60000) {
    $power = '0';
  }
  else {
    $power = ($power * 0.002 - 30);
    $power = sprintf("%.2f", $power);
  }
  return $power;
}

#**********************************************************
=head2 _zte_convert_olt_power();

=cut
#**********************************************************
sub _zte_convert_olt_power {
  my ($olt_power) = @_;

  $olt_power //= 0;

  if ($olt_power eq '65535000') {
    $olt_power = '';
  }
  else {
    $olt_power = ($olt_power * 0.001);
    $olt_power = sprintf("%.2f", $olt_power);
  }

  return $olt_power;
}

#**********************************************************
=head2 _zte_convert_video_power();

=cut
#**********************************************************
sub _zte_convert_video_power {
  my ($video_power) = @_;

  return undef if (!defined $video_power || $video_power == 0);

  return $video_power - 30;
}

#**********************************************************
=head2 _zte_convert_catv_port_admin_status($status_code);

=cut
#**********************************************************
sub _zte_convert_catv_port_admin_status {
  my ($data) = @_;
  my ($oid, $index) = split(/:/, $data, 2);
  my $port = "$oid";
  my $status = 'Unknown';
  my %status_hash = (
    1 => 'Enable',
    2 => 'Disable',
  );
  if ($status_hash{ $index }) {
    $status = $status_hash{ $index };
  }
  return($port, $status);
}

#**********************************************************
=head2 _zte_convert_description();

=cut
#**********************************************************
sub _zte_convert_description {
  my ($description) = @_;

  $description = convert($description || q{}, { win2utf8 => 1 });

  return $description;
}

#**********************************************************
=head2 _zte_convert_epon_description();

=cut
#**********************************************************
sub _zte_convert_epon_description {
  my ($description) = @_;

  if (!defined($description)) {
    return q{};
  }

  if ($description =~ /^.*\$\$(.*)\$\$.*$/) {
    $description = $1;
  }

  $description = convert($description, { win2utf8 => 1 });
  return $description;
}

#**********************************************************
=head2 _zte_convert_temperature();

=cut
#**********************************************************
sub _zte_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;

  if (2147483647 == $temperature) {
    $temperature = '';
  }
  else {
    $temperature = ($temperature * 0.001);
    $temperature = sprintf("%.2f", $temperature);
  }

  return $temperature;
}

#**********************************************************
=head2 _zte_convert_epon_temperature();

=cut
#**********************************************************
sub _zte_convert_epon_temperature {
  my ($temperature) = @_;

  $temperature //= 0;

  if ($temperature eq '2147483647') {
    $temperature = '';
  }
  elsif ($temperature =~ /\d+/) {
    $temperature = sprintf("%.2f", $temperature);
  }

  return $temperature;
}

#**********************************************************
=head2 _zte_convert_epon_voltage($voltage);

=cut
#**********************************************************
sub _zte_convert_epon_voltage {
  my ($voltage) = @_;

  $voltage //= 0;

  if ($voltage =~ /\d+/) {
    $voltage = sprintf("%.2f V", $voltage);
  }

  return $voltage;
}

#**********************************************************
=head2 _zte_convert_voltage();

=cut
#**********************************************************
sub _zte_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;

  $voltage = $voltage * 0.02;

  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _zte_convert_distance();

=cut
#**********************************************************
sub _zte_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  if ($distance eq '-1') {
    $distance = '--';
  }
  else {
    $distance = $distance * 0.001;
    $distance .= ' km';
  }
  return $distance;
}
#**********************************************************
=head2 _zte_delete_onu($attr)

=cut
#**********************************************************
sub _zte_delete_onu {
}
#**********************************************************
=head2 _zte_unregister($attr);

  Arguments:
    $attr

  Returns;
    \@unregister

=cut
#**********************************************************
sub _zte_unregister {
  my ($attr) = @_;
  my @unregister = ();

  #my $unreg_type = ($attr->{NAS_INFO}->{MODEL_NAME} && $attr->{NAS_INFO}->{MODEL_NAME} eq 'C320') ? 'unregister_c320' : 'unregister';
  my $unreg_type = 'unregister_gpon';
  my $snmp = _zte({ TYPE => $unreg_type });
  my %unregister_onus = ();

  #my $nas_model = $attr->{NAS_INFO}->{MODEL_NAME};

  #if(($attr->{NAS_INFO}->{MODEL_NAME} && $attr->{NAS_INFO}->{MODEL_NAME} eq 'C320')) {
  # GPON unreg
  foreach my $oid_type (keys %$snmp) {
    my $unreg_result = snmp_get({
      %{$attr},
      WALK             => 1,
      DONT_USE_GETBULK => 1, #needed because of bug in ZTE C300(?), it returns only first(?) line with getbulk
      OID              => $snmp->{$oid_type}->{OIDS},
      #TIMEOUT          => 8,
      SILENT           => 1,
      DEBUG            => $attr->{DEBUG} || 0
    });

    foreach my $line (@$unreg_result) {
      next if (!$line);
      $line =~ /^([0-9\.]+):(.{0,200})$/igs;
      my ($id, $value)=($1, $2);

      my ($branch, undef) = split(/\./, $id);
      if (!$oid_type) {
        next
      }
      elsif ($oid_type eq 'sn' || $oid_type eq 'UNREGISTER') {
        $value = _zte_mac_serial($value);
      }
      #        if(in_array($oid_type, [ 'MAC', 'UNREGISTER'])) {
      #          $value = bin2mac($value);
      #        }
      #        elsif($oid_type eq 'SN') {
      #          $value = sprintf("%s", $value);
      #        }

      #print "$num TYPE: $oid_type // $id, $value //<br>";
      $unregister_onus{$id}->{$oid_type}    = $value;
      $unregister_onus{$id}->{'branch'}     = _zte_decode_onu($branch, { MODEL_NAME => $attr->{NAS_INFO}->{MODEL_NAME} });
      $unregister_onus{$id}->{'branch_num'} = $branch;
      $unregister_onus{$id}->{'pon_type'}   = $snmp->{$oid_type}->{TYPE} if ($snmp->{$oid_type}->{TYPE});
    }
  }

  #return \@unregister;
  #}

  $snmp = _zte({ TYPE => 'unregister' });

  my $unreg_result = snmp_get({
    %{$attr},
    WALK   => 1,
    OID    => $snmp->{UNREGISTER}->{OIDS},
    #TIMEOUT => 8,
    SILENT => 1,
    DEBUG  => $attr->{DEBUG} || 1
  });

  my %unreg_info = (
    2  => 'mac',
    3  => 'info',
    #    4  => 'x4',
    #    5  => 'x5',
    6  => 'register',
    #    7  => 'x7',
    #    8  => 'x8',
    9  => 'vendor',
    10 => 'firnware',
    11 => 'version',
    #    12 => 'x12',
  );

  foreach my $line (@$unreg_result) {
    next if (!$line);
    my ($id, $value) = split(/:/, $line || q{}, 2);

    my ($type, $branch, $num) = split(/\./, $id || q{});
    next if (!$unreg_info{$type});

    if ($unreg_info{$type} eq 'mac') {
      $value = bin2mac($value);
    }

    $unregister_onus{$branch .'_'. $num}->{$unreg_info{$type}} = $value;
    $unregister_onus{$branch .'_'. $num}->{'branch'}           = _zte_decode_onu($branch, { MODEL_NAME => $attr->{NAS_INFO}->{MODEL_NAME} });
    $unregister_onus{$branch .'_'. $num}->{'branch_num'}       = $branch;
    $unregister_onus{$branch .'_'. $num}->{'pon_type'}         = $snmp->{UNREGISTER}->{TYPE};
  }

  foreach my $branch_num ( keys %unregister_onus ) {
    push @unregister, $unregister_onus{$branch_num};
  }

  return \@unregister;
}

#**********************************************************
=head2 _zte_get_fdb($attr) - GET FDB

  Arguments:
    $attr
      NAS_INFO
        MODEL_NAME
      DEBUG

  Results:


=cut
#**********************************************************
sub _zte_get_fdb {
  my ($attr) = @_;
  my %hash = ();

  my $onu_status_list = snmp_get({
    %$attr,
    WALK => 1,
    OID  => '.1.3.6.1.4.1.3902.1015.6.1.3.1.5.1',
  });

  my $debug = $attr->{DEBUG} || 1;

  foreach my $line (@$onu_status_list) {
    next if (!$line);

    $line =~ /(\d+)\.(\d+)\.(\d+\.\d+\.\d+\.\d+\.\d+\.\d+):(\d+)/;
    my ($port, $vlan, $mac, $id) = ($1, $2, $3, $4);
    $mac = _mac_former($mac);

    my $port_name = '';
    my $onu_info = _zte_decode_onu($port, {HASH_RESULT => 1, MODEL_NAME => $attr->{NAS_INFO}->{MODEL_NAME}});
    if ($onu_info->{type} == 4 || $onu_info->{type} == 10) {
      $port_name = "$onu_info->{shelf}/$onu_info->{slot}/$onu_info->{olt}:$onu_info->{onu}";
    }

    print "$port -> $onu_info->{result_string}, $vlan, $mac, $id\n" if ($debug > 1);

    $hash{$mac}{1} = $mac;
    #$hash{$key}{2} = port_type;
    $hash{$mac}{2} = $port;
    $hash{$mac}{4} = $vlan;
    $hash{$mac}{5} = $port_name;
  }

  return %hash;
}

#**********************************************************
=head2 _zte_mac_serial($value) - GET FDB

=cut
#**********************************************************
sub _zte_mac_serial {
  my ($value) = @_;

  $value = uc(join('', unpack("AAAAH*", $value || q{})));

  return $value;
}

#**********************************************************
=head2 _zte_recode_onu_index_v1_to_v2($attr) - Recode ONU index firmware V1 type to firmware V2 type

  ONU indexes on firmware V1 OIDs and on firmware V2 OIDs are different.
  This function recodes ONU index from firmware V1 type to firmware V2 type.

  Arguments:
    $index

  Returns:
    $onu_index_in_v2_format

=cut
#**********************************************************
sub _zte_recode_onu_index_v1_to_v2 {
  my ($index) = @_;

  my ($branch, $onu_id) = split('\.', $index, 2);

  my $decoded_branch = _zte_decode_onu(
    $branch,
    {
      MODEL_NAME => 'C320_V2', #model name do not matter, as long as it contains 'C3'
      HASH_RESULT => 1
    }
  );

  my $new_branch = unpack("N", pack("CCCC", 17, $decoded_branch->{shelf}, $decoded_branch->{slot}, $decoded_branch->{olt})); #seems 17 is constant

  return "$new_branch.$onu_id\n";
}

#**********************************************************
=head2 _zte_reset_v2($attr) - Reset ONU on ZTE with firmware V2 (only GPON)

  ONU indexes on firmware V1 OIDs and on firmware V2 OIDs are different.
  We are using firmware V1 OIDs even on V2 OLTs, they are mostly working.
  But V1 OID reset (GPON) is not working on V2 OLTs.
  To reset we need to recode V1 index that we know to V2 index that is needed to reset.

  Arguments:
    $attr
      SNMP_INFO
      SNMP_COMMUNITY
      VERSION
      ONU_SNMP_ID

  Returns:
    $reset_result - is reset ok, boolean

=cut
#**********************************************************
sub _zte_reset_v2 {
  my ($attr) = @_;

  my $snmp_info = $attr->{SNMP_INFO};
  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $onu_snmp_id = $attr->{ONU_SNMP_ID};

  my $reset_value = (defined($snmp_info->{reset}->{RESET_VALUE})) ? $snmp_info->{reset}->{RESET_VALUE} : 1;

  $onu_snmp_id = _zte_recode_onu_index_v1_to_v2($onu_snmp_id);

  my $reset_result = snmp_set({
    SNMP_COMMUNITY => $SNMP_COMMUNITY,
    VERSION        => $attr->{VERSION},
    OID            => [ $snmp_info->{reset}->{OIDS} . '.' . $onu_snmp_id, $snmp_info->{reset}->{VALUE_TYPE} || "integer", $reset_value ]
  });

  return $reset_result;
}

#**********************************************************
=head2 zte_unregister_form($attr) - Pre register form

  Arguments:
    $attr
      BRANCH_NUM
      PON_TYPE
      LLID
      DEBUG

=cut
#**********************************************************
sub _zte_unregister_form {
  my ($attr) = @_;

  my $snmp_oids = _zte();
  my $debug = $attr->{DEBUG} || 0;

  if ($attr->{PON_TYPE}) {
    if ($attr->{PON_TYPE} eq 'epon') {
      my $onu_count = snmp_get({ #string like "1-22,28, 40-42,45-46,49, 52, 56, 60-62", ONU numbers
        %{$attr},
        OID => '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.7' . '.' . $attr->{BRANCH_NUM}
      });

      if ($onu_count =~ m/(\d+)(,|$)/) {
        my $free_llid = $1 + 1;

        if ($onu_count !~ m/^1(\-|\,|$)/g) {
          $attr->{LLID} = 1;
        }
        elsif ($free_llid != 65) {
          $attr->{LLID} = $free_llid;
        }
      }
    }
    # elsif ($attr->{PON_TYPE} eq 'epon' && $snmp_oids->{$attr->{PON_TYPE}}{LLID}{OIDS}) {
    #   my $result = snmp_get({
    #     %{$attr},
    #     OID  => $snmp_oids->{$attr->{PON_TYPE}}{LLID}{OIDS} . '.' . $attr->{BRANCH_NUM},
    #     WALK => 1,
    #   });
    #
    #   my $next_llid = 1;
    #
    #   foreach my $line (@$result) {
    #     print "$line<br>\n" if ($debug > 3);
    #     my ($id) = split(/:/, $line);
    #     if ($next_llid != $id) {
    #       last;
    #     }
    #     $next_llid++;
    #   }
    #
    #   $attr->{LLID} = $next_llid;
    # }
    elsif ($snmp_oids->{$attr->{PON_TYPE}}{LLID}) {
      my $result = snmp_get({
        %{$attr},
        OID  => $snmp_oids->{$attr->{PON_TYPE}}{ONU_MAC_SERIAL}{OIDS} . '.' . $attr->{BRANCH_NUM},
        WALK => 1,
      });

      my $next_llid = 1;

      foreach my $line (@$result) {
        print "$line<br>\n" if ($debug > 3);
        my ($id) = split(/:/, $line);
        if ($next_llid != $id) {
          last;
        }
        $next_llid++;
      }

      $attr->{LLID} = $next_llid;
    }
  }

  my $vlan_hash = get_vlans($attr);
  my %vlans = ();
  foreach my $vlan_id (keys %{$vlan_hash}) {
    $vlans{ $vlan_id } = "Vlan$vlan_id ($vlan_hash->{ $vlan_id }->{NAME})";
  }

  $attr->{VLAN_SEL} = $html->form_select('VLAN_ID', {
    SELECTED    => $attr->{DEF_VLAN} || '',
    SEL_OPTIONS => { '' => '--' },
    SEL_HASH    => \%vlans,
    NO_ID       => 1
  });

  $attr->{ACTION} = 'onu_registration';
  $attr->{ACTION_LNG} = $lang{ADD};
  $attr->{VENDOR} //= 'zte';

  my $dir = $base_dir . 'Abills/modules/Equipment/snmp_tpl/zte_registration_*.tpl';
  my @list;
  for my $file (glob $dir) {
    my @path_name = split('/', $file);
    my $name = $path_name[$#path_name];
    push @list, $name;
  }
  if ($#list > 0) {
    my $selected;
    if ($attr->{PON_TYPE}) {
      if ($attr->{PON_TYPE} eq 'epon' && $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_EPON}) {
        $selected = $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_EPON};
      }
      elsif ($attr->{PON_TYPE} eq 'gpon' && $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_GPON}) {
        $selected = $attr->{NAS_INFO}->{DEFAULT_ONU_REG_TEMPLATE_GPON};
      }
      elsif ($conf{ZTE_DEFAULT_REGISTRATION_TEMPLATE_BY_PON_TYPE}->{$attr->{PON_TYPE}}) {
        $selected = $conf{ZTE_DEFAULT_REGISTRATION_TEMPLATE_BY_PON_TYPE}->{$attr->{PON_TYPE}};
      }
      else {
        $selected = "zte_registration_" . $attr->{PON_TYPE} . ".tpl";
      }
    }
    $attr->{TEMPLATE} = $html->form_select('TEMPLATE', {
      SEL_ARRAY     => \@list,
      OUTPUT2RETURN => 1,
      SELECTED => $selected,
    });
  } else {
    my $val = $list[0] || '';
    $attr->{TEMPLATE} = "<input id='TEMPLATE' name='TEMPLATE' class='form-control' readonly value='$val'>";
  }

  $html->tpl_show(_include('equipment_registred_onu_zte', 'Equipment'), $attr);

  return 1;
}

#**********************************************************
=head2 _zte_get_onu_config($attr) - Connect to OLT over telnet and get ONU config

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

  commands (GPON):
    show gpon onu detail-info gpon-onu_%BRANCH%:%ONU_ID%
    show onu running config gpon-onu_%BRANCH%:%ONU_ID%
    show running-config interface gpon-onu_%BRANCH%:%ONU_ID%
    show mac-real-time gpon onu gpon-onu_%BRANCH%:%ONU_ID%
    show gpon remote-onu interface eth gpon-onu_%BRANCH%:%ONU_ID%

=cut
#**********************************************************
sub _zte_get_onu_config {
  my ($attr) = @_;

  my $pon_type = $attr->{PON_TYPE};
  my $branch = $attr->{BRANCH};
  my $onu_id = $attr->{ONU_ID};

  my $username = $attr->{NAS_INFO}->{NAS_MNG_USER};
  my $password = $conf{EQUIPMENT_OLT_PASSWORD} || $attr->{NAS_INFO}->{NAS_MNG_PASSWORD};

  my ($ip, undef) = split (/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}, 2);

  my @cmds = @{equipment_get_telnet_tpl({
    TEMPLATE => "zte_get_onu_config_$pon_type.tpl",
    BRANCH   => $branch,
    ONU_ID   => $onu_id
  })};

  if (!@cmds) {
    @cmds = @{equipment_get_telnet_tpl({
      TEMPLATE => "zte_get_onu_config_$pon_type.tpl.example",
      BRANCH   => $branch,
      ONU_ID   => $onu_id
    })};
  }

  if (!@cmds) {
    if ($pon_type =~ /epon/i) {
      return ([$lang{ERROR}, $lang{ONU_CONFIGURATION_FOR_EPON_IS_NOT_SUPPORTED} . 'Abills/modules/Equipment/snmp_tpl/zte_get_onu_config_epon.tpl']);
    }
    else {
      return ([$lang{ERROR}, $lang{FAILED_TO_GET_TELNET_CMDS_FROM_FILE} . " zte_get_onu_config_$pon_type.tpl"]);
    }
  }

  use Abills::Telnet;

  my $t = Abills::Telnet->new();

  $t->set_terminal_size(256, 1000); #if terminal size is small, ZTE does not print all of command output, but prints first *terminal_height* lines, prints '--More--' and lets user scroll it manually
  $t->prompt('\n.*#$');

  if (!$t->open($ip)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  if(!$t->login($username, $password)) {
    $html->message('err', $lang{ERROR} . ' Telnet', $t->errstr());
    return ();
  }

  my @result = ();

  foreach my $cmd (@cmds) {
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
=head2 _zte_convert_cpu_usage($data);

=cut
#**********************************************************
sub _zte_convert_cpu_usage {
  my ($data) = @_;

  my ($slot, $value) = split(/:/, $data, 2);
  if ($value eq '-1') {
    $value = '--';
  }
  else {
    my $color = q{};
    (undef, $color) = split(/:/, equipment_add_color($value)) if ($value =~ /\d+/);
    $color //= $html_color{green};
    $value = '<span style="background-color:' . $color . '" class="badge">' . $value . ' %</span>';
  }

  return ($slot, $value);
}

#**********************************************************
=head2 _zte_convert_info_temperature($data)();

=cut
#**********************************************************
sub _zte_convert_info_temperature {
  my ($data) = @_;
  my ($slot, $value) = split(/:/, $data, 2);
  if ($value eq '2147483647') {
    $value = '--';
  }
  else {
    my $color = q{};
    (undef, $color) = split(/:/, equipment_add_color($value)) if ($value =~ /\d+/);
    $color //= $html_color{green};
    $value = '<span style="background-color:' . $color . '" class="badge">' . $value . ' °C</span>';
  }
  return($slot, $value);
}

1
