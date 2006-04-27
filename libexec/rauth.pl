#!/usr/bin/perl -w

use vars  qw(%RAD %conf $db %AUTH);
use strict;

use FindBin '$Bin';
require $Bin . '/config.pl';
#use lib '../', "../Abills/$conf{dbtype}";
#my $path = "/home/asmodeus/abills2/";

unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");

require Abills::Base;
Abills::Base->import();
my $begin_time = check_time();

# Max session tarffic limit  (Mb)
$conf{MAX_SESSION_TRAFFIC} = 2048; 




####################################################################
my $RAD = get_radius_params();
test_radius_returns($RAD);
####################################################################



#my $t = "\n\n";
#while(my($k, $v)=each(%$RAD)) {
#	$t .= "$k=\\\"$v\\\"\n";
#}
##print $t;
#my $a = `echo "$t" >> /tmp/voip_test`;




require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
my $GT = '';


if (defined($ARGV[0]) && $ARGV[0] eq 'pre_auth') {
  require Auth;
  Auth->import();
  my $Auth = Auth->new($db, \%conf);

  $Auth->pre_auth($RAD, { SECRETKEY => $conf{secretkey} });
  if ($Auth->{errno}) {
    log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] MS-CHAP PREAUTH FAILED$GT");
  }
 
  exit 0;
}




require Nas;
my $nas = Nas->new($db, \%conf);	
my %NAS_PARAMS = ('IP' => "$RAD->{NAS_IP_ADDRESS}");
$NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER} if (defined($RAD->{NAS_IDENTIFIER}));
$nas->info({ %NAS_PARAMS });


if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
  access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'", 0);
  exit 1;
}
elsif($RAD->{USER_NAME} eq '') {
  #access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
  exit 1;
}
elsif($nas->{NAS_DISABLE} > 0) {
  access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
  exit 1;
}

$nas->{at} = 0 if (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE}));
auth($RAD);
$db->disconnect();



#*******************************************************************
# auth();
#*******************************************************************
sub auth {
 my $GT = '';
 my $rr='';
 
 if(defined($conf{tech_works})) {
 	 print "Reply-Message = \"$conf{tech_works}\"\n";
 	 exit 1;
  }






my ($r, $RAD_PAIRS);

if(defined($AUTH{$nas->{NAS_TYPE}})) {

  require $AUTH{$nas->{NAS_TYPE}} . ".pm";
  $AUTH{$nas->{NAS_TYPE}}->import();
  my $Auth = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
  ($r, $RAD_PAIRS) = $Auth->auth($RAD, $nas);
 
}
else {
  require Auth;
  Auth->import();
  my $Auth = Auth->new($db, \%conf);
  ($r, $RAD_PAIRS) = $Auth->dv_auth($RAD, $nas, { SECRETKEY => $conf{secretkey},
 	                                          MAX_SESSION_TRAFFIC => $conf{MAX_SESSION_TRAFFIC}  } );
}



 




#If Access deny
 
 if($r == 1){
    print "Reply-Message = \"$RAD_PAIRS->{'Reply-Message'}\"\n";
    access_deny("$RAD->{USER_NAME}", "$RAD_PAIRS->{'Reply-Message'}", $nas->{NAS_ID});
  }
 else {
   #Show pairs
   while(my($rs, $ls)=each %$RAD_PAIRS) {
     $rr .= "$rs = $ls,\n";
    }
   print $rr;
   log_print('LOG_DEBUG', "AUTH [$RAD->{USER_NAME}] $rr");
   print $nas->{NAS_RAD_PAIRS};
 }





 if ($begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }

 log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] NAS: $nas->{NAS_ID} ($RAD->{NAS_IP_ADDRESS})$GT");
 exit $r;
}
















#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny {
my ($user, $message, $nas_num) = @_;

 log_print('LOG_WARNING', "AUTH [$user] NAS: $nas_num $message");

exit 1;
}
