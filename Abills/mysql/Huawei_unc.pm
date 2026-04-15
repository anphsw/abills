package Huawei_unc v1.30.00;
#*********************** ABillS ***********************************
# Copyright (с) 2003-2025 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************

=head1 NAME

   Huawei unc (huawei_unc)

=head1 OPTIONS



=head1 VERSION

  VERSION: 1.30
  REVISION: 20260313

=cut

use strict;
use Billing;
use base qw(dbbase Auth2 Acct2);

my %ACCT_TERMINATE_CAUSES = (
  'User-Request'             => 1,
  'Lost-Carrier'             => 2,
  'Lost-Service'             => 3,
  'Idle-Timeout'             => 4,
  'Session-Timeout'          => 5,
  'Admin-Reset'              => 6,
  'Admin-Reboot'             => 7,
  'Port-Error'               => 8,
  'NAS-Error'                => 9,
  'NAS-Request'              => 10,
  'NAS-Reboot'               => 11,
  'Port-Unneeded'            => 12,
  'Port-Preempted'           => 13,
  'Port-Suspended'           => 14,
  'Service-Unavailable'      => 15,
  'Callback'                 => 16,
  'User-Error'               => 17,
  'Host-Request'             => 18,
  'Supplicant-Restart'       => 19,
  'Reauthentication-Failure' => 20,
  'Port-Reinit'              => 21,
  'Port-Disabled'            => 22,
  'Lost-Alive'               => 23,
);

my ($CONF, $Billing);

my %_RAD_REPLY = ();
my %profiles = ();
#my $profile_prefix = 'svc';
my $default_guest_pool = 0;

my $input_octets = 'Acct-Output-Octets';
my $output_octets = 'Acct-Input-Octets';


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($CONF) = @_;

  my $self = {
    db   => $db,
    conf => $CONF
  };

  bless($self, $class);

  $Billing = Billing->new($self->{db}, $CONF);

  return $self;
}

#**********************************************************
=head2 pre_auth($self, $RAD, $attr)

=cut
#**********************************************************
sub pre_auth {
  my ($self) = @_;

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";
  return 0;
}

#**********************************************************
=head2 user_info($RAD_REQUEST, $attr) - get user info

=cut
#**********************************************************
sub user_info {
  my ($self, $RAD_REQUEST, $attr) = @_;

  my $WHERE;
  my @binding_vals = ();
  my $auth_pair = '3GPP-IMSI';
  if ($attr->{SERVICE_ID}) {
    $WHERE = " AND internet.id='$attr->{SERVICE_ID}'";
  }
  elsif ($attr->{UID}) {
    $WHERE = " AND internet.uid='$attr->{UID}'";
  }
  elsif ($RAD_REQUEST->{$auth_pair}) {
    $WHERE = " AND internet.cid= ? ";
    push @binding_vals, $RAD_REQUEST->{$auth_pair};
  }
  else {
    $WHERE = " AND u.id= ? ";
    push @binding_vals, $RAD_REQUEST->{'User-Name'};
  }

  my $ipv6 = q{};
  if ($CONF->{IPV6}) {

    $ipv6 = << "IPV6";
, INET6_NTOA(internet.ipv6) AS ipv6, INET6_NTOA(internet.ipv6_prefix) AS ipv6_prefix,
    internet.ipv6_mask, internet.ipv6_prefix_mask
IPV6
  }

  my $sql = <<"SQL";
  SELECT
    u.id AS user_name,
    internet.tp_id,
    IF (internet.logins=0, IF(tp.logins IS NULL, 0, tp.logins), internet.logins) AS simultaneously,
    internet.speed,
    internet.disable AS internet_disable,
    u.disable AS user_disable,
    u.reduction AS discount,
    u.bill_id,
    u.company_id,
    u.credit,
    u.activate AS account_activate,
    UNIX_TIMESTAMP() AS session_start,
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
    DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
    DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,

    IF(internet.filter_id != '', internet.filter_id, IF(tp.filter_id IS NULL, '', tp.filter_id)) AS filter,
    tp.payment_type,
    tp.neg_deposit_filter_id,
    tp.credit AS tp_credit,
    tp.credit_tresshold,
    DECODE(u.password, '$CONF->{secretkey}') AS password,
    internet.cid,
    tp.neg_deposit_ippool,
    tp.ippool AS tp_ippool,
    tp.rad_pairs AS tp_rad_pairs,
    internet.port,
    tp.age AS account_age,
    internet.expire AS internet_expire,
    tp_int.id AS interval_id,
    internet.uid,
    IF(internet.ip>0, INET_NTOA(internet.ip), 0) AS ip,
    internet.id AS service_id
    $ipv6
  FROM internet_main internet
  INNER JOIN users u ON (u.uid=internet.uid)
  LEFT JOIN tarif_plans tp ON (internet.tp_id=tp.tp_id)
  LEFT JOIN intervals tp_int ON (tp_int.tp_id=tp.tp_id)
  WHERE (internet.expire='0000-00-00' OR internet.expire > CURDATE())
  $WHERE
  GROUP BY u.id;
SQL

  $self->query($sql,
    undef,
    { INFO => 1,
      Bind => \@binding_vals }
  );

  if ($self->{errno}) {
    return $self;
  }

  #DIsable
  if (($self->{INTERNET_DISABLE} && $self->{INTERNET_DISABLE} != 5) || $self->{USER_DISABLE}) {
    $_RAD_REPLY{'Reply-Message'} = "ACCOUNT_DISABLE: $self->{USER_DISABLE}/$self->{INTERNET_DISABLE}";
    $self->{errno} = 6;
    $self->{errstr} = $_RAD_REPLY{'Reply-Message'};
    return 6, \%_RAD_REPLY;
  }

  if (!$RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    if ($CONF->{INTERNET_PASSWORD}) {
      my $WHERE_ = ($self->{SERVICE_ID}) ? "id='$self->{SERVICE_ID}'" : "uid='$self->{UID}'";
      $self->query("SELECT DECODE(password, '$CONF->{secretkey}') AS password FROM internet_main WHERE $WHERE_;");
      if ($self->{list}->[0]->[0]) {
        $self->{PASSWORD} = $self->{list}->[0]->[0];
      }
    }

    if ($RAD_REQUEST->{'CHAP-Password'} && $RAD_REQUEST->{'CHAP-Challenge'}) {
      if (Auth2::check_chap($RAD_REQUEST->{'CHAP-Password'}, $self->{PASSWORD}, $RAD_REQUEST->{'CHAP-Challenge'}, 0) == 0) {
        $_RAD_REPLY{'Reply-Message'} = "WRONG_CHAP_PASSWORD:";
        $self->{errno} = 1;
        $self->{errstr} = $_RAD_REPLY{'Reply-Message'};
        return 1, \%_RAD_REPLY;
      }
    }
    #If don't athorize any above methods auth PAP password
    else {
      # if (defined($RAD_REQUEST->{'User-Password'}) && $self->{PASSWORD} ne $RAD_REQUEST->{'User-Password'}) {
      #   $_RAD_REPLY{'Reply-Message'} = "WRONG_PASSWORD: '" . $RAD_REQUEST->{'User-Password'} . "'";
      #   $self->{errno}              = 1;
      #   $self->{errstr}             = $_RAD_REPLY{'Reply-Message'};
      #   return 1, \%_RAD_REPLY;
      # }
    }

    #Check CID (MAC) for pppoe
    # if ($self->{CID} && $self->{CID} !~ /ANY/i && ! $ignore_cid) {
    #   my ($ret, $ERR_RAD_PAIRS) = $self->auth_cid($RAD_REQUEST);
    #
    #   %_RAD_REPLY = %{ $ERR_RAD_PAIRS } if ($ERR_RAD_PAIRS);
    #   if ($ret == 1) {
    #     $self->{errno}  = 8;
    #     $self->{errstr} = $_RAD_REPLY{'Reply-Message'};
    #     return 8, $ERR_RAD_PAIRS ;
    #   }
    # }
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);
  $self->check_bill_account();

  if ($self->{errno}) {
    $_RAD_REPLY{'Reply-Message'} = $self->{errstr};
    return 1, \%_RAD_REPLY;
  }

  return 1, \%_RAD_REPLY;
}

#**********************************************************
=head2 check_simultaneously($RAD_REPLY, $NAS, $attr) - Check logins

  Arguments:
    $RAR_REPLY_REF
    $NAS
    $attr
      CALLING_STATION_ID

=cut
#**********************************************************
sub check_simultaneously {
  my ($self, $RAD_REPLY, $NAS, $attr) = @_;

  $self->query("SELECT cid, INET_NTOA(framed_ip_address) AS ip, nas_id FROM internet_online WHERE user_name='$self->{USER_NAME}' AND (status <> 2 AND status < 11);");
  my $active_logins = $self->{TOTAL} || 0;

  foreach my $line (@{$self->{list}}) {
    # Zap session with same CID
    if ($line->[0]
      && ($line->[0] eq $attr->{CALLING_STATION_ID}
      #&& $line->[2] eq $NAS->{NAS_ID} #one NAS
      && ($line->[2] eq $NAS->{NAS_ID} || $CONF->{hard_simultaneously_control_skip_nas}))
    ) {
      $self->query("UPDATE internet_online SET status=6 WHERE user_name='$self->{USER_NAME}' AND cid='$attr->{CALLING_STATION_ID}' AND (status <> 2 AND status < 11);", 'do');
      $self->{IP} = $line->[1] if (!$self->{IP});
      $self->{ASSIGN_IP} = 1;
      $active_logins--;
    }
  }

  if ($active_logins >= $self->{SIMULTANEOUSLY}) {
    $RAD_REPLY->{'Reply-Message'} = "MORE_THEN_ALLOW_LOGIN: ($self->{SIMULTANEOUSLY}/$active_logins)";
    $self->{errno} = 3;
    $self->{errstr} = $RAD_REPLY->{'Reply-Message'};
    return 1, $RAD_REPLY;
  }

  return 0, $RAD_REPLY;
}

#**********************************************************
=head2 guest_mode($RAD_REQUEST, $NAS, $message, $attr)

  Arguments:
    $attr
      USER_AUTH_PARAMS
      GUEST_MODE_TYPE

=cut
#**********************************************************
sub guest_mode {
  my ($self, $RAD_REQUEST, $NAS, $message, $attr) = @_;

  $self->{GUEST} = 1;
  my $redirect_profile = ($attr->{GUEST_MODE_TYPE} && $profiles{$attr->{GUEST_MODE_TYPE}}) ? $profiles{$attr->{GUEST_MODE_TYPE}} : $CONF->{MX80_DEFAULT_GUEST_PROFILE};
  $_RAD_REPLY{'Reply-Message'} = $message;
  $self->{INFO} = $message;
  if ($self->{NEG_DEPOSIT_FILTER_ID}) {
    $self->Auth2::neg_deposit_filter_former($RAD_REQUEST, $NAS,
      $self->{NEG_DEPOSIT_FILTER_ID},
      { RAD_PAIRS   => \%_RAD_REPLY,
        USER_NAME   => 'neg',
        SKIP_ADD_IP => 1
      });
  }
  elsif (!$redirect_profile) {
    return 7, \%_RAD_REPLY;
  }

  if (!$CONF->{INTERNET_GUEST_STATIC_IP}) {
    delete $self->{IP};
  }

  if ($redirect_profile) {
    $redirect_profile =~ s/pppoe/ipoe/x if (!$RAD_REQUEST->{'Framed-Protocol'});
    $_RAD_REPLY{'ERX-Service-Activate:1'} = $redirect_profile if ($redirect_profile);
  }

  my $neg_ip_pool = $self->{NEG_DEPOSIT_IPPOOL} || $self->{tp_ippool} || $default_guest_pool || 0;
  if (!$self->{IP} || $self->{IP} eq '0.0.0.0') {
    $self->{USER_NAME} ||= $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'} || q{};

    my $ip = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL       => $neg_ip_pool,
      CONNECT_INFO    => $RAD_REQUEST->{'3GPP-User-Location-Info'} || '',
      CID             => $RAD_REQUEST->{'Calling-Station-Id'},
      GUEST           => 1,
      SERVER_VLAN     => $attr->{SERVER_VLAN},
      VLAN            => $attr->{VLAN},
      ACCT_SESSION_ID => $RAD_REQUEST->{'Acct-Session-Id'},
      REMOTE_ID       => $RAD_REQUEST->{'3GPP-Charging-ID'}
        #CONNECT_INFO => '!-'
    });
    #$self->{GUEST}=0;
    #    $self->query("SELECT INET_NTOA(netmask) AS netmask,
    #        dns,
    #        ntp,
    #        INET_NTOA(gateway) AS gateway,
    #        id
    #      FROM ippools
    #      WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
    #      ORDER BY netmask
    #      LIMIT 1", undef, { INFO => 1 });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = $attr->{GUEST_MODE_TYPE} . " NO_FREE_NEG_POOL_IP (USED: $self->{USED_IPS})";
      return 1, \%_RAD_REPLY;
    }
    elsif ($ip eq '0') {
      #No IP
      $self->Auth2::online_add({
        %{($attr) ? $attr : {}},
        NAS_ID          => $NAS->{NAS_ID},
        #FRAMED_IP_ADDRESS => "INET_ATON('$self->{IP}')",
        #FRAMED_IPV6_PREFIX=> ($self->{IPV6}) ? "INET6_ATON('". $self->{IPV6} ."')" : undef,
        #FRAMED_INTERFACE_ID=>$RAD_REQUEST->{'Framed-Interface-Id'},
        #DELEGATED_IPV6_PREFIX => ($self->{IPV6_PREFIX}) ? "INET6_ATON('". $self->{IPV6_PREFIX} ."')" : undef,
        NAS_IP_ADDRESS  => $NAS->{IP},
        CONNECT_INFO    => $RAD_REQUEST->{'3GPP-User-Location-Info'} || '',
        REMOTE_ID       => $RAD_REQUEST->{'3GPP-Charging-ID'},
        CID             => $RAD_REQUEST->{'Calling-Station-Id'},
        GUEST           => 1,
        ACCT_SESSION_ID => $RAD_REQUEST->{'Acct-Session-Id'}
      });
    }
    else {
      $_RAD_REPLY{'Framed-IP-Address'} = $ip;
    }

    $self->{IP} = $ip;
  }
  elsif ($self->{IP}) {
    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};
    #if(! $self->{ASSIGN_IP}) {
    #Add guest start internet_online_ip
    $self->query("SELECT uid FROM internet_online WHERE uid='$self->{UID}' AND framed_ip_address=INET_ATON('$self->{IP}') AND guest=1;");
    if (!$self->{TOTAL}) {
      $self->Auth2::online_add({
        %{($attr) ? $attr : {}},
        NAS_ID                => $NAS->{NAS_ID},
        FRAMED_IP_ADDRESS     => "INET_ATON('$self->{IP}')",
        FRAMED_IPV6_PREFIX    => ($self->{IPV6}) ? "INET6_ATON('" . $self->{IPV6} . "')" : undef,
        FRAMED_INTERFACE_ID   => $RAD_REQUEST->{'Framed-Interface-Id'},
        DELEGATED_IPV6_PREFIX => ($self->{IPV6_PREFIX}) ? "INET6_ATON('" . $self->{IPV6_PREFIX} . "')" : undef,
        NAS_IP_ADDRESS        => $NAS->{IP},
        CONNECT_INFO          => $RAD_REQUEST->{'3GPP-User-Location-Info'} || '',
        REMOTE_ID             => $RAD_REQUEST->{'3GPP-Charging-ID'},
        CID                   => $RAD_REQUEST->{'Calling-Station-Id'},
        GUEST                 => 1,
        ACCT_SESSION_ID       => $RAD_REQUEST->{'Acct-Session-Id'}
      });
    }
    #}
  }

  my $sql = <<"SQL";
SELECT INET_NTOA(netmask) AS netmask,
       dns,
       ntp,
       INET_NTOA(gateway) AS gateway,
       id
FROM ippools
WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
ORDER BY netmask
LIMIT 1
SQL

  $self->query($sql, undef, { INFO => 1 });

  delete $_RAD_REPLY{'Framed-IP-Netmask'};
  if ($self->{NETMASK} && $RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK};
  }

  # if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
  #   $_RAD_REPLY{'ERX-Dhcp-Options'} = sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./, $self->{GATEWAY}));
  # }

  # if($self->{DNS}) {
  #   $self->{DNS}=~s/ //g;
  #   my @dns_arr = split(/,/, $self->{DNS});
  #   #push @dns_arr, $self->{DNS2} if ($self->{DNS2});
  #   $_RAD_REPLY{'ERX-Primary-Dns'}=$dns_arr[0] if ($dns_arr[0]);
  #   $_RAD_REPLY{'ERX-Secondary-Dns'}=$dns_arr[1] if ($dns_arr[1]);
  # }

  # if($GUEST_POOLS{$neg_ip_pool}) {
  #   %_RAD_REPLY = (%_RAD_REPLY, %{ $GUEST_POOLS{$neg_ip_pool}{RAD_REPLY} });
  # }

  if ($NAS->{NAS_ALIVE}) {
    $_RAD_REPLY{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE};
  }

  $self->{UID} = 0 if (!$self->{UID});
  $self->{TP_ID} = 0 if (!$self->{TP_ID});
  $self->{GUEST_MODE} = 1;

  return 0, \%_RAD_REPLY;
}

#**********************************************************
=head2 auth($RAD_REQUEST, $NAS, $attr)
  Client        -> Server     -> Client       ->  Server
  DHCP-Discover -> DHCP Offer -> DHCP-Request ->  DHCP ACK/DHCP NAK (Not found)

  Arguments:
    $RAD_REQUEST
    $NAS
    $attr

  Results:

=cut
#**********************************************************
sub auth {
  my ($self, $RAD_REQUEST, $NAS, $attr) = @_;

  if ($attr->{RAD_REQUEST}) {
    $RAD_REQUEST = $attr->{RAD_REQUEST};
  }

  %_RAD_REPLY = ();
  my $uid = 0;
  my $cid = $RAD_REQUEST->{'Calling-Station-Id'} || q{};
  $self->{INFO} = '';
  $NAS->{NAS_ALIVE} = 1800 if (!$NAS->{NAS_ALIVE});
  $self->{GUEST_MODE} = 0;
  $self->{GUEST} = 0;
  my $user_auth_params = {};

  # if ($RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}) {
  #   $self->{INFO} = " $RAD_REQUEST->{'ERX-Dhcp-Mac-Addr'}/$RAD_REQUEST->{'NAS-Port-Id'}";
  # }

  #Get user info
  $self->user_info($RAD_REQUEST, { UID => $uid, SERVICE_ID => $self->{SERVICE_ID} });
  # $self->{NAS_MAC} = $user_auth_params->{NAS_MAC} if ($user_auth_params->{NAS_MAC});
  # $self->{PORT} = $user_auth_params->{PORT} if ($user_auth_params->{PORT});

  if ($self->{USER_NAME}) {
    $RAD_REQUEST->{'User-Name'} = $self->{USER_NAME};
  }

  if ($self->{errno}) {
    if ($self->{errno} == 2) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "USER_NOT_EXIST '"
        . $RAD_REQUEST->{'User-Name'} . "' $user_auth_params->{NAS_MAC}/$user_auth_params->{PORT}",
        { GUEST_MODE_TYPE => 'USER_NOT_EXIST', %$user_auth_params });
    }
    elsif ($self->{errno} == 3) {
      $_RAD_REPLY{'Reply-Message'} = $self->{errstr} . "$self->{INFO}";
      return 1, \%_RAD_REPLY;
    }
    else {
      return $self->guest_mode($RAD_REQUEST, $NAS, "$self->{errstr} $self->{INFO}",
        { GUEST_MODE_TYPE => $Auth2::connect_errors_ids{$self->{errno}}, %$user_auth_params });
    }
  }
  elsif (!defined($self->{PAYMENT_TYPE})) {
    return $self->guest_mode($RAD_REQUEST, $NAS, "NOT_ALLOW_SERVICE", {
      GUEST_MODE_TYPE => 'NOT_ALLOW_SERVICE',
      %$user_auth_params
    });
  }

  #Get balance state
  if ($self->{PAYMENT_TYPE} == 0) {
    $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);
    $self->{DEPOSIT} = $self->{DEPOSIT} + $self->{CREDIT} - $self->{CREDIT_TRESSHOLD};
    #Check deposit
    if ($self->{DEPOSIT} <= 0 || $self->{INTERNET_DISABLE} == 5) {
      return $self->guest_mode($RAD_REQUEST, $NAS, "NEG_DEPOSIT: '$self->{DEPOSIT}'", {
        GUEST_MODE_TYPE => 'NEG_DEPOSIT',
        %$user_auth_params,
      });
    }
  }

  if ($attr->{GET_USER}) {
    return $self;
  }

  #Check  simultaneously logins if needs
  delete $self->{ASSIGN_IP};
  if ($self->{SIMULTANEOUSLY} > 0) {
    my ($ret, $RAD_REPLY) = $self->check_simultaneously(\%_RAD_REPLY, $NAS, {
      CALLING_STATION_ID => $cid
    });

    if ($ret == 1) {
      return 1, $RAD_REPLY;
    }
  }

  #@Fixme  very bad situation with renew wrong ip if it assign to other user. We recomended mandatory assign
  # if (! $self->{IP} && $RAD_REQUEST->{'Framed-IP-Address'}) {
  #   $self->{IP}=$RAD_REQUEST->{'Framed-IP-Address'};
  # }

  if ($self->{IP}) {
    # && $self->{IP} ne '0.0.0.0') {
    if (!$self->{ASSIGN_IP}) {
      $self->Auth2::online_add({
        %$user_auth_params,
        %$attr,
        NAS_ID                => $NAS->{NAS_ID},
        FRAMED_IPV6_PREFIX    => ($self->{IPV6}) ? "INET6_ATON('" . $self->{IPV6} . "')" : undef,
        DELEGATED_IPV6_PREFIX => ($self->{IPV6_PREFIX}) ? "INET6_ATON('" . $self->{IPV6_PREFIX} . "')" : undef,
        FRAMED_INTERFACE_ID   => $RAD_REQUEST->{'Framed-Interface-Id'},
        FRAMED_IP_ADDRESS     => "INET_ATON('$self->{IP}')",
        NAS_IP_ADDRESS        => $NAS->{IP},
        CONNECT_INFO          => $RAD_REQUEST->{'3GPP-User-Location-Info'} || '',
        REMOTE_ID             => $RAD_REQUEST->{'3GPP-Charging-ID'} || '',
        CID                   => $cid,
        ACCT_SESSION_ID       => $RAD_REQUEST->{'Acct-Session-Id'},
      });
    }

    $_RAD_REPLY{'Framed-IP-Address'} = $self->{IP};

    if ($self->{IPV6}) {
      my ($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) = split(/:/x, Auth2::ipv6_2_long($self->{IPV6}));
      $_RAD_REPLY{'Framed-IPv6-Address'} = ($p1 || q{}) . ':' . ($p2 || q{}) . ':' . ($p3 || q{}) . ':' . ($p4 || q{}) . ':' .
        ($p5 || q{}) . ':' . ($p6 || q{}) . ':' . ($p7 || q{}) . ':' . ($p8 || q{})
        . '/' . $self->{IPV6_MASK};

      $_RAD_REPLY{'Framed-IPv6-Prefix'} = ($p1 || q{}) . ':' . ($p2 || q{}) . ':' . ($p3 || q{}) . ':' . ($p4 || q{}) . '::/' . $self->{IPV6_MASK};
      $_RAD_REPLY{'Framed-Interface-Id'} = ($p5 || q{}) . ':' . ($p6 || q{}) . ':' . ($p7 || q{}) . ':' . ($p8 || q{});
    }

    if ($self->{IPV6_PREFIX}) {
      $_RAD_REPLY{'Delegated-IPv6-Prefix'} = $self->{IPV6_PREFIX} . '/' . $self->{IPV6_PREFIX_MASK};
    }

    # if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
    #   $self->query("SELECT INET_NTOA(netmask) AS netmask,
    #     dns,
    #     ntp,
    #     INET_NTOA(gateway) AS gateway,
    #     id
    #   FROM ippools
    #   WHERE ip<=INET_ATON('$self->{IP}') AND INET_ATON('$self->{IP}')<=ip+counts
    #   ORDER BY netmask
    #   LIMIT 1", undef, { INFO => 1 });
    #
    #   $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK});
    # }
  }
  else {
    my $ip = $self->Auth2::get_ip($NAS->{NAS_ID}, $RAD_REQUEST->{'NAS-IP-Address'}, {
      TP_IPPOOL       => $self->{TP_IPPOOL},
      CONNECT_INFO    => $RAD_REQUEST->{'3GPP-User-Location-Info'} || '',
      REMOTE_ID       => $RAD_REQUEST->{'3GPP-Charging-ID'} || '',
      CID             => $cid,
      ACCT_SESSION_ID => $RAD_REQUEST->{'Acct-Session-Id'},
    });

    if ($ip eq '-1') {
      $_RAD_REPLY{'Reply-Message'} = "NO_FREE_POOL_IP (USED: $self->{USED_IPS})";
      return 1, \%_RAD_REPLY;
    }
    elsif ($ip eq '0') {
      #my $m = `echo "ADD_CALLS Session  Port: $RAD_REQUEST->{'NAS-Port-Id'} U: $RAD_REQUEST->{'User-Name'}" >> /tmp/mx80`;
      my $sql = "INSERT INTO `internet_online`
       (status, user_name, started, nas_ip_address, nas_port_id, framed_ip_address,
         cid, connect_info, nas_id, tp_id, uid, guest, lupdated, service_id, acct_session_id, remote_id)
       VALUES
        ('11','" . ($self->{USER_NAME} || $_RAD_REPLY{'User-Name'}) . "', now(),
         INET_ATON('" . $RAD_REQUEST->{'NAS-IP-Address'} . "'),
         '" . $RAD_REQUEST->{'NAS-Port'} . "',
         INET_ATON('" . (($_RAD_REPLY{'Framed-IP-Address'}) ? $_RAD_REPLY{'Framed-IP-Address'} : '0.0.0.0') . "'),
         '" . $cid . "', '" . ($RAD_REQUEST->{'3GPP-User-Location-Info'} || q{}) . "',
         '$NAS->{NAS_ID}',
         '$self->{TP_ID}',
         '$self->{UID}',
         '$self->{GUEST}',
         UNIX_TIMESTAMP(),
         '" . ($self->{SERVICE_ID} || 0) . "',
         '" . $RAD_REQUEST->{'Acct-Session-Id'} . "',
         '" . $RAD_REQUEST->{'3GPP-Charging-ID'} ."');";

      $self->query($sql, 'do');
    }
    else {
      $_RAD_REPLY{'Framed-IP-Address'} = $ip;
      if ($RAD_REQUEST->{'ERX-Dhcp-Options'}) {
        $_RAD_REPLY{'Framed-IP-Netmask'} = $self->{NETMASK} if ($self->{NETMASK});
      }
    }
  }

  if ($self->{GATEWAY} && $self->{GATEWAY} ne '0.0.0.0') {
    $_RAD_REPLY{'ERX-Dhcp-Options'} = sprintf("0x0304%.2x%.2x%.2x%.2x", split(/\./x, $self->{GATEWAY}));
    $_RAD_REPLY{'Session-Timeout'} = $NAS->{NAS_ALIVE};
  }
  if ($self->{DNS}) {
    $self->{DNS} =~ s/\s//xg;
    my @dns_arr = split(/,/x, $self->{DNS});
    #push @dns_arr, $self->{DNS2} if ($self->{DNS2});
    $_RAD_REPLY{'ERX-Primary-Dns'} = $dns_arr[0] if ($dns_arr[0]);
    $_RAD_REPLY{'ERX-Secondary-Dns'} = $dns_arr[1] if ($dns_arr[1]);
  }

  # SET ACCOUNT expire date
  if ($self->{ACCOUNT_AGE} > 0 && $self->{INTERNET_EXPIRE} eq '0000-00-00') {
    $self->query("UPDATE internet_main SET expire=CURDATE() + INTERVAL ? day WHERE uid=?;", 'do',
      {
        Bind => [
          $self->{ACCOUNT_AGE},
          $self->{UID}
        ]
      }
    );
  }

  if ($NAS->{NAS_ALIVE}) {
    $_RAD_REPLY{'Acct-Interim-Interval'} = $NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});
  }

  # my $profile_sufix = ($RAD_REQUEST->{'Framed-Protocol'}) ? 'pppoe' : 'ipoe';
  # my $traffic_class_name = 'global';
  # my $traffic_types_count = 3; #$self->{TOTAL};

  if ($self->{TP_RAD_PAIRS}) {
    Auth2::rad_pairs_former($self->{TP_RAD_PAIRS}, { RAD_PAIRS => \%_RAD_REPLY });
  }

  if (length($self->{FILTER}) > 1) {
    $self->Auth2::neg_deposit_filter_former($RAD_REQUEST, $NAS, $self->{FILTER},
      { USER_FILTER => 1, RAD_PAIRS => \%_RAD_REPLY });
  }

  #Other params
  return 0, \%_RAD_REPLY;
}

# #*********************************************************
# =head2 auth_cid($RAD)
#
# =cut
# #*********************************************************
# sub auth_cid {
#   my ($self, $RAD) = @_;
#
#   my $RAD_PAIRS;
#   my $calling_station_id = $RAD->{'Calling-Station-Id'};
#   my @MAC_DIGITS_GET = ();
#   if (!$calling_station_id) {
#     $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID ''";
#     return 1, $RAD_PAIRS, "WRONG_CID ''";
#   }
#
#   my @CID_POOL = split(/;/x, $self->{CID});
#
#   foreach my $TEMP_CID (@CID_POOL) {
#     if ($TEMP_CID ne '') {
#
#       if ($TEMP_CID =~ m/([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2})/xi) {
#         $TEMP_CID = lc("$1$2.$3$4.$5$6");
#       }
#
#       if (($TEMP_CID =~ m/:/x || $TEMP_CID =~ m/\-/x)
#         && $TEMP_CID !~ /\./x) {
#         @MAC_DIGITS_GET = split(/:|-/x, $TEMP_CID);
#         my @MAC_DIGITS_NEED = split(/:|\-|\./x, $RAD->{CALLING_STATION_ID});
#         my $counter = 0;
#
#         for (my $i = 0; $i <= 5; $i++) {
#           if (defined($MAC_DIGITS_NEED[$i]) && hex($MAC_DIGITS_NEED[$i]) == hex($MAC_DIGITS_GET[$i])) {
#             $counter++;
#           }
#         }
#         return 0 if ($counter eq '6');
#       }
#
#       # If like MPD CID
#       # 192.168.101.2 / 00:0e:0c:4a:63:56
#       elsif ($TEMP_CID =~ m/\//x) {
#         $calling_station_id =~ s/\s//xg;
#         my ($cid_ip, $cid_mac) = split(/\//x, $calling_station_id, 3);
#         if ("$cid_ip/$cid_mac" eq $TEMP_CID) {
#           return 0;
#         }
#       }
#       elsif ($TEMP_CID eq $calling_station_id) {
#         return 0;
#       }
#     }
#   }
#
#   $RAD_PAIRS->{'Reply-Message'} = "WRONG_CID '$calling_station_id'";
#   return 1, $RAD_PAIRS;
# }

#**********************************************************
=head2 accounting($RAD, $NAS) Accounting section

=cut
#**********************************************************
sub accounting {
  my ($self, $RAD, $NAS, $attr) = @_;

  $self->{SUM} = 0 if (!$self->{SUM});
  my $acct_status_type = $attr->{ACCT_STATUS_TYPE} || 0; # $ACCT_TYPES{ $RAD->{'Acct-Status-Type'} };
  my $acct_session_id = $RAD->{'Acct-Session-Id'} || $RAD->{'Acct-Session-Id'} || q{};
  $RAD->{'Acct-Input-Gigawords'} = 0 if (!$RAD->{'Acct-Input-Gigawords'});
  $RAD->{'Acct-Output-Gigawords'} = 0 if (!$RAD->{'Acct-Output-Gigawords'});
  $RAD->{$input_octets} = 0 if (!$RAD->{$input_octets});
  $RAD->{$output_octets} = 0 if (!$RAD->{$output_octets});

  if ($RAD->{'ERX-Service-Session'}) {
    if ($acct_session_id =~ /(\d+):/xm) {
      $acct_session_id = $1;
    }
    return $self;
  }

  # if (length($acct_session_id) > 25) {
  #   $acct_session_id = substr($acct_session_id, 0, 24);
  # }

  #Start
  if ($acct_status_type == 1) {
    my $sql = <<'SQL';
SELECT acct_session_id, uid FROM internet_online
WHERE user_name= ?
  AND nas_id= ?
  AND (framed_ip_address=INET_ATON( ? )
  OR framed_ip_address=0) FOR UPDATE;
SQL

    $self->query($sql,
      undef,
      { Bind => [
        $RAD->{'User-Name'},
        $NAS->{NAS_ID},
        $RAD->{'Framed-IP-Address'} || '0.0.0.0'
      ] }
    );

    if ($self->{TOTAL} > 0) {
      $sql = <<'SQL';
UPDATE internet_online
SET
  status           =1,
  started          =NOW() - INTERVAL ? SECOND,
  lupdated         =UNIX_TIMESTAMP(),
  framed_ip_address=INET_ATON( ? )
WHERE
  nas_id= ?
  AND acct_session_id= ?
  AND status>3
LIMIT 1;
SQL

      my @values = (
        $RAD->{'Acct-Session-Time'} || 0,
        $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'} || '0.0.0.0',
        $NAS->{NAS_ID},
        $acct_session_id
      );

      $self->query($sql, 'do', { Bind => \@values });
    }
    else {
      $self->_add_unknown_session($RAD, $NAS, { ACCT_STATUS_TYPE => $acct_status_type });
    }
  }
  # Stop status
  elsif ($acct_status_type == 2) {
    if ($RAD->{'Acct-Session-Time'} > 5) {
      $self->Acct2::rt_billing($RAD, $NAS, { BILLING => $Billing });

      if (!$self->{errno}) {
        $RAD->{'Acct-Terminate-Cause'} = ($RAD->{'Acct-Terminate-Cause'} && defined($ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}})) ? $ACCT_TERMINATE_CAUSES{$RAD->{'Acct-Terminate-Cause'}} : 0;

        my $sql = <<'SQL';
INSERT INTO internet_log
SET
  uid                  = ? ,
  start                =NOW() - INTERVAL ? SECOND,
  tp_id                = ? ,
  duration             = ? ,
  sent                 = ? ,
  recv                 = ? ,
  sum                  = ? ,
  nas_id               = ? ,
  port_id              = ? ,
  ip                   =INET_ATON( ? ),
  cid                  = ? ,
  sent2                = ? ,
  recv2                = ? ,
  acct_session_id      = ? ,
  bill_id              = ? ,
  terminate_cause      = ? ,
  acct_input_gigawords = ? ,
  acct_output_gigawords= ?,
  guest                = ?
SQL

        my @values = (
          $self->{UID},
          $RAD->{'Acct-Session-Time'},
          $self->{TP_ID} || 0,
          $RAD->{'Acct-Session-Time'},
          $RAD->{$output_octets},
          $RAD->{$input_octets},
          $self->{CALLS_SUM} + $self->{SUM},
          $NAS->{NAS_ID},
          $RAD->{'NAS-Port'} || q{},
          $RAD->{'Framed-IP-Address'} || '0.0.0.0',
          $RAD->{'Calling-Station-Id'} || '',
          $RAD->{OUTBYTE2} || 0,
          $RAD->{INBYTE2} || 0,
          $acct_session_id,
          $self->{BILL_ID},
          $RAD->{'Acct-Terminate-Cause'},
          $RAD->{'Acct-Input-Gigawords'},
          $RAD->{'Acct-Output-Gigawords'},
          $self->{GUEST} || 0
        );

        $self->query($sql, 'do', { Bind => \@values });
      }
      else {
        if ($self->{errno} == 2) {
          delete $self->{errno};
          return $self;
        }
        #DEbug only
        if ($CONF->{ACCT_DEBUG}) {
          use POSIX qw(strftime);
          my $DATE_TIME = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time));
          `echo "$DATE_TIME $self->{UID} - $RAD->{'User-Name'} / $acct_session_id / Time: $RAD->{'Acct-Session-Time'} / $self->{errstr}" >> /tmp/unknown_session.log`;
          #DEbug only end
        }
      }
    }

    $self->query('DELETE FROM internet_online WHERE  acct_session_id= ? AND nas_id= ? ;', 'do', {
      Bind => [
        $acct_session_id,
        $NAS->{NAS_ID}
      ] });
  }
  #Alive status 3
  elsif ($acct_status_type == 3) {
    if ($RAD->{'Acct-Session-Time'} < 5) {
      return $self;
    }
    $self->{SUM} = 0 if (!$self->{SUM});

    # if ($RAD->{'ERX-Service-Session'}) {
    #   $self->query("UPDATE internet_online SET
    #   ex_input_octets=$RAD->{$input_octets},
    #   ex_output_octets=$RAD->{$output_octets},
    #   ex_input_octets_gigawords='" . $RAD->{'Acct-Input-Gigawords'} . "',
    #   ex_output_octets_gigawords='" . $RAD->{'Acct-Output-Gigawords'} . "',
    #   status='$acct_status_type'
    # WHERE
    #   acct_session_id='" . $acct_session_id . "'
    #   AND nas_id='$NAS->{NAS_ID}' LIMIT 1;", 'do'
    #   );
    #
    #   return $self;
    # }

    $self->Acct2::rt_billing($RAD, $NAS, { BILLING => $Billing });

    # Can't find online records
    if ($self->{errno} && $self->{errno} == 2) {
      $self->auth($RAD, $NAS, { GET_USER => 1 });
      $RAD->{'User-Name'} = $self->{LOGIN} || $self->{USER_NAME} || $RAD->{'ERX-Dhcp-Mac-Addr'};
      #}
      #else {
      #   $self->query("SELECT u.uid, internet.tp_id, internet.id AS service_id
      #     FROM users u
      #     INNER JOIN internet_main internet ON (u.uid=internet.uid)
      #     WHERE u.id= ? ;",
      #     undef,
      #     { INFO  => 1, Bind => [ $RAD->{'User-Name'} ] });
      # }

      #Lost session debug
      my $debug = 0;
      if ($debug) {
        my $info_rr = '';
        if (!$self->{UID}) {
          foreach my $k (sort keys %$RAD) {
            my $v = $RAD->{$k};
            $info_rr .= "$k, $v\n";
          }
        }
        `echo "Lost session USER_NAME: $RAD->{'User-Name'} UID: $self->{UID} TIME: $RAD->{'Acct-Session-Time'}\n$info_rr" >> /tmp/lost_session`;
        #=== Lost session debug
      }

      my $sql = <<"SQL";
  REPLACE INTO internet_online SET
    status= ? ,
    user_name= ? ,
    started=NOW() - INTERVAL ? SECOND,
    lupdated=UNIX_TIMESTAMP(),
    nas_ip_address= ? ,
    nas_port_id= ? ,
    acct_session_id= ? ,
    framed_ip_address=INET_ATON( ? ),
    cid= ? ,
    connect_info= ? ,
    acct_input_octets= ? ,
    acct_output_octets= ? ,
    acct_input_gigawords= ? ,
    acct_output_gigawords= ? ,
    nas_id= ? ,
    tp_id= ? ,
    uid= ? ,
    guest = ?,
    acct_session_time = ?,
    service_id = ?,
    switch_mac = ?,
    switch_port = ?,
    remote_id = ?
SQL

      my @values = (
        '9',
        $RAD->{'User-Name'} || '',
        $RAD->{'Acct-Session-Time'} || 0,
        $NAS->{IP},
        $RAD->{'NAS-Port'} || 0,
        $acct_session_id,
        $RAD->{'Framed-IP-Address'} || '0.0.0.0',
        $RAD->{'Calling-Station-Id'} || '',
        $RAD->{'3GPP-User-Location-Info'} || $RAD->{'NAS-Port-Id'} || $RAD->{'Connect-Info'},
        $RAD->{$input_octets},
        $RAD->{$output_octets},
        $RAD->{'Acct-Input-Gigawords'},
        $RAD->{'Acct-Output-Gigawords'},
        $NAS->{NAS_ID},
        $self->{TP_ID} || 0,
        $self->{UID} || 0,
        ($self->{UID} && !$self->{GUEST}) ? 0 : 1,
        $RAD->{'Acct-Session-Time'} || 0,
        $self->{SERVICE_ID} || 0,
        $self->{NAS_MAC} || q{},
        $self->{PORT} || q{},
        $RAD->{'3GPP-Charging-ID'}
      );
      $self->query($sql,'do', { Bind => \@values });
      return $self;
    }
    else {
      my $ex_octets = '';
      if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
        $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
      }

      my $sql = <<"SQL";
  UPDATE internet_online SET
    status=?,
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets=?,
    acct_output_octets=?,
    $ex_octets
    lupdated=UNIX_TIMESTAMP(),
    sum=sum + ?,
    framed_ip_address=INET_ATON( ? ),
    acct_input_gigawords= ?,
    acct_output_gigawords= ?
  WHERE
    acct_session_id=?
    AND nas_id= ?
  LIMIT 1;
SQL

      my @values = (
        $acct_status_type,
        $RAD->{$input_octets},
        $RAD->{$output_octets},
        $self->{SUM},
        $RAD->{'Framed-IP-Address'} || $RAD->{'Assigned-IP-Address'},
        $RAD->{'Acct-Input-Gigawords'},
        $RAD->{'Acct-Output-Gigawords'},
        $acct_session_id,
        $NAS->{NAS_ID}
      );

      $self->query($sql, 'do', { Bind => \@values });
    }
  }
  else {
    $self->{errno} = 1;
    $self->{errstr} = "ACCT [" . $RAD->{'User-Name'} . "] Unknown accounting status: " > $RAD->{'Acct-Status-Type'} . " (" . $acct_session_id . ")";
  }

  if ($self->{errno}) {
    $self->{errno} = 1;
    $self->{errstr} = "ACCT " . $RAD->{'Acct-Status-Type'} . " SQL Error";
    return $self;
  }

  if (($CONF->{s_detalization} || $self->{DETAIL_STATS}) && $self->{UID}) {
    $self->accounting_details($RAD, $NAS, { ACCT_STATUS_TYPE => $acct_status_type });
  }

  return $self;
}


#**********************************************************
=head2 _add_unknown_session($RAD)

  Arguments:
    $RAD,
    $NAS,
    $attr
      ACCT_STATUS_TYPE

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub _add_unknown_session {
  my ($self, $RAD, $NAS, $attr) = @_;

  #`echo "ADD UNKNOWN: $RAD->{'User-Name'} / $RAD->{'Acct-Status-Type'} " >> /tmp/unknown `;

  my $guest_mode = '';
  $self->auth($RAD, $NAS, { GET_USER => 1 });
  if ($self->{UID}) {
    $self->{UID} = $self->{UID};
    $self->{SERVICE_ID} = $self->{SERVICE_ID};

    if ($self->{GUEST}) {
      $guest_mode = ', guest=1';
    }
  }
  else {
    $guest_mode = ', guest=1';
  }

  my $sql = <<"SQL";
  REPLACE INTO internet_online SET
    status= ? ,
    user_name= ? ,
    started=NOW() - INTERVAL ? SECOND,
    lupdated=UNIX_TIMESTAMP(),
    nas_ip_address= ? ,
    nas_port_id= ? ,
    acct_session_id= ? ,
    framed_ip_address=INET_ATON( ? ),
    cid= ? ,
    connect_info= ? ,
    nas_id= ? ,
    tp_id= ? ,
    uid= ? ,
    service_id = ? ,
    hostname = ? ,
    remote_id = ?
    $guest_mode
SQL

  my @values = (
    $attr->{ACCT_STATUS_TYPE},
    $RAD->{'User-Name'} || '',
    $RAD->{'Acct-Session-Time'} || 0,
    $NAS->{IP},
    $RAD->{'NAS-Port'} || 0,
    $RAD->{'Acct-Session-Id'} || 'undef',
    $RAD->{'Framed-IP-Address'},
    $RAD->{'Calling-Station-Id'},
    ($RAD->{'3GPP-User-Location-Info'} || q{}) . 'LOST_START_SESSION',
    $NAS->{'NAS_ID'},
    $self->{'TP_ID'} || 0,
    $self->{'UID'} || 0,
    $self->{'SERVICE_ID'} || 0,
    $RAD->{'3GPP-IMEISV'},
    $RAD->{'3GPP-Charging-ID'}
  );

  $self->query($sql, 'do', { Bind => \@values  });

  $sql = << "SQL";
  DELETE FROM internet_online WHERE nas_id= ? AND acct_session_id='IP'
  AND (framed_ip_address=INET_ATON( ? ) OR UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started) > 120 );
SQL

  $self->query($sql, 'do', { Bind => [ $NAS->{NAS_ID}, $RAD->{'Framed-IP-Address'} ] });

  return 1;
}


=head1 AUTHOR

  ABillS Team
  ~AsmodeuS~ (http://abills.net.ua/)
  2012-2025

=head1 COPYRIGHT

  Copyright (с) 2003-2025 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://abills.net.ua/

=cut


1;

