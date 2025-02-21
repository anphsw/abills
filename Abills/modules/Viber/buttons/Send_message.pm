package Viber::buttons::Send_message;

use strict;
use warnings FATAL => 'all';

use JSON;

my %icons = (
  message => "\xE2\x9C\x89\xEF\xB8\x8F"
);

#**********************************************************
=head2 new($conf, $bot_api, $bot_db, $APILayer)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
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

  return $self->{user_config}{msgs_user};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{message} $self->{bot}{lang}{SEND_MESSAGE}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $message = "$self->{bot}->{lang}->{SELECT_CHAPTER}\n";
  my @keyboard = ();

  my ($chapters) = $self->{api}->fetch_api({ PATH => '/user/msgs/chapters' });

  for my $chapter (@{$chapters}) {
    my $button = {
      ActionType => 'reply',
      ActionBody => 'fn:Send_message&select_chapter&' . $chapter->{id},
      Text       => $chapter->{name},
      TextSize   => 'regular'
    };

    push @keyboard, $button;
  }


  my $cancel_button = $self->_cancel_button();

  push @keyboard, $cancel_button;


  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => "true",
      Buttons => \@keyboard
    },
  });

  $self->{bot_db}->add({
    SENDER_ID => $self->{bot}->{receiver},
    BUTTON    => "Send_message",
    FN        => "fn:Send_message&select_chapter",
    ARGS      => '{"message":{"text":""}}',
  });

  return 1;
}

#**********************************************************
=head2 select_chapter()

=cut
#**********************************************************
sub select_chapter {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  # Keep state on something unexpected
  $info->{FN} = $info->{FN} . '&' . $attr->{argv}->[0];
  $self->{bot_db}->change($info);

  my $message = "$self->{bot}->{lang}->{SUBJECT_ADD}:\n";

  my @keyboard = ();

  my ($chapters) = $self->{api}->fetch_api({ PATH => '/user/msgs/chapters' });

  my ($matched) = grep { $_->{id} == $attr->{argv}->[0] } @$chapters;
  if ($matched) {
    my $msg_hash = decode_json($info->{args});
    $msg_hash->{message}->{chapter} = $matched->{id};
    $info->{ARGS} = encode_json($msg_hash);
  }
  else {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
    return 1;
  }

  my $cancel_button = $self->_cancel_button();

  push @keyboard, $cancel_button;

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });


  $info->{FN} = 'fn:Send_message&add_title_to_msg';
  $self->{bot_db}->change($info);
}

#**********************************************************
=head2 add_title_to_msg()

=cut
#**********************************************************
sub add_title_to_msg {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};

  if ($attr->{message}->{text}) {
    my $title = $attr->{message}->{text};
    my $msg_hash = decode_json($info->{args});
    $msg_hash->{message}->{title} = $title;
    $info->{ARGS} = encode_json($msg_hash);
  }
  else {
    $self->{bot}->send_message({ text => 'TEXT_NOT_FOUND' });
    return 1;
  }

  $info->{FN} = 'fn:Send_message&add_to_msg';
  $self->{bot_db}->change($info);

  $self->send_msgs_main_menu($info);
  return 1;
}

#**********************************************************
=head2 add_to_msg()

=cut
#**********************************************************
sub add_to_msg {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{message}->{type} eq "text") {
    $self->add_text_to_msg($attr);
  }
  elsif ($attr->{message}->{type} eq "picture") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $self->add_file_to_msg($attr, $file_id);
  }
  elsif ($attr->{message}->{type} eq "file") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $self->add_file_to_msg($attr, $file_id);
  }
  else {
    return 1;
  }

  $self->send_msgs_main_menu($attr->{step_info});
  return 1;
}

#**********************************************************
=head2 add_text_to_msg()

=cut
#**********************************************************
sub add_text_to_msg {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};
  my $text = $attr->{message}->{text};
  my $msg_hash = decode_json($info->{args});
  $msg_hash->{message}->{text} .= "$text\n";
  $info->{ARGS} = encode_json($msg_hash);
  $self->{bot_db}->change($info);

  $attr->{step_info}->{args} = $info->{ARGS};

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{ADD_MSGS_TEXT}",
  });
  return 1;
}

#**********************************************************
=head2 add_title()

=cut
#**********************************************************
sub add_title {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};

  my $message = "$self->{bot}->{lang}->{SUBJECT_MSGS}\n";
  $message   .= "$self->{bot}->{lang}->{CLICK_BACK}\n";
  $message   .= "$self->{bot}->{lang}->{CANCEL}\n";

  my @keyboard = ();
  my $back_button = {
    Text => "$self->{bot}->{lang}->{BACK}",
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&click',
    TextSize   => 'regular'
  };


  my $cancel_button = $self->_cancel_button();

  push (@keyboard, $back_button, $cancel_button);

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard,
    },
  });

  $info->{FN} = 'fn:Send_message&add_title_to_msg';
  $self->{bot_db}->change($info);

  return 1;
}

#**********************************************************
=head2 add_file_to_msg()

=cut
#**********************************************************
sub add_file_to_msg {
  my $self = shift;
  my ($attr, $file_id) = @_;
  my $info = $attr->{step_info};
  my $msg_hash = decode_json($info->{args});
  push(@{$msg_hash->{message}->{files}}, $file_id);

  $info->{ARGS} = encode_json($msg_hash);
  $self->{bot_db}->change($info);

  $attr->{step_info}->{args} = $info->{ARGS};

  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{ADD_FILE}" });
  return 1;
}

#**********************************************************
=head2 cancel_msg()

=cut
#**********************************************************
sub cancel_msg {
  my $self = shift;
  $self->{bot_db}->del($self->{bot}->{receiver});
  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{SEND_CANCEL}" });

  return 0;
}

#**********************************************************
=head2 send_msg()

=cut
#**********************************************************
sub send_msg {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $msg_hash = decode_json($info->{args});

  my $text = $msg_hash->{message}->{text} || "";

  if (!$text && !$msg_hash->{message}->{files}){
    $self->{bot_db}->del($self->{bot}->{receiver});
    $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{NOT_SEND_MSGS}", });
    return 0;
  }

  my $subject = $msg_hash->{message}->{title} || "Viber Bot";
  my $chapter = $msg_hash->{message}->{chapter};

  my $props = {
    MESSAGE   => $text,
    SUBJECT   => $subject,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
    SEND_TYPE => 5
  };

  if ($msg_hash->{message}->{files}) {
    for my $i (0..$#{$msg_hash->{message}->{files}}) {
      my $file = $msg_hash->{message}->{files}->[$i];
      my ($file_full_name, $file_size, $file_content) = $self->{bot}->get_file($file);
      my ($file_name, $file_extension) = $file_full_name =~ m/(.*)\.(.*)/;

      next unless ($file_content && $file_size && $file_name && $file_extension);

      my $file_content_type = main::file_content_type($file_extension);

      $props->{'FILE'. ($i+1)} = {
        FILENAME     => "$file_name.$file_extension",
        CONTENT_TYPE => $file_content_type,
        SIZE         => $file_size,
        CONTENTS     => $file_content,
      };
    }
  }

  $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/user/msgs',
    PARAMS => $props
  });

  $self->{bot_db}->del($self->{bot}->{receiver});
  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{SEND_MSGS}" });

  return 0;
}

#**********************************************************
=head2 send_msgs_main_menu()

=cut
#**********************************************************
sub send_msgs_main_menu {
  my $self = shift;
  my $info = shift;

  my @keyboard = ();

  my $edit_title = {
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&add_title',
    Text       => $self->{bot}->{lang}->{SUBJECT_EDIT},
    TextSize   => 'regular'
  };

  my $send_msg = {
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&send_msg',
    Text       => $self->{bot}->{lang}->{SEND},
    TextSize   => 'regular'
  };

  my $cancel_button = $self->_cancel_button();

  my $msg_hash = decode_json($info->{args});

  push @keyboard, $edit_title;
  push @keyboard, $send_msg if($msg_hash->{message}->{text} || $msg_hash->{message}->{files});
  push @keyboard, $cancel_button;

  my $message   .= "$self->{bot}->{lang}->{SEND_OR_CANCEL}\n";

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  return 1;
}

#**********************************************************
=head2 _cancel_button()

=cut
#**********************************************************
sub _cancel_button {
  my $self = shift;

  my $cancel_button = {
    ActionType => 'reply',
    ActionBody => 'fn:Send_message&cancel_msg',
    Text       => $self->{bot}->{lang}->{CANCEL_TEXT},
    BgColor    => '#FF0000',
    TextSize   => 'regular'
  };

  return $cancel_button;
}

1;
