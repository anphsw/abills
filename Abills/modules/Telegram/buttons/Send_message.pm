package Telegram::buttons::Send_message;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use JSON;

my %icons = (
  message => "\xE2\x9C\x89\xEF\xB8\x8F"
);

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $user_config)

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
      text => $chapter->{name}
    };

    push @keyboard, [$button];
  }

  my $button = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };
  push (@keyboard, [$button]);


  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
  });

  $self->{bot_db}->add({
    USER_ID    => $self->{bot}->{chat_id},
    BUTTON => "Send_message",
    FN     => "select_chapter",
    ARGS   => '{"message":{"text":""}}',
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

  my $message = "$self->{bot}->{lang}->{SUBJECT_ADD}:\n";

  my @keyboard = ();
  my $button = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };
  push (@keyboard, [$button]);

  my $info = $attr->{step_info};

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});

    if ($text eq "$self->{bot}->{lang}->{CANCEL_TEXT}") {
      $self->cancel_msg();
      return 0;
    }

    my ($chapters) = $self->{api}->fetch_api({ PATH => '/user/msgs/chapters' });

    my ($matched) = grep { $_->{name} eq $text } @$chapters;
    if ($matched) {
      my $msg_hash = decode_json($info->{args});
      $msg_hash->{message}->{chapter} = $matched->{id};
      $info->{ARGS} = encode_json($msg_hash);
    }
    else {
      $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
      return 1;
    }
  }

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
  });


  $info->{FN} = "add_title_to_msg";
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
    my $text = encode_utf8($attr->{message}->{text});
    if ($text eq "$self->{bot}->{lang}->{CANCEL_TEXT}") {
      $self->cancel_msg();
      return 0;
    }
    else {
      my $title = $attr->{message}->{text};
      my $msg_hash = decode_json($info->{args});
      $msg_hash->{message}->{title} = $title;
      $info->{ARGS} = encode_json($msg_hash);
    }
  }
  else {
    $self->{bot}->send_message({ text => 'TEXT_NOT_FOUND' });
    return 1;
  }

  $info->{FN} = "add_to_msg";
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

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});
    if ($text eq "$self->{bot}->{lang}->{CANCEL_TEXT}") {
      $self->cancel_msg();
      return 0;
    }
    elsif ($text eq "$self->{bot}->{lang}->{SEND}") {
      $self->send_msg($attr);
      return 0;
    }
    elsif ($text eq "$self->{bot}->{lang}->{SUBJECT_EDIT}") {
      $self->add_title($attr);
      return 1;
    }
    $self->add_text_to_msg($attr);
  }
  elsif ($attr->{message}->{photo}) {
    my $photo = pop @{$attr->{message}->{photo}};
    $self->add_file_to_msg($attr, $photo->{file_id});
  }
  elsif ($attr->{message}->{document}) {
    $self->add_file_to_msg($attr, $attr->{message}->{document}->{file_id});
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
  my $button1 = {
    text => "$self->{bot}->{lang}->{BACK}",
  };
  my $button2 = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };
  push (@keyboard, [$button1], [$button2]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
  });

  $info->{FN} = 'add_title_to_msg';
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

  $self->{bot}->send_message({
    text => "$self->{bot}->{lang}->{ADD_FILE}",
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
  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{SEND_CANCEL}" });
  return 1;
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

  if(!$text && !$msg_hash->{message}->{files}){
    $self->{bot}->send_message({
      text => "$self->{bot}->{lang}->{NOT_SEND_MSGS}",
    });
    return 0;
  }

  my $subject = $msg_hash->{message}->{title} || "Telegram Bot";
  my $chapter = $msg_hash->{message}->{chapter};

  my $props = {
    MESSAGE   => $text,
    SUBJECT   => $subject,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
    SEND_TYPE => 6
  };

  if ($msg_hash->{message}->{files}) {
    for my $i (0..$#{$msg_hash->{message}->{files}}) {
      my $file = $msg_hash->{message}->{files}->[$i];
      my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file);
      my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

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

  $self->{bot_db}->del($self->{bot}->{chat_id});
  $self->{bot}->send_message({ text => "$self->{bot}->{lang}->{SEND_MSGS}" });

  return 1;
}

#**********************************************************
=head2 send_msgs_main_menu

=cut
#**********************************************************
sub send_msgs_main_menu {
  my $self = shift;
  my $info = shift;

  my @keyboard = ();
  my $button1 = {
    text => "$self->{bot}->{lang}->{SUBJECT_EDIT}",
  };
  my $button2 = {
    text => "$self->{bot}->{lang}->{SEND}",
  };
  my $button3 = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };

  my $msg_hash = decode_json($info->{args});

  push (@keyboard, [$button1]);
  push @keyboard, [$button2] if($msg_hash->{message}->{text} || $msg_hash->{message}->{files});
  push @keyboard, [$button3];

  my $message   .= "$self->{bot}->{lang}->{SEND_OR_CANCEL}\n";

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
  });

  return 1;
}

1;
