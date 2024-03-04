=head1 NAME

  equipment grab

  Params:
    SEARCH_MAC

  Arguments:

   CLEAN=1
   IP_RANGE='192.168.1.0/24' - IP range of scan network
   FILENAME='xxx.txt'        - file with nas servers with tab delimiter values
     COLS_NAME               - Columns name for file Examples: IP
   SNMP_VERSION=1            - Default:1
   SNMP_COMMUNITY            - Community for scan and get describe
   INFO_ONLY=1               - Only show info withot adding equipment
   NAS_ID                    - NAS_ID for NAS autodetect

=cut


use strict;
use warnings "all";
use Abills::Base qw(in_array startup_files _bp);
use Nas;
use Equipment;
require Equipment::Snmp_cmd;
require Equipment::Grabbers;

use SNMP_util;
use SNMP_Session;
use Events;
use Events::API;
use Abills::Misc qw(snmp_get host_diagnostic);

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

our Admins $Admin;

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Equipment = Equipment->new($db, $Admin, \%conf);
my $Nas = Nas->new($db, \%conf, $Admin);
my $Log = Log->new($db, $Admin);

if ($debug > 2) {
  $Log->{PRINT} = 1;
}
else {
  $Log->{LOG_FILE} = $var_dir . '/log/equipment_check.log';
}

if ($argv->{GET_FW}) {
  equipment_get_version();
}
elsif ($argv->{SCAN_EQUIPMENT_PORTS}) {
  equipment_scan_equipment();
}
elsif ($argv->{DELETE_EQUIPMENT_PORTS}) {
  equipment_delete_ports();
}
else {
  equipment_grab();
}

#**********************************************************
=head2 equipment_check($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_grab {

  _log('LOG_INFO', "Equipment grab");

  my $equipment_info;
  if ($argv->{FILENAME}) {
    $equipment_info = equipment_from_file($argv->{FILENAME});
  }
  elsif ($argv->{IP_RANGE}) {
    $equipment_info = equipment_scan($argv->{IP_RANGE});
  }
  else {
    $equipment_info = equipment_from_nas($argv);
  }

  foreach my $info (@$equipment_info) {
    if ($debug > 1) {
      print "IP: $info->{IP} ";
      foreach my $key (keys %$info) {
        print "$key - $info->{$key}\n";
      }
      print "\n";
    }

    if (!$info->{IP}) {
      next;
    }
    next if ($argv->{INFO_ONLY});

    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($debug > 2) {
        _log('LOG_WARNING', "NOT_EXISTS");
      }

      if (!$info->{NAS_TYPE}) {
        $info->{NAS_TYPE} = 'other';
      }

      $Nas->add($info);

      $info->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $info->{NAS_ID} = $nas_list->[0]{nas_id};
      $info->{IP} = $nas_list->[0]{nas_ip};
    }

    $Equipment->{debug} = 1 if ($debug > 5);

    $Equipment->_list({ NAS_ID => $info->{NAS_ID} });

    if (!$Equipment->{TOTAL}) {

      if ($argv->{SNMP_VERSION}) {
        $info->{SNMP_VERSION} = $argv->{SNMP_VERSION};
      }

      if (!$info->{MODEL_ID}) {
        $info->{MODEL_ID} = _get_sysdescr({
          IP           => $info->{IP},
          MNG_PASSWORD => $info->{SNMP_COMMUNITY}
        });
      }

      my $model = equipment_model_detect($info->{MODEL_ID}, { _EQUIPMENT => $Equipment }); # unless ($argv->{IP_RANGE});
      $info->{MODEL_ID} = $model->[0]->{ID} || 0;

      if ($info->{MODEL_ID}) {
        $Equipment->_add($info);
        next;
      }
      elsif ($info->{MODEL}) {
        my $comments = "Can't find model '$info->{MODEL}'\n";
        _log('LOG_ALERT', $comments, { EVENT_TITLE => 'Can\'t find model', EVENT_MODULE => 'Equipment' });
        next;
      }
    }
    else {
      _log('LOG_INFO', "Equipment exist");
    }
  }

  return 1;
}


#**********************************************************
=head2 equipment_from_file($filename)

  Arguments:
    $filename

  Returns:

=cut
#**********************************************************
sub equipment_from_file {
  my ($filename) = @_;

  my @equipment_info = ();
  my $content = '';

  if (open(my $fh, '<', $filename)) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    _log('LOG_ALERT', "File: '$filename' not exists");
    return [];
  }

  my @rows = split(/[\r]\n/, $content);
  my @cols_name = ('IP');

  if ($argv->{COLS_NAME}) {
    @cols_name = split(/,\s?/, $argv->{COLS_NAME});
  }

  foreach my $line (@rows) {
    chomp($line);
    my @cols = split(/\t/, $line);
    my %equipment_info = ();

    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_name = ($cols_name[$i]) ? $cols_name[$i] : $i;
      $equipment_info{$col_name} = $cols[$i];
    }

    push @equipment_info, \%equipment_info;
  }

  return \@equipment_info;
}

#**********************************************************
=head2 equipment_scan($ip_range)

  Arguments:
    $ip_range

  Returns:
    $nas_info_hash_ref
    {IP}

=cut
#**********************************************************
sub equipment_scan {
  my ($ip_range) = @_;

  my ($ip, $mask) = split /\//, $ip_range;
  die "Wrong mask: '$mask'" unless ($mask > 0 && $mask < 32);
  my $ip_count = 2 ** (32 - $mask);
  my $split_ip = my ($w, $x, $y, $z) = split /\./, $ip;
  die "Wrong ip: '$ip'" unless ($split_ip == 4);

  my $i = 0;
  my @info = ();

  my $list = $Equipment->model_list({
    MODEL_NAME => '_SHOW',
    COLS_NAME  => 1,
  });

  while (++$i < $ip_count) {
    my %host = ();
    $z++;
    if ($z > 255) {
      $z = 1;
      $y++;
    }
    last if ($y > 255);

    print "check $w.$x.$y.$z\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

    my $ping = host_diagnostic("$w.$x.$y.$z", {
      QUITE         => 1,
      RETURN_RESULT => 1,
    });

    next if (!$ping);

    $host{IP} = "$w.$x.$y.$z";
    $host{NAS_NAME} = join('_', $w, $x, $y, $z);

    $host{COMMENTS} = _get_sysdescr({
      IP           => $host{IP},
      MNG_PASSWORD => $argv->{SNMP_COMMUNITY} || 'public'
    });

    if ($host{COMMENTS}) {
      if ($argv->{DEBUG} || $argv->{INFO_ONLY}) {
        print "SNMP answer: '$host{COMMENTS}'\n";
      }

      $host{MULTY_RESULT} = '';
      foreach (@$list) {
        next unless ($_->{model_name});
        if ($host{COMMENTS} =~ m/$_->{model_name}/) {
          print "Found matches:\n model_id: '$_->{id}'\n model_name: '$_->{model_name}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

          if ($host{MODEL_ID}) {
            $host{MULTY_RESULT} .= "$_->{id}, "
          }
          else {
            $host{MODEL_ID} = $_->{id};
          }
        }
      }
    }
    $host{COMMENTS} .= "\n Also found matches $host{MULTY_RESULT}" if ($host{MULTY_RESULT});

    push @info, \%host;
  }

  return \@info;
}

#**********************************************************
=head2 equipment_get_version()

  Arguments:

=cut
#**********************************************************
sub equipment_get_version {

  my $Equipment_List = $Equipment->_list({
    COLS_NAME         => 1,
    NAS_MNG_HOST_PORT => '_SHOW',
    NAS_MNG_PASSWORD  => '_SHOW',
    PAGE_ROWS         => 65000,
  });

  foreach my $element (@$Equipment_List) {
    if ($element->{nas_mng_ip_port} && $element->{nas_mng_ip_port} ne '') {
      my $snmp_com = "$element->{nas_mng_password}" . "@" . "$element->{nas_mng_ip_port}";
      my $Version = snmp_get({
        SNMP_COMMUNITY => $snmp_com,
        OID            => ".1.3.6.1.4.1.14988.1.1.4.4.0",
        SILENT         => 1,
        VERSION        => $argv->{SNMP_VERSION} || 1
      });

      if ($Version) {
        $Equipment->_change({
          NAS_ID   => $element->{nas_id},
          FIRMWARE => $Version,
        });
      }
    }
  }

  return 1;
}


#**********************************************************
=head2 equipment_scan_equipment()

  Arguments:

=cut
#**********************************************************
sub equipment_scan_equipment {

  my $Equipment_List = $Equipment->_list({
    NAS_ID            => $argv->{NAS_ID} || '',
    COLS_NAME         => 1,
    NAS_MNG_HOST_PORT => '_SHOW',
    NAS_MNG_PASSWORD  => '_SHOW',
    PORTS             => '_SHOW',
    PAGE_ROWS         => 65000,
    STATUS            => '!5;!1;!4'
  });

  my %Port_id = ();

  foreach my $element (@$Equipment_List) {
    print "Scanning devices: $element->{nas_id}\n";
    my $ports_list = $Equipment->port_list({
      COLS_NAME => 1,
      ID        => '_SHOW',
      NAS_ID    => $element->{nas_id},
      PAGE_ROWS => 65000,
    });

    my $snmp_com = "$element->{nas_mng_password}" . "@" . "$element->{nas_mng_ip_port}";
    #    my $snmp_com = "snmppass" . "@" . "$element->{nas_mng_ip_port}";
    my $all_ports = snmp_get({
      SNMP_COMMUNITY => $snmp_com,
      OID            => ".1.3.6.1.2.1.2.2.1.8",
      WALK           => 1,
      VERSION        => $argv->{SNMP_VERSION} || 2,
    });

    if (@$all_ports) {
      my @exPorts = ();
      foreach my $port (@$ports_list) {
        push @exPorts, $port->{port};
        $Port_id{"$port->{port}"} = $port->{id};
      }

      foreach my $port (@$all_ports) {
        my ($port_number, $port_status) = split(/:/, $port);
        if (!in_array($port_number, \@exPorts)) {
          $Equipment->port_add({
            NAS_ID => $element->{nas_id},
            STATUS => $port_status,
            PORT   => $port_number,
          });
        }
        else {
          $Equipment->port_change({
            ID     => $Port_id{$port_number},
            STATUS => $port_status,
          });
        }
      }
    }

    $ports_list = $Equipment->port_list({
      COLS_NAME => 1,
      ID        => '_SHOW',
      NAS_ID    => $element->{nas_id},
      PAGE_ROWS => 65000,
    });

    foreach my $port (@$ports_list) {
      $Port_id{"$port->{port}"} = $port->{id};
    }

    _equipment_port_vlan($snmp_com, \%Port_id);
    _equipment_port_description($snmp_com, \%Port_id);
  }

  return 1;
}


#**********************************************************
=head2 _equipment_port_vlan()

  Arguments:
    $snmp_com,   - SNMP_COMMUNITY string
    $Port_id     - hash with current port

=cut
#**********************************************************
sub _equipment_port_vlan {
  my ($snmp_com, $Port_id) = @_;

  my $All_ports = snmp_get({
    SNMP_COMMUNITY => $snmp_com,
    OID            => ".1.3.6.1.2.1.17.7.1.4.5.1.1",
    WALK           => 1,
    VERSION        => $argv->{SNMP_VERSION} || 2,
  });

  if (@$All_ports) {
    foreach my $port (@$All_ports) {
      my ($port_number, $port_vlan) = split(/:/, $port);

      $Equipment->port_change({
        ID   => $Port_id->{$port_number},
        VLAN => $port_vlan,
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 _equipment_port_description()

  Arguments:
    $snmp_com,   - SNMP_COMMUNITY string
    $Port_id     - hash with current port

=cut
#**********************************************************
sub _equipment_port_description {
  my ($snmp_com, $Port_id) = @_;

  my $All_ports = snmp_get({
    SNMP_COMMUNITY => $snmp_com,
    OID            => ".1.3.6.1.2.1.2.2.1.2",
    WALK           => 1,
    VERSION        => $argv->{SNMP_VERSION} || 2,
  });

  if (@$All_ports) {
    foreach my $port (@$All_ports) {
      my ($port_number, $port_description) = split(/:/, $port);

      $Equipment->port_change({
        ID       => $Port_id->{$port_number},
        COMMENTS => $port_description,
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 equipment_delete_ports()

  Arguments:

=cut
#**********************************************************
sub equipment_delete_ports {

  if ($argv->{NAS_ID}) {
    $Equipment->port_del_nas({
      NAS_ID => $argv->{NAS_ID},
    })
  }
}

#**********************************************************
=head2 _get_sysdescr($attr)

  Arguments:
    $attr
      IP
      MNG_PASSWORD

  Returns:
    $describe

=cut
#**********************************************************
sub _get_sysdescr {
  my ($attr) = @_;

  my $snmp_community = ($argv->{SNMP_COMMUNITY} || $attr->{MNG_PASSWORD} || 'public') . '@' . $attr->{IP};

  my $describe = snmp_get({
    SNMP_COMMUNITY => $snmp_community,
    OID            => ".1.3.6.1.2.1.1.1.0",
    SILENT         => (!$debug) ? 1 : 0,
    VERSION        => $argv->{SNMP_VERSION} || 1
  });

  return $describe;
}

#**********************************************************
=head2 equipment_from_nas($attr)

  Arguments:
    $attr
      NAS_ID

  Returns:
    $equipment_info_arr_ref

=cut
#**********************************************************
sub equipment_from_nas {
  my ($attr) = @_;

  my @equipment_info = ();

  my $nas_list = $Nas->list({
    NAS_ID    => $attr->{NAS_ID},
    PAGE_ROWS => 65000,
    COLS_NAME => 1
  });

  foreach my $nas (@$nas_list) {
    push @equipment_info, {
      IP             => $nas->{nas_mng_ip_port} || $nas->{nas_ip},
      SNMP_COMMUNITY => $nas->{nas_mng_password}
    };
  }

  return \@equipment_info;
}

1;
