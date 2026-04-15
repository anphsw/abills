package Telegram::buttons::Admin_tasks;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array int2ip json_former vars2lang);
use JSON qw/decode_json encode_json/;
use Encode qw/encode_utf8 decode_utf8/;
use POSIX qw(strftime);

use constant ICONS => {
  report      => "\xF0\x9F\x93\x8A",
  user        => "\xF0\x9F\x91\xA4",
  date        => "\xF0\x9F\x95\x98",
  closed      => "\xE2\x9C\x85",
  open        => "\xE2\x8C\x9B",
  expired     => "\xE2\x9A\xA0",
  chapter     => "\xE2\x9C\x8E",
  line        => "\xE2\x9E\x96",
  wave_line   => "\xE3\x80\xB0",
  right_arrow => "\xE2\x9E\xA1",
  number_1    => "\x31\xEF\xB8\x8F\xE2\x83\xA3",
  number_2    => "\x32\xEF\xB8\x8F\xE2\x83\xA3",
  number_3    => "\x33\xEF\xB8\x8F\xE2\x83\xA3",
  number_4    => "\x34\xEF\xB8\x8F\xE2\x83\xA3",
  number_5    => "\x35\xEF\xB8\x8F\xE2\x83\xA3",
  search      => "\xF0\x9F\x94\x8D",
  page        => "\xF0\x9F\x93\x83",
  fixation    => "\xf0\x9f\x93\x94",
  task_title  => "\xF0\x9F\x93\x8C",
  task_type   => "\xF0\x9F\x97\x82",
  task_desc   => "\xF0\x9F\x93\x9D",
};

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $admin_config)

  Constructor for Admin_tasks module

=cut
#**********************************************************
sub new {
  my ($class, $conf, $bot, $bot_db, $APILayer, $admin_config) = @_;

  my $self = {
    conf         => $conf,
    bot          => $bot,
    bot_db       => $bot_db,
    api          => $APILayer,
    admin_config => $admin_config,
    for_admins   => 1,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  return 1;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;
  return $self->{bot}{lang}{TELEGRAM_TASKS};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my ($self, $attr) = @_;

  my $current_date = $main::DATE;
  my $icons = ICONS;

  my ($tasks) = $self->{api}->fetch_api({
    PATH   => '/tasks/',
    PARAMS => {
      CONTROL_DATE => $current_date,
      STATE        => '0',
      RESPONSIBLE  => $self->{admin_config}{AID},
      PAGE_ROWS    => 5,
    }
  });

  my $message = "$icons->{page} $self->{bot}{lang}{TELEGRAM_TASKS_LIST_FOR}: <b>$current_date</b>\n\n";

  my @info = ();
  my @buttons = ();
  my @inline_keyboard = ();
  my $number = 1;

  foreach my $task (@{$tasks->{list}}) {
    $task->{type_name} ||= $self->{bot}{lang}{TELEGRAM_WITHOUT_TYPE};
    my $icon = $icons->{"number_" . $number++} || '';

    my $task_info = "$icon  <b>$task->{name}</b>\n";
    $task_info .= "$icons->{task_type} $task->{type_name}\n";
    $task_info .= "$icons->{task_desc} $task->{descr}\n";

    push(@info, $task_info);
    push(@buttons, {
      text          => $icon,
      callback_data => "Admin_tasks&task_info&$task->{id}"
    });
  }

  push @inline_keyboard, \@buttons;

  $message .= join($icons->{line} x 9 . "\n", @info);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard,
      resize_keyboard => "true",
    },
  });

  $self->{bot_db}->add({
    USER_ID => $self->{bot}->{chat_id},
    BUTTON  => "Admin_tasks",
    FN      => "main_task_menu",
    ARGS    => '{"message":{"text":""}}',
  });

  my @keyboard = (
    [ { text => $self->{bot}{lang}{TELEGRAM_TASKS_REPORT} } ],
    [ { text => $self->{bot}{lang}{TELEGRAM_NEW_TASK} } ],
    [ { text => $self->{bot}{lang}{TELEGRAM_OVERDUE_TASKS} } ],
    [ { text => $self->{bot}->{lang}->{CANCEL_TEXT} } ],
  );

  $self->{bot}->send_message({
    text         => "$self->{bot}{lang}{TELEGRAM_TASKS_MENU} \xf0\x9f\x91\x87",
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
  });

  return 1;
}

#**********************************************************
=head2 cancel_msg()

=cut
#**********************************************************
sub cancel_msg {
  my $self = shift;
  $self->{bot_db}->del($self->{bot}->{chat_id});
  return 1;
}

#**********************************************************
=head2 main_task_menu()

=cut
#**********************************************************
sub main_task_menu {
  my ($self, $attr) = @_;

  if ($attr->{update}->{callback_query}->{data}) {
    my (undef, $function_name, $task_id) = split(/&/x, $attr->{update}->{callback_query}->{data});
    $self->task_info({ task_id => $task_id });
    return 1;
  }

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});

    if ($text eq $self->{bot}->{lang}->{CANCEL_TEXT}) {
      $self->cancel_msg();
      return 0;
    }

    if ($text eq $self->{bot}{lang}{TELEGRAM_NEW_TASK}) {
      my @keyboard = ([ { text => $self->{bot}->{lang}->{CANCEL_TEXT} } ]);

      $self->{bot}->send_message({
        text         => $self->{bot}->{lang}->{TELEGRAM_ENTER_TASK_NAME},
        reply_markup => {
          keyboard        => \@keyboard,
          resize_keyboard => "true",
        },
      });

      $self->{bot_db}->del($self->{bot}->{chat_id});
      $self->{bot_db}->add({
        USER_ID => $self->{bot}->{chat_id},
        BUTTON  => "Admin_tasks",
        FN      => "task_add",
        ARGS    => '{"message":{"text":""}}',
      });

      return 1;
    }

    if ($text eq $self->{bot}{lang}{TELEGRAM_OVERDUE_TASKS}) {
      $self->expired_tasks();
      return 1;
    }

    if ($text eq $self->{bot}{lang}{TELEGRAM_TASKS_REPORT}) {
      $self->task_report();
      return 1;
    }
  }

  $self->{bot}->send_message({
    text         => "$self->{bot}{lang}{TELEGRAM_TASKS_MENU} \xf0\x9f\x91\x87",
    reply_markup => {
      resize_keyboard => "true",
    },
  });

  return 1;
}

#**********************************************************
=head2 task_add()

=cut
#**********************************************************
sub task_add {
  my ($self, $attr) = @_;

  my $info = $attr->{step_info};

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});

    if ($text eq $self->{bot}->{lang}->{CANCEL_TEXT}) {
      $self->cancel_msg();
      return 0;
    }

    my @keyboard = ([ { text => $self->{bot}->{lang}->{CANCEL_TEXT} } ]);

    $self->{bot}->send_message({
      text         => $self->{bot}->{lang}->{TELEGRAM_ENTER_TASK_DESCRIPTION},
      reply_markup => {
        keyboard        => \@keyboard,
        resize_keyboard => "true",
      },
    });

    my $msg_hash = decode_json($info->{args});
    $msg_hash->{message}->{task_name} = $attr->{message}->{text};
    $info->{ARGS} = encode_json($msg_hash);
  }

  $info->{FN} = "task_add_desc";
  $self->{bot_db}->change($info);

  return 1;
}

#**********************************************************
=head2 task_add_desc()

=cut
#**********************************************************
sub task_add_desc {
  my ($self, $attr) = @_;

  my $info = $attr->{step_info};
  my $current_date = $main::DATE;

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});

    if ($text eq $self->{bot}->{lang}->{CANCEL_TEXT}) {
      $self->cancel_msg();
      return 0;
    }

    my $msg_hash = decode_json($info->{args});

    my ($result) = $self->{api}->fetch_api({
      METHOD => 'POST',
      PATH   => '/tasks/',
      PARAMS => {
        NAME         => $msg_hash->{message}->{task_name},
        STATE        => '0',
        RESPONSIBLE  => $self->{admin_config}{AID},
        DESCR        => $text,
        CONTROL_DATE => $current_date
      }
    });

    my $message = ($result->{errno} && $result->{errstr})
      ? $result->{errstr}
      : $self->{bot}->{lang}->{TELEGRAM_TASK_CREATED};

    $self->{bot}->send_message({
      text         => $message,
      reply_markup => {
        resize_keyboard => "true",
      },
    });
  }

  $self->{bot_db}->del($self->{bot}->{chat_id});

  return 0;
}

#**********************************************************
=head2 task_info()

=cut
#**********************************************************
sub task_info {
  my ($self, $attr) = @_;

  my $task_id = $attr->{task_id} || $attr->{argv}[2];

  if (!$task_id) {
    return 0;
  }

  $self->{bot_db}->del($self->{bot}->{chat_id});

  my ($task) = $self->{api}->fetch_api({
    PATH => "/tasks/$task_id"
  });

  my $subject = $task->{NAME} || $self->{bot}{lang}{NO_SUBJECT};
  my $message = "#$task_id <b>$subject</b>\n\n";

  my @inline_keyboard = (
    [ {
      text          => $self->{bot}->{lang}->{TELEGRAM_CLOSE_TASK},
      callback_data => "Admin_tasks&close_task&$task_id"
    } ],
    [ {
      text          => $self->{bot}->{lang}->{TELEGRAM_DELEGATE_TASK},
      callback_data => "Admin_tasks&delegate_task&$task_id"
    } ],
  );

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard,
      resize_keyboard => "true",
    },
  });

  return 1;
}

#**********************************************************
=head2 expired_tasks()

=cut
#**********************************************************
sub expired_tasks {
  my ($self, $attr) = @_;

  my $current_date = $main::DATE;
  my $icons = ICONS;

  my ($expired_tasks) = $self->{api}->fetch_api({
    PATH   => '/tasks/',
    PARAMS => {
      CONTROL_DATE => "<$current_date",
      STATE        => '0',
      RESPONSIBLE  => $self->{admin_config}{AID},
      PAGE_ROWS    => 5,
    }
  });

  my $message = "$icons->{expired} $self->{bot}->{lang}->{TELEGRAM_OVERDUE_TASKS_TITLE}\n\n";

  my @info = ();
  my @buttons = ();
  my @inline_keyboard = ();
  my $number = 1;

  if ($expired_tasks->{list}) {
    foreach my $task (@{$expired_tasks->{list}}) {
      $task->{type_name} ||= $self->{bot}->{lang}->{TELEGRAM_WITHOUT_TYPE};
      my $icon = $icons->{"number_" . $number++} || '';

      my $task_info = "$icon  <b>$task->{name}</b>\n";
      $task_info .= "$icons->{task_type} $task->{type_name}\n";
      $task_info .= "$icons->{task_desc} $task->{descr}\n";

      push(@info, $task_info);
    }

    $message .= join($icons->{line} x 9 . "\n", @info);
  }

  $self->{bot}->send_message({
    text => $message
  });

  return 1;
}

#**********************************************************
=head2 task_report()

=cut
#**********************************************************
sub task_report {
  my ($self, $attr) = @_;

  my $icons = ICONS;
  my $weeks_range = _get_weeks_range();

  my $total_opened_this_week = $self->_fetch_total_tasks($weeks_range->{this_week});
  my $total_opened_last_week = $self->_fetch_total_tasks($weeks_range->{last_week});
  my $total_closed_this_week = $self->_fetch_total_tasks($weeks_range->{this_week}, 1);
  my $total_closed_last_week = $self->_fetch_total_tasks($weeks_range->{last_week}, 1);
  my $total_expired_this_week = $self->_fetch_total_tasks($weeks_range->{this_week}, 0, 1);
  my $total_expired_last_week = $self->_fetch_total_tasks($weeks_range->{last_week}, 0);

  my $report_text = <<"END";
$icons->{report} $self->{bot}{lang}{TELEGRAM_TASKS_REPORT}

$icons->{open} $self->{bot}{lang}{TELEGRAM_OPEN}:
$icons->{line} $self->{bot}{lang}{TELEGRAM_THIS_WEEK}: $total_opened_this_week
$icons->{line} $self->{bot}{lang}{TELEGRAM_LAST_WEEK}: $total_opened_last_week

$icons->{closed} $self->{bot}{lang}{CLOSED}:
$icons->{line} $self->{bot}{lang}{TELEGRAM_THIS_WEEK}: $total_closed_this_week
$icons->{line} $self->{bot}{lang}{TELEGRAM_LAST_WEEK}: $total_closed_last_week

$icons->{expired} $self->{bot}{lang}{TELEGRAM_OVERDUE}:
$icons->{line} $self->{bot}{lang}{TELEGRAM_THIS_WEEK}: $total_expired_this_week
$icons->{line} $self->{bot}{lang}{TELEGRAM_LAST_WEEK}: $total_expired_last_week
END

  $self->{bot}->send_message({ text => $report_text });

  return 1;
}

#**********************************************************
=head2 close_task()

=cut
#**********************************************************
sub close_task {
  my ($self, $attr) = @_;

  my $task_id = $attr->{task_id} || $attr->{argv}[2];

  if (!$task_id) {
    return 0;
  }

  my ($result) = $self->{api}->fetch_api({
    METHOD => 'PUT',
    PATH   => '/tasks/' . $task_id,
    PARAMS => {
      STATE => 1
    }
  });

  my $message = ($result->{errno} && $result->{errstr})
    ? $result->{errstr}
    : $self->{bot}{lang}{TELEGRAM_TASK_SUCCESSFULLY_CLOSED};

  $self->{bot}->send_message({
    text => $message,
  });

  return 1;
}

#**********************************************************
=head2 delegate_task()

=cut
#**********************************************************
sub delegate_task {
  my ($self, $attr) = @_;

  my $task_id = $attr->{task_id} || $attr->{argv}[2];

  if (!$task_id) {
    return 0;
  }

  my ($result) = $self->{api}->fetch_api({
    METHOD => 'PUT',
    PATH   => '/tasks/' . $task_id,
    PARAMS => {
      RESPONSIBLE => 0
    }
  });

  my $message = ($result->{errno} && $result->{errstr})
    ? $result->{errstr}
    : $self->{bot}{lang}{TELEGRAM_TASK_SUCCESSFULLY_DELEGATED};

  $self->{bot}->send_message({
    text => $message,
  });

  return 1;
}

#**********************************************************
=head2 _get_weeks_range()

=cut
#**********************************************************
sub _get_weeks_range {

  my $now = time;
  my @lt = localtime($now);

  my $wday = $lt[6] || 7;

  my $start_this_week = $now - ($wday - 1) * 24 * 3600;
  my $end_this_week = $start_this_week + 6 * 24 * 3600;

  my $start_last_week = $start_this_week - 7 * 24 * 3600;
  my $end_last_week = $start_last_week + 6 * 24 * 3600;

  return {
    this_week => {
      start => strftime("%Y-%m-%d", localtime($start_this_week)),
      end   => strftime("%Y-%m-%d", localtime($end_this_week))
    },
    last_week => {
      start => strftime("%Y-%m-%d", localtime($start_last_week)),
      end   => strftime("%Y-%m-%d", localtime($end_last_week))
    },
  };
}

#**********************************************************
=head2 _fetch_total_tasks($self, $range, $status)

=cut
#**********************************************************
sub _fetch_total_tasks {
  my ($self, $range, $status, $expired) = @_;

  my %params = ();
  if ($expired) {
    my $current_date = $main::DATE;
    %params = (
      CONTROL_DATE => "<$current_date",
      STATE        => defined $status ? $status : '_SHOW'
    );
  }
  else {
    %params = (
      CONTROL_FROM_DATE => $range->{start},
      CONTROL_TO_DATE   => $range->{end},
      STATE             => defined $status ? $status : '_SHOW'
    );
  }

  if ($self->{admin_config}{AID}) {
    $params{RESPONSIBLE} = $self->{admin_config}{AID};
  }

  my ($result) = $self->{api}->fetch_api({
    PATH   => '/tasks/',
    PARAMS => \%params
  });

  return $result->{total} || 0;
}

1;