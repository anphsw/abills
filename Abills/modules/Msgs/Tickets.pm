=head2 NAME

  Tasks

=cut

use strict;
use warnings FATAL => 'all';
use Encode qw(_utf8_on);

use Abills::Base qw(urlencode in_array int2byte convert);
use Msgs::Misc::Attachments;
use Shedule;
use Address;

our (
  $db,
  %conf,
  %lang,
  $admin,
  %permissions,
  @WEEKDAYS,
  @MONTHES,
  @MONTHES_LIT,
);

our Abills::HTML $html;
my $Address = Address->new($db, $admin, \%conf);
my $Msgs = Msgs->new($db, $admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);
my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);

my @send_methods = ($lang{MESSAGE}, 'E-MAIL');
my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

if ($conf{MSGS_REDIRECT_FILTER_ADD}) {
  $send_methods[3] = 'Web redirect';
}


#**********************************************************
=head2 msgs_admin_privileges($attr)

  Arguments:
    $aid

  Returns:
    \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION

=cut
#**********************************************************
sub msgs_admin_privileges {
  my ($aid) = @_;

  my $a_list = $Msgs->admins_list({ AID => $aid, DISABLE => 0 });
  my %A_PRIVILEGES = ();
  my %CHAPTERS_DELIGATION = ();
  my @A_CHAPTER = ();

  foreach my $line (@{$a_list}) {
    if ($line->[5] > 0) {
      push @A_CHAPTER, "$line->[5]:$line->[3]";
      $CHAPTERS_DELIGATION{ $line->[5] } = $line->[3];
      $A_PRIVILEGES{ $line->[5] } = $line->[2];
    }
  }

  return \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION;
}

#**********************************************************
=head2 msgs_admin($attr) - Admin messages

  Attributes:
    $attr

=cut
#**********************************************************
sub msgs_admin {
  my ($attr) = @_;

  $Msgs->{TAB1_ACTIVE} = "active";

  $FORM{chg} = $FORM{CHG_MSGS} if ($FORM{CHG_MSGS});
  $FORM{del} = $FORM{DEL_MSGS} if ($FORM{DEL_MSGS});


  $Msgs->{ACTION} = 'send';
  $Msgs->{LNG_ACTION} = $lang{SEND};
  my $uid = $FORM{UID};

  #Get admin privileges
  my ($A_CHAPTER, $A_PRIVILEGES, $CHAPTERS_DELIGATION) = msgs_admin_privileges($admin->{AID});

  if ($FORM{ajax} && $FORM{SURVEY_ID}) {
    $Msgs->survey_subject_info($FORM{SURVEY_ID});
    print "$Msgs->{TPL}";
    return 1;
  }

  if ($FORM{MSG_HISTORY}) {
    form_changes({
      SEARCH_PARAMS => {
        MODULE      => 'Msgs',
        ACTION      => 'MSG_ID:' . $FORM{MSG_HISTORY} . "*",
        SORT        => $FORM{sort} || 1,
        DESC        => (! $FORM{sort}) ? 'desc' : $FORM{desc},
      },
      PAGES_QS      => "&MSG_HISTORY=$FORM{MSG_HISTORY}"
    });

    return 1;
  }
  elsif ($FORM{TASK}) {
    require Msgs::Tasks;
    msgs_tasks();
    return 1;
  }
  elsif ($FORM{CHANGE_SUBJECT} && $FORM{SUBJECT} ne '') {
    $Msgs->message_change({
      ID      => $FORM{chg},
      SUBJECT => $FORM{SUBJECT},
    });
    _error_show($Msgs);

    $Msgs->message_reply_add({
      ID              => $FORM{chg},
      REPLY_TEXT      => "$lang{SUBJECT_CHANGED} '$FORM{OLD_SUBJECT}' $lang{ON} '$FORM{SUBJECT}'",
      REPLY_INNER_MSG => 1,
      AID             => $admin->{AID},
    });
    _error_show($Msgs);
  }
  elsif ($FORM{CHANGE_MSGS_TAGS}) {
    $Msgs->{TAB1_ACTIVE} = "active";
    $Msgs->quick_replys_tags_add({ IDS => $FORM{TAGS_IDS}, MSG_ID => $FORM{chg} });
    if (!$Msgs->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADD} $Msgs->{TOTAL} $lang{TAGS}");
    }
  }
  elsif ($FORM{MSG_PRINT_ID}) {
    msgs_ticket_form({ MSG_PRINT_ID => $FORM{MSG_PRINT_ID}, UID => $uid });
    return 1;
  }
  elsif ($FORM{NEXT_MSG}) {
    # Get next message
    my $list = $Msgs->messages_list({
      ID        => ">$FORM{NEXT_MSG}",
      STATE     => 0,
      PAGE_ROWS => 1,
      COLS_NAME => 1,
    });

    if ($Msgs->{TOTAL} > 0) {
      my $user_info = user_info($list->[0]->{uid});
      if ($user_info) {
        print $user_info->{TABLE_SHOW} || q{};
      }
      msgs_ticket_show({ ID => $list->[0]->{id} });
      return 1;
    }
  }
  elsif ($FORM{deligate}) {
    $Msgs->message_change({
      ID         => $FORM{deligate},
      DELIGATION => $FORM{level},
      ADMIN_READ => "0000-00-00 00:00:00",
      RESPOSIBLE => 0,
    });

    $Msgs->message_reply_add({
      ID              => $FORM{deligate},
      AID             => $conf{SYSTEM_ADMIN_ID} || 2,
      IP              => $admin->{SESSION_IP},
      STATE           => 0,
      REPLY_TEXT      => "$lang{DELIGATE} : " . ($admin->{A_FIO} || $admin->{A_LOGIN} || ''),
      REPLY_INNER_MSG => 1
    });

    $html->message('info', $lang{INFO}, "$lang{DELIGATED}") if (!$Msgs->{errno});
  }
  elsif ($FORM{WORK}) {
    if (!msgs_work({ WORK_LIST => 1, UID => $uid, MESSAGE_ID => $FORM{WORK}, MNG => 1 })) {
      return 1;
    }

    my $result = msgs_ticket_show({
      ID                  => $FORM{WORK},
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    if($result) {
      msgs_work({ WORK_LIST => 1, MESSAGE_ID => $FORM{WORK}, UID => $uid });
    }

    return 1;
  }
  elsif ($FORM{export}) {
    msgs_export();
    return 1;
  }
  elsif ($FORM{STORAGE_MSGS_ID}){
    load_module('Storage', $html);
    storage_hardware();

    if($FORM{add} && $FORM{INSTALLATION_ID}){
      $Msgs->msgs_storage_add({
        MSGS_ID         => $FORM{STORAGE_MSGS_ID},
        INSTALLATION_ID => $FORM{INSTALLATION_ID},
      });
    }

    return 1;
  }
  elsif ($FORM{add_dispatch} && $FORM{del}) {
    my @ids = split(/, /, $FORM{del});
    for my $id (@ids) {
      $Msgs->message_change(
        {
          DISPATCH_ID => $FORM{DISPATCH_ID},
          ID          => $id
        }
      );
    }

    $html->message('info', $lang{INFO}, "$lang{DISPATCH} $lang{ADD} # $FORM{del}") if (!$Msgs->{errno});
  }
  elsif ($FORM{reply} && $FORM{ID}) {
    # Add message reply
    $Msgs->{TAB2_ACTIVE} = "active";
    _msgs_reply_admin();
    return 1;
  }
  elsif ($FORM{ATTACHMENT}) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ($FORM{PHOTO}) {
    my $media_return = form_image_mng({
      TO_RETURN => 1,
    });

    if ($FORM{IMAGE}) {
      $FORM{reply} = 1;
      $FORM{ID} = $FORM{PHOTO};
      $FORM{FILE_UPLOAD} = $media_return;
      msgs_admin();
    }

    return 0;
  }
  elsif ($FORM{del} && $FORM{UPDATE_STATUS}) {
    my @id_msgs = ();
    @id_msgs = split(/, /, $FORM{del});
    
    my @id_error_change = ();

    foreach my $id (@id_msgs) {
      $Msgs->message_change({
        ID    => $id,
        STATE => $FORM{STATE_CHANGE} || 2
      });

      push @id_error_change, $id if ($Msgs->{errno});
    }

    if ($#id_error_change > 0) {
      $html->message('err', $lang{ERROR}, "$lang{ERROR}: " . join(', ', @id_error_change));
    }
    else {
      $html->message('info', $lang{INFO}, $lang{SUCCESS});
    }
  }

  if ($FORM{chg}) {
    $Msgs->{TAB2_ACTIVE} = (!$Msgs->{TAB1_ACTIVE}) ? "active" : "";
    msgs_ticket_show({
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    msgs_work({ WORK_LIST => 1, MESSAGE_ID => $FORM{chg}, UID => $uid });
    msgs_storage();
    return 0;
  }
  elsif ($FORM{change}) {
    msgs_ticket_change();

    msgs_ticket_show({
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    return 1;
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    msgs_redirect_filter({
      DEL    => 1,
      UID    => $uid,
      MSG_ID => $FORM{del}
    });

    if ($conf{MSGS_ADDRESS}) {
      $Msgs->msgs_address_del({ ID => $FORM{del} });
    }

    $Msgs->message_team_del($FORM{del});
    if (!_error_show($Msgs)) {
      $Msgs->message_del({ ID => $FORM{del}, UID => $uid });
      $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}") if (!$Msgs->{errno});
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERROR});
    }
  }

  if (scalar keys %{$CHAPTERS_DELIGATION} > 0) {
    $LIST_PARAMS{CHAPTERS_DELIGATION} = $CHAPTERS_DELIGATION;
    $LIST_PARAMS{PRIVILEGES} = $A_PRIVILEGES;
    $LIST_PARAMS{UID} = undef if (!$uid);
  }

  if ($FORM{search_form}) {
    msgs_form_search({ A_PRIVILEGES => $A_PRIVILEGES });
  }
  elsif ($FORM{add_form}) {
    my $return = msgs_admin_add();
    return ($return == 2) ? 2 : 1;
  }

  $LIST_PARAMS{STATE} = undef if ($FORM{STATE} && $FORM{STATE} =~ /^\d+$/ && $FORM{STATE} == 3);
  $LIST_PARAMS{PRIORITY} = undef if ($FORM{PRIORITY} && $FORM{PRIORITY} =~ /^\d+$/ && $FORM{PRIORITY} == 5);
  $LIST_PARAMS{CHAPTER} = $FORM{CHAPTER} if ($FORM{CHAPTER});
  $LIST_PARAMS{DESC} = 'DESC' if (!$FORM{sort});
  $LIST_PARAMS{RESPOSIBLE} = $attr->{ADMIN}->{AID} if ($attr->{ADMIN}->{AID});

  msgs_list({
    A_PRIVILEGES        => $A_PRIVILEGES,
    A_CHAPTER           => $A_CHAPTER,
    CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
  });

  return 1;
}

#**********************************************************
=head2 msgs_ticket_change($attr)

=cut
#**********************************************************
sub msgs_ticket_change {

  $Msgs->{TAB3_ACTIVE} = "active";
  if ($FORM{STATE} && $FORM{STATE} > 0) {
    $FORM{DONE_DATE} = $DATE if ($FORM{STATE} == 2);
    $FORM{CLOSED_DATE} = "$DATE  $TIME" if ($FORM{STATE} == 1 || $FORM{STATE} == 2);
  }

  #Watch
  if ($FORM{WATCH}) {
    if ($FORM{del}) {
      $Msgs->msg_watch_del({ ID => $FORM{ID}, AID => $admin->{AID} });
    }
    else {
      $Msgs->msg_watch(\%FORM);
    }
  }
  else {
    # _msgs_change_resposible will need AID of current responsible admin,
    # so should be executed first
    # We skip changing inside to avoid unnecessary queries
    if (defined $FORM{RESPOSIBLE}) {
      _msgs_change_responsible($FORM{ID}, $FORM{RESPOSIBLE}, {
        SKIP_CHANGE => 1
      });
    }
    $Msgs->message_change({ %FORM, USER_READ => "0000-00-00  00:00:00" });
  }

  if (!_error_show($Msgs)) {
    $html->message('info', $lang{INFO}, "$lang{CHANGED}");
  }

  $FORM{chg} = $FORM{ID} if ($FORM{ID});

  return 1;
}

#**********************************************************
=head2 msgs_admin_add($attr)

=cut
#**********************************************************
sub msgs_admin_add {
  my ($attr) = @_;

  if ($FORM{ADD_ADDRESS_BUILD} && $FORM{STREET_ID} && !$FORM{LOCATION_ID}) {
    $Address->build_add({ STREET_ID => $FORM{STREET_ID}, ADD_ADDRESS_BUILD => $FORM{ADD_ADDRESS_BUILD} });
    if (!_error_show($Address)) {
      $FORM{LOCATION_ID} = $Address->{INSERT_ID};
    }
  }
  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  if ($FORM{add_form} && $FORM{next}) {
    $FORM{send_message} = 1;
  }

  if ($FORM{send_message} || $FORM{PREVIEW}) {
    #Multi send
    my $message = '';
    my @msgs_ids = ();
    my %NUMBERS = ();
    my @ATTACHMENTS = ();
    if ($FORM{DISPATCH_CREATE}) {
      $FORM{COMMENTS} = $FORM{DISPATCH_COMMENTS};
      $Msgs->dispatch_add({ %FORM, PLAN_DATE => $FORM{DISPATCH_PLAN_DATE} });
      $FORM{DISPATCH_ID} = $Msgs->{DISPATCH_ID};
      $html->message('info', $lang{INFO}, "$lang{DISPATCH} $lang{ADDED}") if (!$Msgs->{errno});
    }

    if ($FORM{DELIVERY_CREATE}) {
      $Msgs->msgs_delivery_add({ %FORM,
        TEXT        => $FORM{MESSAGE},
        SUBJECT     => $FORM{SUBJECT},
        SEND_DATE   => $FORM{DELIVERY_SEND_DATE},
        SEND_TIME   => $FORM{DELIVERY_SEND_TIME},
        SEND_METHOD => $FORM{DELIVERY_SEND_METHOD} || $FORM{SEND_TYPE},
        STATUS      => $FORM{DELIVERY_STATUS},
        PRIORITY    => $FORM{DELIVERY_PRIORITY},
      });

      $FORM{DELIVERY} = $Msgs->{DELIVERY_ID};
      $html->message('info', $lang{INFO}, "$lang{DELIVERY} $lang{ADDED}") if (!$Msgs->{errno});
    }

    for (my $i = 0; $i <= 2; $i++) {
      # First input will come without underscore
      my $input_name = 'FILE_UPLOAD' . (($i > 0) ? "_$i" : '');

      if ($FORM{ $input_name }->{filename}) {
        push @ATTACHMENTS,
          {
            FILENAME     => $FORM{ $input_name }->{filename},
            CONTENT_TYPE => $FORM{ $input_name }->{'Content-Type'},
            FILESIZE     => $FORM{ $input_name }->{Size},
            CONTENT      => $FORM{ $input_name }->{Contents},
          };
      }
    }

    if ($FORM{SEND_TYPE} && ($FORM{SEND_TYPE} == 1 || $FORM{SEND_TYPE} == 6)) {
      $FORM{STATE} = 2;
    }

    if ($FORM{UID}) {
      $FORM{UID} =~ s/,/;/g;
    }

    if ($FORM{LOCATION_ID} && $FORM{LOCATION_ID} =~ /, /g) {
      $FORM{LOCATION_ID}   =~ s/, //g;
      $FORM{STREET_ID}     =~ s/, //g;
      $FORM{DISTRICT_ID}   =~ s/, //g;
      $FORM{ADDRESS_FLAT}  =~ s/, //g;
    }

    if (!$FORM{UID} && $FORM{LOCATION_ID} && $FORM{CHECK_FOR_ADDRESS} && $FORM{send_message}) {
      $Msgs->message_add({
        %FORM,
        MESSAGE    => $FORM{MESSAGE},
        PHONE      => $FORM{CALL_PHONE},
        STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
        ADMIN_READ => (!$FORM{INNER_MSG}) ? "$DATE $TIME" : '0000-00-00 00:00:00',
        USER_READ  => '0000-00-00 00:00:00',
        IP         => $admin->{SESSION_IP}
      });

      if (!_error_show($Msgs) && $conf{MSGS_ADDRESS}) {
        $Msgs->msgs_address_add({ 
          ID          => $Msgs->{INSERT_ID},
          DISTRICTS   => $FORM{DISTRICT_ID} || 0,
          STREET      => $FORM{STREET_ID} || 0,
          BUILD       => $FORM{LOCATION_ID} || 0,
          FLAT        => $FORM{ADDRESS_FLAT} || 0
        });
      }

      $html->message('info', $lang{MESSAGES}, "$lang{SENDED} $lang{MESSAGE}");

      print msgs_admin_add_form({
        %{($attr) ? $attr : {}},
        MSGS_STATUS => $msgs_status
      });

      return ($attr->{PREVIEW_FORM}) ? 2 : 1;
    }
    elsif (!$FORM{UID} && !$FORM{LOCATION_ID} && $FORM{CHECK_FOR_ADDRESS} && $FORM{send_message}) {
      $html->message( 'err', $lang{ERROR}, "Выберите дом к которому прикрепить сообщение" );

      print msgs_admin_add_form({
        %{($attr) ? $attr : {}},
        MSGS_STATUS => $msgs_status
      });

      return 1;
    }

    my %query_data = ();

    foreach my $data_element (keys %FORM) {
      if ($FORM{ $data_element }) {
        $query_data{ $data_element } = $FORM{ $data_element };
      }
      else {
        $query_data{ $data_element } = '_SHOW';
      }
    }

    my $users_list = $users->list({
      LOGIN     => '_SHOW',
      FIO       => '_SHOW',
      PHONE     => '_SHOW',
      EMAIL     => '_SHOW',
      %query_data,
      UID       => ($FORM{UID} && $FORM{UID} =~ /\d+/) ? $FORM{UID} : undef,
      GID       => $FORM{GID},
      PAGE_ROWS => 1000000,
      DISABLE   => ($FORM{GID}) ? 0 : undef,
      COLS_NAME => 1,
    });

    if ($users->{TOTAL} < 1) {
      $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST} $FORM{UID}", { ID => 700 });
      return 0;
    }
    elsif (_error_show($users)) {

    }

    if ($FORM{PREVIEW}) {
      $html->message('info', $lang{INFO}, "$lang{PRE}\n $lang{TOTAL}: $users->{TOTAL}");
      my Abills::HTML $table;
      $users->{TOTAL} = '';
      ($table) = result_former({
        INPUT_DATA      => $users,
        LIST            => $users_list,
        BASE_FIELDS     => 1,
        MULTISELECT     => 'UID:uid',
        FUNCTION_FIELDS => '',
        TABLE           => {
          width      => '100%',
          qs         => $pages_qs,
          ID         => 'USERS_LIST',
          SELECT_ALL => "users_list:UID:$lang{SELECT_ALL}",
        },
        MAKE_ROWS       => 1,
      });

      $attr->{PREVIEW_FORM} = $table->show();
      delete($FORM{UID});
    }
    elsif ($FORM{DELIVERY}) {
      my $uids = '';
      foreach my $line (@{$users_list}) {
        $uids .= $line->{uid} . ', ';
      }

      $Msgs->delivery_user_list_add({
        MDELIVERY_ID => $FORM{DELIVERY},
        IDS          => $uids,
      });
      $html->message('info', $lang{INFO},
        "$Msgs->{TOTAL} $lang{USERS_ADDED_TO_DELIVERY} №:$FORM{DELIVERY}") if (!$Msgs->{errno});
    }
    #Send message
    else {
      if ($FORM{SURVEY_ID} && !$FORM{SUBJECT}) {
        $Msgs->survey_subject_info($FORM{SURVEY_ID});
        $FORM{SUBJECT} = $Msgs->{NAME} || q{};

        if ($Msgs->{FILENAME}) {
          push @ATTACHMENTS,
            {
              FILENAME     => $Msgs->{FILENAME} || q{},
              CONTENT_TYPE => $Msgs->{FILE_CONTENT_TYPE} || '',
              FILESIZE     => $Msgs->{FILE_SIZE} || '',
              CONTENT      => $Msgs->{FILE_CONTENTS} || '',
            };
        }
      }

      my @uids = ();
      my %msg_for_uid = ();
      foreach my $user_info (@{$users_list}) {
        $FORM{UID} = $user_info->{uid};
        if ($user_info->{phone}) {
          $user_info->{phone} =~ s/(.*);.*/$1/;
          $NUMBERS{ $user_info->{phone} } = $user_info->{uid};
        }
        push @uids, $user_info->{uid};

        my $user_pi = $users->pi({ UID => $user_info->{uid}, COLS_NAME => 1, COLS_UPPER => 1 });
        my $internet_info = {};
        if (in_array('Internet', \@MODULES)) {
          require Internet;
          Internet->import();
          my $Internet = Internet->new($db, $admin, \%conf);
          $internet_info = $Internet->info($user_info->{uid}, { COLS_NAME => 1, COLS_UPPER => 1 });
        }

        $message = $html->tpl_show($FORM{MESSAGE}, { USER_LOGIN => $user_pi->{LOGIN}, %{$user_pi}, %{$internet_info} }, {
          OUTPUT2RETURN      => 1,
          SKIP_DEBUG_MARKERS => 1
        });

        if ($FORM{DAY}) {
          require JSON;

          _utf8_on($FORM{SUBJECT});
          _utf8_on($message);

          my $args = {
            UID        => $user_info->{uid},
            CHAPTER    => $FORM{CHAPTER},
            SUBJECT    => $FORM{SUBJECT},
            PRIORITY   => $FORM{PRIORITY},
            RESPOSIBLE => $FORM{RESPOSIBLE},
            MESSAGE    => $message,
            STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
            USER_READ  => '0000-00-00 00:00:00',
            IP         => $admin->{SESSION_IP}
          };

          my %action_hash = (
            module   => 'Msgs',
            function => 'message_add',
            args     => $args,
          );

          my $json_action = JSON::to_json(\%action_hash);
          my $Shedule = Shedule->new($db, $admin, \%conf);

          $FORM{DAY} = sprintf("%02d", $FORM{DAY}) unless ($FORM{DAY} eq '*');
          $FORM{MONTH} = sprintf("%02d", $FORM{MONTH}) unless ($FORM{MONTH} eq '*');;

          $Shedule->add({
            DESCRIBE => 'Admin message shedule',
            D        => $FORM{DAY} || '*',
            M        => $FORM{MONTH} || '*',
            Y        => $FORM{YEAR} || '*',
            TYPE     => 'call_fn',
            ACTION   => $json_action,
            COUNTS   => ($FORM{PERIODIC} ? '999' : '0'),
            UID      => $user_info->{uid},
          });

          next;
        }

        $Msgs->message_add({
          %FORM,
          MESSAGE    => $message,
          STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
          ADMIN_READ => (!$FORM{INNER_MSG}) ? "$DATE $TIME" : '0000-00-00 00:00:00',
          USER_READ  => '0000-00-00 00:00:00',
          IP         => $admin->{SESSION_IP}
        });

        if (!_error_show($Msgs)) {
          $Msgs->msgs_address_add({
            ID        => $Msgs->{INSERT_ID},
            DISTRICTS => $FORM{DISTRICT_ID} || 0,
            STREET    => $FORM{STREET_ID} || 0,
            BUILD     => $FORM{LOCATION_ID} || 0,
            FLAT      => $FORM{ADDRESS_FLAT} || 0
          });
        }

        if (_error_show($Msgs)) {
          return 0;
        }
        elsif ($attr->{REGISTRATION}) {
          return 1;
        }

        push @msgs_ids, $Msgs->{MSG_ID};

        $msg_for_uid{$user_info->{uid}} = {
          MSG_ID => $Msgs->{MSG_ID}
        };
      }

      if ($#msgs_ids < 0) {
        $html->message('err', $lang{ERROR}, $lang{NO_CONTACTS_FOR_TYPE}, { ID => 781 });
      }

      if ($FORM{DAY}) {
        $html->message('info', $lang{SHEDULE}, "$lang{ADDED} $lang{SHEDULE}");
        return 1;
      }

      if ($users->{TOTAL} > 1) {
        $message = "$lang{TOTAL}: $users->{TOTAL}";
        $LIST_PARAMS{PAGE_ROWS} = 25;
      }

      if (!$FORM{INNER_MSG}) {
        #Web redirect
        if ($FORM{SEND_TYPE} && $FORM{SEND_TYPE} == 3) {
          msgs_redirect_filter({ UID => join(',', @uids) });
        }
        else {
          msgs_notify_user({
            STATE_ID       => $FORM{STATE},
            STATE          => ($FORM{STATE} && $msgs_status->{$FORM{STATE}}) ? $msgs_status->{$FORM{STATE}} : q{},
            REPLY_ID       => 0,
            MSGS           => $Msgs,
            SEND_TYPE      => $FORM{SEND_TYPE},
            MESSAGES_BATCH => \%msg_for_uid,
            ATTACHMENTS    => \@ATTACHMENTS
          });
        }
      }

      if (!$Msgs->{errno} && $Msgs->{MSG_ID}) {
        #Add attachment
        for (my $i = 0; $i <= $#ATTACHMENTS; $i++) {
          $Attachments->attachment_add(
            {
              MSG_ID => ($#msgs_ids > -1) ? \@msgs_ids : $Msgs->{MSG_ID},
              # Do not create subdirectories if have multiple uids
              UID    => ($#uids == 0) ? $uids[0] : '_',
              %{$ATTACHMENTS[$i]}
            }
          );
        }

        $html->message('info', $lang{MESSAGES}, "$lang{SENDED} $lang{MESSAGE}");

        if ($FORM{INNER_MSG}) {
          msgs_notify_admins();
          if ($FORM{SURVEY_ID}) {
            $FORM{chg} = $Msgs->{MSG_ID};
            msgs_admin();
            return 0;
          }
        }
      }

      return 0 if ($attr->{SEND_ONLY} || $attr->{REGISTRATION});

      if ($#msgs_ids > -1) {
        $FORM{ID} = join(',', @msgs_ids);
        my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
        $html->redirect("?index=$index"
          . "&MESSAGE=$header_message#last_msg",
        );
      }
    }
  }

  print msgs_admin_add_form({
    %{($attr) ? $attr : {}},
    MSGS_STATUS => $msgs_status
  });

  return ($attr->{PREVIEW_FORM}) ? 2 : 1;
}


#**********************************************************
=head2 msgs_admin_add_form($attr) - Show message

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub msgs_admin_add_form {
  my ($attr) = @_;

  my $msgs_status = $attr->{MSGS_STATUS};
  my %tpl_info = ();

  if ($attr->{ACTION}) {
    $tpl_info{ACTION} = $attr->{ACTION};
    $tpl_info{LNG_ACTION} = $attr->{LNG_ACTION};
  }
  else {
    $tpl_info{ACTION} = 'send_message';
    $tpl_info{LNG_ACTION} = $lang{SEND};
  }

  my $a_list = $Msgs->admins_list(
    {
      AID       => $admin->{AID},
      DISABLE   => 0,
      COLS_NAME => 1
    }
  );
  my @A_CHAPTER = ();

  if ($Msgs->{TOTAL} > 0) {
    foreach my $line (@{$a_list}) {
      if ($line->{chapter_id} > 0) {
        push @A_CHAPTER, $line->{chapter_id} if ($line->{priority} > 0);
      }
    }

    if ($#A_CHAPTER == -1) {
      return 0;
    }
    else {
      $LIST_PARAMS{CHAPTER} = join(',  ', @A_CHAPTER);
    }
    $LIST_PARAMS{UID} = undef if (!$FORM{UID});
  }

  $Msgs->{CHAPTER_SEL} = $html->form_select(
    'CHAPTER',
    {
      SELECTED       => $Msgs->{CHAPTER},
      SEL_LIST       => $Msgs->chapters_list({ CHAPTER => $LIST_PARAMS{CHAPTER} || undef, COLS_NAME => 1 }),
      MAIN_MENU      => get_function_index('msgs_chapters'),
      MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : ''
    }
  );

  $Msgs->{DISPATCH_SEL} = $html->form_select(
    'DISPATCH_ID',
    {
      SELECTED    => $Msgs->{DISPATCH_ID} || '',
      SEL_LIST    => $Msgs->dispatch_list({ COMMENTS => '_SHOW', PLAN_DATE => '_SHOW', STATE => 0, COLS_NAME => 1 }),
      SEL_OPTIONS => { '' => '--' },
      SEL_KEY     => 'id',
      SEL_VALUE   => 'plan_date,comments'
    }
  );

  if ((!$FORM{UID} || $FORM{UID} =~ /;/) && !$FORM{TASK}) {
    $tpl_info{GROUP_SEL} = sel_groups({ MULTISELECT => 1 });
    $tpl_info{ADDRESS_FORM} = form_address({ 
      LOCATION_ID       => $FORM{LOCATION_ID} || '',
      SHOW_ADD_BUTTONS  => $conf{MSGS_ADDRESS} ? 1 : 0,
    });

    if (in_array('Tags', \@MODULES)) {
      if (!$admin->{MODULES} || $admin->{MODULES}{'Tags'}) {
        load_module('Tags', $html);

        my (undef, $tags_count) = tags_sel({ HASH => 1 });

        if ($tags_count) {
          $tpl_info{TAGS_FORM} = $html->tpl_show(
            templates('form_show_hide'),
            {
              CONTENT     => tags_search_form(),
              NAME        => $lang{TAGS},
              ID          => 'TAGS_FORM',
              PARAMS      => 'collapsed-box',
              BUTTON_ICON => 'plus'
            },
            { OUTPUT2RETURN => 1 }
          );
        }
      }
    }

    $tpl_info{DATE_PIKER} = $html->form_datepicker('DELIVERY_SEND_DATE');
    $tpl_info{TIME_PIKER} = $html->form_timepicker('DELIVERY_SEND_TIME');
    $tpl_info{STATUS_SELECT} = msgs_sel_status({ NAME => 'DELIVERY_STATUS' });

    $tpl_info{PRIORITY_SELECT} = $html->form_select(
      'DELIVERY_PRIORITY',
      {
        SELECTED     => 2,
        SEL_ARRAY    => \@priority,
        STYLE        => \@priority_colors,
        ARRAY_NUM_ID => 1
      }
    );

    $tpl_info{SEND_METHOD_SELECT} = $html->form_select(
      'DELIVERY_SEND_METHOD',
      {
        SELECTED     => 2,
        SEL_ARRAY    => \@send_methods,
        ARRAY_NUM_ID => 1
      }
    );

    $tpl_info{DELIVERY_SELECT_FORM} = sel_deliverys({ SKIP_MULTISELECT => 1, SELECTED => $FORM{DELIVERY} || '' });
    $tpl_info{SEND_DELIVERY_FORM} = $html->tpl_show(
      _include('msgs_delivery_form', 'Msgs'),
      { %{$attr}, %FORM, %tpl_info, %{$Msgs} },
      { OUTPUT2RETURN => 1 },
    );

    $tpl_info{BACK_BUTTON} = $html->form_input('PREVIEW', $lang{PRE}, { TYPE => 'submit' });
    
    unless ($permissions{0}{28}) {
      $tpl_info{GROUP_HIDE} = 'display: none';
    }

    $tpl_info{SEND_EXTRA_FORM} = $html->tpl_show(_include('msgs_send_extra', 'Msgs'),
      \%tpl_info,
      { OUTPUT2RETURN => 1, ID => 'msgs_send_extra' });
  }

  #Message send  type
  my %send_types = (
    0 => "$lang{MESSAGE}",
  );

  my $sender_send_types = $Sender->available_types({ HASH_RETURN => 1, CLIENT => 1 });

  %send_types = (
    %send_types,
    %$sender_send_types
  );

  if ($conf{MSGS_REDIRECT_FILTER_ADD}) {
    $send_types{3} = 'Msgs redirect';
  }

  my $send_types = $html->form_select(
    'SEND_TYPE',
    {
      SELECTED => $Msgs->{SEND_TYPE} || $FORM{SEND_TYPE} || 0,
      SEL_HASH => \%send_types,
      NO_ID    => 1
    }
  );

  $tpl_info{SEND_TYPES_FORM} = $html->tpl_show(
    templates('form_row'),
    {
      ID    => 'SEND_TYPE',
      NAME  => $lang{SEND},
      VALUE => $send_types
    },
    { OUTPUT2RETURN => 1 }
  );

  $tpl_info{STATE_SEL} = $html->form_select(
    'STATE',
    {
      SELECTED   => $Msgs->{STATE} || 0,
      SEL_HASH   => {
        0 => $msgs_status->{0},
        1 => $msgs_status->{1},
        2 => $msgs_status->{2},
        9 => $msgs_status->{9},
      },
      USE_COLORS => 1,
      NO_ID      => 1
    }
  );

  $tpl_info{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $tpl_info{RESPOSIBLE} = sel_admins({ NAME => 'RESPOSIBLE', SELECTED => $admin->{AID}, DISABLE => 0 });
  $tpl_info{INNER_MSG} = 'checked' if ($conf{MSGS_INNER_DEFAULT});
  $tpl_info{SURVEY_SEL} = msgs_survey_sel();
  $tpl_info{PERIODIC} = 'checked' if ($FORM{PERIODIC});
  $tpl_info{PAR} = $attr->{PAR} if ($attr->{PAR});
  $tpl_info{PLAN_DATETIME_INPUT} = $html->form_datetimepicker(
    'PLAN_DATETIME',
    (
      ($Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00' ? $Msgs->{PLAN_DATE}
        . ' '
        . ($Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00' ? $Msgs->{PLAN_TIME} : '00:00') : '')
    ),
    {
      ICON           => 1,
      TIME_HIDDEN_ID => 'PLAN_TIME',
      DATE_HIDDEN_ID => 'PLAN_DATE',
      EX_PARAMS      => q{pattern='^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'},
    }
  );
  $FORM{CHECK_REPEAT} = $conf{MSGS_CHECK_REPEAT} ? 1 : 0;

  my $add_tpl_form = ($attr->{TASK_ADD}) ? 'msgs_task' : 'msgs_send_form';

  if ($FORM{MESSAGE}) {
    $Msgs->{TPL_MESSAGE} = $FORM{MESSAGE} || '';
    $Msgs->{TPL_MESSAGE} =~ s/\%/&#37/g;
  }
  my $message_form = $html->tpl_show(_include($add_tpl_form, 'Msgs'),
    { %{$attr}, %FORM, %{$Msgs}, %tpl_info },
    { OUTPUT2RETURN => 1,
      ID            => 'MSGS_SEND_FORM'
    });

  return $message_form;
}


#**********************************************************
=head2 msgs_ticket_show($attr) - Show message

  Arguments:
    $attr
      ID
      A_PRIVILEGES
      CHAPTERS_DELIGATION

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub msgs_ticket_show {
  my ($attr) = @_;

  my $A_PRIVILEGES = $attr->{A_PRIVILEGES};
  my $CHAPTERS_DELIGATION = $attr->{CHAPTERS_DELIGATION};
  my $message_id = $attr->{ID} || $FORM{chg} || 0;
  my $msgs_managment_tpl = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_managment_simplified_mode' : 'msgs_managment';
  my $msgs_show_tpl = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_show_simplified_mode' : 'msgs_show';

  if ($FORM{MESSAGE}) {
    $html->message('info', '', $FORM{MESSAGE});
  }

  # Fix missing $FORM{UID}. TODO: remove when result folmer list will be fixed (#899)
  if ($message_id && !$FORM{UID}) {
    my $message_info_list = $Msgs->messages_list({
      MSG_ID      => $message_id,
      COLS_NAME   => 1,
      UID         => '_SHOW',
      LOCATION_ID => '_SHOW',
    });

    _error_show($Msgs);

    if (
      # Check we have correct arrayref
      !$message_info_list || ref $message_info_list ne 'ARRAY' || !scalar @{$message_info_list}
        # Check we have correct hashref
        || !$message_info_list->[0] || ref $message_info_list->[0] ne 'HASH' || !$message_info_list->[0]->{uid}
    ) {
      if ($message_info_list->[0] && !$message_info_list->[0]->{uid} && !$message_info_list->[0]->{location_id}) {
        $html->message('warn', $lang{WARNING}, 'No $FORM{UID} defined');
      }
    }
    else {
      $FORM{UID} = $message_info_list->[0]->{uid};
      my $ui = user_info($FORM{UID});
      print $ui->{TABLE_SHOW};
    }
  }

  if ($FORM{make_new}) {
    my $old_reply = $Msgs->messages_reply_list({ ID => $FORM{make_new}, COLS_NAME => 1, COLS_UPPER => 1 });
    my $reply_text = $old_reply->[0]->{TEXT};
    $old_reply->[0]->{TEXT} =~ s/^/>  /g;
    $old_reply->[0]->{TEXT} =~ s/\n/\n> /g;
    $old_reply->[0]->{TEXT} .= "\n $lang{CREATE_TOPIC_MESSAGE}";

    $Msgs->message_add({
      USER_SEND => 1,
      UID       => $FORM{UID},
      MESSAGE   => "$lang{AUTO_CREATE_TEXT}: [[$FORM{chg}]]\n$reply_text",
      SUBJECT   => $FORM{COMMENTS},
      CHAPTER   => $FORM{chapter},
      PRIORITY  => 2,
      #TODO More fields maybe
    });

    $Attachments->attachment_copy($FORM{make_new}, $Msgs->{MSG_ID}, $FORM{UID});

    $old_reply->[0]->{TEXT} .= "\n$lang{NEW_TOPIC}: [[$Msgs->{MSG_ID}]]";
    $Msgs->message_reply_change($old_reply->[0]);
  }

  if ($FORM{reply_del} && $FORM{COMMENTS}) {
    if ($FORM{SURVEY_ID} && $FORM{CLEAN}) {
      $Msgs->survey_answer_del({ SURVEY_ID => $FORM{SURVEY_ID}, UID => $FORM{UID}, %FORM });
    }
    else {
      $Msgs->message_reply_del({ ID => $FORM{reply_del} });
    }
    $html->message('info', $lang{INFO}, "$lang{DELETED}  [$FORM{reply_del}] ") if (!$Msgs->{errno});
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  print msgs_status_bar({
    NO_UID      => ($FORM{UID}) ? undef : 1,
    TABS        => 1,
    NEXT        => 1,
    MSGS_STATUS => $msgs_status
  });

  $Msgs->message_info($message_id);
  if (_error_show($Msgs)) {
    return 1;
  }
  elsif ($FORM{chg} && !($Msgs->{ID})) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}");
    return 1;
  }

  if ($permissions{7} && $permissions{7}->{1}) {
    $Msgs->{EDIT} = $html->button(
      "$lang{EDIT}", "",
      { class => 'btn btn-default btn-xs reply-edit-btn', ex_params => "reply_id='m$message_id'" }
    );
  }
  $Msgs->{MAIN_ID} = $Msgs->{ID};
  $Msgs->{ACTION} = 'reply';
  $Msgs->{LNG_ACTION} = $lang{REPLY};
  $Msgs->{STATE} //= 0;
  $Msgs->{PRIORITY} //= 0;
  $Msgs->{CHAPTER} //= 0;
  $Msgs->{STATE_NAME} = $html->color_mark($msgs_status->{ $Msgs->{STATE} });

  $Msgs->{STATE_SEL} = $html->form_select('STATE', {
    SELECTED     => $Msgs->{STATE} || 0,
    SEL_HASH     => $msgs_status,
    SORT_KEY_NUM => 1,
    USE_COLORS   => 1,
    NO_ID        => 1
  });

  $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);
  $Msgs->{PRIORITY_SEL} = $html->form_select('PRIORITY', {
    SELECTED     => $Msgs->{PRIORITY} || 2,
    SEL_ARRAY    => \@priority,
    STYLE        => \@priority_colors,
    ARRAY_NUM_ID => 1
  });

  $Msgs->{DELIGATED} = '-';
  $Msgs->{DELIGATED} = $CHAPTERS_DELIGATION->{ $Msgs->{CHAPTER} } + 1 if (defined($CHAPTERS_DELIGATION->{ $Msgs->{CHAPTER} }));
  $Msgs->{DELIGATED_DOWN} = 0;

  $Msgs->{CHAPTERS_SEL} = $html->form_select('CHAPTER_ID', {
    SELECTED       => '',
    SEL_LIST       => $Msgs->chapters_list({ CHAPTER => join(',', keys %{$A_PRIVILEGES}), COLS_NAME => 1 }),
    MAIN_MENU      => get_function_index('msgs_chapters'),
    MAIN_MENU_ARGV => "chg=$Msgs->{CHAPTER}",
    SEL_OPTIONS    => { '' => '--' },
  });

  $Msgs->{RESPOSIBLE_SEL} = sel_admins({
    NAME       => 'RESPOSIBLE',
    RESPOSIBLE => $Msgs->{RESPOSIBLE},
    DISABLE    => ($Msgs->{RESPOSIBLE}) ? undef : 0,
  });

  $Msgs->{DISPATCH_ID} //= 0;
  $Msgs->{DISPATCH_SEL} = $html->form_select('DISPATCH_ID', {
    SELECTED       => $Msgs->{DISPATCH_ID} || 0,
    SEL_LIST       => $Msgs->dispatch_list({ COMMENTS => '_SHOW', STATE => 0, COLS_NAME => 1 }),
    SEL_KEY        => 'id',
    SEL_VALUE      => 'comments',
    MAIN_MENU      => get_function_index('msgs_dispatches'),
    MAIN_MENU_ARGV => "chg=$Msgs->{DISPATCH_ID} ",
    SEL_OPTIONS    => { 0 => '--' },
  });

  $users->pi({ UID => $FORM{UID} });

  $Msgs->{MSG_CLOSED_DATE} = $html->form_input('MSG_CLOSED_DATE', "");
  $Msgs->{INNER_MSG_TEXT} = ($Msgs->{INNER_MSG})
    ? $html->element(
    'span', '',
    { class => 'btn btn-warning', ICON => 'glyphicon glyphicon-sunglasses', title => $lang{INNER} }
  )
    : '';
  $Msgs->{MAP} = msgs_maps2({ %{$Msgs}, %{$users} });

  $Msgs->msg_watch_list({ MAIN_MSG => $Msgs->{ID}, AID => $admin->{AID} });
  my $uid = $Msgs->{UID} || 0;
  if ($Msgs->{TOTAL} > 0) {
    $Msgs->{WATCH_BTN} = $html->button('',
      "index=$index&UID=$uid&WATCH=1&ID=$message_id&change=1&del=1",
      { class   => 'btn btn-info',
        ICON    => 'glyphicon glyphicon-eye-close',
        CONFIRM => "$lang{UNDO} $lang{WATCH}" });
  }
  else {
    $Msgs->{WATCH_BTN} = $html->button('', "index=$index&UID=$uid&WATCH=1&ID=$message_id&change=1",
      { class => 'btn btn-default', ICON => 'glyphicon glyphicon-eye-open', TITLE => $lang{WATCH} });
  }

  $Msgs->{EXPORT_BTN} = $html->button('', "index=$index&UID=$uid&export=1&ID=$message_id&change=1"
    , { class => 'btn btn-default', ICON => 'glyphicon glyphicon-export', TITLE => $lang{EXPORT} });
  $Msgs->{ID} //= 0;
  $Msgs->{SHEDULE_TABLE_OPEN} = "?index=" . get_function_index('msgs_shedule2') . "&ID=$Msgs->{ID}&DATE=";
  if (in_array('Storage', \@MODULES)) {
    $Msgs->{STORAGE_BTN} = $html->button('', "index=$index&UID=$uid&STORAGE_MSGS_ID=$message_id"
      , { class => 'btn btn-default', ICON => 'glyphicon glyphicon-paperclip', TITLE => "ТМЦ" });
  }
  $Msgs->{WORK_BTN} = msgs_work({ MESSAGE_ID => $message_id });
  $Msgs->{HISTORY_BTN} = $html->button('', "index=$index" . "&MSG_HISTORY=$message_id"
    , { class => 'btn btn-default ', ICON => 'glyphicon glyphicon-time', TITLE => $lang{LOG} });

  if (in_array('Workplanning', \@MODULES)) {
    $Msgs->{WORKPLANNING_BTN} = $html->button('',
      "index=" . get_function_index('work_planning_add') . "&MSG_WORKPLANNING=$message_id"
      , { class => 'btn btn-default ', ICON => 'glyphicon glyphicon-plus', TITLE => $lang{ADD_WORKPLANNING} });
  }

  $Msgs->{MSG_PRINT_BTN} = $html->button(
    '',
    "qindex=$index&UID=$uid&MSG_PRINT_ID=$message_id&header=2" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
    { class => 'btn btn-default',
      ICON  => 'glyphicon glyphicon-print print',
      TITLE => $lang{PRINT}, ex_params => 'target=new'
    }
  );

  if ($permissions{4} || $conf{MSGS_TAGS_NON_PRIVILEGED}) {
    $Msgs->{ADD_TAGS_BTN} = $html->button('',
      'qindex=' . get_function_index('msgs_quick_replys_tags') . "&header=2&MSGS_ID=$message_id&UID=$uid",
      {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-default',
        ICON          => 'glyphicon glyphicon-tags',
        TITLE         => $lang{MSGS_TAGS},
      }
    );
  }

  if ($conf{MSGS_TASKS}) {
    require Msgs::Tasks;
    $Msgs->{MSGS_TASK_BTN} = $html->button('',
      'index=' . $index . "&header=2&MSGS_ID=$message_id&UID=$uid&TASK=$message_id",
      {
        class => 'btn btn-default btn-info',
        ICON  => 'glyphicon glyphicon-briefcase',
      }
    );
  }

  my $execution_time_input = $html->form_datetimepicker(
    'PLAN_DATETIME',
    (
      ($Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00' ? $Msgs->{PLAN_DATE}
        . ' '
        . ($Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00' ? $Msgs->{PLAN_TIME} : '00:00') : '')
    ),
    {
      ICON           => 1,
      TIME_HIDDEN_ID => 'PLAN_TIME',
      DATE_HIDDEN_ID => 'PLAN_DATE',
      EX_PARAMS      => q{pattern='^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'},
    }
  );

  if ($conf{MSGS_TASKS}) {
    $Msgs->{TASKS_LIST} = msgs_tasks_list($message_id);
  }

  if ($Msgs->{LOCATION_ID} && !($Msgs->{ADDRESS_BUILD} && $Msgs->{ADDRESS_STREET})) {
    $Address->address_info($Msgs->{LOCATION_ID});
    if ($Address->{TOTAL}) {
      $Msgs->{ADDRESS_BUILD} = $Address->{ADDRESS_BUILD};
      $Msgs->{ADDRESS_STREET} = $Address->{ADDRESS_STREET};
    }
  }

  my $ticket_address = '';
  if ($conf{MSGS_ADDRESS}) {
    $ticket_address = msgs_address({ %FORM });
  }

  $Msgs->{EXT_INFO} = $html->tpl_show(_include($msgs_managment_tpl, 'Msgs'), {
    %{$users},
    %{$Msgs},
    PHONE               => $users->{PHONE} || $users->{CELL_PHONE} || '--',
    PLAN_DATETIME_INPUT => $execution_time_input,
    TICKET_ADDRESS      => $ticket_address,
  },
    { OUTPUT2RETURN => 1 });

  my $REPLIES = msgs_ticket_reply($message_id);

  $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, json => $FORM{json}, SHOW_URL => 1 });
  $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });

  my $msgs_rating_message = '';
  my $rating_icons = '';
  if ($Msgs->{RATING} && $Msgs->{RATING} > 0) {
    for (my $i = 0; $i < $Msgs->{RATING}; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star' });
    };
    for (my $i = 0; $i < 5 - $Msgs->{RATING}; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star-o' });
    };

    my $sig_image = '';
    if ($conf{TPL_DIR} && $Msgs->{UID} && $message_id) {
      my $sig_path = "$conf{TPL_DIR}/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png";
      if (-f $sig_path) {
        $sig_image = $html->img("/images/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png", 'signature');
      }
    }

    push @{$REPLIES}, $msgs_rating_message = $html->tpl_show(_include('msgs_rating_admin_show', 'Msgs'), {
      %{$Msgs},
      RATING_ICONS   => $rating_icons,
      RATING_COMMENT => $Msgs->{RATING_COMMENT},
      SIGNATURE      => $sig_image,
    },
      { OUTPUT2RETURN => 1,
      }
    );
  }

  my %params = ();
  if (!$Msgs->{ACTIVE_SURWEY} && ($A_PRIVILEGES->{ $Msgs->{CHAPTER} } || scalar keys %{$A_PRIVILEGES} == 0)) {
    my $survey_sel = msgs_survey_sel();
    $params{REPLY_FORM} = $html->tpl_show(
      _include('msgs_reply', 'Msgs'),
      {
        %{$Msgs},
        REPLY_TEXT      => "",
        QUOTING         => $Msgs->{REPLY_QUOTE} || '',
        RUN_TIME_FORM   => $html->tpl_show(
          templates('form_row'),
          {
            ID    => "RUN_TIME",
            NAME  => "$lang{RUN_TIME} (mins.)",
            VALUE => $html->form_input('RUN_TIME', '00:00:00',
              { EX_PARAMS => " STYLE='background-color:  $_COLORS[3]' DISABLED  size=9" })
          },
          { OUTPUT2RETURN => 1 }
        ),
        RUN_TIME_STATUS => 'DISABLE',
        MAIN_INNER_MSG  => $Msgs->{INNER_MSG},
        INNER_MSG       => ($FORM{INNER_MSG}) ? ' checked ' : '',
        SURVEY_SEL      => $survey_sel
      },
      { OUTPUT2RETURN => 1, ID => 'MSGS_REPLY', NO_SUBJECT => $lang{NO_SUBJECT} }
    );
  }

  $params{REPLY} = join(($FORM{json}) ? ',' : '', @{$REPLIES});

  if ($Msgs->{FILENAME}) {
    my $attachments_list = $Msgs->attachments_list({
      MESSAGE_ID   => $Msgs->{ID},
      FILENAME     => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COORDX       => '_SHOW',
      COORDY       => '_SHOW',
    });

    $Msgs->{ATTACHMENT} = msgs_get_attachments_view($attachments_list);
  }

  if ($Msgs->{PRIORITY} == 4) {
    $params{MAIN_PANEL_COLOR} = 'box-danger';
  }
  elsif ($Msgs->{PRIORITY} == 3) {
    $params{MAIN_PANEL_COLOR} = 'box-warning';
  }
  elsif ($Msgs->{PRIORITY} >= 1) {
    $params{MAIN_PANEL_COLOR} = 'box-info';
  }
  else {
    $params{MAIN_PANEL_COLOR} = 'box-primary';
  }

  my $msg_tags_list = $Msgs->quick_replys_tags_list({ MSG_ID => $message_id, COLOR => '_SHOW', COLS_NAME => 1 });
  if ($Msgs->{TOTAL}) {
    foreach my $msg_tag (@{$msg_tags_list}) {
      $params{MSG_TAGS} .= ' ' . $html->element('span', $msg_tag->{reply}, {
        'class' => 'label new-tags',
        'style' => "background-color:" . ($msg_tag->{color} || q{}) . ";border-color:". ($msg_tag->{color} || q{}) .";font-weight: bold;"
      });
    }
  }
  else {
    $params{MSG_TAGS_DISPLAY_STATUS} = 1;
    $params{MSG_TAGS} = $html->button('',
      'qindex=' . get_function_index('msgs_quick_replys_tags') . "&header=2&MSGS_ID=$message_id&UID=$uid",
      {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-xs btn-danger',
        ICON          => 'glyphicon glyphicon-tags',
        TITLE         => "$lang{ADD} $lang{TAGS}"
      }
    );
  }

  $Msgs->{ID} = $Msgs->{MAIN_ID};

  while ($Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/) {
    my $msg_button = $html->button($1, "&index=$index&chg=$1",
      { class => 'badge bg-blue' });
    $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
  }
  # Button for subject chaning
  if (scalar keys %{$A_PRIVILEGES} == 0 || ($Msgs->{CHAPTER} && $A_PRIVILEGES->{$Msgs->{CHAPTER}} && $A_PRIVILEGES->{$Msgs->{CHAPTER}} == 3)) {
    $params{CHANGE_SUBJECT_BUTTON} = $html->button("$lang{CHANGE} $lang{SUBJECT}",
      "qindex=" . get_function_index('_msgs_show_change_subject_template') . "&header=2&subject=" . ($Msgs->{SUBJECT} || q{}) . "&msg_id=$Msgs->{ID}",
      {
        LOAD_TO_MODAL  => 1,
        NO_LINK_FORMER => 1,
        class          => 'change',
        TITLE          => $lang{SUBJECT}
      }
    );
  }
  elsif($Msgs->{CHAPTER} && ! $A_PRIVILEGES->{$Msgs->{CHAPTER}}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY}, { ID => 791 });
    return 0;
  }

  $params{PROGRESSBAR} = msgs_progress_bar_show($Msgs);

  if (in_array('Workplanning', \@MODULES)) {
    $params{WORKPLANNING} = work_planning_table_show($message_id);
  }

  #Parent
  if ($Msgs->{PAR}) {
    $params{PARENT_MSG} = $html->button('PARENT: ' . $Msgs->{PAR}, 'index=' . $index . "&chg=$Msgs->{PAR}",
      { class => 'btn btn-xs btn-default text-right' });
  }
  $params{RATING_ICONS} = $rating_icons;
  $params{LOGIN} = ($Msgs->{AID}) ? $html->b($Msgs->{A_NAME}) . " ($lang{ADMIN})" : $html->button($Msgs->{LOGIN},
    "index=15&UID=$uid");
  $params{ADMIN_LOGIN} = $admin->{A_LOGIN};

  $html->tpl_show(_include($msgs_show_tpl, 'Msgs'), { %{$Msgs}, %params });

  if (!$FORM{quick}
    && (!$Msgs->{RESPOSIBLE} || ($Msgs->{RESPOSIBLE} =~ /^\d+$/ && $Msgs->{RESPOSIBLE} == $admin->{AID}))
  ) {
    $Msgs->message_change({
      UID        => $uid,
      ID         => $message_id,
      ADMIN_READ => "$DATE $TIME",
      SKIP_LOG   => 1
    });
  }

  if($conf{MSGS_CHAT}) {
    require Msgs::Chat;
    show_admin_chat();
  }

  return 1;
}
#**********************************************************
=head2 msgs_ticket_reply

=cut
#**********************************************************
sub msgs_ticket_reply {
  my ($message_id) = @_;

  my $uid = $Msgs->{UID} || 0;
  my @REPLIES = ();
  my $msgs_reply_show_tpl = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_reply_show_simplified_mode' : 'msgs_reply_show';

  if ($Msgs->{SURVEY_ID}) {
    my $main_message_survey = msgs_survey_show({
      SURVEY_ID => $Msgs->{SURVEY_ID},
      MSG_ID    => $Msgs->{ID},
      MAIN_MSG  => 1,
    });

    if ($main_message_survey) {
      push @REPLIES, $main_message_survey;
    }

  }

  my $list = $Msgs->messages_reply_list({
    MSG_ID    => $Msgs->{ID},
    COLS_NAME => 1
  });

  my $total_reply = $Msgs->{TOTAL};

  if (!$Msgs->{TOTAL} || $Msgs->{TOTAL} < 1) {
    $Msgs->{REPLY_QUOTE} = '> ' . ($Msgs->{MESSAGE} || q{});
  }

  foreach my $line (@{$list}) {
    if ($line->{survey_id}) {
      $FORM{REPLY_ID} = $line->{id};
      push @REPLIES, msgs_survey_show({
        SURVEY_ID => $line->{survey_id},
        REPLY_ID  => $line->{id},
        MSG_ID    => $Msgs->{ID},
        TEXT      => $line->{text},
      });

      delete($Msgs->{SURVEY_ID});
      next;
    }

    if ($FORM{QUOTING} && $FORM{QUOTING} == $line->{id}) {
      $Msgs->{REPLY_QUOTE} = '>' . $line->{text};
    }

    my $reply_color = 'box-theme';
    if ($conf{MSGS_SIMPLIFIED_MODE}) {
      if ($line->{inner_msg}) {
        $reply_color = 'bg-yellow';
      }
      elsif ($line->{aid} > 0) {
        $reply_color = 'bg-green';
      }
      else {
        $reply_color = 'bg-aqua';
      }
    }
    else {
      if ($line->{inner_msg}) {
        $reply_color = 'box-warning';
      }
      elsif ($line->{aid} > 0) {
        $reply_color = 'box-success';
      }
    }

    my $new_topic_button = '';
    my $edit_reply_button = '';
    if ($permissions{7} && $permissions{7}->{1} && $uid) {
      $new_topic_button = $html->button($lang{CREATE_NEW_TOPIC},
        "&index=$index&chg=$message_id&UID=$uid&make_new=$line->{id}&chapter=$Msgs->{CHAPTER}",
        { MESSAGE => "$lang{NEW_TOPIC}?", BUTTON => 1 }
      );
      $edit_reply_button = $html->button(
        "$lang{EDIT}", "",
        { class => 'btn btn-default btn-xs reply-edit-btn', ex_params => "reply_id='$line->{id}'" }
      );
    }

    my $del_reply_button = $html->button(
      $lang{DEL},
      "&index=$index&chg=$message_id&reply_del=$line->{id}&UID=$uid",
      { MESSAGE => "$lang{DEL}  $line->{id}?", BUTTON => 1 }
    );

    my $quote_button = $html->button(
      $lang{QUOTING}, "",
      { class => 'btn btn-default btn-xs quoting-reply-btn', ex_params => "quoting_id='$line->{id}'" }
    );

    my $run_time = ($line->{run_time} && $line->{run_time} ne '00:00:00') ? "$lang{RUN_TIME}: $line->{run_time}" : '';

    my $attachment_html = '';
    if ($line->{attachment_id}) {
      my $attachments_list = $Msgs->attachments_list({
        REPLY_ID     => $line->{id},
        FILENAME     => '_SHOW',
        CONTENT_SIZE => '_SHOW',
        CONTENT_TYPE => '_SHOW',
        COORDX       => '_SHOW',
        COORDY       => '_SHOW',
      });

      $attachment_html = msgs_get_attachments_view($attachments_list);
    }

    push @REPLIES, $html->tpl_show(
      _include($msgs_reply_show_tpl, 'Msgs'),
      {
        ADMIN_MSG  => $line->{aid},
        LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
        REPLY_ID   => $line->{id},
        DATE       => $line->{datetime},
        PERSON     => ($line->{creator_id} || q{}) . ' ' .
          (($line->{aid})
            ? " ($lang{ADMIN})"
            . (($line->{inner_msg})
            ? "  $lang{PRIVATE}"
            : '')
            : ""),
        MESSAGE    => msgs_text_quoting($line->{text}, 1),
        QUOTING    => $quote_button,
        NEW_TOPIC  => $new_topic_button,
        EDIT       => $edit_reply_button,
        DELETE     => $del_reply_button,
        ATTACHMENT => $attachment_html,
        COLOR      => $reply_color,
        RUN_TIME   => $run_time,
      },
      { OUTPUT2RETURN => 1, ID => $line->{id} },
    );
  }

  if ($Msgs->{REPLY_QUOTE}) {
    if ($FORM{json}) {
      $Msgs->{REPLY_QUOTE} = '';
    }
    else {
      $Msgs->{REPLY_QUOTE} =~ s/\n/> /g;
    }
  }

  return \@REPLIES;
}


#**********************************************************
=head2 _msgs_change_responsible($message_id, $new_responsible_aid, $attr)

  Arguments:
    $message_id
    $new_responsible_aid
    $attr

=cut
#**********************************************************
sub _msgs_change_responsible {
  my ($message_id, $new_responsible_aid, $attr) = @_;

  # Check for test
  return 0 unless ($message_id);

  my $message_info = $attr->{MESSAGE_INFO};

  # Check we have all information we need
  my $given_message_has_all_required_info = (
    ($message_info && ref $message_info eq 'HASH')
      && (defined $message_info->{subject})
      && (defined $message_info->{resposible})
      && (defined $message_info->{message})
  );

  # If there is not enough, get it ourselves
  if (!$given_message_has_all_required_info) {
    my $message_info_list = $Msgs->messages_list({
      MSG_ID     => $message_id,
      RESPOSIBLE => '_SHOW',
      MESSAGE    => '_SHOW',
      SUBJECT    => '_SHOW',
      UID        => '_SHOW',
      COLS_NAME  => 1
    });
    return 0 if ($Msgs->{errno} || !$Msgs->{TOTAL});
    $message_info = $message_info_list->[0];
  }

  my $previous_responsible_aid = $message_info->{resposible} || 0;

  # Check if it's really changed
  if ($previous_responsible_aid eq $new_responsible_aid) {
    return 1
  }

  # Change resposible in DB
  if (!$attr->{SKIP_CHANGE}) {
    $Msgs->message_change({
      ID         => $message_id,
      RESPOSIBLE => $new_responsible_aid
    });
    return 0 if ($Msgs->{errno});
  }

  # Check if now we have resposible and if this is not admin who changes
  return 1 if (!$new_responsible_aid || ($admin->{AID} eq $new_responsible_aid));

  # Send notification if Telegram available
  if ($conf{TELEGRAM_TOKEN}) {
    # Safe section
    eval {
      require Msgs::Messaging;
      my $subject = $message_info->{subject} || '';
      my $first_message_for_mess = $message_info->{message} || '';

      return msgs_send_via_telegram($message_id, {
        AID         => $new_responsible_aid,
        SUBJECT     => $lang{YOU_HAVE_BEEN_SET_AS_RESPONSIBLE_IN} . " <b>'$subject'</b>",
        MESSAGE     => $first_message_for_mess || '',
        SENDER_UID  => $message_info->{uid},
        SENDER_TYPE => $Contacts::TYPES{TELEGRAM},
        PARSE_MODE  => 'HTML'
      });
    };
  }
  else {
    msgs_notify_admins({
      MSGS_ID       => $message_id,
      SKIP_TELEGRAM => 1,
      AID           => $new_responsible_aid
    });
  }

  return 1;
}

#**********************************************************
=head2 msgs_work($attr)

  Arguments:
     $attr
       WORK_LIST
       MESSAGE_ID

  Returns:

=cut
#**********************************************************
sub msgs_work {
  my ($attr) = @_;

  if (!in_array('Employees', \@MODULES)) {
    return q{};
  }

  if ($attr->{WORK_LIST}) {
    load_module('Employees', $html);
    if ($attr->{MNG}) {
      return employees_works({ EXT_ID => $attr->{MESSAGE_ID}, UID => $attr->{UID} });
    }
    else {
      delete $FORM{index};
      return employees_works_list({
       EXT_ID => $attr->{MESSAGE_ID},
       UID    => $attr->{UID},
       INDEX  => $index,
       chg    => $FORM{chg}
     });
    }
  }

  return $html->button('', "index=$index&UID=$Msgs->{UID}&WORK=$attr->{MESSAGE_ID}",
    { class => 'btn btn-default', ICON => 'glyphicon glyphicon-wrench', TITLE => $lang{WORK} });
}

#**********************************************************
=head2 msgs_storage()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub msgs_storage {
  if (!in_array('Storage', \@MODULES)) {
    return q{};
  }

  $LIST_PARAMS{MSGS_ID} = $FORM{chg};

  result_former(
    {
      INPUT_DATA      => $Msgs,
      FUNCTION        => 'msgs_storage_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, ARTICLE_TYPE_NAME, ARTICLE_NAME, COUNT_MEASURE, SERIAL, ADMIN_NAME, DATE",
      HIDDEN_FIELDS   => 'MSGS_ID',
      FUNCTION_FIELDS => '',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'id'                => "ID",
        'article_name'      => $lang{NAME},
        'article_type_name' => "$lang{TYPE} $lang{NAME}",
        'count_measure'     => $lang{COUNT},
        'serial'            => 'SN',
        'admin_name'        => $lang{ADMIN},
        'date'              => $lang{DATE},
      },
      FILTER_COLS     => {
        count_measure => '_translate',
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{STORAGE},
        qs      => $pages_qs,
        ID      => 'MSGS_STORAGE_ITEMS',
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Msgs',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );

}

#**********************************************************
=head2 msgs_export($attr); - Export to other systems


=cut
#**********************************************************
sub msgs_export {
  #my ($attr) = @_;

  if ($FORM{_export}) {
    require Msgs::Export_redmine;
    Export_redmine->import();

    my $Export_redmine = Export_redmine->new($db, $admin, \%conf);

    $Export_redmine->export_task(\%FORM);
    my $task_link = ($Export_redmine->{TASK_LINK}) ? $html->button($Export_redmine->{TASK_ID}, '', { GLOBAL_URL => $Export_redmine->{TASK_LINK} }) : $Export_redmine->{TASK_ID};
    if(! _error_show($Export_redmine, { MESSAGE => $task_link })) {
      if ($Export_redmine->{TASK_ID}) {
        $html->message('info', $lang{ADDED}, "$lang{ADDED}: "
          . $task_link
        );
      }
    }

    my $list = $Export_redmine->task_list();
    my $table;

    ($table, $list) = result_former(
      {
        TABLE         => {
          width            => '100%',
          caption          => 'Redmine tasks',
          SHOW_COLS_HIDDEN => {
          },
          ID               => 'MSGS_REDMINE_LIST',
        },
        DATAHASH      => $Export_redmine->{RESULT}->{issues},
        SKIPP_UTF_OFF => 1,
        TOTAL         => 1
      }
    );
  }

  $Msgs->message_info($FORM{ID});
  $Msgs->{ACTION} = '_export';
  $Msgs->{LNG_ACTION} = $lang{EXPORT};

  $Msgs->{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $Msgs->{EXPORT_SYSTEM_SEL} = $html->form_select(
    'EXPORT',
    {
      SELECTED  => 'redmine',
      SEL_ARRAY => [ 'redmine' ],
    }
  );

  $html->tpl_show(_include('msgs_export', 'Msgs'), $Msgs);

  return 1;
}


#**********************************************************
=head2 msgs_employee_tasks_map() - show tasks for employee on map

=cut
#**********************************************************
sub msgs_employee_tasks_map {
  my $aid = $FORM{AID} || $admin->{AID};
  my $date = $FORM{DATE} || $DATE;
  my $date_type = $FORM{DATE_TYPE} // 'PLAN_DATE';
  my @date_types = (
    { name => $lang{ALL}, id => '' },
    { name => $lang{CREATED}, id => 'DATE' },
    { name => $lang{PLANNED}, id => 'PLAN_DATE' },
    { name => $lang{DONE}, id => 'DONE_DATE' },
  );
  my $state_name_list = $Msgs->status_list({ NAME => '_SHOW', COLS_NAME => 1 });
  _error_show($Msgs) and return 0;
  my %state_name = map {$_->{id} => _translate($_->{name} || '')} @{$state_name_list};

  my $admin_select = sel_admins();

  my $date_type_select = $html->form_select('DATE_TYPE', {
    SELECTED => $date_type,
    SEL_LIST => \@date_types,
    NO_ID    => 1
  });

  #show panel for choosing admin and date
  $html->tpl_show(
    _include('msgs_map_employee_tasks', 'Msgs'),
    {
      AID_SELECT       => $admin_select,
      DATE_TYPE_SELECT => $date_type_select
    }
  );

  # if no employee choosed, then
  return 1 unless ($aid);

  # if employee chosed, find all tasks for given date or today if no date
  my $tasks = $Msgs->messages_list(
    {
      RESPOSIBLE  => $aid,
      LOGIN       => '_SHOW',
      $date_type  => $date,
      LOCATION_ID => '_SHOW',
      STATE       => '_SHOW',
      COLS_NAME   => 1
    });

  _error_show($Msgs);

  my %tasks_by_location = ();
  foreach my $task (@{$tasks}) {

    if ($tasks_by_location{$task->{build_id}}) {
      push @{$tasks_by_location{$task->{build_id}}}, $task;
    }
    else {
      $tasks_by_location{$task->{build_id}} = [ $task ];
    }

    $task->{location_id} = $task->{build_id};
    $task->{state} = $state_name{$task->{state}} || '--';

    delete $task->{build_id};
    #delete $task->{user_name};
  }

  load_module("Maps", $html);

  # enable GPS marker for this AID
  $FORM{show_gps} = $aid;
  $FORM{DATE} = $date;

  # Show a map
  maps_show_map({
    QUICK                 => 1,
    DATA                  => \%tasks_by_location,
    HIDE_ALL_LAYERS       => 1,
    LOCATION_TABLE_FIELDS => 'ID,LOGIN,SUBJECT,STATE',
  });

  return 1;
}

#**********************************************************
=head1 msgs_survey_sel($attr)

=cut
#**********************************************************
sub msgs_survey_sel {
  my $list = $Msgs->survey_subjects_list({ PAGE_ROWS => 10000, COLS_NAME => 1 });

  if ($Msgs->{TOTAL} > 0) {
    return $html->form_select(
      'SURVEY_ID',
      {
        SELECTED       => '' || $FORM{SURVEY_ID},
        SEL_LIST       => $list,
        SEL_OPTIONS    => { '' => '' },
        MAIN_MENU      => get_function_index('msgs_survey'),
        MAIN_MENU_ARGV => ($FORM{SURVEY_ID}) ? "chg=$FORM{SURVEY_ID}" : ''
      }
    );
  }

  return '';
}

#**********************************************************
=head2 msgs_maps()

=cut
#**********************************************************
sub msgs_maps {
  my ($Msgs_) = @_;

  if (!$Msgs_->{LOCATION_ID} || !in_array('Maps', \@MODULES)) {
    return '';
  }

  load_module('Maps', $html);

  return maps_show_map({
    QUICK                 => 1,
    DATA                  => {
      $Msgs_->{LOCATION_ID} => [ {
        uid   => $Msgs_->{UID},
        login => $Msgs_->{LOGIN},
        fio   => $Msgs_->{FIO}
      } ]
    },
    LOCATION_TABLE_FIELDS => 'LOGIN,UID,FIO',
    OUTPUT2RETURN         => 1,
    HIDE_ALL_LAYERS       => 1,
    MAP_ZOOM              => 16,
    SMALL                 => 1,
    MAP_HEIGHT            => 25,
    SHOW_BUILD            => $Msgs_->{LOCATION_ID},
    NAVIGATION_BTN        => 1
  });

}

#**********************************************************
=head2 msgs_maps2()

=cut
#**********************************************************
sub msgs_maps2 {
  my ($Msgs_) = @_;

  if (!$Msgs_->{LOCATION_ID} || !in_array('Maps2', \@MODULES)) {
    return msgs_maps($Msgs_);
  }

  load_module('Maps2', $html);

  return maps2_show_map({
    MSGS_MAP              => 1,
    QUICK                 => 1,
    DATA                  => {
      $Msgs_->{LOCATION_ID} => [ {
        uid   => $Msgs_->{UID},
        login => $Msgs_->{LOGIN},
        fio   => $Msgs_->{FIO}
      } ]
    },
    LOCATION_ID           => $Msgs_->{LOCATION_ID},
    LOCATION_TABLE_FIELDS => 'LOGIN,UID,FIO',
    OUTPUT2RETURN         => 1,
    HIDE_ALL_LAYERS       => 1,
    MAP_ZOOM              => 16,
    SMALL                 => 1,
    MAP_HEIGHT            => 25,
    SHOW_BUILD            => $Msgs_->{LOCATION_ID},
    NAVIGATION_BTN        => 1
  });

}

#**********************************************************
=head2 msgs_progress_bar_show($Msgs)

=cut
#**********************************************************
sub msgs_progress_bar_show {
  my Msgs $Msgs_ = shift;

  my $pb_list = $Msgs_->pb_msg_list({
    MAIN_MSG   => $Msgs_->{ID},
    CHAPTER_ID => $Msgs_->{CHAPTER},
    COLS_NAME  => 1
  });

  _error_show($Msgs_);

  if ($Msgs_->{TOTAL} > 0) {
    my $progress_name = '';
    my $cur_step = 0;
    my $tips = '';

    foreach my $line (@{$pb_list}) {
      my $step_map = $line->{step_date} || '';

      if ($line->{coorx1} && $line->{coorx1} + $line->{coordy} > 0) {
        $step_map = $html->button($line->{step_date},
          "index=" . get_function_index('maps_show_map') . "&COORDX=$line->{coordx}&COORDY=$line->{coordy}&TITLE=$line->{step_name}+$line->{step_date}");
      }

      $progress_name .= "['" . ($line->{step_name} || $line->{step_num}) . "', '$step_map' ], ";
      if ($line->{step_date}) {
        $cur_step = $line->{step_num};
        $tips = $line->{step_tip};
      }
    }

    return $html->tpl_show(_include('msgs_progressbar', 'Msgs'), {
      PROGRESS_NAMES => $progress_name,
      CUR_STEP       => $cur_step || 0,
      TIPS           => $tips,
    }, { OUTPUT2RETURN => 1 });
  }

  return '';
}

#**********************************************************
=head2 _msgs_show_change_subject_template()

=cut
#**********************************************************
sub _msgs_show_change_subject_template {

  my $subject = $FORM{subject} || '';
  my $changes_index = get_function_index('msgs_admin');
  my $msg_id = $FORM{msg_id};

  $html->tpl_show(_include('msgs_change_subject', 'Msgs'), {
    SUBJECT => $subject,
    INDEX   => $changes_index,
    ID      => $msg_id,
  }, {});

  return 1;
}

#**********************************************************
=head2 _msgs_edit_reply()

=cut
#**********************************************************
sub _msgs_edit_reply {

  return 1 unless ($permissions{7} && $permissions{7}->{1} && $FORM{edit_reply});

  my $edit_reply = $FORM{edit_reply};
  if ($edit_reply =~ s/^[m]\d+//) {
    my (undef, $msg_id) = split('m', $FORM{edit_reply});

    $Msgs->message_change({
      ID      => $msg_id,
      MESSAGE => $FORM{replyText}
    });

    return 1;
  }

  $Msgs->message_reply_change({
    ID   => $FORM{edit_reply},
    TEXT => $FORM{replyText}
  });

  return 1;
}

#**********************************************************
=head2 work_planning_table_show($message_id)

=cut
#**********************************************************
sub work_planning_table_show {
  my ($message_id) = @_;

  require Workplanning::db::Workplanning;
  Workplanning::db::Workplanning->import();

  my $Workplanning = Workplanning->new($db, $admin, \%conf);

  my $workplanning_list = $Workplanning->list({
    COLS_NAME => 1,
    DESC      => "desc",
    MSGS_ID   => $message_id
  });
  _error_show($Workplanning) and return 0;

  unless (scalar @${workplanning_list}) {
    return 0;
  }

  my $table = $html->table({
    caption => $lang{RELATED_WORK},
    title   => [ "ID", $lang{DATE_OF_CREATION}, $lang{DATE_OF_EXECUTION}, $lang{RESPONSIBLE}, $lang{DESCRIPTION} ],
    qs      => $pages_qs,
    ID      => "TABLE_ID",
    MENU    =>
      "$lang{SEARCH}:index=" . get_function_index('work_planning_add') . "&MSG_WORKPLANNING=$message_id&$pages_qs:add",
    EXPORT  => 1
  }
  );

  foreach my $item (@{$workplanning_list}) {
    $table->addrow(
      $item->{id},
      $item->{date_of_creation},
      $item->{date_of_execution},
      $item->{name},
      $item->{description}
    );
  }

  print $table->show();

  return 1;
}


#**********************************************************
=head2 _msgs_reply_admin()

=cut
#**********************************************************
sub _msgs_reply_admin {
  if ($FORM{RUN_TIME}) {
    my ($h, $min, $sec) = split(/:/, $FORM{RUN_TIME}, 3);
    $FORM{RUN_TIME} = ($h || 0) * 60 * 60 + ($min || 0) * 60 + ($sec || 0);
  }
  my $reply_id;

  if ($FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID}) {

    $Msgs->message_reply_add(
      {
        %FORM,
        AID => $admin->{AID},
        IP  => $admin->{SESSION_IP},
      }
    );
    $reply_id = $Msgs->{INSERT_ID};
    $FORM{REPLY_ID} = $reply_id;

    if (!_error_show($Msgs)) {

      # Fixing empty attachment filename
      if ($FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{'Content-Type'} && !$FORM{FILE_UPLOAD}->{filename}) {
        my $extension = 'dat';
        for my $ext ('jpg', 'jpeg', 'png', 'gif', 'txt', 'pdf') {
          if ($FORM{FILE_UPLOAD}->{'Content-Type'} =~ /$ext/i) {
            $extension = $ext;
            last;
          }
        }
        $FORM{FILE_UPLOAD}->{filename} = 'reply_img_' . $Msgs->{INSERT_ID} . q{.} . $extension
      }

      #Add attachment
      if ($FORM{FILE_UPLOAD}->{filename} && $FORM{ID}) {

        my $attachment_saved = msgs_receive_attachments($FORM{ID}, {
          REPLY_ID => $Msgs->{REPLY_ID},
          UID      => $FORM{UID},
          MSG_INFO => { %$Msgs }
        });

        if (!$attachment_saved) {
          _error_show($Msgs);
          $html->message('err', $lang{ERROR}, "Can't save attachment");
        }
      }

    }
  }

  my %params = ();
  my $msg_state = $FORM{STATE} || 0;
  $params{CHAPTER} = $FORM{CHAPTER_ID} if ($FORM{CHAPTER_ID});
  $params{STATE} = ($msg_state == 0 && !$FORM{MAIN_INNER_MESSAGE} && !$FORM{REPLY_INNER_MSG}) ? 6 : $msg_state;
  $params{CLOSED_DATE} = "$DATE  $TIME" if ($msg_state == 1 || $msg_state == 2);
  $params{DONE_DATE} = $DATE if ($msg_state > 1);

  $Msgs->message_change({
    UID        => $LIST_PARAMS{UID},
    ID         => $FORM{ID},
    USER_READ  => "0000-00-00 00:00:00",
    ADMIN_READ => "$DATE $TIME",
    %params
  });

  if ($FORM{STEP_NUM}) {

    my $chapter = $Msgs->pb_msg_list(
      {
        MAIN_MSG           => $FORM{ID},
        CHAPTER_ID         => $FORM{CHAPTER},
        STEP_NUM           => $FORM{STEP_NUM},
        USER_NOTICE        => '_SHOW',
        RESPONSIBLE_NOTICE => '_SHOW',
        FOLLOWER_NOTICE    => '_SHOW',
        COLS_NAME          => 1,
      }
    );

    if (!defined($Msgs->{TOTAL})) {
      $Msgs->msg_watch_info($FORM{ID});
      my $watch_aid = $Msgs->{AID};

      my %send_msgs = (
        SUBJECT => $chapter->[0]->{step_name},
        MESSAGE => $FORM{REPLY_TEXT} || "$lang{CHAPTER} $chapter->[0]->{step_name} $lang{DONE}",
      );

      foreach my $chapter_info (@{$chapter}) {
        if ($chapter_info->{user_notice} && $FORM{UID}) {
          $Sender->send_message({ UID => $FORM{UID}, SENDER_TYPE => 'Mail', %send_msgs });
        }
        elsif ($chapter_info->{responsible_notice} && $FORM{RESPOSIBLE}) {
          $Sender->send_message({ AID => $FORM{RESPOSIBLE}, %send_msgs });
        }
        elsif ($chapter_info->{follower_notice} && $watch_aid) {
          $Sender->send_message({ AID => $watch_aid, %send_msgs });
        }
      }
    }

    $Msgs->pb_msg_change(\%FORM);
  }

  $FORM{chg} = $FORM{ID};
  if (_error_show($Msgs)) {
    return 0;
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  $Msgs->message_info($FORM{ID});

  msgs_notify_user({
    UID        => $FORM{UID},
    STATE_ID   => $Msgs->{STATE},
    STATE      => $msgs_status->{$Msgs->{STATE}},
    REPLY_ID   => $reply_id,
    MSG_ID     => $FORM{ID},
    MSGS       => $Msgs,
    SENDER_AID => $admin->{AID},
  });

  if (!$FORM{RESPOSIBLE}) {
    $Msgs->message_change({
      RESPOSIBLE => $admin->{AID},
      ID         => $FORM{ID},
    });
  }

  msgs_notify_admins({
    STATE      => $msgs_status->{$Msgs->{STATE}},
    SENDER_AID => $admin->{AID},
    MSG_ID     => $FORM{ID},
    MSGS       => $Msgs,
  });

  my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
  $html->redirect("?index=$index"
    . "&UID=" . ($FORM{UID} || q{})
    . "&chg=" . ($FORM{ID} || q{})
    . "&MESSAGE=$header_message#last_msg",
    {
      MESSAGE_HTML => $html->message('info', $lang{INFO}, "$lang{REPLY}", { OUTPUT2RETURN => 1 }),
      WAIT         => '0'
    }
  );

  return 1;
}

#**********************************************************
=head2 msgs_dispatch_admins($attr) - dispatch admins for adding dispatch

  Arguments:
    DISPATCH_ID - Dispatch id at msgs_dispatch_admins

  Returns:
    true or html code

=cut
#**********************************************************
sub msgs_dispatch_admins {
  my ($attr) = @_;
  my $admins_list = '';
  my $admins_list2 = '';

  if ($attr->{ADD} || $attr->{CHANGE}) {
    $Msgs->dispatch_admins_change($attr);
    return 1;
  }

  my $list = $Msgs->dispatch_admins_list({
    DISPATCH_ID => $attr->{DISPATCH_ID} || $FORM{chg},
    COLS_NAME   => 1
  });

  my %active_admins = ();
  foreach my $line (@$list) {
    $active_admins{ $line->{aid} } = 1;
  }

  $list = $admin->list({ %LIST_PARAMS, DISABLE => 0, COLS_NAME => 1, PAGE_ROWS => 1000 });

  my $checkbox = '';
  my $label = '';
  my $div_checkbox = '';

  my $count = 1;
  foreach my $line (@$list) {
    $checkbox = $html->form_input('AIDS', $line->{aid}, {
      class => 'list-checkbox',
      TYPE  => 'checkbox',
      STATE => ($active_admins{ $line->{aid} }) ? 1 : undef
    }) . " " . ($line->{name} || q{}) . ' : ' . ($line->{login} || q{});

    $label = $html->element('label', $checkbox);
    $div_checkbox = $html->element('li', $checkbox, { class => 'list-group-item' });
    if ($attr->{TWO_COLUMNS}) {
      $admins_list .= $div_checkbox if ($count % 2 != 0);
      $admins_list2 .= $div_checkbox if ($count % 2 == 0);
      $count++;
    }
    else {
      $admins_list .= $div_checkbox;
    }
  }

  return { AIDS => $admins_list, AIDS2 => $admins_list2 } if $attr->{TWO_COLUMNS};
  return $admins_list;
}

#**********************************************************
=head2 msgs_repeat_ticket($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub msgs_repeat_ticket {

  my $answer = "";
  if ($FORM{LOCATION_ID} && !$FORM{UID}) {
    my $msgs_list = $Msgs->messages_list({
      DATE                   => $DATE,
      LOCATION_ID_MSG        => $FORM{LOCATION_ID},
      ADDRESS_BY_LOCATION_ID => '_SHOW',
      COLS_NAME              => 1,
    });

    $answer = $Msgs->{TOTAL} ? ":$lang{REPEAT_MSG_LOCATION_1} '$msgs_list->[0]{address_by_location_id}'" .
      "$lang{REPEAT_MSG_LOCATION_2} $lang{ADD_ANOTHER_ONE}" : "";
  }

  if ($FORM{UID}) {
    $Msgs->messages_list({
      DATE      => $DATE,
      UID       => $FORM{UID},
      COLS_NAME => 1,
    });

    $answer = $Msgs->{TOTAL} ? ":$lang{REPEAT_MSG_USER}</br>$lang{ADD_ANOTHER_ONE}" : "";
  }

  print $Msgs->{TOTAL} . $answer;
  return $Msgs->{TOTAL} . $answer;
}

1