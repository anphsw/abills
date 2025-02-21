package Telegram::buttons::Admin_msgs;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array int2ip json_former vars2lang);
use JSON qw/decode_json encode_json/;
use Encode qw/encode_utf8 decode_utf8/;

my %icons = (
  user        => "\xF0\x9F\x91\xA4",
  date        => "\xF0\x9F\x95\x98",
  closed      => "\xE2\x9C\x85",
  open        => "\xE2\x8C\x9B",
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
  fixation    => "\xf0\x9f\x93\x94"
);
my %msgs_status = ();

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $admin_config)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $admin_config) = @_;

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
  my $self = shift;

  return 1;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}{lang}{MESSAGES};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  $self->_get_statuses();

  my $page = $attr->{argv}[2];
  my $message = "$icons{page} <b>$self->{bot}{lang}{ADMIN}:</b> $self->{admin_config}{A_FIO}\n\n";
  my @inline_keyboard = ();
  my @equipment_buttons = ();

  $message .= $self->messages_list($page, \@equipment_buttons);

  push @inline_keyboard, \@equipment_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, 'click');

  $self->_send_message($message, $page, \@inline_keyboard, $attr);

  return 1;
}

#**********************************************************
=head2 messages_list($page, $buttons)

=cut
#**********************************************************
sub messages_list {
  my $self = shift;
  my ($page, $buttons, $attr) = @_;

  my @info = ();

  my ($messages) = $self->{api}->fetch_api({
    PATH   => '/msgs/list',
    PARAMS => {
      SUBJECT      => '_SHOW',
      STATE_ID     => '_SHOW',
      DATETIME     => '_SHOW',
      MESSAGE      => '_SHOW',
      CHAPTER_NAME => '_SHOW',
      UID          => '_SHOW',
      LOGIN        => '_SHOW',
      FIO          => '_SHOW',
      STATE        => '!1,!2',
      RESPOSIBLE   => $self->{admin_config}{AID},
      PAGE_ROWS    => 5,
      PG           => $page ? (($page - 1) * 5) : 0,
      %{$attr // {}},
    }
  });

  $self->{last_page} = int($messages->{total} / 5) + ($messages->{total} % 5 == 0 ? 0 : 1) if $messages->{total} > 5;

  my $number = 1;
  foreach my $message (@{$messages->{list}}) {
    my $icon = $icons{"number_" . $number++} || '';
    $message->{subject} ||= $self->{bot}{lang}{NO_SUBJECT};
    $message->{chapter_name} ||= $self->{bot}{lang}{NO_CHAPTER};
    $message->{fio} ||= $message->{login} || '';
    $message->{status} = $msgs_status{$message->{state_id}} || '';

    my $message_info = "$icon  <b>$message->{subject}</b>\n";
    $message_info .= "$icons{chapter} $message->{chapter_name}\n";
    $message_info .= "$icons{date} $message->{datetime}\n";
    $message_info .= "$message->{status}\n";
    $message_info .= "$icons{user} $message->{fio}\n";

    push(@info, $message_info);
    push(@{$buttons}, {
      text          => $icon,
      callback_data => "Admin_msgs&msgs_info&$message->{id}"
    });
  }

  return join($icons{line} x 9 . "\n", @info);
}

#**********************************************************
=head2 msgs_info($attr)

=cut
#**********************************************************
sub msgs_info {
  my $self = shift;
  my ($attr) = @_;

  my $msg_id = $attr->{argv}[2];
  return if !$msg_id;

  $self->_get_statuses();

  my @inline_keyboard = ();
  my ($msg_info) = $self->{api}->fetch_api({ PATH => "/msgs/$msg_id" });

  my $subject = $msg_info->{SUBJECT} || $self->{bot}{lang}{NO_SUBJECT};
  my $chapter_name = $msg_info->{CHAPTER_NAME} || $self->{bot}{lang}{NO_CHAPTER};
  my $status = $msgs_status{$msg_info->{STATE}} || '';

  my $message = "#$msg_id <b>$subject</b>\n\n";

  $message .= "$icons{chapter} $chapter_name\n";
  $message .= "$icons{date} $msg_info->{DATE}\n";
  $message .= "$status\n";
  $message .= "$icons{user} $msg_info->{LOGIN}\n\n";

  $message .= "$msg_info->{MESSAGE}\n";

  if ($msg_info->{UID}) {
    my $user_btn = {
      text          => "$icons{user} $self->{bot}{lang}{USER_INFO}",
      callback_data => "Admin_msgs&user_info&$msg_info->{UID}"
    };

    push(@inline_keyboard, [$user_btn]) if $msg_info->{UID};
  }

  my $fixation_btn = {
    text          => "$icons{fixation} $self->{bot}{lang}{FIXATION}",
    callback_data => "Admin_msgs&msg_tech_flow&$msg_id"
  };

  push(@inline_keyboard, [$fixation_btn]);

  $self->_send_message($message, 0, \@inline_keyboard);
  $self->{bot}->answer_callback_query({ callback_query_id => $attr->{update}{callback_query}{id} });
}

#**********************************************************
=head2 user_info($attr)

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{argv}[2];
  return if !$uid;

  my ($user_pi) = $self->{api}->fetch_api({ PATH => "/users/$uid/pi" });

  my $message = "<b>$self->{bot}{lang}{USER_INFO}</b>\n\n";
  $message .= "<b>$self->{bot}{lang}{FIO}</b>: $user_pi->{FIO}\n";
  for my $phone (@{$user_pi->{PHONE}}) {
    $message .= "<b>$self->{bot}{lang}{PHONE}</b>: $phone\n";
  }
  $message .= $icons{wave_line} x 9 . "\n";
  $message .= $self->_user_internet_info($uid);

  $self->{bot}->send_message({ text => $message });
  $self->{bot}->answer_callback_query({ callback_query_id => $attr->{update}{callback_query}{id} });
}

#**********************************************************
=head2 search($attr)

=cut
#**********************************************************
sub search {
  my $self = shift;
  my ($attr) = @_;

  my $search = Encode::encode_utf8($attr->{argv}[2]) || '';
  my $page = $attr->{argv}[3] || 0;

  $self->_get_statuses();

  my $search_text = "$icons{search} <b>$self->{bot}{lang}{SEARCH}: $search</b>\n\n";
  my @msgs_buttons = ();
  my @inline_keyboard = ();

  $search_text .= $self->messages_list($page, \@msgs_buttons, { SEARCH_MSGS => $search, STATE => '_SHOW' });

  push @inline_keyboard, \@msgs_buttons;
  push @inline_keyboard, _get_page_range($page, $self->{last_page}, "search&$search");

  $self->_send_message($search_text, $page, \@inline_keyboard, $attr);
}

#**********************************************************
=head2 msg_tech_flow($attr)

=cut
#**********************************************************
sub msg_tech_flow {
  my $self = shift;
  my ($attr) = @_;

  my $msg_id = $attr->{argv}[2];
  return if !$msg_id;

  $self->{bot}->answer_callback_query({ callback_query_id => $attr->{update}{callback_query}{id} });
  my ($msg_info) = $self->{api}->fetch_api({
    METHOD => 'PUT',
    PATH   => "/msgs/$msg_id",
    PARAMS => {
      RESPOSIBLE => $self->{admin_config}{AID}
    }
  });

  if ($msg_info->{errno}) {
    $self->{bot}->send_message({
      text => 'ERROR'
    });

    return 1;
  }

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{TASK_FIXATED},
    reply_markup => {
      remove_keyboard => 'true'
    },
  });

  $self->{bot_db}->add({
    USER_ID    => $self->{bot}{chat_id},
    BUTTON => "Admin_msgs",
    FN     => "msg_send_photo",
    ARGS   => json_former({
      msgs => {
        fixation => {
          msg_id => $msg_id,
          start => {
            date => $attr->{update}{callback_query}{message}{date}
          }
        }
      }
    }),
  });

  return 1;
}

#**********************************************************
=head2 msg_send_photo($attr)

=cut
#**********************************************************
sub msg_send_photo {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  my $msg_id = $args->{msgs}{fixation}{msg_id};
  return 1 if !$msg_id;

  my $task_state = $args->{msgs}{fixation}{is_ending} ? 'end' : 'start';

  $info->{FN} = "msg_send_location";

  if (!$attr->{message}{photo}) {
    $self->{bot}->send_message({
      text => $self->{bot}{lang}{THERE_IS_NO_PHOTO}
    });
    return 1;
  }

  my @keyboard = ();

  my $geo_button = {
    text             => $self->{bot}{lang}{GEO},
    request_location => 'true'
  };

  my $skip_step_btn = {
    text => $self->{bot}{lang}{SKIP},
  };

  push @keyboard, [$geo_button];
  push @keyboard, [$skip_step_btn];

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{PHOTO_ADD_SUCCESS},
    reply_markup => {
      keyboard => \@keyboard,
      resize_keyboard => "true",
    },
  });

  $args->{msgs}{fixation}{$task_state}{photos} = [ $attr->{message}{photo}->[-1]->{file_id} ];
  $info->{ARGS} = encode_json($args);
  $self->{bot_db}->change($info);

  return 1;
}

#**********************************************************
=head2 msg_send_location($attr)

=cut
#**********************************************************
sub msg_send_location {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  my $msg_id = $args->{msgs}{fixation}{msg_id};
  return if !$msg_id;

  my $task_state = $args->{msgs}{fixation}{is_ending} ? 'end' : 'start';

  $info->{FN} = $task_state eq 'end' ? 'msg_close_ticket' : 'msg_confirm_end';

  my $text = encode_utf8($attr->{message}->{text} || '');
  if ($text eq $self->{bot}{lang}{SKIP}) {
    my @keyboard = ();

    my $done_button = {
      text             => $self->{bot}{lang}{TASK_DONE},
    };

    push @keyboard, [$done_button];

    $self->{bot}->send_message({
      text         => $self->{bot}{lang}{SKIP_SEND_LOCATION},
      reply_markup => {
        keyboard => \@keyboard,
        resize_keyboard => "true",
      },
    });

    $info->{ARGS} = encode_json($args);
    $self->{bot_db}->change($info);

    $attr->{step_info} = $self->{bot_db}->info($self->{bot}{chat_id});
    if (!$args->{msgs}{fixation}{is_ending}) {
      $self->{bot}->send_message({
        text         => $self->{bot}{lang}{CONFIRM_CLOSE_TASK},
        reply_markup => {
          keyboard        => \@keyboard,
          resize_keyboard => "true",
        },
      });
      return $self->msg_step_to_close($attr);
    }
    else {
      return $self->msg_close_ticket($attr);
    }
  };

  my $location = $attr->{message}{location};
  if (!$location) {
    $self->{bot}->send_message({
      text => $self->{bot}{lang}{THERE_IS_NO_GEO}
    });
    return 1;
  }

  my @keyboard = ();

  my $done_button = {
    text  => $self->{bot}{lang}{TASK_DONE},
  };

  push @keyboard, [$done_button];

  $args->{msgs}{fixation}{$task_state}{location} = $location;
  $info->{ARGS} = encode_json($args);
  $self->{bot_db}->change($info);

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{GEO_COLLECTED},
  });

  $attr->{step_info} = $self->{bot_db}->info($self->{bot}{chat_id});
  if (!$args->{msgs}{fixation}{is_ending}) {
    $self->{bot}->send_message({
      text         => $self->{bot}{lang}{CONFIRM_CLOSE_TASK},
      reply_markup => {
        keyboard        => \@keyboard,
        resize_keyboard => "true",
      },
    });
    return $self->msg_step_to_close($attr);
  }
  else {
    return $self->msg_close_ticket($attr);
  }
}

#**********************************************************
=head2 msg_confirm_end($attr)

=cut
#**********************************************************
sub msg_confirm_end {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  my $msg_id = $args->{msgs}{fixation}{msg_id};

  return if !$msg_id;

  $info->{FN} = 'msg_send_photo';
  $args->{msgs}{fixation}{is_ending} = 1;

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{TICKET_END_CONFIRM},
    reply_markup => {
      remove_keyboard => "true",
    },
  });

  $info->{ARGS} = encode_json($args);
  $self->{bot_db}->change($info);

  return 1;
}

#**********************************************************
=head2 msg_step_to_close($attr)

=cut
#**********************************************************
sub msg_step_to_close {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  my $msg_id = $args->{msgs}{fixation}{msg_id};

  return if !$msg_id;

  my $location = $args->{msgs}{fixation}{start}{location};

  $info->{FN} = 'msg_send_photo';
  $args->{msgs}{fixation}{is_ending} = 1;

  my $props = {};

  for my $i (0..$#{$args->{msgs}{fixation}{start}{photos}}) {
    my $file = $args->{msgs}{fixation}{start}{photos}->[$i];
    my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file);
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

    next unless ($file_content && $file_size && $file_name && $file_extension);

    my $file_content_type = main::file_content_type($file_extension);

    $props->{'FILE' . ($i + 1)} = {
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      SIZE         => $file_size,
      CONTENTS     => $file_content,
      COORDX       => $location->{longitude},
      COORDY       => $location->{latitude},
    };
  }

  my ($msg_info) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => "/msgs/$msg_id/reply",
    PARAMS => $props
  });

  if ($msg_info->{errno}) {
    $self->{bot}->send_message({
      text => 'ERROR'
    });

    return 1;
  }

  return 1;
}

#**********************************************************
=head2 msg_close_ticket($attr)

=cut
#**********************************************************
sub msg_close_ticket {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  my $msg_id = $args->{msgs}{fixation}{msg_id};

  return if !$msg_id;

  my $location = $args->{msgs}{fixation}{end}{location};
  my $end_date = $attr->{update}{message}{date};
  my $diff_date = $end_date - $args->{msgs}{fixation}{start}{date};

  my $props = {};

  my $run_time = POSIX::strftime('%H:%M:%S', gmtime($diff_date));
  $props->{RUN_TIME} = $run_time;

  for my $i (0..$#{$args->{msgs}{fixation}{end}{photos}}) {
    my $file = $args->{msgs}{fixation}{end}{photos}->[$i];
    my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file);
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

    next unless ($file_content && $file_size && $file_name && $file_extension);

    my $file_content_type = main::file_content_type($file_extension);

    $props->{'FILE' . ($i + 1)} = {
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      SIZE         => $file_size,
      CONTENTS     => $file_content,
      COORDX       => $location->{longitude},
      COORDY       => $location->{latitude},
    };
  }

  my ($msg_info) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => "/msgs/$msg_id/reply",
    PARAMS => $props
  });

  my ($close_res) = $self->{api}->fetch_api({
    METHOD => 'PUT',
    PATH   => "/msgs/$msg_id",
    PARAMS => {
      STATE => 2
    }
  });

  if ($msg_info->{errno} || $close_res->{errno}) {
    $self->{bot}->send_message({
      text => 'ERROR'
    });

    return 1;
  }

  my $params = {
    MSG_ID      => $msg_id,
    RUN_TIME    => $run_time,
    GEOLOCATION => %$location ? "$location->{longitude} $location->{latitude}" : $self->{bot}{lang}{NOT_EXIST}
  };

  my $text = vars2lang($self->{bot}{lang}{TASK_DONE_OVERALL}, $params);

  $self->{bot}->send_message({
    text         => $text,
    reply_markup => {
      remove_keyboard => "true",
    },
  });

  $self->{bot_db}->del($self->{bot}{chat_id});

  return 0;
}

#**********************************************************
=head2 _user_internet_info($uid)

=cut
#**********************************************************
sub _user_internet_info {
  my $self = shift;
  my $uid = shift;

  my ($internet_info) = $self->{api}->fetch_api({
    PATH   => "/users/$uid/internet",
    PARAMS => {
      TP_NAME => '_SHOW',
      IP_NUM  => '_SHOW',
    },
  });

  my @info = ();
  foreach my $tp (@{$internet_info}) {
    my $ip = int2ip($tp->{ip_num});

    my $message_info = "<b>$self->{bot}{lang}{NAME}</b>: $tp->{tp_name}\n";
    $message_info .= "<b>IP</b>: $ip\n";
    push(@info, $message_info);
  }

  return "<b>$self->{bot}{lang}{TARIF_PLANS}:</b> \n\n" . join($icons{line} x 9 . "\n", @info);
}

#**********************************************************
=head2 _get_page_range($page, $last_page, $path)

=cut
#**********************************************************
sub _get_page_range {
  my ($page, $last_page, $path) = @_;

  return [] if !$last_page || $last_page < 2;

  my @row = ();
  my @range = $last_page < 5 ? (1 .. $last_page) : (!$page || $page < 4) ? (1 .. 4, $last_page) :
    ($page + 2 < $last_page) ? (1, $page - 1 .. $page + 1, $last_page) : (1, $last_page - 3 .. $last_page);

  for (@range) {
    push @row, {
      text          => (!$page && $_ eq '1') || ($page && $page eq $_) ? "$icons{right_arrow} $_" : $_,
      callback_data => "Admin_msgs&$path&$_"
    }
  }

  return \@row;
}

#**********************************************************
=head2 _send_message($message, $page, $inline_keyboard, $attr)

=cut
#**********************************************************
sub _send_message {
  my $self = shift;
  my ($message, $page, $inline_keyboard, $attr) = @_;

  push @{$inline_keyboard}, [ {
    text                             => $icons{search} . ' ' . $self->{bot}{lang}{SEARCH},
    switch_inline_query_current_chat => "/msgs "
  } ];

  if ($page) {
    $self->{bot}->edit_message_text({
      text         => $message,
      message_id   => $attr->{message_id},
      reply_markup => {
        inline_keyboard => $inline_keyboard,
        resize_keyboard => "true",
      },
    });
    return 1;
  }

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => $inline_keyboard,
      resize_keyboard => "true",
    },
  });
}

#**********************************************************
=head2 _get_statuses()

=cut
#**********************************************************
sub _get_statuses {
  my $self = shift;

  my ($statuses) = $self->{api}->fetch_api({
    PATH   => '/msgs/statuses',
    PARAMS => {
      TASK_CLOSED => '_SHOW',
      STATUS_ONLY => 1,
      NAME        => '_SHOW',
    }
  });

  foreach my $status (@{$statuses->{list}}) {
    my $icon = $status->{task_closed} ? 'closed' : 'open';
    $msgs_status{$status->{id}} = $icons{$icon} . ' ' . ($status->{locale_name} || '');
  }
}

1;
