=head1 NAME

  BDCOM

=cut

use strict;
use warnings;
use Abills::Base qw(in_array);
our %lang;
our $html;

#**********************************************************
=head2 _bdcom_ports($attr) - Show ports

  Arguments:
    COLS
    INFO_OIDS

 Return:
   port + mac

=cut
#**********************************************************
sub _bdcom_ports{
  my ($attr) = @_;

  my $cols = $attr->{COLS};
  my $info_oids = $attr->{INFO_OIDS};
  my $snmp = _bdcom();
  my $onu_status = _bdcom_onu_status();

  foreach my $oid_name ( keys %{ $snmp } ){
    if ( $attr->{snmp} && $attr->{snmp}->{$oid_name} eq 'HASH' ){
      next;
    }
    $info_oids->{uc( $oid_name )} = $oid_name;
  }

  my $ports_descr = snmp_get( { %{$attr},
      WALK => 1,
      OID  => '.1.3.6.1.2.1.2.2.1.2',
    } );

  $cols = [ 'PORTS', 'MAC_ONU' ];

  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{EQUIPMENT}",
      ID      => 'EQUIPMENT_MODELS'
    }
  );
  $LIST_PARAMS{ADDRESS_FULL}='_SHOW';

  my $used_ports = equipments_get_used_ports({ NAS_ID     => $attr->{NAS_ID},
                                               FULL_LIST  => 1,
                                               PORTS_ONLY => 1,
                                             });
  my %BRANCHES = ();
  foreach my $line ( @{$ports_descr} ){
    if ( $line =~ /(.+):(.+):(.+)/ ){
      my $if_index = $1;
      my $branch = $2;
      my $sub_if = $3;
      $BRANCHES{$branch}{$sub_if} = $if_index;
    }
  }

  my %if_indexes = ();
  foreach my $branch ( sort keys %BRANCHES ){
    foreach my $device_index ( sort { $a <=> $b } keys %{ ($BRANCHES{$branch}) ? $BRANCHES{$branch} : {} } ){
      my $interface_index = $BRANCHES{$branch}{$device_index};
      my $type = "$branch:$device_index";
      $if_indexes{$branch} = $interface_index;

      my $onus_status_ports = snmp_get( { %$attr,
          WALK => 1,
          OID  => $snmp->{onu_ports_status} . '.' . $interface_index
        } );

      my @ports_state = ();
      my $port_id = '';
      foreach my $key_ ( sort @{ $onus_status_ports } ){
        my ($port, $state) = split( /:/, $key_ );

        # option 82 - hn-type
        if ( $conf{DHCP_O82_BDCOM_TYPE} && $conf{DHCP_O82_BDCOM_TYPE} eq 'hn-type' ){
          $branch =~ /\/(\d+)/;
          my $olt_num = $1 + 6;
          $port_id = sprintf( "%02x%02x", $olt_num, $device_index );
        }
        # option 82 - cm-type
        else{
          #my $brench_index = $device_index + 6;
          $branch =~ /\/(\d+)/;
          my $brench_index = $1;
          $port_id = sprintf( "%02x%02x", $brench_index, $device_index );
        }

        my ($status_text) = split( /:/, $onu_status->{$state} );
        push  @ports_state,
          $port_id . "<div value='" . $port_id . "' class='clickSearchResult'><button title='($state) $status_text' class='btn " . (($state == 1) ? 'btn-success' : 'btn-default') . "'>$port</button></div>";
      }

      my @row = ($type, $interface_index);
      my $value = '';
      if ($used_ports->{$port_id}){
        foreach my $uinfo ( @{ $used_ports->{$port_id} } ){
          $value .= $html->br() if ($value);
          $value .= $html->button( $uinfo->{login},
            "index=15&UID=$uinfo->{uid}" ) . $html->br() . $uinfo->{address_full};
        }
      }

      push @row, $value;

      foreach my $oid_name ( @$cols ){
        print " $oid_name -> $info_oids->{$oid_name} : $snmp->{$info_oids->{$oid_name}}" . $html->br() if ($FORM{debug});

        if (! $info_oids->{$oid_name} || !$snmp->{$info_oids->{$oid_name}} ){
          next;
        }
        my $oid = $snmp->{$info_oids->{$oid_name}} . '.' . $interface_index;
        $value = snmp_get( { %{$attr}, OID => $oid } );

        if ( $oid_name eq 'MAC_ONU' ){
          $value = $html->color_mark( join( ':', unpack( "H2H2H2H2H2H2", $value ) ), 'code' );
        }
        elsif ( $oid_name =~ /ONUCHIPMODULEID|ONUCHIPREVISION/ ){
          $value = join( ':', unpack( "H*", $value ) );
        }
        elsif ( $oid_name eq 'ONUSTATUS' ){
          my ($status, $color) = split( /:/, $onu_status->{$value} );
          $value = $html->color_mark( $status, $color );

          #$value = $onu_status->{$value};
        }
        elsif ( $oid_name =~ /CUR_RX|CUR_TX/ ){
          $value = pon_tx_alerts($value / 10);
        }

        push @row, $value;
      }
      $table->addrow( @row, @ports_state );
    }
  }

  print $table->show();

  return 1;
}


#**********************************************************
=head2 _bdcom_onu_info($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID

=cut
#**********************************************************
sub _bdcom_onu_info{
  my ($attr) = @_;

  my $cols      = $attr->{COLS};
  my $info_oids = $attr->{INFO_OIDS};
  my $debug     = $attr->{DEBUG} || 0;

  #my %total_info = ();
  my $snmp        = _bdcom();
  my $onu_status  = _bdcom_onu_status();
  my @all_rows    = ();
  my $ports_descr = snmp_get({ %$attr,
      WALK => 1,
      OID  => '.1.3.6.1.2.1.2.2.1.2',
  });

  my $onu_status_list = snmp_get( { %$attr,
      WALK => 1,
      OID  => $snmp->{onustatus}
    } );

  my %onu_cur_status = ();
  foreach my $line ( @$onu_status_list ) {
    my($port_index, $status)=split(/:/, $line);
    $onu_cur_status{$port_index}=$status;
  }

  my %onu_ports_status = ();
#  my $onu_port_status_list = snmp_get( { %$attr,
#      WALK => 1,
#      OID  => $snmp->{onu_ports_status}
#  });
#
#  foreach my $line ( @$onu_port_status_list ) {
#    $line =~ m/(\d+)\.(\d+):(\d+)/;
#    $onu_ports_status{$1}{$2}=$3;
#  }

  my $used_ports = equipments_get_used_ports( { NAS_ID => $attr->{NAS_ID}, FULL_LIST => 1 } );

  foreach my $line ( @$ports_descr ){
    my ($interface_index, $type) = split( /:/, $line, 2 );
    if ($type && $type =~ /(.+):(.+)/ ){
      #my $olt = $1;

      my @row = (
        $interface_index,
        $type,
      );

      my $port_id;
      $type =~ /(.+)\/(\d+):(\d+)/;
      my $device_index = $3;
      my $brench_index = $2;
      # option 82 - hn-type
      if ( $conf{DHCP_O82_BDCOM_TYPE} && $conf{DHCP_O82_BDCOM_TYPE} eq 'hn-type' ){
        $type =~ /\/(\d+)/;
        my $olt_num = $1 + 6;
        $port_id = sprintf( "%02x%02x", $olt_num, $device_index );
      }
      # option 82 - cm-type
      else{
        $port_id = sprintf( "%02d%02x", $brench_index, $interface_index );
      }

      foreach my $oid_name ( @$cols ){
        print " $oid_name -> $info_oids->{$oid_name}" . $html->br() if ($debug);
        next if (in_array($oid_name, ['NUM', 'EPON_N' ]));

        if ($info_oids->{$oid_name} && ! $snmp->{$info_oids->{$oid_name}} ){
          my $value;
          if($oid_name eq 'ONU_PORTS') {
            my @ports_state = ();
            foreach my $port ( sort keys %{ $onu_ports_status{$interface_index} } ){
              my $state = $onu_ports_status{$interface_index}{$port};
              if ( $state == 1 ){
                $state = "up";
              }
              elsif ( $state == 2 ){
                $state = "down";
              }

              push  @ports_state, $port . " : " . $state;
            }
            $value = join( $html->br(), @ports_state ) || 'Down';
          }
          elsif($used_ports->{$port_id}) {
            foreach my $uinfo ( @{ $used_ports->{$port_id} } ){
              $value .= $html->br() if ($value);
              if ($oid_name eq 'LOGIN'){
                $value .= $html->button($uinfo->{lc( $oid_name )}, "index=11&UID=$uinfo->{uid}");
              }
              elsif ($oid_name eq 'ADDRESS_FULL'){
                $value .= $html->button($uinfo->{login}, "index=11&UID=$uinfo->{uid}") . $html->br() . $uinfo->{address_full};
              }
              else {
                $value .= $uinfo->{lc( $oid_name )};
              }
            }
          }
          else {
            $value = '';
          }
          push @row, $value;
          next;
        }
        elsif ( $oid_name =~ /CUR_RX|CUR_TX|ONU_DISTANCE/ && (! $onu_ports_status{$interface_index}{1} || $onu_ports_status{$interface_index}{1} == 2) ){
          push @row, '--';
          next;
        }
        elsif ( $oid_name eq 'ONUSTATUS' ){
          my ($status, $color) = split( /:/, $onu_status->{ $onu_cur_status{$interface_index} } );
          my $value = $html->color_mark( $status, $color );
          push @row, $value;
          next;
        }

#        if (! $info_oids->{$oid_name}) {
#          next;
#        }

        my $oid = $snmp->{$info_oids->{$oid_name}} . '.' . $interface_index;
        my $value = snmp_get( { %{$attr}, OID => $oid, SILENT => 1 } );

        if ( $oid_name eq 'MAC_ONU' ){
          $value = $html->color_mark( join( ':', unpack( "H2H2H2H2H2H2", $value ) ), 'code' );
        }
        elsif ( $oid_name =~ /ONUCHIPMODULEID|ONUCHIPREVISION/ ){
          $value = join( ':', unpack( "H*", $value ) );
        }
        elsif ( $oid_name =~ /CUR_RX|CUR_TX/ ){
          $value = pon_tx_alerts($value / 10);
        }
        push @row, $value;
      }

      push @all_rows, [
          @row,
          $html->button( $lang{REBOOT}, "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&onuReset=$interface_index",
            { class => 'off' } ),
          ($used_ports->{$port_id}) ? '' : $html->button( $lang{ADD}, 'index=15', { class => 'add' } ),
          $html->button( $lang{INFO}, "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$interface_index",
            { class => 'info' } )
        ];
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _bdcom_onu_status()

=cut
#**********************************************************
sub _bdcom_onu_status{
  my %status = (
    0  => 'free',
    1  => 'allocated:text-success',
    2  => 'authInProgress:text-warning',
    3  => 'cfgInProgress:text-info',
    4  => 'authFailed:text-danger',
    5  => 'cfgFailed:text-danger',
    6  => 'reportTimeout',
    7  => 'ok',
    8  => 'authOk',
    9  => 'resetInProgress',
    10 => 'resetOk',
    11 => 'discovered',
    12 => 'blocked:text-danger',
    13 => 'checkNewFw',
    14 => 'unidentified',
    15 => 'unconfigured',
  );

  return \%status;
}

#**********************************************************
=head2 _bdcom()

=cut
#**********************************************************
sub _bdcom{

  my %snmp = (
    'onuReset'                        => '1.3.6.1.4.1.3320.101.10.1.1.29',
    'cur_tx'                          => '1.3.6.1.4.1.3320.101.10.5.1.5', #TX cure
    #''        => '1.3.6.1.4.1.3320.101.10.5.1.6', #TX ULimit
    'cur_rx'                          => '1.3.6.1.4.1.3320.9.183.1.1.5', #RX cure
    #'mac_onu' => '1.3.6.1.4.1.3320.101.10.1.1.3',
    #'RTT(TQ)' =>  '1.3.6.1.4.1.3320.101.11.1.1.8.8',
    'onu_ports_status'                => '1.3.6.1.4.1.3320.101.12.1.1.8',
    'onustatus'                       => '1.3.6.1.4.1.3320.101.10.1.1.26',
    'onu_distance'                    => '1.3.6.1.4.1.3320.101.10.1.1.27',
    'mac_onu'                         => '1.3.6.1.4.1.3320.101.10.4.1.1', #Active macs
    #'onu_mac' =>  '1.3.6.1.4.1.3320.101.10.1.1.76',  #new params
    #                'speed_in' => '1.3.6.1.4.1.3320.101.12.1.1.13',  # onu_id.onu_port
    #                'speed_out'=> '1.3.6.1.4.1.3320.101.12.1.1.21',  # onu_id.onu_port

    # bdEponOnuEntry
    'onuVendorID'                     => '1.3.6.1.4.1.3320.101.10.1.1.1',
    'onuIcVersion'                    => '1.3.6.1.4.1.3320.101.10.1.1.10',
    'onuServiceSupported'             => '1.3.6.1.4.1.3320.101.10.1.1.11',
    'onuGePortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.12',
    'onuGePortDistributing'           => '1.3.6.1.4.1.3320.101.10.1.1.13',
    'onuFePortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.14',
    'onuFePortDistributing'           => '1.3.6.1.4.1.3320.101.10.1.1.15',
    'onuPotsPortCount'                => '1.3.6.1.4.1.3320.101.10.1.1.16',
    'onuE1PortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.17',
    'onuUsQueueCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.18',
    'onuUsQueueMaxCount'              => '1.3.6.1.4.1.3320.101.10.1.1.19',
    'onuModuleID'                     => '1.3.6.1.4.1.3320.101.10.1.1.2',
    'onuDsQueueCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.20',
    'onuDsQueueMaxCount'              => '1.3.6.1.4.1.3320.101.10.1.1.21',
    'onuIsBakupBattery'               => '1.3.6.1.4.1.3320.101.10.1.1.22',
    'onuADSL2PlusPortCount'           => '1.3.6.1.4.1.3320.101.10.1.1.23',
    'onuVDSL2PortCount'               => '1.3.6.1.4.1.3320.101.10.1.1.24',
    'onuLLIDCount'                    => '1.3.6.1.4.1.3320.101.10.1.1.25',
    'onuStatus'                       => '1.3.6.1.4.1.3320.101.10.1.1.26',
    'onuDistance'                     => '1.3.6.1.4.1.3320.101.10.1.1.27',
    'onuBindStatus'                   => '1.3.6.1.4.1.3320.101.10.1.1.28',
    'onuReset'                        => '1.3.6.1.4.1.3320.101.10.1.1.29',
    'onuID'                           => '1.3.6.1.4.1.3320.101.10.1.1.3',
    'onuUpdateImage'                  => '1.3.6.1.4.1.3320.101.10.1.1.30',
    'onuUpdateEepromImage'            => '1.3.6.1.4.1.3320.101.10.1.1.31',
    'onuEncryptionStatus'             => '1.3.6.1.4.1.3320.101.10.1.1.32',
    'onuEncryptionMode'               => '1.3.6.1.4.1.3320.101.10.1.1.33',
    'onuIgmpSnoopingStatus'           => '1.3.6.1.4.1.3320.101.10.1.1.34',
    'onuMcstMode'                     => '1.3.6.1.4.1.3320.101.10.1.1.35',
    'OnuAFastLeaveAbility'            => '1.3.6.1.4.1.3320.101.10.1.1.36',
    'onuAcFastLeaveAdminControl'      => '1.3.6.1.4.1.3320.101.10.1.1.37',
    'onuAFastLeaveAdminState'         => '1.3.6.1.4.1.3320.101.10.1.1.38',
    'onuInFecStatus'                  => '1.3.6.1.4.1.3320.101.10.1.1.39',
    'onuHardwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.4',
    'onuOutFecStatus'                 => '1.3.6.1.4.1.3320.101.10.1.1.40',
    'onuIfProtectedStatus'            => '1.3.6.1.4.1.3320.101.10.1.1.41',
    'onuSehedulePolicy'               => '1.3.6.1.4.1.3320.101.10.1.1.42',
    'onuDynamicMacLearningStatus'     => '1.3.6.1.4.1.3320.101.10.1.1.43',
    'onuDynamicMacAgingTime'          => '1.3.6.1.4.1.3320.101.10.1.1.44',
    #          'onuStaticMacAddress' => '1.3.6.1.4.1.3320.101.10.1.1.45',
    #          'onuStaticMacAddressPortBitmap' => '1.3.6.1.4.1.3320.101.10.1.1.46',
    #          'onuStaticMacAddressConfigRowStatus' => '1.3.6.1.4.1.3320.101.10.1.1.47',
    'onuClearDynamicMacAddressByMac'  => '1.3.6.1.4.1.3320.101.10.1.1.48',
    'onuClearDynamicMacAddressByPort' => '1.3.6.1.4.1.3320.101.10.1.1.49',
    'onuSoftwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.5',
    'onuPriorityQueueMapping'         => '1.3.6.1.4.1.3320.101.10.1.1.50',
    #          'onuVlanMode'             => '1.3.6.1.4.1.3320.101.10.1.1.51',
    'onuIpAddressMode'                => '1.3.6.1.4.1.3320.101.10.1.1.52',
    'onuStaticIpAddress'              => '1.3.6.1.4.1.3320.101.10.1.1.53',
    'onuStaticIpMask'                 => '1.3.6.1.4.1.3320.101.10.1.1.54',
    'onuStaticIpGateway'              => '1.3.6.1.4.1.3320.101.10.1.1.55',
    'onuMgmtVlan'                     => '1.3.6.1.4.1.3320.101.10.1.1.56',
    'onuStaticIpAddressRowStatus'     => '1.3.6.1.4.1.3320.101.10.1.1.57',
    #nf          'onuCIR' => '1.3.6.1.4.1.3320.101.10.1.1.58',
    #nf          'onuCBS' => '1.3.6.1.4.1.3320.101.10.1.1.59',
    'onuFirmwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.6',
    #60          'onuEBS' => '1.3.6.1.4.1.3320.101.10.1.1.60',
    'onuIfMacACL'                     => '1.3.6.1.4.1.3320.101.10.1.1.61',
    'onuIfIpACL'                      => '1.3.6.1.4.1.3320.101.10.1.1.62',
    'onuVlans'                        => '1.3.6.1.4.1.3320.101.10.1.1.63',
    'onuActivePonDiid'                => '1.3.6.1.4.1.3320.101.10.1.1.64',
    'onuPonPortCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.65',
    'onuActivePonPortIndex'           => '1.3.6.1.4.1.3320.101.10.1.1.66',
    'onuSerialPortWorkMode'           => '1.3.6.1.4.1.3320.101.10.1.1.67',
    'onuSerialPortWorkPort'           => '1.3.6.1.4.1.3320.101.10.1.1.68',
    'onuSerialWorkModeRowStatus'      => '1.3.6.1.4.1.3320.101.10.1.1.69',
    'onuChipVendorID'                 => '1.3.6.1.4.1.3320.101.10.1.1.7',
    'onuRemoteServerIpAddrIndex'      => '1.3.6.1.4.1.3320.101.10.1.1.70',
    'onuPeerOLTIpAddr'                => '1.3.6.1.4.1.3320.101.10.1.1.71',
    'onuPeerPONIndex'                 => '1.3.6.1.4.1.3320.101.10.1.1.72',
    'onuSerialPortCount'              => '1.3.6.1.4.1.3320.101.10.1.1.73',
    'onuChipModuleID'                 => '1.3.6.1.4.1.3320.101.10.1.1.8',
    'onuChipRevision'                 => '1.3.6.1.4.1.3320.101.10.1.1.9',


    #Mac argument  bdEponLlidOnuBindEntry ->
    mac_arg                           => {
      'llidEponIfDiid'      => '1.3.6.1.4.1.3320.101.11.1.1.1',
      'llidSequenceNo'      => '1.3.6.1.4.1.3320.101.11.1.1.2',
      'onuMacAddressIndex'  => '1.3.6.1.4.1.3320.101.11.1.1.3',
      'llidOnuBindDesc'     => '1.3.6.1.4.1.3320.101.11.1.1.4',
      'llidOnuBindType'     => '1.3.6.1.4.1.3320.101.11.1.1.5',
      'llidOnuBindStatus'   => '1.3.6.1.4.1.3320.101.11.1.1.6',
      'llidOnuBindDistance' => '1.3.6.1.4.1.3320.101.11.1.1.7', # distance
      'llidOnuBindRTT'      => '1.3.6.1.4.1.3320.101.11.1.1.8',
    },

    #bdEponOnuIfEntry
    onu_info                          => {
      'onuLlidDiid'                     => '1.3.6.1.4.1.3320.101.12.1.1.1',
      'onuUniIfSpeed'                   => '1.3.6.1.4.1.3320.101.12.1.1.10',
      'onuUniIfFlowControlStatus'       => '1.3.6.1.4.1.3320.101.12.1.1.11',
      'onuUniIfLoopbackTest'            => '1.3.6.1.4.1.3320.101.12.1.1.12',
      'onuUniIfSpeedLimit'              => '1.3.6.1.4.1.3320.101.12.1.1.13',
      'onuUniIfStormControlType'        => '1.3.6.1.4.1.3320.101.12.1.1.14',
      'onuUniIfStormControlThreshold'   => '1.3.6.1.4.1.3320.101.12.1.1.15',
      'onuUniIfStormControlRowStatus'   => '1.3.6.1.4.1.3320.101.12.1.1.16',
      'onuUniIfDynamicMacLearningLimit' => '1.3.6.1.4.1.3320.101.12.1.1.17',
      'onuUniIfVlanMode'                => '1.3.6.1.4.1.3320.101.12.1.1.18',
      'onuUniIfVlanCost'                => '1.3.6.1.4.1.3320.101.12.1.1.19',
      'onuIfSequenceNo'                 => '1.3.6.1.4.1.3320.101.12.1.1.2',
      'onuPvid'                         => '1.3.6.1.4.1.3320.101.12.1.1.3',
      'onuOuterTagTpid'                 => '1.3.6.1.4.1.3320.101.12.1.1.4',
      'onuMcstTagStrip'                 => '1.3.6.1.4.1.3320.101.12.1.1.5',
      'onuMcstMaxGroup'                 => '1.3.6.1.4.1.3320.101.12.1.1.6',
      'onuUniIfAdminStatus'             => '1.3.6.1.4.1.3320.101.12.1.1.7',
      'onuUniIfOperStatus'              => '1.3.6.1.4.1.3320.101.12.1.1.8',
      'onuUniIfMode'                    => '1.3.6.1.4.1.3320.101.12.1.1.9',
    }
  );

  return \%snmp;
}

#**********************************************************
=head2 _zte_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _bdcom_get_ports {
  my ($attr) = @_;

  my %EPON_N = ();
  my $ports_descr = snmp_get( { %{$attr},
      WALK => 1,
      OID  => '.1.3.6.1.2.1.2.2.1.2',
    } );

  foreach my $line ( @{$ports_descr} ){
    if ( $line =~ /(.+):(.+):(.+)/ ){
      my $if_index = $1;
      my $branch   = $2;
      my $sub_if   = $3;
      $EPON_N{$branch} = "$branch // $if_index // $sub_if ";
    }
  }

  return \%EPON_N;
}

1
