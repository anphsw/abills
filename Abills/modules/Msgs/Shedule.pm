=head1 NAME

  Msgs Shedule

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(days_in_month date_diff load_pmodule);

our (
  %lang,
  $admin,
  %conf,
  $db,
  @WEEKDAYS,
  @MONTHES
);

our Abills::HTML $html;
my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_shedule_month()

=cut
#**********************************************************
sub msgs_task_board {
  my $loaded_json_result = load_pmodule("JSON", { RETURN => 1 });
  if ( $loaded_json_result ) {
    print $loaded_json_result;

    return 0;
  }


  my $json = JSON->new->utf8(0);

  if ($FORM{HOURS}) {
    msgs_shedule_hourse();

    return 1;
  }

  _msgs_tasg_board_change(\%FORM);

  my $date = (defined $FORM{DATE}) ? $FORM{DATE} : $DATE;
  my ($cur_year, $cur_month, $cur_day) = _current_data($date);

  my @weekdays = @WEEKDAYS;
  shift @weekdays;

  my $cur_day_time = POSIX::mktime(1, 0, 0, $cur_day - 1, $cur_month - 1, $cur_year - 1900);
  my ($mon, $year) = (localtime($cur_day_time))[4, 5];

  my ($f_wday, @fweek_row) = _generated_first_row($mon, $year);

  my $shedule_table_index = get_function_index("msgs_task_board");
  my $link = "?index=$shedule_table_index&DATE=$cur_year-$cur_month-";

  my $current_week_row = \@fweek_row;
  my $week_day_counter = $f_wday - 1;

  my @table_rows = ();
  my $days_count = days_in_month({ DATE => $date });
  ($current_week_row, @table_rows) = _generated_row_column($days_count, $week_day_counter, $current_week_row, {
    CURRENT_DAY => $cur_day,
    LINK        => $link
  });

  my ($tasks_ids, $tasks_free, $tasks_for_month) = _msgs_shedule_month_get_tasks($cur_year, $cur_month, $FORM{AID});
  my $tasks_info = msgs_tasks_info($tasks_ids);

  map {
    $_->{message} = convert($_->{message}, { text2html => 1 })
  } @{ $tasks_free };

  my $tasks_script = "<script>
    jQuery(function(){
    tasksInfo = " . $json->encode($tasks_info) . ";
    ATasks.addTasks(" . $json->encode($tasks_free) . ");
    AMonthWorkTable.init();
    AMonthWorkTable.addJobs( " . $json->encode($tasks_for_month) . ");
  });
  </script>";

  my $task_status_select = msgs_sel_status({ NAME => 'TASK_STATUS_SELECT', ALL => 1 });
  my $admins_select = sel_admins();

  my $prev_month_num  = ($cur_month - 1 != 0)   ? $cur_month - 1  : 12;
  my $prev_year_num   = ($cur_month - 1 == 0)   ? $cur_year - 1   : $cur_year;
  my $next_month_num  = ($cur_month + 1 != 13)  ? $cur_month + 1  : 1;
  my $next_year_num   = ($cur_month + 1 == 13)  ? $cur_year + 1   : $cur_year;

  $prev_month_num = "0" . $prev_month_num if ( length($prev_month_num) < 2 );
  $next_month_num = "0" . $next_month_num if ( length($next_month_num) < 2 );

  my $prev_month_date = "$prev_year_num-$prev_month_num-01";
  my $next_month_date = "$next_year_num-$next_month_num-01";

  my $table = $html->table({
    width       => '100%',
    border      => 1,
    title_plain => \@weekdays,
    class       => "table work-table-month no-highlight\" data-year='$cur_year' data-month='$cur_month'",
    ID          => 'MSGS_SHEDULE_MONTH_TABLE',
  });

  $table = _generated_last_row($current_week_row, \@table_rows, $table);

  $html->tpl_show(_include('msgs_shedule_month', 'Msgs'), {
    TABLE              => $table->show(),
    OPTIONS_SCRIPT     => $tasks_script,

    TASK_STATUS_SELECT => $task_status_select,
    ADMINS_SELECT      => $admins_select,

    DATE               => $date,
    YEAR               => $cur_year,
    MONTH_NAME         => $MONTHES[$cur_month - 1],

    PREV_MONTH_DATE    => $prev_month_date,
    NEXT_MONTH_DATE    => $next_month_date
  });

  return 1;
}

#**********************************************************
=head2 _msgs_shedule_month_get_tasks($year, $month) - get tasks that have not defined PLAN_DATE date or date && time

  Arguments:
    $year - year with century
    $month - month num 01 to 12

  Returns:
    arr_ref, arr_ref

=cut
#**********************************************************
sub _msgs_shedule_month_get_tasks {
  my ($year, $month, $aid) = @_;

  my $date_interval = "$year-$month-01/$year-$month-" . days_in_month({ DATE => "$year-$month-1" });

  my $messages_list = $Msgs->messages_list({
    PLAN_DATE   => $date_interval,
    COLS_NAME   => 1,
    STATE       => $FORM{TASK_STATUS_SELECT},
    ADMIN_LOGIN => '_SHOW',
    MESSAGE     => '_SHOW',
    RESPOSIBLE  => $aid || '_SHOW',
    PAGE_ROWS   => 100
  });

  my $free_messages_list = $Msgs->messages_list({
    ADMIN_LOGIN => '_SHOW',
    LOGIN       => '_SHOW',
    MESSAGE     => '_SHOW',
    PLAN_DATE   => '0000-00-00',
    RESPOSIBLE  => $aid || '_SHOW',
    STATE       => $FORM{TASK_STATUS_SELECT},
    COLS_NAME   => 1,
    PAGE_ROWS   => 100
  });

  my @tasks_ids = ();
  my @new_tasks = ();

  for my $message ( @{$free_messages_list} ) {
    my $task_id = $message->{id};

    $message->{login} ||= '';
    $message->{subject} ||= '';
    $message->{admin_login} ||= '';

    push (@tasks_ids, $task_id);
    push (@new_tasks, {
      id      => $task_id,
      user    => $message->{login},
      subject => $message->{subject},
      message => $message->{message},
      admin   => $message->{admin_login},
      name    => "$message->{admin_login}: $message->{subject}",
    });
  }

  my @assigned_date_tasks = ();
  foreach my $message ( @{$messages_list} ) {
    my $task_id = $message->{id};

    $message->{login} ||= '';
    $message->{subject} ||= '';
    $message->{admin_login} ||= '';

    push (@tasks_ids, $task_id);
    push (@assigned_date_tasks, {
      id        => $task_id,
      message   => $message->{message},
      admin     => $message->{admin_login},
      plan_date => $message->{plan_date},
      name      => "$message->{admin_login}: $message->{subject}",
    });
  }

  return (\@tasks_ids, \@new_tasks, \@assigned_date_tasks);
}

#**********************************************************
=head2 _msgs_tasg_board_change()

=cut
#**********************************************************
sub _msgs_tasg_board_change {
  my ($attr) = @_;

  if ($attr->{change} && $attr->{popped} && $attr->{jobs}) {
    my $jobs_popped = $attr->{popped} || q{};
    $jobs_popped =~ s/\\\"/\"/g;
    my $jobs = $attr->{jobs} || q{};
    $jobs =~ s/\\\"/\"/g;

    my $tasks_popped = JSON::decode_json($jobs_popped);
    my $tasks_applied = JSON::decode_json($jobs);

    $Msgs->{db}->{db}->{AutoCommit} = 0;

    foreach my $task_popped ( @{$tasks_popped} ) {
      $Msgs->message_change({ ID => $task_popped, PLAN_DATE => '0000-00-00' });
    }

    foreach my $task_applied ( @{$tasks_applied} ) {
      $Msgs->message_change({ ID => $task_applied->{id}, PLAN_DATE => $task_applied->{plan_date} });
    }

    if ( $Msgs->{errno} ) {
      _error_show($Msgs);
    }
    else {
      my DBI $db_ = $Msgs->{db}->{db};
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }
}

#**********************************************************
=head2 _current_data()

=cut
#**********************************************************
sub _current_data {
  my ($date) = @_;

  if ( $date =~ /(\d{4})\-(\d{2})\-(\d{2})/ ) {
    my $cur_year = $1;
    my $cur_month = $2;
    my $cur_day = $3;

    return ($cur_year, $cur_month, $cur_day);
  }

  $html->message('err', $lang{ERROR}, "Incorrect DATE");
  return 0;
}

#**********************************************************
=head2 _generated_first_row()

=cut
#**********************************************************
sub _generated_first_row {
  my ($mon, $year) = @_;

  my $first_day_time = POSIX::mktime(1, 0, 0, 1, $mon, $year);
  my $f_wday = (localtime($first_day_time))[6];

  $f_wday = 7 if ($f_wday == 0);

  my @fweek_row = ();
  for ( my $i = 1; $i < $f_wday; $i++ ) {
    push (@fweek_row, $html->element('span', '', { class => 'disabled' }));
  };

  return ($f_wday, @fweek_row);
}

#**********************************************************
=head2 _generated_row_column()

=cut
#**********************************************************
sub _generated_row_column {
  my ($days_count, $week_day_counter, $current_week_row, $attr) = @_;

  my @table_rows = ();

  for (my $day = 1; $day <= $days_count; $day++, $week_day_counter++) {

    my $is_weekday = '';
    if ( $week_day_counter % 7 > 4 ) {
      $is_weekday = ' weekday';
    }

    my $current = ($attr->{CURRENT_DAY} == $day) ? ' current' : '';

    if ( $week_day_counter % 7 == 0 ) {
      push (@table_rows, $current_week_row);
      $current_week_row = [ ];
    }

    my $two_digits_day = (length($day) == 1) ? '0' . $day : $day;

    push (@{$current_week_row},
      "<a href='$attr->{LINK}$two_digits_day&HOURS=1' target='_blank' title='$lang{SHEDULE_BOARD}' class='mday$is_weekday$current' data-mday='$day'>$day</a>");
  };

  return ($current_week_row, @table_rows);
}

#**********************************************************
=head2 _generated_last_row()

=cut
#**********************************************************
sub _generated_last_row {
  my ($current_week_row, $table_rows, $table) = @_;

  my $days_left = 7 - scalar @{ $current_week_row } - 1;
  for ( my $i = 1; $i < $days_left; $i++ ) {
    push (@{ $current_week_row }, $html->element('span', '', { class => 'disabled' }));
  };

  push (@{ $table_rows }, $current_week_row);

  foreach my $week_row (@{ $table_rows }) {
    $table->addrow(@{ $week_row });
  }

  return $table;
}

#**********************************************************
=head2 msgs_show_shedule_table($attr) - show interactive table with tasks

ARGUMENTS
  $attr - hash
    ADMINS - array of hashes with admins to display
      [
        {aid, name},
        {aid, name}
      ]
    ADMINS_JOBS  - array of jobs
      [
        {
          administrator: aid,
          tasks: [ { id, start, length, name, info },  { id, start, length, name, info} ]
        },
        {
          administrator: aid,
          tasks: [ { id, start, length, name, info },  { id, start, length, name, info} ]
        }
      ]
    NEW_TASKS     - array of free tasks
      [
        {id, name, length, info},
        {id, name, length, info}
      ]
    TASKS_INFO - hash_ref of html content for tooltip
      {
        id : html,
        id : html
      }
    OPTIONS       - hash of options
      COLUMNS    - columns for tasks               || 9
      START_TIME - time for first column           || 9
      FRACTION   - time for one column (minutes)   || 60 (one hour)


    OUTPUT2RETURN - return result string;
    DEBUG         - show debug information
=cut
#**********************************************************
sub msgs_show_shedule_table {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG};
  my $json  = JSON->new->utf8(0);

  my $admins_json   = $json->encode($attr->{ADMINS});
  my @tasks         = $attr->{ADMINS_JOBS};
  my @new_tasks_arr = $attr->{NEW_TASKS};
  my $tasks_info    = $attr->{TASKS_INFO} || {};

  my $columns       = $attr->{OPTIONS}->{COLUMNS} || 9;
  my $start_time    = $attr->{OPTIONS}->{START_TIME} || 9;
  my $fraction      = $attr->{OPTIONS}->{FRACTION} || 60;
  my $time_unit     = $attr->{OPTIONS}->{TIME_UNIT} || 0;
  my $highlighted   = $attr->{OPTIONS}->{ACTIVE} || 0;

  $columns = $json->encode($columns) if (ref ($columns) eq 'ARRAY');

  my $container = '#hour-grid';

  my $init_options = "
    tableOptions = {
    container: '$container',
    administrators: $admins_json,
    hours: $columns,
    startTime: $start_time,
    fraction: $fraction,
    timeUnit : $time_unit,
    highlighted : $highlighted
    };
    AWorkTable.init(tableOptions);
    ";

  my $jobs = 'AWorkTable.addJobs(' . $json->encode(@tasks) . ');';

  my $new_tasks = 'ATasks.addTasks(' . $json->encode(@new_tasks_arr) . ');';

  $tasks_info = 'tasksInfo = ' . $json->encode($tasks_info) . ';';

  my $result = "
    <script>
    jQuery(function(){
    $init_options
    $tasks_info
    $jobs
    $new_tasks
    AWorkTable.render();
    });
    </script>";

  if ( $attr->{OUTPUT2RETURN} ) {
    return $html->tpl_show(_include('msgs_shedule_table', 'Msgs'), {
      OPTIONS_SCRIPT     => $result,
      OUTPUT2RETURN      => 1,
      TASK_STATUS_SELECT => $attr->{TASK_STATUS_SELECT},
      INDEX_JOB          => get_function_index('shedule_hour_work')
    });
  }
  else {
    $html->tpl_show(_include('msgs_shedule_table', 'Msgs'), {
      OPTIONS_SCRIPT     => $result,
      TASK_STATUS_SELECT => $attr->{TASK_STATUS_SELECT},
      INDEX_JOB          => get_function_index('shedule_hour_work')
    });
  }
}


#**********************************************************
=head2 msgs_shedule_hourse() - Visualize time and admin task assignment

=cut
#**********************************************************
sub msgs_shedule_hourse {

  my $loaded_json_result = load_pmodule("JSON", { RETURN => 1 });
  if ( $loaded_json_result ) {
    print $loaded_json_result;

    return 0;
  }

  if ( !$FORM{DATE} ) {
    $FORM{DATE} = POSIX::strftime('%Y-%m-%d', localtime);
  }
  else {
    $FORM{DATE} =~ s/.+,.//g;
  }

  my DBI $db_ = $Msgs->{db}->{db};
  my $options = {
    COLUMNS     => 10,
    START_TIME  => 9,
    FRACTION    => 60,
    TIME_UNIT   => 0
  };
  my $default_task_length = 1;

  _msgs_hour_change($db_, $options, { %FORM });

  my @admins_list = (
    @{
      $admin->list({
        GID       => $admin->{GID},
        DISABLE   => 0,
        PAGE_ROWS => 1000,
        COLS_NAME => 1
      })
    });
  my @admins = ();

  for my $admin_ (@admins_list) {
    next if ( !$admin_->{aid} || $admin_->{aid} == 2 || $admin_->{aid} == 3 );

    push (@admins, {
      id   => $admin_->{aid},
      name => $admin_->{name} || $admin_->{login}
    });
  }

  my $new_task_ = 1;

  $options->{ACTIVE} = $FORM{ID} if (defined($FORM{ID}) && $FORM{ID} ne '');

  my $date = $FORM{DATE} || 'NOW()';

  my $messages_list = $Msgs->messages_list({
    LOGIN         => '_SHOW',
    RESPOSIBLE    => '_SHOW',
    MESSAGE       => '_SHOW',
    PLAN_DATE     => $date,
    PLAN_INTERVAL => '_SHOW',
    PLAN_POSITION => '_SHOW',
    COLS_NAME     => 1,
    STATE         => $FORM{TASK_STATUS_SELECT}
  });

  my $free_messages_list = $Msgs->messages_list({
    LOGIN           => '_SHOW',
    RESPOSIBLE      => '_SHOW',
    PLAN_DATE       => $date,
    PLAN_INTERVAL   => '_SHOW',
    PLAN_POSITION   => '_SHOW',
    MESSAGE         => '_SHOW',
    COLS_NAME       => 1,
    STATE           => $FORM{TASK_STATUS_SELECT}
  });

  my @tasks_ids = ();
  my @new_tasks = ();
  my %jobs_aid  = ();

  for my $message ( @{$messages_list}, @{$free_messages_list} ) {
    my $aid     = $message->{resposible};
    my $task_id = $message->{id};

    push @tasks_ids, $task_id;

    $new_task_ = undef if ( $options->{ACTIVE} && ($task_id == $options->{ACTIVE}) );

    my $mess_start = int(substr($message->{plan_time}, 0, 2)) - $options->{START_TIME};

    my $mess_name = ($message->{login} ? "$message->{login}:" : q{ }) . ($message->{subject} ? $message->{subject} : q{});

    if ($aid && $mess_start >= 0) {
      $jobs_aid{$aid} = () if ( !$jobs_aid{$aid} );

      push @{ $jobs_aid{$aid} }, {
        id       => $task_id,
        name     => $mess_name,
        length   => $default_task_length,
        start    => $message->{plan_position},
        message  => $message->{message},
        interval => $message->{plan_interval}
      }
    }
    else {
      push @new_tasks, {
        id       => $task_id,
        name     => $mess_name,
        length   => $default_task_length,
        message  => $message->{message},
        interval => $message->{plan_interval}
      };
    }
  }

  _msgs_hour_show(\@tasks_ids, \%jobs_aid, \@new_tasks, \@admins, {
    new_task_           => $new_task_,
    default_task_length => $default_task_length,
    options             => $options
  });

  return 1;
}

#**********************************************************
=head2 _msgs_hour_change() -

=cut
#**********************************************************
sub _msgs_hour_change {
  my ($db_, $options, $attr) = @_;

  if ( $attr->{change} && $attr->{change} ne '' && ($attr->{jobs} || $attr->{popped}) ) {
    if ( $attr->{jobs} ) {
      my $jobs_unescaped = $attr->{jobs};
      $jobs_unescaped =~ s/\\\"/\"/g;

      my $jobs = JSON::decode_json($jobs_unescaped);

      $db_->{AutoCommit} = 0;

      _msgs_hour_jobs($jobs, $options);
    }

    _msgs_hour_popped();

    $db_->commit();
    $db_->{AutoCommit} = 1;
  }
}

#**********************************************************
=head2 _msgs_hour_jobs() -

=cut
#**********************************************************
sub _msgs_hour_jobs {
  my ($jobs, $options) = @_;

  for my $job (@{ $jobs }) {
    my $aid   = $job->{administrator};
    my $tasks = $job->{tasks};

    for my $task (@{ $tasks }) {
      my $task_id       = $task->{id};
      my $task_start    = $task->{start} || 0;
      my $task_name     = $task->{name} || '';
      my $plan_position = $task->{plan_position};

      my $hours_start = $task_start;
      if ($task_start <= 9) {
        $hours_start = $task_start + $options->{START_TIME};
      }

      if ( $options->{TIME_UNIT} == 0 && $hours_start >= 24 ) {
        $html->message('danger', "$task_name : $lang{RESETED}", "$hours_start:00:00 > 23:59:59");
        $hours_start = "00";
      }

      my $task_start_time = "$hours_start:00:00";

      $Msgs->message_change({
        ID            => $task_id,
        PLAN_TIME     => $task_start_time,
        RESPOSIBLE    => $aid,
        PLAN_POSITION => $plan_position
      });
    }
  }
}

#**********************************************************
=head2 _msgs_hour_show() -

=cut
#**********************************************************
sub _msgs_hour_show {
  my ($tasks_ids, $jobs_aid, $new_tasks, $admins, $attr) = @_;

  my $tasks_info = { };

  $tasks_info = msgs_tasks_info(\@{ $tasks_ids }) if (scalar @{ $tasks_ids } > 0);

  my @jobs = ();
  my %jobs_aid_new = %{ $jobs_aid };

  for my $key ( keys %{ $jobs_aid } ) {
    push @jobs, { administrator => $key, tasks => $jobs_aid_new{$key} };
  }

  if ( $FORM{ID} && $FORM{ID} ne '' && defined $attr->{new_task_} ) {
    my $message_info = $Msgs->message_info($FORM{ID}, { COLS_NAME => 1 });
    my $mess_name    = "$message_info->{LOGIN}: $message_info->{SUBJECT}";

    $attr->{new_task_} = ({
      id      => $message_info->{ID},
      name    => $mess_name,
      length  => $attr->{default_task_length}
    });

    push @{ $new_tasks }, $attr->{new_task_};
  }

  my $task_status_select = msgs_sel_status({ NAME => 'TASK_STATUS_SELECT', ALL => 1 });

  msgs_show_shedule_table({
    ADMINS             => \@{ $admins },
    OPTIONS            => $attr->{options},
    NEW_TASKS          => \@{ $new_tasks },
    ADMINS_JOBS        => \@jobs,
    TASKS_INFO         => $tasks_info,
    TASK_STATUS_SELECT => $task_status_select
  });
}

#**********************************************************
=head2 _msgs_hour_popped() -

=cut
#**********************************************************
sub _msgs_hour_popped {
  if ( $FORM{popped} ) {
    my $tasks_unescaped = $FORM{popped};
    $tasks_unescaped =~ s/\\\"/\"/g;
    my $task_ids = JSON::decode_json($tasks_unescaped);

    for my $task_id ( @{$task_ids} ) {
      $Msgs->message_change({ ID => $task_id, PLAN_TIME => '00:00:00', RESPOSIBLE => 0 });
    }

    $html->message('info', $lang{SUCCESS}) if (!_error_show($Msgs));
  }
}

#**********************************************************
=head2 msgs_tasks_info($id_arr, $attr) - Return (AJAX compatible) info about tasks

  Arguments:
    $id_arr - arr_ref
    $attr

  Returns:
    hash_ref

=cut
#**********************************************************
sub msgs_tasks_info {
  my ($id_arr) = @_;

  return 0 unless (ref($id_arr) eq 'ARRAY');

  my $messages_list = $Msgs->messages_list({
    ID              => $id_arr,
    FIO             => '_SHOW',
    DATETIME        => '_SHOW',
    CHAPTER_NAME    => '_SHOW',
    ADDRESS_FULL    => '_SHOW',
    PLAN_DATE_TIME  => '_SHOW',
    A_NAME          => '_SHOW',
    SUBJECT         => '_SHOW',
    USER_NAME       => '_SHOW',
    USERS_FIELDS    => 1,
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 150
  });

  my $result = { };
  foreach my $message (@{ $messages_list }) {
    $result->{$message->{id}} = msgs_task_info_to_html($message);
  }

  return $result;
}

#**********************************************************
=head2 shedule_hour_work() -

  Arguments:

  Returns:

=cut
#**********************************************************
sub shedule_hour_work {
  $Msgs->message_change({
    ID            => $FORM{id},
    PLAN_INTERVAL => $FORM{hours}
  })
}

1;
