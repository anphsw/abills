package Telegram::buttons::Msgs_reply;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use JSON;

require Telegram::buttons::Send_message;

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
=head2 reply()

=cut
#**********************************************************
sub reply {
  my $self = shift;
  my ($attr) = @_;

  return 0 unless ($attr->{argv}[2]);

  my $message = "$self->{bot}->{lang}->{WRITE_TEXT}\n";
  $message   .= "$self->{bot}->{lang}->{SEND_FILE}\n";
  $message   .= "$self->{bot}->{lang}->{CANCEL}";

  my @keyboard = ();
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
    BUTTON => "Msgs_reply",
    FN     => "send_reply",
    ARGS   => '{"message":{"text":"","id":"' . $attr->{argv}[2] .'"}}',
  });

  return 1;
}

#**********************************************************
=head2 send_reply()

=cut
#**********************************************************
sub send_reply {
  my $self = shift;
  my ($attr) = @_;

  my $Send_message = Telegram::buttons::Send_message->new(
    $self->{conf}, $self->{bot}, $self->{bot_db}, $self->{api}, $self->{user_config});

  if ($attr->{message}{text}) {
    my $text = encode_utf8($attr->{message}->{text});
    if ($text eq $self->{bot}{lang}{CANCEL_TEXT}) {
      $Send_message->cancel_msg();
      return 0;
    }
    elsif ($text eq $self->{bot}{lang}{SEND}) {
      $self->send_msg($attr);
      return 0;
    }
    $Send_message->add_text_to_msg($attr);
  }
  elsif ($attr->{message}{photo}) {
    my $photo = pop @{$attr->{message}{photo}};
    $Send_message->add_file_to_msg($attr, $photo->{file_id});
  }
  elsif ($attr->{message}{document}) {
    $Send_message->add_file_to_msg($attr, $attr->{message}->{document}->{file_id});
  }
  else {
    return 1;
  }

  $self->send_msgs_main_menu($attr->{step_info});
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

  if (!$text && !$msg_hash->{message}->{files}) {
    $self->{bot}->send_message({ text => $self->{bot}->{lang}->{NOT_SEND_MSGS} });
    return 0;
  }

  my $props = {
    REPLY_TEXT => $text,
    STATE      => 0
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
    PATH   => "/user/msgs/$msg_hash->{message}->{id}/reply",
    PARAMS => $props
  });

  $self->{bot_db}->del($self->{bot}->{chat_id});
  $self->{bot}->send_message({ text => $self->{bot}->{lang}->{SEND_MSGS} });

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
  my $button2 = {
    text => "$self->{bot}->{lang}->{SEND}",
  };
  my $button3 = {
    text => "$self->{bot}->{lang}->{CANCEL_TEXT}",
  };

  my $msg_hash = decode_json($info->{args});

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