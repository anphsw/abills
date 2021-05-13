=head1 NAME

 External Paysys cmds

=head1 ARGUMENTS

  IP
  UID
  NAS_TYPE=

=head1 VERSION

  VERSION: 0.03
  UPDATED: 20210317

=cut

use strict;
use warnings;
use Paysys;
use Conf;
use Time::Local;
use Data::Dumper;

our (
  $db,
  $Admin,
  %conf,
  $argv,
  $debug
);

our Internet::Sessions $Sessions;
our Nas $Nas;

my $Paysys = Paysys->new($db, $Admin, \%conf);
my $Config = Conf->new($db, $Admin, \%conf);

if ($argv->{START} || $argv->{STOP}) {
  paysys_extcmd_start();
}
else {
  run_end_command();
}

#**********************************************************
=head2 run_end_command() -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_extcmd_start {

  _log('LOG_INFO', "Start paysys external cmd");

  my $uid = $argv->{UID} || q{};

  if ($argv->{NAS_TYPE} && $argv->{NAS_TYPE} eq 'mx80') {
    my $Nas_cmd = Abills::Nas::Control->new($db, \%conf);

    if ($debug > 6) {
      $Sessions->{debug} = 1;
      $Nas->{debug} = 1;
    }

    my $sessions_list = $Sessions->online({
      UID                  => $uid,
      ACCT_SESSION_ID      => '_SHOW',
      CALLING_STATION_ID   => '_SHOW',
      FRAMED_IP_ADDRESS    => '_SHOW',
      NETMASK              => '_SHOW',
      DEBUG                => $debug,
      FILTER_ID            => '_SHOW',
      OLD_TP_ID            => '_SHOW',
      ACCT_TERMINATE_CAUSE => '_SHOW',
      GUEST                => 1,
      NAS_ID               => '_SHOW',
      USER_NAME            => '_SHOW',
      DEPOSIT              => '_SHOW',
      CREDIT               => '_SHOW',
      INTERNET             => 1
    });

    if ($Sessions->{TOTAL} > 0) {
      foreach my $online (@$sessions_list) {
        _log('LOG_DEBUG', "NAS_ID: $online->{nas_id} GUEST: $online->{guest} ACCT_SESSION_ID: $online->{acct_session_id}");

        if (($online->{credit} || 0) + ($online->{deposit} || 0) > 0) {
          next;
        }

        my $nas_info = $Nas->info({ NAS_ID => $online->{nas_id} });

        my @coa_action = ();

        if ($argv->{START}) {
          @coa_action = (
            { 'ERX-Service-Deactivate' => 'svc-guest-ipoe',
              'Acct-Session-Id'        => $online->{acct_session_id}
            },
            {
              'ERX-Service-Activate:1' => 'svc-guest-ipoe(svc-filter-in-paysys)',
              'Acct-Session-Id'        => $online->{acct_session_id}
            }
          );
        }
        else {
          @coa_action = (
            { 'ERX-Service-Deactivate' => 'svc-guest-ipoe',
              'Acct-Session-Id'        => $online->{acct_session_id}
            },
            {
              'ERX-Service-Activate:1' => 'svc-guest-ipoe(svc-filter-in-nomoney)',
              'Acct-Session-Id'        => $online->{acct_session_id}
            }
          );
        }

        $Nas_cmd->hangup(
          $nas_info,
          $online->{nas_port_id},
          $online->{user_name},
          {
            %{$nas_info},
            ACCT_SESSION_ID      => $online->{acct_session_id},
            CALLING_STATION_ID   => $online->{CID} || $online->{cid},
            FRAMED_IP_ADDRESS    => $online->{client_ip},
            NETMASK              => $online->{netmask},
            UID                  => $online->{uid},
            DEBUG                => 2, #$debug,
            FILTER_ID            => $online->{filter_id},
            OLD_TP_ID            => $online->{tp_id},
            ACCT_TERMINATE_CAUSE => 15,
            GUEST                => $online->{guest},
            INTERNET             => 1,
            COA_ACTION           => \@coa_action
          }
        );
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 run_end_command() -

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub run_end_command {
  my $end_command = ($Config->config_info({ PARAM => 'PAYSYS_EXTERNAL_END_COMMAND' }))->{VALUE};
  my $time = ($Config->config_info({ PARAM => 'PAYSYS_EXTERNAL_TIME' }))->{VALUE};

  if ($debug > 6) {
    $Paysys->{debug} = 1;
  }

  my $users_list = $Paysys->paysys_user_list({ COLS_NAME => 1, CLOSED => 0, PAGE_ROWS => 1000 });

  foreach my $user (@$users_list) {
    my ($user_date, $user_time) = split(' ', $user->{external_last_date});
    my ($user_year, $user_month, $user_day) = split('-', $user_date);
    my ($user_hours, $user_minutes, $user_seconds) = split(':', $user_time);

    my $command_start_time = timelocal(int($user_seconds), int($user_minutes), int($user_hours), int($user_day), int($user_month - 1), int($user_year));
    my $command_end_time = $command_start_time + ($time * 60);

    my ($year, $month, $day) = split('-', $DATE);
    my ($hours, $minutes, $seconds) = split(':', $TIME);
    my $now_time = timelocal(int($seconds), int($minutes), int($hours), int($day), int($month - 1), int($year));

    if ($command_end_time <= $now_time) {
      cmd($end_command, {
        PARAMS => { IP => $user->{external_user_ip}, UID => $user->{uid} }
      });

      $Paysys->paysys_user_change({
        UID       => $user->{uid},
        PAYSYS_ID => $user->{paysys_id},
        CLOSED    => 1
      });

      if ($debug > 2) {
        _log('LOG_INFO', "UID: $user->{uid} external_cpmmands STOP");
      }
    }
  }

  return 1;
}

1;
