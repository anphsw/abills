#*********************** ABillS ***********************************
# Copyright (с) 2003-2025 Andy Gulay (ABillS DevTeam) Ukraine
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#
#******************************************************************
=head1 DESCRIBE: Ring


=head1 VERSION

  VERSION: 0.09
  UPDATE: 20240812

=head1  CONFIGURATION

$VAR1 = {
          'Message'   => 'Originate failed',
          'ActionID'  => '2',
          'GOOD'      => 0,
          'COMPLETED' => 1,
          'Response'  => 'Error'
        };

$VAR1 = {
          'Message'   => 'Originate successfully queued',
          'ActionID'  => '2',
          'GOOD'      => 1,
          'COMPLETED' => 1,
          'Response'  => 'Success'
        };

=head1 Options

  TIMEOUT  - Ring timeout
  TEST     - Test connect
  DEBUG

=cut
#**********************************************************

use warnings;
use strict;

use Abills::Base qw(show_hash);
use Ring;
use Asterisk::AMI;
use Time::Local;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug
);

use Abills::Base qw{in_array};

my $Ring = Ring->new($db, $Admin, \%conf); # connect Ring module

my $ring_timeout = $argv->{TIMEOUT} || 15;

if ($debug > 6) {
  $Ring->{debug} = 1;
}

if ($argv->{CMD} && $argv->{CMD} eq 'users') {
  update_users();
}
else {
  asterisk($argv);
}

#**********************************************************
=head2 asterisk() -

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub asterisk {
  my ($attr) = @_;

  _log('LOG_INFO', "Ring start");

  my $ring_path = "$conf{TPL_DIR}ring/"; # path to wav files

  my @TODAY_RULES = rules_list();

  my $astman = Asterisk::AMI->new(
    PeerAddr => $conf{ASTERISK_AMI_IP},
    PeerPort => $conf{ASTERISK_AMI_PORT},
    Username => $conf{ASTERISK_AMI_USERNAME},
    Secret   => $conf{ASTERISK_AMI_SECRET},
    Timeout  => 20
  );
  if (!$astman) {
    print "Unable to connect to asterisk $!";
    return 0;
  }

  if ($attr->{TEST}) {
    asterisk_test($astman);
    return 1;
  }

  #my $response; # variable for call response
  for (my $i = 0; $i < (scalar @TODAY_RULES); $i++) {
    my $users = Users->new($db, $Admin, \%conf); # connect users personal info
    my $response;                                # response variable

    # user's list for rule
    my $users_list = $Ring->users_rule({
      RID       => $TODAY_RULES[$i],
      COLS_NAME => 1,
      STATUS    => 0
    });

    # take rule's information
    my $rule_info = $Ring->rule_select({ RULE_ID => $TODAY_RULES[$i] });

    # check rule's time
    if ($TIME ge $rule_info->{TIME_START}) {
      _log('LOG_INFO', "No call rules: $TIME ge $rule_info->{TIME_START}");
      return 1;
    }

    foreach my $user (@$users_list) {
      next if ($TIME ne $rule_info->{TIME_END});

      my $u_pinfo = $users->pi({ UID => $user->{uid} });

      my $phone = $u_pinfo->{PHONE};
      my ($filename, undef) = split('\.', $rule_info->{FILE});

      # check status, should be 'waiting'
      if (defined($user->{status}) && $user->{status} == 0) {
        my %request = (
          Action      => 'Originate',
          #                Channel     => "Local/$phone\@$conf{ASTERISK_CALL}",  # work
          Channel     => "SIP/$phone", # test debug
          Application => "Playback",
          Data        => $ring_path . $filename,
          #Data       => "silence/1&cannot-complete-as-dialed&check-number-dial-again,noanswer",
          WaitTime    => 20,
          Timeout     => $ring_timeout,
          Callerid    => $phone,
          Async       => "1", # allows multiple calls without waiting for a response
        );

        my $log = show_hash(\%request, { OUTPUT2RETURN => 1, DELIMITER => "\n" });
        _log('LOG_DEBUG', $log);

        $response = $astman->action(\%request);

        if (!$response) {
          print "no responce . $astman !!!!\т";
          return 0;
        }

        # response ok - change status
        if ($response->{Response} eq 'Success') {
          $Ring->user_change({
            UID    => $user->{uid},
            R_ID   => $TODAY_RULES[$i],
            STATUS => 1,
            TIME   => 'NOW()',
            DATE   => $DATE
          });
        }

        # response error - change status
        else {
          $Ring->user_change({
            UID    => $user->{uid},
            R_ID   => $TODAY_RULES[$i],
            STATUS => 2,
            TIME   => 'NOW()',
            DATE   => $DATE
          });
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 rules_list() - Today rules list

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub rules_list {

  my $rules_list = $Ring->rule_list({
    COLS_NAME => 1,
    DATE_NOW  => $DATE
  });

  my @TODAY_RULES = ();

  # looking for today's rules
  foreach my $rule (@$rules_list) {
    #my ($start_time, $end_time, $today_time);
    #
    #my ($s_y, $s_m, $s_d) = split('-', $rule->{date_start});
    #my ($e_y, $e_m, $e_d) = split('-', $rule->{date_end});
    #my ($t_y, $t_m, $t_d) = split('-', $DATE);
    #
    ## start date to timestamp
    #if ($s_d != 0 && $s_m != 0 && $s_y != 0) {
    #  $start_time = timelocal(1, 0, 0, $s_d, $s_m, $s_y);
    #}
    #else {
    #  $start_time = 0;
    #}
    #
    ## today date to timestamp
    #if ($t_d != 0 && $t_m != 0 && $t_y != 0) {
    #  $today_time = timelocal(1, 0, 0, $t_d, $t_m, $t_y);
    #}
    #else {
    #  $today_time = 0;
    #}
    #
    ## end date to timestamp
    #if ($e_d != 0 && $e_m != 0 && $e_y != 0) {
    #  $end_time = timelocal(1, 0, 0, $e_d, $e_m, $e_y);
    #}
    #else {
    #  $end_time = 0;
    #}
    #
    ## rule has start date and end date
    #if ( $start_time <= $today_time
    #  && $end_time >= $today_time
    #  && $start_time != 0
    #  && $end_time != 0)
    #{
    #  push(@TODAY_RULES, $rule->{id});
    #}
    #
    ## rule has only end time
    #if ($start_time == 0 && $end_time >= $today_time) {
    #  push(@TODAY_RULES, $rule->{id});
    #}
    #
    ## rule has only start time
    #if ($end_time == 0 && $start_time <= $today_time) {
    #  push(@TODAY_RULES, $rule->{id});
    #}
    push(@TODAY_RULES, $rule->{id});
  }

  $rules_list = $Ring->rule_list({
    COLS_NAME   => 1,
    EVERY_MONTH => 1,
    DATE_START  => '_SHOW',
    DATE_END    => '_SHOW',
  });

  foreach my $rule (@$rules_list) {
    my (undef, undef, $start_day) = split('-', $rule->{date_start});
    my (undef, undef, $end_day) = split('-', $rule->{date_end});
    my (undef, undef, $now_day) = split('-', $DATE);

    if ($now_day eq $start_day) {
      my $users_list = $Ring->users_rule({
        RID       => $rule->{id},
        DATE      => '_SHOW',
        COLS_NAME => 1
      });

      foreach my $user (@$users_list) {
        # set user status to WAITING if changing date not eq rule's start day
        if ($user->{date} ne $DATE) {
          $Ring->user_change({
            UID    => $user->{uid},
            R_ID   => $rule->{id},
            STATUS => 0,
            TIME   => 'NOW()',
            DATE   => $DATE
          });
        }
      }
    }

    if ($now_day ge $start_day && $now_day le $end_day) {
      push(@TODAY_RULES, $rule->{id});
    }
  }

  return @TODAY_RULES;
}

#**********************************************************
=head2 update_users()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub update_users {
  my (undef, undef, $d) = split(/\-/x, $DATE);

  #  get update options
  my $rules_list = $Ring->rule_list({
    COLS_NAME  => 1,
    UPDATE_DAY => '_SHOW',
    SQL_QUERY  => '_SHOW',
    DATE_NOW   => $DATE,
    PAGE_ROWS  => 10000
  });

  if (!$rules_list) {
    return 1;
  }

  foreach my $item (@$rules_list) {
    next if (!$item->{update_day} || $item->{update_day} eq '0' || $item->{update_day} eq '');
    next if (!$item->{sql_query} || $item->{sql_query} eq '');
    #    FOR  EVERYDAY
    if (defined($item->{update_day}) && $item->{update_day} eq '*') {
      $Ring->user_del({ R_ID => $item->{id} });
      if (!$Ring->{errno}) {
        $Ring->users_add_by_rule({ SQL_QUERY => $item->{sql_query}, R_ID => $item->{id} });
      }
    }
    else {
      my @days = split(/,/x, $item->{update_day});
      if (in_array(int($d), \@days)) {
        $Ring->user_del({ R_ID => $item->{id} });
        if (!$Ring->{errno}) {
          $Ring->users_add_by_rule({ SQL_QUERY => $item->{sql_query}, R_ID => $item->{id} });
        }
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 update_users($satman)- test connect

  Arguments:
    $astmaan

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub asterisk_test {
  my ($astman) = @_;

  my $response = $astman->action({
    Action  => 'Command',
    Command => 'sip show peers'
  });

  show_hash($response, { DELIMITER => "\n" });

  return 1;
}

=head1 COPYRIGHT

  Copyright (с) 2003-2025 Andy Gulay (ABillS DevTeam) Ukraine
  All rights reserved.
  https://abills.net.ua/

=cut

1;