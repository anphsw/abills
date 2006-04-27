package Acct;
# Accounting functions
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

# User name expration
use main;
use Billing;

@ISA  = ("main");
my ($db, $conf);



my %ACCT_TYPES = ('Start'          => 1,
                  'Stop'           => 2,
                  'Alive'          => 3,
                  'Interim-Update' => 3,
                  'Accounting-On'  => 7,
                  'Accounting-Off' => 8
                  ); 





#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}


#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
 my $self = shift;
 my ($RAD, $NAS)=@_;
 

 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};
 my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ?  "FROM_UNIXTIME($RAD->{SESSION_START})" : 'now()';

#   print "aaa $acct_status_type '$RAD->{ACCT_STATUS_TYPE}'  /$RAD->{SESSION_START}/"; 
#my $a=`echo "test $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}}"  >> /tmp/12211 `;
 
 $RAD->{FRAMED_IP_ADDRESS} = '0.0.0.0' if(! defined($RAD->{FRAMED_IP_ADDRESS}));
    
#Start
if ($acct_status_type == 1) { 
  my $sql = "INSERT INTO dv_calls
   (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, acct_session_time,
    acct_input_octets, acct_output_octets, framed_ip_address, CID, CONNECT_INFO, nas_id)
    values ('$acct_status_type', 
    \"$RAD->{USER_NAME}\", 
    $SESSION_START, 
    UNIX_TIMESTAMP(), 
    INET_ATON('$RAD->{NAS_IP_ADDRESS}'),
    '$RAD->{NAS_PORT}', 
    \"$RAD->{ACCT_SESSION_ID}\", 0, 0, 0, 
     INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), 
    '$RAD->{CALLING_STATION_ID}', 
    '$RAD->{CONNECT_INFO}', 
    '$NAS->{NAS_ID}');";


  $self->query($db, "$sql", 'do');
      
 }
# Stop status
elsif ($acct_status_type == 2) {


  my $Billing = Billing->new($db, $conf);	

  ($self->{UID}, 
  $self->{SUM}, 
  $self->{BILL_ID}, 
  $self->{TARIF_PLAN}, 
  $self->{TIME_TARIF}, 
  $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                 $RAD->{SESSION_START}, 
                                                 $RAD->{ACCT_SESSION_TIME}, 
                                                 $RAD);

#  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}=1;   
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
   }
  elsif($self->{UID} == -3) {
    my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
    $self->{errno}=1;
    $self->{errstr}="ACCT [$RAD->{USER_NAME}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
   }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
   }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
   }
  else {
    $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, minp, kb,  sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TIME_TARIF}', '$self->{TRAF_TARIF}', '$self->{SUM}', '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  \"$RAD->{ACCT_SESSION_ID}\", 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}');", 'do');

    if ($self->{errno}) {
      my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
      $self->{LOG_WARNING}="ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
      $Billing->mk_session_log($RAD);
     }
# If SQL query filed
    else {
      if ($self->{SUM} > 0) {
         $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
       }
     }
   }

  # Delete from session wtmp
#  $self->{debug}=1;
  $self->query($db, "DELETE FROM dv_calls WHERE acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" 
     and user_name=\"$RAD->{USER_NAME}\" 
     and nas_id='$NAS->{NAS_ID}';", 'do');
     
}
#Alive status 3
elsif($acct_status_type eq 3) {

## Experemental Linux alive hangup
## Author: Wanger
#if ($conf{experimentsl} eq 'yes') {
#  my ($sum, $variant, $time_t, $traf_t) = session_sum("$RAD{USER_NAME}", $ACCT_INFO{SESSION_START}, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
#  if ($sum > 0) {
#     $sql = "SELECT deposit, credit FROM users WHERE id=\"$RAD{USER_NAME}\";";
#     log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
#     $q = $db->prepare("$sql") || die $db->errstr;
#     $q -> execute();
#     my ($deposit, $credir) = $q -> fetchrow();
#      if (($deposit + $credir) - $sum) < 0) {
#        log_print('LOG_WARNING', "ACCT [$RAD{USER_NAME}] Negative balance ($d - $sum) - kill session($RAD{ACCT_SESSION_ID})");
#        system ($Bin ."/modules/hangup.pl $RAD{ACCT_SESSION_ID}");
#       }
#  }
#}
###

  $self->query($db, "UPDATE dv_calls SET
    status='$acct_status_type',
    nas_port_id='$RAD->{NAS_PORT}',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets='$RAD->{INBYTE}',
    acct_output_octets='$RAD->{OUTBYTE}',
    ex_input_octets='$RAD->{INBYTE2}',
    ex_output_octets='$RAD->{OUTBYTE2}',
    framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id=\"$RAD->{ACCT_SESSION_ID}\" and 
    user_name=\"$RAD->{USER_NAME}\" and
    nas_id='$NAS->{NAS_ID}';", 'do');
 }
else {
  $self->{errno}=1;
  $self->{errstr}="ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
}

  if ($self->{errno}) {
  	$self->{errno}=1;
  	$self->{errstr}="ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error";
  	return $self;
   }

#detalization for Exppp
if ($conf->{s_detalization} eq 'yes') {
   $RAD->{INTERIUM_INBYTE}=0 if (! defined($RAD->{INTERIUM_INBYTE}));
   $RAD->{INTERIUM_OUTBYTE}=0 if (! defined($RAD->{INTERIUM_OUTBYTE}));
   $RAD->{INTERIUM_INBYTE2}=0 if (! defined($RAD->{INTERIUM_INBYTE2}));
   $RAD->{INTERIUM_OUTBYTE2}=0 if (! defined($RAD->{INTERIUM_OUTBYTE2}));

  $self->query($db, "INSERT into s_detail (acct_session_id, nas_id, acct_status, last_update, 
    sent1, recv1, sent2, recv2, id)
  VALUES (\"$RAD->{ACCT_SESSION_ID}\", '$NAS->{NAS_ID}',
   '$acct_status_type', UNIX_TIMESTAMP(),
   '$RAD->{INTERIUM_INBYTE}', '$RAD->{INTERIUM_OUTBYTE}', 
   '$RAD->{INTERIUM_INBYTE2}', '$RAD->{INTERIUM_OUTBYTE2}', 
   '$RAD->{USER_NAME}');", 'do');
}



 return $self;
}


#**********************************************************
# start
#**********************************************************
sub start {
	my ($RAD, $NAS)=@_;
	
}


#**********************************************************
# start
#**********************************************************
sub stop {
	my ($RAD, $NAS)=@_;
	
}

#**********************************************************
# start
#**********************************************************
sub alive {
	my ($RAD, $NAS)=@_;
	
}




1
