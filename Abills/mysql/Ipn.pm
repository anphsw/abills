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
@EXPORT = qw();

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

  if (! defined($CONF->{KBYTE_SIZE})) {
  	 $CONF->{KBYTE_SIZE}=1024;
  	}
  

  $Billing = Billing->new($db, $CONF);
  return $self;
}



#**********************************************************
# user_ips
#**********************************************************
sub user_ips {
  my $self = shift;
  my ($DATA) = @_;

  
  #$self->query($db, "SELECT uid, ip  FROM dv_main WHERE ip>0;");
  $self->query($db, "SELECT u.uid, calls.framed_ip_address, calls.user_name, 
    calls.acct_session_id,
    calls.acct_input_octets,
    calls.acct_output_octets,
    calls.tp_id
    
    FROM dv_calls calls, users u
   WHERE u.id=calls.user_name;");

  my $list = $self->{list};
  my %session_ids = ();
  my %users_info  = ();
  
  $ips{0}='0';
  
  
  $self->{0}{IN}=0;
 	$self->{0}{OUT}=0;
  #$self->{INTERIM}{0}{IN}=0;
 	#$self->{INTERIM}{0}{OUT}=0;



  foreach my $line (@$list) {
  	 $ips{$line->[1]}         = $line->[0];

  	 $session_ids{$line->[1]} = $line->[3];
  	 $self->{$line->[1]}{IN}  = $line->[4];
  	 $self->{$line->[1]}{OUT} = $line->[5];

     
  	 $users_info{TPS}{$line->[0]} = $line->[6];
   	 $users_info{LOGINS}{$line->[0]} = $line->[2];
  	 
   	 #$self->{INTERIM}{$line->[1]}{IN}  = 0;
  	 #$self->{INTERIM}{$line->[1]}{OUT} = 0;
  	 	
  	 push @clients_lst, $line->[1];
   }
 
  $self->{USERS_IPS}   = \%ips;
  $self->{SESSIONS_IPS}= \%session_ids;
  $self->{USERS_INFO}  = \%users_info;
  

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
    nas_id)
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

$self->{debug}=1;
  $self->query($db, "$sql", 'do');

	
 return $self;
}


#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_agregate {
  my $self = shift;
  my ($DATA) = @_;
 
  my $ips=$self->{USERS_IPS};
  my $y = 0;

  if (defined($ips->{$DATA->{SRC_IP}})) {
    $DATA->{UID} = $ips->{$DATA->{SRC_IP}};
 	 	$self->{$DATA->{SRC_IP}}{OUT}+=$DATA->{SIZE};
 		$self->{INTERIM}{$DATA->{SRC_IP}}{OUT}+=$DATA->{SIZE};
 		$y++;
   }
#  else {
#  	$DATA->{UID}=0;
#  	$self->{$DATA->{UID}}{IN}+=$DATA->{SIZE};
#    push @{$self->{IN}}, "$DATA->{SRC_IP}/$DATA->{DST_IP}";	
#   }

  if (defined($ips->{$DATA->{DST_IP}})) {
    $DATA->{UID} = $ips->{$DATA->{DST_IP}};
	  $self->{$DATA->{DST_IP}}{IN}+=$DATA->{SIZE};
  	$self->{INTERIM}{$DATA->{DST_IP}}{IN}+=$DATA->{SIZE};
	  $y++;
   }
  elsif ($y < 1) {
  	$DATA->{UID}=0;
  	$self->{INTERIM}{$DATA->{UID}}{OUT}+=$DATA->{SIZE};
    push @{$self->{IN}}, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";	

    #push @{$self->{OUT}}, "$DATA->{DST_IP}/$DATA->{DST_IP}";
   }


  return $self;
}


#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_agregate_users {
  my $self = shift;
  my ($DATA) = @_;
 
  my $ips=$self->{USERS_IPS};
  my $y = 0;
 

  if (defined($ips->{$DATA->{SRC_IP}})) {
    #$DATA->{UID} = $ips->{$DATA->{SRC_IP}};
 	 	#$self->{$DATA->{SRC_IP}}{OUT}+=$DATA->{SIZE};
 	  push @{ $self->{AGREGATE_USERS}{$ips->{$DATA->{SRC_IP}}}{OUT} }, { %$DATA };
 		$y++;
   }
#  else {
#  	$DATA->{UID}=0;
#  	$self->{$DATA->{UID}}{IN}+=$DATA->{SIZE};
#    push @{$self->{IN}}, "$DATA->{SRC_IP}/$DATA->{DST_IP}";	
#   }

  if (defined($ips->{$DATA->{DST_IP}})) {
    #$DATA->{UID} = $ips->{$DATA->{DST_IP}};
	  #$self->{$DATA->{DST_IP}}{IN}+=$DATA->{SIZE};
  	#$self->{INTERIM}{$DATA->{DST_IP}}{IN}+=$DATA->{SIZE};
    push @{ $self->{AGREGATE_USERS}{$ips->{$DATA->{DST_IP}}}{IN} }, { %$DATA };
	  $y++;
   }
  elsif ($y < 1) {
  	$DATA->{UID}=0;
  	$self->{INTERIM}{$DATA->{UID}}{OUT}+=$DATA->{SIZE};
    push @{$self->{IN}}, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";	

    #push @{$self->{OUT}}, "$DATA->{DST_IP}/$DATA->{DST_IP}";
   }


  return $self;
}



sub traffic_agregate_nets {
  my $self = shift;
  my ($DATA) = @_;

  my $AGREGATE_USERS  = $self->{AGREGATE_USERS}; 
  my $ips       = $self->{USERS_IPS};
  my $user_info = $self->{USERS_INFO};

  my %tp_interval = ();

  require Dv;
  Dv->import();
  my $Dv = Dv->new($db, undef, $CONF);



  while(my ($uid, $data_hash)= each (%$AGREGATE_USERS)) {

    my $user = $Dv->info($uid);

    #$tp_interval{TP} = $user_info->{TPS}{$uid};
    #($user_info->{TIME_INTERVALS}, 
    # $user_info->{INTERVAL_TIME_TARIF}, 
    # $user_info->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($tp_interval{TP});
    
    #print "$tp_interval{TP} --\n";
    #$tp_interval{}=37;
    my $TP_ID = $user->{TP_ID} || 0;
    
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
  
  
       $tp_interval{$TP_ID} = (defined($ret_attr->{TT}) && $ret_attr->{TT} > 0) ? $ret_attr->{TT} :  0;
      }

    
  print "\nUID: $uid\n####TP $TP_ID Interval: $tp_interval{$TP_ID}  ####\n" if ($self->{debug}); 
    
    if (! defined(  $intervals{$tp_interval{$TP_ID}} )) {
    	$self->get_zone({ TP_INTERVAL => $tp_interval{$TP_ID} });
     }

   my %zones;
   @zoneids = @{ $intervals{$tp_interval{$TP_ID}}{ZONEIDS} };
   %zones   = %{ $intervals{$tp_interval{$TP_ID}}{ZONES} };
    
    
    
    if (defined($data_hash->{OUT})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{OUT};
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
  	    if ( $#zoneids >= 0 ) {
  	      foreach my $zid (@zoneids) {

    	      if (ip_in_zone($DATA->{DST_IP}, $DATA->{DST_PORT}, $zid, \%zones)) {
		          # в эту зону попал, плюсуем трафик и заканчиваем проверку
              #$self->{$DATA->{SRC_IP}}{"$zid"}{IN} = 0 if (! defined($self->{$DATA->{SRC_IP}}{"$zid"}{IN}));
		          $self->{INTERIM}{$DATA->{SRC_IP}}{"$zid"}{OUT} += $DATA->{SIZE};
	  	      print " $zid ". int2ip($DATA->{SRC_IP}) ." -> ". int2ip($DATA->{DST_IP}) ."  $DATA->{SIZE}\n" if ($self->{debug});;
		          last;
		         }

	         }
         
         }
	      else {
	    	print " < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) ." -> ". int2ip($DATA->{DST_IP}) ."\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{SRC_IP}}{"0"}{OUT} += $DATA->{SIZE};
	       }
      } 
    }

#	    # прогоняем адрес по зонам и смотрим, куда попадает
    if (defined($data_hash->{IN})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{IN};
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
  	    if ($#zoneids >= 0) {
 	        foreach my $zid (@zoneids) {
 		        if (ip_in_zone($DATA->{SRC_IP}, $DATA->{SRC_PORT}, $zid, \%zones)) {
		          # в эту зону попал, плюсуем трафик и заканчиваем проверку
	    	      $self->{INTERIM}{$DATA->{DST_IP}}{"$zid"}{IN} += $DATA->{SIZE};
    		      print " $zid ". int2ip($DATA->{DST_IP}) ." <- ". int2ip($DATA->{SRC_IP})  ."  $DATA->{SIZE} \n" if ($self->{debug});
  		        last;
		         }
	         }
         }
	      else {
	    	  print " > $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) ." -> ". int2ip($DATA->{DST_IP}) ."\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{DST_IP}}{"0"}{IN} += $DATA->{SIZE};
	       }
       }
     }

}


}




#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_agregate2 {
  my $self = shift;
  my ($DATA) = @_;
 
  my $ips=$self->{USERS_IPS};
  my $y = 0;

	  if ($self->is_client_ip($DATA->{SRC_IP})) { # это исходящий трафик клиента
      if ($self->{debug}) { print "         It is outbound\n"; }
	    # прогоняем адрес по зонам и смотрим, куда попадает
	    
	    if ( $#zoneids >= 0 ) {
	      foreach my $zid (@zoneids) {
  	      if (ip_in_zone($DATA->{DST_IP}, $DATA->{DST_PORT}, $zid)) {
		        # в эту зону попал, плюсуем трафик и заканчиваем проверку

            #$self->{$DATA->{SRC_IP}}{"$zid"}{IN} = 0 if (! defined($self->{$DATA->{SRC_IP}}{"$zid"}{IN}));
		        $self->{INTERIM}{$DATA->{SRC_IP}}{"$zid"}{OUT} = $DATA->{SIZE};
	  	      #print " $zid $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) ." -> ". int2ip($DATA->{DST_IP}) ."\n";
    
		        last;
		       }
	       }
       }
	    else {
	    	 $self->{INTERIM}{$DATA->{SRC_IP}}{"0"}{OUT} = $DATA->{SIZE};
	     }
	    $y++;
	   }

	  if ($self->is_client_ip($DATA->{DST_IP})) { # это входящий трафик клиента
      if ($self->{debug}) { print "         It is inbound\n"; }

	    # прогоняем адрес по зонам и смотрим, куда попадает
	    if ($#zoneids >= 0) {
	      foreach my $zid (@zoneids) {
 		      if (ip_in_zone($DATA->{SRC_IP}, $DATA->{SRC_PORT}, $zid)) {
		        # в эту зону попал, плюсуем трафик и заканчиваем проверку
	  	      $self->{INTERIM}{$DATA->{DST_IP}}{"$zid"}{IN} += $DATA->{SIZE};
		      
  		      #print " $zid $DATA->{SIZE} ". int2ip($DATA->{DST_IP}) ." -> ". int2ip($DATA->{SRC_IP}) ."\n";
		      
  		      last;
		       }
	       }
       }
	    else {
	    	 $self->{INTERIM}{$DATA->{DST_IP}}{"0"}{IN} = $DATA->{SIZE};
	     }

	   
	   }
   elsif ($y < 1) {
  	$DATA->{UID}=0;
  	#$self->{INTERIM}{$DATA->{UID}}{OUT}+=$DATA->{SIZE};
    push @{$self->{IN}}, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";	

    #push @{$self->{OUT}}, "$DATA->{DST_IP}/$DATA->{DST_IP}";
   }

  
}

#**********************************************************
#
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
  my $tariffs = Tariffs->new($db, $admin);
  my $list = $tariffs->tt_list({ TI_ID => $tariff });

  foreach my $line (@$list) {
 	    #$speeds{$line->[0]}{IN}="$line->[4]";
 	    #$speeds{$line->[0]}{OUT}="$line->[5]";
      $zoneid=$line->[0];

      $zones{$zoneid}{PriceIn}=$line->[1]+0;
      $zones{$zoneid}{PriceOut}=$line->[2]+0;

  	  my $ip_list="$line->[7]";
  	  #Make ip hach
      # !10.10.0.0/24:3400
      # [Negative][IP][/NETMASK][:PORT]
      my @ip_list_array = split(/\n|;/, $ip_list);
      
      push @zoneids, $zoneid;

      my $i = 0;      

      foreach my $ip_full (@ip_list_array) {
   	    if ($ip_full =~ /([!]{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\d{1,2})/ ) {
   	    	my $NEG      = $1 || ''; 
   	    	my $IP       = unpack("N", pack("C4", split( /\./, $2))); 
   	    	my $NETMASK  = (length($4) < 3) ? unpack "N", pack("B*",  ( "1" x $4 . "0" x (32 - $4) )) : unpack("N", pack("C4", split( /\./, "$4")));
   	    	
   	    print "REG ID: $zoneid NEGATIVE: $NEG IP: ".  int2ip($IP). " MASK: ". int2ip($NETMASK) ."\n" if ($self->{debug});

  	      $zones{$zoneid}{A}[$i]{IP}   = $IP;
	        $zones{$zoneid}{A}[$i]{Mask} = $NETMASK;
	        $zones{$zoneid}{A}[$i]{Neg}  = $NEG;
	        
    	    #my $sth2 = $dbh->prepare("SELECT PortNum FROM Port WHERE Address_ID=$ref1->{'ID'}");
    	    #$sth2->execute();
	        
	        @{$zones{$zoneid}{A}[$i]{'Ports'}} = ();
	      	
	      	#while (my $ref2=$sth2->fetchrow_hashref()) {
	        #  if ($DEBUG) { print "$ref2->{'PortNum'} "; }
	        #  push @{$zones{$zoneid}{A}[$i]{Ports}}, $ref2->{'PortNum'};
	        #}
   	     }

        
        $i++;
       }
 	 }

   @{$intervals{$tariff}{ZONEIDS}}=@zoneids;
   %{$intervals{$tariff}{ZONES}}=%zones;


print " Tariff Interval: $tariff\n".
   " Zone Ids:". @{$intervals{$tariff}{ZONEIDS}}."\n".
   " Zones:". %{$intervals{$tariff}{ZONES}}."\n" if ($self->{debug}); 

}





#**********************************************************
# определяет принадлежность адреса зоне, зоны заданы СУПЕР-ПУПЕР-хэшем %zones
#**********************************************************
sub ip_in_zone($$$) {
    my $self;
    my ($ip_num, 
        $port, 
        $zoneid,
        $zone_data) = @_;
    
    # переводим адрес в число

    # изначально считаем, что адрес в зону не попадает
    my $res = 0;
    # debug
    my %zones = %$zone_data;

    if ($self->{debug}) { print "--- CALL ip_in_zone($ip_num, $port, $zoneid) -> \n"; }
    # идем по списку адресов зоны
    for (my $i=0; $i<=$#{$zones{$zoneid}{A}}; $i++) {
	     
	     my $adr_hash = \%{$zones{$zoneid}{A}[$i]};
       
       my $a_ip = $$adr_hash{'IP'}; 
       my $a_msk = $$adr_hash{'Mask'}; 
       my $a_neg = $$adr_hash{'Neg'}; 
       my $a_ports_ref = \@{$$adr_hash{'Ports'}};
       
       
       # если адрес попадает в подсеть
       if ( (($a_ip & $a_msk) == ($ip_num & $a_msk)) && # адрес совпадает
              (is_exist($a_ports_ref, $port)) ) {       # И порт совпадает

          #print ">>". int2ip($a_ip). " & $a_msk / ". int2ip($ip_num) ." $zoneid / $res\n";
	        if ($a_neg) { # если установлен бит выбрасывания адреса
		        $res = 0; # то выбрасываем найденный адрес из зоны
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
  my $stop= 0;
 
  $self->query($db, "insert into ipn_log (
         uid,
         start,
         stop,
         traffic_class,
         traffic_in,
         traffic_out,
         nas_id
       )
     VALUES (
       '$DATA->{UID}',
        $start,
        $stop,
       '$DATA->{TARFFIC_CLASS}',
       '$DATA->{INBYTE}',
       '$DATA->{OUTBYTE}',
       '$DATA->{NAS_ID}'
      );", 'do');


  return $self;
}


#**********************************************************
# traffic_add
#**********************************************************
sub traffic_add {
  my $self = shift;
  my ($DATA) = @_;

 my $table_name = "ipn_traf_log_". $Y."_".$M;

 $self->query($db, "CREATE TABLE IF NOT EXISTS `$table_name`  (
  `src_addr` int(11) unsigned NOT NULL default '0',
  `dst_addr` int(11) unsigned NOT NULL default '0',
  `src_port` smallint(5) unsigned NOT NULL default '0',
  `dst_port` smallint(5) unsigned NOT NULL default '0',
  `protocol` tinyint(3) unsigned default '0',
  `size` bigint(20) unsigned default '0',
  `f_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `s_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(5) unsigned NOT NULL default 0
  );", 'do');



  $self->query($db, "insert into $table_name (src_addr,
       dst_addr,
       src_port,
       dst_port,
       protocol,
       size,
       f_time,
       nas_id)
     VALUES (
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
       '$DATA->{SRC_PORT}',
       '$DATA->{DST_PORT}',
       '$DATA->{PROTOCOL}',
       '$DATA->{SIZE}',
        now(),
        '$DATA->{NAS_ID}'
      );", 'do');

 return $self;
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

 $self->{debug}=1;
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

  my $a_ref = $self->{list}->[0];
  ($self->{COUNT},
   $self->{SUM}) = @$a_ref;


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
 $self->{debug}=1;
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


 $self->query($db, "SELECT count(*),  sum(size)
  from $table_name
  $WHERE
   ;");

  my $a_ref = $self->{list}->[0];
  ($self->{COUNT},
   $self->{SUM}) = @$a_ref;


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
  count(*),  sum(size)
  from  $table_name
  $WHERE
  ;");

  my $a_ref = $self->{list}->[0];
  ($self->{COUNT},
   $self->{SUM}) = @$a_ref;


 return $list;
}



sub is_client_ip($) {
  my $self = shift;
  my $ip = shift @_;

    if ($self->{debug}) { print "--- CALL is_client_ip($ip),\t\$#clients_lst = $#clients_lst\n"; }
    if ($#clients_lst < 0) {return 0;} # список пуст!
    foreach my $i (@clients_lst) {
	    if ($i eq $ip) { return 1; }
     }
    if ($self->{debug}) { print "         Client $ip not found in \@clients_lst\n"; }
    return 0;
}

# определяет наличие элемента в массиве (массив по ссылке)
sub is_exist($$)
{
    (my $arrayref, my $elem) = @_;
    # если список пуст, считаем, что элемент в него попадает
    if ($#{@$arrayref} == -1) { return 1; }
    
    foreach my $e (@$arrayref) {
	    if ($e eq $elem) { return 1; }
     }
    
    return 0;
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


1
