package Ipn;
# Ipn functions
#
#


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw(
  &ip_in_zone
  &is_exist
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


require Billing;
Billing->import();
my $Billing;

use POSIX qw(strftime);
my $DATE = strftime "%Y-%m-%d", localtime(time);
my ($Y, $M, $D)=split(/-/, $DATE, 3);

my %ips = ();
my $db;
my $CONF;
my $debug = 0;

my %intervals = ();
my %tp_interval = ();


my @zoneids;
my @clients_lst = ();

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  if (! defined($CONF->{KBYTE_SIZE})){
  	$CONF->{KBYTE_SIZE}=1024;
   }

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};

  if ($CONF->{DELETE_USER}) {
    $self->user_del({ UID => $CONF->{DELETE_USER} });
   }
  
  $self->{TRAFFIC_ROWS}=0;
  $Billing = Billing->new($db, $CONF);
  return $self;
}


#**********************************************************
# Delete user log
# user_del 
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "DELETE FROM ipn_log WHERE uid='$attr->{UID}';", 'do');

  $admin->action_add($attr->{UID}, "DELETE");
  return $self;   
}

#**********************************************************
# user_ips
#**********************************************************
sub user_ips {
  my $self = shift;
  my ($DATA) = @_;

  
  my $sql;
  
  if ($DATA->{NAS_ID} =~ /(\d+)-(\d+)/) {
  	my $first = $1;
  	my $last = $2;
  	my @nas_arr = ();
  	for(my $i=$1; $i<=$2; $i++) {
  	  push @nas_arr, $i;
     }

    $DATA->{NAS_ID} = join(',', @nas_arr);
   }
  
  if ( $CONF->{IPN_DEPOSIT_OPERATION} ) {
  	$sql="select u.uid, calls.framed_ip_address, calls.user_name,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id),
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit,
      tp.payment_type,
      UNIX_TIMESTAMP() - calls.lupdated,
      calls.nas_id,
      tp.octets_direction
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
    WHERE u.id=calls.user_name
    and calls.nas_id IN ($DATA->{NAS_ID});";
  }
  else {
  	$sql = "SELECT u.uid, calls.framed_ip_address, calls.user_name, 
    calls.acct_session_id,
    calls.acct_input_octets,
    calls.acct_output_octets,
    calls.tp_id,
    NUll,
    NULL,
    1,
    UNIX_TIMESTAMP() - calls.lupdated,
    calls.nas_id,
    0
    FROM (dv_calls calls, users u)
   WHERE u.id=calls.user_name
   and calls.nas_id IN ($DATA->{NAS_ID});";
  }  
  
  $self->query($db, $sql);

  my $list = $self->{list};
  my %session_ids = ();
  my %users_info  = ();
  my %interim_times  = ();
  
  $ips{0}='0';
  $self->{0}{IN}=0;
 	$self->{0}{OUT}=0;

  foreach my $line (@$list) {
     #UID
  	 $ips{$line->[1]}         = $line->[0];
     
     #IN / OUT octets
  	 $self->{$line->[1]}{IN}  = $line->[4];
  	 $self->{$line->[1]}{OUT} = $line->[5];
     
     #user NAS
     $self->{$line->[1]}{NAS_ID} = $line->[11];
     
     #Octet direction
     $self->{$line->[1]}{OCTET_DIRATION} = $line->[12];
     
  	 $users_info{TPS}{$line->[0]} = $line->[6];
   	 #User login
   	 $users_info{LOGINS}{$line->[0]} = $line->[2];
     #Session ID
     $session_ids{$line->[1]} = $line->[3];
     $interim_times{$line->[3]}=$line->[10];
     #$self->{INTERIM}{$line->[3]}{TIME}=$line->[10];

    
     #If post paid set deposit to 0
     if (defined($line->[9]) && $line->[9] == 1) {
  	   $users_info{DEPOSIT}{$line->[0]} = 0;
  	  } 
  	 else {
  	   $users_info{DEPOSIT}{$line->[0]} = $line->[8];
  	  }

 	   $users_info{BILL_ID}{$line->[0]} = $line->[7];  	 
 	 	
  	 push @clients_lst, $line->[1];
   }
 
  $self->{USERS_IPS}     = \%ips;
  $self->{USERS_INFO}    = \%users_info;
  $self->{SESSIONS_ID}   = \%session_ids;
  $self->{INTERIM_TIME}  = \%interim_times;
  
  return $self;
}

#**********************************************************
# status
#**********************************************************
sub user_status {
 my $self = shift;
 my ($DATA) = @_;

 my $SESSION_START = 'now()';

 my $sql = "INSERT INTO dv_calls
   (status, 
    user_name, 
    started, 
    lupdated, 
    nas_port_id, 
    acct_session_id, 
    framed_ip_address, 
    CID, 
    CONNECT_INFO, 
    nas_id
)
    values (
    '$DATA->{ACCT_STATUS_TYPE}', 
    \"$DATA->{USER_NAME}\", 
    $SESSION_START, 
    UNIX_TIMESTAMP(), 
    '$DATA->{NAS_PORT}', 
    \"$DATA->{ACCT_SESSION_ID}\",
     INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'), 
    '$DATA->{CALLING_STATION_ID}', 
    '$DATA->{CONNECT_INFO}', 
    '$DATA->{NAS_ID}' );";


  $self->query($db, "$sql", 'do');

	
 return $self;
}

sub traffic_agregate_clean {
  my $self = shift;
  delete $self->{AGREGATE_USERS};
  delete $self->{INTERIM};
  delete $self->{IN};
}


#**********************************************************
# traffic_agregate_users
# Get Data and agregate it by users
#**********************************************************
sub traffic_agregate_users {
  my $self = shift;
  my ($DATA) = @_;

  my $users_ips=$self->{USERS_IPS};
  my $y = 0;
 
  if (defined($users_ips->{$DATA->{SRC_IP}})) {
 	  push @{ $self->{AGREGATE_USERS}{$users_ips->{$DATA->{SRC_IP}}}{OUT} }, { %$DATA };
 	  $DATA->{UID}=$users_ips->{$DATA->{SRC_IP}};
 		$y++;
   }

  if (defined($users_ips->{$DATA->{DST_IP}})) {
    push @{ $self->{AGREGATE_USERS}{$users_ips->{$DATA->{DST_IP}}}{IN} }, { %$DATA };
    $DATA->{UID}=$users_ips->{$DATA->{DST_IP}};
	  $y++;
   }
  #Unknow Ips
  elsif ($y < 1) {
  	$DATA->{UID}=0;
  	$self->{INTERIM}{$DATA->{UID}}{OUT}+=$DATA->{SIZE};
    push @{ $self->{IN} }, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";	
   }
  
  $self->{TRAFFIC_ROWS}++;

  #Make user detalization
  if ($DATA->{UID} > 0) {
  	  $self->traffic_add({ 
        SRC_IP   => $DATA->{SRC_IP}, 
        DST_IP   => $DATA->{DST_IP},
        SRC_PORT => 0,
        DST_PORT => 0,
        PROTOCOL => 0,
        SIZE     => $DATA->{SIZE},
        NAS_ID   => 0,
        UID      => $DATA->{UID}
      });
   }

  return $self;
}


#**********************************************************
#
#**********************************************************
sub traffic_agregate_nets {
  my $self = shift;
  my ($DATA) = @_;

  my $AGREGATE_USERS  = $self->{AGREGATE_USERS}; 
  my $ips       = $self->{USERS_IPS};
  my $user_info = $self->{USERS_INFO};

  require Dv;
  Dv->import();
  my $Dv = Dv->new($db, undef, $CONF);

  


  #while(my ($uid, $data_hash)= each (%$AGREGATE_USERS)) {
  #Get user and session TP
  while (my ($uid, $session_tp) = each ( %{ $user_info->{TPS} } )) {

    my $TP_ID = 0;
    my $user = $Dv->info($uid);

    if ($Dv->{TOTAL} > 0) {
    	$TP_ID = $user->{TP_ID} || 0;
      $self->{USERS_INFO}->{TPS}->{$uid}=$TP_ID;
     }
    
    
    my ($remaining_time, $ret_attr);
    if (! defined( $tp_interval{$TP_ID} )) {
      ($user->{TIME_INTERVALS},
       $user->{INTERVAL_TIME_TARIF},
       $user->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($TP_ID);

      ($remaining_time, $ret_attr) = $Billing->remaining_time(0, {
          TIME_INTERVALS      => $user->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $user->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $user->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $user->{SESSION_START},
          DAY_BEGIN           => $user->{DAY_BEGIN},
          DAY_OF_WEEK         => $user->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $user->{DAY_OF_YEAR},
          REDUCTION           => $user->{REDUCTION},
          POSTPAID            => 1 
         });

       #$tp_interval{$TP_ID} = (defined($ret_attr->{TT}) && $ret_attr->{TT} > 0) ? $ret_attr->{TT} :  0;
       
       $tp_interval{$TP_ID} = ($ret_attr->{FIRST_INTERVAL}) ? $ret_attr->{FIRST_INTERVAL} :  0;
       $intervals{$tp_interval{$TP_ID}}{TIME_TARIFF} = ($ret_attr->{TIME_PRICE}) ? $ret_attr->{TIME_PRICE} :  0;
     }

  print "\nUID: $uid\n####TP $TP_ID Interval: $tp_interval{$TP_ID}  ####\n" if ($self->{debug}); 


    if (! defined(  $intervals{$tp_interval{$TP_ID}}{ZONES} )) {
    	$self->get_zone({ TP_INTERVAL => $tp_interval{$TP_ID} });
     }

   my $data_hash;
   
   #Get agrigation data
   if (defined($AGREGATE_USERS->{$uid})) {
     $data_hash = $AGREGATE_USERS->{$uid};
    }
   # Go to next user
   else {
   	 next;
    }

   my %zones;

   @zoneids = @{ $intervals{$tp_interval{$TP_ID}}{ZONEIDS} };
   %zones   = %{ $intervals{$tp_interval{$TP_ID}}{ZONES} };
    
    if (defined($data_hash->{OUT})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{OUT};
      
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
   	    #print "------ < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
  	    if ( $#zoneids >= 0 ) {
  	     
  	      foreach my $zid (@zoneids) {
    	      if (ip_in_zone($DATA->{DST_IP}, $DATA->{DST_PORT}, $zid, \%zones)) {
		          $self->{INTERIM}{$DATA->{SRC_IP}}{"$zid"}{OUT} += $DATA->{SIZE};
	  	        print " $zid ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceOut}\n" if ($self->{debug});;
		          last;
		         }
	         }
         
         }
	      else {
	    	  print " < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{SRC_IP}}{"0"}{OUT} += $DATA->{SIZE};
	       }
      } 
    }

    if (defined($data_hash->{IN})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{IN};
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
  	    #print "!!------ < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
  	    if ($#zoneids >= 0) {
 	        foreach my $zid (@zoneids) {
 		        if (ip_in_zone($DATA->{SRC_IP}, $DATA->{SRC_PORT}, $zid, \%zones)) {
	    	      $self->{INTERIM}{$DATA->{DST_IP}}{"$zid"}{IN} += $DATA->{SIZE};
    		      print " $zid ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT} <- ". int2ip($DATA->{SRC_IP})  .":$DATA->{SRC_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceIn}\n" if ($self->{debug});
  		        last;
		         }
	         }
         }
	      else {
	    	  print " > $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{DST_IP}}{"0"}{IN} += $DATA->{SIZE};
	       }
       }
     }

}

}

#**********************************************************
#
#**********************************************************
sub get_interval_params {
	my $self = shift;





	return \%intervals, \%tp_interval;
}

#**********************************************************
# Get zones from db
#**********************************************************
sub get_zone {
	my $self = shift;
	my ($attr)=@_;


	my $zoneid  = 0;
	my %zones   = ();
	my @zoneids = ();

  my $tariff  = $attr->{TP_INTERVAL} || 0;
 
  require Tariffs;
  Tariffs->import();
  my $tariffs = Tariffs->new($db, $admin, $CONF);
  my $list = $tariffs->tt_list({ TI_ID => $tariff });

  foreach my $line (@$list) {
 	    #$speeds{$line->[0]}{IN}="$line->[4]";
 	    #$speeds{$line->[0]}{OUT}="$line->[5]";
      $zoneid=$line->[0];

      $zones{$zoneid}{PriceIn}=$line->[1]+0;
      $zones{$zoneid}{PriceOut}=$line->[2]+0;
      $zones{$zoneid}{PREPAID_TSUM}=$line->[3]+0;

  	  my $ip_list="$line->[7]";
  	  #Make ip hash
      # !10.10.0.0/24:3400
      # [Negative][IP][/NETMASK][:PORT]
      my @ip_list_array = split(/\n|;/, $ip_list);
      
      push @zoneids, $zoneid;

      my $i = 0;      

      foreach my $ip_full (@ip_list_array) {
   	    if ($ip_full =~ /([!]{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\d{1,2})(:{0,1})(\S{0,100})/ ) {
   	    	my $NEG      = $1 || ''; 
   	    	my $IP       = unpack("N", pack("C4", split( /\./, $2))); 
   	    	my $NETMASK  = (length($4) < 3) ? unpack "N", pack("B*",  ( "1" x $4 . "0" x (32 - $4) )) : unpack("N", pack("C4", split( /\./, "$4")));
   	    	
   	      print "REG $i ID: $zoneid NEGATIVE: $NEG IP: ".  int2ip($IP). " MASK: ". int2ip($NETMASK) ." Ports: $6\n" if ($self->{debug});

  	      $zones{$zoneid}{A}[$i]{IP}   = $IP;
	        $zones{$zoneid}{A}[$i]{Mask} = $NETMASK;
	        $zones{$zoneid}{A}[$i]{Neg}  = $NEG;
        
	        #Get ports
	        @{$zones{$zoneid}{A}[$i]{'Ports'}} = ();
          if ($6 ne '')	{      	
	      	  my @PORTS_ARRAY = split(/,/, $6);
	      	  foreach my $port (@PORTS_ARRAY) {
	      	    push @{$zones{$zoneid}{A}[$i]{Ports}}, $port;
    	      	#while (my $ref2=$sth2->fetchrow_hashref()) {
	            #  if ($DEBUG) { print "$ref2->{'PortNum'} "; }
	            #  push @{$zones{$zoneid}{A}[$i]{Ports}}, $ref2->{'PortNum'};
	            #}
             }
           }
          $i++;
   	     }

        
        
       }
 	 }

   @{$intervals{$tariff}{ZONEIDS}}=@zoneids;
   %{$intervals{$tariff}{ZONES}}=%zones;

   $self->{ZONES_IDS}=$intervals{$tariff}{ZONEIDS};
   $self->{ZONES}=$intervals{$tariff}{ZONES};

print " Tariff Interval: $tariff\n".
   " Zone Ids:". @{$intervals{$tariff}{ZONEIDS}}."\n".
   " Zones:". %{$intervals{$tariff}{ZONES}}."\n" if ($self->{debug}); 

  return $self;
}





#**********************************************************
# ii?aaaeyao i?eiaaea?iinou aa?ana ciia, ciiu caaaiu NOIA?-IOIA?-oyoai %zones
#**********************************************************
sub ip_in_zone($$$) {
    my $self;
    my ($ip_num, 
        $port, 
        $zoneid,
        $zone_data) = @_;
    
    # ecia?aeuii n?eoaai, ?oi aa?an a ciio ia iiiaaaao
    my $res = 0;
    # debug
    my %zones = %$zone_data;

    if ($self->{debug}) { print "--- CALL ip_in_zone($ip_num, $port, $zoneid) -> \n"; }
    # eaai ii nieneo aa?ania ciiu
    for (my $i=0; $i<=$#{$zones{$zoneid}{A}}; $i++) {
	     
	     my $adr_hash = \%{ $zones{$zoneid}{A}[$i] };
       
       my $a_ip  = $$adr_hash{'IP'}; 
       my $a_msk = $$adr_hash{'Mask'}; 
       my $a_neg = $$adr_hash{'Neg'}; 
       my $a_ports_ref = \@{ $$adr_hash{'Ports'} };
       
       #print "AAAAAAAA:" . @$a_ports_ref . "\n";
       
       # anee aa?an iiiaaaao a iianaou
       if ( (( $a_ip & $a_msk) == ($ip_num & $a_msk)) && # aa?an niaiaaaao
              (is_exist($a_ports_ref, $port)) ) {       # E ii?o niaiaaaao

          #print ">>". int2ip($a_ip). " & $a_msk / ". int2ip($ip_num) ." $zoneid / $res\n";
	        if ($a_neg) { # anee onoaiiaeai aeo aua?anuaaiey aa?ana
		        $res = 0; # oi aua?anuaaai iaeaaiiue aa?an ec ciiu
	         } 
	        else {
		        $res = 1;
            #print ">>". int2ip($a_ip). " & $a_msk / ". int2ip($ip_num) ." $zoneid / $res\n";
		        next; #next
	         }
	      }
    }
    
    #if ($self->{debug}) { print "IP is " . ($res ? "" : "not ") . "in zone $zoneid\n";  }
    return $res;									  												      
}



#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_add_user {
  my $self = shift;
  my ($DATA) = @_;
 
  my $start = (! $DATA->{START}) ? 'now()':  "'$DATA->{START}'";
  my $stop  = (! $DATA->{STOP}) ?  0 : "'$DATA->{STOP}'";
 
 
  if ($DATA->{INBYTE} + $DATA->{OUTBYTE} > 0) {

   $self->query($db, "insert into ipn_log (
         uid,
         start,
         stop,
         traffic_class,
         traffic_in,
         traffic_out,
         nas_id,
         ip,
         interval_id,
         sum,
         session_id
       )
     VALUES (
       '$DATA->{UID}',
        $start,
        $stop,
       '$DATA->{TARFFIC_CLASS}',
       '$DATA->{INBYTE}',
       '$DATA->{OUTBYTE}',
       '$DATA->{NAS_ID}',
       '$DATA->{IP}',
       '$DATA->{INTERVAL}',
       '$DATA->{SUM}',
       '$DATA->{SESSION_ID}'
      );", 'do');
   }


  if ($self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}}) {
  	#Take money from bill
    if ($DATA->{SUM} > 0) {
   	  $self->query($db, "UPDATE bills SET deposit=deposit-$DATA->{SUM} WHERE id='$self->{USERS_INFO}->{BILL_ID}->{$DATA->{UID}}';", 'do');
     }
    #If negative deposit hangup
    if ($self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}} - $DATA->{SUM} < 0) {
      $self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}}=$self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}} - $DATA->{SUM};
     }
   }

  return $self;
}



#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "  UPDATE ipn_log SET
     sum='$attr->{SUM}'
   WHERE 
         uid='$attr->{UID}' and 
         start='$attr->{START}' and 
         traffic_class='$attr->{TRAFFIC_CLASS}' and 
         traffic_in='$attr->{IN}' and 
         traffic_out='$attr->{OUT}' and
         session_id='$attr->{SESSION_ID}';", 'do');

  return $self;
}

#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc_bill {
  my $self = shift;
  my ($attr) = @_;
 
  if ($attr->{SUM} > 0) {
   $self->query($db, "UPDATE bills SET
      deposit=deposit - $attr->{SUM}
    WHERE 
    id='$attr->{BILL_ID}';", 'do');
   }

  return $self;
}


#**********************************************************
# traffic_user_get
# Get used traffic from DB
#**********************************************************
sub traffic_user_get {
  my $self = shift;
  my ($attr) = @_;

  my $uid        = $attr->{UID};
  my $traffic_id = $attr->{TRAFFIC_ID} || 0;
  my $from       = $attr->{FROM} || '';
  my %result = ();


  if ($attr->{DATE_TIME}) {
  	$WHERE = "start>=$attr->{DATE_TIME}";
   }
  elsif ($attr->{INTERVAL}) {
  	my ($from, $to)=split(/\//, $attr->{INTERVAL});
  	$from = ($from eq '0000-00-00') ? 'DATE_FORMAT(curdate(), \'%Y-%m\')' : "'$from'";
  	$WHERE = "( DATE_FORMAT(start, '%Y-%m')>=$from AND start<'$to') ";
   }
  elsif ($attr->{ACTIVATE}) {
  	$WHERE = "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{ACTIVATE}'";
   }
  else {
    $WHERE = "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";
   }

  #$self->{debug}=1;
  $self->query($db, "SELECT traffic_class, sum(traffic_in) / $CONF->{MB_SIZE}, sum(traffic_out) / $CONF->{MB_SIZE}  from ipn_log
        WHERE uid='$uid'
        and $WHERE
        GROUP BY uid, traffic_class;");
  
 
  foreach my $line (@{ $self->{list} }) {
    #Trffic class
  	$result{$line->[0]}{TRAFFIC_IN}=$line->[1];
  	$result{$line->[0]}{TRAFFIC_OUT}=$line->[2];
   }

  return \%result;
}
 
 
 
#**********************************************************
# traffic_add
#**********************************************************
sub traffic_add {
  my $self = shift;
  my ($DATA) = @_;

 #my $table_name = "ipn_traf_log_". $Y."_".$M;

 my $table_name = 'ipn_traf_detail';
 my $UID = $DATA->{UID} || 0;

  $self->query($db, "insert into $table_name (src_addr,
       dst_addr,
       src_port,
       dst_port,
       protocol,
       size,
       f_time,
       nas_id,
       uid)
     VALUES (
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
       '$DATA->{SRC_PORT}',
       '$DATA->{DST_PORT}',
       '$DATA->{PROTOCOL}',
       '$DATA->{SIZE}',
        now(),
        '$DATA->{NAS_ID}',
        '$UID'
      );", 'do');


# $self->query($db, "CREATE TABLE IF NOT EXISTS `$table_name`  (
#  `src_addr` int(11) unsigned NOT NULL default '0',
#  `dst_addr` int(11) unsigned NOT NULL default '0',
#  `src_port` smallint(5) unsigned NOT NULL default '0',
#  `dst_port` smallint(5) unsigned NOT NULL default '0',
#  `protocol` tinyint(3) unsigned default '0',
#  `size` bigint(20) unsigned default '0',
#  `f_time` datetime NOT NULL default '0000-00-00 00:00:00',
#  `s_time` datetime NOT NULL default '0000-00-00 00:00:00',
#  `nas_id` smallint(5) unsigned NOT NULL default 0
#  );", 'do');
#
#
#
#  $self->query($db, "insert into $table_name (src_addr,
#       dst_addr,
#       src_port,
#       dst_port,
#       protocol,
#       size,
#       f_time,
#       nas_id)
#     VALUES (
#        $DATA->{SRC_IP},
#        $DATA->{DST_IP},
#       '$DATA->{SRC_PORT}',
#       '$DATA->{DST_PORT}',
#       '$DATA->{PROTOCOL}',
#       '$DATA->{SIZE}',
#        now(),
#        '$DATA->{NAS_ID}'
#      );", 'do');

 return $self;
}



#**********************************************************
# Acct_stop
#**********************************************************
sub acct_stop {
  my $self = shift;
  my ($attr) = @_;
  my $session_id;


  if (defined($attr->{SESSION_ID})) {
  	$session_id=$attr->{SESSION_ID};
   }
  else {
    return $self;
  }
 
  my $ACCT_TERMINATE_CAUSE = (defined($attr->{ACCT_TERMINATE_CAUSE})) ? $attr->{ACCT_TERMINATE_CAUSE} : 0;

  my	$sql="select u.uid, calls.framed_ip_address, 
      calls.user_name,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id),
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit,
      calls.started,
      UNIX_TIMESTAMP()-UNIX_TIMESTAMP(calls.started),
      nas_id,
      nas_port_id
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
    WHERE u.id=calls.user_name and acct_session_id='$session_id';";

  $self->query($db, $sql);
  
  if ($self->{TOTAL} < 1){
  	 $self->{errno}=2;
  	 $self->{errstr}='ERROR_NOT_EXIST';
  	 return $self;
   }


  ($self->{UID},
   $self->{FRAMED_IP_ADDRESS},
   $self->{USER_NAME},
   $self->{ACCT_SESSION_ID},
   $self->{INPUT_OCTETS},
   $self->{OUTPUT_OCTETS},
   $self->{TP_ID},
   $self->{BILL_ID},
   $self->{DEPOSIT},
   $self->{START},
   $self->{ACCT_SESSION_TIME},
   $self->{NAS_ID},
   $self->{NAS_PORT}
  ) = @{ $self->{list}->[0] };

 
 $self->query($db, "SELECT sum(l.traffic_in), 
   sum(l.traffic_out),
   sum(l.sum),
   l.nas_id
   from ipn_log l
   WHERE session_id='$session_id'
   GROUP BY session_id  ;");  


  if ($self->{TOTAL} < 1) {
    $self->{TRAFFIC_IN}=0;
    $self->{TRAFFIC_OUT}=0;
    $self->{SUM}=0;
    $self->{NAS_ID}=0;
    $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
    return $self;
  }
  
  ($self->{TRAFFIC_IN},
   $self->{TRAFFIC_OUT},
   $self->{SUM}
  ) = @{ $self->{list}->[0] };



  $self->query($db, "INSERT INTO dv_log (uid, 
    start, 
    tp_id, 
    duration, 
    sent, 
    recv, 
    minp, 
    kb,  
    sum, 
    nas_id, 
    port_id,
    ip, 
    CID, 
    sent2, 
    recv2, 
    acct_session_id, 
    bill_id,
    terminate_cause) 
        VALUES ('$self->{UID}', '$self->{START}', '$self->{TP_ID}', 
          '$self->{ACCT_SESSION_TIME}', 
          '$self->{OUTPUT_OCTETS}', '$self->{INPUT_OCTETS}', 
          '0', '0', '$self->{SUM}', '$self->{NAS_ID}',
          '$self->{NAS_PORT}', 
          '$self->{FRAMED_IP_ADDRESS}', 
          '',
          '0', 
          '0',  
          '$self->{ACCT_SESSION_ID}', 
          '$self->{BILL_ID}',
          '$ACCT_TERMINATE_CAUSE');", 'do');

  $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');

}


#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 undef @WHERE_RULES; 

 my $table_name = "ipn_traf_log_". $Y."_".$M;

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




#$PAGE_ROWS = 10;

 $self->query($db, "SELECT 
  $lupdate,
  $size,
  INET_NTOA(src_addr),
  src_port,
  INET_NTOA(dst_addr),
  dst_port,

  protocol
  FROM $table_name
  $WHERE
  $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;");


  #

 my $list = $self->{list};

 $self->query($db, "SELECT 
  count(*),  sum(size)
  from $table_name
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };


  return $list;
}


#**********************************************************
# host_list
#**********************************************************
sub hosts_list {
  my $self = shift;
  my ($attr) = @_;
	
	
}



#**********************************************************
#
#**********************************************************
sub reports2 {
 my $self = shift;
 my ($attr) = @_;


 my $table_name = "ipn_traf_log_". $Y."_".$M;
 undef @WHERE_RULES; 

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d %H')='$attr->{HOUR}'";
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 my $list;

 $self->query($db, "SELECT INET_NTOA(dst_addr), sum(size), count(*), 
  sum(if(protocol = 0, 1, 0)),
  sum(if(protocol = 1, 1, 0))
   from $table_name
   $WHERE
   GROUP BY 1
  ORDER BY $SORT $DESC 
  LIMIT $PG, 100;");

 $list = $self->{list};


 if ($self->{TOTAL} > 0) {
   $self->query($db, "SELECT count(*),  sum(size)
     from $table_name
     $WHERE ;");

     ($self->{COUNT},
      $self->{SUM}) = @{ $self->{list}->[0] };
  }

 return $list;
}


#**********************************************************
#
#**********************************************************
sub stats {
 my $self=shift;
 my ($attr) = @_;
 
 undef @WHERE_RULES;  
 
 if ($attr->{UID}) {
     push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
  }

 if ($attr->{SESSION_ID}) {
     push @WHERE_RULES, "l.session_id='$attr->{SESSION_ID}'"; 	
  }


 if ($attr->{UID}) {
 	
 }
 
 my $GROUP = 'l.uid, l.ip, l.traffic_class';

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 $self->query($db, "SELECT u.id, min(l.start), INET_NTOA(l.ip), 
   l.traffic_class,
   tt.descr,
   sum(l.traffic_in), sum(l.traffic_out),
   sum(sum),
   l.nas_id
   from (ipn_log l)
   LEFT join  users u ON (l.uid=u.uid)
   LEFT join  trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)
   $WHERE 
   GROUP BY $GROUP
  ;");
  #

 my $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(l.traffic_in), sum(l.traffic_out)
  from  ipn_log l
  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };


  return $list;
}


#**********************************************************
#
#**********************************************************
sub reports_users {
 my $self=shift;
 my ($attr) = @_;
 
 
my $lupdate = ""; 
my $GROUP = '1';

 
 undef @WHERE_RULES;  
 if ($attr->{UID}) {
   push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
   $lupdate = " DATE_FORMAT(start, '%Y-%m-%d'), l.traffic_class, tt.descr,";
   $GROUP = '1, 2';
  }
 else {
   $lupdate = " DATE_FORMAT(start, '%Y-%m-%d'), count(DISTINCT l.uid), ";
  }

if ($attr->{SESSION_ID}) {
	push @WHERE_RULES, "session_id='$attr->{SESSION_ID}'";
}
 
 #Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d %H')='$attr->{HOUR}'";
	 $GROUP = "1, 2, 3";
	 $lupdate = "DATE_FORMAT(start, '%Y-%m-%d %H'), u.id, l.traffic_class, tt.descr, ";
 }
elsif($attr->{DATE}) {

	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";

   if ($attr->{UID}) {
   	 $GROUP = "1, 2";
     #push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
     $lupdate = " DATE_FORMAT(start, '%Y-%m-%d %H'), l.traffic_class, tt.descr,";
    }
   elsif($attr->{HOURS}) {
   	 $GROUP = "1, 3";
	   $lupdate = "DATE_FORMAT(start, '%Y-%m-%d %H'), count(DISTINCT u.id), l.traffic_class, tt.descr, ";
    }
   else {
   	 $GROUP = "1, 2, 3";
	   $lupdate = "DATE_FORMAT(start, '%Y-%m-%d'), u.id, l.traffic_class, tt.descr, ";
	  }
}
elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
 } 
else {
 	 $lupdate = "date_format(l.start, '%Y-%m'), count(DISTINCT u.id), "; 
 }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "SELECT $lupdate
   sum(l.traffic_in), sum(l.traffic_out), sum(l.sum),
   l.nas_id, l.uid
   from ipn_log l
   LEFT join  users u ON (l.uid=u.uid)
   LEFT join  trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)
   $WHERE 
   GROUP BY $GROUP
  ;");
  #

 my $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(l.traffic_in), sum(l.traffic_out)
  from  ipn_log l

  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };

  return $list;
}




#**********************************************************
#
#**********************************************************
sub reports {
 my $self = shift;
 my ($attr) = @_;

  my $table_name = "ipn_traf_log_". $Y."_".$M;

 undef @WHERE_RULES; 

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d %H')='$attr->{HOUR}'";
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


  my $list;

if (defined($attr->{HOSTS})) {

 	 $self->query($db, "SELECT INET_NTOA(src_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT INET_NTOA(dst_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_TO} = $self->{list};
 }
elsif (defined($attr->{PORTS})) {
 	 $self->query($db, "SELECT src_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT dst_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_TO} = $self->{list};
 }
else {
#$PAGE_ROWS = 10;
 $self->query($db, "SELECT   $lupdate,
   sum(if(src_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(dst_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(src_port=0 && dst_port=0, size, 0)),
   sum(size),
   count(*)
   from  $table_name
   $WHERE
   $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS;
  ;");
}

  #

 $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  suuuuuuum(size)
  from  $table_name
  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @$self->{list}->[0];


 return $list;
}



sub is_client_ip($) {
  my $self = shift;
  my $ip = shift @_;

    if ($self->{debug}) { print "--- CALL is_client_ip($ip),\t\$#clients_lst = $#clients_lst\n"; }
    if ($#clients_lst < 0) {return 0;} # nienie iono!
    foreach my $i (@clients_lst) {
	    if ($i eq $ip) { return 1; }
     }
    if ($self->{debug}) { print "         Client $ip not found in \@clients_lst\n"; }
    return 0;
}

# ii?aaaeyao iaee?ea yeaiaioa a ianneaa (iannea ii nnueea)
sub is_exist($$) {
    my ($arrayref, $elem) = @_;
    # anee nienie iono, n?eoaai, ?oi yeaiaio a iaai iiiaaaao
    if ($#{@$arrayref} == -1) { return 1; }
    
    foreach my $e (@$arrayref) {
	    if ($e eq $elem) { return 1; }
     }
    
    return 0;
}


#**********************************************************
#
#**********************************************************
sub comps_list {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "SELECT number, name, INET_NTOA(ip), cid, id FROM ipn_club_comps
  ORDER BY $SORT $DESC ;");
 
  my $list = $self->{list};
  return $list;
}

#**********************************************************
#
#**********************************************************
sub comps_add {
 my $self = shift;
 my ($attr) = @_;

  $self->query($db, "INSERT INTO ipn_club_comps (number, name, ip, cid)
  values ('$attr->{NUMBER}', '$attr->{NAME}', INET_ATON('$attr->{IP}'), '$attr->{CID}');", 'do');

}

#**********************************************************
#
#**********************************************************
sub comps_info {
 my $self = shift;
 my ($id) = @_;
 
  $self->query($db, "SELECT 
  number,
  name,
  INET_NTOA(ip),
  cid
  FROM ipn_club_comps
  WHERE id='$id';");

  ($self->{NUMBER},
   $self->{NAME},
   $self->{IP},
   $self->{CID}
   ) = @{ $self->{list}->[0] };
 
 return $self;
}

#**********************************************************
#
#**********************************************************
sub comps_change {
 my $self = shift;
 my ($attr) = @_;
 
 	my %FIELDS = (NUMBER => 'number',
 	              ID     => 'id',
	              NAME   => 'name', 
	              IP     => 'ip',
	              CID    => 'cid'); 



 	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'ipn_club_comps',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->comps_info($attr->{ID}),
		                DATA         => $attr
		              } );

 
 
}

#**********************************************************
#
#**********************************************************
sub comps_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM ipn_club_comps WHERE id='$id';");

 return $self;
}


#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub int2ip {
my $i = shift;
my (@d);
$d[0]=int($i/256/256/256);
$d[1]=int(($i-$d[0]*256*256*256)/256/256);
$d[2]=int(($i-$d[0]*256*256*256-$d[1]*256*256)/256);
$d[3]=int($i-$d[0]*256*256*256-$d[1]*256*256-$d[2]*256);
 return "$d[0].$d[1].$d[2].$d[3]";
}


#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub log_del {
	my $self = shift;
	my ($attr) = @_;

 if ($attr->{UID}) {
   push @WHERE_RULES, "ipn_log.uid='$attr->{UID}'";
  }

 if ($attr->{SESSION_ID}) {
   push @WHERE_RULES, "ipn_log.session_id='$attr->{SESSION_ID}'";
  }

 my $WHERE = "WHERE " . join(' and ', @WHERE_RULES);
 $self->query($db, "DELETE FROM ipn_log WHERE $WHERE;");

 return $self;
}

#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub prepaid_rest {
	my $self = shift;
	my ($attr) = @_;
  my $info = $attr->{INFO};

 my $octets_direction = "l.traffic_in + l.traffic_out";
 
 
 #Recv
 if ($info->[0]->[6] == 1) {
   $octets_direction = "l.traffic_in";
  }
 #sent
 elsif ($info->[0]->[6] == 2) {
   $octets_direction = "l.traffic_out";
  }


 $self->query($db, "SELECT l.traffic_class, (sum($octets_direction)) / $CONF->{MB_SIZE}
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and DATE_FORMAT(start, '%Y-%m-%d')>='$info->[0]->[3]'
   GROUP BY l.traffic_class, l.uid ;");
  
 my %traffic = ();
 foreach my $line (@{ $self->{list} }) {
    $traffic{$line->[0]}=$line->[1];
  }

  $self->{TRAFFIC}=\%traffic;

  return $info;
}

#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub recalculate {
  my $self = shift;
	my ($attr) = @_;

  my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  #push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";


  $self->query($db, "SELECT start,
   traffic_class,
   traffic_in,
   traffic_out,
   nas_id,
   INET_NTOA(ip),
   interval_id,
   sum,
   session_id
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and 
     (
      DATE_FORMAT(start, '%Y-%m-%d')>='$from'
      and DATE_FORMAT(start, '%Y-%m-%d')<='$to'
      )
   ;");



  return $self;	
}

1


