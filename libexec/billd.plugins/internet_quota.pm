=head1 NAME

 billd plugin

 DESCRIBE: СoA Request

 #MB : DAYS (DEFAULT: 1) : SPEED_IN : SPEED_OUT)
 $conf{INTERNET_DAY_QUOTA} = '10:1:1024:1024';


 Recomended use with Internet module

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Nas::Control;
use Radius;

our (
  $Nas,
  $argv,
  $debug,
  $Sessions,
  $Dv,
  %LIST_PARAMS,
  $debug_output,
  %conf,
  $base_dir,
);


if(! $conf{INTERNET_DAY_QUOTA}) {
  $conf{INTERNET_DAY_QUOTA} = '1024:1:5024:5024';
}

quota_check();


#**********************************************************
=head2 coa_request($attr) - CoA request

=cut
#**********************************************************
sub quota_check {

  if($debug > 6) {
    $Sessions->{debug}=1;
  }

  my ($quota, $days, $speed);
  if($conf{INTERNET_DAY_QUOTA}) {
    ($quota, $days, $speed)=split(/:/, $conf{INTERNET_DAY_QUOTA}, 3);
  }

  if($argv->{SPEED}) {
    $speed = $argv->{SPEED};
  }

  $Sessions->online(
    {
      'USER_NAME'           => '_SHOW',
      'LOGIN'               => '_SHOW',
      'NAS_PORT_ID'         => '_SHOW',
      'CLIENT_IP'           => '_SHOW',
      'DURATION'            => '_SHOW',
      'ACCT_INPUT_OCTETS'   => '_SHOW',
      'ACCT_OUTPUT_OCTETS'  => '_SHOW',
      'ACCT_SESSION_ID'     => '_SHOW',
      'LAST_ALIVE'          => '_SHOW',
      'ACCT_SESSION_TIME'   => '_SHOW',
      'DURATION_SEC'        => '_SHOW',
      'TP_ID'               => '_SHOW',
      'TP_NUM'              => '_SHOW',
      'TP_CREDIT_TRESSHOLD' => '_SHOW',
      'ONLINE_TP_ID'        => '_SHOW',
      'CONNECT_INFO'        => '_SHOW',
      'SKIP_DEL_CHECK'      => 1,
      %LIST_PARAMS,
    }
  );

  my $online_session = $Sessions->{nas_sorted};
  my $nas_list = $Nas->list( {
    %LIST_PARAMS,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    PAGE_ROWS  => 65000
  } );

  $conf{MB_SIZE}=1024 * 1024;

  foreach my $nas ( @{$nas_list} ) {
    #if don't have online users skip it
    my $l = $online_session->{ $nas->{NAS_ID} };
    next if ($#{$l} < 0);

    foreach my $online ( @{$l} ) {
      my $connect_info = $online->{CONNECT_INFO} || $online->{connect_info} || q{};
      $online->{acct_input_octets} = sprintf("%.2f", $online->{acct_input_octets} / $conf{MB_SIZE});
      $online->{acct_output_octets} = sprintf("%.2f", $online->{acct_output_octets} / $conf{MB_SIZE});
      if($debug > 1) {
        print "UID: $online->{uid} TRAFFIC: $online->{acct_input_octets}/$online->{acct_output_octets}\n";
      }

      my $total_traffic = ($online->{acct_input_octets} + $online->{acct_output_octets});

      if($speed && $total_traffic > $quota) {
        if ($connect_info =~ /QUOTA/) {
          next;
        }

        my $speed_list = $Dv->get_speed({
          UID       => $online->{uid},
          COLS_NAME => 1
        });

        print "$speed_list->[0]->{in_speed} / $speed_list->[0]->{out_speed}\n";

        if ($debug) {
          print "QUOTA: $total_traffic > $quota SPEED: $speed\n";
          if ($debug > 6) {
            next;
          }
        }

        $Sessions->online_update({
           CONNECT_INFO    => "QUOTA:$speed",
           USER_NAME       => $online->{user_name},
           ACCT_SESSION_ID => $online->{acct_session_id}
        });
      }
      elsif($connect_info =~ /QUOTA:(.+)/) {
        my $speed_list = $Dv->get_speed({
          UID       => $online->{uid},
          COLS_NAME => 1
        });

        $Sessions->online_update({
          CONNECT_INFO    => "-",
          USER_NAME       => $online->{user_name},
          ACCT_SESSION_ID => $online->{acct_session_id}
        });

        print "TP_SPEED: $speed_list->[0]->{in_speed} / $speed_list->[0]->{out_speed}\n";
        $speed = "$speed_list->[0]->{in_speed}:$speed_list->[0]->{out_speed}";
      }

      if($argv->{SPEED}) {
        $speed = $argv->{SPEED};
      }

      if($speed) {
        coa_request({
          NAS_ID    => $nas->{NAS_ID},
          USER_NAME => $online->{user_name},
          CLIENT_IP => $online->{client_ip},
          SPEED     => $speed
        });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 coa_request($attr) - CoA request

   Arguments:
     $attr

   Results:


=cut
#**********************************************************
sub coa_request {
  my ($attr) = @_;

  print "CoA Request\n";

  my $user_name = $attr->{USER_NAME} || q{};
  my $user_ip   = $attr->{CLIENT_IP} || q{};
  my $command   = $attr->{COMMAND} || q{account-status-query};

  my @request = (
    { 'User-Name'          => $user_name  },
    { 'Cisco-Account-Info' => "S$user_ip" },
  );

  if($attr->{SPEED}) {
    my ($speed_in, $speed_out)=split(/:/, $attr->{SPEED});

    my $speed_in_rule = q{};
    if ($speed_in > 0) {
      $speed_in_rule = "D;" . ($speed_in * 1000) . ";" . ($speed_in / 8 * 1000) . ';' . ($speed_in / 4 * 1000) . ';';
    }

    my $speed_out_rule = q{};
    if ($speed_out > 0) {
      $speed_out_rule = "U;" . ($speed_out * 1000) . ";" . ($speed_out / 8 * 1000) . ';' . ($speed_out / 4 * 1000);
    }

    if ($speed_in_rule || $speed_out_rule) {
      push @request, { 'Cisco-Service-Info' => "Q$speed_out_rule;$speed_in_rule" };
    }
  }
  else {
    push @request, { 'Cisco-AVPair'       => "subscriber:command=$command" };
  }


  if(! $attr->{NAS_ID}) {
    print "Select NAS: NAS_IDS=2\n";
    return 1;
  }

  $Nas->info({ NAS_ID => $attr->{NAS_ID} });

  my $nas_control = {};
  bless($nas_control, 'nas_control');

  _coa_request($nas_control, \@request, {
    %$Nas,
    COA => 1
  });

  if($nas_control->{errno}) {
    print "Error: $nas_control->{message}\n";
  }

  my $rad_reply = $nas_control->{responce};

  foreach my $r ( @$rad_reply ) {
    print "$r->{Name} -> $r->{Name}\n";
  }

  return 1;
}

#**********************************************************
=head2 coa_request($attr) - CoA request

=cut
#**********************************************************
sub _coa_request {
  my $self = shift;
  my ($request, $attr) = @_;

  if(! $request) {
    $self->{message}='No CoA request';
    $self->{errno}=1;
    return $self
  }

  my $ip = $attr->{NAS_MNG_IP_PORT} || '127.0.0.1';
  my $password = $attr->{NAS_MNG_PASSWORD} || 'secretpass';

  my $type;

  my $r = Radius->new(
    Host   => $ip,
    Secret => $password,
    Debug  => $attr->{DEBUG} || 0
  ) or print "Can't connect '$ip' $!\n";

  $conf{'dictionary'} = $base_dir.'/lib/dictionary' if (!$conf{'dictionary'});

  if (!-f $conf{'dictionary'}) {
    print "Can't find radius dictionary: $conf{'dictionary'}";
    return 0;
  }

  $r->load_dictionary( $conf{'dictionary'} );

  foreach my $request_param (@$request) {
    my($k, $v)=each %$request_param;
    $r->add_attributes({ Name => $k, Value => $v });
  }

  my $request_type = ($attr->{COA}) ? 'COA' : 'POD';
  if ( $attr->{COA} ){
    $r->send_packet( COA_REQUEST ) and $type = $r->recv_packet;
  }
  else{
    $r->send_packet( POD_REQUEST ) and $type = $r->recv_packet;
  }

  my $result;
  if ( !defined $type ){
    # No responce from COA/POD server
    my $message = "No responce from $request_type server '$ip'";
    $result .= $message;
    #$Log->log_print( 'LOG_DEBUG', "$USER", $message, { ACTION => 'CMD' } );
  }

  for my $rad ( $r->get_attributes ){
    $result .= "  $rad->{'Name'} -> $rad->{'Value'}\n";
  }

  print $result;

  return $self;
}


1;