=head1 NAME

 huawei snmp monitoring and managment

=cut

use Abills::Base qw(in_array _bp int2byte);


#**********************************************************
=head2 _huawei_ports($attr) - Show ports

  Experemental

=cut
#**********************************************************
sub _huawei_ports{
  my ($attr) = @_;

  my $cols      = $attr->{COLS} || [ 'MAC_ONU', 'ONUSTATUS', 'UPTIME', 'CUR_TX', 'NUM', 'MODEL' ];
  my $info_oids = $attr->{INFO_OIDS};
  my $snmp      = _huawei();
  #my $onu_status = _huawei_onu_status();

  foreach my $oid_name ( keys %{ $snmp } ){
    if ( $attr->{snmp}->{$oid_name} eq 'HASH' ){
      next;
    }
    $info_oids->{uc( $oid_name )} = $oid_name;
  }

  #Reg onu count
  my $reg_arr = snmp_get( { %{$attr},
      WALK => 1,
      OID  => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13',
    } );

  my %reg_onu_count = ();

  foreach my $line ( @{$reg_arr} ){
    my ($id, $count) = split( /:/, $line, 2 );
    $reg_onu_count{$id} = $count;
  }

  #get way id
  my $ports_descr = snmp_get( { %{$attr},
      WALK => 1,
      # .1.3.6.1.4.1.3902.1012.3.13.1.1.1
      OID  => '.1.3.6.1.2.1.2.2.1.2',
    } );

  my %info = ();
  foreach my $oid_name ( @{$cols} ){
    _bp( { SHOW => " $oid_name -> $info_oids->{$oid_name} : $snmp->{$info_oids->{$oid_name}} " } ) if ($FORM{debug});
    if ( !$snmp->{$info_oids->{$oid_name}} ){
      next;
    }

    my $oid = $snmp->{$info_oids->{$oid_name}} . '.' . $key;

    my $snmp_arr = snmp_get( { %{$attr},
        WALK => 1,
        OID  => $oid
      } );

    foreach my $line ( @{$snmp_arr} ){
      my ($id, $value) = split( /:/, $line, 2 );

      if ( $oid_name eq 'MAC_ONU' ){
        $value = join( ':', unpack( "H2H2H2H2H2H2", $value ) );
      }

      $info{$id}{$oid_name} = $value;
    }
  }

  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{EQUIPMENT}",
      ID      => 'EQUIPMENT_MODELS'
    }
  );

  foreach my $line ( @{$ports_descr} ){
    my ($key, $type) = split( /:/, $line, 2 );
    my $ports_arr = snmp_get( { %{$attr},
        WALK => 1,
        OID  => $snmp->{onustatus} . '.' . $key
      } );

    my @row = ("$type ($key)", "$lang{COUNT}: $reg_onu_count{$key}");
    $table->{rowcolor} = 'bg-success';
    $table->addrow( @row, join( $html->br(), @ports_state ) );
    $table->{rowcolor} = undef;

    if ( $reg_onu_count{$key} > 0 ){
      for ( my $_id = 1; $_id <= $reg_onu_count{$key}; $_id++ ){
        @row = ($type);
        foreach my $value_id ( @{$cols} ){
          push @row, $info{$key . '.' . $_id}{$value_id};
        }

        $table->addrow( @row );
      }
    }
  }

  print $table->show();

  return 1;
}


#**********************************************************
=head2 _huawei_onu_status();

=cut
#**********************************************************
sub _huawei_onu_status{

  my %status = (
    0 => 'free',
    1 => 'online',
    2 => 'offline',
  );

  return \%status;
}


#**********************************************************
=head2 _huawei_onu_info($attr) -

=cut
#**********************************************************
sub _huawei_onu_info{
  my ($attr) = @_;

  my $cols = $attr->{COLS};
  my $info_oids = $attr->{INFO_OIDS};

  my %total_info = ();
  my $snmp       = _huawei();
  my $onu_status = _huawei_onu_status();
  my @all_rows   = ();

  my %EPON_N = ();
  if ( in_array( 'EPON_N', $cols ) ){
    my $reg_arr = snmp_get( { %{$attr},
        WALK => 1,
        OID  => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
      } );

    #my %reg_onu_count = ();
    foreach my $line ( @{$reg_arr} ){
      my ($id, $value) = split( /:/, $line, 2 );
      $EPON_N{$id} = $value;
    }
  }

  foreach my $oid_name ( @{$cols} ){
    _bp( { SHOW => "$oid_name -- $info_oids->{$oid_name} -- $snmp->{$info_oids->{$oid_name}}" } ) if ($FORM{DEBUG});

    if ( !$snmp->{$info_oids->{$oid_name}} ){
      next;
    }

    my $oid = $snmp->{$info_oids->{$oid_name}};
    my $values = snmp_get( { %{$attr},
        WALK    => 1,
        OID     => $oid,
        TIMEOUT => 25
    } );

    foreach my $line ( @{$values} ){
      my ($key, $oid_value) = split( /:/, $line );

      if ( $FORM{DEBUG} && $FORM{DEBUG} > 3 ){
        print $html->br() . $info_oids->{$oid_name} . '->' .
            "$key, $oid_value";
      }

      if ( $oid_name eq 'MAC_ONU' ){
        $oid_value = join( ':', unpack( "H2H2H2H2H2H2", $oid_value ) );
      }
      elsif ( $oid_name eq 'ONUSTATUS' ){
        $oid_value = $onu_status->{$oid_value} . "($oid_value)";
        $key =~ s/\.\d+$//;
      }
      elsif ( $oid_name eq 'BYTE_IN' || $oid_name eq 'BYTE_OUT' ){
        $oid_value = int2byte( $oid_value );
      }
      elsif ( $oid_name eq 'CUR_TX' ){
        if ( 2147483647 == $oid_value ){
          $oid_value = 0;
        }
        else{
          $oid_value = $oid_value / 100;
        }
      }
      $total_info{NUM}{$key} = $key;
      $total_info{$oid_name}{$key} = $oid_value;
    }
  }

  my $num = 0;
  foreach my $key ( keys %{ $total_info{ONUSTATUS} } ){
    my @row = ();
    for ( my $i = 0; $i <= $#{ $cols }; $i++ ){
      my $value = q{};
      if ( $cols->[$i] eq 'EPON_N' ){
        my ($id, undef) = split( /\./, $key );
        $value = $EPON_N{$id};
      }
      else{
        $value = $total_info{$cols->[$i]}{$key};
      }

      push @row, $value;
    }

    push @all_rows, [
        @row,
        $html->button( '', "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&onuReset=$key",
          { class => 'glyphicon glyphicon-retweet', TITLE => $lang{REBOOT} } ),
        $html->button( $lang{ADD}, 'index=15', { class => 'add' } ),
        $html->button( $lang{INFO}, "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$key",
          { class => 'info' } )
      ];
    $num++;
  }

  return \@all_rows;
}


#**********************************************************
=head2 _huawei() - Snmp recovery

=cut
# http://pastebin.com/wjj68SUX
#**********************************************************
sub _huawei{

  my %snmp = (
    'product_id'    => '1.3.6.1.4.1.2011.6.128.1.1.2.45.1.3',
    'soft_version'  => '1.3.6.1.4.1.2011.6.128.1.1.2.45.1.6',
    'reset'         => '1.3.6.1.4.1.2011.6.128.1.1.2.46.1.2',
    'onu_mac_count' => '1.3.6.1.4.1.2011.6.128.1.1.2.46.1.21',
    'onudistance'   => '1.3.6.1.4.1.2011.6.128.1.1.2.46.1.20',
    'lazerpower'    => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4',
    'optic_tempr'   => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.1',
    'cur_tx'        => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4', # lazerpower
    'onustatus'     => '1.3.6.1.4.1.2011.6.128.1.1.2.62.1.22',
    'slottable'     => '1.3.6.1.4.1.2011.6.3.3.2',
    'onu_unreg'     => '1.3.6.1.4.1.2011.6.128.1.1.2.48.1', #!!!

    #hwMaxMacLearn 1.3.6.1.4.1.2011.5.14.1.4.1.6
    #hwMacExpire 1.3.6.1.4.1.2011.5.14.1.3
    #hwOpticsMDWaveLength 1.3.6.1.4.1.2011.5.14.6.1.1.15
    #hwOpticsMDVendorName 1.3.6.1.4.1.2011.5.14.6.1.1.11
    #hwRingCheckAdminStatus 1.3.6.1.4.1.2011.5.21.1.7
    #hwVlanInterfaceID 1.3.6.1.4.1.2011.5.6.1.2.1.1
    #hwVlanInterfaceTable 1.3.6.1.4.1.2011.5.6.1.2
    #hwVlanName 1.3.6.1.4.1.2011.5.6.1.1.1.2
    #icmpInEchos 1.3.6.1.2.1.5.8
    #ipAddrEntry 1.3.6.1.2.1.4.20.1
    #                 'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
    #                 'unreg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
    #
    #                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
    #                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
    #                 'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
    #                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
    #
    #                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
    #                 'model'       => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
    #                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
    #                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
    #                 'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
    #                 'onuReset'    => '1.3.6.1.4.1.3320.101.10.1.1.29',
    #                 'uptime'      => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
    #                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.1',
    #                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.4',

    main_onu_info   => {
      'lazerpower'    => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4',
      'cur_tx'        => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4', # lazerpower
      'slottable'     => '1.3.6.1.4.1.2011.6.3.3.2',
      'onustatus'     => '1.3.6.1.4.1.2011.6.128.1.1.2.62.1.22',
      'optic_tempr'   => '1.3.6.1.4.1.2011.6.128.1.1.2.51.1.1',
      'onu_mac_count' => '1.3.6.1.4.1.2011.6.128.1.1.2.46.1.21',
      'onudistance'   => '1.3.6.1.4.1.2011.6.128.1.1.2.46.1.20',
      #                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
      #                 'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
      #                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
      #                 'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
      #                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
      #                 'model'       => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
      #                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
      #                 'onudistance' => '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
      #                 'uptime'      => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
      #                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.1',
      #                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.4',
      #                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
    }
  );

  return \%snmp;
}

1