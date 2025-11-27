=head1 NAME

  Iptv::Monitoring - IPTV monitoring and online sessions management

=head1 SYNOPSIS

  Functions for monitoring IPTV devices and managing online sessions

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  %conf,
  $admin,
  %lang,
  @bool_vals,
  @state_colors,
  %permissions
);

our Abills::HTML $html;
use Abills::Base qw(mk_unique_value int2ip int2byte cmd in_array json_former);

our $Iptv = Iptv->new($db, $admin, \%conf);

use Iptv::Services;
my $Iptv_services = Iptv::Services->new($db, $admin, \%conf, { lang => \%lang, ENABLE_FEES_MESSAGES => 1 });

use Iptv::Init qw/init_iptv_service/;

#*******************************************************************
=head2 iptv_monitoring() - IPTV monitoring main function

  Displays monitoring interface for IPTV devices
  If SERVICE_ID is provided, shows service-specific monitoring
  Otherwise shows online sessions

  Arguments:
    Uses global %FORM hash with:
      SERVICE_ID - Service ID to monitor (optional)

  Returns:
    Nothing (outputs HTML directly)

=cut
#*******************************************************************
sub iptv_monitoring {

  my $services = $html->form_main({
    CONTENT => tv_services_sel({ AUTOSUBMIT => 'form', ALL => 1, SKIP_DEF_SERVICE => 1, SERVICE_ID => '' }),
    HIDDEN  => {
      index => $index,
      show  => 1
    },
    class   => 'form-inline ml-auto flex-nowrap',
  });
  func_menu({ $lang{NAME} => $services });

  if (!$FORM{SERVICE_ID}) {
    iptv_online();
    return;
  }

  my $Tv_service = init_iptv_service($db, $admin, \%conf, {
    SERVICE_ID => $FORM{SERVICE_ID},
    HTML       => $html,
    LANG       => \%lang
  });

  if (!$Tv_service || !$Tv_service->can('monitoring')) {
    iptv_online();
    return;
  }

  $pages_qs .= "&SERVICE_ID=$FORM{SERVICE_ID}" if ($FORM{SERVICE_ID} && $pages_qs !~ (m/&SERVICE_ID=/x));
  my $monitoring_result = $Tv_service->monitoring(\%FORM);

  if ($monitoring_result && $monitoring_result->{tables}) {
    foreach my $table_info (@{$monitoring_result->{tables}}) {
      my %all_fields = $table_info->{data_hash}[0] ? map {$_ => 1} keys %{$table_info->{data_hash}[0]} : ();
      my %default_fields = map {$_ => 1} keys %{$table_info->{titles}};
      my @hidden_fields = grep {!$default_fields{$_}} keys %all_fields;
      $table_info->{table}{qs} = $pages_qs;

      result_former({
        DEFAULT_FIELDS  => join(',', keys %default_fields),
        HIDDEN_FIELDS   => join(',', @hidden_fields),
        FUNCTION_FIELDS => $table_info->{function_fields},
        FILTER_VALUES   => $table_info->{filter_values},
        SELECT_VALUE    => $table_info->{select_value},
        FILTER_COLS     => {
          action_buttons => '_form_action_buttons',
        },
        TABLE           => $table_info->{table},
        EXT_TITLES      => $table_info->{titles},
        DATAHASH        => $table_info->{data_hash},
        DATAHASH_ORDER  => $table_info->{datahash_order},
        TOTAL           => 1,
      });
    }
  }
}

#*******************************************************************
=head2 _form_action_buttons($action_buttons) - Generate action buttons dropdown

  Creates HTML dropdown menu with action buttons

  Arguments:
    $action_buttons - Array reference with action button definitions
      Each element should be hash with:
        url   - URL for the action
        title - Button title/text

  Returns:
    HTML string with dropdown or original value if not array

=cut
#*******************************************************************
sub _form_action_buttons {
  my ($action_buttons) = @_;

  return $action_buttons if (!$action_buttons || ref $action_buttons ne 'ARRAY');

  my @html_buttons = map {
    my $url = "index=$index" . ($_->{url} || '') . $pages_qs;
    $html->button($_->{title}, $url, { class => 'dropdown-item cursor-pointer' });
  } @{$action_buttons};

  my $dropdown_button = $html->element('button', $lang{ACTION} || 'Actions', {
    class           => 'btn btn-default btn-block dropdown-toggle',
    id              => 'IptvMonitoringActionBtn',
    type            => 'button',
    'data-toggle'   => 'dropdown',
    'aria-haspopup' => 'true',
    'aria-expanded' => 'true',
    'data-boundary' => 'window'
  });

  my $ul_dropdown_elements = $html->element('div', join('', @html_buttons), {
    class             => 'dropdown-menu',
    'aria-labelledby' => 'IptvMonitoringActionBtn'
  });

  return $html->element('div', $dropdown_button . $ul_dropdown_elements, { class => 'dropdown' });
}

#*******************************************************************
=head2 iptv_online() - Display and manage IPTV online sessions

  Shows currently active IPTV sessions with options to:
    - Ping devices
    - Zap (disconnect) sessions
    - Hangup sessions (reboot devices)
    - Delete sessions from online list

  Arguments:
    Uses global %FORM hash with:
      ping    - IP address to ping
      zap     - Session ID to disconnect
      hangup  - Session ID to hangup/reboot
      del     - Session ID to delete
      dellist - List of session IDs to delete
      ZAPED   - Show zapped sessions flag

  Returns:
    1 on success

=cut
#*******************************************************************
sub iptv_online {
  require Nas;
  Nas->import();
  my $Nas = Nas->new($db, \%conf, $admin);

  my Iptv $sessions = $Iptv;

  my $message;

  if ($FORM{ping}) {
    require Internet::Diagnostic;
    Internet::Diagnostic->import('host_diagnostic');
    my $result = host_diagnostic($FORM{ping});
    $html->message('info', $lang{INFO}, $result);
  }
  elsif ($FORM{hangup}) {
    my (undef, $acct_session_id) = split('\s', $FORM{hangup});
    my $iptv_online = $Iptv->online({
      ACCT_SESSION_ID => $acct_session_id,
      ID              => '_SHOW',
      COLS_NAME       => 1,
      PAGE_ROWS       => 1,
    });

    if ($Iptv->{TOTAL} == 1) {
      my $user_info = $Iptv->user_info($iptv_online->[0]{id});
      if ($user_info->{ID}) {
        $Iptv_services->service_hangup({ ID => $user_info->{ID}, REBOOT => 1 });
      }
    }
  }
  elsif ($FORM{zap}) {
    my ($nas_id, $acct_session_id, $nas_port_id) = split(/ /, $FORM{zap}, 3);
    $sessions->zap($nas_id, $acct_session_id);
    if (_error_show($sessions, { MESSAGE => "ZAP SESSION" })) {
      return 0;
    }
    $Nas->info({ NAS_ID => $nas_id, SECRETKEY => $conf{secretkey} });
    $message = "<table width=100%>
     <tr><th colspan=2 align=left>$lang{CLOSED}</th></tr>
     <tr><td>$lang{NAS}:</td><td>$Nas->{NAS_IP} / $Nas->{NAS_INDENTIFIER}</td></tr>
     <tr><td>$lang{PORT}:</td><td>$nas_port_id</td></tr>
     <tr><td>SESSION_ID:</td><td>$acct_session_id</td></tr>
     </table>\n";
    $sessions->online({
      ACCT_SESSION_ID => $acct_session_id,
      NAS_ID          => $Nas->{NAS_ID}
    });
    if ($sessions->{TOTAL} < 1) {
      $message .= $html->button('add to log', "index=$index&tolog=$acct_session_id&nas_id=$nas_id", { BUTTON => 1 }) . "
         " . $html->button("$lang{DEL}", "index=$index&del=$acct_session_id&nas_id=$nas_id&nas_port_id=$nas_port_id",
        { BUTTON => 1 });
    }
    else {
      $message = $lang{EXIST};
      $sessions->online_del(
        {
          NAS_ID          => $nas_id,
          ACCT_SESSION_ID => $acct_session_id
        }
      );
    }
    $html->message('info', $lang{INFO}, $message);
  }
  elsif ($FORM{del} || $FORM{dellist}) {
    if ($FORM{dellist}) {
      my @sessions_list = split(/, /, $FORM{dellist});
      $sessions->online_del({ SESSIONS_LIST => \@sessions_list });
      $FORM{del} = $FORM{dellist};
    }
    else {
      $sessions->online_del({
        NAS_ID          => $FORM{nas_id},
        ACCT_SESSION_ID => $FORM{del}
      });
    }
    if (!$sessions->{errno}) {
      my $table = $html->table({
        width => '100%',
        rows  => [ [ "NAS_ID", $FORM{nas_id} ], [ "ACCT_SESSION_ID", $FORM{del} ] ]
      });
      $html->message('info', $lang{DELETED}, $table->show());
    }
  }

  my $form_link = '';
  my $cure = '';
  if ($FORM{ZAPED}) {
    $LIST_PARAMS{ZAPED} = '1';
    $form_link = $html->button('On line', "index=$index", { BUTTON => 1 });
    $cure = 'Zap';
  }
  else {
    $cure = 'Online';
  }
  %LIST_PARAMS = (
    %LIST_PARAMS,
    LOGIN       => '_SHOW',
    FIO         => '_SHOW',
    STARTED     => '_SHOW',
    DURATION    => '_SHOW',
    CLIENT_IP   => '_SHOW',
    TP_NAME     => '_SHOW',
    ONLINE_BASE => '_SHOW',
  );

  my $dub_logins = $sessions->{dub_logins};
  my Abills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $sessions,
    FUNCTION        => 'online',
    BASE_FIELDS     => 1,
    FUNCTION_FIELDS => 'iptv_ping, iptv_zap, iptv_hangup',
    EXT_TITLES      => {
      'ip'              => 'IP',
      'netmask'         => 'NETMASK',
      'speed'           => $lang{SPEED},
      'port'            => $lang{PORT},
      'CID'             => 'CID',
      'filter_id'       => 'Filter ID',
      'tp_name'         => $lang{TARIF_PLAN},
      'dv_status'       => $lang{STATUS},
      'started',        => $lang{START},
      'duration'        => $lang{DURATION},
      'last_alive'      => "Last alive",
      'iptv_expire'     => "$lang{TV} $lang{EXPIRE}",
      'acct_session_id' => "ACCT_SESSION_ID",
    },
    TABLE           => {
      width   => '100%',
      caption => "$cure",
      qs      => $pages_qs,
      ID      => 'IPTV_ONLINE',
      EXPORT  => 1,
    },
    SKIP_PAGES      => 1
  });
  my $bg = '';
  my $online = $sessions->{nas_sorted};
  my $nas_list = $Nas->list({ COLS_NAME => 1, PAGE_ROWS => 1 });

  foreach my $nas_row (@{$nas_list}) {
    $nas_row->{id} = 0;
    next if (!defined($online->{ $nas_row->{id} }));
    my $online_users = $online->{ $nas_row->{id} };

    foreach my $line (@{$online_users}) {
      my @fields_array = ();
      for (my $i = 0; $i < 1 + $sessions->{SEARCH_FIELDS_COUNT}; $i++) {
        if ($conf{EXT_BILL_ACCOUNT} && $sessions->{COL_NAMES_ARR}->[$i] eq 'ext_bill_deposit') {
          $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit},
            $_COLORS[6]) : $line->{ext_bill_deposit};
        }
        elsif ($sessions->{COL_NAMES_ARR}->[$i] eq 'deleted') {
          $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ],
            ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
        }
        elsif ($sessions->{COL_NAMES_ARR}->[$i] eq 'login') {
          $line->{login} = user_ext_menu($line->{uid}, $line->{login});
        }
        push @fields_array, $line->{ $sessions->{COL_NAMES_ARR}->[$i] };
      }

      undef($table->{rowcolor});
      undef($table->{extra});

      if (defined($dub_logins->{ $line->{login} })) {
        $bg = '#FFFF00';
      }
      elsif ($line->{status} && $line->{status} == 3) {
        $bg = '#FF0000';
      }
      else {
        $bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
      }

      $table->addrow(
        @fields_array,
        $html->button('P', "index=$index&ping=$line->{client_ip}", { TITLE => 'Ping', BUTTON => 1 }),
        $html->button('Z', "index=$index&zap=$nas_row->{id}+$line->{acct_session_id}", { TITLE => 'Zap', BUTTON => 1 })
        ,
        ($FORM{ZAPED}) ? $html->form_input('dellist', "$line->{acct_session_id}",
          { TYPE => 'checkbox', { BUTTON => 1 } }) : $html->button('H',
          "index=$index&hangup=$nas_row->{id}+$line->{acct_session_id}", { TITLE => 'Hangup', BUTTON => 1 })
      );
    }
  }

  my $table2 = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($sessions->{TOTAL}), "$form_link" ] ]
  });

  my $total = $table2->show();
  my $output = $total . $table->show();
  $table = $html->table({
    width       => '100%',
    title_plain => [ "$lang{REFRESH} (sec): " . $html->form_input('REFRESH', int(($FORM{REFRESH}) ? $FORM{REFRESH} : 0),
      { SIZE => 4 }), $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' }) ],
    cols_align  => [ 'center:d-print-none', 'center:d-print-none' ],
  });

  if ($FORM{ZAPED}) {
    $output = $html->form_main(
      {
        CONTENT => $output,
        HIDDEN  => {
          index => "$index",
          ZAPED => 1
        },
        SUBMIT  => { go => "$lang{DEL}" },
        METHOD  => 'GET'
      }
    );
  }
  else {
    $output .= $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => { index => "$index" },
        METHOD  => 'GET'
      }
    );
    $output .= $html->button('Zap All', "index=$index&zapall=1",
      { MESSAGE => "Do you realy want zap all sessions ?", BUTTON => 1 });
  }

  print $output;

  return 1;
}

1;