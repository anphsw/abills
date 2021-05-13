#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

our (
  %FORM,
  %COOKIES,
  $DATE,
  $TIME,
  %conf,
  $base_dir,
  $db,
);

our Users  $users;
our Admins $admin;
our Tariffs  $Tariffs;
our Internet $Internet;
our Hotspot $Hotspot;
use Abills::Base qw/_bp/;

#**********************************************************
=head2 hotspot_init()

=cut
#**********************************************************
sub hotspot_init {
  #check params
  if (!$FORM{server_name} && !$COOKIES{server_name}) {
    errexit("Unknown hotspot.");
  }
  elsif (!$FORM{mac} || $FORM{mac} !~ /^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$/) {
    errexit("Unknown mac.");
  }

  #load hotspot conf
  $Hotspot->load_conf($FORM{server_name} || $COOKIES{server_name});

  #domain info
  if ( $Hotspot->{hotspot_conf}->{DOMAIN_ID} ){
    $Hotspot->{admin}->info( '', { DOMAIN_ID => $Hotspot->{hotspot_conf}->{DOMAIN_ID} } );
    if($Hotspot->{admin}->{errno}) {
      errexit("Unknown domain admin.");
    }
  }

  #set cookie
  my %new_cookies = ();
  $new_cookies{mac}         = $FORM{mac}             if ($FORM{mac});
  $new_cookies{server_name} = $FORM{server_name}     if ($FORM{server_name});
  $new_cookies{link_login}  = $FORM{link_login_only} if ($FORM{link_login_only});
  mk_cookie(\%new_cookies);

  #load scheme
  if (!$Hotspot->{hotspot_conf}->{SCHEME}) {
    errexit("Unknown scheme.");
  }
  my $scheme_name = $Hotspot->{hotspot_conf}->{SCHEME};
  eval { require "Hotspot/Scheme/$scheme_name.pm"; 1; };
  if ($@) {
    errexit("Cant load scheme $scheme_name.<br>$@");
  }
  return 1;
}

#**********************************************************
=head2 hotspot_radius_error()

=cut
#**********************************************************
sub hotspot_radius_error { 
  my $uid = get_user_uid();
  if (!$uid) {
    delete_old_cookie();
    return 1;
  }
  scheme_radius_error($uid);
  errexit($FORM{error});
}

#**********************************************************
=head2 hotspot_pre_auth()

=cut
#**********************************************************
sub hotspot_pre_auth {
  if ($FORM{ajax}) {
    hotspot_ajax();
  }
  else {
    scheme_pre_auth();
  }

  return 1;
}

#**********************************************************
=head2 hotspot_auth()

=cut
#**********************************************************
sub hotspot_auth {
  scheme_auth();
  return 1;
}

#**********************************************************
=head2 hotspot_registration()

=cut
#**********************************************************
sub hotspot_registration {
  scheme_registration();
  return 1;
}

#**********************************************************
=head2 hotspot_user_registration()

=cut
#**********************************************************
sub hotspot_user_registration {
  my ($attr) = @_;

  my $tp_id = $Hotspot->{hotspot_conf}->{TRIAL_TP} || $Hotspot->{hotspot_conf}->{TP};
  if (!$tp_id) {
    errexit("Sorry, can't find tarif for new users.");
  }
  $Tariffs->info( '', { ID => $tp_id} );
  my $domain_id = ($Hotspot->{hotspot_conf}->{DOMAIN_ID} || $admin->{DOMAIN_ID} || 0);

  my $login = $Hotspot->next_login({
    LOGIN_LENGTH => ($Hotspot->{hotspot_conf}->{HOTSPOT_LOGIN_LENGTH} || 6),
    LOGIN_PREFIX => ($Hotspot->{hotspot_conf}->{HOTSPOT_LOGIN_PREFIX} || ''),
    DOMAIN_ID    => $domain_id,
  });
  my $password = int(rand(90000000)) + 10000000;
  my $cid = uc($attr->{ANY_MAC} ? 'ANY' : $FORM{mac});
  my $group_id = 0;

  if ( $Hotspot->{hotspot_conf}->{HOTSPOT_GUESTS_GROUP} && $Hotspot->{hotspot_conf}->{HOTSPOT_GUESTS_GID} ) {
    my $group_name = $Hotspot->{hotspot_conf}->{HOTSPOT_GUESTS_GROUP};
    $group_id   = $Hotspot->{hotspot_conf}->{HOTSPOT_GUESTS_GID};
    $users->group_info($group_id);
    if ($users->{errno}) {
      $users->group_add({
        GID       => $group_id,
        NAME      => $group_name,
        DOMAIN_ID => $domain_id,
        DESCR     => 'Hotspot guest group'
      });
    }
  }

  $users->add({
    LOGIN       => $login,
    PASSWORD    => $password,
    GID         => $group_id,
    DOMAIN_ID   => $domain_id,
    CREATE_BILL => 1,
  });
  if ($users->{errno}) {
    errexit("Sorry, can't add user.");
  }
  my $uid = $users->{UID};
  $users->pi_add({ UID => $uid, PHONE => ($FORM{PHONE} || '') });

  $Internet->add({ 
    UID   => $uid,
    TP_ID => $Tariffs->{TP_ID},
    CID   => $cid,
  });
  if ($Internet->{errno}) {
    errexit("Sorry, can't add internet service.");
  }

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 1,
    PHONE    => $FORM{PHONE} || '',
    COMMENTS => "$login registred, UID:$uid"
  });

  mikrotik_login({ LOGIN => $login, PASSWORD => $password });
  
  exit;
}

#**********************************************************
=head2 mac_login()
  Search user with CID = $FORM(mac) and redirect to 
  Hotspot login page.
=cut
#**********************************************************
sub mac_login {
  my $list = $Internet->list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => '_SHOW',
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    CID            => $FORM{mac},
    TP_NUM         => ($Hotspot->{hotspot_conf}->{HOTSPOT_TPS} || ''),
    COLS_NAME      => 1,
  });

  if ( $Internet->{TOTAL} > 0 ){
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 2,
      PHONE    => $FORM{PHONE} || $list->[0]->{phone},
      COMMENTS => "$list->[0]->{login} $FORM{mac} MAC login"
    });

    mikrotik_login({LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password}});
    exit;
  }
  return 1;
}

#**********************************************************
=head2 phone_login()
  Search user with PHONE = $FORM{PHONE} and redirect to 
  Hotspot login page.
=cut
#**********************************************************
sub phone_login {
  if ($FORM{PHONE} !~ /^\+?[0-9]+$/) {
    errexit("Wrong phone.");
  }
  my $list = $Internet->list({
    PASSWORD       => '_SHOW',
    LOGIN          => '_SHOW',
    PHONE          => $FORM{PHONE},
    SERVICE_EXPIRE => "0000-00-00,>$DATE",
    TP_NUM         => ($Hotspot->{hotspot_conf}->{HOTSPOT_TPS} || ''),
    COLS_NAME      => 1,
  });
  if ( $Internet->{TOTAL} > 0 ){
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 5,
      PHONE    => $FORM{PHONE},
      COMMENTS => "$list->[0]->{login} $FORM{PHONE} PHONE login"
    });

    mikrotik_login({LOGIN => $list->[0]->{login}, PASSWORD => $list->[0]->{password}});
    exit;
  }
  return 1;
}

#**********************************************************
=head2 check_phone_verify()

=cut
#**********************************************************
sub check_phone_verify {
  my $hot_log = $Hotspot->log_list({
    CID       => $FORM{mac},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 12,
    PHONE     => '_SHOW',
    COLS_NAME => 1,
  });

  if ($Hotspot->{TOTAL} > 0) {
    $FORM{PHONE} = $hot_log->[0]->{phone};
    return 1;
  }
  return 0;
}

#**********************************************************
=head2 ask_phone()

=cut
#**********************************************************
sub ask_phone {
  return 1 if ($FORM{PHONE});
  
  my $phone_tpl = $Hotspot->{hotspot_conf}->{phone} || 'hotspot_phone';
  print "Content-type:text/html\n\n";
  print hotspot_tpl_show( $phone_tpl, \%FORM);
  exit;
}

#**********************************************************
=head2 ask_pin()

=cut
#**********************************************************
sub ask_pin {
  return 1 if ($FORM{PIN});

  $Hotspot->log_list({
    PHONE     => $FORM{PHONE},
    CID       => $FORM{mac},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 11,
    COMMENTS  => '_SHOW',
    COLS_NAME => 1,
  });
  if ($Hotspot->{TOTAL} < 1 || $FORM{send_pin}) {
    send_pin();
  }
  my $pin_tpl = $Hotspot->{hotspot_conf}->{pin} || 'hotspot_pin';
  print "Content-type:text/html\n\n";
  print hotspot_tpl_show( $pin_tpl, \%FORM);
  exit;
}

#**********************************************************
=head2 send_pin()

=cut
#**********************************************************
sub send_pin {
  my $pin = int(rand(900)) + 100;
  use Sms::Init;
  my $Sms_service = init_sms_service($db, $admin, \%conf);
  $Sms_service->send_sms({
    NUMBER     => $FORM{PHONE},
    MESSAGE    => "CODE: $pin",
  });

  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 11,
    PHONE    => $FORM{PHONE},
    COMMENTS => "Send PIN: $pin"
  });
  return 1;
}

#**********************************************************
=head2 verify_pin()

=cut
#**********************************************************
sub verify_pin {
  my $hot_log = $Hotspot->log_list({
    PHONE     => $FORM{PHONE},
    INTERVAL  => "$DATE/$DATE",
    ACTION    => 11,
    COMMENTS  => '_SHOW',
    COLS_NAME => 1,
  });

  if (($Hotspot->{TOTAL} > 0) && ($hot_log->[0]->{comments} eq "Send PIN: $FORM{PIN}" )) {
    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name},
      CID      => $FORM{mac},
      ACTION   => 12,
      PHONE    => $FORM{PHONE},
      COMMENTS => 'Phone confirmed.'
    });
  }
  else {
    errexit("Wrong PIN.");
  }
  return 1;
}

#**********************************************************
=head2 verify_call()

=cut
#**********************************************************
sub verify_call {
  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 11,
    PHONE    => $FORM{PHONE},
    COMMENTS => "Waiting for client call."
  });

  my $auth_tpl = $Hotspot->{hotspot_conf}->{call_auth} || 'hotspot_call_auth'; 
  print "Content-type:text/html\n\n";
  print hotspot_tpl_show( $auth_tpl, \%FORM);
  exit;
}

#**********************************************************
=head2 hotspot_sms_pay()

=cut
#**********************************************************
sub hotspot_sms_pay{
  my ($uid) = @_;
  $users->info($uid);
  exit if ($users->{errno});
  $users->pi();
  my $sms_pay_tpl = $Hotspot->{hotspot_conf}->{sms_pay_tpl} || 'hotspot_sms_pay';
  my $mac = uc($FORM{mac});
  $mac =~ s/://g;
  my $params = ();
  $params->{SMS_CODE} = "ICNHS+$mac";
  $params->{mac}  = $FORM{mac};
  $params->{date} = "$DATE $TIME";  
  if ($users->{PHONE}) {
    $params->{HIDE_BUTTON} = 'style="display:none"';
  }
  else {
    $params->{SMS_FREE_CODE} = "ICNFREEHS+$mac";
  }
  print "Content-type:text/html\n\n";
  print hotspot_tpl_show( $sms_pay_tpl, $params);
  exit;
}

#**********************************************************
=head2 hotspouser_portal_redirectt_sms_pay()

=cut
#**********************************************************
sub user_portal_redirect {
  if ($COOKIES{hotspot_username} && $COOKIES{hotspot_password}) {
    my $user_portal_url = "index.cgi?user=$COOKIES{hotspot_username}&passwd=$COOKIES{hotspot_password}";
    print "Location: $user_portal_url\n\n";
    exit;
  }
  return 1;
}

#**********************************************************
=head2 cookie_login()

=cut
#**********************************************************
sub cookie_login {
  return 1 if (!$COOKIES{hotspot_username} || !$COOKIES{hotspot_password});
  $Hotspot->log_add({
    HOTSPOT  => $COOKIES{server_name},
    CID      => $FORM{mac},
    ACTION   => 3,
    COMMENTS => "User:$COOKIES{hotspot_username} cookies login"
  });
  mikrotik_login({LOGIN => $COOKIES{hotspot_username}, PASSWORD => $COOKIES{hotspot_password}});
  exit;
}

#**********************************************************
=head2 mikrotik_login()
    
=cut
#**********************************************************
sub mikrotik_login {
  my ($attr) = @_;
  my $tpl = 'hotspot_auto_login';
  my $ad_to_show = ();

  mk_cookie({
    hotspot_username=> $attr->{LOGIN},
    hotspot_password=> $attr->{PASSWORD},
  });

  if($Hotspot->{hotspot_conf}->{HOTSPOT_SHOW_AD}) {

    $ad_to_show = $Hotspot->request_random_ad({ COLS_NAME => 1 });
    my $user_info = $users->list({
      LOGIN     => $attr->{LOGIN},
      COLS_NAME => 1,
    });

    my $tp_info = $Internet->info($user_info->[0]->{uid});

    my @show_tp = split(';', ($conf{HOTSPOT_AD_TP_IDS} || ''));
    if($ad_to_show->{id} && in_array($tp_info->{TP_ID}, \@show_tp)) {
      $Hotspot->advert_shows_add({ AD_ID => $ad_to_show->{id}});

      $tpl='hotspot_auto_login_advertisement';
    }
  }
  print "Content-type:text/html\n\n";
  print hotspot_tpl_show($tpl, {
    LOGIN              => $attr->{LOGIN},
    PASSWORD           => $attr->{PASSWORD},
    HOTSPOT_AUTO_LOGIN => $COOKIES{link_login} || $FORM{link_login_only} || '1',
    TIME               => $conf{HOTSPOT_AD_SHOW_TIME} || 10,
    ADVERTISEMENT      => $ad_to_show->{url} || '',
    DST                => 'http://google.com',
  });

  return 1;
}

#**********************************************************
=head2 hotspot_ajax()

=cut
#**********************************************************
sub hotspot_ajax {
  print "Content-type:text/html\n\n";
  if ($FORM{ajax} == 1) {
    my $hot_log = $Hotspot->log_list({
      PHONE     => $FORM{PHONE},
      CID       => $FORM{mac},
      INTERVAL  => "$DATE/$DATE",
      ACTION    => 12,
    });
    print ($Hotspot->{TOTAL} < 1 ? 0 : 1);
  }
  elsif ($FORM{ajax} == 2) {
    my $hot_log = $Hotspot->log_list({
      CID       => $FORM{mac},
      DATE      => ">$FORM{date}",
      ACTION    => '22,23',
    });
    print ($Hotspot->{TOTAL} < 1 ? 0 : 1);
  }
  else {
    print 0;
  }
  exit;
}

#**********************************************************
=head2 get_user_uid ()

=cut
#**********************************************************
sub get_user_uid {
  my $list = $Internet->list({
    PHONE          => '_SHOW',
    CID            => uc($FORM{mac}),
    DOMAIN_ID      => ($Hotspot->{hotspot_conf}->{DOMAIN_ID} || ''),
    COLS_NAME      => 1,
  });
  
  if ( $Internet->{TOTAL} < 1 ){
    return 0;
  }

  return $list->[0]{uid};
}

#**********************************************************
=head2 trial_tp_change ()

=cut
#**********************************************************
sub trial_tp_change {
  my ($uid) = @_;

  return if (!$Hotspot->{hotspot_conf}->{TRIAL_TP} || !$Hotspot->{hotspot_conf}->{TP} || !$uid);
  $Internet->info($uid);
  if ($Internet->{TP_NUM} eq $Hotspot->{hotspot_conf}->{TRIAL_TP}) {
    $Tariffs->info( '', { ID => $Hotspot->{hotspot_conf}->{TP} });
    $Hotspot->change_tp({
      UID   => $uid,
      TP_ID => $Tariffs->{TP_ID},
    });

    $Hotspot->log_add({
      HOTSPOT  => $COOKIES{server_name} || $FORM{server_name},
      CID      => $FORM{mac},
      ACTION   => 6,
      COMMENTS => "User:$uid change trial tp",
    });
  }
  return 1;
}

#**********************************************************
=head2 parse_query()

=cut
#**********************************************************
sub parse_query {
  my $buffer = '';
  $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
  if ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  }
  else {
    $buffer = $ENV{'QUERY_STRING'};
  }
  my @pairs = split('&', $buffer);
  foreach my $pair (@pairs) {
    my ($key, $value) = split('=', $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $FORM{$key} = $value;
  }
  return 1;
}

#**********************************************************
=head2 get_cookies()

=cut
#**********************************************************
sub get_cookies {
  if (defined($ENV{'HTTP_COOKIE'})) {
    my (@rawCookies) = split(/; /, $ENV{'HTTP_COOKIE'});
    foreach (@rawCookies) {
      my ($key, $val) = split(/=/, $_);
      $COOKIES{$key} = $val;
    }
  }
  return 1;
}

#**********************************************************
=head2 delete_old_cookie()

=cut
#**********************************************************
sub delete_old_cookie {
  mk_cookie({ hotspot_username => '', hotspot_password => '' }, { DELETE => 1 });
  return 1;
}

#**********************************************************
=head2 mk_cookie($hash)

=cut
#**********************************************************
sub mk_cookie {
  my ($cookie_vals, $attr) = @_;
  my $auth_cookie_time = $attr->{DELETE} ? 0 : ($conf{AUTH_COOKIE_TIME} || 86400);
  my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
  foreach my $key (keys %$cookie_vals) {
    my $value = $cookie_vals->{$key};
    my $cookie = "Set-Cookie: $key=$value; expires=\"$cookies_time\";\n";
    print $cookie;
  }
  return 1;
}

#**********************************************************
=head2 hotspot_tpl_show()

=cut
#**********************************************************
sub hotspot_tpl_show {
  my ($tpl_file, $attr) = @_;
  $tpl_file .= '.tpl' if ($tpl_file !~ m/\.tpl$/);
  my $file_path = '';
  if ( -e "$base_dir/Abills/templates/$tpl_file" ) {
    $file_path = "$base_dir/Abills/templates/$tpl_file";
  }
  elsif ( -e "$base_dir/Abills/modules/Hotspot/templates/$tpl_file" ) {
    $file_path = "$base_dir/Abills/modules/Hotspot/templates/$tpl_file";
  }
  else {
    return '';
  }
  open(my $fh, '<', $file_path) or die;
    my $tpl = '';
    while(<$fh>) {
      $tpl .= $_;
    }
  close($fh);

  $tpl =~ s/\%([a-zA-Z0-9_]+)\%/$attr->{$1} || $1/eg;

  return $tpl;
}

#**********************************************************
=head2 errexit($str)

=cut
#**********************************************************
sub errexit {
  my ($str) = @_;
  print "Content-type:text/html\n\n";
  print $str;
  exit;
}

1;