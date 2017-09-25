=head NAME

 User Portal

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(urlencode convert int2byte);


our(
  $db,
  %conf,
  $html,
  %lang,
  $admin,
  @priority,
  @priority_colors,
);

my $Msgs = Msgs->new($db, $admin, \%conf);
#**********************************************************
=head2 msgs_user() - Client web interface

=cut
#**********************************************************
sub msgs_user {

  #If User have new unread msg, open it
  #(Return msg object with LAST_ID)
  if($user->{UID} && !($FORM{ID} || $Msgs->{LAST_ID} || $Msgs->{INSERT_ID} || $Msgs->{ID}) ){

    my %SHOW_PARAMS = (
      UID        => $user->{UID},
      USER_READ  => '0000-00-00  00:00:00',
      ADMIN_READ => '>0000-00-00 00:00:00',
      INNER_MSG  => 0,
    );

    $Msgs->messages_new({%SHOW_PARAMS});
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  $Msgs->{STATE_SEL} = $html->form_select(
    'STATE',
    {
      SELECTED   => $FORM{STATE} || 0,
      #SEL_HASH   => { %{$msgs_status}{(0,1,2)} },
      SEL_HASH   => {
        0 => $msgs_status->{0},
        1 => $msgs_status->{1},
        2 => $msgs_status->{2}
    },
    NO_ID      => 1,
    USE_COLORS => 1,
    }
  );

  $Msgs->{PRIORITY_SEL} = msgs_sel_priority();

  if ($FORM{send}) {
    $Msgs->message_add(
      {
        UID       => $user->{UID},
        STATE     => ($FORM{STATE}) ? $FORM{STATE} : 0,
        USER_READ => "$DATE  $TIME",
        IP        => $ENV{'REMOTE_ADDR'},
        %FORM,
        USER_SEND => 1,
      }
    );

    if (!$Msgs->{errno}) {

      #Add attachment
      if ($FORM{FILE_UPLOAD}{filename}) {
        $Msgs->attachment_add(
          {
            MSG_ID       => $Msgs->{INSERT_ID},
            CONTENT      => $FORM{FILE_UPLOAD}{Contents},
            FILESIZE     => $FORM{FILE_UPLOAD}{Size},
            FILENAME     => $FORM{FILE_UPLOAD}{filename},
            CONTENT_TYPE => $FORM{FILE_UPLOAD}{'Content-Type'},
            UID          => $user->{UID}
          }
        );
      }
      $html->message( 'info', $lang{INFO}, "$lang{MESSAGE} # $Msgs->{MSG_ID}.  $lang{MSG_SENDED} " );

      msgs_notify_admins();

      # Sent to client
      if ($FORM{UID}){
        $html->redirect("?index=$index&UID=" . ($FORM{UID} || q{}) . "&chg=" . ($FORM{ID} || q{}) . '#last_msg',
          {
            MESSAGE_HTML => $html->message( 'info', $lang{INFO}, "$lang{MESSAGE} $Msgs->{MSG_ID} $lang{MSG_SENDED} ", {OUTPUT2RETURN => 1} ),
            WAIT         => '0'
          }
        );
      }
      else {
        # Instant redirect
        my $header_message = urlencode("$lang{MESSAGE} "
          . ($Msgs->{MSG_ID} ? " #$Msgs->{MSG_ID} " : '')
          . $lang{MSG_SENDED}
        );
        $html->redirect("?index=$index&sid=" . ($sid || $user->{SID} || $user->{sid})
        . "&MESSAGE=$header_message&chg=" . ($FORM{ID} || q{}) . '#last_msg');
        exit 0;
      }
    }

    return 1;
  }
  elsif ($FORM{ATTACHMENT}) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ($FORM{ID} || $Msgs->{LAST_ID}) {
    if ($FORM{reply}) {
      my %params = ();
      $params{CLOSED_DATE} = $DATE if ($FORM{STATE} > 0);
      $params{DONE_DATE}   = $DATE if ($FORM{STATE} > 1);
      $params{ADMIN_READ}  = "0000-00-00  00:00:00" if (! $FORM{INNER});

      $Msgs->message_change({
        UID            => $LIST_PARAMS{UID},
        ID             => $FORM{ID},
        STATE          => $FORM{STATE},
        RATING         => $FORM{rating}         ? $FORM{rating}         : 0,
        RATING_COMMENT => $FORM{rating_comment} ? $FORM{rating_comment} : '',
        %params
      });

      if ($FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID}) {
        $Msgs->message_reply_add({
          %FORM,
          AID => 0,
          IP  => $admin->{SESSION_IP},
          UID => $LIST_PARAMS{UID}
        });

        if (!$Msgs->{errno}) {
          #Add attachment
          if ($FORM{FILE_UPLOAD}{filename}) {
            $Msgs->attachment_add({
              MSG_ID       => $Msgs->{INSERT_ID},
              CONTENT      => $FORM{FILE_UPLOAD}{Contents},
              FILESIZE     => $FORM{FILE_UPLOAD}{Size},
              FILENAME     => $FORM{FILE_UPLOAD}{filename},
              CONTENT_TYPE => $FORM{FILE_UPLOAD}{'Content-Type'},
              UID          => $user->{UID},
              MESSAGE_TYPE => 1
            });
          }
        }
        $html->message( 'info', $lang{INFO}, "$lang{REPLY}" );

        msgs_notify_admins({
          MSG_ID     => $FORM{ID},
          SENDER_UID => $user->{UID}
        });

        # Instant redirect
        my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($Msgs->{INSERT_ID} ? " : $Msgs->{INSERT_ID}" : ''));
        $html->redirect("?index=$index&sid=".( $sid || $user->{SID} || $user->{sid} )
          ."&MESSAGE=$header_message&chg=" . ($FORM{ID} || q{}) . '#last_msg');
        exit 0;
      }
      return 1;
    }
    elsif ($FORM{change}) {
      $Msgs->message_change({
        UID        => $LIST_PARAMS{UID},
        ID         => $FORM{ID},
        ADMIN_READ => "0000-00-00  00:00:00",
        STATE      => $FORM{STATE} || 0,
      });

      if ($FORM{SURVEY_ID}) {
        msgs_survey_show({ SURVEY_ID => $FORM{SURVEY_ID} });
      }
    }

    $FORM{ID} = $Msgs->{LAST_ID} if ($Msgs->{LAST_ID});
    $Msgs->message_info($FORM{ID}, { UID => $LIST_PARAMS{UID} });
    _error_show($Msgs);
    if ($Msgs->{errno}) {
      return 1;
    }

    $Msgs->{ACTION} = 'reply';
    $Msgs->{LNG_ACTION}    = $lang{REPLY};
    $Msgs->{STATE_NAME}    = $html->color_mark($msgs_status->{$Msgs->{STATE}}) if(defined($Msgs->{STATE}) && $msgs_status->{$Msgs->{STATE}});
    $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);

    if ($Msgs->{PRIORITY} == 4) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-danger';
    }
    elsif ($Msgs->{PRIORITY} == 3) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-warning';
    }
    elsif ($Msgs->{PRIORITY} >= 1) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-info';
    }
    else {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-primary';
    }

    my @REPLIES = ();
    if ($Msgs->{ID}) {
      my $main_msgs_id = $Msgs->{ID};
      my $list = $Msgs->messages_reply_list({
        MSG_ID       => $main_msgs_id,
        CONTENT_SIZE => '_SHOW',
        INNER_MSG    => 0,
        CONTENT_TYPE => '_SHOW',
        COLS_NAME    => 1
      });

      my $total_reply = $Msgs->{TOTAL};
      my $reply = '';

      if ($Msgs->{SURVEY_ID}) {
        push @REPLIES, msgs_survey_show({
            SURVEY_ID => $Msgs->{SURVEY_ID}, MSG_ID => $main_msgs_id
          });
      }

      foreach my $line (@$list) {
        $FORM{REPLY_ID} = $line->{id};
        if ($line->{survey_id}) {
          push @REPLIES, msgs_survey_show({
              SURVEY_ID => $line->{survey_id},
              REPLY_ID  => $line->{id}
            });
        }
        else {
          if ($FORM{QUOTING} && $FORM{QUOTING} == $line->{id}) {
            $reply = $line->{text} if (! $FORM{json});
          }

          push @REPLIES, $html->tpl_show(
              _include('msgs_reply_show', 'Msgs'),
              {
                LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
                REPLY_ID   => $line->{id},
                DATE       => $line->{datetime},
                CAPTION    => convert($line->{caption}, { text2html => 1, json => $FORM{json} }),
                PERSON     => $line->{creator_id},
                MESSAGE    => msgs_text_quoting($line->{text}). (($line->{filename} && $line->{content_type} && $line->{content_type} =~ /ima/ ) ? $html->img("$SELF_URL?qindex=$index&ATTACHMENT=$line->{attachment_id}") : ''),
                COLOR      => (($line->{aid} > 0) ? 'box-success' : 'box-theme'),
                QUOTING    =>
                $html->button( $lang{QUOTING}, "index=$index&QUOTING=$line->{id}&ID=$FORM{ID}&sid=$sid", { BUTTON => 1 } )
                ,
                ATTACHMENT => ($line->{attachment_id}) ? "$lang{ATTACHMENT}:  " . $html->button($line->{filename} || 'No name', "qindex=$index&ATTACHMENT=$line->{attachment_id}",
                    { TARGET => '_new' } ) . "  ($lang{SIZE}:   " . int2byte( $line->{content_size} ) . ')' : '',
              },
              { OUTPUT2RETURN => 1 }
            );

          if ($reply ne '') {
            $reply =~ s/^/>  /g;
            $reply =~ s/\n/> /g;
          }
        }
      }

      if (!$Msgs->{ACTIVE_SURWEY} && ($Msgs->{STATE} < 1 || $Msgs->{STATE} == 6)) {
        push @REPLIES, $html->tpl_show(_include('msgs_client_reply', 'Msgs'), { %$Msgs, REPLY_TEXT => $reply }, { OUTPUT2RETURN => 1 });
      }
      else {
        #$html->message('info',  $lang{INFO},  "$msg_status[$Msgs->{STATE}] $lang{DATE}: $Msgs->{CLOSED_DATE}");
      }

      $Msgs->{REPLY} = join(($FORM{json}) ? ',' : '', @REPLIES);
      $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, SHOW_URL => 1, json => $FORM{json} });
      $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });
      if ($Msgs->{FILENAME}) {
        $Msgs->{MESSAGE} .= ($Msgs->{FILENAME} && $Msgs->{CONTENT_TYPE} =~ /ima/ ) ? $html->img("$SELF_URL?qindex=$index&ATTACHMENT=$Msgs->{ATTACHMENT_ID}") : '';

        $Msgs->{ATTACHMENT} = "$lang{ATTACHMENT}: " . $html->button( "$Msgs->{FILENAME}",
          "qindex=$index&sid=$sid&ATTACHMENT=$Msgs->{ATTACHMENT_ID}",
          { TARGET => '_new' } ) . "  ($lang{SIZE}: " . int2byte( $Msgs->{CONTENT_SIZE} ) . ')';
      }

      if ($Msgs->{STATE} == 9) {
        push @REPLIES, $html->button( "$lang{CLOSE}", "index=$index&STATE=10&ID=$FORM{ID}&change=1&sid=$sid",
            { BUTTON => 1 } );
      }

      $Msgs->{REPLY} = join(($FORM{json}) ? ',' : '', @REPLIES);
      while ($Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/) {
        my $msg_button = $html->button( $1, "&index=$index&ID=$1",
                { class => 'badge bg-blue'});
        $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
      }
      $html->tpl_show(_include('msgs_client_show', 'Msgs'), {
          %$Msgs,
          ID => $main_msgs_id });

      my %params = ();
      my $state = $FORM{STATE};
      $params{CLOSED_DATE} = $DATE if ($state && $state > 0);
      $params{DONE_DATE} = $DATE if ($state && $state > 1);

      $Msgs->message_change({
        UID       => $LIST_PARAMS{UID},
        ID        => $FORM{ID},
        USER_READ => "$DATE  $TIME",
        %params
      });

      msgs_redirect_filter({
        UID => $LIST_PARAMS{UID}, DEL => 1
      });
    }

    #return  0;
  }
  elsif(!$FORM{SECRH_MSG_TEXT}) {
    $Msgs->{CHAPTER_SEL} = $html->form_select(
      'CHAPTER',
      {
        SELECTED       => $Msgs->{CHAPTER} || undef,
        SEL_LIST       => $Msgs->chapters_list({ INNER_CHAPTER => 0, COLS_NAME => 1 }),
        MAIN_MENU      => get_function_index('msgs_chapters'),
        MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : ''
      }
    );

    $html->tpl_show(
      _include('msgs_send_form_user', 'Msgs'),
      {
        %$Msgs,
      }
    );
  }

  if ($FORM{MESSAGE}) {
    $html->message('info', '', "$FORM{MESSAGE}");
  }

  _error_show($Msgs);

  my %statusbar_status = (
    0 => $msgs_status->{0},
    1 => $msgs_status->{1},
    2 => $msgs_status->{2},
    3 => $msgs_status->{3},
    4 => $msgs_status->{4},
    5 => $msgs_status->{5},
    6 => $msgs_status->{6}
  );

  $pages_qs .= "&SECRH_MSG_TEXT=$FORM{SECRH_MSG_TEXT}" if( $FORM{SECRH_MSG_TEXT});

  my $status_bar = msgs_status_bar({ MSGS_STATUS => \%statusbar_status, USER_UNREAD => 1, SHOW_ONLY => 3 });

  if (! $FORM{SORT}){
    $LIST_PARAMS{SORT} = '5 DESC, 4';
    delete $LIST_PARAMS{DESC};
  }

  $LIST_PARAMS{INNER_MSG} = 0;
  delete($LIST_PARAMS{STATE}) if ($FORM{STATE} && $FORM{STATE} =~ /\d+/ && $FORM{STATE} == 3);
  delete($LIST_PARAMS{PRIORITY}) if ($FORM{PRIORITY} && $FORM{PRIORITY} == 5);

  if (!defined($FORM{STATE}) && !$FORM{ALL_MSGS}) {
    $FORM{ALL_OPENED} = 1;
  }

  #===================================

  $html->tpl_show(_include('msgs_user_search_form', 'Msgs'), {%$Msgs});

  #If search messeges create custom table, else create deffult

  my $table;

  if ($FORM{SECRH_MSG_TEXT}) {
    my $request_search_word = $FORM{SECRH_MSG_TEXT};
    $request_search_word =~ s/\\/\\\\/gi;
    $request_search_word =~ s/\%/\\%/gi;
    $request_search_word =~ s/\'/\\'/gi;

    my $list = $Msgs->messages_list(
      {
        SUBJECT             => '_SHOW',
        CHAPTER_NAME        => '_SHOW',
        DATETIME            => '_SHOW',
        STATE               => '_SHOW',
        USER_READ           => '_SHOW',
        REPLY_TEXT          => '_SHOW',
        MESSAGE             => '_SHOW',
        SEARCH_MSGS_BY_WORD => $request_search_word,
        %LIST_PARAMS,
        COLS_NAME => 1
      }
    );

    $table = msgs_user_search_table(
      {
        ID          => $FORM{ID},
        SID         => $sid,
        TOTAL_MSGS  => $Msgs->{TOTAL},
        JSON        => $FORM{json},
        STATUS_BAR  => $status_bar,
        SEARCH_TEXT => $FORM{SECRH_MSG_TEXT},
      },
      $msgs_status,
      $list
    );
  }
  else {

    my $list = $Msgs->messages_list({
      SUBJECT             => '_SHOW',
      CHAPTER_NAME        => '_SHOW',
      DATETIME            => '_SHOW',
      STATE               => '_SHOW',
      USER_READ           => '_SHOW',
      %LIST_PARAMS,
      COLS_NAME           => 1
    });

    $table = $html->table({
      width       => '100%',
      caption     => $lang{MESSAGES},
      title_plain => [ '#', $lang{SUBJECT}, $lang{DATE}, $lang{STATUS}, '-' ],
      qs          => $pages_qs,
      pages       => $Msgs->{TOTAL},
      ID          => 'MSGS_LIST',
      header      => $status_bar,
    });

    foreach my $line (@$list) {
      $table->{rowcolor} = ($FORM{ID} && $line->{id} == $FORM{ID}) ? 'row_active' : undef;
      $line->{subject} = convert($line->{subject}, { text2html => 1, json => $FORM{json} });

      $table->addrow(
        $line->{id},
        ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT}), "index=$index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT})), "index=$index&ID=$line->{id}&sid=$sid#last_msg"),
        $line->{datetime},
        $html->color_mark($msgs_status->{ $line->{state} }),
        $html->button($lang{SHOW}, "index=$index&ID=$line->{id}&sid=$sid", { class => 'show' })
      );
    }
  }

  print $table->show();

  $Msgs->{TOTAL_MSG} = $Msgs->{TOTAL};
  #my %SHOW_PARAMS = (ADMIN_READ => '0000-00-00 00:00:00',);

  $table = $html->table(
    {
      width      => '100%',
      rows       => [
        [
          "$lang{TOTAL}:  " . $html->b( $Msgs->{TOTAL_MSG} ),
          #$html->color_mark( "$lang{IN_WORK}:  " . $html->b( $Msgs->{IN_WORK} ), $msgs_status_colors[3] ),
          "$lang{OPEN}: " . $html->b( $Msgs->{OPEN} ),
          #$html->color_mark( "$lang{CLOSED_UNSUCCESSFUL}:  " . $html->b( $Msgs->{UNMAKED} ), $msgs_status_colors[1] ),
          #$html->color_mark( "$lang{CLOSED_SUCCESSFUL}:  " . $html->b( $Msgs->{CLOSED} ), $msgs_status_colors[2] ),
        ]
      ],
      rowcolor => 'total'
    }
  );
  print $table->show();

  delete $LIST_PARAMS{SORT};

  return 1;
}

#**********************************************************
=head2 msgs_user_search_table() - Create table with find msgs

  Arguments:
    $attr -
      SEARCH_TEXT - Search word
      TOTAL_MSGS -  Total msgs
      STATUS_BAR -  Table status bar
    msgs_status  = hash reff with messages status
    list         = list of messages

  Returns:  HTML Table

  Examples:
=cut
#**********************************************************
sub msgs_user_search_table {
my ($attr, $msgs_status, $list) = @_;

  my $function_index = get_function_index('msgs_user') || $attr->{INDEX};

  my $table = $html->table(
      {
        width       => '100%',
        caption     => $lang{MESSAGES},
        title_plain => [ '#', $lang{SUBJECT}, $lang{MESSAGE}, $lang{DATE}, $lang{STATUS}, '-' ],
        qs          => $pages_qs . "SECRH_MSG_TEXT=$FORM{SECRH_MSG_TEXT}",
        pages       => $attr->{TOTAL_MSGS},
        ID          => 'MSGS_LIST_SEARCH',
        header      => $attr->{STATUS_BAR}
      }
    );

    foreach my $line (@$list) {
      $table->{rowcolor} = ($attr->{ID} && $line->{id} == $attr->{ID}) ? 'row_active' : undef;

      #Add color to search word In Subject, messegas, reply
      my $subject_color = _add_color_search($attr->{SEARCH_TEXT}, $line->{subject} );
      my ($text_color, $have_word_in_text)    = _add_color_search($attr->{SEARCH_TEXT}, $line->{message}, {SLICE => 1} );
      my ($reply_color, $have_word_in_reply)  = _add_color_search($attr->{SEARCH_TEXT}, $line->{reply_text}, {SLICE => 1} );

      #Watch if we have word in text if not add standart text
      my $resul_text = $have_word_in_text ? $text_color :  $have_word_in_reply ? $reply_color :  $text_color;

      $table->addrow(
        $line->{id},
        ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((( $subject_color) ? " $subject_color" : $lang{NO_SUBJECT}), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((( $subject_color) ? " $subject_color" : $lang{NO_SUBJECT})), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg"),
        $resul_text,
        $line->{datetime},
        $html->color_mark($msgs_status->{ $line->{state} }),
        $html->button($lang{SHOW}, "index=$function_index&ID=$line->{id}&sid=$sid", { class => 'show' })
      );
    }

  return $table;
}

#**********************************************************
=head2 _add_color_search() - Add color to search word in text

  Arguments:
    $attr -
      SLICE - Slice text 80  or 95 if no search word
  Returns: format_text(String), Find word(Bool: 1 or 0)

  Examples:
=cut
#**********************************************************
sub _add_color_search {
  my ($word, $full_text, $attr) = @_;

  if($word && $full_text){

    #Turn off special characters for regexp
    my $quote_word = quotemeta($word);

    #my $word_with_color;
    #If we didnt want full text. Slice
    if($attr->{SLICE}){

      #Slice and search word
      my ($result_text) = $full_text =~ m/.{0,40}$quote_word.{0,40}/gi;

      #If see search word add color else onle slice
      if($result_text){

        #Add color
        $result_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

        return $result_text, 1;
      }
      else{
        ($result_text) = $full_text =~ m/.{0,95}/g;
        return $result_text, 0;
      }
    }

    #If see search word add color
    $full_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

    return $full_text;
  }
  else{
    return '';
  }
}

1;