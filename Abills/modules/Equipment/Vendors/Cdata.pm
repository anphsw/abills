=head1 Cdata

  C-data
  MODEL:
    epon
      FD1104SN
      FD1216S

    gpon
      FD1616S-2AC

    testing
      FD1204S
      FD1208S
      FD1608SN
      FD1708SX

  DATE: 20190704
  UPDATE: 20250813

=head1 extra_info

  MIbs
  https://github.com/librenms/librenms/blob/master/mibs/cdata/FD-SYSTEM-MIB

  .1.3.6.1.4.1.17409.2.3.1.2.1.1.2.1 = STRING: "TAsvan_CDATA1608"
  .1.3.6.1.4.1.17409.2.3.1.2.1.1.3.1 = STRING: "FD1608SN-R1"

  ponPortName
    1.3.6.1.4.1.17409.2.3.3.1.1.21.1.0
  ponPortIndex
    1.3.6.1.4.1.17409.2.3.3.1.1.3


=cut

use strict;
use warnings;
use Abills::Filters qw(bin2mac bin2hex serial2mac);
use JSON qw(decode_json);

our (
  $base_dir,
  #%lang,
  #%conf,
  #%FORM,
  %ONU_STATUS_TEXT_CODES
);

my $TEMPLATE_DIR = $base_dir . 'Abills/modules/Equipment/snmp_tpl/';

#**********************************************************
=head2 _cdata_get_ports($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr

  Results:
    $ports_info_hash_ref

=cut
#**********************************************************
sub _cdata_get_ports {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  #GEt pon_ports FD16
  # ponPortName
  #   1.3.6.1.4.1.17409.2.3.3.1.1.21.1.0
  # ponPortIndex
  #   1.3.6.1.4.1.17409.2.3.3.1.1.3

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => $attr->{TIMEOUT} || 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,TRAFFIC,PORT_IN_ERR,PORT_OUT_ERR'
  });

  foreach my $key (sort keys %{$ports_info}) {
    print "ID: $key PORT_NAME: $ports_info->{$key}{PORT_NAME} PORT_TYPE: $ports_info->{$key}{PORT_TYPE}\n" if ($debug > 3);
    #FD11..
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1
      && $ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^(.PON).+PON-(\d+)/xm) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_NAME};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_NAME};
    }
    #FD11..
    elsif ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1
      && $ports_info->{$key}{PORT_DESCR} && $ports_info->{$key}{PORT_DESCR} =~ /^(.PON).+PON-(\d+)/xm) {
      my $type = lc($1);
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
    }
    #FD12 and FD16..
    elsif ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 117
      && $ports_info->{$key}{PORT_DESCR} && $ports_info->{$key}{PORT_DESCR} =~ /^pon(.+)/xm) {
      my $branch = $1;
      my ($branch_num) = $branch =~ /\d+\/\d+\/(\d+)/xm;

      if ($branch_num < 10) {
        $branch_num = '0' . $branch_num;
      }

      $ports_info->{$key}{PON_TYPE} = $attr->{MODEL_NAME} =~/^FD16/xm ? 'gpon' : 'epon';
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH} = $branch_num;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
    }
    #FD1616S-2AC gpon
    elsif ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} == 1
      && $ports_info->{$key}{PORT_NAME} && $ports_info->{$key}{PORT_NAME} =~ /^gpon(.+)/xm) {
      #my $branch = $1;
      # my ($branch_num) = $branch =~ /\d+\/\d+\/(\d+)/xm;
      #
      # if ($branch_num < 10) {
      #   $branch_num = '0' . $branch_num;
      # }
      my $branch_num = $1;

      $ports_info->{$key}{PON_TYPE} = 'gpon';
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH} = $branch_num;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
      $ports_info->{$key}{PORT_ALIAS} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _cdata_onu_list($port_list, $attr)

  Arguments:
    $port_list  - OLT ports list
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

  Returns:
    $onu_list [arra_of_hash]

    Example:
      oid result - 2.1:6
      port_descr - '5:EPON System, PON-1'
      port_ids - '1' => '645'

=cut
#**********************************************************
sub _cdata_onu_list {
  my ($port_list, $attr) = @_;

  if ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /^FD12/xm) {
    return _cdata_fd12_onu_list($port_list, $attr);
  }
  elsif ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~/^FD16|FD17/xm) {
    return _cdata_fd16_onu_list($port_list, $attr)
  }

  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => $attr->{TIMEOUT} || 5,
    VERSION  => 2,
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

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
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _cdata({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    my %onu_snmp_info = ();
    foreach my $oid_name (sort keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset' );
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        my $timeout = $snmp->{$oid_name}->{TIMEOUT};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1,
          TIMEOUT => $timeout || 2
        });

        foreach my $line (@$result) {
          next if (!$line);

          my (undef, $value) = split(/:/x, $line, 2);
          my ($port_index, $onu_index) = $line =~ /(\d+)\.(\d+)/xm;
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$port_index}{$onu_index}{$oid_name} = $value;
        }
      }
    }

    foreach my $branch (sort keys %port_ids) {
      next if (!$branch);

      foreach my $onu_id (sort keys %{$onu_snmp_info{$branch}}) {
        next if (!$onu_id);

        my %onu_info = ();

        $onu_info{ONU_ID}      = $onu_id;
        $onu_info{ONU_SNMP_ID} = "$branch.$onu_id";
        $onu_info{PORT_ID}     = $port_ids{$branch};
        $onu_info{PON_TYPE}    = $pon_type;
        $onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id); #according to #S18564 ONU_DHCP_PORT on FD11* always matches this format
        foreach my $oid_name (keys %{$onu_snmp_info{$branch}{$onu_id}}) {
          next if (!$oid_name);
          $onu_info{$oid_name} = $onu_snmp_info{$branch}{$onu_id}{$oid_name} || q{};
        }
        push @onu_list, { %onu_info };
      }
    }
  }

  return \@onu_list;
}

#**********************************************************
=head2 _cdata($attr) - for FD11..

  Argumnets:
    MODEL - Default FD11xx

  Returns:
    $snmp SNMP oids

=cut
#**********************************************************
sub _cdata {
  my ($attr) = @_;

  my $template = 'cdata.snmp'; #For FD11xx

  if ($attr->{MODEL}) {
    if ($attr->{MODEL} =~ /^FD12/xm) {
      $template = 'cdata_fd12.snmp';
    }
    elsif ($attr->{MODEL} =~ /^FD16|FD17/xm) {
      $template = 'cdata_fd16.snmp';
    }
  }

  my $file_content = file_op({
    FILENAME   => $template,
    PATH       => $TEMPLATE_DIR,
  });
  $file_content =~ s#//.*$##gxm;

  my $snmp = decode_json($file_content);

  if ($attr->{TYPE}) {
    return $snmp->{$attr->{TYPE}};
  }

  return $snmp;
}

#**********************************************************
=head2 _cdata_onu_status()

=cut
#**********************************************************
sub _cdata_onu_status {

  my %status = (
#    0 => 'Authenticated:text-green',
    1 => $ONU_STATUS_TEXT_CODES{ONLINE},
    2 => $ONU_STATUS_TEXT_CODES{OFFLINE},
    3 => $ONU_STATUS_TEXT_CODES{ONLINE}
  );
  return \%status;
}

#**********************************************************
=head2 _cdata_convert_temperature();

=cut
#**********************************************************
sub _cdata_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _cdata_convert_power();

=cut
#**********************************************************
sub _cdata_convert_power {
  my ($power) = @_;

  return 0 if (!$power);

  $power = $power * 0.0001;
  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = 10 * (log($power/1)/(log(10)));
    $power = sprintf("%.2f", $power);
  }

  return $power;
}
#**********************************************************
=head2 _cdata_convert_power();

=cut
#**********************************************************
sub _cdata_fd12_convert_power {
  my ($power) = @_;

  return 0 if (!$power);

  $power = $power * 0.01;
  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = sprintf("%.2f", $power);
  }

  return $power;
}
#**********************************************************
=head2 _cdata_convert_distance();

=cut
#**********************************************************
sub _cdata_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';

  return $distance;
}
#**********************************************************
=head2 _cdata_convert_voltage();

=cut
#**********************************************************
sub _cdata_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.0001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}
#**********************************************************
=head2 _cdata_fd12_convert_voltage();

=cut
#**********************************************************
sub _cdata_fd12_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.00001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

sub _cdata_sec2time {
  my ($sec)=@_;

  return sec2time($sec, { str => 1 });
}


#**********************************************************
=head2 _cdata_fd12_onu_list($port_list, $attr)

  Arguments:
    $port_list
    $attr
      DEBUG
      TIMEOUT

  Returns:
    \@onu_arr

=cut
#**********************************************************
sub _cdata_fd12_onu_list { #TODO: merge with _cdata_onu_list
  my ($port_list, $attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => $attr->{TIMEOUT} || 5,
    VERSION  => 2,
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _cdata({ TYPE => $pon_type, MODEL => 'FD12' });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    my %onu_snmp_info = ();
    foreach my $oid_name (sort keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        my $timeout = $snmp->{$oid_name}->{TIMEOUT};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1,
          TIMEOUT => $timeout || 2
        });

        foreach my $line (@$result) {
          next if (!$line);

          my ($onu_index, $value) = split(/:/x, $line, 2);
          ($onu_index) = $onu_index =~ /^\d+/xmg;
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$onu_index}{$oid_name} = $value;
        }
      }
    }

    foreach my $onu_snmp_id (sort keys %onu_snmp_info) {
      next if (!$onu_snmp_id);
      next if (!$onu_snmp_info{$onu_snmp_id}{'ONU_MAC_SERIAL'});

      my %onu_info = ();

      my $port_snmp_id_1 = $onu_snmp_id & ~0xFF;
      my $port_snmp_id_2 = ($onu_snmp_id >> 8) & 0xFF;
      my $port = $port_list->{$port_snmp_id_1} || $port_list->{$port_snmp_id_2};

      my $branch = $port->{branch};
      my $onu_id = $onu_snmp_id & 0xFF;

      $onu_info{ONU_ID} = $onu_id;
      $onu_info{ONU_SNMP_ID} = $onu_snmp_id;
      $onu_info{PORT_ID} = $port->{id};
      $onu_info{PON_TYPE} = $pon_type;
      $onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id);
      foreach my $oid_name (keys %{$onu_snmp_info{$onu_snmp_id}}) {
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu_snmp_info{$onu_snmp_id}{$oid_name} || q{};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}

sub _cdata_fd16_onu_list { #TODO: merge with _cdata_onu_list
  my ($port_list, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my @onu_list = ();
  my %pon_types = ();

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _cdata({ TYPE => $pon_type, MODEL => 'FD16' });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    my %onu_snmp_info = ();
    foreach my $oid_name (sort keys %{$snmp}) {
      next if ($oid_name eq 'main_onu_info' || $oid_name eq 'reset');
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        my $timeout = $snmp->{$oid_name}->{TIMEOUT};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1,
          TIMEOUT => $timeout || 2
        });

        foreach my $line (@$result) {
          next if (!$line);

          my ($onu_index, $value) = split(/:/x, $line, 2);
          ($onu_index) = $onu_index =~ /^\d+/xmg;
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$onu_index}{$oid_name} = $value;
        }
      }
    }

    foreach my $onu_snmp_id (sort keys %onu_snmp_info) {
      next if (!$onu_snmp_id);
      next if (!$onu_snmp_info{$onu_snmp_id}{'ONU_MAC_SERIAL'});

      my %onu_info = ();

      my $port_snmp_id_1 = $onu_snmp_id & ~0xFF;
      my $port_snmp_id_2 = ($onu_snmp_id >> 8) & 0xFF;
      my $port = $port_list->{$port_snmp_id_1} || $port_list->{$port_snmp_id_2};

      my $onu_snmp_id_bin = join('', split(//, unpack("B*", $onu_snmp_id)));

      #FD1616
      if (! $port) {
        my @port_arr = _cdata_decode_port($onu_snmp_id);
        my $port_index = _cdata_encode_port_index($port_arr[0], $port_arr[1], $port_arr[2], $port_arr[3]);
        $port = $port_list->{$port_index};

        if ($debug && $debug > 3) {
          print "$attr->{MODEL_NAME} : ONU_INDEX: $onu_snmp_id PORT_INDEX: $port_index / $port_snmp_id_1 / $port_snmp_id_2\n";
          print "PORT:" . join('/', @port_arr);
          print "\nPORT_INDEX: $port_index";
        }
      }

      my $branch = $port->{branch};
      my $onu_id = $onu_snmp_id & 0xFF;

      if (! $port->{branch}) {
        foreach my $key ( sort keys %{ $port_list }) {
          # if ($key !~/^18/) {
          #   next;
          # }
          print "ERROR NO BRANCH $key / ID1: $port_snmp_id_1 ID2: $port_snmp_id_2\n";
          my $port_bin =  join('', split(//, unpack("B*", $key))) ." $key\n";
          $port_bin =~ s/1/\+/gx;
          $port_snmp_id_1 =~ s/1/\+/gx;
          $onu_snmp_id_bin =~ s/1/\+/gx;
          print ">> $port_bin\n>>>$onu_snmp_id_bin\n";
          foreach my $k2 ( sort keys %{ $port_list->{$key} }) {
            print "  $k2 -> $port_list->{$key}->{$k2} \n";
          }
          print "\n";
          #exit;
        }
        exit;
      }

      $onu_info{ONU_ID} = $onu_id;
      $onu_info{ONU_SNMP_ID} = $onu_snmp_id;
      $onu_info{PORT_ID} = $port->{id};
      $onu_info{PON_TYPE} = $pon_type;
      $onu_info{ONU_DHCP_PORT} = sprintf("%s:%s", $branch, $onu_id);
      #$onu_info{ONU_DHCP_PORT} = sprintf("%02x%02x", $branch, $onu_id);
      foreach my $oid_name (keys %{$onu_snmp_info{$onu_snmp_id}}) {
        next if (!$oid_name);
        $onu_info{$oid_name} = $onu_snmp_info{$onu_snmp_id}{$oid_name} || q{};
      }
      push @onu_list, { %onu_info };
    }
  }

  return \@onu_list;
}


#**********************************************************
=head2 _cdata_use_memory($attr) - Get OLT slots and connect ONU

  Arguments:
    $attr$data, $info_list

  Results:
    $value

=cut
#**********************************************************
sub _cdata_use_memory {
  my($data, $info_list)=@_;

  if ($info_list->{RAM_TOTAL}) {
    $data = 100 - (100 / $info_list->{RAM_TOTAL} * $data);

    $data .= ' %';
  }

  return $data;
}

#**********************************************************
=head2 _cdata_temperature($data, $attr) - Get OLT slots and connect ONU

  Arguments:
    $data,
    $attr

  Results:
    $value

=cut
#**********************************************************
sub _cdata_temperature {
  my ($data)=@_;

  $data //= 0;

  $data = int($data / 10);

  return $data;
}


#**********************************************************
=comments _cdata_decode_port($onu_index) - Get $frame, $slot, $port, $onu  For FD1616


  Arguments:
    $onu_index

  Returns:
    ($frame, $slot, $port, $onu)

=cut
#**********************************************************
sub _cdata_decode_port {
  my ($onu_index) = @_;

  my $onu   =  $onu_index & 0x7F;             # Р±РёС‚С‹ 0..6 (7 Р±РёС‚)
  my $port  = (($onu_index >> 12) & 0x1F) + 1;  # Р±РёС‚С‹ 12..16 (5 Р±РёС‚) +1
  my $slot  = ($onu_index >> 24) & 0x0F;      # Р±РёС‚С‹ 24..27 (4 Р±РёС‚Р°)
  my $frame = ($onu_index >> 28) & 0x0F;      # Р±РёС‚С‹ 28..31 (4 Р±РёС‚Р°)

  return($frame, $slot, $port, $onu);
}


#**********************************************************
=comments _cdata_encode_port($frame, $slot, $port, $onu) - Encode ports fopr C-data FD 1616

  Arguments:
    $frame,
    $slot,
    $port,
    $onu

  Returns:
    $onu_index

=cut
#**********************************************************
sub _cdata_encode_port {
  my ($frame, $slot, $port, $onu ) = @_;

  my $onu_index = 0x480000;
  $onu_index |= ($frame & 0x0F) << 28;
  $onu_index |= ($slot  & 0x0F) << 24;
  $onu_index |= (($port - 1) & 0x1F) << 12;
  $onu_index |= ($onu   & 0x7F);

  return $onu_index;
}


#**********************************************************
=comments _cdata_encode_port_index($frame, $slot, $port, $onu) - Get port index from port dec

  Arguments:
    $frame,
    $slot,
    $port,
    $onu

  Returns:
    $port_index

=cut
#**********************************************************
sub _cdata_encode_port_index {
  my ($frame, $slot, $port, $onu ) = @_;

  my $port_index = ($frame << 28) | ($slot << 24) | 0x140000 | $port;


  return $port_index;
}


#**********************************************************
=comments _cdata_mac_behind_onu($mac) - convers data

  Arguments:
    $mac

  Returns:
    $mac_hash_ref
=cut
#**********************************************************
sub _cdata_mac_behind_onu {
  my ($mac) = @_;

  $mac = bin2mac($mac);

  return { $mac => { mac => $mac } };
}

1;
