=head1 NAME

  Notify admins and users

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail _bp);

our ($db,
  %lang,
  $html,
  $admin,
  %conf,
  $ui
);

my $Msgs = Msgs->new($db, $admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_notify_admins($attr)

  Arguments:
    $attr
      STATE
      MSGS

  Results:

=cut
#**********************************************************
sub msgs_notify_admins {
  my ($attr) = @_;

  my $admins_resposible_for_chapter = $Msgs->admins_list(
    {
      EMAIL_NOTIFY => 1,
      DISABLE      => 0,
      CHAPTER_ID   => $FORM{CHAPTER},
      COLS_NAME    => 1
    }
  );

  my $message_id = $attr->{MSG_ID} || $Msgs->{INSERT_ID} || '--';
  my $reply_id = $Msgs->{REPLY_ID} || '--';
  my $Msgs_ = $attr->{MSGS};
  my $subject = ($Msgs_->{SUBJECT} || $FORM{SUBJECT} || q{}) . ($FORM{REPLY_SUBJECT}
    ? ' / ' . $FORM{REPLY_SUBJECT}
    : '');

  my $site = '';
  if ( $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER} =~ m/(https?:\/\/[a-zA-Z0-9:\.\-]+)\//g ) {
    $site = $1 || '';
  }
  foreach my $line ( @{$admins_resposible_for_chapter} ) {

    my $RESPOSIBLE = ($FORM{RESPOSIBLE} && $FORM{RESPOSIBLE} eq $line->{aid}) ? $lang{YES} : $lang{NO};
    my $message = $html->tpl_show(
      _include('msgs_email_notify', 'Msgs'),
      {
        SITE       => $site,
        LOGIN      => $Msgs->{LOGIN} || $FORM{LOGIN} || $ui->{LOGIN} || $user->{LOGIN} || '',
        ADMIN      => ($FORM{INNER_MSG}) ? "$lang{ADMIN}:  $admin->{A_LOGIN}  (" . ($admin->{A_FIO} || q{}) . '}' : '',
        UID        => $Msgs->{UID} || $FORM{UID} || $LIST_PARAMS{UID} || '',
        DATE       => $DATE,
        TIME       => $TIME,
        ID         => $message_id . (($reply_id) ? " / $reply_id" : ''),
        RESPOSIBLE => $RESPOSIBLE,
        SUBJECT    => $subject,
        STATUS     => $attr->{STATE} || $FORM{STATE} || 0,
        MESSAGE    => $FORM{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{MESSAGE} || '',
        ATTACHMENT => ($FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{filename}) ? $FORM{FILE_UPLOAD}->{filename} : q{}
      },
      { OUTPUT2RETURN => 1 }
    );

    next if ( !$line->{email_notify} );

    sendmail("$conf{ADMIN_MAIL}",
      "$line->{email}",
      "$conf{WEB_TITLE}  -  $lang{NEW_MESSAGE} " . $subject,
      $message,
      $conf{MAIL_CHARSET} || 'utf-8', undef,
      { MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-Reply-ID: $reply_id" ] });
  }

  if ( $conf{TELEGRAM_TOKEN} ) {

    # Get resposible admin
    my $message_info = $Msgs->messages_list({
      MSG_ID     => $message_id,
      RESPOSIBLE => '_SHOW',
      COLS_NAME  => 1
    });

    return 0 if ( !$message_info || ref $message_info ne 'ARRAY' || !$message_info->[0] || !$message_info->[0]->{resposible} );

    my $resposible_aid = $message_info->[0]->{resposible};

    # If he has sent a message, he knows about it
    return 1 if ( !$resposible_aid || ($attr->{SENDER_AID} && $attr->{SENDER_AID} eq $resposible_aid) );

    #my $link = $site . "/admin/index.cgi?get_index=msgs_admin&full=1&chg=" . ($message_id || '');
    my $message = $FORM{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{MESSAGE} || '';

    require Msgs::Messaging;

    msgs_send_via_telegram($message_id, {
        AID         => $resposible_aid,
        SUBJECT     => $lang{YOU_HAVE_NEW_REPLY} . " <b>'$subject'</b>",
        SENDER_UID  => $attr->{SENDER_UID},
        MESSAGE     => $message,
        SENDER_TYPE => $Contacts::TYPES{TELEGRAM},
        PARSE_MODE  => 'HTML'
      });
  }

  return 1;
}

#**********************************************************
=head2 msgs_notify_user($attr)

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
sub msgs_notify_user {
  my ($attr) = @_;
  
  if ( !$attr->{UID} ){
    $html->message('warn', $lang{WARNING}, 'Will not notify user ( no UID )');
    return 1;
  };

  my $message_id = $attr->{MSG_ID} || '--';
  my $reply_id = $attr->{REPLY_ID} || '';
  my $Msgs_ = $attr->{MSGS};
  my $ATTACHMENTS = $attr->{ATTACHMENTS} || [];

  if ( $FORM{SURVEY_ID} ) {
    $Msgs->{SURVEY_TEXT} = msgs_survey_show(
      {
        SURVEY_ID        => $FORM{SURVEY_ID},
        MSG_ID           => $message_id,
        SHOW_SURVAY_TEXT => 1,
        MAIN_MSG         => 1,
      }
    );
  }

  my $message_tpl = 'msgs_email_notify';
  if ( $attr->{SEND_TYPE} && $attr->{SEND_TYPE} == 1 ) {
    $message_tpl = 'msgs_email_delivery';
  }

  my $site = '';
  if ( $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER} =~ m/(https?:\/\/[a-zA-Z0-9:\.\-]+)\//g ) {
    $site = $1 || '';
  }

  my $list = $users->list({
    LOGIN     => '_SHOW',
    FIO       => '_SHOW',
    EMAIL     => '_SHOW',
    UID       => $attr->{UID},
    COLS_NAME => 1
  });

  foreach my $line  ( @{$list} ) {
    my $message = $attr->{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{SURVEY_TEXT} || '';
    my $subject = ($Msgs_->{SUBJECT} || '') . (($FORM{REPLY_SUBJECT}) ? ' / ' . $FORM{REPLY_SUBJECT} : '');

    if ( $FORM{INNER_MSG} || $FORM{REPLY_INNER_MSG} ) {
      next;
    }

    my $mail_message = $html->tpl_show(
      _include($message_tpl, 'Msgs'),
      {
        SITE        => $html->button($lang{GO}, $site),
        DATE        => $DATE,
        TIME        => $TIME,
        LOGIN       => $line->{login},
        UID         => $line->{uid},
        ID          => $message_id,
        SUBJECT     => $subject,
        STATUS      => $attr->{STATE},
        MESSAGE     => $attr->{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{SURVEY_TEXT} || '',
        ATTACHMENT  => $FORM{FILE_UPLOAD}->{filename} || '',
        SUBJECT_URL => $site . "/index.cgi?get_index=msgs_user&ID=" . ($message_id || ''),
      },
      { OUTPUT2RETURN => 1 }
    );

    $Sender->send_message({
      UID         => $line->{uid},
      SUBJECT     => "$conf{WEB_TITLE} - $lang{NEW_MESSAGE} " . $subject,
      SENDER_TYPE => $attr->{SEND_TYPE} || 'Mail',
      # TO_ADDRESS  => $line->{email},
      MESSAGE     => $message,
      MAIL_TPL    => $mail_message,
      ATTACHMENTS => ($FORM{SEND_TYPE} && $#{ $ATTACHMENTS } > - 1) ? $ATTACHMENTS : undef,
      ACTIONS     => $site . "/index.cgi?get_index=msgs_user&ID=" . ($message_id || ''),
      MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-REPLY-ID: $reply_id" ]
    });

    if ( $conf{TELEGRAM_TOKEN} && $message_id ) {
      require Msgs::Messaging;
      msgs_send_via_telegram($message_id, {
          UID        => $line->{uid},
          MESSAGE    => $message,
          SUBJECT    => "_{YOU_HAVE_NEW_REPLY}_ '<b>$subject</b>'",
          PARSE_MODE => 'HTML'
        });
    }
  }

  return 1;
}

#**********************************************************
=head2 msgs_admin_quick_message()

=cut
#**********************************************************
sub msgs_admin_quick_message {
  unless ( $conf{PUSH_ENABLED} || $conf{WEBSOCKET_ENABLED} ) {
    $html->message('err', $lang{ERROR}, 'Need Websocket or Push to be configured');
    return 0;
  }

  if ( $FORM{MESSAGE} && $FORM{AID} && $FORM{SEND_TYPE} ) {

    foreach my $aid ( split(',\s?', $FORM{AID}) ) {

      # Send via sender
      my $sended = $Sender->send_message({
        AID         => $aid,
        TITLE       => $admin->{A_FIO} ? "$lang{FROM} : $admin->{A_FIO} " : '',
        MESSAGE     => $FORM{MESSAGE},
        SENDER_TYPE => $FORM{SEND_TYPE}
      });

      if ( $sended ) {
        $html->message('info', $lang{SENT} . ' : ' . $aid);
      }
    }

    return 1;
  }

  my $admins_online_list = $admin->online_list();
  # make list with checkboxes

  # Form HTML for checkbox panel
  my $checkboxes_html = '';
  foreach my $adm ( sort {$a->{aid} <=> $b->{aid}} @{$admins_online_list} ) {
    #    next if ($adm->{aid} == $admin->{AID});

    my $checkbox = $html->form_input('AID', $adm->{aid}, { TYPE => 'checkbox' });
    my $label = $html->element('label', $checkbox . $adm->{admin});
    my $checkbox_group = $html->element('div', $label, { class => 'checkbox col-md-6 text-left' });

    $checkboxes_html .= $checkbox_group;
  }

  $html->tpl_show(_include('msgs_admin_quick_message', 'Msgs'),
    {
      CHECKBOXES            => $checkboxes_html,
      PUSH_RADIO_VISIBLE    => $conf{PUSH_ENABLED},
      BROWSER_RADIO_VISIBLE => $conf{WEBSOCKET_ENABLED}
    }
  );

  return 1;
}


1;