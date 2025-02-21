package Viber::buttons::Msgs_reply;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use JSON;

require Viber::buttons::Send_message;

#**********************************************************
=head2 new($conf, $bot_api, $bot_db)

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

  return 0 unless ($attr->{argv}[0]);

  my $message = "$self->{bot}->{lang}->{WRITE_TEXT}\n";
  $message   .= "$self->{bot}->{lang}->{SEND_FILE}\n";
  $message   .= "$self->{bot}->{lang}->{CANCEL}";

  my @keyboard = ();
  my $button = $self->_cancel_button();
  push (@keyboard, $button);

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  $self->{bot_db}->add({
    SENDER_ID => $self->{bot}->{receiver},
    FN        => "fn:Msgs_reply&send_reply",
    ARGS      => '{"message":{"text":"","id":"' . $attr->{argv}[0] . '"}}',
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

  my $Send_message = Viber::buttons::Send_message->new(
    $self->{conf},
    $self->{bot},
    $self->{bot_db},
    $self->{api},
    $self->{user_config}
  );

  if ($attr->{message}->{type} eq "text") {
    $Send_message->add_text_to_msg($attr);
  }
  elsif ($attr->{message}->{type} eq "picture") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $Send_message->add_file_to_msg($attr, $file_id);
  }
  elsif ($attr->{message}->{type} eq "file") {
    my $file_id = $attr->{message}->{media}.'|'.$attr->{message}->{file_name}.'|'.$attr->{message}->{size};
    $Send_message->add_file_to_msg($attr, $file_id);
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
    $self->{bot_db}->del($self->{bot}->{receiver});
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
      my ($file_name, $file_extension) = $file_path =~ m/(.*)\.(.*)/;

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

  $self->{bot_db}->del($self->{bot}->{receiver});
  $self->{bot}->send_message({ text => $self->{bot}->{lang}->{SEND_MSGS} });

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

  my $send_msg = {
    ActionType => 'reply',
    ActionBody => 'fn:Msgs_reply&send_msg',
    Text       => $self->{bot}->{lang}->{SEND},
    TextSize   => 'regular'
  };

  my $cancel_button = $self->_cancel_button();

  my $msg_hash = decode_json($info->{args});

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
=head2 _cancel_button()

=cut
#**********************************************************
sub _cancel_button {
  my $self = shift;

  my $cancel_button = {
    ActionType => 'reply',
    ActionBody => 'fn:Msgs_reply&cancel_msg',
    Text       => $self->{bot}->{lang}->{CANCEL_TEXT},
    BgColor    => '#FF0000',
    TextSize   => 'regular'
  };

  return $cancel_button;
}

1;