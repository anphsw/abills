=head1
  Name: equipment ping

=cut


use strict;
use Abills::Filters;
use Abills::Base qw(in_array);
use Equipment;
use Abills::HTML;
use Nas;
use Net::Ping;
use JSON;
use Data::Dumper;
#require Abills::Misc;
use SNMP;
our $Admin;
our $db;
our %conf;
our $argv;
our $debug;

#load_pmodule('SNMP');

SNMP::initMib();
SNMP::addMibDirs($Bin."/../Abills/MIBs/private", $Bin."/../Abills/MIBs");
SNMP::addMibFiles(glob($Bin."/../Abills/MIBs/private".'/*'));
$Admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $sess;

equipment_check();

#**********************************************************
=head2 equipment_check($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub equipment_check {

  my $timeout = $argv->{TOUT} || '5';
  if ($argv->{NAS_IPS}) {
    $LIST_PARAMS{NAS_IP} = $argv->{NAS_IPS};
  }
  if ($argv->{DEBUG} && $argv->{DEBUG} > 7) {
    $Equipment->{debug} = 1;
  }

  my $SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $p = Net::Ping->new() or die "Can't create new ping object: $!\n";
  my $Nas = Nas->new( $db, $Admin, \%conf );
  my $equipment_list = $Equipment->_list( { COLS_NAME => 1,
      PAGE_ROWS                                       => 100000,
      NAS_ID                                          => '_SHOW',
      NAS_IP                                          => '_SHOW',
      STATUS                                          => '_SHOW',
      MAC                                             => '_SHOW',
      NAS_NAME                                        => '_SHOW',
      PORTS                                           => '_SHOW',
      %LIST_PARAMS,
    } );
  foreach my $equip (@$equipment_list) {
    next if (!$equip->{nas_ip});
    $Nas->info( { IP => $equip->{nas_ip} } );
    my $ping_result = '0';
    $ping_result = '1' if $p->ping( $equip->{nas_ip}, $timeout );

    if ($debug > 2) {
      print "$equip->{nas_ip}: $ping_result\n";
    }

    if($ping_result == 1){
    	$sess = new SNMP::Session(DestHost => $equip->{nas_ip}, Community => $SNMP_COMMUNITY, Version => 2, UseEnums =>1 );
    	my $sysoid = $sess->get(['sysObjectID',0]);

    	my $models = $Equipment->model_list({COLS_NAME => 1,
                                            #MODEL_ID => $equip->{id},
                                            SYS_OID  => $sysoid,
                                            SNMP_TMPL  => '_SHOW',
                                            SNMP_PORT_TMPL  => '_SHOW',
                                            });

       	if ($equip->{id} ne $models->[0]->{id}){
      		$Equipment->_change({NAS_ID => $equip->{nas_id}, MODEL_ID => $models->[0]->{id} });
      		#$Equipment->_change({NAS_ID => $equip->{nas_id}, SNMP_INFO => $to_json});
      		#$Equipment->_change({NAS_ID => $equip->{nas_id}, PORTS => $vals[1]});
      		#$Log();
      	}
      	
      	if ($argv->{INFO}) {
      		my $json_arr = decode_json($models->[0]->{snmp_tmpl});

      		my $vars = new SNMP::VarList(@$json_arr);
      		my @vals = $sess->get($vars);
      		#$model = $SNMP::MIB{$vals[0]}{label};
      		#$mac = join( ':', unpack("H2H2H2H2H2H2",$vals[2]));
      		#printf "ports $vals[1] MAC: $mac $model NAS ".$equip->{mac}."\n";
      		my $to_json = encode_json(\@vals);
      		$Equipment->_change({NAS_ID => $equip->{nas_id}, SNMP_INFO => $to_json});
      		#if ( (! $equip->{ports}) || ( $vals[1] != $equip->{ports} )){
      		#	printf "$equip->{nas_ip} ports $vals[1] MAC: $mac $model NAS ".$equip->{mac}."\n";
      			#$Equipment->_change({NAS_ID => $equip->{nas_id}, PORTS => $vals[1]});
      		#}
      	}
      	
		if ($argv->{PORTS}) {
			port_info({ TMPL => $models->[0]->{snmp_port_tmpl},
						PORTS => $equip->{ports},
						NAS_ID => $equip->{nas_id}
						});
  		}
  		if ($argv->{FDB}) {
			fdb({PORTS => $equip->{ports},
			NAS_ID => $equip->{nas_id}
			});
  		}
  	}
  	$p->close;
  }
  return 1;
}

#**********************************************************
=head2 port_info($attr)

=cut
#**********************************************************      	
sub port_info {
  my ($attr) = @_;

  my $json_port_arr = decode_json($attr->{TMPL});
  my $port_vars     = SNMP::VarList->new( @$json_port_arr );
  my @ports_vals    = $sess->bulkwalk( 0, 1, $port_vars );
  my @port_arr;
  foreach my $vr (0 .. $attr->{PORTS} - 1) {
    my @new;
    foreach my $var (@ports_vals) {
      push @new, $var->[$vr]->[2];
    }
    push @port_arr, \@new;
  }
  my $port_to_json = encode_json(\@port_arr);
  $Equipment->_change( { NAS_ID => $attr->{NAS_ID}, SNMP_PORT_INFO => $port_to_json } );
}

#**********************************************************
# stats
#********************************************************** 
sub stats {

}

#**********************************************************
=head2 fdb($attr)

=cut
#********************************************************** 
sub fdb{
 	my ($attr) = @_;
 	my $ctime =  POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
 	#$fdb_vars = new SNMP::VarList(@$json_port_arr);
    my @fdb_vals = $sess->bulkwalk(0,1,['dot1qTpFdbPort']);
    my @fdb_arr;
    foreach my $var (@{$fdb_vals[0]}) {
    	if( $var->[2] ~~[1..$attr->{PORTS}-4] ){
      		my @whithvid = split(/[.\s]/,$var->[1]);
      		my $vid = $whithvid[0];
      		my @k;
      		foreach my $vr (1..@whithvid-1) {
      			push @k,sprintf( '%.2x', $whithvid[$vr]);
         	}
         	push @fdb_arr,[$var->[2], join(":",@k), $vid];
         	$Equipment->mac_log_add({ NAS_ID   => $attr->{NAS_ID},
         							  MAC      => join(":",@k),
         							  VLAN     => $vid,
         							  PORT     => $var->[2],
         							  DATETIME => $ctime
         							  });
      	}	
    }
    my $fdb_to_json = encode_json(\@fdb_arr);
    $Equipment->_change({ NAS_ID => $attr->{NAS_ID}, FDB_INFO => $fdb_to_json});
}


1
