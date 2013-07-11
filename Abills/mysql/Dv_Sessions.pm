package Dv_Sessions;
# Dv Stats functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;

  if ($CONF->{DELETE_USER}) {
    $self->del($CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;

  if ($attr->{DELETE_USER}) {
    $self->query2("DELETE FROM dv_log WHERE uid='$attr->{DELETE_USER}';", 'do');
  }
  else {
    $self->query2("SHOW TABLES LIKE 'traffic_prepaid_sum'");

    if ($self->{TOTAL} > 0) {
      $self->query2(
         "UPDATE traffic_prepaid_sum pl, dv_log l SET 
         traffic_in=traffic_in-(l.recv + 4294967296 * acct_input_gigawords),
         traffic_out=traffic_out-(l.sent + 4294967296 * acct_output_gigawords),
         li.sum=li.sum-l.sum
         WHERE pl.uid=l.uid AND l.uid='$uid' and l.start='$session_start' and l.nas_id='$nas_id' 
          and l.acct_session_id='$session_id';", 'do'
      );
    }

    $self->query2(
         "UPDATE dv_log_intervals li, dv_log l SET 
         li.recv=li.recv-(l.recv + 4294967296 * l.acct_input_gigawords),
         li.sent=li.sent-(l.sent + 4294967296 * l.acct_output_gigawords),
         li.sum=li.sum-l.sum
         WHERE li.uid=l.uid AND li.acct_session_id=l.acct_session_id
           AND l.uid='$uid' 
           AND l.acct_session_id='$session_id';", 'do'
      );

    $self->query2(
      "DELETE FROM dv_log 
       WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do'
    );
  }

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online_update {
  my $self      = shift;
  my ($attr)    = @_;
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

  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES) : '';

  $self->query2("UPDATE dv_calls SET $SET
   WHERE 
    user_name='$attr->{USER_NAME}'
    and acct_session_id='$attr->{ACCT_SESSION_ID}'; ", 'do'
  );

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online_count {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  my $WHERE = '';
  if($attr->{DOMAIN_ID}) {
    $EXT_TABLE = ' INNER JOIN users u ON (c.uid=u.uid)';
    $WHERE = " AND u.domain_id='$attr->{DOMAIN_ID}'";
  }

  $self->query2("SELECT n.id AS nas_id, 
   n.name AS nas_name, n.ip AS nas_ip, n.nas_type,  
   sum(if (c.status=1 or c.status>=3, 1, 0)) AS nas_total_sessions,
   count(distinct c.uid) AS nas_total_users,
   sum(if (status=2, 1, 0)) AS nas_zaped, 
   sum(if (status>3, 1, 0)) AS nas_error_sessions
 FROM dv_calls c  
 INNER JOIN nas n ON (c.nas_id=n.id)
 $EXT_TABLE
 WHERE c.status<11 $WHERE
 GROUP BY c.nas_id
 ORDER BY $SORT $DESC;",
 undef,
 $attr
  );

  my $list = $self->{list};
  $self->{ONLINE}=0;
  if ($self->{TOTAL} > 0) {
    $self->query2(
      "SELECT 1, count(c.uid) AS total_users,  
      sum(if (c.status=1 or c.status>=3, 1, 0)) AS online,
      sum(if (c.status=2, 1, 0)) AS zaped
   FROM dv_calls c 
   $EXT_TABLE
   WHERE c.status<11 $WHERE
   GROUP BY 1;",
   undef,
   { INFO => 1 }
    );
   $self->{TOTAL} = $self->{TOTAL_USERS};
  }

  return $list;
}

#**********************************************************
# 
# online()
#**********************************************************
sub online {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';

  $admin->{DOMAIN_ID} = 0 if (!$admin->{DOMAIN_ID});
  if ($attr->{COUNT}) {
    my $WHERE     = '';
    if ($attr->{ZAPED}) {
      $WHERE = 'WHERE c.status=2';
    }
    else {
      $WHERE = 'WHERE ((c.status=1 or c.status>=3) AND c.status<11)';
    }

    $self->query2("SELECT  count(*) AS total FROM dv_calls c $WHERE;", undef, { INFO => 1 });
    return $self;
  }
 
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ($attr->{ZAPED}) {
    push @WHERE_RULES, "c.status=2";
  }
  elsif ($attr->{ALL}) {

  }
  elsif ($attr->{STATUS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{STATUS}", 'INT', 'c.status') };
  }
  else {
    push @WHERE_RULES, "((c.status=1 or c.status>=3) AND c.status<11)";
  }

  if ($attr->{FILTER}) {
  	$attr->{$attr->{FILTER_FIELD}} = $attr->{FILTER};
  }

  my $WHERE =  $self->search_former($attr, [
      ['USER_NAME',        'STR', 'c.user_name',                                  1 ],
      ['NAS_PORT_ID',      'INT', 'c.nas_port_id',                                1 ],
      ['DURATION',         'INT', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration', 1 ],
      ['CLIENT_IP',        'IP',  'c.framed_ip_address',   'INET_NTOA(c.framed_ip_address) AS client_ip',  1 ],
      ['ACCT_INPUT_OCTETS','INT', 'c.acct_input_octets + 4294967296 * acct_input_gigawords AS acct_input_octets',    1 ],
      ['ACCT_OUTPUT_OCTETS','INT', 'c.acct_output_octets + 4294967296 * acct_output_gigawords AS acct_output_octets', 1 ],
      ['EX_INPUT_OCTETS',  'INT', 'c.ex_input_octets',                            1 ],
      ['EX_OUTPUT_OCTETS', 'INT', 'c.ex_output_octets',                           1 ],
      ['CID',              'STR', 'c.CID',                                        1 ],
      ['TP_NAME',          'STR', 'tp.name AS tp_name',                           1 ],
      ['STARTED',          'DATE', 'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started) AS started', 1],
      ['CLIENT_IP_NUM',    'INT', 'c.framed_ip_address',    'c.framed_ip_address AS ip_num' ],
      ['NETMASK',          'IP',  'service.netmask',        'INET_NTOA(service.netmask) AS netmask'],
      ['CONNECT_INFO',     'STR', 'c.CONNECT_INFO',                               1 ],
      ['SPEED',            'INT', 'service.speed',                                1 ],
      ['SUM',              'INT', 'c.sum AS session_sum',                         1 ],
      ['CALLS_TP_ID',      'INT', 'c.tp_id AS calls_tp_id',                       1 ],
      ['STATUS',           'INT', 'c.status',                                     1 ],
      ['TP_ID',            'INT', 'service.tp_id',                                1 ],
      ['SERVICE_CID',      'STR', 'service.cid',                                  1 ],
      ['GUEST',            'INT', 'c.guest',                                     1 ],
      ['TURBO_MODE',       'INT', 'c.turbo_mode',                                 1 ],
      ['JOIN_SERVICE',     'INT', 'c.join_service',                               1 ],
      ['NAS_IP',           'IP',  'nas_ip',                 'INET_NTOA(c.nas_ip_address) AS nas_ip'],
      ['ACCT_SESSION_TIME','INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS acct_session_time',1 ],
      ['DURATION_SEC',     'INT', 'if(c.lupdated>0, c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS duration_sec', 1 ],
      ['FILTER_ID',        'STR', 'if(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id',  1 ],
      ['SESSION_START',    'INT', 'UNIX_TIMESTAMP(started) AS started_unixtime',  1 ],
      ['SERVICE_STATUS',   'INT', 'service.disable AS service_status',            1 ],
      ['TP_BILLS_PRIORITY','INT', 'tp.bills_priority',                            1 ],
      ['TP_CREDIT',        'INT', 'tp.credit AS tp_credit',                       1 ],
      ['NAS_NAME',         'STR', 'nas.name AS nas_name',                         1 ],
      ['PAYMENT_METHOD',   'INT', 'tp.payment_type',                              1 ],
      ['TP_CREDIT_TRESSHOLD','INT','tp.credit_tresshold',                         1 ],
      ['EXPIRED',           'DATE',"if(u.expire>'0000-00-00' AND u.expire <= curdate(), 1, 0) AS expired", 1 ],
      ['EXPIRE',            'DATE','u.expire',                                     1 ],
      ['DV_EXPIRED',        'DATE',"if(service.expire>'0000-00-00' AND service.expire <= curdate(), 1, 0) AS dv_expired", 1 ],
      ['DV_EXPIRE',         'DATE','service.expire AS dv_expire',                  1 ],
      ['IP',                'IP',  'service.ip',          'INET_NTOA(service.ip) AS ip' ],
      ['NETMASK',           'IP',  'service.netmask',     'INET_NTOA(service.netmask) AS netmask' ],
      ['SIMULTANEONSLY',    'INT', 'service.logins',                              1 ],
      ['PORT',              'INT', 'service.port',                                1 ],
      ['FILTER_ID',         'STR', 'service.filter_id',                           1 ],
      ['STATUS',            'INT', 'service.disable AS service_status',           1 ],
      ['SESSION_IDS',       'STR', 'c.acct_session_id',                           1 ],
      ['FRAMED_IP_ADDRESS', 'IP',  'c.framed_ip_address',                         1 ],
      ['NAS_ID',            'INT', 'c.nas_id',                                    1 ],
      ['ACCT_SESSION_ID',   'STR', 'c.acct_session_id',                           1 ],
      ['UID',               'INT', 'c.uid'                                          ],
      ['LAST_ALIVE',        'INT', 'UNIX_TIMESTAMP() - c.lupdated AS last_alive', 1 ],
      ['ONLINE_BASE',  	    '',    '', 'c.CID, c.acct_session_id, UNIX_TIMESTAMP() - c.lupdated AS last_alive, c.uid' ]
    ],
    { WHERE        => 1,
    	WHERE_RULES  => \@WHERE_RULES,
    	USERS_FIELDS => 1
    }    
    );

  foreach my $field ( keys %$attr ) {
    if (! $field) {
      print "dv_calls/online: Wrong field name\n";
    }
    elsif ($field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT|PAYMENT_METHOD/ && $EXT_TABLE !~ /tarif_plans/) {
      $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id AND MODULE='Dv')";
    }
    elsif ($field =~ /NAS_NAME/ && $EXT_TABLE !~ / nas /) {
      $EXT_TABLE .= " LEFT JOIN nas ON (nas.id=c.nas_id)";
    }
    elsif ($field =~ /FIO|PHONE|ADDRESS_STREET/ && $EXT_TABLE !~ / users_pi /) {
      $EXT_TABLE .= " LEFT JOIN users_pi pi ON (pi.uid=u.uid)";
    }
  }

  $EXT_TABLE .= $self->{EXT_TABLES} if ($self->{EXT_TABLES});
  
  delete $self->{COL_NAMES_ARR};

  $self->query2("SELECT $self->{SEARCH_FIELDS} c.uid,c.nas_id,c.acct_session_id
       FROM dv_calls c
       LEFT JOIN users u     ON (u.uid=c.uid)
       LEFT JOIN dv_main service ON (service.uid=u.uid)

       $EXT_TABLE

       $WHERE
       ORDER BY $SORT $DESC;", 
   undef,
   { COLS_NAME => 1 }
  );


  my %dub_logins = ();
  my %dub_ports  = ();
  my %nas_sorted = ();

  if ($self->{TOTAL} < 1) {
    $self->{dub_ports}  = \%dub_ports;
    $self->{dub_logins} = \%dub_logins;
    $self->{nas_sorted} = \%nas_sorted;
    return $self->{list};
  }

  my $list = $self->{list};
  foreach my $line (@$list) {
     push @{ $nas_sorted{$line->{nas_id}} }, $line ;
     $dub_logins{ $line->{user_name} }++ if ($line->{user_name});
     $dub_ports{ $line->{nas_id} }{ $line->{nas_port_id} }++ if ($line->{nas_port_id});
  }

  $self->{dub_ports}  = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}

#**********************************************************
# online_join_services()
#**********************************************************
sub online_join_services {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT  join_service, 
   sum(c.acct_input_octets) + 4294967296 * sum(acct_input_gigawords), 
   sum(c.acct_output_octets) + 4294967296 * sum(acct_output_gigawords) 
 FROM dv_calls c
 GROUP BY join_service;"
  );

  return $self->{list};
}

#**********************************************************
# online_del()
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{ $attr->{SESSIONS_LIST} });
    $WHERE = "acct_session_id in ( '$session_list' )";

    if ($attr->{QUICK}) {
      $self->query2("DELETE FROM dv_calls WHERE $WHERE;", 'do');
      return $self;
    }
  }
  else {
    my $NAS_ID          = (defined($attr->{NAS_ID}))          ? $attr->{NAS_ID}          : '';
    my $NAS_PORT        = (defined($attr->{NAS_PORT}))        ? $attr->{NAS_PORT}        : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and nas_port_id='$NAS_PORT' 
            and acct_session_id='$ACCT_SESSION_ID'";
  }

  $self->query2("SELECT uid, user_name, started, SEC_TO_TIME(lupdated-UNIX_TIMESTAMP(started)), sum FROM dv_calls WHERE $WHERE");
  foreach my $line (@{ $self->{list} }) {
    $admin->action_add("$line->[0]", "START: $line->[2] DURATION: $line->[3] SUM: $line->[4]", { MODULE => 'Dv', TYPE => 13 });
  }

  $self->query2("DELETE FROM dv_calls WHERE $WHERE;", 'do');

  return $self;
}

#**********************************************************
# Add online session to log
# online2log()
#**********************************************************
sub online_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE =  $self->search_former($attr, [
      ['NAS_ID',         'INT', 'nas_id'         ],
      ['NAS_IP_ADDRESS', 'IP',  'nas_ip_address' ],
      ['NAS_PORT',       'INT', 'nas_port_id',   ],
      ['ACCT_SESSION_ID','STR', 'acct_session_id'],
    ],
    { WHERE => 1,
    }    
    );

  $self->query2("SELECT user_name, 
    UNIX_TIMESTAMP(started) AS session_start, 
    acct_session_time, 
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address) AS framed_ip_address,
   lupdated as last_update,
   nas_port_id as nas_port,
   INET_NTOA(nas_ip_address) AS nas_ip_address , 
   CID AS calling_session_id,
   CONNECT_INFO,
   acct_session_id,
   nas_id,
   started AS acct_session_started,
   acct_input_gigawords 
   acct_output_gigawords 
   FROM dv_calls 
   $WHERE",
   undef,
   { INFO => 1 }
  );

  $self->{CID} = $self->{CALLING_SESSION_ID};

  return $self;
}

#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self = shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr) = @_;

  my $WHERE = '';

  if ($attr->{NAS_ID}) {
    $WHERE = "WHERE nas_id='$attr->{NAS_ID}'";
  }
  elsif (!defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id'";
  }

  if ($acct_session_id) {
    $WHERE .= "and acct_session_id='$acct_session_id'";
  }

  $self->query2("UPDATE dv_calls SET status='2' $WHERE;", 'do');
  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});

  $self->query2("SELECT 
  l.start,
  l.start + INTERVAL l.duration SECOND AS stop,
  l.duration,
  l.tp_id,
  tp.name AS tp_name,
  l.sent + 4294967296 * acct_output_gigawords AS sent, 
  l.recv + 4294967296 * acct_input_gigawords AS recv,
  l.recv2 AS sent2,
  l.sent2 AS recv2, 
  INET_NTOA(l.ip) AS ip,
  l.CID,
  l.nas_id,
  n.name AS nas_name,
  n.ip AS nas_ip,
  l.port_id AS nas_port,
  l.sum,
  l.bill_id,
  u.id AS login,
  l.uid,
  l.acct_session_id AS session_id,
  l.terminate_cause AS acct_terminate_cause,
  UNIX_TIMESTAMP(l.start) AS start_unixtime,
  tp.tp_id AS tp_num
 FROM (dv_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id AND module='Dv') 
 LEFT JOIN nas n ON (l.nas_id=n.id) 
 WHERE l.uid=u.uid 
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';",
 undef,
 { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# detail_list()
#**********************************************************
sub detail_list {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  my $lupdate;

  my $WHERE = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';
  my $GROUP;

  if ($attr->{PERIOD} eq 'days') {
    $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";
    $GROUP   = $lupdate;
    $WHERE   = '';
  }
  elsif ($attr->{PERIOD} eq 'hours') {
    $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";
    $GROUP   = $lupdate;
    $WHERE   = '';
  }
  elsif ($attr->{PERIOD} eq 'sessions') {
    $WHERE   = '';
    $lupdate = "FROM_UNIXTIME(last_update)";
    $GROUP   = 'acct_session_id';
  }
  else {
    $lupdate = "FROM_UNIXTIME(last_update)";
    $GROUP   = $lupdate;
  }

  $self->query2("SELECT $lupdate, acct_session_id, nas_id, 
   sum(sent1), sum(recv1), sum(recv2), sum(sent2) sum
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' $WHERE
  GROUP BY $GROUP 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(DISTINCT $lupdate)
      FROM s_detail 
     WHERE id='$attr->{LOGIN}' $WHERE ;"
    );

    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  return $list;
}

#**********************************************************
# detail_list()
#**********************************************************
sub detail_sum {
  my $self = shift;
  my ($attr) = @_;

  my $lupdate;
  my $GROUP;

  my $interval = 3600;
  if ($attr->{INTERVAL}) {
    $interval = $attr->{INTERVAL};
  }

  $self->query2("select ((SELECT  sent1+recv1
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update DESC
  LIMIT 1 ) - (SELECT  sent1+recv1
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update
  LIMIT 1));"
  );

  my $speed = 0;

  if ($self->{TOTAL} > 0) {
    $self->{TOTAL_TRAFFIC} = $self->{list}->[0]->[0] || 0;
    $speed = int($self->{TOTAL_TRAFFIC} / $interval);
  }

  return $speed;
}

#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
  my $self   = shift;
  my ($attr) = @_;
  my $WHERE  = '';

  if ($attr->{UIDS}) {
    $WHERE .= "WHERE uid IN ($attr->{UIDS})";
  }
  elsif ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ? " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

  $self->query2("SELECT  
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sent + 4294967296 * acct_output_gigawords, 0)) AS day_sent, 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), recv + 4294967296 * acct_input_gigawords, 0)) AS day_recv, 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))) AS day_duration, 

   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sent + 4294967296 * acct_output_gigawords, 0)) AS yesterday_sent,
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, recv + 4294967296 * acct_input_gigawords, 0)) AS yesterday_resc,
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))) AS yesterday_duration,

   sum(if((YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start)), sent + 4294967296 * acct_output_gigawords, 0)) AS week_sent,
   sum(if((YEAR(curdate())=YEAR(start)) and  WEEK(curdate()) = WEEK(start), recv + 4294967296 * acct_input_gigawords, 0)) AS week_resc,
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))) AS week_duration,
                                                                              
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent + 4294967296 * acct_output_gigawords, 0)) AS month_sent, 
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv + 4294967296 * acct_input_gigawords, 0)) AS month_recv, 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))) AS month_duration,
  
   sum(sent + 4294967296 * acct_output_gigawords) AS total_sent, 
   sum(recv + 4294967296 * acct_input_gigawords)  AS total_recv, 
   SEC_TO_TIME(sum(duration))  AS total_duration
   FROM dv_log $WHERE;"
  );

  if ($self->{TOTAL} == 0) {
    return $self;
  }

  ($self->{sent_0}, $self->{recv_0}, $self->{duration_0}, $self->{sent_1}, $self->{recv_1}, $self->{duration_1}, $self->{sent_2}, $self->{recv_2}, $self->{duration_2}, $self->{sent_3}, $self->{recv_3}, $self->{duration_3}, $self->{sent_4}, $self->{recv_4}, $self->{duration_4}) =
  @{ $self->{list}->[0] };

  for (my $i = 0 ; $i < 5 ; $i++) {
    $self->{ 'sum_' . $i } = $self->{ 'sent_' . $i } + $self->{ 'recv_' . $i };
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub prepaid_rest {
  my $self = shift;
  my ($attr) = @_;

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  #Get User TP and intervals
  $self->query2("select tt.id AS traffic_class, 
    i.begin AS interval_begin, 
    i.end AS interval_end, 
    if(u.activate<>'0000-00-00', u.activate, DATE_FORMAT(curdate(), '%Y-%m-01')) AS activate, 
    tt.prepaid, 
    u.id AS login, 
    tp.octets_direction, 
    u.uid, 
    dv.tp_id, 
    tp.name AS tp_name,
    if (PERIOD_DIFF(DATE_FORMAT(curdate(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m')) < tp.traffic_transfer_period, 
      PERIOD_DIFF(DATE_FORMAT(curdate(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m'))+1, tp.traffic_transfer_period) AS traffic_transfert, 
    tp.day_traf_limit,
    tp.week_traf_limit,
    tp.month_traf_limit,
    tt.interval_id
  from (users u,
        dv_main dv,
        tarif_plans tp,
        intervals i,
        trafic_tarifs tt)
WHERE
     u.uid=dv.uid
 and dv.tp_id=tp.id
 and tp.tp_id=i.tp_id
 and i.id=tt.interval_id
 and u.uid='$attr->{UID}'
 ORDER BY 1
 ",
 undef,
 { COLS_NAME => 1 }
  );

  if ($self->{TOTAL} < 1) {
    return 0;
  }

  $self->{INFO_LIST}    = $self->{list};
  my $login             = $self->{INFO_LIST}->[0]->{login};
  my $traffic_transfert = $self->{INFO_LIST}->[0]->{traffic_transfert};

  my %prepaid_traffic = (
    0 => 0,
    1 => 0
  );

  my %rest_intervals = ();

  my %rest = (
    0 => 0,
    1 => 0
  );

  foreach my $line (@{ $self->{list} }) {
    $prepaid_traffic{ $line->{traffic_class} } = $line->{prepaid};
    $rest{ $line->{traffic_class} }            = $line->{prepaid};
    $rest_intervals{$line->{interval_id}}{$line->{traffic_class}} = $line->{prepaid};
  }

  return 1 if ($attr->{INFO_ONLY});

  my $octets_direction          = "(sent + 4294967296 * acct_output_gigawords) + (recv + 4294967296 * acct_input_gigawords) ";
  my $octets_direction2         = "sent2 + recv2";
  my $octets_online_direction   = "acct_input_octets + acct_output_octets";
  my $octets_online_direction2  = "ex_input_octets + ex_output_octets";
  my $octets_direction_interval = "(li.sent + li.recv)";

  if ($self->{INFO_LIST}->[0]->{octets_direction} == 1) {
    $octets_direction          = "recv + 4294967296 * acct_input_gigawords ";
    $octets_direction2         = "recv2";
    $octets_online_direction   = "acct_input_octets + 4294967296 * acct_input_gigawords";
    $octets_online_direction2  = "ex_input_octets";
    $octets_direction_interval = "li.recv";
  }
  elsif ($self->{INFO_LIST}->[0]->{octets_direction} == 2) {
    $octets_direction          = "sent + 4294967296 * acct_output_gigawords ";
    $octets_direction2         = "sent2";
    $octets_online_direction   = "acct_output_octets + 4294967296 * acct_output_gigawords";
    $octets_online_direction2  = "ex_output_octets";
    $octets_direction_interval = "li.sent";
  }

  my $uid = "l.uid='$attr->{UID}'";
  if ($attr->{UIDS}) {
    $uid = "l.uid IN ($attr->{UIDS})";
  }

  #Traffic transfert
  my $GROUP = '4';
  if ($traffic_transfert > 0) {
    $GROUP = '3';
  }

  my $WHERE = '';

  if ($attr->{FROM_DATE}) {
    $WHERE = "date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}'";
  }
  else {
    $WHERE = "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->{activate}' - INTERVAL $traffic_transfert MONTH ";
  }

  if ($CONF->{DV_INTERVAL_PREPAID}) {
    $WHERE =~ s/start/li\.added/g;
    $uid =~ s/l.uid/li.uid/g;
    $self->query2("SELECT li.traffic_type, SUM($octets_direction_interval) / $CONF->{MB_SIZE}, li.interval_id
       FROM dv_log_intervals li
       WHERE $uid AND ($WHERE)
    GROUP BY interval_id, li.traffic_type");
  }
  else {
    #Get using traffic
    $self->query2("SELECT  
     sum($octets_direction) / $CONF->{MB_SIZE},
     sum($octets_direction2) / $CONF->{MB_SIZE},
     DATE_FORMAT(l.start, '%Y-%m'), 
     1
     FROM dv_log l
     WHERE $uid  and l.tp_id='$self->{INFO_LIST}->[0]->{tp_id}' and
      (  $WHERE
        ) 
     GROUP BY $GROUP
     ;"
    );
  }
  

  if ($self->{TOTAL} > 0) {
    my ($class1, $class2) = (0, 0);

    if (! $CONF->{DV_INTERVAL_PREPAID}) {
      $self->{INFO_LIST}->[0]->{prepaid} = 0;
      if ($prepaid_traffic{1}) { $self->{INFO_LIST}->[1]->{prepaid} = 0 }
    }

    foreach my $line (@{ $self->{list} }) {
      if ($CONF->{DV_INTERVAL_PREPAID}) {
        $rest_intervals{$line->[2]}{$line->[0]} = $rest_intervals{$line->[2]}{$line->[0]} - $line->[1];
      }
      else {
        $class1 = ((($class1 > 0) ? $class1 : 0) + $prepaid_traffic{0}) - $line->[0];
        $class2 = ((($class2 > 0) ? $class2 : 0) + $prepaid_traffic{1}) - $line->[1];

        $self->{INFO_LIST}->[0]->{prepaid} += $prepaid_traffic{0};
        if ($prepaid_traffic{1}) {
          $self->{INFO_LIST}->[1]->{prepaid} += $prepaid_traffic{1};
        }
      }
    }
    if (! $CONF->{DV_INTERVAL_PREPAID}) {
      $rest{0} = $class1;
      $rest{1} = $class2;
    }
  }


  if (! $CONF->{DV_INTERVAL_PREPAID}) {
    #Check online
    $self->query2("SELECT
       $rest{0} - sum($octets_online_direction) / $CONF->{MB_SIZE},
       $rest{1} - sum($octets_online_direction2) / $CONF->{MB_SIZE},
       1
     FROM dv_calls l
     WHERE $uid
     GROUP BY 3;"
    );

    if ($self->{TOTAL} > 0) {
      ($rest{0}, $rest{1}) = @{ $self->{list}->[0] };
    }
    $self->{REST} = \%rest;
  }
  else {
    $self->{REST} = \%rest_intervals;
  }
  

  return 1;
}

#**********************************************************
# List
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  @WHERE_RULES = ();

  #Interval from date to date
  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }
  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) { }
    else {
      if    ($period == 0) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
      #Prev month
      elsif ($period == 6) { push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate() - interval 1 month, '%Y-%m') "; }
      else                 { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
  }

  my $WHERE = $self->search_former($attr, [
      [ 'LOGIN',           'STR', 'u.id AS login',                1],
      [ 'DATE',            'DATE','l.start',                      1],
      [ 'DURATION',        'DATE','SEC_TO_TIME(l.duration) AS duration',   1 ],
      [ 'SENT',            'INT', 'l.sent + 4294967296 * acct_output_gigawords AS sent', 1 ], 
      [ 'RECV',            'INT', 'l.recv + 4294967296 * acct_input_gigawords AS recv',  1 ], 
      [ 'SENT2',           'INT', 'l.sent2',                      1],
      [ 'RECV2',           'INT', 'l.recv2',                      1], 
      [ 'IP',              'IP',  'l.ip',   'INET_NTOA(l.ip) AS ip'],
      [ 'CID',             'STR', 'l.cid',                        1],
      [ 'TP_ID',           'INT', 'l.tp_id',                      1],
      [ 'SUM',             'INT', 'l.sum',                        1],
      [ 'NAS_ID',          'INT', 'l.nas_id',                     1],
      [ 'NAS_PORT',        'INT', 'l.port_id',                    1],
      [ 'ACCT_SESSION_ID', 'STR', 'l.acct_session_id',            ],
      [ 'TERMINATE_CAUSE', 'INT', 'l.terminate_cause',            1],
      [ 'BILL_ID',         'STR', 'l.bill_id',                    1],
      [ 'DURATION_SEC',    'INT', 'l.duration AS duration_sec',   1],
      [ 'START_UNIXTIME',  'INT', 'UNIX_TIMESTAMP(l.start) AS asstart_unixtime', 1],
      [ 'FROM_DATE|TO_DATE','DATE',"date_format(l.start, '%Y-%m-%d')"],
      [ 'MONTH',           'DATE',"date_format(l.start, '%Y-%m')"    ],
      [ 'UID',             'INT', 'l.uid'                            ],
    ], 
    { WHERE             => 1,
    	WHERE_RULES       => \@WHERE_RULES,
    	USERS_FIELDS      => 1,
    	SKIP_USERS_FIELDS => [ 'UID' ]
    }    
    );

  my $EXT_TABLE = '';

  if ($self->{SEARCH_FIELDS} =~ /pi\./) {
    $EXT_TABLE .= "LEFT JOIN users_pi pi ON (pi.uid=l.uid)";
  }
  if ($self->{SEARCH_FIELDS} =~ /u\./) {
    $EXT_TABLE .= "INNER JOIN users u ON (u.uid=l.uid)";
  }


  $self->query2("SELECT $self->{SEARCH_FIELDS} l.acct_session_id, l.uid
    FROM dv_log l
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(l.uid) AS total, 
      SEC_TO_TIME(sum(l.duration)) AS duration, 
      sum(l.sent + 4294967296 * acct_output_gigawords) AS traffic_in, 
      sum(l.recv + 4294967296 * acct_input_gigawords) AS traffic_out, 
      sum(l.sent2) AS traffic2_in, 
      sum(l.recv2) AS traffic2_out, 
      sum(sum) AS sum
      FROM dv_log l
      $EXT_TABLE
     $WHERE;",
     undef,
     { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
  my ($self) = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  #Login
  if ($attr->{UIDS}) {
    push @WHERE_RULES, "l.uid IN ($attr->{UIDS})";
  }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }

  if ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }

  #Period
  elsif (defined($attr->{PERIOD})) {
    my $period = int($attr->{PERIOD});
    if ($period == 4) {

    }
    else {
      if    ($period == 0) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
      elsif ($period == 1) { push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 "; }
      elsif ($period == 2) { push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) "; }
      elsif ($period == 3) { push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
      elsif ($period == 5) { push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
    }
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
  SEC_TO_TIME(min(l.duration)) AS min_dur, 
  SEC_TO_TIME(max(l.duration)) AS max_dur, 
  SEC_TO_TIME(avg(l.duration)) AS avg_dur, 
  SEC_TO_TIME(sum(l.duration)) AS total_dur,
  min(l.sent + 4294967296 * acct_output_gigawords) AS min_sent, 
  max(l.sent + 4294967296 * acct_output_gigawords) AS max_sent, 
  avg(l.sent + 4294967296 * acct_output_gigawords) AS avg_sent, 
  sum(l.sent + 4294967296 * acct_output_gigawords) AS total_sent,
  min(l.recv + 4294967296 * acct_input_gigawords) AS min_recv, 
  max(l.recv + 4294967296 * acct_input_gigawords) AS max_recv, 
  avg(l.recv + 4294967296 * acct_input_gigawords) AS avg_recv, 
  sum(l.recv + 4294967296 * acct_input_gigawords) AS total_recv,
  min(l.recv+l.sent) AS min_sum, 
  max(l.recv+l.sent) AS max_sum, 
  avg(l.recv+l.sent) AS avg_sum, 
  sum(l.recv+l.sent) AS total_sum
  FROM dv_log l $WHERE",
  undef,
  { INFO => 1 }
  );

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
  my $date       = '';
  my $EXT_TABLES = '';
  my $ext_fields = ', u.company_id';

  my @FIELDS_ARR = ('DATE', 'USERS', 'USERS_FIO', 'TP', 'SESSIONS', 'TRAFFIC_RECV', 'TRAFFIC_SENT', 'TRAFFIC_SUM', 'TRAFFIC_2_SUM', 'DURATION', 'SUM',);

  $self->{REPORT_FIELDS} = {
    DATE            => '',
    USERS           => 'u.id',
    USERS_FIO       => 'u.fio',
    SESSIONS        => 'count(l.uid)',
    TERMINATE_CAUSE => 'l.terminate_cause',
    TRAFFIC_SUM     => 'sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords)',
    TRAFFIC_2_SUM   => 'sum(l.sent2 + l.recv2)',
    DURATION        => 'sec_to_time(sum(l.duration))',
    SUM             => 'sum(l.sum)',
    TRAFFIC_RECV    => 'sum(l.recv + 4294967296 * acct_input_gigawords)',
    TRAFFIC_SENT    => 'sum(l.sent + 4294967296 * acct_output_gigawords)',
    USERS_COUNT     => 'count(DISTINCT l.uid)',
    TP              => 'l.tp_id',
    COMPANIES       => 'c.name'
  };

  my $EXT_TABLE = 'users';

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, " l.tp_id='$attr->{TP_ID}'";
  }

  if (defined($attr->{DATE})) {
    push @WHERE_RULES, " date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
  elsif ($attr->{INTERVAL}) {
    my ($from, $to) = split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
    $attr->{TYPE} = '-' if (!$attr->{TYPE});
    if ($attr->{TYPE} eq 'HOURS') {
      $date = "date_format(l.start, '\%H')";
    }
    elsif ($attr->{TYPE} eq 'DAYS') {
      $date = "date_format(l.start, '%Y-%m-%d')";
    }
    elsif ($attr->{TYPE} eq 'TP') {
      $date = "l.tp_id";
    }
    elsif ($attr->{TYPE} eq 'TERMINATE_CAUSE') {
      $date = "l.terminate_cause";
    }
    elsif ($attr->{TYPE} eq 'GID') {
      $date = "u.gid";
    }
    elsif ($attr->{TYPE} eq 'COMPANIES') {
      $date       = "c.name";
      $EXT_TABLES = "INNER JOIN companies c ON (c.id=u.company_id)";
    }
    else {
      $date = "u.id";
    }
  }
  elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
    $date = "date_format(l.start, '%Y-%m-%d')";
  }
  else {
    $date = "date_format(l.start, '%Y-%m')";
  }

  # Compnay
  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id=$attr->{COMPANY_ID}";
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
    #$EXT_TABLES .= " INNER JOIN users u ON (u.uid=f.uid)";
  }
  else {
    #$EXT_TABLES .= " LEFT JOIN users u ON (u.uid=f.uid)";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->{REPORT_FIELDS}{DATE} = $date;
  my $fields = "$date, count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), 
      sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)";

  if ($attr->{FIELDS}) {
    my @fields_array    = split(/, /, $attr->{FIELDS});
    my @show_fields     = ();
    my %get_fields_hash = ();

    foreach my $line (@fields_array) {
      $get_fields_hash{$line} = 1;
      if ($line eq 'USERS_FIO') {
        $EXT_TABLE = 'users_pi';
        $date      = 'u.fio';

        #$ext_fields = '';
      }
      elsif ($line =~ /^_(\S+)/) {

        #$date =
        my $f = '_' . $1;
        push @FIELDS_ARR, $f;
        $self->{REPORT_FIELDS}{$f} = 'u.' . $f;
        $EXT_TABLE = 'users_pi';

        #$ext_fields = '';
      }
    }

    foreach my $k (@FIELDS_ARR) {
      if ($get_fields_hash{$k}) {
        push @show_fields, $self->{REPORT_FIELDS}{$k};
      }
    }

    $fields = join(', ', @show_fields);
  }

  if (defined($attr->{DATE})) {
    if (defined($attr->{HOURS})) {
      $self->query2("SELECT date_format(l.start, '%Y-%m-%d %H')start, '%Y-%m-%d %H')start, '%Y-%m-%d %H'), 
     count(DISTINCT l.uid), count(l.uid), 
    sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), 
     sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid $ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE 
      GROUP BY 1 
      ORDER BY $SORT $DESC"
      );
    }
    else {
      $self->query2("SELECT date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
    sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC"
      );
    }
  }
  elsif ($attr->{TP}) {
    print "TP";
  }
  else {
    $self->query2("select $fields,
      l.uid $ext_fields
       FROM dv_log l
       LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
       $EXT_TABLES
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;"
    );
  }

  my $list = $self->{list};

  $self->{USERS}     = 0;
  $self->{SESSIONS}  = 0;
  $self->{TRAFFIC}   = 0;
  $self->{TRAFFIC_2} = 0;
  $self->{DURATION}  = 0;
  $self->{SUM}       = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query2("select count(DISTINCT l.uid) AS users, 
      count(l.uid) AS sessions,
      sum(l.sent + 4294967296 * acct_output_gigawords) AS traffic_out,
      sum(l.recv + 4294967296 * acct_input_gigawords) AS traffic_in, 
      sum(l.sent2) AS traffic_2_out,
      sum(l.recv2) AS traffic_2_in,
      sec_to_time(sum(l.duration)) AS duration, 
      sum(l.sum) AS sum
       FROM dv_log l
       LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
       $EXT_TABLES
       $WHERE;",
    undef,
    { INFO => 1 }
  );

  $self->{TRAFFIC}   = $self->{TRAFFIC_OUT} + $self->{TRAFFIC_IN};
  $self->{TRAFFIC_2} = $self->{TRAFFIC_2_OUT} + $self->{TRAFFIC_2_IN};

  return $list;
}

#**********************************************************
# List
#**********************************************************
sub list_log_intervals {
  my $self = shift;
  my ($attr) = @_;

  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 2;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';

  undef @WHERE_RULES;

  #UID
  if ($attr->{ACCT_SESSION_ID}) {
    push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT interval_id,
                           traffic_type,
                           sent,
                           recv,
                           duration,
                           sum
  FROM dv_log_intervals l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Rotete logs
#**********************************************************
sub log_rotate {
  my $self = shift;
  my ($attr) = @_;

  my $version = $self->db_version();
  my @rq      = ();

  if ($version > 4.1) {
    push @rq, 'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
    'CREATE TABLE IF NOT EXISTS errors_log_new_sorted LIKE errors_log;',
    'RENAME TABLE errors_log TO errors_log_old, errors_log_new TO errors_log;',
    'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log_old GROUP BY user,message,nas_id ORDER BY 1;',
    'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log GROUP BY user,message,nas_id ORDER BY 1;',
    'DROP TABLE errors_log_old;',
    'RENAME TABLE errors_log TO errors_log_old, errors_log_new_sorted TO errors_log;',
    'DROP TABLE errors_log_old;';

    if (!$attr->{DAILY}) {
      use POSIX qw(strftime);
      my $DATE = (strftime "%Y_%m_%d", localtime(time - 86400));
      push @rq, 'CREATE TABLE IF NOT EXISTS s_detail_new LIKE s_detail;', 
      'RENAME TABLE s_detail TO s_detail_' . $DATE . ', s_detail_new TO s_detail;',

      #'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
      #'RENAME TABLE errors_log TO errors_log_'. $DATE .
      # ', errors_log_new TO errors_log;',

      'CREATE TABLE IF NOT EXISTS dv_log_intervals_new LIKE dv_log_intervals;', 
      'DROP TABLE dv_log_intervals_old',
      'RENAME TABLE dv_log_intervals TO dv_log_intervals_old, dv_log_intervals_new TO dv_log_intervals;';
      if ($CONF->{DV_INTERVAL_PREPAID}) {
        push @rq, 'INSERT INTO dv_log_intervals SELECT * FROM dv_log_intervals_old WHERE added>=UNIX_TIMESTAMP()-86400*31;';
      }
    }
  }
  else {
    push @rq, "DELETE from s_detail
            WHERE last_update < UNIX_TIMESTAMP()- $attr->{PERIOD} * 24 * 60 * 60;";

    # LOW_PRIORITY
    push @rq, "DELETE dv_log_intervals from dv_log, dv_log_intervals
     WHERE
     dv_log.acct_session_id=dv_log_intervals.acct_session_id
      and dv_log.start < curdate() - INTERVAL $attr->{PERIOD} DAY;";
  }

  foreach my $query (@rq) {
    $self->query2("$query", 'do');
  }

  return $self;
}

1
