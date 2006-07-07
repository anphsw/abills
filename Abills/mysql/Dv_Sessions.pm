package Dv_Sessions;
# Stats functions
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

my $db;
my $admin;
my $conf;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $conf) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}


#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;


  $self->query($db, "DELETE FROM dv_log 
   WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do');
   
  return $self;
}

#**********************************************************
# online()
#********************************************************** 
sub online_update {
	my $self = shift;
	my ($attr) = @_;


  my @SET_RULES = ();
  
  push @SET_RULES, 'lupdated=UNIX_TIMESTAMP()' if (defined($attr->{STATUS}) && $attr->{STATUS} == 5);
  
  if (defined($attr->{in})) {
   	push @SET_RULES, "acct_input_octets='$attr->{in}'";
   }

  if (defined($attr->{out})) {
  	push @SET_RULES, "acct_output_octets='$attr->{out}'";
   }


  if (defined($attr->{STATUS})) {
  	push @SET_RULES, "status='$attr->{STATUS}'";
   }


 
  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES)  : '';

  $self->query($db, "UPDATE dv_calls SET $SET
   WHERE 
    user_name='$attr->{USER_NAME}'
    and acct_session_id='$attr->{ACCT_SESSION_ID}'; ", 'do');

  return $self;
}

#**********************************************************
# online()
#********************************************************** 
sub online {
	my $self = shift;
	my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my $WHERE;
 
 if (defined($attr->{ZAPED})) {
 	 $WHERE = "c.status=2";
  }
 else {
   $WHERE = "c.status=1 or c.status>=3";
  } 
 
 if (defined($attr->{USER_NAME})) {
 	 $WHERE = "user_name='$attr->{USER_NAME}'";
  }


 if (defined($attr->{FRAMED_IP_ADDRESS})) {
 	 $WHERE = "framed_ip_address=INET_ATON('$attr->{FRAMED_IP_ADDRESS}')";
  }

 if (defined($attr->{NAS_ID})) {
 	 $WHERE = "nas_id='$attr->{NAS_ID}'";
  }


 $self->query($db, "SELECT c.user_name,
                          pi.fio,
                          c.nas_port_id,
                          c.framed_ip_address,
                          SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)),
                          c.acct_input_octets, c.acct_output_octets, c.ex_input_octets, c.ex_output_octets,
                          INET_NTOA(c.framed_ip_address),
                          c.status,
                          u.uid,
  INET_NTOA(c.nas_ip_address),
  c.acct_session_id,
  pi.phone,
  dv.tp_id,
    if(company.name IS NULL, b.deposit, cb.deposit),
  u.credit,
  dv.speed,
  c.CID,
  c.CONNECT_INFO,
  if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
  c.nas_id,
  UNIX_TIMESTAMP()-c.lupdated,
  c.sum
 FROM dv_calls c
 LEFT JOIN users u     ON u.id=user_name
 LEFT JOIN dv_main dv  ON dv.uid=u.uid
 LEFT JOIN users_pi pi ON pi.uid=u.uid

 LEFT JOIN bills b ON (u.bill_id=b.id)
 LEFT JOIN companies company ON (u.company_id=company.id)
 LEFT JOIN bills cb ON (company.bill_id=cb.id)
 
 WHERE $WHERE
 ORDER BY $SORT $DESC;");
 
 if ($self->{TOTAL} < 1) {
 	 return $self->{list};
  }


 my $list = $self->{list};
 my %dub_logins = ();
 my %dub_ports = ();
 my %nas_sorted = ();
 
 
 foreach my $line (@$list) {
 	  $dub_logins{$line->[0]}++;
 	  $dub_ports{$line->[22]}{$line->[2]}++;
    push( @{ $nas_sorted{"$line->[22]"} }, [ $line->[0], $line->[1], $line->[2], $line->[9], $line->[4], $line->[5], $line->[6], $line->[7], $line->[8], $line->[10], $line->[11], 
      $line->[13], $line->[14], $line->[15], $line->[16], $line->[17], $line->[18], $line->[19], $line->[20], $line->[21], $line->[23], $line->[24]]);

  }
 
 


 $self->{dub_ports} =\%dub_ports;
 $self->{dub_logins}=\%dub_logins;
 $self->{nas_sorted}=\%nas_sorted;

 return $self->{list};	
}



#**********************************************************
# online_del()
#********************************************************** 
sub online_del {
	my $self = shift;
	my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
  	my $session_list = join("', '", @{$attr->{SESSIONS_LIST}});
  	$WHERE = "acct_session_id in ( '$session_list' )";
   }
  else {
    my $NAS_ID  = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';
    my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id=INET_ATON('$NAS_ID')
            and nas_port_id='$NAS_PORT' 
            and acct_session_id='$ACCT_SESSION_ID'";
   }

  $self->query($db, "DELETE FROM dv_calls WHERE $WHERE;", 'do');

  return $self;
}


#**********************************************************
# Add online session to log
# online2log()
#
#********************************************************** 
sub online2log {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "SELECT c.user_name, ", 'do');
}


#**********************************************************
# Add online session to log
# online2log()
#********************************************************** 
sub online_info {
	my $self = shift;
	my ($attr) = @_;

   undef @WHERE_RULES; 

   if($attr->{NAS_ID}) {
   	  push @WHERE_RULES, "nas_id=INET_ATON('$attr->{NAS_ID}')";
    }
   elsif (defined($attr->{NAS_IP_ADDRESS})) {
      push @WHERE_RULES, "nas_ip_address=INET_ATON('$attr->{NAS_IP_ADDRESS}')";
    }
   
   if (defined($attr->{NAS_PORT})) {
     push @WHERE_RULES, "nas_port_id='$attr->{NAS_PORT}'";
    }
   
   if (defined($attr->{ACCT_SESSION_ID})) {
     push @WHERE_RULES, "acct_session_id='$attr->{ACCT_SESSION_ID}'";
    }
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT user_name, UNIX_TIMESTAMP(started), acct_session_time, 
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address),
   lupdated,
   nas_port_id,
   INET_NTOA(nas_ip_address),
      CID,
      CONNECT_INFO,
      acct_session_id,
      nas_id
      FROM dv_calls 
   $WHERE 
   ");


  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{USER_NAME}, 
   $self->{SESSION_START}, 
   $self->{ACCT_SESSION_TIME}, 
   $self->{ACCT_INPUT_OCTETS}, 
   $self->{ACCT_OUTPUT_OCTETS}, 
   $self->{ACCT_EX_INPUT_OCTETS}, 
   $self->{ACCT_EX_INPUT_OCTETS}, 
   $self->{CONNECT_TERM_REASON}, 
   $self->{FRAMED_IP_ADDRESS}, 
   $self->{LAST_UPDATE}, 
   $self->{NAS_PORT}, 
   $self->{NAS_IP_ADDRESS}, 
   $self->{CALLING_STATION_ID},
   $self->{CONNECT_INFO},
   $self->{ACCT_SESSION_ID},
   $self->{NAS_ID}
    )= @$ar;


  return $self;
}




#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self=shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr)=@_;
  
  if (! defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id' and acct_session_id='$acct_session_id'";
   }

  $self->query($db, "UPDATE dv_calls SET status='2' $WHERE;", 'do');
  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
 my $self = shift;	
 my ($attr) = @_;
 

 $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});
 

 $self->query($db, "SELECT 
  l.start,
  l.start + INTERVAL l.duration SECOND,
  l.duration,
  l.tp_id,
  tp.name,

  l.sent,
  l.recv,
  l.sent2,
  l.recv2,

  INET_NTOA(l.ip),
  l.CID,
  l.nas_id,
  n.name,
  n.ip,
  l.port_id,
  
  l.minp,
  l.kb,
  l.sum,

  l.bill_id,
  u.id,
  
  l.uid,
  l.acct_session_id,
  l.terminate_cause
 FROM dv_log l, users u
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id) 
 LEFT JOIN nas n ON (l.nas_id=n.id) 
 WHERE l.uid=u.uid 
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{START}, 
   $self->{STOP}, 
   $self->{DURATION}, 
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{SENT}, 
   $self->{RECV}, 
   $self->{SENT2},   #?
   $self->{RECV2},   #?
   $self->{IP}, 
   $self->{CID}, 
   $self->{NAS_ID}, 
   $self->{NAS_NAME},
   $self->{NAS_IP},
   $self->{NAS_PORT}, 

   $self->{TIME_TARIFF},
   $self->{TRAF_TARIFF},
   $self->{SUM}, 

   $self->{BILL_ID}, 
   $self->{LOGIN}, 

   $self->{UID}, 
   $self->{SESSION_ID},
   $self->{ACCT_TERMINATE_CAUSE}
    )= @$ar;


 return $self;
}

#**********************************************************
# detail_list()
#**********************************************************
sub detail_list {
	my $self = shift;
	my ($attr) = @_;

	
my $lupdate;
	
my $WHERE = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';	
my $GROUP;

if ($attr->{PERIOD} eq 'days') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'hours') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'sessions') {
	$WHERE = '';
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP='acct_session_id';
}
else {
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP = $lupdate;
}


 
 $self->query($db, "SELECT $lupdate, acct_session_id, nas_id, 
   sum(sent1), sum(recv1), sum(sent2), sum(recv2) 
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' $WHERE
  GROUP BY $GROUP 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;" );

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(DISTINCT $lupdate)
      FROM s_detail 
     WHERE id='$attr->{LOGIN}' $WHERE ;");
    
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
  }
	
	
return $list;
}


#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 if($attr->{UID})  {
   $WHERE .= ($WHERE ne '') ?  " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

 $self->query($db, "SELECT  
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sent, 0)), 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))), 

   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sent, 0)),
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, recv, 0)),
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))),

   sum(if((YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start)), sent, 0)),
   sum(if((YEAR(curdate())=YEAR(start)) and  WEEK(curdate()) = WEEK(start), recv, 0)),
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))),

   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent, 0)), 
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
  
   sum(sent), sum(recv), SEC_TO_TIME(sum(duration))
   FROM dv_log $WHERE;");

  my $ar = $self->{list}->[0];
  ($self->{sent_0}, 
      $self->{recv_0}, 
      $self->{duration_0}, 
      $self->{sent_1}, 
      $self->{recv_1}, 
      $self->{duration_1},
      $self->{sent_2}, 
      $self->{recv_2}, 
      $self->{duration_2}, 
      $self->{sent_3}, 
      $self->{recv_3}, 
      $self->{duration_3}, 
      $self->{sent_4}, 
      $self->{recv_4}, 
      $self->{duration_4}) =  @$ar;
  
  for(my $i=0; $i<5; $i++) {
    $self->{'sum_'. $i } = $self->{'sent_' . $i } + $self->{'recv_' . $i};
  }

  return $self;	
}

#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 undef @WHERE_RULES; 
 
#UID
 if ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }


 if ($attr->{LIST_UIDS}) {
   push @WHERE_RULES, "l.uid IN ($attr->{LIST_UIDS})";
  }


#IP
 if ($attr->{IP}) {
   push @WHERE_RULES, "l.ip=INET_ATON('$attr->{IP}')";
  }

#NAS ID
 if ($attr->{NAS_ID}) {
   push @WHERE_RULES, "l.nas_id='$attr->{NAS_ID}'";
  }

#NAS ID
 if ($attr->{CID}) {
   if($attr->{CID}) {
     $attr->{CID} =~ s/\*/\%/ig;
     push @WHERE_RULES, "l.cid LIKE '$attr->{CID}'";
    }
   else {
     push @WHERE_RULES, "l.cid='$attr->{CID}'";
    }
  }

#NAS PORT
 if ($attr->{NAS_PORT}) {
   push @WHERE_RULES, "l.port_id='$attr->{NAS_PORT}'";
  }

#TARIF_PLAN
 if ($attr->{TARIF_PLAN}) {
   push @WHERE_RULES, "l.tp_id='$attr->{TARIF_PLAN}'";
  }

#Session ID
if ($attr->{ACCT_SESSION_ID}) {
   push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

if ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}')";
 }

if ($attr->{DATE}) {
   push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$attr->{DATE}'";
 }

if ($attr->{MONTH}) {
   push @WHERE_RULES, "date_format(l.start, '%Y-%m')>='$attr->{MONTH}'";
 }


#Interval from date to date
if ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }
#Period
elsif (defined($attr->{PERIOD}) ) {
   my $period = int($attr->{PERIOD});   
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
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";
}
#else {
#	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";
#}
#From To


 push @WHERE_RULES, "u.uid=l.uid";
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




 $self->query($db, "SELECT u.id, l.start, SEC_TO_TIME(l.duration), l.tp_id,
  l.sent, l.recv, l.CID, l.nas_id, l.ip, l.sum, INET_NTOA(l.ip), 
  l.acct_session_id, 
  l.uid, 
  UNIX_TIMESTAMP(l.start),
  l.duration,
  l.sent2, l.recv2
  FROM dv_log l, users u
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};



 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*), SEC_TO_TIME(sum(l.duration)), sum(l.sent + l.recv), 
      sum(l.sent2 + l.recv2), 
      sum(sum)  
      FROM dv_log l, users u
     $WHERE;");

    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL},
     $self->{DURATION},
     $self->{TRAFFIC},
     $self->{TRAFFIC2},
     $self->{SUM}) = @$a_ref;
  }

#  $self->{list}=$list;

return $list;
}


#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
	my ($self) = shift;
	my ($attr) = @_;

#Login
  if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and l.uid='$attr->{UID}' " : "WHERE l.uid='$attr->{UID}' ";
   }

  $self->query($db, "SELECT SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)), SEC_TO_TIME(avg(l.duration)),
  min(l.sent), max(l.sent), avg(l.sent),
  min(l.recv), max(l.recv), avg(l.recv),
  min(l.recv+l.sent), max(l.recv+l.sent), avg(l.recv+l.sent)
  FROM dv_log l $WHERE");

  my $ar = $self->{list}->[0];

  ($self->{min_dur}, 
   $self->{max_dur}, 
   $self->{avg_dur}, 
   $self->{min_sent}, 
   $self->{max_sent}, 
   $self->{avg_sent},
   $self->{min_recv}, 
   $self->{max_recv}, 
   $self->{avg_recv}, 
   $self->{min_sum}, 
   $self->{max_sum}, 
   $self->{avg_sum}) =  @$ar;

	return $self;
}


#**********************************************************
# Use
#**********************************************************
sub reports {
	my ($self) = shift;
	my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 undef @WHERE_RULES;
 my $date = '';
 

 if ($attr->{GID}) {
 	 push @WHERE_RULES, "u.gid='$attr->{GID}'";
  } 
 
 
 if(defined($attr->{DATE})) {
   push @WHERE_RULES, " date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
   if ($attr->{TYPE} eq 'HOURS') {
     $date = "date_format(l.start, '%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(l.start, '%Y-%m-%d')";
    }
   else {
     $date = "u.id";   	
    }  
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(l.start, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(l.start, '%Y-%m')";
  }



 if ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 if(defined($attr->{DATE})) {
   if (defined($attr->{HOURS})) {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d %H'), count(DISTINCT l.uid), count(l.uid), 
    sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM dv_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY 1 
      ORDER BY $SORT $DESC");
    }
   else {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
    sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM dv_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC");
   #$WHERE = "WHERE date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'"; 
    }
  }
 else {
  $self->query($db, "select $date, count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + l.recv), 
      sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM dv_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;");
  }

  my $list = $self->{list}; 

  $self->{USERS}    = 0; 
  $self->{SESSIONS} = 0; 
  $self->{TRAFFIC}  = 0; 
  $self->{TRAFFIC_2}= 0; 
  $self->{DURATION} = 0; 
  $self->{SUM}      = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query($db, "select count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + l.recv), 
      sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM dv_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;");

   my $a_ref = $self->{list}->[0];
 
  ($self->{USERS}, 
   $self->{SESSIONS}, 
   $self->{TRAFFIC}, 
   $self->{TRAFFIC_2}, 
   $self->{DURATION}, 
   $self->{SUM}) = @$a_ref;



	return $list;
}




1
