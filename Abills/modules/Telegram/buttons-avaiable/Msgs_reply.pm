package Msgs_reply;

use strict;
use warnings FATAL => 'all';
use Encode qw/encode_utf8/;
use JSON;

#**********************************************************
=head2 new($db, $admin, $conf, $bot_api, $bot_db)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot, $bot_db) = @_;
  
  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $conf,
    bot    => $bot,
    bot_db => $bot_db
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 reply()

=cut
#**********************************************************
sub reply {
  my $self = shift;
  my ($attr) = @_;

  return 0 unless ($attr->{argv}[2]);

  my $message = "Напишите текст вашего ответа.\n";
  $message   .= "Также вы можете отправить файлы и изображения, они будут прикреплены к ответу.\n";
  $message   .= "Нажмите <b>Отменить</b> если вы передумали.";
  
  my @keyboard = ();
  my $button = {
    text => "Отменить",
  };
  push (@keyboard, [$button]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => { 
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });

  $self->{bot_db}->add({
    UID    => $self->{bot}->{uid},
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

  if ($attr->{message}->{photo}) {
    my $photo = pop @{$attr->{message}->{photo}};
    $self->add_file_to_msg($attr, $photo->{file_id});
    return 1;
  }
  elsif ($attr->{message}->{document}) {
    $self->add_file_to_msg($attr, $attr->{message}->{document}->{file_id});
    return 1;
  }

  if ($attr->{message}->{text}) {
    my $text = encode_utf8($attr->{message}->{text});
    if ($text eq "Отменить") {
      $self->cancel_msg();
      return 0;
    }
  }
  else {
    $self->cancel_msg();
    return 0;
  }

  my $info = $attr->{step_info};
  my $msg_hash = eval { decode_json($info->{args}) };

  use Msgs;
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});
  $Msgs->message_info($msg_hash->{message}->{id});

  if ($Msgs->{errno}) {
    $self->{bot}->send_message({
      text => "Ошибка. Вы не можете ответить на это сообщение.\nВозможно оно уже удалено.",
    });
    $self->cancel_msg();
    return 0;
  }

  if ($Msgs->{STATE} == 1 || $Msgs->{STATE} == 2) {
    $self->{bot}->send_message({
      text => "Вы не можете ответить на уже закрытое сообщение.",
    });
    $self->cancel_msg();
    return 0;
  }

  $Msgs->message_reply_add({
    ID         => $msg_hash->{message}->{id},
    UID        => $self->{bot}->{uid},
    REPLY_TEXT => $attr->{message}->{text},
  });

  my $reply_id = $Msgs->{REPLY_ID};

  $Msgs->message_change({
    ID         => $msg_hash->{message}->{id},
    UID        => $self->{bot}->{uid},
    STATE      => 0,
  });
  
  if (!$Msgs->{errno} && $msg_hash->{message}->{files}) {
    use Msgs::Misc::Attachments;
    my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});
    foreach my $file_id ( @{$msg_hash->{message}->{files}} ) {
      my ($file_path, $file_size, $file_content) = $self->{bot}->get_file($file_id);
      my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;
      next unless ($file_content && $file_size && $file_name && $file_extension);
      my $file_content_type = "application/octet-stream";
      if ( $file_extension eq 'png'
        || $file_extension eq 'jpg'
        || $file_extension eq 'gif'
        || $file_extension eq 'jpeg'
        || $file_extension eq 'tiff'
        ) {
        $file_content_type = "image/$file_extension";
      }
      elsif ( $file_extension eq "zip" ) {
        $file_content_type = "application/x-zip-compressed";
      }

      $Attachments->attachment_add({
        MSG_ID       => $msg_hash->{message}->{id},
        REPLY_ID     => $reply_id,
        MESSAGE_TYPE => 1,
        UID          => $self->{bot}->{uid},
        FILENAME     => "$file_name.$file_extension",
        CONTENT_TYPE => $file_content_type,
        FILESIZE     => $file_size,
        CONTENT      => $file_content,
      });
    }
  }
  $self->{bot_db}->del($self->{bot}->{uid});
  $self->{bot}->send_message({
    text => "Сообщение отправлено.",
  });
  return 0;
}

#**********************************************************
=head2 cancel_msg()

=cut
#**********************************************************
sub cancel_msg {
  my $self = shift;
  $self->{bot_db}->del($self->{bot}->{uid});
  $self->{bot}->send_message({
    text => "Отправка сообщения отменена.",
  });
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

  $self->{bot}->send_message({
    text => "К сообщению добавлен файл.",
  });
  return 1;
}

1;