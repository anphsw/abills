=head1 NAME

  billd plugin — Tasks admin notify

=head1 DESCRIPTION

  Notifies responsible admins about tasks with a specific control date.
  Supports filtering by date, responsible admin, and debug level.

=cut

use strict;
use warnings;

our (
  $argv,
  $debug,
  %conf,
  %lang,
  $Admin,
  $db,
  $base_dir,
  $DATE,
);

do "$base_dir/Abills/modules/Tasks/lng_$conf{default_language}.pl";

use Tasks::db::Tasks;
use Abills::Base qw(load_pmodule in_array _bp);
require Abills::Sender::Core;
Abills::Sender::Core->import();

my $Tasks = Tasks->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);
my $Sender = Abills::Sender::Core->new($db, $Admin, \%conf);

notify_admins();

#**********************************************************
=head2 notify_admins()

=cut
#**********************************************************
sub notify_admins {

  $Tasks->{debug} = 1 if $debug > 6;

  my $date = $argv->{DATE} || $DATE;
  if (!$date) {
    $Log->log_print('LOG_WARNING', 'SYSTEM', 'No date provided for notify_admins', { PRINT => 1 });
    return;
  };

  my $tasks = $Tasks->list({
    RESPONSIBLE  => $argv->{RESPONSIBLE} || '_SHOW',
    CONTROL_DATE => $date,
    NAME         => '_SHOW',
    STATE        => '0',
    SORT         => 'tm.responsible',
    COLS_NAME    => 1,
    PAGE_ROWS    => 65000,
  });

  if (!$tasks || !@$tasks) {
    $Log->log_print('LOG_INFO', 'SYSTEM', "No open tasks found for date: $date", { PRINT => 1 });
    return;
  }

  my $admin_tasks = _group_tasks_by_admin($tasks);
  _send_notifications($admin_tasks, $date);

  return 1;
}


#**********************************************************
=head2 _group_tasks_by_admin(\@tasks)

=cut
#**********************************************************
sub _group_tasks_by_admin {
  my ($tasks) = @_;

  my %admin_tasks;
  for my $task (@$tasks) {
    my $aid = $task->{RESPONSIBLE};
    next if !$aid;

    my $name = $task->{NAME} // $lang{UNKNOWN} // 'N/A';
    my $descr = $task->{DESCR} // '—';

    my $message = sprintf(
      "ID: %s\n%s: %s\n%s: %s",
      $task->{ID},
      $lang{TASK_NAME}, $name,
      $lang{TASK_DESCRIBE}, $descr,
    );

    push @{$admin_tasks{$aid}}, $message;
  }

  return \%admin_tasks;
}

#**********************************************************
=head2 _send_notifications(\%admin_tasks, $date)

=cut
#**********************************************************
sub _send_notifications {
  my ($admin_tasks, $date) = @_;

  my $is_debug = ($argv->{DEBUG} || 0) > 5 ? 1 : 0;
  my $sent = 0;
  my $failed = 0;

  for my $aid (sort keys %$admin_tasks) {
    my $task_count = scalar @{$admin_tasks->{$aid}};
    my $message = sprintf("%s: %s (%d)\n\n%s",
      $lang{TASKS} // 'Tasks',
      $date,
      $task_count,
      join("\n---\n", @{$admin_tasks->{$aid}}),
    );

    $Sender->send_message_auto({
      AID     => $aid,
      MESSAGE => $message,
      DEBUG   => $is_debug,
    });

    if ($Sender->{errno}) {
      $Sender->{errstr} //= '';
      $Log->log_print('LOG_ERR', 'SYSTEM', "Failed to notify admin $aid: $Sender->{errstr}", { PRINT => 1 });
      $failed++;
    }
    else {
      $Log->log_print('LOG_INFO', 'SYSTEM', "Notified admin $aid: $task_count task(s) for $date", { PRINT => 1 });
      $sent++;
    }
  }

  $Log->log_print('LOG_INFO', 'SYSTEM', "Notifications done. Sent: $sent, Failed: $failed", { PRINT => 1 });

  return;
}

1;