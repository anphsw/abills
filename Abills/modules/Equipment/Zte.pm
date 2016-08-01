
=head1 NAME

  ZTE snmp monitoring and managment

  VERSION: 0.02

=cut

use strict;
use Abills::Base qw( _bp in_array int2byte);
our %lang;
our $html;

my %type_name = (
  1 => 'epon_olt_virtualIfBER',
  3 => 'epon-onu',
  6 => 'type6'
);

#**********************************************************
=head2 _zte_ports($attr) - Show ports
  Experemental

=cut
#**********************************************************
sub _zte_ports  {
  my ($attr) = @_;

  my $cols       = $attr->{COLS} || [ 'NUM', 'ONU_NAME', 'ONUSTATUS', 'CUR_TX', 'ONU_VLAN', 'ONU_UPTIME' ];
  my $info_oids  = $attr->{INFO_OIDS};
  my $snmp       = _zte($attr);
  my $onu_status = _zte_onu_status($attr);

  foreach my  $oid_name (keys %{ $snmp }) {
    if ($attr->{snmp}->{$oid_name} eq 'HASH') {
    	next;
    }
    $info_oids->{uc($oid_name)}=$oid_name;
  }

  #Reg onu count
  my $reg_arr = snmp_get({ %$attr,
                           WALK => 1,
                           OID  => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13',
                          });

  my %reg_onu_count = ();

  foreach my $line ( @$reg_arr ) {
    my ($id, $count)=split(/:/, $line, 2);
    $reg_onu_count{$id}=$count;
  }

  #get way id
#  my $ports_descr = snmp_get({ %$attr,
#                               WALK => 1,
#                               OID  => '.1.3.6.1.2.1.2.2.1.2',
#                               });

  my %info = ();
  foreach my $oid_name ( @$cols ) {
     _bp({ SHOW => " $oid_name -> $info_oids->{$oid_name} : $snmp->{$info_oids->{$oid_name}} " }) if ($FORM{debug});
     if (! $snmp->{$info_oids->{$oid_name}}) {
       next;
     }

     my $oid = $snmp->{$info_oids->{$oid_name}};
     my $snmp_arr = snmp_get({
                            %$attr,
                            WALK => 1,
                            OID  => $oid
                          });

     foreach my $line ( @$snmp_arr ) {
       my ($id, $value)=split(/:/, $line, 2);
       if ($oid_name eq 'MAC_ONU') {
         $value = join(':', unpack("H2H2H2H2H2H2", $value));
       }
       elsif ($oid_name eq 'ONUSTATUS') {
         $info{$id}{ONUSTATUS_ID}=$value;
         $value = $onu_status->{$value} || 'Unknown';
       }
       elsif($oid_name eq 'CUR_TX') {
         $value = pon_tx_alerts(sprintf("%.2f", $value / 1000));
       }
       elsif($oid_name eq 'ONU_VLAN') {
         if($id =~ /(\d+\.\d+)\.\d+\.(\d+)/) {
           $id = $1;
           $value = $2;
         }
       }

       $info{$id}{$oid_name}=$value;
     }
  }

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{EQUIPMENT} ZTE",
      title      => ['', 'NUM', 'ONU_NAME', 'CUR_TX', 'ONU_VLAN', 'ONU_UPTIME' ],
      ID         => 'EQUIPMENT_MODELS',
      border     => 1
    }
  );

  foreach my $id_ ( @$reg_arr ) {
    my ($id, $count)=split(/:/, $id_, 2);
    my @row = ($html->b(decode_onu($id)), "($count)");
    if (! $count) {
      next;
    }
    my $o82_ = decode_onu($id);
    $table->{rowcolor}='bg-success';
    $table->addrow(@row);
    $table->{rowcolor}=undef;
    for(my $num=1; $num<=$count; $num++) {
      my $port_name = sprintf("%s/%03d", $o82_, $num);
      my $port = "<div value='" . $port_name . "' class='clickSearchResult'><button title='". $info{"$id.$num"}{ONUSTATUS}
        ."' class='btn " . (($info{"$id.$num"}{ONUSTATUS_ID} == 3) ? 'btn-success' : 'btn-default') . "'>$port_name</button></div>";
      @row = ($port);
      foreach my $oid_name (@$cols) {
        if($oid_name eq 'ONUSTATUS') {
          next;
        }
        push @row, $info{"$id.$num"}{$oid_name} || '-';
      }
      $table->addrow(@row);
    }
  }

  print $table->show();

  return 1;
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
sub _zte_onu_status () {
  my ($attr) = @_;

  my %status = (
    0 => 'unknown',
    1 => 'LOS',
    2 => 'Synchronization',
    3 => 'Online',
    4 => 'Dying gasp',
    5 => 'Power off',
    6 => 'Offline',
  );

  if ($attr->{EPON}) {
    %status = (1 => 'Power Off',
               2 => 'Offline',
               3 => 'Online'
              );
  }

  return \%status;
}

#**********************************************************
=head2 _zte_get_slots($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _zte_get_ports {
  my ($attr) = @_;

  my %reg_onu_count = ();
  if ($attr->{FULL_INFO}) {
    #Reg onu count
    my $reg_arr = snmp_get({ %$attr,
                             WALK => 1,
                             OID  => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13',
                            });

    foreach my $line ( @$reg_arr ) {
      my ($id, $count)=split(/:/, $line, 2);
      $reg_onu_count{$id}=$count;
    }
  }

  my %EPON_N = ();
  my $ports_arr = snmp_get({ %$attr,
                           WALK => 1,
                           OID  => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
                         });

  foreach my $line ( @$ports_arr ) {
    my ($id, $value)=split(/:/, $line, 2);
    $EPON_N{$id}=$value . (($reg_onu_count{$id}) ? " ($reg_onu_count{$id})": '' );
  }

  return \%EPON_N;
}

#**********************************************************
=head2 _zte_onu_info($attr) -

=cut
#**********************************************************
sub _zte_onu_info  {
  my ($attr) = @_;

  my $cols      = $attr->{COLS};
  my $info_oids = $attr->{INFO_OIDS};

  my %total_info = ();
  my $snmp       = _zte();
  my $onu_status = _zte_onu_status();
  my @all_rows   = ();

  my $EPON_N;
  if (in_array('EPON_N', $cols)) {
    $EPON_N = _zte_get_ports($attr);
  }

  foreach my $oid_name (@$cols) {
    _bp({ SHOW => "$oid_name -- $info_oids->{$oid_name} -- $snmp->{$info_oids->{$oid_name}}" }) if ($FORM{debug});

    if (! $snmp->{$info_oids->{$oid_name}}) {
      next;
    }

    my $oid = $snmp->{$info_oids->{$oid_name}};

    if ($attr->{OLT_PORT}) {
      $oid .= '.'.$attr->{OLT_PORT};
    }

    my $values = snmp_get({ %$attr,
                            WALK    => 1,
                            OID     => $oid,
                            TIMEOUT => 25
                          });

    foreach my $line ( @$values ) {
      my ($key, $oid_value) = split(/:/, $line, 2);

      if($oid_name eq 'MAC_ONU') {
        $oid_value = join(':', unpack("H2H2H2H2H2H2", $oid_value));
      }
      elsif($oid_name eq 'ONUSTATUS') {
        $oid_value = $onu_status->{$oid_value}. "($oid_value)";
      }
      elsif($oid_name eq 'BYTE_IN' || $oid_name eq 'BYTE_OUT') {
        $oid_value = int2byte($oid_value);
      }
      elsif($oid_name eq 'CUR_TX') {
        $oid_value = pon_tx_alerts(sprintf("%.2f", $oid_value / 1000));
      }
      elsif($oid_name eq 'ONU_VLAN') {
        if($key =~ /^([0-9\.]+)\.\d+\.(\d+)/) {
          $key = $1;
          $oid_value = $2;
        }
      }

      $total_info{$oid_name}{$key}=$oid_value;
    }
  }

  my $used_ports = equipments_get_used_ports( {
      NAS_ID    => $attr->{NAS_ID},
      FULL_LIST => 1,
  } );

  my $num = 0;
  foreach my $key (keys %{ $total_info{ONUSTATUS} } ) {
    my @row = ();
    my $port_id = decode_onu($attr->{OLT_PORT} || $key);
    for(my $i=0; $i<=$#{ $cols }; $i++) {
      my $value = '';
      my $oid_name = $cols->[$i];
      my $num_ = sprintf("%03d", $total_info{NUM}{$key});
      if ($oid_name eq 'EPON_N') {
        my ($id, undef) = split(/\./, $key);
        $value = $EPON_N->{$id} || $attr->{OLT_PORT};
      }
      elsif ($oid_name eq 'NUM') {
        $value = sprintf("%03d", $total_info{$oid_name}{$key});
      }
      elsif ($oid_name eq 'BRANCH') {
        $value = $port_id;
      }
      elsif(! $info_oids->{$oid_name} && $used_ports->{$port_id.'/'.$num_}) {
        foreach my $uinfo ( @{ $used_ports->{$port_id.'/'.$num_} } ){
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
        $value = $total_info{$cols->[$i]}{$key};
      }

      push @row, $value;
    }

    my $onu_id = ($attr->{OLT_PORT}) ? $attr->{OLT_PORT}. '.'. $key : $key;

    push @all_rows, [
            @row,
            $html->button('', "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&onuReset=$onu_id", { class => 'glyphicon glyphicon-retweet', TITLE => $lang{REBOOT} }),
            $html->button($lang{ADD}, 'index=15', { class => 'add' }),
            $html->button($lang{INFO}, "index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$onu_id", { class => 'info' })
         ];
    $num++;
  }

  return \@all_rows;
}


#**********************************************************
=head2 _zte($attr) - Snmp recovery

  Arguments:
    $attr
      EPON

  Returns:
    OID hash_ref

=cut
#**********************************************************
sub _zte {
  my ($attr) = @_;

  my %snmp =  (
                 'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
                 'unreg_onu_count' => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
                 'onu_type'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.1',
                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
                 'onu_vendorid'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.1',
                 'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.50.16.1.1.3', #'.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onu_vlan'    => '1.3.6.1.4.1.3902.1012.3.50.13.3.1.1',
                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
                 'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
                 'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
                 'onu_distance'=> '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
                 'onu_Reset'   => '.1.3.6.1.4.1.3320.101.10.1.1.29',
                 'onu_load'    => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
                 'onu_uptime'  => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.20',
                 'onu_firmware'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.2',
                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.5',
                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.15',
             gpon => {
                 'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
                 'unreg_onu_count' => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
                 'onu_type'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.1',
                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
                 'onu_vendorid'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.1',
                 'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.50.16.1.1.3', #'.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onu_vlan'    => '1.3.6.1.4.1.3902.1012.3.50.13.3.1.1',
                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
                 'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
                 'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
                 'onu_distance'=> '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
                 'onu_Reset'   => '.1.3.6.1.4.1.3320.101.10.1.1.29',
                 'onu_load'    => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
                 'onu_uptime'  => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.20',
                 'onu_firmware'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.2',
                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.5',
                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.15',
             },
             # Epon
             epon => {
                 'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
                 'unreg_onu_count' => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
                 'onu_type'    => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.5',
                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
                 'onu_vendorid'=> '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.2',
                 'mac_onu'     => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.4',
                 'onu_vlan'    => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.10.2.1.1',
                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onustatus'   => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.17',
                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
                 'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
                 'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
                 'onu_distance_feet'=> '.1.3.6.1.4.1.3902.1015.1010.1.2.1.1.10',
                 'onu_Reset'   => '.1.3.6.1.4.1.3320.101.10.1.1.29',
                 'onu_load'    => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.12',
                 'onu_uptime'  => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.20',
                 'onu_firmware'=> '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.6',
                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.5',
                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.15',
                 'onu_hard_version' => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.5',
             },
             main_onu_info => {
                 'onu_type'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.1',
                 'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
                 'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
                 'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
                 'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
                 'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
                 'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
                 'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
                 'onudistance' => '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
                 'uptime'      => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
                 'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.1',
                 'byte_out'    => '.1.3.6.1.4.1.3902.1012.3.28.6.1.4',
             }
  );

  if ($attr->{EPON}) {
    return $snmp{epon};
  }

  return \%snmp;
}

#**********************************************************
=head2 decode_onu($dec) - Decode onu int

  Arguments:
    $dec

  Returns:
    deparsing string

=cut
#**********************************************************
sub decode_onu {
  my ($dec, $attr) = @_;

  $dec =~ s/\.\d+//;

  my %result = ();
  my $bin = sprintf( "%032b", $dec );

  my ($bin_type) = $bin =~ /^(\d{4})/;
  my $type = oct( "0b$bin_type" );

  if ( $type == 3 ) {
    @result{'type', 'shelf', 'slot', 'olt',
      'onu'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{5})(\d{3})(\d{8})(\d{8})/;
    return $type .'#'. $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot}
      . '/' . ($result{olt} + 1)
      . ':' . $result{onu};
  }
  elsif ( $type == 1 ) {
    @result{'type', 'shelf', 'slot', 'olt'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})(\d{8})(\d{8})/;
    return (($attr->{DEBUG}) ? $type .'#'. $type_name{$result{type}} . '_' : '')
      . $result{shelf}
      . '/' . sprintf("%02d", $result{slot})
      . '/' . $result{olt};
  }
  elsif ( $type == 6 ) {
    @result{'type', 'shelf', 'slot'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})/;
    return $type .'#'. $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot};
  }
  else {
    print "Unknown type: $type\n";
  }

  return 0;
}


1
