=head1 NAME

  Msgs Schedule

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(days_in_month date_diff load_pmodule json_former);

our (
  %lang,
  $admin,
  %conf,
  $db,
  @WEEKDAYS,
  @MONTHES,
  %msgs_permissions
);

our Abills::HTML $html;
my $Msgs = Msgs->new($db, $admin, \%conf);

require Control::Schedule;
my $Schedule_control = Control::Schedule->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, index => $index });

#**********************************************************
=head2 msgs_task_board()

=cut
#**********************************************************
sub msgs_task_board {

  if ($FORM{HOURS}) {
    msgs_schedule_hours();
    return 1;
  }

  my $date = $FORM{DATE} ? $FORM{DATE} : $DATE;

  my $status_list = $Msgs->status_list({
    STATUS_ONLY => 1,
    NAME        => '_SHOW',
    COLOR       => '_SHOW',
    ICON        => '_SHOW',
    COLS_NAME   => 1
  });
  my $statuses = {};
  foreach my $status (@{$status_list}) {
    $statuses->{$status->{id}} = {
      name  => _translate($status->{name}),
      icon  => $status->{icon} || '',
      color => $status->{color} || ''
    };
  }

  my $locales = { russian => 'ru', ukrainian => 'uk' };

  $html->tpl_show(_include('msgs_calendar', 'Msgs'), {
    DATE       => $date,
    STATUSES   => json_former($statuses),
    LOCALE     => $locales->{$html->{language}} || 'en'
  });

  return 1;
}

#**********************************************************
=head2 _msgs_schedule_month_get_tasks($year, $month) - get tasks that have not defined PLAN_DATE date or date && time

  Arguments:
    $year - year with century
    $month - month num 01 to 12

  Returns:
    arr_ref, arr_ref

=cut
#**********************************************************
sub _msgs_schedule_month_get_tasks {
  my ($year, $month, $aid) = @_;

  my $date_interval = "$year-$month-01/$year-$month-" . days_in_month({ DATE => "$year-$month-1" });

  my $messages_list = $Msgs->messages_list({
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    PLAN_INTERVAL          => '_SHOW',
    RESPOSIBLE             => $aid || '_SHOW',
    PLAN_DATE              => $date_interval,
    SUBJECT                => '_SHOW',
    PRIORITY_ID            => '_SHOW',
    STATE                  => $FORM{TASK_STATUS_SELECT},
    CHAPTER                => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',
    PAGE_ROWS              => 65500,
    COLS_NAME              => 1
  });

  my $free_messages_list = $Msgs->messages_list({
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    LOGIN                  => '_SHOW',
    PLAN_DATE              => '0000-00-00',
    RESPOSIBLE             => $aid || '_SHOW',
    STATE                  => $FORM{TASK_STATUS_SELECT},
    SUBJECT                => '_SHOW',
    PLAN_INTERVAL          => '_SHOW',
    PRIORITY_ID            => '_SHOW',
    CHAPTER                => $msgs_permissions{4} ? join(';', keys %{$msgs_permissions{4}}) : '_SHOW',
    COLS_NAME              => 1,
    PAGE_ROWS              => 50
  });

  my @tasks = ();
  foreach my $task (@{$messages_list}, @{$free_messages_list}) {
    $task->{subject} =~ s/\//\\\//g;
    push(@tasks, {
      id          => $task->{id},
      subject     => $task->{subject},
      priority    => $task->{priority_id},
      responsible => $task->{resposible_admin_login},
      plan_date   => $task->{plan_date},
      info_url    => "?get_index=msgs_admin&full=1&chg=$task->{id}"
    })
  }

  return \@tasks;
}

#**********************************************************
=head2 msgs_schedule_hours() - Visualize time and admin task assignment

=cut
#**********************************************************
sub msgs_schedule_hours {

  my $messages_list = $Msgs->messages_list({
    LOGIN         => '_SHOW',
    RESPOSIBLE    => '_SHOW',
    PRIORITY_ID   => '_SHOW',
    SUBJECT       => '_SHOW',
    PLAN_DATE     => $FORM{DATE} || 'NOW()',
    PLAN_INTERVAL => '_SHOW',
    PLAN_TIME     => '_SHOW',
    PLAN_POSITION => '_SHOW',
    COLS_NAME     => 1,
  });

  my @tasks = ();
  map push(@tasks, {
    id            => $_->{id},
    subject       => $_->{subject},
    priority      => $_->{priority_id},
    responsible   => $_->{resposible},
    plan_date     => $_->{plan_date},
    plan_time     => $_->{plan_time},
    plan_interval => $_->{plan_interval},
    info_url      => "?get_index=msgs_admin&full=1&chg=$_->{id}"
  }), @{$messages_list};

  my $tasks_json = json_former(\@tasks);
  $tasks_json =~ s/[\n\r]+//g;
  $tasks_json =~ s/\"/\\\"/g;
  $tasks_json =~ s/\//\\\//g;

  $Schedule_control->schedule_hours_tasks_board($tasks_json);
  $html->tpl_show(_include('msgs_schedule', 'Msgs'), { FORM_CLASS => 'd-none' });

  return 1;
}

1;
