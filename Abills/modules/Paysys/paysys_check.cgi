#!/usr/bin/perl
# Paysys processing system
# Check payments incomming request
#

use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
%LIST_PARAMS
@MODULES
$admin
$users
$payments
$Paysys
$debug
%conf
%PAYSYS_PAYMENTS_METHODS
$md5
$html
$systems_ips
%systems_ident_params
%system_params
$silent
);

BEGIN {
  my $libpath = '../';

  $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/modules/Paysys');
  unshift(@INC, $libpath . 'Abills');

  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
  }
  else {
    $begin_time = 0;
  }
}

require "config.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;

$silent  = 1;
$debug   = $conf{PAYSYS_DEBUG} || 0;
$html    = Abills::HTML->new();
my $sql  = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db   = $sql->{db};
require "Misc.pm";


#Operation status
my $status = '';

require "Abills/templates.pl";

if ($Paysys::VERSION < 3.2) {
  print "Content=-Type: text/html\n\n";
  print "Please update module 'Paysys' to version 3.2 or higher. http://abills.net.ua/";
  return 0;
}

#Check allow ips
if ($conf{PAYSYS_IPS}) {
  $conf{PAYSYS_IPS} =~ s/ //g;
  @ips_arr = split(/,/, $conf{PAYSYS_IPS});

  #Default DENY FROM all
  my $allow = 0;
  foreach my $ip (@ips_arr) {

    #Deny address
    if ($ip =~ /^!/ && $ip =~ /$ENV{REMOTE_ADDR}$/) {
      last;
    }

    #allow address
    elsif ($ENV{REMOTE_ADDR} =~ /^$ip/) {
      $allow = 1;
      last;
    }

    #allow from all networks
    elsif ($ip eq '0.0.0.0') {
      $allow = 1;
      last;
    }
  }

  #Address not allow
  #Send info mail to admin
  if (!$allow) {
    print "Content-Type: text/html\n\n";
    my $error = "Error: IP '$ENV{REMOTE_ADDR}' DENY by System";
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Paysys", "IP '$ENV{REMOTE_ADDR}' DENY by System", "$conf{MAIL_CHARSET}", "2 (High)");
    mk_log($error);
    exit;
  }
}

if ($conf{PAYSYS_PASSWD}) {
  my ($user, $password) = split(/:/, $conf{PAYSYS_PASSWD});

  if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
    $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
    my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

    #  print "Content-Type: text/html\n\n";
    #  print "($REMOTE_PASSWD ne $password || $REMOTE_USER ne $user)";

    if ( (!$REMOTE_PASSWD)
      || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
      || (!$REMOTE_USER)
      || ($REMOTE_USER   && $REMOTE_USER   ne $user))
    {
      print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
      print "Status: 401 Unauthorized\n";
      print "Content-Type: text/html\n\n";
      print "Access Deny";
      exit;
    }
  }
}

$Paysys   = Paysys->new($db, undef, \%conf);
$admin    = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });
$payments = Finance->payments($db, $admin, \%conf);
$users    = Users->new($db, $admin, \%conf);

%PAYSYS_PAYMENTS_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#debug =========================================

my $output2 = '';

#read(STDIN, $output2, $ENV{'CONTENT_LENGTH'});
if ($debug > 0) {
  while (my ($k, $v) = each %FORM) {
    $output2 .= "$k -> $v\n" if ($k ne '__BUFFER');
  }

  mk_log($output2);
}

#END debug =====================================

eval { require Digest::MD5; };
if (!$@) {
  Digest::MD5->import();
}
else {
  print "Content-Type: text/html\n\n";
  print "Can't load 'Digest::MD5' check http://www.cpan.org";
  exit;
}

$md5 = new Digest::MD5;

if ($conf{PAYSYS_SUCCESSIONS}) {
  $conf{PAYSYS_SUCCESSIONS} =~ s/[\n\r]+//g;
  my @systems_arr = split(/;/, $conf{PAYSYS_SUCCESSIONS});
  # IPS:ID:NAME:SHORT_NAME:MODULE_function;
  foreach my $line (@systems_arr) {
    my ($ips, $id, $name, $short_name, $function) = split(/:/, $line);

    %system_params = (
      SYSTEM_SHORT_NAME => $short_name,
      SYSTEM_ID         => $id
    );

    my @ips_arr = split(/,/, $ips);
    if (in_array($ENV{REMOTE_ADDR}, \@ips_arr)) {
      if ($function =~ /\.pm/) {
        require "$function";
      }
      else {
        $function->(\%system_params);
      }

      exit;
    }
    
    %system_params = ();
  }
}

if (check_ip($ENV{REMOTE_ADDR}, '213.160.149.0/24')) {
  require "Ibox.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '91.194.189.69')) {
  require "Payu.pm";
  exit;
}
elsif ($FORM{ok_txn_id} || check_ip($ENV{REMOTE_ADDR}, '78.140.166.69')) {
  require "Okpay.pm";
  exit;
}
# Perfectmoney
elsif ($FORM{PAYEE_ACCOUNT} && check_ip($ENV{REMOTE_ADDR}, '77.109.141.170')) {
  require "Perfectmoney.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '85.192.45.0/24,194.67.81.0/24,91.142.251.0/24,89.111.54.0/24,95.163.74.0/24')) {
  require "Smsonline.pm";
  exit;
}
elsif ($FORM{__BUFFER} =~ /^{.+}$/ && 
  check_ip($ENV{REMOTE_ADDR}, '75.101.163.115,107.22.173.15,107.22.173.86,213.154.214.76,217.117.64.232-217.117.64.238')) {
  require "Private_bank_json.pm";
  exit;
}
# Privat bank terminal interface
elsif (check_ip($ENV{REMOTE_ADDR}, '107.22.173.15,107.22.173.86,217.117.64.232/28,75.101.163.115,213.154.214.76,192.168.1.104,217.117.64.232/29')) {
  eval { require "Privat_terminal.pm" };
  if ( $@ ) {
  	print $@;
  }
  exit;
}
elsif (($FORM{signature} && $FORM{operation_xml}) || check_ip($ENV{REMOTE_ADDR}, '54.229.105.178')) {
  require "Liqpay.pm";
  exit;
}

# IP: 77.120.97.36
elsif ($FORM{merchantid}) {
  require "Regulpay.pm";
  exit;
}
# IP: 77.120.97.36
#elsif (check_ip($ENV{REMOTE_ADDR}, '192.168.1.103')) {
#  require "PayU.pm";
#  exit;
#}
# IP: -
elsif ($FORM{params}) {
  require "Sberbank.pm";
  exit;
}
elsif ($FORM{request_type} && $FORM{random} || $FORM{copayco_result}) {
  require "Copayco.pm";
  exit;
}
elsif ($FORM{xmlmsg}) {
  require "Minbank.pm";
  minbank_check_payment();
  exit;
}
elsif ($FORM{from} eq 'Payonline') {
  require "Payonline.pm";
  exit;
}
elsif ($conf{PAYSYS_EXPPAY_ACCOUNT_KEY}
  && ( $FORM{action} == 1
    || $FORM{action} == 2
    || $FORM{action} == 4 )) {
  require "Express.pm";
  exit;
}
elsif ( check_ip($ENV{REMOTE_ADDR}, '62.89.31.36,95.140.194.139')) {
  require "Telcell.pm";
  exit;
}
elsif ( check_ip($ENV{REMOTE_ADDR}, '195.76.9.187,195.76.9.222,192.168.1.101')) {
  require "Redsys.pm";
  exit;
}
elsif ($FORM{action} && $conf{PAYSYS_CYBERPLAT_ACCOUNT_KEY}) {
  require "Cyberplat.pm";
  exit;
}
elsif ($FORM{SHOPORDERNUMBER}) {
  portmone_payments();
}
elsif ($FORM{acqid}) {
  privatbank_payments();
}
elsif ($FORM{operation} || $ENV{'QUERY_STRING'} =~ /operation=/) {
  require "Comepay.pm";
  exit;
}
elsif ($FORM{'<OPERATION id'} || $FORM{'%3COPERATION%20id'}) {
  require "Express-oplata.pm";
  exit;
}
elsif ($FORM{ACT}) {
  require "24_non_stop.pm";
  exit;
}
elsif ($conf{PAYSYS_GIGS_IPS} && $conf{PAYSYS_GIGS_IPS} =~ /$ENV{REMOTE_ADDR}/) {
  require "Gigs.pm";
}
elsif (check_ip($ENV{REMOTE_ADDR}, '217.77.49.157')) {
  require "Rucard.pm";
  exit;
}
elsif ($conf{PAYSYS_EPAY_ACCOUNT_KEY} && $FORM{command} && $FORM{txn_id}) {
  require "Epay.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '77.73.26.162,77.73.26.163,77.73.26.164,217.73.198.66')) {
  require "Deltapay.pm";
  exit;
}
elsif ($FORM{txn_id} || $FORM{prv_txn} || defined($FORM{prv_id}) || ($FORM{command} && $FORM{account})) {
  osmp_payments();
}
elsif (
  $conf{PAYSYS_GAZPROMBANK_ACCOUNT_KEY}
  && ( $FORM{lsid}
    || $FORM{trid}
    || $FORM{dtst})
) {
  require "Gazprombank.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '193.110.17.230')) {
  require "Zaplati_sumy.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '77.222.134.205')) {
  require "Ipay.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '62.149.15.210,62.149.8.166,82.207.125.57')) {
  require "Platezhka.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '213.230.106.112/28,213.230.65.85/28')) {
  require "Paynet.pm";
  exit;
}



#Check payment system by IP
if (check_ip($ENV{REMOTE_ADDR}, '92.125.0.0/24')) {
  osmp_payments_v4();
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '93.183.196.26,195.230.131.50,93.183.196.28')) {
  require "Easysoft.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, "$conf{PAYSYS_ERIPT_IPS}")) {
  require "Erip.pm";
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '79.142.16.0/21')) {
  print "Content-Type: text/xml\n\n" . "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" . "<response>\n" . "<result>300</result>\n" . "<result1>$ENV{REMOTE_ADDR}</result1>\n" . " </response>\n";
  exit;
}

#USMP
elsif (check_ip($ENV{REMOTE_ADDR}, '77.222.138.142,78.30.232.14,77.120.96.58,91.105.201.31')) {
  require "Usmp.pm";
  exit;
}
elsif ($FORM{payment} && $FORM{payment} =~ /pay_way/) {
  require "P24.pm";
  p24_payments();
  exit;
}
elsif($conf{'PAYSYS_YANDEX_ACCCOUNT'} && $FORM{code}) {
  yandex();
  exit;
}

print "Content-Type: text/html\n\n";

#New module load method
#
#use FindBin '$Bin';
#my %systems_ips = ();
#my %systemS_params = ();
#
#my $modules_dir = $Bin."/../Abills/modules/Paysys/";
#$debug = 4;
#opendir DIR, $modules_dir or die "Can't open dir '$modules_dir' $!\n";
#    my @paysys_modules = grep  /\.pm$/  , readdir DIR;
#closedir DIR;
#
#for(my $i=0; $i<=$#paysys_modules; $i++) {
#  my $paysys_module = $paysys_modules[$i];
#  undef $system_ips;
#  undef $systems_ident_params;
#
#  print "$paysys_module";
#  require "$modules_dir$paysys_module";
#
#  my $pay_function = $paysys_module.'_payment';
#  if (! defined(&$pay_function)) {
#    print "Not found" if ($debug > 2);
#    next;
#   }
#
#  if ($debug > 3) {
#
#    if ($system_ips) {
#      my @ips = split(/,/, $system_ips);
#      foreach my $ip (@ips) {
#        $systems_ips{$ip}="$paysys_module"."_payment";
#       }
#     }
#    elsif (defined(%systems_ident_params)) {
#      while(my ($param, $function) = %systems_ident_params) {
#        $systemS_params{$param}="$paysys_module:$function";;
#       }
#     }
#
#    if (!$@) {
#      print "Loaded";
#     }
#    print "<br>\n";
#   }
#}

payments();

#**********************************************************
#
#**********************************************************
sub payments {

  if ($FORM{LMI_PAYMENT_NO}) {    # || $FORM{LMI_HASH}) {
    wm_payments();
  }
  elsif ($FORM{userField_UID}) {
    require "Rbkmoney.pm";
    #print 'lol';
  }
  elsif ($FORM{id_ups}) {
    require "Ukrpays.pm";
  }
  elsif ($FORM{smsid}) {
    smsproxy_payments();
  }
  elsif ($FORM{sign}) {
    usmp_payments();
  }
  elsif ($FORM{lr_paidto}) {
    require "Libertyreserve.pm";
  }
  else {
    
    if ($FORM{INTERACT}) {
    	interact_mode();
    }
    elsif (scalar keys %FORM > 0) {
      print "Error: Unknown payment system";
      if ($debug == 0) {
        while (my ($k, $v) = each %FORM) {
          $output2 .= "$k -> $v\n" if ($k ne '__BUFFER');
        }
      }
      mk_log($output2, { PAYSYS_ID => 'Unknown' });
    }
    else {
    	$FORM{INTERACT}=1;
    	interact_mode();
    }
  }
}

#**********************************************************
# Check ip
#**********************************************************
sub check_ip {
  my ($require_ip, $ips) = @_;

  $ips =~ s/ //g;
  my $mask           = 0b0000000000000000000000000000001;
  my @ip_arr         = split(/,/, $ips);
  my $require_ip_num = ip2int($require_ip);

  foreach my $ip (@ip_arr) {
    if ($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      if ($require_ip eq "$ip") {
        return 1;
      }
    }
    elsif ($ip =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d+)/) {
      $ip = $1;
      my $bit_mask = $2;
      my $first_ip = ip2int($ip);
      my $last_ip  = ip2int($ip) + sprintf("%d", $mask << (32 - $bit_mask));

      if ($require_ip_num >= $first_ip && $require_ip_num <= $last_ip) {
        return 1;
      }
    }
  }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub portmone_payments {

  #Get order
  my $status = 0;
  my $list   = $Paysys->list(
    {
      TRANSACTION_ID => "PM:$FORM{'SHOPORDERNUMBER'}",
      SUM            => '_SHOW',
      STATUS         => 1,
      COLS_NAME      => 1,
    }
  );

  if ($Paysys->{TOTAL} > 0) {
    my $uid  = $list->[0]{uid};
    my $sum  = $list->[0]{sum};
    my $user = $users->info($uid);
    $payments->add(
      $user,
      {
        SUM          => $sum,
        DESCRIBE     => 'PORTMONE',
        METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{45}) ? 45 : '2',
        EXT_ID       => "PM:$FORM{SHOPORDERNUMBER}",
        CHECK_EXT_ID => "PM:$FORM{SHOPORDERNUMBER}"
      }
    );

    #Exists
    if ($payments->{errno}) {
    	if ($payments->{errno} == 7) {
        $status = 8;
      }
      else {
        $status = 4;
      }
    }
    else {
      $Paysys->change(
        {
          ID     => $list->[0]{id},
          INFO   => "APPROVALCODE: $FORM{APPROVALCODE}",
          STATUS => 2
        }
      );
      $status = 1;
    }

    if ($conf{PAYSYS_EMAIL_NOTICE}) {
      my $message = "\n" . "System: Portmone\n" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $FORM{SHOPORDERNUMBER}\n" . "SUM: $sum\n";

      sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Paysys Portmone Add", "$message", "$conf{MAIL_CHARSET}", "2 (High)");

    }
  }

  #money added sucesfully
  my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};
  $home_url =~ s/paysys_check.cgi/index.cgi/;

  if ($status == 1) {
    print "Location: $home_url?index=$FORM{index}&sid=$FORM{sid}&SHOPORDERNUMBER=$FORM{SHOPORDERNUMBER}&TRUE=1" . "\n\n";
  }
  else {
    print "Location: $home_url?index=$FORM{index}&sid=$FORM{sid}&SHOPORDERNUMBER=$FORM{SHOPORDERNUMBER}" . "\n\n";
  }

  exit;
}

#**********************************************************
#MerID=100000000918471
#OrderID=test00000001g5hg45h45
#AcqID=414963
#Signature=e2DkM6RYyNcn6+okQQX2BNeg/+k=
#ECI=5
#IP=217.117.65.41
#CountryBIN=804
#CountryIP=804
#ONUS=1
#Time=22/01/2007 13:56:38
#Signature2=nv7CcUe5t9vm+uAo9a52ZLHvRv4=
#ReasonCodeDesc=Transaction is approved.
#ResponseCode=1
#ReasonCode=1
#ReferenceNo=702308304646
#PaddedCardNo=XXXXXXXXXXXX3982
#AuthCode=073291
#**********************************************************
sub privatbank_payments {

  #Get order
  my $status            = 0;
  my $payment_system    = 'PBANK';
  my $payment_system_id = 48;
  my $order_id          = $FORM{orderid};

  my $list = $Paysys->list(
    {
      TRANSACTION_ID => "$payment_system:$order_id",
      STATUS         => 1,
      COLS_NAME      => 1
    }
  );

  if ($Paysys->{TOTAL} > 0) {
    if ($FORM{reasoncode} == 1) {
      my $uid  = $list->[0]->{uid};
      my $sum  = $list->[0]->{sum};
      my $user = $users->info($uid);
      $payments->add(
        $user,
        {
          SUM          => $sum,
          DESCRIBE     => $payment_system,
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$order_id",
          CHECK_EXT_ID => "$payment_system:$order_id"
        }
      );

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status = 8;
      }
      elsif ($payments->{errno}) {
        $status = 4;
      }
      else {
        $Paysys->change(
          {
            ID        => $list->[0]{id},
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => "ReasonCode: $FORM{reasoncode}\n Authcode: $FORM{authcode}\n PaddedCardNo:$FORM{paddedcardno}\n ResponseCode: $FORM{responsecode}\n ReasonCodeDesc: $FORM{reasoncodedesc}\n IP: $FORM{IP}\n Signature:$FORM{signature}",
            STATUS    => 2
          }
        );
      }

      if ($conf{PAYSYS_EMAIL_NOTICE}) {
        my $message = "\n" . "System: Privat Bank\n" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $list->[0][0]\n" . "SUM: $sum\n";

        sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Privat Bank Add", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
      }
    }
    else {
    	my $status = 6;

    	if ($FORM{reasoncode}==36) {
    		$status=3;
    	}

      $Paysys->change(
        {
          ID        => $list->[0]{id},
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => "ReasonCode: $FORM{reasoncode}. $FORM{reasoncodedesc} responsecode: $FORM{responsecode}",
          STATUS    => $status
        }
      );
    }
  }

  my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};
  $home_url =~ s/paysys_check.cgi/index.cgi/;

  if ($FORM{ResponseCode} == 1 || $FORM{responsecode} == 1) {
    print "Location: $home_url?PAYMENT_SYSTEM=48&orderid=$FORM{orderid}&TRUE=1" . "\n\n";
  }
  else {
    #print "Content-Type: text/html\n\n";
    #print "FAILED PAYSYS: Portmone SUM: $FORM{BILL_AMOUNT} ID: $FORM{SHOPORDERNUMBER} STATUS: $status";
    print "Location:$home_url?PAYMENT_SYSTEM=48&orderid=$FORM{orderid}&FALSE=1&reasoncodedesc=$FORM{reasoncodedesc}&reasoncode=$FORM{reasoncode}&responsecode=$FORM{responsecode}" . "\n\n";
  }

  exit;
}

#**********************************************************
# OSMP / Pegas
#**********************************************************
sub osmp_payments {
  my ($attr) = @_;

  if ($conf{PAYSYS_PEGAS_PASSWD}) {
    my ($user, $password) = split(/:/, $conf{PAYSYS_PEGAS_PASSWD});

    if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));
      if ( (!$REMOTE_PASSWD)
        || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
        || (!$REMOTE_USER)
        || ($REMOTE_USER   && $REMOTE_USER   ne $user))
      {
        print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
        print "Status: 401 Unauthorized\n";
        print "Content-Type: text/html\n\n";
        print "Access Deny";
        exit;
      }
    }
  }
  
  if ($debug > 1) {
  	print "Content-Type: text/plain\n\n";
  }
  
  print "Content-Type: text/xml\n\n";

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'OSMP';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 44;
  my $CHECK_FIELD       = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || $attr->{CHECK_FIELDS} || 'UID';
  my $txn_id = 'osmp_txn_id';

  my %status_hash = (
    0 => 'Success',
    1 => 'Temporary DB error',
    4 => 'Wrong client indentifier',
    5 => 'Failed witness a signature',
    6 => 'Unknown terminal',
    7 => 'Payments deny',

    8   => 'Double request',
    9   => 'Key Info mismatch',
    79  => 'Счёт абонента не активен',
    300 => 'Unknown error',
  );

  #For pegas
  if ($conf{PAYSYS_PEGAS} && $ENV{REMOTE_ADDR} ne '213.186.115.164') {
    $txn_id            = 'txn_id';
    $payment_system    = 'PEGAS';
    $payment_system_id = 49;
    $status_hash{5}    = 'Неверный индентификатор абонента';
    $status_hash{243}  = 'Невозможно проверитьсостояние счёта';
    $CHECK_FIELD       = $conf{PAYSYS_PEGAS_ACCOUNT_KEY} || 'UID';
    
    if ($conf{PAYSYS_PEGAS_SELF_TERMINALS} && $FORM{terminal}) {
      if ($conf{PAYSYS_PEGAS_SELF_TERMINALS} =~ /$FORM{terminal}/) {
        $payment_system_id = 80;
        $payment_system    = 'PST';
      }
    }
  }

  my $comments = '';
  my $command  = $FORM{command};

  if ($FORM{account} && $CHECK_FIELD eq 'UID') {
    $FORM{account} =~ s/^0+//g; 
  }
  elsif ($FORM{account} && $CHECK_FIELD eq 'LOGIN' && $conf{PAYSYS_OSMP_ACCOUNT_RULE}) {
    $FORM{account} = sprintf($conf{PAYSYS_OSMP_ACCOUNT_RULE},$FORM{account}) ;
  }
  
  my %RESULT_HASH = (result => 300);
  my $results = '';

  mk_log("$payment_system: $ENV{QUERY_STRING}") if ($debug > 0);
  #Check user account
  #https://service.someprovider.ru:8443/paysys_check.cgi?command=check&txn_id=1234567&account=0957835959&sum=10.45
  if ($command eq 'check') {
    my $list = $users->list({ $CHECK_FIELD  => $FORM{account}, 
    	                        DISABLE_PAYSYS=> '_SHOW',
    	                        GROUP_NAME    => '_SHOW',
    	                        COLS_NAME     => 1 
    	                      });

    if ($payment_system_id == 44 && !$FORM{sum}) {
      $status = 300;
    }
    elsif ($users->{errno}) {
      $status = 300;
    }
    elsif ($users->{TOTAL} < 1) {
      if ($CHECK_FIELD eq 'UID' && $FORM{account} !~ /\d+/) {
        $status = 4;
      }
      elsif ($FORM{account} !~ /$conf{USERNAMEREGEXP}/) {
        $status = 4;
      }
      else {
        $status = 5;
      }
      $comments = 'User Not Exist';
    }
    else {
      $status = 0;
    }

    $RESULT_HASH{result} = $status;

    if ($list->[0]->{disable_paysys}) {
    	$RESULT_HASH{disable_paysys}=1;
    }

    #For OSMP
    if ($payment_system_id == 44) {
      $RESULT_HASH{$txn_id} = $FORM{txn_id};
      $RESULT_HASH{prv_txn} = $FORM{prv_txn};
      $RESULT_HASH{comment} = "Balance: $list->[0]->{deposit}" if ($status == 0);
    }
  }

  #Cancel payments
  elsif ($command eq 'cancel') {
    my $prv_txn = $FORM{prv_txn};
    $RESULT_HASH{prv_txn} = $prv_txn;

    my $list = $payments->list({ ID        => "$prv_txn", 
                                 EXT_ID    => "PEGAS:*",
                                 BILL_ID   => '_SHOW',
                                 COLS_NAME => 1 });

    if ($payments->{errno} && $payments->{errno} != 7) {
      $RESULT_HASH{result} = 1;
    }
    elsif ($payments->{TOTAL} < 1) {
      if ($conf{PAYSYS_PEGAS}) {
        $RESULT_HASH{result} = 0;
      }
      else {
        $RESULT_HASH{result} = 79;
      }
    }
    else {
      my %user = (
        BILL_ID => $list->{bill_id},
        UID     => $list->{uid}
      );

      $payments->del(\%user, $prv_txn);
      if (!$payments->{errno}) {
        $RESULT_HASH{result} = 0;
      }
      else {
        $RESULT_HASH{result} = 1;
      }
    }
  }
  elsif ($command eq 'balance') {

  }

  #https://service.someprovider.ru:8443/payment_app.cgi?command=pay&txn_id=1234567&txn_date=20050815120133&account=0957835959&sum=10.45
  elsif ($command eq 'pay') {
    my $user;
    my $payments_id = 0;

    if ($CHECK_FIELD eq 'UID') {
      $user = $users->info($FORM{account});
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $FORM{account}, COLS_NAME => 1 });
      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->{uid};
        $user = $users->info($uid);
      }
    }

    if ($users->{errno}) {
      $status = ($users->{errno} == 2) ? 5 : 300;
    }
    elsif ($users->{TOTAL} < 1) {
      $status = 4;
    }
    elsif (!$FORM{sum}) {
      $status = 300;
    }
    else {
      cross_modules_call('_pre_payment', 
            {
              USER_INFO  => $user,
              SUM        => $FORM{sum},
              QUITE      => 1
            }
       );

      my $er = 1;
      if ($conf{PAYSYS_OSMP_CURRENCY}) {
        $payments->exchange_info(0, { ISO => $conf{PAYSYS_OSMP_CURRENCY} });
        if ($payments->{TOTAL} > 0) {
          $er = $payments->{ER_RATE};
        }
      }

      #Add payments
      $payments->add(
        $user,
        {
          SUM          => $FORM{sum},
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$FORM{txn_id}",
          CHECK_EXT_ID => "$payment_system:$FORM{txn_id}",
          ER           => $er
        }
      );

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status      = 0;
        $payments_id = $payments->{ID};
      }
      elsif ($payments->{errno}) {
        $status = 4;
      }
      else {
        $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;
        $status = 0;
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "'$DATE $TIME'",
            SUM            => "$FORM{sum}",
            UID            => "$user->{UID}",
            IP             => $ENV{REMOTE_ADDR},
            TRANSACTION_ID => "$payment_system:$FORM{txn_id}",
            INFO           => "TYPE: $FORM{command}\nPS_TIME: " . (($FORM{txn_date}) ? $FORM{txn_date} : '') . "\nSTATUS: $status $status_hash{$status}\n". (($FORM{terminal}) ? "Terminal: $FORM{terminal}" : ''),
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 2
          }
        );
        
        cross_modules_call('_payments_maked', { USER_INFO => $user, 
                                                SUM       => $FORM{sum},
                                                QUITE     => 1 });
      }
    }

    $RESULT_HASH{result}  = $status;
    $RESULT_HASH{$txn_id} = $FORM{txn_id};
    $RESULT_HASH{prv_txn} = $payments_id;
    $RESULT_HASH{sum}     = $FORM{sum};
  }

  #Result output
  $RESULT_HASH{comment} = $status_hash{ $RESULT_HASH{result} } if ($RESULT_HASH{result} && !$RESULT_HASH{comment});

  while (my ($k, $v) = each %RESULT_HASH) {
    $results .= "<$k>$v</$k>\n";
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<response>
$results
</response>
};

  print $response;
  if ($debug > 0) {
    mk_log("$response", { PAYSYS_ID => "$attr->{SYSTEM_ID}/$attr->{SYSTEM_SHORT_NAME}" });
  }

  exit;
}

#**********************************************************
# OSMP
# protocol-version 4.00
# IP 92.125.xxx.xxx
# $conf{PAYSYS_OSMP_LOGIN}
# $conf{PAYSYS_OSMP_PASSWD}
# $conf{PAYSYS_OSMP_SERVICE_ID}
# $conf{PAYSYS_OSMP_TERMINAL_ID}
#
#**********************************************************
sub osmp_payments_v4 {
  my ($attr) = @_;

  my $version = '0.2';
  $debug = 1;
  print "Content-Type: text/xml\n\n";

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'OSMP';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 61;

  my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';
  $FORM{__BUFFER} = '' if (!$FORM{__BUFFER});
  $FORM{__BUFFER} =~ s/data=//;

  eval { require XML::Simple; };
  if (!$@) {
    XML::Simple->import();
  }
  else {
    print "Content-Type: text/html\n\n";
    print "Can't load 'XML::Simple' check http://www.cpan.org";
    exit;
  }

  $FORM{__BUFFER} =~ s/encoding="windows-1251"//g;
  my $_xml = eval { XMLin("$FORM{__BUFFER}", forcearray => 1) };

  if ($@) {
    mk_log("---- Content:\n" . $FORM{__BUFFER} . "\n----XML Error:\n" . $@ . "\n----\n");

    return 0;
  }
  else {
    if ($debug == 1) {
      mk_log($FORM{__BUFFER});
    }
  }

  my %request_hash = ();
  my $request_type = '';

  my $status_id    = 0;
  my $result_code  = 0;
  my $service_id   = 0;
  my $response     = '';

  my $BALANCE      = 0.00;
  my $OVERDRAFT    = 0.00;
  my $txn_date     = "$DATE$TIME";
  $txn_date        =~ s/[-:]//g;
  my $txn_id       = 0;

  $request_hash{'protocol-version'} = $_xml->{'protocol-version'}->[0];
  $request_hash{'request-type'}     = $_xml->{'request-type'}->[0] || 0;
  $request_hash{'terminal-id'}      = $_xml->{'terminal-id'}->[0];
  $request_hash{'login'}            = $_xml->{'extra'}->{'login'}->{'content'};
  $request_hash{'password'}         = $_xml->{'extra'}->{'password'}->{'content'};
  $request_hash{'password-md5'}     = $_xml->{'extra'}->{'password-md5'}->{'content'};
  $request_hash{'client-software'}  = $_xml->{'extra'}->{'client-software'}->{'content'};
  my $transaction_number            = $_xml->{'transaction-number'}->[0] || '';

  $request_hash{'to'} = $_xml->{to};

  if ($request_hash{'password-md5'}) {
    $md5->reset;
    $md5->add($conf{PAYSYS_OSMP_PASSWD});
    $conf{PAYSYS_OSMP_PASSWD} = lc($md5->hexdigest());
  }

  if ($conf{PAYSYS_OSMP_LOGIN} ne $request_hash{'login'}
    || ($request_hash{'password'} && $conf{PAYSYS_OSMP_PASSWD} ne $request_hash{'password'}))
  {
    $status_id   = 150;
    $result_code = 1;

    $response = qq{
<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
};
  }
  elsif (defined($_xml->{'status'})) {
    my $count           = $_xml->{'status'}->[0]->{count};
    my @payments_arr    = ();
    my %payments_status = ();

    for (my $i = 0 ; $i < $count ; $i++) {
      push @payments_arr, $_xml->{'status'}->[0]->{'payment'}->[$i]->{'transaction-number'}->[0];
    }

    my $ext_ids = "'$payment_system:" . join("', '$payment_system:", @payments_arr) . "'";
    my $list = $payments->list({ EXT_IDS => $ext_ids, PAGE_ROWS => 100000 });

    if ($payments->{errno}) {
      $status_id = 78;
    }
    else {
      foreach my $line (@$list) {
        my $ext = $line->[7];
        $ext =~ s/$payment_system://g;
        $payments_status{$ext} = $line->[0];
      }

      foreach my $id (@payments_arr) {
        if ($id < 1) {
          $status_id = 160;
        }
        elsif ($payments_status{$id}) {
          $status_id = 60;
        }
        else {
          $status_id = 10;
        }

        $response .= qq{
<payment transaction-number="$id" status="$status_id" result-code="0" final-status="true" fatal-error="true">
</payment>\n };
      }
    }
  }

  #User info
  elsif ($request_hash{'request-type'} == 1) {
    my $to             = $request_hash{'to'}->[0];
    my $amount         = $to->{'amount'}->[0];
    my $sum            = $amount->{'content'};
    my $currency       = $amount->{'currency-code'};
    my $account_number = $to->{'account-number'}->[0];
    my $service_id     = $to->{'service-id'}->[0];
    my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

    my $user;
    my $payments_id = 0;

    if ($account_number !~ /$conf{USERNAMEREGEXP}/) {
      $status_id   = 4;
      $result_code = 1;
    }
    elsif ($CHECK_FIELD eq 'UID') {
      $user      = $users->info($account_number);
      $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
      $OVERDRAFT = $user->{CREDIT};
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $account_number });

      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->[ 5 + $users->{SEARCH_FIELDS_COUNT} ];
        $user      = $users->info($uid);
        $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
        $OVERDRAFT = $user->{CREDIT};
      }
    }

    if ($users->{errno}) {
      $status_id   = 79;
      $result_code = 1;
    }
    elsif ($users->{TOTAL} < 1) {
      $status_id   = 5;
      $result_code = 1;
    }

    $response = qq{
<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
<from>
<service-id>$service_id</service-id>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>1</service-id>
<amount>amount</amount>
<account-number>$account_number</account-number>
<extra name="FIO">$user->{FIO}</extra>
</to>};
  }

  # Payments
  elsif ($request_hash{'request-type'} == 2) {
    my $to             = $request_hash{'to'}->[0];
    my $amount         = $to->{'amount'}->[0];
    my $sum            = $amount->{'content'};
    my $currency       = $amount->{'currency-code'};
    my $account_number = $to->{'account-number'}->[0];
    my $service_id     = $to->{'service-id'}->[0];
    my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

    my $txn_id = 0;
    my $user;
    my $payments_id = 0;

    if ($CHECK_FIELD eq 'UID') {
      $user      = $users->info($account_number);
      $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
      $OVERDRAFT = $user->{CREDIT};
    }
    else {
      my $list = $users->list({ $CHECK_FIELD => $account_number });

      if (!$users->{errno} && $users->{TOTAL} > 0) {
        my $uid = $list->[0]->[ 5 + $users->{SEARCH_FIELDS_COUNT} ];
        $user      = $users->info($uid);
        $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
        $OVERDRAFT = $user->{CREDIT};
      }
    }

    if ($users->{errno}) {
      $status_id   = 79;
      $result_code = 1;
    }
    elsif ($users->{TOTAL} < 1) {
      $status_id   = 5;
      $result_code = 1;
    }
    else {
      cross_modules_call('_pre_payment', { USER_INFO => $user, QUITE => 1, SUM => $sum });
      #Add payments
      $payments->add(
        $user,
        {
          SUM          => $sum,
          DESCRIBE     => "$payment_system",
          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2',
          EXT_ID       => "$payment_system:$transaction_number",
          CHECK_EXT_ID => "$payment_system:$transaction_number"
        }
      );

      cross_modules_call('_payments_maked', { USER_INFO => $user, SUM => $sum, QUITE => 1 });

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status_id   = 10;
        $result_code = 1;
        $payments_id = $payments->{ID};
      }
      elsif ($payments->{errno}) {
        $status_id   = 78;
        $result_code = 1;
      }
      else {
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "'$DATE $TIME'",
            SUM            => "$sum",
            UID            => "$user->{UID}",
            IP             => '0.0.0.0',
            TRANSACTION_ID => "$payment_system:$transaction_number",
            INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
          }
        );

        $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
        $txn_id = $payments_id;
      }
    }

    $response = qq{
<txn-date>$txn_date</txn-date>
<txn-id>$txn_id</txn-id>
<receipt>
<datetime>0</datetime>
</receipt>
<from>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
}
  }

  # Pack processing
  elsif ($request_hash{'request-type'} == 10) {
    my $count        = $_xml->{auth}->[0]->{count};
    my $final_status = '';
    my $fatal_error  = '';

    for ($i = 0 ; $i < $count ; $i++) {
      my %request_hash = %{ $_xml->{auth}->[0]->{payment}->[$i] };
      my $to           = $request_hash{'to'}->[0];
      $transaction_number = $request_hash{'transaction-number'}->[0] || '';

      #    my $amount         = $to->{'amount'}->[0];
      my $sum = $to->{'amount'}->[0];

      #    my $currency       = $amount->{'currency-code'};
      my $account_number = $to->{'account-number'}->[0];
      my $service_id     = $to->{'service-id'}->[0];
      my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

      if ($CHECK_FIELD eq 'UID') {
        $user      = $users->info($account_number);
        $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
        $OVERDRAFT = $user->{CREDIT};
      }
      else {
        my $list = $users->list({ $CHECK_FIELD => $account_number });

        if (!$users->{errno} && $users->{TOTAL} > 0) {
          my $uid = $list->[0]->[ 5 + $users->{SEARCH_FIELDS_COUNT} ];
          $user      = $users->info($uid);
          $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
          $OVERDRAFT = $user->{CREDIT};
        }
      }

      if ($users->{errno}) {
        $status_id   = 79;
        $result_code = 1;
      }
      elsif ($users->{TOTAL} < 1) {
        $status_id   = 0;
        $result_code = 0;
      }
      else {
        cross_modules_call('_pre_payment', 
            {
              USER_INFO  => $user,
              SUM        => $FORM{PAY_AMOUNT},
              QUITE      => 1
            }
        );

        #Add payments
        $payments->add(
          $user,
          {
            SUM          => $sum,
            DESCRIBE     => "$payment_system",
            METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2',
            EXT_ID       => "$payment_system:$transaction_number",
            CHECK_EXT_ID => "$payment_system:$transaction_number"
          }
        );

        #Exists
        if ($payments->{errno} && $payments->{errno} == 7) {
          $status_id   = 10;
          $result_code = 1;
          $payments_id = $payments->{ID};
        }
        elsif ($payments->{errno}) {
          $status_id   = 78;
          $result_code = 1;
        }
        else {
          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "'$DATE $TIME'",
              SUM            => "$sum",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system:$transaction_number",
              INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
            }
          );

          $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
          $txn_id      = $payments_id;
          $status_id   = 51;
        }
      }

      $fatal_error = ($status_id != 51 && $status_id != 0) ? 'true' : 'false';
      $response .= qq{
<payment status="$status_id" transaction-number="$transaction_number" result-code="$result_code" final-status="true"fatal-error="$fatal_error">
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
</payment>
  
};

    }
  }

  my $output = qq{<?xml version="1.0" encoding="windows-1251"?>
<response requestTimeout="60">
<protocol-version>4.00</protocol-version>
<configuration-id>0</configuration-id>
<request-type>$request_hash{'request-type'}</request-type>
<terminal-id>$request_hash{'terminal-id'}</terminal-id>
<transaction-number>$transaction_number</transaction-number>
<status-id>$status_id</status-id>
};

  $output .= $response . qq{
 <operator-id>$admin->{AID}</operator-id>
 <extra name="REMOTE_ADDR">$ENV{REMOTE_ADDR}</extra>
 <extra name="client-software">ABillS Paysys $payment_system $version</extra>
 <extra name="version-conf">$version</extra>
 <extra name="serial">$version</extra>
 <extra name="BALANCE">$BALANCE</extra>
 <extra name="OVERDRAFT">$OVERDRAFT</extra>
</response>};

  print $output;

  if ($debug > 0) {
    mk_log("RESPONSE:\n" . $output);
  }

  return $status_id;
}

#**********************************************************
#
#**********************************************************
sub smsproxy_payments {

  #https//demo.abills.net.ua:9443/paysys_check.cgi?skey=827ccb0eea8a706c4c34a16891f84e7b&smsid=1208992493215&num=1171&operator=Tester&user_id=1234567890&cost=1.5&msg=%20Test_messages
  my $sms_num = $FORM{num}      || 0;
  my $cost    = $FORM{cost_rur} || 0;
  my $skey    = $FORM{skey}     || '';
  my $prefix  = $FORM{prefix}   || '';

  my %prefix_keys = ();
  my $service_key = '';

  if ($conf{PAYSYS_SMSPROXY_KEYS} && $conf{PAYSYS_SMSPROXY_KEYS} =~ /:/) {
    my @keys_arr = split(/,/, $conf{PAYSYS_SMSPROXY_KEYS});

    foreach my $line (@keys_arr) {
      my ($num, $key) = split(/:/, $line);
      if ($num eq $sms_num) {
        $prefix_keys{$num} = $key;
        $service_key = $key;
      }
    }
  }
  else {
    $prefix_keys{$sms_num} = $conf{PAYSYS_SMSPROXY_KEYS};
    $service_key = $conf{PAYSYS_SMSPROXY_KEYS};
  }

  $md5->reset;
  $md5->add($service_key);
  my $digest = $md5->hexdigest();

  print "smsid: $FORM{smsid}\n";

  if ($digest ne $skey) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "Wrong key!\n";
    return 0;
  }

  my $code = mk_unique_value(8);

  #Info section
  my ($transaction_id, $m_secs) = split(/\./, $FORM{smsid}, 2);

  my $er = 1;
  $payments->exchange_info(0, { SHORT_NAME => "SMSPROXY" });
  if ($payments->{TOTAL} > 0) {
    $er = $payments->{ER_RATE};
  }

  if ($payments->{errno}) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "PAYMENT ERROR: $payments->{errno}!\n";
    return 0;
  }

  $Paysys->add(
    {
      SYSTEM_ID      => 43,
      DATETIME       => "'$DATE $TIME'",
      SUM            => "$cost",
      UID            => "",
      IP             => "0.0.0.0",
      TRANSACTION_ID => "$transaction_id",
      INFO           => "ID: $FORM{smsid}, NUM: $FORM{num}, OPERATOR: $FORM{operator}, USER_ID: $FORM{user_id}",
      PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
      CODE           => $code
    }
  );

  if ($Paysys->{errno} && $Paysys->{errno} == 7) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "Request dublicated $FORM{smsid}\n";
    return 0;
  }

  print "status:reply\n";
  print "content-type: text/plain\n\n";
  print $conf{PAYSYS_SMSPROXY_MSG} if ($conf{PAYSYS_SMSPROXY_MSG});
  print " CODE: $code";

}


#**********************************************************
# https://merchant.webmoney.ru/conf/guide.asp
#
#**********************************************************
sub wm_payments {
  my ($attr) = @) = @_;

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'WM';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 41;
  my $status_code = 0;

  #Pre request section
  if ($FORM{'LMI_PREREQUEST'} && $FORM{'LMI_PREREQUEST'} == 1) {

  }
  #Payment notification
  elsif ($FORM{LMI_HASH}) {
    my $checksum = wm_validate();
    my $info     = '';
    my $user     = $users->info($FORM{UID});

    my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});

    if (!in_array($FORM{LMI_PAYEE_PURSE}, \@ACCOUNTS)) {
      $status = 'Not valid money account';
    }
    elsif (defined($FORM{LMI_MODE}) && $FORM{LMI_MODE} == 1) {
      $status = 'Test mode';
      $status_code = 12;
    }
    elsif (length($FORM{LMI_HASH}) != 32) {
      $status = 'Not MD5 checksum' . $FORM{LMI_HASH};
      $status_code = 5;
    }
    elsif ($FORM{LMI_HASH} ne $checksum) {
      $status = "Incorect checksum \"$checksum/$FORM{LMI_HASH}\"";
      $status_code = 5;
    }
    elsif ($user->{errno}) {
      $status = "ERROR: $user->{errno}";
      $status_code = 11;
    }
    elsif ($user->{TOTAL} < 0) {
      $status = "User not exist";
      $status_code = 9;
    }
    else {

      #Add payments
      my $er = 1;
      if ($FORM{LMI_PAYEE_PURSE} =~ /^(\S)/) {
        my $payment_unit = 'WM' . $1;
        $payments->exchange_info(0, { SHORT_NAME => "$payment_unit" });
        if ($payments->{TOTAL} > 0) {
          $er = $payments->{ER_RATE};
        }
      }

      #my $er = ($FORM{'5.ER'}) ? $payments->exchange_info() : { ER_RATE => 1 } ;
      my $pay_describe = ($FORM{LMI_PAYMENT_DESC} && $conf{dbcharset} eq 'utf8') ? convert($FORM{LMI_PAYMENT_DESC}, { win2utf8 => 1 }) : 'Webmoney';
      $payments->add(
        $user,
        {
          SUM      => $FORM{LMI_PAYMENT_AMOUNT},
          DESCRIBE => $pay_describe,
          METHOD   => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID   => $FORM{LMI_PAYMENT_NO},
          ER       => $er
        }
      );

      if ($payments->{errno}) {
        $info = "PAYMENT ERROR: $payments->{errno}\n";
        $status_code = 7;
      }
      else {
        $status = "Added $payments->{INSERT_ID}\n";
        $status_code = 2;
      }
    }

    while (my ($k, $v) = each %FORM) {
      $info .= "$k, $v\n" if ($k =~ /^LMI/);
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        SUM            => $FORM{LMI_PAYMENT_AMOUNT},
        UID            => $FORM{UID},
        IP             => $FORM{IP},
        TRANSACTION_ID => "$FORM{LMI_PAYMENT_NO}",
        INFO           => "STATUS, $status\n$info",
        PAYSYS_IP      => $status_code2
      }
    );

    cross_modules_call('_payments_maked', { USER_INFO => $user, SUM => $FORM{LMI_PAYMENT_AMOUNT}, QUITE => 1 });

    $output2 .= "Paysys:" . $Paysys->{errno} if ($Paysys->{errno});
    $output2 .= "CHECK_SUM: $checksum\n";
  }

}

#**********************************************************
# Read Public Key
#**********************************************************
sub read_public_key {
  my ($filename) = @_;
  my $cert = "";

  open(CERT, "$filename") || die "Can't open '$filename' $!\n";
  while (<CERT>) {
    $cert .= $_;
  }
  close CERT;

  return $cert;
}

#**********************************************************
# Error Trap
#**********************************************************
sub err_trap {
  my ($err_code, $error) = @_;
  print "code=$err_code";
  die "Paysys database error: $error\n";
}

#**********************************************************
# Get Date
#**********************************************************
sub get_date {
  my ($sec, $min, $hour, $mday, $mon, $year) = (localtime time)[ 0, 1, 2, 3, 4, 5 ];
  $year -= 100;
  $mon++;
  $year = "0$year" if $year < 10;
  $mday = "0$mday" if $mday < 10;
  $mon  = "0$mon"  if $mon < 10;
  $hour = "0$hour" if $hour < 10;
  $min  = "0$min"  if $min < 10;
  $sec  = "0$sec"  if $sec < 10;

  return "$mday.$mon.$year $hour:$min:$sec";
}

#**********************************************************
# Webmoney MD5 validate
#**********************************************************
sub wm_validate {
  $md5->reset;

  $md5->add($FORM{LMI_PAYEE_PURSE});
  $md5->add($FORM{LMI_PAYMENT_AMOUNT});
  $md5->add($FORM{LMI_PAYMENT_NO});
  $md5->add($FORM{LMI_MODE});
  $md5->add($FORM{LMI_SYS_INVS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_DATE});
  $md5->add($conf{PAYSYS_LMI_SECRET_KEY});

  #$md5->add($FORM{LMI_SECRET_KEY});
  $md5->add($FORM{LMI_PAYER_PURSE});
  $md5->add($FORM{LMI_PAYER_WM});

  my $digest = uc($md5->hexdigest());

  return $digest;
}


#**********************************************************
#
#**********************************************************
sub yandex () {
  my ($attr)=@_;
  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'Yandex';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 73;
  
  print "Location: https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?get_index=paysys_payment&PAYMENT_SYSTEM=$payment_system_id&code=$FORM{code}\n\n";
}

#**********************************************************
# get_fees_types
#
# return $Array_ref
#**********************************************************
sub get_fees_types {
  my ($attr) = @_;

  use Finance;
  my %FEES_METHODS = ();
  my $fees         = Finance->fees($db, $admin, \%conf);
  my $list         = $fees->fees_type_list({ PAGE_ROWS => 10000 });
  foreach my $line (@$list) {
    if ($FORM{METHOD} && $FORM{METHOD} == $line->[0]) {
      $FORM{SUM}      = $line->[3] if ($line->[3] > 0);
      $FORM{DESCRIBE} = $line->[2] if ($line->[2]);
    }

    $FEES_METHODS{ $line->[0] } = (($line->[1] =~ /\$/) ? eval($line->[1]) : $line->[1]) . (($line->[3] > 0) ? (($attr->{SHORT}) ? ":$line->[3]" : " ($_SERVICE $_PRICE: $line->[3])") : '');
  }

  return \%FEES_METHODS;
}


#**********************************************************
#
#**********************************************************
sub interact_mode() {
	load_module('Paysys', $html);

  require "../language/$html->{language}.pl";
  $html->{NO_PRINT} = 1;
  $LIST_PARAMS{UID} = $FORM{UID};
  
  print paysys_payment();	

}


1
