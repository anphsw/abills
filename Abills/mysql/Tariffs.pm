package Tariffs;
# Tarif plans functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");



my %FIELDS = ( TP_ID        => 'id', 
               NAME         => 'name',  
               TIME_TARIF   => 'hourp',
               DAY_FEE      => 'day_fee',
               MONTH_FEE    => 'month_fee',
               SIMULTANEOUSLY   => 'logins',
               AGE              => 'age',
               DAY_TIME_LIMIT   => 'day_time_limit',
               WEEK_TIME_LIMIT  => 'week_time_limit',
               MONTH_TIME_LIMIT => 'month_time_limit',
               DAY_TRAF_LIMIT   => 'day_traf_limit',  
               WEEK_TRAF_LIMIT  => 'week_traf_limit',
               MONTH_TRAF_LIMIT => 'month_traf_limit',
               ACTIV_PRICE      => 'activate_price',
               CHANGE_PRICE     => 'change_price', 
               CREDIT_TRESSHOLD => 'credit_tresshold',
               ALERT            => 'uplimit',
               OCTETS_DIRECTION => 'octets_direction',
               MAX_SESSION_DURATION => 'max_session_duration',
               FILTER_ID        => '',
               PAYMENT_TYPE     => 'payment_type',
               MIN_SESSION_COST => 'min_session_cost',

               RAD_PAIRS        => 'rad_pairs'
             );

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF, $admin) = @_;
  my $self = { };
  bless($self, $class);

  #$self->{debug}=1;
  return $self;
}




#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub ti_del {
	my $self = shift;
	my ($id) = @_;
	$self->query($db, "DELETE FROM intervals WHERE id='$id';", 'do');
	$self->query($db, "DELETE FROM trafic_tarifs WHERE interval_id='$id';", 'do');
	return $self;
}


#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub ti_add {
	my $self = shift;
	my ($attr) = @_;
	$self->query($db, "INSERT INTO intervals (tp_id, day, begin, end, tarif)
     values ('$self->{TP_ID}', '$attr->{TI_DAY}', '$attr->{TI_BEGIN}', '$attr->{TI_END}', '$attr->{TI_TARIF}');", 'do');
	return $self;
}

#**********************************************************
# Time_intervals  list
# ti_list
#**********************************************************
sub ti_list {
	my $self = shift;
	my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : "2, 3";
  if ($SORT == 1) { $SORT = "2, 3"; }  
  my $begin_end = "i.begin, i.end,";   
  my $TP_ID = $self->{TP_ID};  
  

    
  if (defined($attr->{TP_ID})) {
    $begin_end =  "TIME_TO_SEC(i.begin), TIME_TO_SEC(i.end), "; 
    $TP_ID = $attr->{TP_ID};
   }
#   if(sum(tt.in_price+tt.out_price) IS NULL || sum(tt.in_price+tt.out_price)=0, 0, sum(tt.in_price+tt.out_price)),
  $self->query($db, "SELECT i.id, i.day, $begin_end
   i.tarif,
   count(tt.id),
   i.id
   FROM intervals i
   LEFT JOIN  trafic_tarifs tt ON (tt.interval_id=i.id)
   WHERE i.tp_id='$TP_ID'
   GROUP BY i.id
   ORDER BY $SORT $DESC");
 
	return $self->{list};
}

#**********************************************************
# Time intervals change
#**********************************************************
sub ti_change {
  my $self = shift;
  my ($ti_id, $attr) = @_;
  
  %DATA = $self->get_data($attr); 

  my %FIELDS = (
    TI_DAY   => 'day', 
    TI_BEGIN => 'begin', 
    TI_END   => 'end', 
    TI_TARIF => 'tarif',
    TI_ID    => 'id'
   );

	$self->changes($admin, { CHANGE_PARAM => 'TI_ID',
		               TABLE        => 'intervals',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->ti_info($ti_id),
		               DATA         => $attr
		              } );



  if ($ti_id == $DATA{TI_ID}) {
  	$self->ti_info($ti_id);
   }
  else {
  	$self->info($DATA{TI_ID});
   }
  
#  $admin->action_add(0, "$CHANGES_LOG");
	return $self;
}


#**********************************************************
# Time_intervals  info
# ti_info();
#**********************************************************
sub ti_info {
	my $self = shift;
	my ($ti_id, $attr) = @_;

  $self->query($db, "SELECT day, begin, end, tarif, id
    FROM intervals 
    WHERE id='$ti_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  $self->{TI_ID}=$ti_id;
  ($self->{TI_DAY}, 
   $self->{TI_BEGIN}, 
   $self->{TI_END}, 
   $self->{TI_TARIF}
  ) = @$ar;

  return $self;
}


#**********************************************************
# ti_defaults
#**********************************************************
sub  ti_defaults {
	my $self = shift;
	
	my %TI_DEFAULTS = (
            TI_DAY => 0,
            TI_BEGIN => '00:00:00',
            TI_END => '24:00:00',
    	      TI_TARIF => 0
    );
	
  while(my($k, $v) = each %TI_DEFAULTS) {
    $self->{$k}=$v;
   }	
	
	return $self;
}


#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( TP_ID => 0, 
            NAME => '',  
            TIME_TARIF => '0.00000',
            DAY_FEE => '0.00',
            MONTH_FEE => '0.00',
            SIMULTANEOUSLY => 0,
            AGE => 0,
            DAY_TIME_LIMIT => 0,
            WEEK_TIME_LIMIT => 0,
            MONTH_TIME_LIMIT => 0,
            DAY_TRAF_LIMIT => 0, 
            WEEK_TRAF_LIMIT => 0, 
            MONTH_TRAF_LIMIT => 0,
            ACTIV_PRICE => '0.00',
            CHANGE_PRICE => '0.00',
            CREDIT_TRESSHOLD => '0.00',
            ALERT => 0,
            OCTETS_DIRECTION => 0,
            MAX_SESSION_DURATION => 0,
            FILTER_ID            => '',
            PAYMENT_TYPE         => 0,
            MIN_SESSION_COST     => '0.00000',
            RAD_PAIRS            => ''

         );   
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  #$self->{debug}=1;

  $self->query($db, "INSERT INTO tarif_plans (id, hourp, uplimit, name, month_fee, day_fee, logins, 
     day_time_limit, week_time_limit,  month_time_limit, 
     day_traf_limit, week_traf_limit,  month_traf_limit,
     activate_price, change_price, credit_tresshold, age, octets_direction,
     max_session_duration, filter_id, payment_type, min_session_cost, rad_pairs)
    values ('$DATA{TP_ID}', '$DATA{TIME_TARIF}', '$DATA{ALERT}', \"$DATA{NAME}\", 
     '$DATA{MONTH_FEE}', '$DATA{DAY_FEE}', '$DATA{SIMULTANEONSLY}', 
     '$DATA{DAY_TIME_LIMIT}', '$DATA{WEEK_TIME_LIMIT}',  '$DATA{MONTH_TIME_LIMIT}', 
     '$DATA{DAY_TRAF_LIMIT}', '$DATA{WEEK_TRAF_LIMIT}',  '$DATA{MONTH_TRAF_LIMIT}',
     '$DATA{ACTIV_PRICE}', '$DATA{CHANGE_PRICE}', '$DATA{CREDIT_TRESSHOLD}', '$DATA{AGE}', '$DATA{OCTETS_DIRECTION}',
     '$DATA{MAX_SESSION_DURATION}', '$DATA{FILTER_ID}',
     '$DATA{payment_type}', '$DATA{min_session_cost}', '$DATA{RAD_PAIRS}');", 'do' );


  return $self;
}



#**********************************************************
# change
#**********************************************************
sub change {
  my $self = shift;
  my ($tp_id, $attr) = @_;

  if ($tp_id != $attr->{CHG_TP_ID}) {
  	 $FIELDS{CHG_TP_ID}='id';
   }


	$self->changes($admin, { CHANGE_PARAM => 'TP_ID',
		                TABLE        => 'tarif_plans',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->info($tp_id),
		                DATA         => $attr
		              } );


  if ($tp_id != $attr->{CHG_TP_ID}) {
  	 $attr->{TP_ID} = $attr->{CHG_TP_ID};
   }


  $self->info($attr->{TP_ID});
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM tarif_plans WHERE id='$id';", 'do');

 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT id, name, hourp, day_fee, month_fee, logins, age,
      day_time_limit, week_time_limit,  month_time_limit, 
      day_traf_limit, week_traf_limit,  month_traf_limit,
      activate_price, change_price, credit_tresshold, uplimit, octets_direction, 
      max_session_duration,
      filter_id,
      payment_type,
      min_session_cost,
      rad_pairs
    FROM tarif_plans
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{TP_ID}, 
   $self->{NAME}, 
   $self->{TIME_TARIF}, 
   $self->{DAY_FEE}, 
   $self->{MONTH_FEE}, 
   $self->{SIMULTANEOUSLY}, 
   $self->{AGE},
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{DAY_TRAF_LIMIT}, 
   $self->{WEEK_TRAF_LIMIT}, 
   $self->{MONTH_TRAF_LIMIT}, 
   $self->{ACTIV_PRICE},    
   $self->{CHANGE_PRICE}, 
   $self->{CREDIT_TRESSHOLD},
   $self->{ALERT},
   $self->{OCTETS_DIRECTION},
   $self->{MAX_SESSION_DURATION},
   $self->{FILTER_ID},
   $self->{PAYMENT_TYPE},
   $self->{MIN_SESSION_COST},
   $self->{RAD_PAIRS}
  ) = @$ar;


  return $self;
}


#**********************************************************
# list
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = (defined($attr->{SORT})) ? $attr->{SORT} : 1;
  $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : '';
  $WHERE = '';
 
 $self->query($db, "SELECT tp.id, 
    tp.name, 
    if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1), 
    if(sum(tt.in_price + tt.out_price)> 0, 1, 0), 
    tp.payment_type,
    tp.day_fee, tp.month_fee, 
    tp.logins, 
    tp.age,
    tp.rad_pairs
    FROM tarif_plans tp
    LEFT JOIN intervals i ON (i.tp_id=tp.id)
    LEFT JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
    $WHERE
    GROUP BY tp.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}



#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  $self->query($db, "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}';");
	return $self->{list};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   $self->query($db, "INSERT INTO tp_nas (nas_id, tp_id)
        VALUES ('$line', '$self->{TP_ID}');", 'do');	
  }
  #$admin->action_add($uid, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  $self->query($db, "DELETE FROM tp_nas WHERE tp_id='$self->{TP_ID}';", 'do');
  #$admin->action_add($uid, "DELETE NAS");
  return $self;
}


#**********************************************************
# tt_defaults
#**********************************************************
sub  tt_defaults {
	my $self = shift;
	
	my %TT_DEFAULTS = (
      TT_DESCRIBE   => '',
      TT_PRICE_IN   => '0.00000',
      TT_PRICE_OUT  => '0.00000',
      TT_NETS       => '0.0.0.0/0',
      TT_PREPAID    => 0,
      TT_SPEED_IN   => 0,
      TT_SPEED_OUT  => 0);

#      TT_DESCRIBE_1 => '',
#      TT_PRICE_IN_1 => '0.00000',
#      TT_PRICE_OUT_1 => '0.00000',
#      TT_PRICE_NETS_1 => '',
#      TT_PREPAID_1 => 0,
#      TT_SPEED_1 => 0,
#
#      TT_DESCRIBE_2 => '',
#      TT_PRICE_IN_2 => 0,
#      TT_PRICE_OUT_2 => 0,
#      TT_NETS_2 => '',
#      TT_PREPAID_2 => 0,
#      TT_SPEED_2 => 0
#     );
	
  while(my($k, $v) = each %TT_DEFAULTS) {
    $self->{$k}=$v;
   }	
	
  #$self = \%DATA;
	return $self;
}



#**********************************************************
# tt_info
#**********************************************************
sub  tt_list {
	my $self = shift;
	my ($attr) = @_;
	
	
	if (defined( $attr->{TI_ID} )) {
	  $self->query($db, "SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, nets
     FROM trafic_tarifs WHERE interval_id='$attr->{TI_ID}';");
   }	
	else {
	  $self->query($db, "SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, nets
     FROM trafic_tarifs WHERE tp_id='$self->{TP_ID}';");
   }


if (defined($attr->{form})) {
  my $a_ref = $self->{list};

  foreach my $row (@$a_ref) {
      my ($id, $tarif_in, $tarif_out, $prepaid, $speed_in, $speed_out, $describe, $nets) = @$row;
      $self->{'TT_DESCRIBE_'. $id}   = $describe;
      $self->{'TT_PRICE_IN_' . $id}  = $tarif_in;
      $self->{'TT_PRICE_OUT_' . $id} = $tarif_out;
      $self->{'TT_NETS_'.  $id}      = $nets;
      $self->{'TT_PREPAID_' .$id}    = $prepaid;
      $self->{'TT_SPEED_IN' .$id}    = $speed_in;
      $self->{'TT_SPEED_OUT' .$id}   = $speed_out;
   }

  return $self;
}

	
	return $self->{list};
}



#**********************************************************
# tt_info
#**********************************************************
sub  tt_info {
	my $self = shift;
	my ($attr) = @_;
	
	
	  $self->query($db, "SELECT id, interval_id, in_price, out_price, prepaid, in_speed, out_speed, 
	     descr, nets
     FROM trafic_tarifs 
     WHERE 
     interval_id='$attr->{TI_ID}'
     and id='$attr->{TT_ID}';");

  my $ar = $self->{list}->[0];

  ($self->{TT_ID},
   $self->{Ti_ID},
   $self->{TT_PRICE_IN},
   $self->{TT_PRICE_OUT},
   $self->{TT_PREPAID},
   $self->{TT_SPEED_IN},
   $self->{TT_SPEED_OUT},
   $self->{TT_DESCRIBE},
   $self->{TT_NETS}
  ) = @$ar;

	
	return $self;
}


#**********************************************************
# tt_add
#**********************************************************
sub  tt_add {
  my $self = shift;
	my ($attr) = @_; 
  
  %DATA = $self->get_data($attr, {default => $self->tt_defaults() }); 

  if($DATA{TT_ID} > 2) {
  	 $self->{errno}='1';
  	 $self->{errstr}='Max 3 network group';
  	 return $self;
   }
  
  $self->query($db, "INSERT INTO trafic_tarifs  
    (interval_id, id, descr,  in_price,  out_price,  nets,  prepaid,  in_speed, out_speed)
    VALUES 
    ('$DATA{TI_ID}', '$DATA{TT_ID}',   '$DATA{TT_DESCRIBE}', '$DATA{TT_PRICE_IN}',  '$DATA{TT_PRICE_OUT}',
     '$DATA{TT_NETS}', '$DATA{TT_PREPAID}', '$DATA{TT_SPEED_IN}', '$DATA{TT_SPEED_OUT}')", 'do');

  $self->create_nets({ TI_ID => $DATA{TI_ID} });

  return $self;
}



#**********************************************************
# tt_change
#**********************************************************
sub  tt_change {
  my $self = shift;
	my ($attr) = @_; 
  
  my %DATA = $self->get_data($attr, { default => $self->tt_defaults() }); 

  $self->query($db, "UPDATE trafic_tarifs SET 
    descr='". $DATA{TT_DESCRIBE} ."', 
    in_price='". $DATA{TT_PRICE_IN}  ."',
    out_price='". $DATA{TT_PRICE_OUT} ."',
    nets='". $DATA{TT_NETS} ."',
    prepaid='". $DATA{TT_PREPAID} ."',
    in_speed='". $DATA{TT_SPEED_IN} ."',
    out_speed='". $DATA{TT_SPEED_OUT} ."'
    WHERE 
    interval_id='$attr->{TI_ID}' and id='$DATA{TT_ID}';", 'do');

  $self->create_nets({ TI_ID => $attr->{TI_ID} });
  
  return $self;
}


#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub create_nets {
	my $self = shift;
  my ($attr) = @_;
  my $body = '';


  my $list = $self->tt_list({TI_ID => $attr->{TI_ID}});
  $/ = chr(0x0d);
  
  foreach my $line (@$list) {
     my @n = split(/\n|;/, $line->[7]);
     foreach my $ip (@n) {
       chomp($ip);
       next if ($ip eq "");
       $body .= "$ip $line->[0]\n";
     }
   }

  $self->create_tt_file("$attr->{TI_ID}.nets", "$body");
}

#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub tt_del {
	my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => $self->tt_defaults() }); 

	$self->query($db, "DELETE FROM trafic_tarifs 
	 WHERE  interval_id='$attr->{TI_ID}'  and id='$attr->{TT_ID}' ;", 'do');

	return $self;
}


#**********************************************************
# create_tt_file()
#**********************************************************
sub create_tt_file {
 my ($self, $file_name, $body) = @_;
 
 open(FILE, ">$CONF->{netsfilespath}/$file_name") || die "Can't create file '$CONF->{netsfilespath}/$file_name' $!\n";
   print FILE "$body";
 close(FILE);

 print "Created '$CONF->{netsfilespath}/$file_name'
 <pre>$body</pre>";
 
 return $self;
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_list {
	my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $year = (defined($attr->{year})) ? $attr->{year} : 'YEAR(CURRENT_DATE)';
  my $format = (defined($attr->{format}) && $attr->{format} eq 'daysofyear') ? "DAYOFYEAR(CONCAT($year, '-', day)) as dayofyear" : 'day';

  $self->query($db, "SELECT $format, descr  FROM holidays ORDER BY $SORT $DESC;");
	return $self->{list};
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_add {
	my $self = shift;
	my ($attr)=@_;
	
	$DATA{MONTH} = (defined($attr->{MONTH})) ? $attr->{MONTH} : 1;
	$DATA{DAY} = (defined($attr->{DAY})) ? $attr->{DAY} : 1;
	
	$self->query($db,"INSERT INTO holidays (day)
       VALUES ('$DATA{MONTH}-$DATA{DAY}');", 'do');

  return $self;
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_del {
	my $self = shift;
  my ($id) = @_;
	$self->query($db, "DELETE from holidays WHERE day='$id';", 'do');
  return $self;
}





1