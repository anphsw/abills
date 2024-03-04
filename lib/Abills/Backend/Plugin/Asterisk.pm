package Abills::Backend::Plugin::Asterisk;
use strict;
use warnings FATAL => 'all';

use parent 'Abills::Backend::Plugin::BasePlugin';

use Abills::Base qw/in_array/;
use Encode;
use Users;
use Callcenter::db::Callcenter;
use Admins;
use POSIX qw(strftime);

my Users $Users;
my Callcenter $Callcenter;
my Admins $Admins;


# Used in local thread and can't be global
my (
  $db,
  %conf
);

our (@MODULES, $DATE, $TIME);

use Abills::Backend::Log;
our Abills::Backend::Log $Log;
my $log_user = ' Asterisk ';

# DEBUGGING EVENTS ( Will be removed )
my $Event_log = Abills::Backend::Log->new('FILE', 4, 'Asterisk debug', {
  FILE => ('/usr/abills/var/log/event_asterisk.log'),
});
# DEBUGGING EVENTS

use Abills::Backend::Defs;
use Abills::Backend::Plugin::Websocket::API;
my Abills::Backend::Plugin::Websocket::API $websocket_api = get_global('WEBSOCKET_API');

# Cache
my %calls_statuses = ();
my @skip_nums = ();

#**********************************************************
=head2 new($db, $admin, $CONF)
 
  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($CONF) = @_;

  %conf = %{$CONF};

  $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
    CHARSET => $conf{dbcharset},
    SCOPE   => 2
  });

  require Service;
  Service->import();

  $Admins = Admins->new($db, $CONF);
  $Users = Users->new($db, $Admins, $CONF);
  $Callcenter = Callcenter->new($db, $Admins, $CONF);

  my $self = {
    db    => $db,
    admin => $Admins,
    conf  => $CONF,
  };

  if ($conf{CALLCENTER_SKIP_LOG}) {
    @skip_nums = split(/,\s?/, $conf{CALLCENTER_SKIP_LOG});
  }

  bless($self, $class);

  $DATE = strftime("%Y-%m-%d", localtime(time));
  $TIME = strftime("%H:%M:%S", localtime(time));

  return $self;
}

#**********************************************************
=head2 init() - inits Asterisk events listener
    
=cut
#**********************************************************
sub init {
  my $self = shift;

  $self->init_connection();

  return 1;
}

#**********************************************************
=head2 init_connection() - new thread for asterisk

  Setting up Asterisk connection. Will die on error.
  All events will be passed to process_asterisk_event()

=cut
#**********************************************************
sub init_connection {
  my $self = shift;

  eval {require Asterisk::AMI};
  if ($@) {
    $Log->critical($log_user, "Can't load Asterisk::AMI perl module");
    die "Can't load Asterisk::AMI perl module";
  }

  Asterisk::AMI->import();

  $Log->info("Connecting to asterisk ");

  $self->connect_to_asterisk();
}

#**********************************************************
=head2 connect_to_asterisk() -

=cut
#**********************************************************
sub connect_to_asterisk {
  my $self = shift;

  $self->{connection_num} //= 0;

  delete $self->{astman_guard} if (exists $self->{astman_guard});

  $DATE = strftime("%Y-%m-%d", localtime(time));
  $TIME = strftime("%H:%M:%S", localtime(time));


  # Install handler for new calls
  my %handlers = (
    Newchannel        => \&process_asterisk_newchannel,
    Hangup            => \&process_asterisk_softhangup,
    Newstate          => \&process_asterisk_newstate,
    Bridge            => \&process_asterisk_bridge,
    SoftHangupRequest => \&process_asterisk_softhanguprequest,
    RTCPSent          => \&process_asterisk_rtcpsent,
    RTCPReceived      => \&process_asterisk_rtcpreceived,
    default           => \&process_default
  );

  $self->{astman_guard} = Asterisk::AMI->new(
    PeerAddr   => $conf{ASTERISK_AMI_IP},
    PeerPort   => $conf{ASTERISK_AMI_PORT},
    Username   => $conf{ASTERISK_AMI_USERNAME},
    Secret     => $conf{ASTERISK_AMI_SECRET},
    Events     => 'on', # Give us something to proxy
    Timeout    => 2,
    Blocking   => 0,
    Handlers   => \%handlers,
    Keepalive  => 3, # Send a keepalive every 3 seconds
    on_connect => sub {
      # Counter for connections
      $self->{connection_num}++;
      $Log->info("Connected to Asterisk::AMI (Connection #$self->{connection_num})");

      # Clear counter of unsuccessful tries
      $self->{connection_tries} = 0;
    },
    on_error   => sub {
      $Log->critical("Error occured on Asterisk::AMI socket : $_[1]");
      $self->reconnect_to_asterisk_in(3) or $self->exit_with_error("Unable to connect to Asterisk");
    },
    on_timeout => sub {
      $Log->critical("Connection $self->{connection_num} to Asterisk timed out");
      $self->reconnect_to_asterisk_in(2) or $self->exit_with_error("Unable to connect to Asterisk");
    }
  );

  return $self->{astman_guard};
}

#**********************************************************
=head2 reconnect_to_asterisk_in($seconds) - Controls number of tries to reconnect

  Arguments:
    $seconds - delay beetween next try
    
  Returns:
    1 if below connection tries treshold
    
=cut
#**********************************************************
sub reconnect_to_asterisk_in {
  my ($self, $seconds) = @_;

  $self->{connection_tries} //= 0;

  return 0 if ($self->{connection_tries} >= 20);

  $Log->notice("Set timer in $seconds seconds to reestablish connection to Asterisk ");

  # Create delayed action
  $self->{guard_timer} = AnyEvent->timer(
    after => $seconds,
    cb    => sub {
      $self->{connection_tries} = $self->{connection_tries} + 1;
      $Log->notice("Trying to connect again (Try #$self->{connection_tries})");
      $self->{astman_guard} = $self->connect_to_asterisk();
    }
  );

}

#**********************************************************
=head2 process_asterisk_newchannel($asterisk, $event)

  Default handler for asterisk AMI events

=cut
#**********************************************************
sub process_asterisk_newchannel {
  my ($asterisk, $event) = @_;

  my $event_ = $event->{Event} || 'NO EVENT';

  #`echo "NEWCHANNEL: $event_ // $event->{Uniqueid}" >> /tmp/sip`;

  process_default($asterisk, $event, { LOG_FILE => '/usr/abills/var/log/newchannel.log' });

  if ($event->{Event} && $event->{Event} eq 'Newchannel') {
    my $caller_number_param = $conf{CALLCENTER_ASTERISK_CALLER} || 'CallerIDNum';
    my $called_number = $event->{Exten} || q{};
    my $caller_number = $event->{$caller_number_param} || q{};
    my $call_id = $event->{Uniqueid} || q{};

    if (skip_call($caller_number, $called_number)) {
      return 0;
    }

    `echo "$DATE $TIME NEWCHANNEL: $call_id $caller_number -> $called_number" >> /tmp/sip`;

    # CALLCENTER CODE
    if (in_array('Callcenter', \@MODULES)) {
      call_processing($asterisk, {
        CALLER_NUMBER => $caller_number,
        CALLED_NUMBER => $called_number,
        CALL_ID       => $call_id,
        STATUS        => 1
      });

      # my $ivr_call_info = $Callcenter->log_list({COLS_NAME => 1, UID=> '_SHOW', UNIQUE_ID => $call_id});

      # use Abills::Base;
      # _bp("ivr", $ivr_call_info, {TO_CONSOLE=>1});
    }

    $Log->info("Got Newchannel event. $caller_number calling to $called_number ");

    notify_admin_about_new_call($called_number, $caller_number, $event);
  }
  # elsif ($event->{Event}) {
  #   my $caller_number_param = $conf{CALLCENTER_ASTERISK_CALLER} || 'CallerIDNum';
  #   my $caller_number = $event->{$caller_number_param} || q{};
  #   my $called_number = $event->{Exten} || q{};
  #
  #   my $call_id = $event->{Uniqueid} || q{-};
  #
  #   `echo "EVENT END: $event->{Event} ID: $call_id $caller_number -> $called_number" >> /tmp/sip`;
  # }

  return 1;
}

#**********************************************************
=head2 process_asterisk_newstate() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_asterisk_newstate {
  my ($asterisk, $event) = @_;

  if ($event->{ConnectedLineNum} && $event->{ChannelStateDesc} eq 'Up') {
    #my ($call_id, undef) = split('\.', $event->{Uniqueid} || q{UNKNOWN});
    my $call_id = $event->{Uniqueid} || q{UNKNOWN};

    if ($call_id) {
      $Callcenter->callcenter_change_calls({
        STATUS => 2,
        ID     => $call_id
      });

      if (!$Callcenter->{errno}) {
        $Log->info("CALL_IN_PROCESS. ID: $call_id");
      }
      else {
        $Log->info("CAN_T_CHANGE_STATUS_CALL ($Callcenter->{errno}/$Callcenter->{errstr})");
      }

      $calls_statuses{$call_id} = 2;
    }
  }

  return 1;
}


#**********************************************************
=head2 process_asterisk_softhangup($asterisk, $event) -

  Arguments:
    $asterisk
    $event

  Returns:

  Examples:

    # HangupRequest

   ================EVENT START=================
    Channel: SIP/mts_one-000058a5
    Event: HangupRequest
    Privilege: call,all
    Uniqueid: 1699956609.22696

=cut
#**********************************************************
sub process_asterisk_softhangup {
  my ($asterisk, $event) = @_;

  my $called_number = $event->{Exten} || q{};
  #my ($call_id, undef) = split('\.', $event->{Uniqueid} || q{UNKNOWN});
  my $call_id = $event->{Uniqueid} || q{UNKNOWN};

  #`echo "Event: $event->{Event} ID: $call_id" >> /tmp/sip`;

  if (defined($calls_statuses{$call_id}) && $calls_statuses{$call_id} == 2) {
    $Callcenter->callcenter_change_calls({
      STATUS => 3,
      ID     => $call_id,
      STOP   => 'NOW()'
    });

    delete $calls_statuses{$call_id};
    $Log->info("CALL_PROCESSED ID: $call_id NUMBER: $called_number");
  }
  else {
    $Callcenter->callcenter_info_calls({
      ID => $call_id
    });
    my $status = $Callcenter->{STATUS} || 0;
    my $error = $Callcenter->{errno} || '';

    if (!$error && $status < 3) {
      $Callcenter->callcenter_change_calls({
        STATUS => 4,
        ID     => $call_id,
        STOP   => 'NOW()'
      });
      $Log->warning("CALL_NOT_PROCEESSED ID: $call_id NUMBER: $called_number");
    }
  }

  return 1
}


#**********************************************************
=head2 get_admin_by_sip_number($sip_number)

  Arguments:
    $sip_number

  Returns:
    AID_ARRAY_REF

=cut
#**********************************************************
sub get_admin_by_sip_number {
  my ($sip_number) = @_;

  my %params = (SIP_NUMBER => $sip_number);

  if ($conf{CALLCENTER_ASTERISK_ADMIN_EXPR}) {
    $params{SIP_NUMBER} = '*' . $sip_number . '*';
  }

  $params{SIP_NUMBER} = $params{SIP_NUMBER} . ',ALL';

  my $admins_for_number_list = $Admins->list({
    %params,
    COLS_NAME => 1,
    PAGE_ROWS => 50,
  });

  my @admins = ();
  if ($Admins->{TOTAL}) {
    foreach my $admin_ (@$admins_for_number_list) {
      push @admins, $admin_->{aid};
    }
  }

  return \@admins;
}

#**********************************************************
=head2 notify_admin_about_new_call($called_number, $caller_number) - notifies admin in new thread

  Arguments:
    $called_number - call receiver (Admin)
    $caller_numer  - call initiatior
    
  Returns:
    UID or 0 for unknown
    
=cut
#**********************************************************
sub notify_admin_about_new_call {
  my ($called_number, $caller_number, $event) = @_;

  $called_number //= q{};
  $caller_number //= q{};
  my $admin_aids = get_admin_by_sip_number($called_number);
  my @online_aids = ();

  foreach my $aid (@$admin_aids) {
    if ($websocket_api->has_connected('admin', $aid)) {
      push @online_aids, $aid;
    }
    else {
      $Log->notice("CANT_NOTIFY AID: '" . ($aid || q{-}) . "', NUMBER: $called_number no connection");
    }
  }

  if ($#online_aids == -1) {
    $Log->notice("ONLINE_ADMIN_NOT_PRESENT NUMBER: $called_number");
    return 0;
  }

  if ($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}) {
    $caller_number =~ s/^$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
  }

  my $search_expr = '*USER_PHONE';
  if ($caller_number =~ /(\d{6,13})/) {
    $search_expr = '*USER_PHONE*';
  }
  elsif ($conf{CALLCENTER_ASTERISK_SEARCH}) {
    $search_expr = $conf{CALLCENTER_ASTERISK_SEARCH};
  }

  $search_expr =~ s/USER_PHONE/$caller_number/g;

  my $users_list = $Users->list({
    PHONE        => $search_expr,
    UID          => '_SHOW',
    FIO          => '_SHOW',
    DEPOSIT      => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    CITY         => '_SHOW',
    COMPANY_NAME => '_SHOW',
    COLS_UPPER   => 1,
    PAGE_ROWS    => 5,
    COLS_NAME    => 1
  });

  #`echo "ADMIN_NOTIFY: $caller_number -> $called_number ($search_expr)" >> /tmp/sip`;

  if (!$Users->{TOTAL} || $Users->{TOTAL} < 1) {
    # That's not an ABillS registered number
    $Log->warning("UNKNOWN_NUMBER: '$caller_number'");
    my $notification = _create_lead_notification($caller_number);
    foreach my $aid (@online_aids) {
      #`echo "POPUP NUMBER: $caller_number USER: LEAD  AID: $aid " >> /tmp/sip `;
      $websocket_api->notify_admin($aid, $notification);
    }
    return 0;
  }

  foreach my $user_info (@$users_list) {
    $Log->info("USER_INFO: $user_info->{UID} NUMBER: $caller_number ");
    my $notification = _create_user_notification({ %{$user_info}, });
    $Log->info("END Notification");
    # Notify admin by messageChecker.ParseMessage
    foreach my $aid (@online_aids) {
      $websocket_api->notify_admin($aid, $notification);
      my $uid = $user_info->{UID} || '!!! NO USER';
      #`echo "POPUP  NUMBER: $caller_number USER: $uid  AID: $aid " >> /tmp/sip `;
      #$Log->info("STOP AID: '$aid' <<< NUM: $i/$count  " . join(', ', @online_aids));
    }
  }

  return $users_list->[0]->{UID} || 0;
}


#**********************************************************
=head2 exit_with_error($error) - notifies admins, writes to log and finishes thread

  Arguments:
    $error - text for message
    
  Returns:
    TRUE or FALSE
    
=cut
#**********************************************************
sub exit_with_error {
  my ($self, $error) = @_;

  $websocket_api->notify_admin('*', {
    TITLE  => 'ASTERISK',
    TEXT   => $error || 'Unable connect to asterisk',
    MODULE => 'Callcenter'
  });

  $Log->critical("Unable to connect to Asterisk ");

  return 1;
}

#**********************************************************
=head2 _create_user_notification($user_info) -  Create JSON message from %user_info

  Arguments:
    $user_info

  Return:
    \%result

=cut
#**********************************************************
sub _create_user_notification {
  my ($user_info) = @_;

  my $tp_name = '';
  my $internet_status = 0;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    Internet->import();
    my $Internet = Internet->new($db, $Admins, \%conf);

    my $user_internet_main = $Internet->user_list({
      UID             => $user_info->{UID},
      TP_NAME         => '_SHOW',
      INTERNET_STATUS => '_SHOW',
      SORT            => 2,
      DESC            => 'DESC',
      COLS_NAME       => 1,
      #COLS_UPPER      => 1,
      PAGE_ROWS       => 1
    });

    if ($Internet->{TOTAL} && $Internet->{TOTAL} > 0) {
      $tp_name = $user_internet_main->[0]->{tp_name} || '';
      $internet_status = $user_internet_main->[0]->{internet_status} || 0;
    }
  }

  my $title = ($user_info->{FIO} || '')
    . ' ( '
    . (($user_info->{COMPANY_NAME}) ? $user_info->{COMPANY_NAME} . ' : ' . ($user_info->{LOGIN} || q{})
    : ($user_info->{LOGIN} || q{}))
    . ' )';

  our %lang;
  do "$base_dir/language/" . ($conf{default_language} || 'english') . ".pl";

  my $Service = Service->new($db, $admin, \%conf);
  my $status_list = $Service->status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
  my %service_status = ();
  foreach my $line (@$status_list) {
    my $name = $line->{name} || q{};
    if ($name =~ /\$lang\{(.+)\}/) {
      $name = $lang{$1} || $1 || q{};
    }
    $service_status{$line->{id} || 0} = $name || q{};
  }

  my $money_name = '';
  if ($conf{MONEY_UNIT_NAMES}) {
    $money_name = $conf{MONEY_UNIT_NAMES} ? (split(/;/, $conf{MONEY_UNIT_NAMES}))[0] : '';
  }

  my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
  my $deposit = sprintf('%.2f', $user_info->{DEPOSIT} || 0);

  if ($deposit < 0) {
    $deposit = "<span class='badge badge-danger'>$deposit</span>";
  }

  my $status = $service_status{$internet_status} || q{};
  if ($internet_status == 0) {
    $status = "<b class='text-success'>$status</b>";
  }
  else {
    $status = "<b class='text-warning'>$status</b>";
  }

  my $text = "$lang{DEPOSIT} : " . $deposit . " $money_name"
    . '<br>'
    . "$lang{ADDRESS} : " . ($user_info->{CITY} || '') . $build_delimiter . ($user_info->{ADDRESS_FULL} || '')
    . '<br>'
    . "$lang{TARIF_PLAN} : " . sprintf('%.25s', $tp_name)
    . '<br>'
    . "$lang{STATUS} : $status";

  my $result = {
    TITLE  => Encode::decode('utf8', $title),
    TEXT   => Encode::decode('utf8', $text),
    EXTRA  => '?index=15&UID=' . ($user_info->{UID} || 0),
    ICON   => 'fa fa-user text-success',
    CLIENT => {
      UID   => $user_info->{UID},
      LOGIN => $user_info->{LOGIN},
    }
  };

  return $result;
}

#**********************************************************
=head2 _create_lead_notification($number) -  Create JSON message from %user_info

  Arguments:
    $number

  Return:
    \%result

=cut
#**********************************************************
sub _create_lead_notification {
  my ($number) = @_;

  my %lead_info = ();

  if (in_array('Crm', \@MODULES)) {
    require Crm::db::Crm;
    Crm->import();
    my $Crm = Crm->new($db, $Admins, \%conf);
    my $crm_leads = $Crm->crm_lead_list({
      PHONE           => '*' . $number . '*',
      FIO             => '_SHOW',
      DATE            => '_SHOW',
      ADDRESS         => '_SHOW',
      ADDRESS_FULL    => '_SHOW',
      SKIP_RESPOSIBLE => 1,
      SKIP_DEL_CHECK  => 1,
      COLS_NAME       => 1,
      PAGE_ROWS       => 10
    });

    foreach my $lead (@$crm_leads) {
      $lead_info{FIO} = $lead->{fio};
      $lead_info{ID} = $lead->{id};
      $lead_info{ADDRESS_FULL} = $lead->{address_full} || $lead->{address};
      $lead_info{DATE} = $lead->{date};
      $Log->info("LEAD_FOUND: '" . ($lead->{id} || 0) . "'");
    }
  }

  our %lang;
  do "$base_dir/language/" . ($conf{default_language} || 'english') . ".pl";
  my $text = qq{$lang{PHONE} : $number};
  my $icon = 'fa fa-user text-danger';
  my $link = '?get_index=crm_leads&full=1&add_form=1&PHONE=' . $number;

  if ($lead_info{'ID'}) {
    $text = " $lang{FIO} : " . ($lead_info{FIO} || q{})
      . '<br/>' . "$lang{ADDRESS} : " . ($lead_info{ADDRESS_FULL} || q{})
      . '<br/>' . "$lang{DATE} : " . ($lead_info{DATE} || q{});
    $icon = 'fa fa-user text-warning';
    $link = '?get_index=crm_lead_info&full=1&LEAD_ID=' . ($lead_info{'ID'} || q{}) . '&PHONE=' . $number;
  }

  my %result = (
    TITLE  => Encode::decode('utf8', ($lead_info{'ID'}) ? $lang{LEAD} : "$lang{UNKNOWN} $lang{USER}"),
    TEXT   => Encode::decode('utf8', $text),
    EXTRA  => $link,
    ICON   => $icon,
    CLIENT => {
      FIO          => $lead_info{FIO} || q{},
      ADDRESS_FULL => $lead_info{ADDRESS_FULL} || q{},
      ID           => $lead_info{ID} || q{},
      DATE         => $lead_info{DATE} || q{},
      PHONE        => $lead_info{PHONE} || $number,
    }
  );

  return \%result;
}

#**********************************************************
=head2 process_default() -

  Arguments:
    $asterisk
    $event
    $attr -
      LOG_FILE

  Returns:

  Examples:

=cut
#**********************************************************
sub process_default {
  my ($asterisk, $event, $attr) = @_;

  # Start debuging events, Will be removed
  my $debug_event = "\n================EVENT START=================\n";
  foreach my $key (sort keys %{$event}) {
    $debug_event .= ($key || '') . ": " . ($event->{$key} || '') . "\n";
  }
  $debug_event .= "================EVENT END=================\n";
  if ($attr->{LOG_FILE}) {
    $Event_log->{logger}->{main_file}=$Event_log->{logger}->{file};
    $Event_log->{logger}->{file} = $attr->{LOG_FILE};
  }

  $Event_log->info($debug_event);
  if ($attr->{LOG_FILE}) {
    $Event_log->{logger}->{file} = $Event_log->{logger}->{main_file};
  }
  # End debuging events

  return 1;
}


#**********************************************************
=head2 process_asterisk_bridge($asterisk, $event)

=cut
#**********************************************************
sub process_asterisk_bridge {
  my ($asterisk, $event) = @_;

  # process_default($asterisk, $event);

  my $event_ = $event->{Event} || 'NO EVENT';
  my $bridgestate = $event->{Bridgestate} || q{};
  my $called_number = $event->{CallerID2} || q{};
  my $caller_number = $event->{CallerID1} || q{};
  my $call_id = $event->{Uniqueid} || $event->{Uniqueid1} || q{UNKNOWN};

  `echo "BRIDGE: $event_ /$bridgestate/ $call_id, $caller_number -> $called_number" >> /tmp/sip`;

  if ($bridgestate eq 'Unlink') {
    $Callcenter->callcenter_change_calls({
      STATUS => 5,
      ID     => $call_id,
      STOP   => 'NOW()'
    });

    $Log->info("BRIDGE UNLINK: $call_id NUMBER: $caller_number");
  }
  else {
    notify_admin_about_new_call($called_number, $caller_number, $event);

    $Callcenter->callcenter_change_calls({
      OPERATOR_PHONE => $called_number,
      ID             => $call_id,
      #UID            => $uid || 0,
      STATUS         => 2,
    });
  }

  return 1;
}

#**********************************************************
=head2 process_asterisk_bridge($asterisk, $event)

=cut
#**********************************************************
sub process_asterisk_softhanguprequest {
  my ($asterisk, $event) = @_;

  my $event_ = $event->{Event} || 'NO EVENT';
  #my $called_number = $event->{Exten} || q{};
  my $call_id = $event->{Uniqueid} || q{UNKNOWN};

  # process_default($asterisk, $event);
  #`echo "SOFTHANGUPREQUEST: $event_ // $call_id" >> /tmp/sip`;

  $Callcenter->callcenter_info_calls({
    ID => $call_id
  });

  my $status = $Callcenter->{STATUS} || 0;
  my $error = $Callcenter->{errno} || '';

  if (!$error && $status < 3) {
    $Callcenter->callcenter_change_calls({
      STATUS => 3,
      ID     => $call_id,
      STOP   => 'NOW()'
    });
    $Log->warning("CALL_NOT_PROCEESSED ID: $call_id NUMBER: ");
  }

  return 1;
}

#**********************************************************
=head2 process_asterisk_rtcpsent($asterisk, $event)

Kodr, [20.11.2023 17:46]
================EVENT START=================
AccountCode:
CallerIDName: +380964742263
CallerIDNum: +380964742263
Channel: SIP/380971365136-000538c9
ChannelState: 6
ChannelStateDesc: Up
ConnectedLineName: КЦ Бригадир Олександр
ConnectedLineNum: 338
Context: ext-queues
Event: RTCPSent
Exten: 1001
From: 91.225.160.15:12331
Language: uk
Linkedid: 1700494719.829805
PT: 200(SR)
Priority: 20
Privilege: reporting,all
Report0CumulativeLost:
Report0DLSR: 0.0000
Report0FractionLost:
Report0HighestSequence: 10
Report0IAJitter: 7
Report0LSR:
Report0SequenceNumberCycles:
Report0SourceSSRC: 0x6474571d
ReportCount: 1
SSRC: 0x281b4dae
SentNTP: 1700495054.196621
SentOctets: 327560
SentPackets: 16378
SentRTP: 14080
To: 100.64.64.10:16391
Uniqueid: 1700494719.829805
================EVENT END=================
=cut
#**********************************************************
sub process_asterisk_rtcpsent {
  my ($asterisk, $event) = @_;

  # process_default($asterisk, $event);
  #my $event_ = $event->{Event} || 'NO EVENT';
  #my $channel_state = $event->{ChannelStateDesc} || q{};
  my $called_number = $event->{ConnectedLineNum} || q{};
  my $caller_number = $event->{CallerIDNum} || q{};
  my $call_id = $event->{Uniqueid} || $event->{Uniqueid1} || q{UNKNOWN};

  if (skip_call($caller_number, $called_number)) {
    return 0;
  }

  if ($event->{Context} && $event->{Context} eq 'cos-all') {
    $called_number = $event->{CallerIDNum} || q{};
    $caller_number = $event->{ConnectedLineNum} || q{};
    $call_id = $event->{Linkedid} || $event->{Uniqueid} || q{UNKNOWN};
    #`echo "$DATE $TIME REPLYYY RTCP: $event_ /$channel_state/ $call_id, $caller_number -> $called_number" >> /tmp/sip`;
  }
  # else {
  #   #`echo "$DATE $TIME  RTCP: $event_ /$channel_state/ $call_id, $caller_number -> $called_number" >> /tmp/sip`;
  # }

  $Callcenter->query("SELECT status
    FROM callcenter_calls_handler
    WHERE id='$call_id';"
  );

  if (!$Callcenter->{TOTAL}) {
    call_processing($asterisk, {
      CALLER_NUMBER => $caller_number,
      CALLED_NUMBER => $called_number,
      CALL_ID       => $call_id,
      STATUS        => 15
    });

    $DATE = strftime("%Y-%m-%d", localtime(time));
    $TIME = strftime("%H:%M:%S", localtime(time));
    #`echo "$DATE $TIME N111111111111111111111111111111111 / $call_id $caller_number -> $called_number" >> /tmp/sip`;
  }
  else {
    my $call_status = $Callcenter->{list}->[0]->[0] || 0;
    if ($call_status == 1) {
      notify_admin_about_new_call($called_number, $caller_number, $event);
      $DATE = strftime("%Y-%m-%d", localtime(time));
      $TIME = strftime("%H:%M:%S", localtime(time));
      `echo "$DATE $TIME UPDATEEEEE STATUS: $call_status ID: $call_id -> $called_number ($Callcenter->{AFFECTED})" >> /tmp/sip`;
    }

    $Callcenter->callcenter_change_calls({
      OPERATOR_PHONE => $called_number,
      ID             => $call_id,
      STATUS         => 2,
      STOP           => 'NOW()'
    });
  }

  return 1;
}


#**********************************************************
=head2 call_processing($asterisk, $caller_number, $called_number, $call_id, $attr)

  Arguments:
    $asterisk
    $attr
      CALLER_NUMBER
      CALLED_NUMBER
      CALL_ID
      STATUS - CUstom status (Default: 1)

  Returns:

=cut
#**********************************************************
sub call_processing {
  my ($asterisk, $attr) = @_;

  my $caller_number = $attr->{CALLER_NUMBER} || q{};
  my $called_number = $attr->{CALLED_NUMBER} || q{};
  my $call_id = $attr->{CALL_ID} || q{};

  if ($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}) {
    $caller_number =~ s/^$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
  }

  my $newchannel_handler = sub {
    my $search_expr = '*USER_PHONE';

    if ($caller_number =~ /(\d{6,13})/) {
      $search_expr = '*USER_PHONE*';
    }
    elsif ($conf{CALLCENTER_ASTERISK_SEARCH}) {
      $search_expr = $conf{CALLCENTER_ASTERISK_SEARCH};
    }

    $search_expr =~ s/USER_PHONE/$caller_number/g;

    my $user = $Users->list({
      UID       => '_SHOW',
      PHONE     => $search_expr,
      COLS_NAME => 1,
      TEST      => 1
    });

    my $uid = 0;
    if ($Users->{TOTAL} && $Users->{TOTAL} > 0) {
      $uid = $user->[0]->{uid};
    }
    my $error = -1;
    if ($Users->{errno}) {
      $error = $Users->{errno} || '-2';
    }

    $Callcenter->callcenter_add_calls({
      USER_PHONE     => $caller_number,
      OPERATOR_PHONE => $called_number,
      ID             => $call_id,
      UID            => $uid || 0,
      STATUS         => $attr->{STATUS} || 1,
    });

    if (!$Callcenter->{errno}) {
      $Log->info("NEW_CALL ID: " . ($call_id || 'UNKNOWN'));
    }
    else {
      $Log->info("ERR_CANT_ADD_CALL ID: " . ($call_id || 'UNKNOWN'));
    }

    #$DATE = strftime("%Y-%m-%d", localtime(time));
    #$TIME = strftime("%H:%M:%S", localtime(time));
    #`echo "$DATE $TIME >>>>>>>>>>>>>>>> $caller_number  ->  $called_number ID:  $call_id UID: $uid / $search_expr ($error)" >> /tmp/sip`;
  };

  my $ivr_is_exist = 0;
  $asterisk->{guard_timer} = AnyEvent->timer(
    after => 1,
    cb    => sub {
      $Callcenter->callcenter_list_calls({
        ID => $call_id
      });

      #print "Total - $Callcenter->{TOTAL}\n";
      if (!$Callcenter->{TOTAL}) {
        $newchannel_handler->();
      }
    }
  );

  return 1;
}

#**********************************************************
=head2 skip_call($caller_number, $called_number, $call_id)

  Arguments:
    $asterisk
    $attr
      CALLER_NUMBER
      CALLED_NUMBER
      CALL_ID
      STATUS - CUstom status (Default: 1)

  Returns:
    TRUE or FALSE
=cut
#**********************************************************
sub skip_call {
  my ($caller_number, $called_number)=@_;

  if (! $caller_number || ! $called_number) {
    return 1
  }
  elsif(in_array($called_number, [ '+', 's'])) {
    return 1
  }
  elsif ($called_number =~ /unknown/ || $caller_number =~ /unknown/) {
    return 1;
  }
  elsif ($conf{CALLCENTER_SKIP_LOG}) {
    if (in_array($caller_number, \@skip_nums)) {
      $Log->info("Got Newchannel event. $caller_number calling to $called_number (Skip)");
      return 1;
    }
  }

  return 0;
}


sub process_asterisk_rtcpreceived {
  my ($asterisk, $event) = @_;

  process_default($asterisk, $event, { LOG_FILE => '/usr/abills/var/log/rtcpreceived.log' });

  return 1;
}



1;
