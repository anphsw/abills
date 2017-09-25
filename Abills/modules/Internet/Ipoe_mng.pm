=head1 NAME

  IPoE manage functions

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(mk_unique_value int2byte ip2int int2ip sec2time cmd);
use Abills::Filters;

our(
  $db,
  $admin,
  %conf,
  %LIST_PARAMS,
  $html,
  $IPV4,
  %lang,

);

use Internet::Ipoe;
use Internet::Collector;
use Internet::Sessions;

my $Internet       = Internet->new( $db, $admin, \%conf );
my $Internet_ipoe  = Internet::Ipoe->new( $db, $admin, \%conf );
my $Sessions       = Internet::Sessions->new($db, $admin, \%conf);
my $Ipoe_collector = Internet::Collector->new( $db, $admin, \%conf );
my $Nas            = Nas->new( $db, \%conf, $admin );
my $Log            = Log->new($db, \%conf);

#**********************************************************
=head2 internet_ipoe_activate($attr) - Activate ipoe session

  Arguments:
   $attr
     IP
     UID

  Results:


=cut
#**********************************************************
sub internet_ipoe_activate{
  my ($attr) = @_;

  my $ip       = '0.0.0.0';
  my $IP_INPUT = '';
  $Internet->info( $LIST_PARAMS{UID}, $attr );
  my $static_ip= $Internet->{IP};

  if ( $Internet->{STATUS} && $Internet->{STATUS} > 0 ){
    my $service_status = sel_status({ HASH_RESULT => 1 });

    if ( $user->{UID} ){
      dv_user_info();
    }
    else{
      $html->message( 'err', $lang{ERROR}, "$service_status->{$Internet->{STATUS}}", { ID => 162 } );
    }

    return 1 if (!$FORM{activate});
  }

  if ( !$user->{UID} && !$attr->{IP} ){
    $ENV{REMOTE_ADDR} = $static_ip if ($static_ip && $static_ip ne '0.0.0.0');
    $IP_INPUT = $html->form_input( 'REMOTE_ADDR', "$ENV{REMOTE_ADDR}", { OUTPUT2RETURN => 1 } );
    $ip = ($FORM{REMOTE_ADDR}) ? $FORM{REMOTE_ADDR} : $ENV{REMOTE_ADDR};
  }
  else{
    if ( !$conf{IPN_SKIP_IP_WARNING}
      && $static_ip
      && $static_ip ne '0.0.0.0'
      && ($static_ip ne $ENV{REMOTE_ADDR} && $user->{UID})){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_UNALLOW_IP} '$ENV{REMOTE_ADDR}'\n $lang{STATIC} IP: $static_ip", { ID => 320 } );
      return 1;
    }
    $ip = $attr->{IP} || $ENV{REMOTE_ADDR};
  }

  $ip =~ s/\s+//g;
  my $nas_id = 0;
  if ( !$user->{UID} && $FORM{NAS_ID} ){
    $nas_id = int( $FORM{NAS_ID} );
  }
  else{
    my $poll_list = $Nas->nas_ip_pools_list( { COLS_NAME => 1 } );
    my $ip_num = unpack( "N", pack( "C4", split( /\./, $ip ) ) );

    # Get valid NAS
    foreach my $line ( @{$poll_list} ){
      if ( ($line->{ip} <= $ip_num) && ($ip_num <= $line->{last_ip_num}) ){
        if ( $line->{nas_id} ){
          $nas_id = $line->{nas_id};
          last;
        }
      }
    }
  }

  if ( $nas_id < 1 ){
    if ( !$FORM{LOGOUT} ){
      $html->message( 'err', $lang{ERROR}, "$lang{NOT_EXIST} IP '$ip' ", { ID => 161 } );
    }

    if ( !$user->{UID} ){
      my %NAS_PARAMS_LIST = ();
      if ( $admin->{DOMAIN_ID} ){
        $NAS_PARAMS_LIST{DOMAIN_ID} = $admin->{DOMAIN_ID};
      }

      $Internet->{NAS_SEL} = $html->form_select(
        'NAS_ID',
        {
          SELECTED  => $nas_id,
          SEL_LIST  => $Nas->list( { DISABLE => 0, COLS_NAME => 1, NAS_NAME => '_SHOW', %NAS_PARAMS_LIST, SHORT => 1 } )
          ,
          SEL_KEY   => 'nas_id',
          SEL_VALUE => 'nas_name',
          MAIN_MENU => get_function_index( 'form_nas' )
        }
      );
    }
    else{
      return 1;
    }
  }

  if ( $FORM{CONNECT_INFO} && $FORM{CONNECT_INFO} =~ /Amon/ ){
    $FORM{CONNECT_INFO} = time();
    if ( $ENV{HTTP_USER_AGENT} =~ /^AMon \[(\S+)\]/ ){
      $FORM{CONNECT_INFO} .= ":" . $1;
    }
  }
  else{
    $FORM{CONNECT_INFO} = '';
  }

  if ( $FORM{ALIVE} ){
    if ( $FORM{REMOTE_ADDR} !~ /^$IPV4$/ ){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}", { ID => 321 } );
      return 1;
    }

    $Internet_ipoe->online_alive( { %FORM, LOGIN => $LIST_PARAMS{LOGIN} } );
    if ( $Internet_ipoe->{TOTAL} < 1 ){
      $html->message( 'err', $lang{ERROR}, "$lang{NOT_ACTIVE}", { ID => 322 } );
    }
    elsif ( $Internet_ipoe->{errno} ){
      _error_show( $Internet_ipoe );
    }
    else{
      $html->message( 'info', $lang{INFO}, "ALIVED" );
    }
    return 0;
  }
  elsif ( $FORM{ACTIVE} ){
    require Auth2;
    Auth2->import();
    if ( int( $nas_id ) < 1 ){
      $html->message( 'err', $lang{ERROR}, "Unknown NAS", { ID => 323 } );
    }
    else{
      my $user = $users->info( $LIST_PARAMS{UID} );
      $Internet_ipoe->online_alive(
        {
          LOGIN       => $user->{LOGIN} || $users->{LOGIN},
          REMOTE_ADDR => $ip,
        }
      );

      if ( $Internet_ipoe->{TOTAL} < 1 ){
        $Nas->info( { NAS_ID => $nas_id } );

        if ( $Internet->{SIMULTANEONSLY} && $Internet->{SIMULTANEONSLY} == 1 ){
          $Ipoe_collector->acct_stop(
            {
              USER_NAME            => $user->{LOGIN},
              NAS_ID               => $nas_id,
              STATUS               => 2,
              ACCT_TERMINATE_CAUSE => $attr->{ACCT_TERMINATE_CAUSE} || 6
            }
          );
        }

        my %DATA = (
          ACCT_STATUS_TYPE   => 1,
          USER_NAME          => $user->{LOGIN},
          SESSION_START      => 0,
          ACCT_SESSION_ID    => mk_unique_value( 10 ),
          FRAMED_IP_ADDRESS  => $ip,
          NETMASK            => $Internet->{NETMASK},
          NAS_ID             => $nas_id,
          NAS_TYPE           => $Nas->{NAS_TYPE},
          NAS_IP_ADDRESS     => $Nas->{NAS_IP},
          NAS_MNG_USER       => $Nas->{NAS_MNG_USER},
          NAS_MNG_IP_PORT    => $Nas->{NAS_MNG_IP_PORT},
          TP_ID              => $Internet->{TP_ID},
          CALLING_STATION_ID => $ip,
          NAS_PORT           => $Internet->{PORT},
          FILTER_ID          => $Internet->{FILTER_ID} || $Internet->{TP_FILTER_ID},
          CONNECT_INFO       => $FORM{CONNECT_INFO},
          UID                => $user->{UID},
        );

        my %RAD = (
          'Acct-Status-Type'   => 1,
          'User-Name'          => $user->{LOGIN},
          'Acct-Session-Id'    => mk_unique_value( 10 ),
          'Framed-IP-Address'  => $ip,
          'Calling-Station-Id' => $ip,
          'NAS-IP-Address'     => $Nas->{NAS_IP},
          'NAS-Port'           => $Internet->{PORT},
          'Filter-Id'          => $Internet->{FILTER_ID} || $Internet->{TP_FILTER_ID},
          'Connect-Info'       => $FORM{CONNECT_INFO},
        );

        my $Auth = Auth2->new( $db, \%conf );
        $Auth->{UID} = $user->{UID};
        my ($r, $RAD_PAIRS) = $Auth->internet_auth( \%RAD, $Nas, { SECRETKEY => $conf{secretkey} } );
        delete ( $RAD_PAIRS->{'Session-Timeout'} );
        if ( $RAD_PAIRS->{'Filter-Id'} ){
          $DATA{FILTER_ID} = $RAD_PAIRS->{'Filter-Id'};
        }
        else{
          while (my ($k, $v) = each %{$RAD_PAIRS}) {
            $DATA{FILTER_ID} .= "$k=$v, ";
          }
        }

        if ( $r == 1 ){
          $html->message( 'err', $lang{ERROR}, "$RAD_PAIRS->{'Reply-Message'}", { ID => 324 } );
          $Log->log_add(
            {
              LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
              ACTION    => 'AUTH',
              USER_NAME => $user->{LOGIN} || '-',
              MESSAGE   => "$RAD_PAIRS->{'Reply-Message'}",
              NAS_ID    => $nas_id
            }
          );
        }
        else{
          $Internet_ipoe->user_status( { %DATA } );
          $DATA{NAS_PORT} = $Internet_ipoe->{PORT} || $DATA{NAS_PORT} || 0;
          internet_ipoe_change_status( { STATUS => 'ONLINE_ENABLE', %DATA } );

          if ( $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER} !~ /index.cgi/ && $html->{SID} ){
            print "Location: $ENV{HTTP_REFERER}" . "\n\n";
            exit;
          }
        }
      }
      else{
        $html->message( 'info', $lang{INFO}, "$lang{ACTIVATE}" );
      }
    }
  }
#  elsif ( $FORM{LOGOUT} ){
#    my $user = $users->info( $LIST_PARAMS{UID} );
#    my $online_list = $Sessions->online(
#      {
#        USER_NAME       => $user->{LOGIN},
#        ACCT_SESSION_ID => $FORM{SESSION_ID},
#        CLIENT_IP       => '_SHOW',
#        NAS_PORT_ID     => '_SHOW'
#      }
#    );
#
#    if ( $Sessions->{TOTAL} < 1 ){
#      $html->message( 'err', $lang{ERROR}, "$lang{NOT_EXIST} $lang{SESSIONS}", {  ID => 325 } );
#      return 0;
#    }
#
#    $ip = $online_list->[0]->{client_ip};
#    my $nas_port_id = $online_list->[0]->{nas_port_id};
#    my $user_name = $online_list->[0]->{user_name};
#    $Nas->info( { NAS_ID => $online_list->[0]->{nas_id} } );
#
#    if (_error_show($Nas)){
#      return 0;
#    }
#
#    if ( $Nas->{NAS_TYPE} eq 'ipcad' || $Nas->{NAS_TYPE} eq 'other' || $Nas->{NAS_TYPE} eq 'dhcp' ){
#      internet_ipoe_change_status(
#        {
#          STATUS                 => 'HANGUP',
#          USER_NAME            => $user->{LOGIN},
#          FRAMED_IP_ADDRESS    => $ip,
#          NETMASK              => $Internet->{NETMASK},
#          ACCT_TERMINATE_CAUSE => 1,
#          UID                  => $LIST_PARAMS{UID},
#          FILTER_ID            => $Internet->{FILTER_ID} || $Internet->{TP_FILTER_ID},
#          NAS_ID               => $Nas->{NAS_ID},
#          NAS_IP_ADDRESS       => $Nas->{NAS_IP},
#          NAS_MNG_USER         => $Nas->{NAS_MNG_USER},
#          NAS_MNG_IP_PORT      => $Nas->{NAS_MNG_IP_PORT},
#        }
#      );
#    }
#    else{
#      require Abills::Nas::Control;
#      Abills::Nas::Control->import();
#      my $Nas_cmd = Abills::Nas::Control->new( $db, \%conf );
#      $Nas_cmd->hangup(
#        $Nas,
#        $nas_port_id,
#        $user_name,
#        {
#          ACCT_SESSION_ID   => "$FORM{SESSION_ID}",
#          FRAMED_IP_ADDRESS => $ip || '0.0.0.0',
#          UID               => $user->{LOGIN}
#        }
#      );
#    }
#    $html->message( 'info', $lang{INFO}, "$lang{DISABLE} IP: $ip" );
#  }

#  my @ACTION = ('ACTIVE', "$lang{LOGON}");
#  my %HIDDEN = ();
#  my $table;
#  my $online_session = '';
#
#  my $list = $Sessions->online( {
#    USER_NAME          => '_SHOW',
#    CLIENT_IP          => '_SHOW',
#    DURATION           => '_SHOW',
#    ACCT_INPUT_OCTETS  => '_SHOW',
#    ACCT_OUTPUT_OCTETS => '_SHOW',
#    ACCT_SESSION_ID    => '_SHOW',
#    ALL                => 1,
#    UID                => $LIST_PARAMS{UID}
#  } );
#
#  if ( $Sessions->{TOTAL} > 0 ){
#    $table = $html->table(
#      {
#        width       => '100%',
#        caption     => "Online",
#        title_plain => [ "$lang{USER}", "IP", "$lang{DURATION}", "$lang{RECV}", "$lang{SENT}", '-' ],
#        qs          => $pages_qs,
#        ID          => 'IPN_ONLINE'
#      }
#    );
#
#    my %online_ips = ();
#    foreach my $online ( @{$list} ){
#      $online_ips{$ip} = 1;
#
#      if ( $online->{client_ip} eq $ip && $user->{UID} ){
#        if ( $online->{uid} == $LIST_PARAMS{UID} ){
#          @ACTION = ('LOGOUT', "$lang{HANGUP}");
#          $HIDDEN{SESSION_ID} = $online->{acct_session_id};
#          if ( $online->{status} && $online->{status} == 11 ){
#            $html->message( 'err', $lang{ERROR}, $lang{DISABLE}, {  ID => 326 } );
#            return 0;
#          }
#        }
#        else{
#          $html->message( 'err', $lang{ERROR}, "$lang{IP_IN_USE}", { ID => 327 } );
#          return 0;
#        }
#      }
#
#      $table->addrow( $online->{user_name},
#        $online->{client_ip},
#        $online->{duration},
#        int2byte( $online->{acct_input_octets} ),
#        int2byte( $online->{acct_output_octets} ),
#        $html->button( "$lang{HANGUP}",
#          "index=$index&UID=$LIST_PARAMS{UID}&LOGOUT=1&SESSION_ID=$online->{acct_session_id}&REMOTE_ADDR=$online->{client_ip}"
#            . (($html->{SID}) ? "&sid=$html->{SID}" : '')
#          , { class => 'off' } ) )
#        if ($online->{uid} && $LIST_PARAMS{UID} && $online->{uid} == $LIST_PARAMS{UID});
#    }
#
#    $online_session = $table->show( { OUTPUT2RETURN => 1 } );
#  }
#  else{
#    @ACTION = ('ACTIVE', "$lang{LOGON}");
#  }
#
#  $HIDDEN{sid} = $html->{SID} if ($html->{SID});
#
#  $html->tpl_show(
#    _include( 'ipn_form_active', 'Ipn' ),
#    {
#      %{$attr},
#      IP                     => (!$IP_INPUT) ? $ip : '',
#      IP_INPUT_FORM          => $IP_INPUT,
#      NAS_ID                 => ($nas_id) ? $nas_id : undef,
#      UID                    => $LIST_PARAMS{UID},
#      ACCT_INTERIUM_INTERVAL => $conf{AMON_INTERIUM_UPDATE} || 120,
#      ACTION                 => $ACTION[0],
#      ACTION_LNG             => $ACTION[1],
#      ONLINE                 => $online_session,
#      INDEX                  => get_function_index( 'ipn_user_activate' ),
#      NAS_SEL                => $Internet_ipoe->{NAS_SEL},
#      %HIDDEN
#    },
#    { ID => 'ipn_form_active' }
#  );

  return 1;
}


#**********************************************************
=head2 internet_ipoe_change_status($attr)

  Arguments:
    $attr
      FRAMED_IP_ADDRESS
      NETMASK
      STATUS
      USER_NAME
      ACCT_SESSION_ID
      FILTER_ID
      UID
      NAS_PORT
      DEBUG

  Returns:

=cut
#**********************************************************
sub internet_ipoe_change_status{
  my ($attr) = @_;

  if ( $attr->{FRAMED_IP_ADDRESS} !~ /^$IPV4$/ ){
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}", { ID => 330 } );
    return 0;
  }

  my $ip        = $attr->{FRAMED_IP_ADDRESS};
  my $netmask   = $attr->{NETMASK} || '32';
  my $STATUS    = $attr->{STATUS} || '';
  my $USER_NAME = $attr->{USER_NAME} || '';
  my $ACCT_SESSION_ID = $attr->{ACCT_SESSION_ID} || '';
  my $FILTER_ID = $attr->{FILTER_ID} || '';
  my $uid       = $attr->{UID} || 0;
  my $PORT      = $attr->{NAS_PORT} || 0;
  my $DEBUG     = $attr->{DEBUG} || 0;

  my $speed_in = 0;
  my $speed_out = 0;

  my $list = $Internet->get_speed( { UID => $uid } );
  if ( $Internet->{TOTAL} > 0 ){
    $speed_in = $list->[0]->[3] || 0;
    $speed_out = $list->[0]->[4] || 0;
  }

  #netmask to bitmask
  if ( $netmask ne '32' ){
    my $ips = 4294967296 - ip2int( $netmask );
    $netmask = 32 - length( sprintf( "%b", $ips ) ) + 1;
  }

  my $num = 0;
  if ( $uid && $conf{IPN_FW_RULE_UID} ){
    $num = $uid;
  }
  else{
    my @ip_array = split( /\./, $ip, 4 );
    $num = $ip_array[3];
  }

  my $rule_num = $conf{IPN_FW_FIRST_RULE} || 20000;
  $rule_num = $rule_num + 10000 + $num;
  my $cmd;

  #Enable IPN Session
  if ( $STATUS eq 'ONLINE_ENABLE' ){
    $cmd = $conf{INTERNET_IPOE_START};
    $html->message( 'info', $lang{INFO}, "$lang{ENABLE} IP: $ip" ) if (!$attr->{QUICK});
    $Sessions->online_update(
      {
        USER_NAME       => $USER_NAME,
        ACCT_SESSION_ID => $ACCT_SESSION_ID,
        STATUS          => 10
      }
    );

    $Log->log_add(
      {
        LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
        ACTION    => 'AUTH',
        USER_NAME => $USER_NAME || '-',
        MESSAGE   => "IP: $ip",
        NAS_ID    => $attr->{NAS_ID}
      }
    );

  }
  elsif ( $STATUS eq 'ONLINE_DISABLE' ){
    $cmd = $conf{INTERNET_IPOE_STOP};

    $html->message( 'info', $lang{INFO}, "$lang{DISABLE} IP: $ip" );
    $Sessions->online_update(
      {
        USER_NAME       => $USER_NAME,
        ACCT_SESSION_ID => $ACCT_SESSION_ID,
        STATUS          => 11
      }
    );
  }
  elsif ( $STATUS eq 'HANGUP' ){
    $Ipoe_collector->acct_stop( { %{$attr}, %FORM, ACCT_TERMINATE_CAUSE => $attr->{ACCT_TERMINATE_CAUSE} || 6 } );

    $cmd = $conf{INTERNET_IPOE_STOP};

    if ( !$attr->{QUICK} ){
      my $message =
        "\n IP:  "
          . int2ip( $Ipoe_collector->{FRAMED_IP_ADDRESS} )
          . "\n$lang{RECV}:  "
          . int2byte( $Ipoe_collector->{INPUT_OCTETS} )
          . "\n$lang{SENT}:  "
          . int2byte( $Ipoe_collector->{OUTPUT_OCTETS} )
          . "\n$lang{TOTAL}:  "
          . int2byte( $Ipoe_collector->{INPUT_OCTETS} + $Ipoe_collector->{OUTPUT_OCTETS} )
          . "\n$lang{DURATION}:  "
          . sec2time( $Ipoe_collector->{ACCT_SESSION_TIME}, { str => 1 } )
          . "\n$lang{SUM}:  "
          . ($Ipoe_collector->{SUM} || 0);

      $html->message( 'info', $lang{INFO}, $message );
    }
  }

  #my $bitmask = $netmask;

  if ( !$cmd ){
    print "Error: Not defined external command for status: $STATUS\n";
    return 0;
  }
  else{
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%NUM/$rule_num/g;
    $cmd =~ s/\%SPEED_IN/$speed_in/g if ($speed_in > 0);
    $cmd =~ s/\%SPEED_OUT/$speed_out/g if ($speed_out > 0);
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%PORT/$PORT/g;
    $cmd =~ s/\%DEBUG//g;

    if ( $attr->{NAS_IP_ADDRESS} ){
      $ENV{NAS_IP_ADDRESS} = $attr->{NAS_IP_ADDRESS};
      $ENV{NAS_MNG_USER} = $attr->{NAS_MNG_USER};
      $ENV{NAS_MNG_IP_PORT} = $attr->{NAS_MNG_IP_PORT};
      $ENV{NAS_ID} = $attr->{NAS_ID};
      $ENV{NAS_TYPE} = $attr->{NAS_TYPE} || '';
    }

    print "IPN: $cmd\n" if ($DEBUG > 4);
    cmd( $cmd );
  }

  if ( $conf{IPN_FILTER} && ($STATUS ne 'ONLINE_ENABLE' || ($STATUS eq 'ONLINE_ENABLE' && $FILTER_ID ne '')) ){
    $cmd = "$conf{IPN_FILTER}";
    $cmd =~ s/\%STATUS/$STATUS/g;
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%FILTER_ID/$FILTER_ID/g;
    $cmd =~ s/\%UID/$uid/g;
    $cmd =~ s/\%PORT/$PORT/g;
    cmd( $cmd );
    print "IPN FILTER: $cmd\n" if ($DEBUG > 4);
  }

  return 1;
}

1;