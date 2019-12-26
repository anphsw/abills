#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

=head1 NAME

  sms_callback.cgi

=head1 SYNOPSIS

  sms_callback.cgi is to receive incoming SMS from gateway

=cut

BEGIN {
  print "Content-Type: text/html\n\n";
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/abills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift (@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/abills dir \n";
  }
}

use Abills::Init qw/$db $admin %conf $users @MODULES $DATE $TIME/;
use Abills::HTML;
use Abills::Base qw/_bp startup_files cmd ssh_cmd int2byte/;
use Abills::Misc;
use Abills::Defs;
use Companies;
use Internet;
use Internet::Sessions;
use Log;

our %lang;

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
#    LANG => \%lang,
  }
);

if($conf{SMS_CALLBACK_LANGUAGE}){
  $html->{language} = $conf{SMS_CALLBACK_LANGUAGE};
}

do "../language/english.pl";
do "../language/$html->{language}.pl";

my $Log = Log->new($db, \%conf, {LOG_FILE => '/usr/abills/var/log/sms_callback.log', SILENT => 1});

my %STATUSES = (
  '0' => 'active',
  '3' => 'hold up',
);

our %FORM;
%FORM = form_parse();
$FORM{text} //= $FORM{content};
$FORM{sender} //= $FORM{from};

# Check required params
for my $param_name ('apikey', 'sender', 'text') {
  exit_with_error(400, "No $param_name given") if (!$FORM{$param_name});
}

# Do auth
$admin->info(undef, { API_KEY => $FORM{apikey} });
exit_with_error(401, "Invalid apikey") unless $admin->{AID};

my @sms_args = split('\+', $FORM{text});

#Hotspot
if ($sms_args[0] eq "ICNFREEHS" || $sms_args[0] eq "ICNHS") {
  my $cid = $sms_args[1];
  if ($cid !~ /^[0-9A-F]{12}$/) {
    show_command_result(0, '');
    exit;
  }
  $cid =~ s/(.{2})(.{2})(.{2})(.{2})(.{2})(.{2})/$1:$2:$3:$4:$5:$6/;
  my ($uid, $phone) = get_user_info($cid);
  use Hotspot;
  my $Hotspot = Hotspot->new($db, $admin, \%conf);
  if ($sms_args[0] eq "ICNFREEHS" && $uid && !$phone) {
    set_user_phone($uid, $FORM{sender});
    sms_payment($uid, 1);
    $Hotspot->log_add({
      HOTSPOT  => '',
      CID      => $cid,
      ACTION   => 22,
      PHONE    => $FORM{sender},
      COMMENTS => "User $uid use $sms_args[0]"
    });
  }
  elsif ($sms_args[0] eq "ICNHS" && $uid) {
    sms_payment($uid, 2);
    $Hotspot->log_add({
      HOTSPOT  => '',
      CID      => $cid,
      ACTION   => 23,
      PHONE    => $FORM{sender},
      COMMENTS => "User $uid use $sms_args[0]"
    });
  }
  show_command_result(0, '');
  exit;
}

my $uid = $sms_args[0];
my $additional_info = $sms_args[2];

# Find user
my $user_object = check_user($FORM{sender}, $sms_args[0]);

if ($sms_args[1] eq '01') {
  send_user_memo($user_object);
}
elsif ($sms_args[1] eq '02') {
  send_internet_info($user_object);
}
elsif ($sms_args[1] eq '03') {
  start_external_command($user_object);
}
elsif ($sms_args[1] eq '04') {
  hold_up_user($user_object)
}
elsif ($sms_args[1] eq '05') {
  activate_user($user_object);
}
elsif ($sms_args[1] eq '06') {
  money_transfer($user_object, $sms_args[2], $sms_args[3]);
  show_command_result(0, '');
}

exit 0;

#**********************************************************
=head2 exit_with_error($code, $string)

=cut
#**********************************************************
sub exit_with_error {
  my ($code, $string) = @_;
  if ($conf{SMS_UNIVERSAL_URL}) {
    print "ACK/Jasmin\n";
    exit 0;
  }

  my %error_explanation = (
    400 => 'Bad request',
    401 => 'Unauthorized',
  );

  print "Status: $code " . ($error_explanation{$code} || '') . "\n";
  print "Content-Length: " . length($string) . "\n";
  print "Content-Type: text/html\n\n";
  print $string;

  $Log->log_print('LOG_ERR', '', $string);

  exit 0;
}

#**********************************************************
=head2 send_user_memo($user)

  Arguments:
    $user - user Object

  Returns:

=cut
#**********************************************************
sub send_user_memo {
  my ($user) = @_;
  my $code   = 0;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $company_info = {};

  if ($user->{COMPANY_ID}) {
    my $Company = Companies->new($db, $admin, \%conf);
    $company_info = $Company->info($user->{company_id});
  }

  my $internet_info = $Internet->info($user->{uid});
  my $pi = $users->pi({ UID => $uid });

  $internet_info->{PASSWORD} = $user->{PASSWORD} if (!$internet_info->{PASSWORD});
  $internet_info->{LOGIN} = $user->{LOGIN} if (!$internet_info->{LOGIN});

  my $message = $html->tpl_show('', { %$user, %$internet_info, %$pi, %$company_info },
    { TPL => 'internet_user_memo_sms', MODULE => 'Internet', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKSERS => 1 });

  load_module('Sms');

  my $sms_id = sms_send(
    {
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

  if(!$sms_id){
    $code = 2;
    $message = 'User memo didnt send'
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 send_internet_info($user)

  Arguments:
    $user - user Object

  Returns:

=cut
#**********************************************************
sub send_internet_info {
  my ($user) = @_;
  my %INFO_HASH;
  my $code = 0;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $internet_info = $Internet->info($user->{uid});
  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

  $Sessions->prepaid_rest(
    {
      UID  => ($Internet->{JOIN_SERVICE} && $Internet->{JOIN_SERVICE} > 1) ? $Internet->{JOIN_SERVICE} : $user->{uid},
      UIDS => $user->{uid}
    }
  );

  my $list = $Sessions->{INFO_LIST};
  my $rest = $Sessions->{REST};

  my $traffic_rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $rest->{ $list->[0]{interval_id} }->{ $list->[0]{traffic_class} }  :  $rest->{ $list->[0]{traffic_class} };


  my $hash_statuses = sel_status({ HASH_RESULT => 1 });
  my $status_describe;

  $status_describe = $hash_statuses->{$internet_info->{STATUS}} if ($hash_statuses->{$internet_info->{STATUS}});
  my ($status, undef) = split('\:', $status_describe);

  $INFO_HASH{DEPOSIT}      = sprintf("%.3f", $user->{deposit});
  $INFO_HASH{TP_NAME}      = $internet_info->{TP_NAME};
  $INFO_HASH{STATUS_NAME}  = $status;
  $INFO_HASH{REST_TRAFFIC} = int2byte($traffic_rest * 1024 * 1024);
  $INFO_HASH{PREPAID}      = int2byte($list->[0]{prepaid} * 1024 * 1024);

  require Internet::Service_mng;
  my $Service = Internet::Service_mng->new({ lang => \%lang });

  ($INFO_HASH{NEXT_FEES_WARNING}, $INFO_HASH{NEXT_FEES_MESSAGE_TYPE}) = $Service->service_warning({
    SERVICE => $Internet,
    USER    => $user,
  });

  my $message = $html->tpl_show('', { %$user, %$internet_info, %INFO_HASH},
    { TPL => 'sms_callback_user_info', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKSERS => 1 });

  load_module('Sms');

  my $sms_id = sms_send(
    {
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

  if(!$sms_id){
    $code = 3;
    $message = 'User internet info didnt send'
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 start_external_opertaion($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub start_external_command {
  my ($user) = @_;
  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, PASSWORD => $additional_info },
    { TPL => 'sms_callback_change_wifi_password', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

#  my $startup_files = startup_files();
  if(!$additional_info || length($additional_info) < 8){
    $message = "Password length should be 8 symbols";
    load_module('Sms');

    my $sms_id = sms_send(
      {
        NUMBER  => $user->{phone},
        MESSAGE => $message,
        UID     => $user->{uid},
      });

    if(!$sms_id){
      $code = 3;
      $message = 'Sms didnt sent'
    }

    show_command_result(5, $message);
  }

  my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
  my $online_info = $Sessions->online_info({
    UID => $user->{uid}
  });

  if($Sessions->{errno}){
    $code = 1;
    $message = 'Something goes wrong';

    show_command_result($code, $message);
  }

  my $user_ip = $online_info->{FRAMED_IP_ADDRESS};

  my $ping_result = host_diagnostic($user_ip);

  if($ping_result == 1){
    my $ssh_command = qq{/interface wireless security-profiles set [ find default=yes ] authentication-types=wpa-psk,wpa2-psk eap-methods="" mode=dynamic-keys wpa-pre-shared-key="$additional_info" wpa2-pre-shared-key="$additional_info"};
    ssh_cmd("$ssh_command", {
        NAS_MNG_IP_PORT => "$user_ip:22",
        NAS_MNG_USER    => "abills_admin",
        SSH_KEY         => "",  # path_to_rsa_key
      });

    $users->pi_change({
      UID         => $user->{uid},
      _CPE_SERIAL => $additional_info,
    });

    load_module('Sms');

    my $sms_id = sms_send(
      {
        NUMBER  => $user->{phone},
        MESSAGE => $message,
        UID     => $user->{uid},
      });

    if(!$sms_id){
      $code = 3;
      $message = 'Sms with changed password didnt sent'
    }

    show_command_result($code, $message);
    exit 0;
  }

  return 1;
}
#**********************************************************
=head2 check_user($phone, $uid)

  Arguments:
    $phone - user Phone
    $uid   - user Identifier


  Returns:

=cut
#**********************************************************
sub check_user {
  my ($phone, $uid) = @_;

  my $user = {};

  if ($conf{CONTACTS_NEW}) {
    require Contacts;
    my $Contacts = Contacts->new($db, $admin, \%conf);
    my $users_list = $Contacts->contacts_list({
      TYPE_ID   => '2,3',
      VALUE     => "*$FORM{sender}*",
      UID       => $uid,
      PAGE_ROWS => 1,
    });

    if ($Contacts->{errno} || ref $users_list ne 'ARRAY' || !$users_list->[0]) {
      show_command_result(1, "User not found");
      exit 0;
    }
    my $users_list_by_uid = $users->list({
      LOGIN          => '_SHOW',
      FIO            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PHONE          => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      GID            => '_SHOW',
      DOMAIN_ID      => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      GROUP_NAME     => '_SHOW',
      COMPANY_ID     => '_SHOW',
      DISABLE        => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      PASSWORD       => '_SHOW',
      #    %EXTRA_FIELDS,
      UID            => $uid,
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
      PAGE_ROWS      => 1,
    });

    $user = $users_list_by_uid->[0];

    # show_command_result(0, "User found");
    return $user;
  }
  else {
    my $users_list = $users->list({
      LOGIN          => '_SHOW',
      FIO            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PHONE          => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      GID            => '_SHOW',
      DOMAIN_ID      => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      GROUP_NAME     => '_SHOW',
      COMPANY_ID     => '_SHOW',
      DISABLE        => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      PASSWORD       => '_SHOW',
      #    %EXTRA_FIELDS,
      PHONE          => "*$phone*",
      UID            => $uid,
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
      PAGE_ROWS      => 1,
    });

    if ($users->{errno} || ref $users_list ne 'ARRAY' || !$users_list->[0]) {
      show_command_result(1, "User not found");
      exit 0;
    }

    $user = $users_list->[0];
  }

  # show_command_result(0, "User found");
  return $user;
}

#**********************************************************
=head2 hold_up_user($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub hold_up_user {
  my ($user) = @_;
  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, STATUS => $STATUSES{'3'} },
    { TPL => 'internet_user_status_sms', MODULE => 'Internet', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

  load_module('Sms');

  my $Internet = Internet->new($db, $admin, \%conf);

  my $user_services = $Internet->list({UID => $user->{uid}, INTERNET_STATUS => '0', COLS_NAME => 1});

  if($Internet->{TOTAL} == 0){
    show_command_result(6, "All user servicecs not active. UID: $user->{uid}");
    exit 0;
  }

  foreach my $service (@$user_services){
    $Internet->change({ UID => $user->{uid}, ID => $service->{id}, STATUS => 3 });
  }

  if($Internet->{errno}){
    my $sms_id = sms_send(
      {
        NUMBER  => $user->{phone},
        MESSAGE => 'Service is not holding up',
        UID     => $user->{uid},
      });

    show_command_result(4, 'Service is not holding up');
    exit 0;
  }

  my $sms_id = sms_send(
    {
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

  if(!$sms_id){
    $code = 5;
    $message = 'Service is holding up but sms not sent'
  }

  show_command_result($code, $message);

  exit 0;
}


#**********************************************************
=head2 activate_user($user)

  Arguments:
    $user -

  Returns:

=cut
#**********************************************************
sub activate_user {
  my ($user) = @_;
  my $code    = 0;
  my $message = $html->tpl_show('', { %$user, STATUS => $STATUSES{'0'} },
    { TPL => 'internet_user_status_sms', MODULE => 'Internet', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

  load_module('Sms');

  my $Internet = Internet->new($db, $admin, \%conf);

  my $user_services = $Internet->list({UID => $user->{uid}, INTERNET_STATUS => 3, COLS_NAME => 1});

  if($Internet->{TOTAL} == 0){
    show_command_result(7, "All user servicecs not holding up. UID: $user->{uid}");
    exit 0;
  }

  foreach my $service (@$user_services){
    $Internet->change({ UID => $user->{uid}, ID => $service->{id}, STATUS => 0 });
  }

  if($Internet->{errno}){
    my $sms_id = sms_send(
      {
        NUMBER  => $user->{phone},
        MESSAGE => 'Service is not active',
        UID     => $user->{uid},
      });

    show_command_result(4, 'Service is not active');
    exit 0;
  }

  my $sms_id = sms_send(
    {
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });

  if(!$sms_id){
    $code = 5;
    $message = 'Service is active but sms not sent'
  }

  show_command_result($code, $message);

  exit 0;
}

#**********************************************************
=head2 get_user_info ($mac)

=cut
#**********************************************************
sub get_user_info {
  my ($cid) = @_;

  my $Internet = Internet->new($db, $admin, \%conf);
  my $list = $Internet->list({
    PHONE          => '_SHOW',
    CID            => $cid,
    # DOMAIN_ID      => 4,
    COLS_NAME      => 1,
  });
  
  if ( $Internet->{TOTAL} < 1 ){
    return (0, 0);
  }

  return ($list->[0]{uid}, $list->[0]{phone});
}

#**********************************************************
=head2 set_user_phone ($uid, $phone)

=cut
#**********************************************************
sub set_user_phone {
  my ($uid, $phone) = @_;
  require Contacts;
  my $Contacts = Contacts->new($db, $admin, \%conf);
  $Contacts->contacts_add({
    TYPE_ID => 2,
    VALUE   => $phone,
    UID     => $uid,
  });
  return 1;
}

#**********************************************************
=head2 sms_payment ($uid, $sum)

=cut
#**********************************************************
sub sms_payment {
  my ($uid, $sum) = @_;

  use Finance;
  my $Payments = Finance->payments($db, $admin, \%conf);
  my $user = Users->new($db, $admin, \%conf);
  $user->info($uid);

  $Payments->add($user, { 
    SUM      => $sum,
    METHOD   => 11,
    DESCRIBE => "Public hotspot SMS",
  });

  load_module('Sms');
  my $message = $html->tpl_show('', { UID => $uid, SUM => $sum, PAYMENT_ID => $Payments->{PAYMENT_ID} },
    { TPL => 'sms_callback_sms_pay_complete', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
  sms_send({
    NUMBER  => $FORM{sender},
    MESSAGE => $message,
    UID     => $uid,
  });

  return 1;
}

#**********************************************************
=head2 money_transfer($user, $target_uid, $sum)

=cut
#**********************************************************
sub money_transfer {
  my ($user, $target_uid, $sum) = @_;
  load_module('Sms');

  my $error = 0;
  my $percentage = 0;
  my $user1 = Users->new($db, $admin, \%conf);
  my $user2 = Users->new($db, $admin, \%conf);
  $user1->info($user->{uid});
  $user2->info($target_uid);
  $error = 2 if ($user2->{errno});

  require Dillers;
  my $Diller = Dillers->new($db, $admin, \%conf);

  $Diller->diller_info({ UID => $target_uid });
  $error = 2 if ($Diller->{TOTAL} > 0);

  $Diller->diller_info({ UID => $user->{uid} });
  $error = 3 if ($Diller->{TOTAL} < 1 && $user1->{GID} != $user2->{GID});
  
  if ($error) {
    my $message = $html->tpl_show('', { UID => $target_uid },
      { TPL => 'sms_callback_user_not_exist', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
    sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });
    return 1;
  }

  use Finance;
  my $Fees     = Finance->fees($db, $admin, \%conf);
  my $Payments = Finance->payments($db, $admin, \%conf);
  
  my $last_payments = $Payments->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    UID       => $user->{uid},
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $last_sum = $last_payments->[0]->{sum} || 0;

  if ($Diller->{TOTAL} < 1) {
    $percentage = 0;
  }
  elsif ($user1->{GID} && $user1->{GID} == $user2->{GID}) {
    $percentage = $Diller->{DILLER_PERCENTAGE} || 10;
  }
  elsif ($last_sum > 6000) {
    $percentage = 6;
  }
  elsif ($last_sum > 4000) {
    $percentage = 5;
  }
  elsif ($last_sum > 2000) {
    $percentage = 4;
  }
  elsif ($last_sum > 1000) {
    $percentage = 3;
  }
  else {
    $percentage = 0;
  }

  my $dillers_fee = $sum * (100 - $percentage) / 100;

  if ($user->{deposit} < $dillers_fee) {
    my $message = $html->tpl_show('', { DEPOSIT => $user->{deposit} },
      { TPL => 'sms_callback_not_enough_money', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
    sms_send({
      NUMBER  => $user->{phone},
      MESSAGE => $message,
      UID     => $user->{uid},
    });
    return 1;
  }

  $Fees->take($user1, $dillers_fee, {
    DESCRIBE => "Transfer '$sum' -> '$user2->{LOGIN}'",
    METHOD   => 10,
  });
  
  $Payments->add($user2, { 
    SUM      => $sum,
    METHOD    => 10,
    DESCRIBE => "User '$user1->{LOGIN}' add payment sum:'$sum' for user:'$user2->{LOGIN}' $DATE $TIME",
  });
  
  if (!$Payments->{errno}) {
    cross_modules_call('_payments_maked', {
      USER_INFO   => $user2,
      SUM         => $sum,
      SILENT      => 1,
      QUITE       => 1,
      timeout     => 4,
    });
  }

  my $deposit = sprintf("%.3f", ($user1->{DEPOSIT} - $dillers_fee));

  my $message = $html->tpl_show('', { %$user1, SUM => $sum, TARGET_UID => $target_uid, DEPOSIT => $deposit},
    { TPL => 'sms_callback_money_transfer', MODULE => 'Sms', OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
  sms_send({
    NUMBER  => $user->{phone},
    MESSAGE => $message,
    UID     => $user->{uid},
  });

  return 1;
}

#**********************************************************
=head2 show_command_result($message)

  Arguments:
     $message - what will show on screen

  Returns:

=cut
#**********************************************************
sub show_command_result {
  my ($code, $message) = @_;
  if ($conf{SMS_UNIVERSAL_URL}) {
    print "ACK/Jasmin\n";
    exit 1;
  }
  print "$message<br>";

  if($code == 0){
    $Log->log_print('LOG_INFO', '', $message);
  }
  else{
    $Log->log_print('LOG_ERR', '', $message);
  }

  return 1;
}

1;