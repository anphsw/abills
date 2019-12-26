=head1 NAME

 billd plugin

 DESCRIBE: PON load onu info

 Arguments:

   TIMEOUT
   RELOAD  - Reload onu
   STEP
   SKIP_RRD - Skip gen rrd
   NAS_IDS
   multi
   CPE_CHECK - 
   CPE_FILL

=cut

use strict;
use warnings;
use Abills::Filters;
use SNMP_Session;
use SNMP_util;
use Equipment;
use Events;
use Events::API;
use Data::Dumper;
use Abills::Base qw(load_pmodule in_array check_time gen_time in_array);
use FindBin '$Bin';

use threads;
our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir
);

my $running_threads = 10;
our $Equipment = Equipment->new($db, $Admin, \%conf);
my $Events = Events::API->new($db, $Admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $Admin, \%conf);

do 'Abills/Misc.pm';

require Equipment::Grabbers;
require Equipment::Pon_mng;
require Equipment::Graph;

if ($argv->{NAS_IDS} && !$argv->{CPE_FILL}) {
  _equipment_pon_load($argv->{NAS_IDS});
}
elsif ($argv->{multi}) {
  _equipment_pon_multi();
}
elsif ($argv->{SERIAL_SCAN}) {
  _scan_mac_serial();
}
elsif ($argv->{SNMP_SERIAL_SCAN_ALL}) {
  _scan_mac_serial_on_all_nas();
}
elsif ($argv->{CPE_FILL} || $argv->{FORCE_FILL}) {
  _save_port_and_nas_to_internet_main();
}
elsif ($argv->{CPE_CHECK}) {
  _check_port_and_nas_from_internet_main();
}
else {
  _equipment_pon();
}


#**********************************************************
=head2 _equipment_pon($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub _equipment_pon {

  if ($debug > 6) {
    $Equipment->{debug} = 1;
  }
  my $equipment_list = $Equipment->_list({
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0',
    TYPE_NAME => '4',
  });

  foreach my $line (@$equipment_list) {
    #    my $zz = `/usr/abills/libexec/billd equipment_pon NAS_ID=$line->{nas_id}`;
    _equipment_pon_load($line->{nas_id});
  }

  return 1;
}
#**********************************************************
=head2 _equipment_pon_load($nas_id)

=cut
#**********************************************************
sub _equipment_pon_load {
  my ($nas_id) = @_;

  my $pon_begin_time = check_time();
  our $SNMP_TPL_DIR = $Bin . "/../Abills/modules/Equipment/snmp_tpl/";
  #"/usr/abills/Abills/modules/Equipment/snmp_tpl/";

  $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef }, \%conf);
  if (!$db->{db}) {
    print "Error: SQL connect error\n";
    exit;
  }

  my $admin_ = Admins->new($db, \%conf);
  $admin_->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
  $Equipment = Equipment->new($db, $admin_, \%conf);

  if ($debug > 6) {
    $Equipment->{debug} = 1;
  }

  my $Equipment_list = $Equipment->_list({
    NAS_ID           => $nas_id,
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE             => '_SHOW',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => '_SHOW',
    NAS_IP           => '_SHOW',
    MNG_HOST_PORT    => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => '',
    COLS_NAME        => 1
  });

  if ($Equipment->{TOTAL} < 1) {
    print "No found any pon equipment\n";
    return 1;
  }

  my $nas_info = $Equipment_list->[0];
  $Equipment->model_info($nas_info->{model_id});
  if (!$nas_info->{nas_ip}) {
    print "NAS_ID: $nas_info->{nas_id} deleted\n";
    # next;
    return 1;
  }
  elsif (!$nas_info->{nas_mng_password}) {
    print "NAS_ID: $nas_info->{nas_id} COMMUNITY not defined\n";
    $nas_info->{nas_mng_password} = 'public';
    #next;
  }

  my $SNMP_COMMUNITY = "$nas_info->{nas_mng_password}\@" . (($nas_info->{nas_mng_ip_port}) ? $nas_info->{nas_mng_ip_port} : $nas_info->{nas_ip});
  my $onu_counts = 0;

  if ($nas_info->{status} eq 0) {
    $nas_info->{NAME} = $nas_info->{vendor_name};
    my $nas_type = equipment_pon_init({ NAS_INFO => $nas_info });
    if (!$nas_type) {
      return 0;
    }

    my $onu_list_fn = $nas_type . '_onu_list';

    if (defined(&{$onu_list_fn})) {
      my $olt_ports = ();
      my $port_list = $Equipment->pon_port_list({
        COLS_NAME  => 1,
        COLS_UPPER => 1,
        NAS_ID     => $nas_id
      });

      #Add ports
      if ($argv->{RELOAD}) {
        if ($debug > 2) {
          print "Reload ports: $Equipment->{TOTAL}\n";
        }

        foreach my $line (@$port_list) {
          if ($debug > 1) {
            print "Delete onu port: $line->{ID} \n";
          }

          $Equipment->onu_del(0, { PORT_ID => $line->{ID} });
          $Equipment->pon_port_del($line->{ID});
        }
        $Equipment->{TOTAL} = 0;
      }

      if (!$Equipment->{TOTAL}) {
        equipment_pon_get_ports({
          VERSION        => $nas_info->{snmp_version} || 1,
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          NAS_ID         => $nas_id,
          NAS_TYPE       => $nas_type,
          MODEL_NAME     => $Equipment->{MODEL_NAME},
          SNMP_TPL       => $Equipment->{SNMP_TPL},
        });

        $port_list = $Equipment->pon_port_list({
          COLS_NAME  => 1,
          COLS_UPPER => 1,
          NAS_ID     => $nas_id
        });
      }

      foreach my $line (@$port_list) {
        $olt_ports->{$line->{snmp_id}} = $line;
      }

      #my $olt_ports = equipment_pon_get_ports({SNMP_COMMUNITY => $SNMP_COMMUNITY, NAS_ID => $nas_id, NAS_TYPE => $nas_type, MODEL_NAME => $Equipment->{MODEL_NAME}, SNMP_TPL => $Equipment->{SNMP_TPL}});
      my $onu_snmp_list = &{\&$onu_list_fn}($olt_ports, {
        VERSION        => $nas_info->{snmp_version} || 1,
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        TIMEOUT        => $argv->{TIMEOUT} || 5,
        SKIP_TIMEOUT   => 1,
        DEBUG          => $debug,
        MODEL_NAME     => $Equipment->{MODEL_NAME},
        TYPE           => 'dhcp'
      });

      $onu_counts = $#{$onu_snmp_list} + 1;

      my $onu_database_list = $Equipment->onu_list({
        NAS_ID     => $nas_id,
        COLS_NAME  => 1,
        SKIP_DOMAIN=> 1,
        PAGE_ROWS  => 100000,
        ONU_GRAPH  => '_SHOW',
        COMMENTS   => '_SHOW',
        ONU_STATUS => '_SHOW',
      });

      my $created_onu = ();
      foreach my $onu (@$onu_database_list) {
        $created_onu->{ $onu->{onu_snmp_id} }->{ONU_GRAPH} = $onu->{onu_graph};
        $created_onu->{ $onu->{onu_snmp_id} }->{ONU_DESC} = $onu->{comments} || '';
        $created_onu->{ $onu->{onu_snmp_id} }->{ID} = $onu->{id};
        $created_onu->{ $onu->{onu_snmp_id} }->{ONU_STATUS} = $onu->{onu_status};
      }

      my @MULTI_QUERY = ();
      my @ONU_ADD = ();
      #print Dumper $onu_list;
      my %pon_types_oids = ();
      foreach my $onu (@$onu_snmp_list) {
        if ($created_onu->{ $onu->{ONU_SNMP_ID} }) {
          #          if($debug > 6) {
          #            print "$nas_type TYPE => $onu->{PON_TYPE} \n";
          #          }

          if (! $pon_types_oids{$onu->{PON_TYPE}}) {
            $pon_types_oids{$onu->{PON_TYPE}} = &{\&{$nas_type}}({ TYPE => $onu->{PON_TYPE}, MODEL => ($nas_info->{model_name} || '') });
          }
          my $snmp = $pon_types_oids{$onu->{PON_TYPE}};
          #          if ($created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} && $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} ne $onu->{ONU_DESC}){
          #            my $set_desc_fn = $nas_type . '_set_desc';
          #            if ( defined( &{$set_desc_fn} ) ){
          #              #print "CHANGE $onu->{ONU_SNMP_ID} TYPE: \"$onu->{PON_TYPE}\" DESC: \"$onu->{ONU_DESC}\" OID: \"$snmp->{ONU_DESC}->{OIDS}.$onu->{ONU_SNMP_ID}\"";
          #              &{ \&$set_desc_fn }({ SNMP_COMMUNITY => $SNMP_COMMUNITY,
          #                      ONU_ID         => $onu->{ONU_ID},
          #                      PON_TYPE       => $onu->{PON_TYPE},
          #                      OID            => $snmp->{ONU_DESC}->{OIDS}.'.'.$onu->{ONU_SNMP_ID},
          #                      DESC           => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC}
          #                  });
          #            }
          #          }
          my @onu_graph_types = split(',', $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_GRAPH});
          foreach my $graph_type (@onu_graph_types) {
            my @onu_graph_data = ();
            if ($graph_type eq 'SIGNAL' && ($snmp->{ONU_RX_POWER}->{OIDS} || $snmp->{OLT_RX_POWER}->{OIDS})) {
              push @onu_graph_data, { DATA => $onu->{ONU_RX_POWER} || 0, SOURCE => $snmp->{ONU_RX_POWER}->{NAME} || q{}, TYPE => 'GAUGE' };
              push @onu_graph_data, { DATA => $onu->{OLT_RX_POWER} || 0, SOURCE => $snmp->{OLT_RX_POWER}->{NAME} || q{OLT_RX_POWER}, TYPE => 'GAUGE' };
            }
            elsif ($graph_type eq 'TEMPERATURE' && $snmp->{TEMPERATURE}->{OIDS}) {
              push @onu_graph_data, { DATA => $onu->{TEMPERATURE} || 0, SOURCE => $snmp->{TEMPERATURE}->{NAME}, TYPE => 'GAUGE' };
            }
            elsif ($graph_type eq 'SPEED' && ($snmp->{ONU_IN_BYTE}->{OIDS} || $snmp->{ONU_OUT_BYTE}->{OIDS})) {
              push @onu_graph_data, { DATA => $onu->{ONU_IN_BYTE} || 0, SOURCE => $snmp->{ONU_IN_BYTE}->{NAME}, TYPE => 'COUNTER' };
              push @onu_graph_data, { DATA => $onu->{ONU_OUT_BYTE} || 0, SOURCE => $snmp->{ONU_OUT_BYTE}->{NAME}, TYPE => 'COUNTER' };
            }

            if ($#onu_graph_data > -1 && !$argv->{SKIP_RRD}) {
              if ($debug > 3) {
                print "NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => $graph_type, DATA => " . join(',', @onu_graph_data) . " STEP => ". ($argv->{STEP} || '300'). "\n";
              }
              add_graph({ NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => $graph_type, DATA => \@onu_graph_data, STEP => $argv->{STEP} || '300' });
            }
          }

          push @MULTI_QUERY, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS},
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT},
            $onu->{PORT_ID},
            $onu->{ONU_MAC_SERIAL},
            $onu->{VLAN} || 0,
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $onu->{LINE_PROFILE} || 'ONU',
            $onu->{SRV_PROFILE} || 'ALL',
            '0',
            $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}
          ];
          #$Equipment->onu_change( { ID => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}, NAS_ID => $nas_id, %{$onu} } );
          delete $created_onu->{ $onu->{ONU_SNMP_ID} };
        }
        else {
          #$Equipment->onu_add( { NAS_ID => $nas_id, %{$onu} } );
          push @ONU_ADD, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS} || 0,
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT} || '',
            $onu->{PORT_ID} || '',
            $onu->{ONU_MAC_SERIAL} || '',
            $onu->{VLAN} || 0,
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $onu->{ONU_SNMP_ID},
            $onu->{LINE_PROFILE} || 'ONU',
            $onu->{SRV_PROFILE} || 'ALL',
          ];
        }
        #        pon_alert($onu->{ONU_RX_POWER});
      }

      my $time;

      foreach my $snmp_id (keys %{$created_onu}) {
        $time = check_time() if ($debug > 2);
        print "UPDATE EXPIRED ONU." if ($debug > 2);
        if ($created_onu->{ $snmp_id }->{ONU_STATUS} && $created_onu->{ $snmp_id }->{ONU_STATUS} > 0) {
          $Equipment->onu_change({
            ID         => $created_onu->{ $snmp_id }->{ID},
            ONU_STATUS => 2,
            DELETED    => 1
          });
          print " " . gen_time($time) . "\n" if ($debug > 2);
        }
      }

      if ($#ONU_ADD > -1) {
        $time = check_time() if ($debug > 2);
        print "ADD ONU." if ($debug > 2);
        $Equipment->onu_add({ MULTI_QUERY => \@ONU_ADD });
        print " " . gen_time($time) . "\n" if ($debug > 2);
        my $serials = join(', ', map {$_->[8]} @ONU_ADD);
        $Sender->send_message({
          TO_ADDRESS  => $conf{ADMIN_MAIL},
          MESSAGE     => "Add " . ($#ONU_ADD + 1) . " new onu on NAS_ID: $nas_id (" . ($nas_info->{NAME} || q{}) . ") Serials: $serials\n",
          SUBJECT     => "Add new ONU",
          SENDER_TYPE => 'Mail',
          DEBUG       => 5,
        });
      }
      if ($#MULTI_QUERY > -1) {
        $time = check_time() if ($debug > 2);
        print "UPDATE ONU info." if ($debug > 2);
        $Equipment->onu_change({ MULTI_QUERY => \@MULTI_QUERY });
        print " " . gen_time($time) . "\n" if ($debug > 2);
      }
    }
  }

  if ($debug) {
    print "NAS_TYPE : " . ($nas_info->{NAME} || q{}) . " MODEL_NAME: " . ($Equipment->{MODEL_NAME} || q{}) . ", NAS_IP: $nas_info->{nas_ip}"
      . " NAS_ID: $nas_id, ONU: $onu_counts " . gen_time($pon_begin_time) . "\n";
  }

  return 1;
}

#**********************************************************
=head2 wait_ps($threads, $max_threads) - Wait until ps end for next thread

  Arguments:
    $threads     - thread id arrays
    $max_threads - Max thread running

  Return:
     1 - wait
     0 - run


=cut
#**********************************************************
sub wait_ps {
  my ($threads, $max_threads) = @_;

  my $running_ps = 0;

  foreach my threads $th (@$threads) {
    my $running = $th->is_running();
    if ($running) {
      $running_ps++
    }
    #else {
    #  $running_ps--;
    #}
  }

  if ($running_ps > $max_threads) {
    print "Sleep: Running: $running_ps Total: $#{$threads}\n" if ($debug > 3);
    sleep 1;
    #run
    return 1;
  }

  #Finish
  return 0;
}

#**********************************************************
=head2 _equipment_pon_multi()

=cut
#**********************************************************
sub _equipment_pon_multi {

  my @threads = ();

  my $equipment_list = $Equipment->_list({
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0',
    TYPE_NAME => '4',
  });

  foreach my $line (@$equipment_list) {
    my threads $t = threads->create(\&_equipment_pon_load, $line->{nas_id});
    push @threads, $t;
    $t->detach();

    while (wait_ps(\@threads, $running_threads)) {

    }
  }

  while (wait_ps(\@threads, 0)) {
    print "Wait finish\n" if ($debug > 3);
  }

  return 1;
}


#**********************************************************
=head2 pon_alert($attr)

=cut
#**********************************************************
sub pon_alert {
  my ($parameter) = @_;

  if (!$parameter) {
    return 0;
  }

  my %parameters = (
    # Name for module
    MODULE      => 'Equipment',
    # Text
    COMMENTS    => 'PON ALERT: ' . $parameter,
    # Link to see external info
    EXTRA       => '',
    # 1..5 Bigger is more important
    PRIORITY_ID => 2,
  );

  if (!$parameter || $parameter == 65535) {
    return 0;
  }
  elsif ($parameter > 0) {
    return 0;
  }
  elsif ($parameter > -8 || $parameter < -30) {
    #$parameter = $html->color_mark($parameter, 'text-red' );
  }
  elsif ($parameter > -10 || $parameter < -27) {
    $parameters{PRIORITY_ID} = 1;
  }
  else {
    return 0;
  }

  $Events->events_add(\%parameters);

  return 1;
}

#**********************************************************
=head2 _scan_mac_serial()

=cut
#**********************************************************
sub _scan_mac_serial {

  my $equipment_list = $Equipment->_list({
    COLS_NAME  => 1,
    PAGE_ROWS  => 100000,
    STATUS     => '0',
    TYPE_NAME  => '4',
    MAC_SERIAL => "_SHOW",
    ID         => "_SHOW",
  });
  
  my @mac_array = ();
  my @dublicate = ();
  foreach my $pon (@$equipment_list) {
    my $onu_list = $Equipment->onu_list({
      COLS_NAME  => 1,
      PAGE_ROWS  => 100000,
      GROUP_BY   => 'onu.id',
      # STATUS     => '0',
      # TYPE_NAME  => '4',
      MAC_SERIAL => "_SHOW",
      NAS_ID     => $pon->{nas_id},
    });

    foreach my $onu (@$onu_list) {
      if ($onu->{mac_serial} && !in_array($onu->{mac_serial}, \@mac_array)) {
        push @mac_array, $onu->{mac_serial};
      }
      elsif ($onu->{mac_serial}) {
        push @dublicate, $onu;
      }
    }
  }

  if (scalar @dublicate != 0) {
    my $message = "";

    foreach my $element (@dublicate) {
      $message = "Nas (id)" . $element->{nas_id} . " has " . $element->{mac_serial} . " mac_serial duplicate\n";
      _generate_new_event($message);
    }
  }

  return 1;
}

#**********************************************************
=head2 _generate_new_event($comments)

  Arguments:
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub _generate_new_event {
  my ($comments) = @_;

  #  print "EVENT: $name, $comments \n";
  print $comments . "\n" if ($argv->{DEBUG});

  $Events->add_event({
    MODULE      => "Equipment",
    PRIORITY_ID => 5,
    STATE_ID    => 1,
    TITLE       => '_{WARNING}_',
    COMMENTS    => $comments,
  });

  return 1;
}

#**********************************************************
=head2 _scan_mac_serial_on_all_nas($comments)

  Arguments:

  Returns:

=cut
#**********************************************************
sub _scan_mac_serial_on_all_nas {

  my $Equipment_list = $Equipment->_list({
    NAS_ID           => '_SHOW',
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE             => '_SHOW',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => '_SHOW',
    NAS_IP           => '_SHOW',
    MNG_HOST_PORT    => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => '4',
    COLS_NAME        => 1,
    COLS_UPPER       => 1,
  });

  my %Nas_macs = ();

  foreach my $nas (@$Equipment_list) {
    my $port_type = $Equipment->pon_port_list({
      NAS_ID    => $nas->{NAS_ID},
      COLS_NAME => 1,
    });

    my $oids = '';
    my $nas_type = equipment_pon_init({ VENDOR_NAME => $nas->{VENDOR_NAME} });
    if ($nas_type eq "_zte") {
      $oids = _zte({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_eltex") {
      $oids = _eltex({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_bdcom") {
      $oids = _bdcom({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_huawei") {
      $oids = _huawei({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_vsolution") {
      $oids = _vsolution({ TYPE => $port_type->[0]{pon_type} });
    }
    elsif ($nas_type eq "_cdata") {
      $oids = _cdata({ TYPE => $port_type->[0]{pon_type} });
    }
    else {
      next;
    }

    my $SNMP_COMMUNITY = $nas->{NAS_MNG_PASSWORD} . '@' . $nas->{NAS_MNG_IP_PORT};

    my $mac_serials = snmp_get({
      %$nas,
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      WALK           => 1,
      OID            => $oids->{ONU_MAC_SERIAL}{OIDS},
      VERSION        => 2,
      TIMEOUT        => 2
    });

    foreach my $mac (@$mac_serials) {
      if ($Nas_macs{$mac}) {
        my $message = "You have mac_serial duplicate in $Nas_macs{$mac} and $nas->{NAS_ID} $nas->{NAS_NAME} ($mac)\n";
        _generate_new_event($message);
      }
      else {
        $Nas_macs{$mac} = $nas->{NAS_ID} . " " . $nas->{NAS_NAME};
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 _save_port_and_nas_to_internet_main()

=cut
#**********************************************************
sub _save_port_and_nas_to_internet_main {
  my $onu_list = $Equipment->onu_and_internet_cpe_list();
  require Internet;
  my @ids = split ';', $argv->{NAS_IDS} || '';
  my $Internet = Internet->new($db, $Admin, \%conf);
  foreach my $line (@$onu_list) {
    if ($argv->{NAS_IDS} && !in_array($line->{onu_nas}, \@ids)) {
      next;
    }
    if ($argv->{FORCE_FILL} || !$line->{user_port} || !$line->{user_nas}) {
      $Internet->change({
        UID    => $line->{uid},
        ID     => $line->{service_id},
        NAS_ID => $line->{onu_nas},
        PORT   => $line->{onu_port},
      });
      print "User:$line->{uid} add port ($line->{onu_port}) and nas ($line->{onu_nas})\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 _check_port_and_nas_in_internet_main()

=cut
#**********************************************************
sub _check_port_and_nas_from_internet_main {
  my $onu_list = $Equipment->onu_and_internet_cpe_list();
  foreach my $line (@$onu_list) {
    if ($line->{onu_port} ne $line->{user_port}) {
      $line->{onu_port} //= '';
      print "User:$line->{uid},  port does not match user_port:'$line->{user_port}'/onu_port:'$line->{onu_port}'\n";
    }
    if ($line->{onu_nas} ne $line->{user_nas}) {
      print "User:$line->{uid},  nas does not match user_nas:'$line->{user_nas}'/onu_nas:'$line->{onu_nas}'\n";
    }
  }
  return 1;
}

1
