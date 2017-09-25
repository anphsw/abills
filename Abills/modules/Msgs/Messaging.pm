use strict;
use warnings FATAL => 'all';

=head1 NAME

  Msgs::Messaging

=head1 DESCRIBE

  Separated message reply and notify logic

=head1 SYNOPSIS
  
  require Msgs::Messaging;
  
  msgs_send_via_telegram($message_id, {
    UID         => $attr->{UID},
    SUBJECT     => $lang{YOU_HAVE_NEW_REPLY} . " '<b>$subject</b>'",
    MESSAGE     => $notification_body,
    PARSE_MODE  => 'HTML'
  });
  
=cut

use Abills::Base qw(urlencode convert int2byte);
use Abills::SQL;
use Admins;
use POSIX qw/strftime/;
#use utf8;
use Encode;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $base_dir
);

use Abills::Base qw/_bp/;
_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });

if ( !scalar keys %conf ) {
  require 'libexec/config.pl';
}
if ( !$db ) {
  $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
    { CHARSET => $conf{dbcharset} });
}
if ( !$admin ) {
  $admin = Admins->new($db, \%conf);
  $admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
}
if ( !scalar keys %lang ) {
  our $html;
  my $language = ($html) ? $html->{language} : $conf{default_language};
  
  my $main_lang = "$base_dir/language/$language.pl";
  my $msgs_lang = "$base_dir/Abills/modules/Msgs/lng_$language.pl";
  
  (-f $main_lang) and require $main_lang;
  (-f $msgs_lang) and require $msgs_lang;
}

use Msgs;
use Abills::Sender::Core;
use Users;

$conf{MSGS_MESSAGING_DEBUG} //= 0;
my $debug = $conf{MSGS_MESSAGING_DEBUG};

our Msgs $Msgs;
our Abills::Sender::Core $Sender;
our Users $users;

$Msgs //= Msgs->new($db, $admin, \%conf);
$Sender //= Abills::Sender::Core->new($db, $admin, \%conf);
$users //= Users->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_user_reply()

  Arguments:
    $message_id - integer, main message id, where reply goes
    $attr       - hash_ref
      UID        - reply sender uid
      REPLY_TEXT - text of reply
      STATE      - if have to change main message

=cut
#**********************************************************
sub msgs_user_reply {
  my ($message_id, $attr) = @_;
  
  $attr->{STATE} //= 0;
  
  $Msgs->message_reply_add({
    ID  => $message_id,
    %{ $attr // {} },
    AID => 0,
    IP  => $admin->{SESSION_IP},
    UID => $attr->{UID}
  });
  return 0 if ( $Msgs->{errno} );
  my $reply_id = $Msgs->{INSERT_ID};
  
  my $message_info_list = $Msgs->messages_list({
    MSG_ID     => $message_id,
    RESPOSIBLE => '_SHOW',,
    UID        => '_SHOW',
    COLS_NAME  => 1
  });
  
  return 0 if ( $Msgs->{errno} || !$Msgs->{TOTAL} );
  my $message_info = $message_info_list->[0];
  
  # Change status to unreaded
  my %params = ();
  my $msg_state = $attr->{STATE} || 0;
  
  my $DATE = strftime "%Y-%m-%d", localtime(time);
  my $TIME = strftime "%H:%M:%S", localtime(time);
  
  $params{CLOSED_DATE} = $DATE if ( $attr->{STATE} > 0 );
  $params{DONE_DATE} = $DATE if ( $attr->{STATE} > 1 );
  $params{ADMIN_READ} = "0000-00-00 00:00:00" if ( !$attr->{INNER} );
  
  $Msgs->message_change({
    UID   => $attr->{UID},
    ID    => $message_id,
    STATE => $msg_state,
    #    RATING         => $attr->{rating} ? $attr->{rating} : 0,
    #    RATING_COMMENT => $attr->{rating_comment} ? $attr->{rating_comment} : '',
    %params
  });
  
  return 0 if ( $Msgs->{errno} );
  
  msgs_messaging_notify_admins({
    %{$attr},
    MSG_ID        => $message_id,
    UID           => $attr->{UID},
    STATE         => $attr->{STATE},
    REPLY_TEXT    => $attr->{REPLY_TEXT},
    SENDER_UID    => $attr->{UID},
    MESSAGE_INFO  => $message_info,
    MESSAGE_STATE => $msg_state,
  });
  
  return $reply_id;
}


#**********************************************************
=head2 msgs_admin_reply()

=cut
#**********************************************************
sub msgs_admin_reply {
  my ($message_id, $attr) = @_;
  
  $attr->{STATE} //= 6;
  $Msgs->message_reply_add(
    {
      ID  => $message_id,
      %{$attr},
      AID => $attr->{AID} || $admin->{AID},
      IP  => $admin->{SESSION_IP},
    }
  );
  
  if ( $debug > 2 ) {
    _bp('adding admin reply error', $Msgs->{errno});
  }
  
  return 0 if ( $Msgs->{errno} );
  my $reply_id = $Msgs->{INSERT_ID};
  
  my $message_info_list = $Msgs->messages_list({
    MSG_ID     => $message_id,
    RESPOSIBLE => '_SHOW',
    UID        => '_SHOW',
    COLS_NAME  => 1
  });
  
  return 0 if ( $Msgs->{errno} || !$Msgs->{TOTAL} );
  my $message_info = $message_info_list->[0];
  
  my %params = ();
  
  my $DATE = strftime "%Y-%m-%d", localtime(time);
  my $TIME = strftime "%H:%M:%S", localtime(time);
  
  my $msg_state = $attr->{STATE} || 0;
  #$attr->{STATE}         = $msg_state;
  $params{CHAPTER} = $attr->{CHAPTER_ID} if ( $attr->{CHAPTER_ID} );
  $params{STATE} = ($msg_state == 0 && !$attr->{MAIN_INNER_MESSAGE} && !$attr->{REPLY_INNER_MSG}) ? 6 : $msg_state;
  $params{CLOSED_DATE} = "$DATE  $TIME" if ( $msg_state > 0 );
  $params{DONE_DATE} = $DATE if ( $msg_state > 1 );
  
  #  if ( !$attr->{RESPOSIBLE} ) {
  #    $Msgs->message_change({
  #      RESPOSIBLE => $admin->{AID},
  #      ID         => $attr->{ID},
  #    });
  #  }
  
  $Msgs->message_change({
    UID        => $attr->{UID},
    ID         => $message_id,
    USER_READ  => "0000-00-00 00:00:00",
    ADMIN_READ => "$DATE $TIME",
    %params
  });
  
  if ( $Msgs->{errno} ) {
    return 0;
  }
  
  my $sent_notification_to_admin =
    msgs_messaging_notify_admins({
      REPLY_INNER_MSG => $attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG},
      MSG_ID          => $message_id,
      UID             => $attr->{UID},
      REPLY_ID        => $reply_id,
      REPLY_TEXT      => $attr->{REPLY_TEXT},
      SENDER_AID      => $attr->{AID} || $admin->{AID},
      MESSAGE_INFO    => $message_info,
      MESSAGE_STATE   => $msg_state,
    });
  
  if ( $debug > 2 ) {
    _bp('admin notification sent', $sent_notification_to_admin);
  }
  
  if ( $attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG} ) {
    return $reply_id;
  }
  
  my $sent_notification_to_user =
    msgs_messaging_notify_user({
      UID             => $attr->{UID},
      REPLY_ID        => $reply_id,
      REPLY_TEXT      => $attr->{REPLY_TEXT},
      REPLY_INNER_MSG => $attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG},
      MSG_ID          => $message_id,
      SENDER_AID      => $admin->{AID},
      MESSAGE_INFO    => $message_info
    });
  
  if ( $debug > 2 ) {
    _bp('user notification sent', $sent_notification_to_user);
  }
  
  return $reply_id;
}


#**********************************************************
=head2 msgs_messaging_notify_user($attr)

  Arguments:
    $attr
      MSG_ID
      REPLY_ID
      MSGS
      MESSAGE
      SEND_TYPE
         1 - Msgs delivery tpl
      UID

  Results:

=cut
#**********************************************************
sub msgs_messaging_notify_user {
  my ($attr) = @_;
  
  if ( $attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG} ) {
    return;
  }
  
  my $message_id = $attr->{MSG_ID} or return 1;
  #  my $reply_id = $attr->{REPLY_ID} || '';
  
  my $message_info = $attr->{MESSAGE_INFO};
  return 0 if ( !$message_info || ref $message_info ne 'HASH' || !$message_info->{uid} );
  my $uid = $attr->{UID} || $message_info->{uid} || return 0;
  
  my $subject = $attr->{SUBJECT} || $message_info->{subject};
  
  my $message = $attr->{MESSAGE} || $attr->{REPLY_TEXT} || $Msgs->{SURVEY_TEXT} || '';
  
  if ( $conf{TELEGRAM_TOKEN} ) {
    return msgs_send_via_telegram($message_id, {
        UID        => $uid,
        SUBJECT    => "_{YOU_HAVE_NEW_REPLY}_ '<b>$subject</b>'",
        MESSAGE    => $message
      });
  }
  
  return 1;
}

#**********************************************************
=head2 msgs_messaging_notify_admins($attr)

  Arguments:
    $attr
      STATE
      MSGS

  Results:

=cut
#**********************************************************
sub msgs_messaging_notify_admins {
  my ($attr) = @_;
  
  my $message_id = $attr->{MSG_ID} or return 1;
  
  #  my $reply_id = $attr->{REPLY_ID} || '--';
  
  # Get resposible admin
  my $message_info = $attr->{MESSAGE_INFO};
  return 0 if ( !$message_info || ref $message_info ne 'HASH' || !$message_info->{resposible} );
  
  my $resposible_aid = $message_info->{resposible};
  my $subject = $attr->{SUBJECT} || $message_info->{subject};
  
  my $status_name = '';
  if ( defined $attr->{MESSAGE_STATE} ) {
    $Msgs->status_list({
      ID          => '_SHOW',
      NAME        => '_SHOW',
      LIST2HASH   => 'id,name',
      STATUS_ONLY => 1
    });
    
    if ( !$Msgs->{errno} ) {
      my $status_hash = $Msgs->{list_hash};
      $status_name = $status_hash->{$attr->{MESSAGE_STATE}} || '';
    }
  }
  
  if ( $conf{TELEGRAM_TOKEN} ) {
    
    # If he has sent a message, he knows about it
    return 1 if ( !$resposible_aid || ($attr->{SENDER_AID} && $attr->{SENDER_AID} eq $resposible_aid) );
    
    my $message = $attr->{MESSAGE} || $attr->{REPLY_TEXT} || '';
    
    if ( $debug > 4 ) {
      _bp('TELEGRAM MESSAGE WAS', $message);
    }
    my $notification_subject = "_{YOU_HAVE_NEW_REPLY}_ '<b>$subject</b>'";
    
    if ( $status_name ) {
      if ( $status_name =~ /\$lang\{([a-zA-Z\_]+)\}/ ) {
        $status_name = "_{$1}_";
      }
      $notification_subject .= "\n ( _{STATE}_ : $status_name)";
    }
    
    return msgs_send_via_telegram($message_id, {
        AID          => $resposible_aid,
        SENDER_UID => $attr->{UID},
        SUBJECT      => $notification_subject,
        MESSAGE      => $message,
      });
    
  }
  
  return 1;
}

#**********************************************************
=head2 msgs_send_via_telegram() - Sends message with reply ability

=cut
#**********************************************************
sub msgs_send_via_telegram {
  my ($message_id, $sender_attr) = @_;
  
  return if ( !$message_id || $message_id eq '--' );
  
  # 6 is Telegram contact_type
  $sender_attr->{SENDER_TYPE} = 6;
  
  my $translate = sub {
    my $text = $_[0];
    while ( $text && $text =~ /\_\{(\w+)\}\_/ ) {
      my $to_translate = $1;
      $text =~ s/\_\{$to_translate\}\_/$lang{$to_translate}/sg;
    }
    Encode::_utf8_off($text);
    $text;
  };
  if ( $sender_attr->{MESSAGE} ) {
    $sender_attr->{MESSAGE} = $translate->($sender_attr->{MESSAGE});
  }
  if ( $sender_attr->{SUBJECT} ) {
    $sender_attr->{SUBJECT} = $translate->($sender_attr->{SUBJECT});
  }
  
  my @keyboard = ();
  if ( $conf{TELEGRAM_MSGS_BOT_ENABLE} ) {
    push(@keyboard, { text => $translate->('_{MSGS_REPLY}_'), 'callback_data' => 'MSGS:REPLY:' . $message_id });
  }
  
  my $referer = ($conf{BILLING_URL} || $ENV{HTTP_REFERER} || '');
  if ( $referer =~ /(https?:\/\/[a-zA-Z0-9:\.\-]+)\/?/g ) {
    my $site_url = $1;
    
    if ( $site_url ) {
      my $link = $site_url;
      
      if ( $sender_attr->{UID} ) {
        $link .= "/index.cgi?get_index=msgs_user&ID=$message_id#last_msg";
      }
      elsif ( $sender_attr->{AID} ) {
        my $receiver_uid = $sender_attr->{SENDER_UID} ? '&UID=' . $sender_attr->{SENDER_UID} : '';
        $link .= "/admin/index.cgi?get_index=msgs_admin&full=1$receiver_uid&chg=$message_id#last_msg";
      }
      else {
        if ( $conf{MSGS_MESSAGING_DEBUG} > 1 ) {
          _bp('MSGS_MESSAGING_DEBUG', 'EMPTY MESSAGE RECEIVER', { HEADER => 1 });
        }
        return 0;
      }
      
      push(@keyboard, { text => $translate->('_{MSGS_OPEN}_'), 'url' => $link });
    }
    
  }
  
  #  push(@keyboard, { text => $translate->('_{GO}_'), 'url' => 'https://192.168.1.1/' });
  
  my $message_send_params = {
    %{$sender_attr},
    DEBUG         => $debug > 3,
    SENDER_TYPE   => $Contacts::TYPES{TELEGRAM},
    STRICT_TYPE   => 1,
    PARSE_MODE   => 'HTML',
    TELEGRAM_ATTR => {
      reply_markup => {
        inline_keyboard => [
          \@keyboard
        ]
      },
      force_reply  => 1
    },
  };
  
  if ( $conf{MSGS_MESSAGING_DEBUG} > 5 ) {
    require Data::Dumper;
    my $dumped = Data::Dumper::Dumper($message_send_params);
    my $debug_file = $conf{MSGS_MESSAGING_DEBUG_FILE} || '/tmp/telegram_messaging.log';
    `echo "$dumped" >> $debug_file`;
  }
  
  return $Sender->send_message($message_send_params);
}

1;