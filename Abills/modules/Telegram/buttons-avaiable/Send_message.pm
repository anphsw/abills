package Send_message;

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
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  return "Создать сообщение";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $message = "Напишите текст вашего сообщения.\n";
  $message   .= "Также вы можете отправить файлы и изображения, они будут прикреплены к сообщению.\n";
  $message   .= "Нажмите <b>Отправить</b> когда сообщение готово или <b>Отменить</b> если вы передумали.";
  
  my @keyboard = ();
  my $button1 = {
    text => "Тема сообщения",
  };
  my $button2 = {
    text => "Отменить",
  };
  push (@keyboard, [$button1], [$button2]);

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
    BUTTON => "Send_message",
    FN     => "add_to_msg",
    ARGS   => '{"message":{"text":""}}',
  });

  return 1;
}

#**********************************************************
=head2 simple_msgs()

=cut
#**********************************************************
sub simple_msgs {
  my $self = shift;
  my ($attr) = @_;

  my $subject = "Telegram Bot";
  my $chapter = 1;

  use Msgs;
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});

  $Msgs->message_add({
    USER_SEND => 1,
    UID       => $attr->{uid},
    MESSAGE   => $attr->{text},
    SUBJECT   => $subject,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
  });

  $self->{bot}->send_message({
    text => "Ваше сообщение отправлено в службу поддержки.",
  });

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
    if ($text eq "Отменить") {
      $self->cancel_msg();
      return 0;
    }
    elsif ($text eq "Отправить") {
      $self->send_msg($attr);
      return 0;
    }
    elsif ($text eq "Тема сообщения") {
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

  $self->send_msgs_main_menu();
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

  $self->{bot}->send_message({
    text => "К сообщению добавлен текст.",
  });
  return 1;
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
    if ($text eq "Отменить") {
      $self->cancel_msg();
      return 0;
    }
    elsif ($text eq "Назад") {

    }
    else {
      my $title = $attr->{message}->{text};
      my $msg_hash = decode_json($info->{args});
      $msg_hash->{message}->{title} = $title;
      $info->{ARGS} = encode_json($msg_hash);
      $self->{bot}->send_message({
        text => "Тема сообщения изменена.",
      });
    }
  }
  else {
    return 1;
  }

  $info->{FN} = "add_to_msg";
  $self->{bot_db}->change($info);

  $self->send_msgs_main_menu();
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
  
  my $message = "Напишите тему сообщения\n";
  $message   .= "Нажмите <b>Назад</b> чтобы вернуться в предыдущее меню\n";
  $message   .= "Нажмите <b>Отменить</b> если вы хотите отменить создание сообщения\n";
  
  my @keyboard = ();
  my $button1 = {
    text => "Назад",
  };
  my $button2 = {
    text => "Отменить",
  };
  push (@keyboard, [$button1], [$button2]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => { 
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
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

  $self->{bot}->send_message({
    text => "К сообщению добавлен файл.",
  });
  return 1;
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
=head2 send_msg()

=cut
#**********************************************************
sub send_msg {
  my $self = shift;
  my ($attr) = @_;
  my $info = $attr->{step_info};
  my $msg_hash = eval { decode_json($info->{args}) };
  if ($@) {
  # JSON in 'args' column is invalid, drop it.
    $self->{bot}->send_message({
      text => "Что-то пошло не так. Сообщение не отправлено.",
    });
    $self->{bot_db}->del( $self->{bot}->{uid} );
    return 1;
  }
  
  my $title = "Telegram Bot";
  my $chapter = 1;

  use Msgs;
  use Msgs::Misc::Attachments;
  my $Msgs = Msgs->new($self->{db}, $self->{admin}, $self->{conf});
  my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});

  $Msgs->message_add({
    USER_SEND => 1,
    UID       => $self->{bot}->{uid},
    MESSAGE   => $msg_hash->{message}->{text},
    SUBJECT   => $msg_hash->{message}->{title} || $title,
    CHAPTER   => $chapter,
    PRIORITY  => 2,
  });

  if (!$Msgs->{errno} && $msg_hash->{message}->{files}) {
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
        MSG_ID       => $Msgs->{MSG_ID},
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
  return 1;
}

#**********************************************************
=head2 send_msgs_main_menu()

=cut
#**********************************************************
sub send_msgs_main_menu {
  my $self = shift;

  my @keyboard = ();
  my $button1 = {
    text => "Тема сообщения",
  };
  my $button2 = {
    text => "Отправить",
  };
  my $button3 = {
    text => "Отменить",
  };
  push (@keyboard, [$button1], [$button2], [$button3]);

  my $message   .= "Нажмите <b>Отправить</b> когда сообщение будет готово или <b>Отменить</b> если вы передумали.\n";

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => { 
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });
  
  return 1;
}

1;