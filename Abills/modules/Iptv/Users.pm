=head NAME


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array cmd date_diff);
use Shedule;
require Abills::Misc;
require Control::Service_control;
require Control::Services;
use Abills::Loader qw/load_plugin/;
use Iptv::Init qw/init_iptv_service/;

our (
  %FORM,
  %lang,
  $db,
  %conf,
  $admin,
  #%permissions,
  @MONTHES_LIT,
  $Tv_service,
  $user,
  @MODULES,
  @MONTHES,
  @WEEKDAYS,
  $DATE,
  $TIME,
  $index,
  %LIST_PARAMS,
);

our Abills::HTML $html;
our Users $users;

my $Iptv = Iptv->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Shedule = Shedule->new($db, $admin, \%conf);
my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

use Iptv::Services;
my $Iptv_services = Iptv::Services->new($db, $admin, \%conf, { lang => \%lang, ENABLE_FEES_MESSAGES => 1 });
#my $Iptv = Iptv->new( $db, $admin, \%conf );

#**********************************************************
=head2 iptv_user($attr) - Users info

=cut
#**********************************************************
sub iptv_user {
  my ($attr) = @_;

  $Iptv->{UID} = $FORM{UID};
  $FORM{CID} = $FORM{CID2} if ($FORM{CID2});
  my $additional_infos = '';

  if ($FORM{REGISTRATION_INFO}) {
    # Info
    load_module('Docs', $html);
    $users = Users->new($db, $admin, \%conf);
    $Iptv = $Iptv->user_info($Iptv->{ID});
    my $pi = $users->pi({ UID => $Iptv->{UID} });
    $user = $users->info($Iptv->{UID}, { SHOW_PASSWORD => $admin->{permissions}{0}{3} });

    ($Iptv->{Y}, $Iptv->{M}, $Iptv->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
    $pi->{CONTRACT_DATE_LIT} = "$Iptv->{D} " . $MONTHES_LIT[ int($Iptv->{M}) - 1 ] . " $Iptv->{Y} $lang{YEAR}";
    $Iptv->{MONTH_LIT} = $MONTHES_LIT[ int($Iptv->{M}) - 1 ];

    if ($Iptv->{Y} =~ /(\d{2})$/) {
      $Iptv->{YY} = $1;
    }

    if (!$FORM{pdf}) {
      if (in_array('Mail', \@MODULES)) {
        load_module('Mail', $html);
        my $Mail = Mail->new($db, $admin, \%conf);
        my $list = $Mail->mbox_list({ UID => $Iptv->{UID} });
        foreach my $line (@{$list}) {
          $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
          $user->{EMAIL_INFO} .= $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
        }
      }
    }
    print $html->header();
    $Iptv->{PASSWORD} = $user->{PASSWORD} if (!$Iptv->{PASSWORD});
    return $html->tpl_show(_include('iptv_user_memo', 'Iptv', { pdf => $FORM{pdf} }), {
      %{$user},
      %{$pi},
      DATE => $DATE,
      TIME => $TIME,
      %{$Iptv},
    });
  }
  elsif ($FORM{new}) {

  }
  elsif ($FORM{import}) {
    _iptv_users_import();
    return 1;
  }
  elsif ($FORM{add}) {
    my $result = $Iptv_services->user_add({ %FORM, %{($attr) ? $attr : {}} });
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $html->message('info', $lang{ADDED});

      if ($result->{FEES_MESSAGES} && ref $result->{FEES_MESSAGES} eq 'ARRAY') {
        foreach my $message (@{$result->{FEES_MESSAGES}}) {
          $html->message('info', $lang{INFO}, $message);
        }
      }
    }
  }
  elsif ($FORM{change}) {
    my $result = $Iptv_services->user_change(\%FORM);
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $html->message('info', $lang{CHANGED});

      if ($result->{FEES_MESSAGES} && ref $result->{FEES_MESSAGES} eq 'ARRAY') {
        foreach my $message (@{$result->{FEES_MESSAGES}}) {
          $html->message('info', $lang{INFO}, $message);
        }
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $result = $Iptv_services->user_del({ ID => $FORM{del}, COMMENTS => $FORM{COMMENTS} });
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $html->message('info', $lang{DELETED});
    }
  }
  else {
    my $list = $Iptv->user_list({ UID => $FORM{UID}, COLS_NAME => 1 });
    if ($Iptv->{TOTAL} == 1) {
      $FORM{chg} = $list->[0]->{id};
    }
    elsif ($Iptv->{TOTAL} == 0) {
      $FORM{add_form} = 1;
    }
  }

  if ($FORM{chg}) {
    my $response = $Iptv_services->user_info({ %FORM, ID => $FORM{chg} });
    _error_show($response);

    foreach my $action (@{$response->{actions}}) {
      if ($action->{type} eq 'message') {
        $html->message($action->{level}, $lang{INFO}, $action->{message});
      }
      elsif ($action->{type} eq 'redirect') {
        $html->redirect($action->{url});
      }
      elsif ($action->{type} eq 'template') {
        $html->tpl_show(_include($action->{template}, 'Iptv'), { %{$Iptv}, %FORM });
      }

      return if $FORM{IN_MODAL};
    }

    my $service_results = $response->{data}{service_results};
    if ($service_results && $service_results->{data}) {
      ($Iptv->{SERVICE_RESULT_FORM}) = result_former({
        TABLE => {
          width => '100%',
          HIDE_TABLE => 1,
          caption => ($service_results->{service_name} || '') . " ($service_results->{count})",
          ID => 'IPTV_EXTERNAL_LIST',
        },
        DATAHASH => $service_results->{data},
        SKIP_TOTAL_FORM => 1,
        TOTAL => 1,
        OUTPUT2RETURN => 1
      });
    }

    my $additional_info = $response->{data}{additional_info};
    if ($additional_info->{tables}) {
      foreach my $table_info (@{$additional_info->{tables}}) {
        for my $row_idx (0 .. $#{$table_info->{buttons} || []}) {
          my $row_buttons = $table_info->{buttons}[$row_idx] || [];

          for my $btn_idx (0 .. $#{$row_buttons}) {
            my $button = $row_buttons->[$btn_idx];
            my $button_key = "zbutton$btn_idx";

            $table_info->{data}[$row_idx]{$button_key} = $html->button($button->{title}, $button->{url}, $button->{params});
            $table_info->{titles}{$button_key} = '-';
          }
        }


        my ($table, undef) = result_former({
          TABLE           => $table_info->{table},
          EXT_TITLES      => $table_info->{titles},
          DATAHASH        => $table_info->{data},
          SKIP_TOTAL_FORM => 1,
          TOTAL           => 1,
          OUTPUT2RETURN   => 1
        });

        $additional_infos .= $table;
      }
    }

    my $buttons = $response->{data}{buttons};
    if ($buttons && %{$buttons}) {
      my $buttons_html = '';

      foreach my $button_name (sort keys %{$buttons}) {
        my $button = $buttons->{$button_name};
        my $url = "get_index=iptv_user&header=2&chg=$FORM{chg}&UID=$Iptv->{UID}&$button_name=1";

        $buttons_html .= $html->button($button->{title}, $url, $button);
      }

      $Iptv->{EXTRA_BUTTONS} = $html->element('div', $buttons_html, { class => 'btn-group' });
    }

    $Iptv->{chg} = $FORM{chg};
    $Iptv->user_info($FORM{chg});
  }

  if ($attr->{REGISTRATION} && $FORM{add}) {
    return 1;
  }

  $Iptv->{EX_PARAMS} = 'disabled' if $FORM{chg} || $Iptv->{ID};
  $Iptv->{SUBSCRIBE_FORM} = tv_services_sel({ %$Iptv, FORM_ROW => 1, UNKNOWN => 1 });

  if (!$Iptv->{ID}) {
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'add';
      $user->{LNG_ACTION} = $lang{ACTIVATE};
    }

    $Iptv->{TP_ADD} = sel_tp({
      SELECT     => 'TP_ID',
      USER_INFO  => $users,
      MODULE     => 'Iptv',
      TP_ID      => $Iptv->{TP_ID},
      SERVICE_ID => $Iptv->{SERVICE_ID},
      STATUS     => '0'
    });

    $Iptv->{TP_DISPLAY_NONE} = "style='display:none'";
  }
  elsif ($Iptv->{UID}) {
    $Iptv->{REGISTRATION_INFO} = $html->button($lang{MEMO},
      "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1",
      { BUTTON => 1, ex_params => 'target=_new' });

    if ($conf{DOCS_PDF_PRINT}) {
      $Iptv->{REGISTRATION_INFO_PDF} = $html->button("$lang{MEMO} (PDF)",
        "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', BUTTON => 1 });
    }

    iptv_user_channels_list({ ID => $FORM{ID}, TP_ID => $Iptv->{TP_ID} });

    $user->{TP_IDS} = $Iptv->{TP_ID};
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'change';
      $user->{LNG_ACTION} = $lang{CHANGE};
    }

    $FORM{chg} = $Iptv->{ID} if (!$FORM{chg});
    $user->{CHANGE_TP_BUTTON} = $html->button($lang{CHANGE},
      'UID=' . $Iptv->{UID} . '&index=' . get_function_index('iptv_chg_tp') . '&ID=' . $Iptv->{ID}
        . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
      { class => 'change' });

    if ($Tv_service && $Tv_service->{SEND_MESSAGE}) {
      $user->{SEND_MESSAGE} = $html->button("$lang{SEND} $lang{MESSAGE}",
        "index=$index&ID=$Iptv->{ID}&UID=" . $Iptv->{UID} . "&send_message=1"
          . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
        { BUTTON => 1 });
    }

    my $warning_info = $Service_control->service_warning({
      UID         => $Iptv->{UID},
      ID          => $Iptv->{ID},
      MODULE      => 'Iptv',
      DATE        => $DATE
    });

    if (defined $warning_info->{WARNING}) {
      $Iptv->{NEXT_FEES_WARNING} = $warning_info->{WARNING};
      $Iptv->{NEXT_FEES_MESSAGE_TYPE} = $warning_info->{MESSAGE_TYPE};
    }

    $Iptv->{NEXT_FEES_WARNING} = $html->message($Iptv->{NEXT_FEES_MESSAGE_TYPE}, $Iptv->{TP_NAME},
      $Iptv->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 }) if ($Iptv->{NEXT_FEES_WARNING});

    _iptv_user_shedules($users);
  }

  if ($admin->{permissions}{0}{4} && $Iptv->{ID}) {
    $Iptv->{SCHEDULE} = {
      EXT_BUTTON => $html->button('', "UID=$Iptv->{UID}&ID=$Iptv->{ID}&SCHEDULE=status&get_index=iptv_form_schedule&full=1",{
          class => 'btn input-group-button hidden-print rounded-left-0',
          ICON  => 'fa fa-calendar',
      })
    };
  }

  $Iptv->{STATUS_SEL} = sel_status({ STATUS => $Iptv->{STATUS} }, $Iptv->{SCHEDULE} || {});
  $Iptv->{DESCRIBE_AID} = ($Iptv->{DESCRIBE_AID}) ? ('['.$Iptv->{DESCRIBE_AID}.']') : '';
  $Iptv->{VOD} = ($Iptv->{VOD} && $Iptv->{VOD} == 1) ? 'checked' : '';
  my $service_info1 = q{};
  my $service_info2 = q{};
  my $service_info_subscribes = q{};

  if ($FORM{chg} || $FORM{USER_CHANNELS} || $FORM{add_form} || $attr->{REGISTRATION}) {
    $service_info1 .= iptv_users_screens($Iptv);
    if (!$FORM{screen}) {
      $service_info1 .= $html->tpl_show(_include('iptv_user', 'Iptv'), {
        %{($attr) ? $attr : {}},
        %{$Iptv},
        %{($user) ? $user : {}} },
        { ID => 'iptv_user', OUTPUT2RETURN => ($FORM{json}) ? undef : 1 });

      $service_info_subscribes .= iptv_user_channels({ SERVICE_INFO => $Iptv }) if $Iptv->{ID};
    }

    return 1 if ($attr->{ACCOUNT_INFO});
    delete $FORM{chg};
  }

  $service_info_subscribes .= iptv_users_list({ USER_ACCOUNT => 1 });
  $service_info_subscribes .= $additional_infos if ($additional_infos);

  if ($attr->{PROFILE_MODE}) {
    return '', ($service_info1 || q{}), $service_info2, ($Iptv->{SERVICE_RESULT_FORM} || q{}) . $service_info_subscribes;
  }

  print(($Iptv->{SERVICE_RESULT_FORM} || q{}) . ($service_info1 || q{}) . $service_info2 . $service_info_subscribes);

  return 1;
}

# #**********************************************************
# =head2 iptv_user_add($attr) - Users add
#
#   Arguments:
#     REGISTRATION
#     SERVICE_ID
#     SERVICE_ADD => 1
#     TP_ID
#     USER_INFO
#     skip_step
#
#   Results:
#     TRUE or FALSE
#
# =cut
# #**********************************************************
# sub iptv_user_add {
#   my ($attr) = @_;
#
#   if ($attr->{REGISTRATION}) {
#     if (!$attr->{TP_ID}) {
#       return 0;
#     }
#     elsif ($attr->{skip_step}) {
#       return 1;
#     }
#   }
#
#   if (!$users && $attr->{USER_INFO}) {
#     $users = $attr->{USER_INFO};
#   }
#
#   if (!$attr->{SERVICE_ID}) {
#     $Tariffs->{db} = $Iptv->{db};
#     my $tp_list = $Tariffs->list({
#       INNER_TP_ID  => $attr->{TP_ID},
#       SERVICE_ID   => '_SHOW',
#       NEW_MODEL_TP => 1,
#       COLS_NAME    => 1
#     });
#
#     if ($Tariffs->{TOTAL}) {
#       $FORM{SERVICE_ID} = $tp_list->[0]->{service_id};
#       $attr->{SERVICE_ID} = $tp_list->[0]->{service_id};
#     }
#   }
#
#   my $service_info = $Iptv->services_info($attr->{SERVICE_ID});
#
#   $Iptv->user_list({
#     SERVICE_ID => $attr->{SERVICE_ID},
#     UID        => $attr->{UID},
#     COLS_NAME  => 1,
#     PAGE_ROWS  => 99999,
#   });
#
#   if ($service_info->{SUBSCRIBE_COUNT} && $service_info->{SUBSCRIBE_COUNT} == $Iptv->{TOTAL}) {
#     $html->message("err", "$lang{ERROR}", "$lang{IPTV_MAX_SUBSCRIPTIONS_REACHED}: $service_info->{SUBSCRIBE_COUNT}", { ID => 1080012 });
#     return 0;
#   }
#
#   if ($conf{IPTV_USER_UNIQUE_TP}) {
#     $Iptv->user_list({
#       SERVICE_ID => $attr->{SERVICE_ID},
#       UID        => $attr->{UID},
#       TP_ID      => $attr->{TP_ID},
#       COLS_NAME  => 1,
#       #PAGE_ROWS     => 99999,
#     });
#
#     if ($Iptv->{TOTAL}) {
#       $html->message("err", $lang{ERROR}, $lang{THIS_TARIFF_PLAN_IS_ALREADY_CONNECTED}, { ID => 830 });
#       return 0;
#     }
#   }
#
#   $Iptv->{db}{db}->{AutoCommit} = 0;
#   $Iptv->{db}->{TRANSACTION} = 1;
#   $Iptv->user_add($attr);
#   if ($Iptv->{errno}) {
#     $Iptv->{db}{db}->rollback();
#     return 0;
#   }
#
#   # $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
#   $Iptv->{ID} = $Iptv->{INSERT_ID};
#   $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($attr->{TP_ID});
#
#   if (!$FORM{STATUS}) {
#     $Iptv->user_info($Iptv->{ID});
#
#     ::service_get_month_fee($Iptv, {
#       SERVICE_NAME               => $lang{TV},
#       DO_NOT_USE_GLOBAL_USER_PLS => 1,
#       MODULE                     => 'Iptv'
#     });
#
#     if ($attr->{SERVICE_ADD}) {
#       $FORM{add} = 1;
#       $attr->{add} = 1;
#       $Tv_service = iptv_user_services($attr);
#     }
#   }
#   else {
#     delete($Iptv->{db}->{TRANSACTION});
#     $Iptv->{db}{db}->commit();
#     $Iptv->{db}{db}->{AutoCommit} = 1;
#   }
#
#   return $Tv_service->{errno} ? 0 : $Iptv->{ID};
#
# }
#
# #**********************************************************
# =head2 iptv_user_services($form_) - Service add
#
#   Arguments:
#     $form_ - INPUT FORM arguments
#       SERVICE_ID
#       SERIAL_NUMBER
#       MAC
#       CID
#       SUBSCRIBE_ID
#       QUITE   - Quite mode
#
#   Results:
#     $Tv_service [obj]
#
# =cut
# #**********************************************************
# sub iptv_user_services {
#   my ($form_) = @_;
#
#   $Iptv->{SERVICE_ID} ||= $form_->{SERVICE_ID};
#   $Tv_service = undef;
#   my DBI $db_ = $Iptv->{db}{db};
#
#   if ($Iptv->{SERVICE_ID}) {
#     $Tv_service = init_iptv_service($db, $admin, \%conf, {
#       SERVICE_ID => $Iptv->{SERVICE_ID},
#       HTML       => $html,
#       LANG       => \%lang
#     });
#   }
#   else {
#     delete($Iptv->{db}->{TRANSACTION});
#     $db_->commit();
#     $db_->{AutoCommit} = 1;
#     return $Tv_service;
#   }
#
#   if (!::_error_show($Iptv) && ($Tv_service || $conf{IPTV_SKIP_CHECK_PLUGIN})) {
#     my $action_result = iptv_account_action({
#       %$form_,
#       ID           => $Iptv->{ID},
#       SUBSCRIBE_ID => $form_->{SUBSCRIBE_ID} || $Iptv->{SUBSCRIBE_ID},
#       SCREEN_ID    => undef,
#       SERVICE_ID   => $Iptv->{SERVICE_ID}
#     });
#
#     if ($action_result) {
#       ::_error_show($Iptv, {
#         ID          => 835,
#         MODULE_NAME => $Tv_service->{SERVICE_NAME}
#       });
#
#       $db_->rollback();
#       delete $Iptv->{ID};
#       $Tv_service->{errno} = $Iptv->{errno};
#       $Tv_service->{errstr} = $Iptv->{errstr};
#     }
#     else {
#       $html->message('info', $lang{INFO}, $Iptv->{MESSAGE}) if ($Iptv->{MESSAGE});
#       if ($form_->{ARTICLE_ID} && in_array('Storage', \@MODULES)) {
#         load_module('Storage', $html);
#         storage_hardware({
#           ADD_ONLY => 1,
#           SERIAL   => $form_->{SERIAL_NUMBER},
#           MAC      => $form_->{CID} || $form_->{MAC},
#           add      => 1
#         });
#       }
#     }
#     if ($Iptv->{MANDATORY_CHANNELS} && ref $Iptv->{MANDATORY_CHANNELS} eq 'HASH' && !$FORM{change} && !$Tv_service->{errno}) {
#       my @channel_list = keys %{$Iptv->{MANDATORY_CHANNELS}};
#       _iptv_channels_change_now({
#         UID                => $Iptv->{UID},
#         ID                 => $Iptv->{ID},
#         TP_ID              => $Iptv->{TP_ID},
#         MANDATORY_ARR      => \@channel_list,
#         channels           => 1,
#         MANDATORY_CHANNELS => 1,
#         IPTV_              => $Iptv
#       });
#       _iptv_get_fees_mandatory_channels($Iptv);
#     }
#
#   }
#
#   delete($Iptv->{db}->{TRANSACTION});
#   if (! $db_->{AutoCommit}) {
#     $db_->commit();
#     $db_->{AutoCommit} = 1;
#   }
#
#   return $Tv_service;
# }
#
# #**********************************************************
# =head2 iptv_mandatory_channels($tp_id) - Service add
#
#   Arguments:
#     $tp_id
#
#   Results:
#     $channels{num} => {
#       ID
#       FILTER_ID
#       NAME
#     }
#
# =cut
# #**********************************************************
# sub iptv_mandatory_channels {
#   my ($tp_id) = @_;
#
#   my %tp_channels_list = ();
#   $Tariffs->ti_list({ TP_ID => $tp_id, COLS_NAME => 1 });
#
#   return \%tp_channels_list if ($Tariffs->{TOTAL} == 0);
#
#   my $channels_list = $Iptv->channel_ti_list({
#     INTERVAL_ID => $Tariffs->{list}->[0]->{id},
#     MANDATORY   => 1,
#     FILTER_ID   => '_SHOW',
#     COLS_NAME   => 1
#   });
#
#   foreach my $line (@{$channels_list}) {
#     $tp_channels_list{ $line->{channel_id} }{NUM} = $line->{channel_num};
#     $tp_channels_list{ $line->{channel_id} }{NAME} = $line->{name};
#     $tp_channels_list{ $line->{channel_id} }{FILTER_ID} = $line->{filter_id};
#     $tp_channels_list{ $line->{channel_id} }{MONTH_PRICE} = $line->{month_price};
#   }
#
#   return \%tp_channels_list;
# }

# #**********************************************************
# =head2 iptv_account_action($attr) - Control external services
#
#   Arguments:
#     $attr
#       NEGDEPOSIT
#       add
#       change
#       del
#       channels
#       PARENT_CONTROL
#       USER_CHANNELS  - Chnage user channels
#         IDS - Users channels ids
#       SCREEN_ID
#       SEND_MESSAGE
#       ID
#       UID
#       TP_ID
#       LOGIN
#       CID
#       STATUS
#       SUBSCRIBE_ID
#       SILENT       = Silent actions,
#       USER_INFO
#
#   Returns:
#
#     True or False
#
# =cut
# #**********************************************************
# sub iptv_account_action {
#   my ($attr) = @_;
#
#   my $result = 0;
#
#   $Iptv->{SERVICE_ID} = $attr->{SERVICE_ID} || $Iptv->{SERVICE_ID};
#   if ($Iptv->{SERVICE_ID}) {
#     $Tv_service = init_iptv_service($db, $admin, \%conf, {
#       SERVICE_ID            => $Iptv->{SERVICE_ID},
#       HTML                  => $html,
#       LANG                  => \%lang,
#       # TODO: the test function takes too long to execute, something else is needed
#       # CHECK_PLUGIN_ACTIVITY => 1
#     });
#
#     $attr->{SUBSCRIBE_COUNT} = $Tv_service->{SUBSCRIBE_COUNT} if ($Tv_service && $Tv_service->{SUBSCRIBE_COUNT});
#
#     if ($Tv_service && $Tv_service->{STATUS}) {
#       if ($attr->{DEBUG}) {
#         print "ERROR: $Tv_service->{SERVICE_NAME} DISABLE \n";
#       }
#       return $result;
#     }
#   }
#   elsif(! $Iptv->{SERVICE_MODULE}) {
#     $Tv_service = undef;
#   }
#
#   $Iptv->{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID} && !$Iptv->{TP_ID});
#   my $uid = $attr->{UID} || $Iptv->{UID};
#   $users = $attr->{USER_INFO} if ($attr->{USER_INFO});
#   if ((ref $users eq 'HASH' && scalar(keys(%{$users})) < 1) || !$users) {
#     require Users;
#     $users = Users->new($db, $admin, \%conf);
#   }
#
#   my $disable_catv_port = 0;
#   my $enable_catv_port  = 0;
#
#   #Get chanels list
#   $Iptv->{CHANNELS} = iptv_user_channels_list({
#     UID          => $uid,
#     TP_ID        => $attr->{TP_ID} || $Iptv->{TP_ID},
#     RETURN_PORTS => $conf{IPTV_STALKER_API_HOST}
#   }) if $FORM{UID};
#
#   if ($attr->{NEGDEPOSIT}) {
#     $disable_catv_port=1;
#     if ($Tv_service && $Tv_service->can('user_negdeposit')) {
#       $users->info($uid, { SHOW_PASSWORD => 1 });
#       $users->pi({ UID => $uid });
#       $Iptv->user_info($Iptv->{ID} || $attr->{ID});
#       $attr->{TP_ID} = $Iptv->{TP_ID} if $Iptv->{TP_ID};
#       $Tv_service->user_negdeposit({
#         %$users,
#         %$Iptv,
#         %FORM,
#         %$attr
#       });
#       if ($Tv_service->{errno}) {
#         print "$Tv_service->{SERVICE_NAME} Error: [$Tv_service->{errno}]  $Tv_service->{errstr} UID: $uid $attr->{ID}\n";
#       }
#     }
#   }
#   elsif ($attr->{add}) {
#
#     $enable_catv_port=1;
#     _external('', { EXTERNAL_CMD => 'Iptv', %{$users}, %{$Iptv}, ACTION => 'up', QUITE => 1 });
#
#     if ($Tv_service && $Tv_service->can('user_add')) {
#       $users->info($uid, { SHOW_PASSWORD => 1 });
#       $users->pi({ UID => $uid });
#       $Iptv->user_info($attr->{ID});
#       $Iptv->{LOGIN} = $users->{LOGIN};
#
#       $Tv_service->user_add({
#         %{$users},
#         %{$Iptv},
#         %{$attr},
#         PASSWORD      => $users->{PASSWORD},
#         ID            => $Iptv->{ID},
#         EMAIL         => $attr->{EMAIL} || $Iptv->{EMAIL} || $users->{EMAIL},
#         SERVICE_EMAIL => $Iptv->{EMAIL}
#       });
#
#       if (!$Tv_service->{errno}) {
#         if ($Tv_service->{SUBSCRIBE_ID}) {
#           $Iptv->user_change({
#             ID           => $Iptv->{ID},
#             SUBSCRIBE_ID => $Tv_service->{SUBSCRIBE_ID}
#           });
#         }
#
#         $result = 0;
#       }
#       else {
#         $Iptv->{errno} = $Tv_service->{errno};
#         if ($Tv_service->{errno} == 1000) {
#           $Iptv->{errstr} = $lang{WRONG_EMAIL};
#         }
#         elsif ($Tv_service->{errno} == 1001) {
#           $Iptv->{errstr} = 'ERR_CREATE';
#         }
#         elsif ($Tv_service->{errno} == 1002) {
#           $Iptv->{errstr} = $lang{EXIST};
#         }
#         elsif ($Tv_service->{errno} == 1003) {
#           $Iptv->{errstr} = "E-mail $lang{EXIST}\n$Iptv->{EMAIL}";
#         }
#         elsif ($Tv_service->{errno} == 1004) {
#           $Iptv->{errstr} = "E-mail $lang{ERR_NOT_EXISTS}";
#         }
#         elsif ($Tv_service->{errno} == 1005) {
#           $Iptv->{errstr} = "ERR_NO_PASSWORD";
#         }
#         elsif ($Tv_service->{errno} == 1020) {
#           $Iptv->{errstr} = "ERR_INCORRECT_RESPONSE";
#         }
#         else {
#           $Iptv->{errstr} = $Tv_service->{errstr} || 'ERR_UNDEFINED';
#         }
#         $result = 1;
#       }
#     }
#
#     if ($attr->{SUBSCRIBE_ID}) {
#       $Iptv->subscribe_change({
#         ID     => $FORM{SUBSCRIBE_ID},
#         STATUS => 0
#       });
#       if ($conf{IPTV_SUBSCRIBE_CMD}) {
#         $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
#         $result = cmd($conf{IPTV_SUBSCRIBE_CMD}, {
#           PARAMS => { %{$Iptv}, ACTION => 'SET' },
#           ARGV   => 1,
#           debug  => $conf{IPTV_CMD_DEBUG}
#         });
#       }
#     }
#   }
#   elsif ($attr->{change}) {
#     if ($attr->{STATUS}) {
#       $disable_catv_port = 1;
#     }
#     if ($Tv_service && $Tv_service->can('user_change')) {
#       $users->info($uid, { SHOW_PASSWORD => 1 });
#       $users->pi({ UID => $uid });
#       $Iptv->user_info($attr->{ID} || $Iptv->{ID});
#       $Iptv->{TP_INFO_OLD} //= $attr->{TP_INFO_OLD};
#       $Tv_service->user_change({
#         %$users,
#         %$Iptv,
#         %FORM,
#         %$attr,
#         EMAIL         => $users->{EMAIL} || $Iptv->{EMAIL},
#         SERVICE_EMAIL => $Iptv->{EMAIL}
#       });
#
#       if ($Tv_service->{errno}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#       elsif ($Tv_service->{SUBSCRIBE_ID}) {
#         $Iptv->user_change({
#           ID           => $Iptv->{ID},
#           SUBSCRIBE_ID => $Tv_service->{SUBSCRIBE_ID}
#         });
#       }
#     }
#
#     if ($FORM{SUBSCRIBE_ID}) {
#       $Iptv->subscribe_change({
#         ID     => $attr->{SUBSCRIBE_ID},
#         STATUS => 0
#       });
#
#       $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
#       if ($conf{IPTV_SUBSCRIBE_CMD}) {
#         cmd($conf{IPTV_SUBSCRIBE_CMD}, {
#           PARAMS => { %{$Iptv}, ACTION => 'SET' },
#           debug  => $conf{IPTV_CMD_DEBUG}
#         });
#       }
#     }
#
#     _external('', { EXTERNAL_CMD => 'Iptv', %{$users}, %{$Iptv}, ACTION => 'down', QUITE => 1 });
#   }
#   elsif ($attr->{channels}) {
#     if ($Tv_service && ref $Tv_service ne 'HASH') {
#       if ($Tv_service->can('channels_change')) {
#         my @filters_list = ();
#         my $channel_ti_list = $Iptv->channel_ti_list({
#           ID        => join(';', @{$attr->{ADD_ID}}) || '-',
#           FILTER_ID => '_SHOW',
#           COLS_NAME => 1
#         });
#
#         foreach my $line (@$channel_ti_list) {
#           next if !$line->{filter_id};
#           push @filters_list, $line->{filter_id};
#         }
#
#         $Tv_service->channels_change({
#           %{$users},
#           %{$Iptv},
#           %{$attr},
#           FILTER_ID => join(',', @filters_list),
#           ID        => $Iptv->{ID},
#         });
#       }
#
#       if ($Tv_service->{errno}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#     }
#   }
#   elsif ($attr->{SCREEN_ID}) {
#     my %request = (
#       %{$attr},
#       CID => $attr->{CID},
#     );
#
#     if ($attr->{DEL}) {
#       $Iptv->users_screens_info($Iptv->{ID}, { SCREEN_ID => $attr->{SCREEN_ID} });
#       ::_error_show($Iptv);
#       %request = (
#         MAC             => $Iptv->{CID} || $attr->{CID},
#         %{$attr},
#         CID             => $Iptv->{CID} || $attr->{CID},
#         ID              => $Iptv->{ID},
#         SERIAL          => $Iptv->{SERIAL} || $attr->{SERIAL},
#         TP_FILTER_ID    => $Iptv->{FILTER_ID},
#         SUB_ID          => $Iptv->{FILTER_ID},
#         del             => 1,
#         TYPE            => $attr->{TYPE} || 'subs_break_contract',
#         DEVICE_DEL_TYPE => $attr->{DEVICE_DEL_TYPE} || 'device_break_contract'
#       );
#
#     }
#     else {
#       $request{BUNDLE_TYPE} = $attr->{BUNDLE_TYPE} || ($attr->{CID} ? 'subs_free_device' : undef) || 'subs_no_device';
#     }
#
#     if ($attr->{chg} || $attr->{ID}) {
#       $Iptv->user_info($attr->{chg} || $attr->{ID});
#       $request{SUBSCRIBE_ID} = $Iptv->{SUBSCRIBE_ID} if $Iptv->{TOTAL} && $Iptv->{SUBSCRIBE_ID};
#
#       $users->info($users->{UID} || $Iptv->{UID}, { SHOW_PASSWORD => 1 });
#       $request{LOGIN} = $users->{LOGIN};
#       $request{PASSWORD} = $users->{PASSWORD};
#       $request{DEPOSIT} = $users->{DEPOSIT};
#     }
#
#     if ($Tv_service && $Tv_service->can('user_screens')) {
#       $Tv_service->user_screens(\%request);
#       if (!$Tv_service->{errno}) {
#
#         if ($Tv_service->{CID} || $Tv_service->{SERIAL}) {
#           $Iptv->users_screens_add({
#             SERVICE_ID => $Iptv->{ID},
#             SCREEN_ID  => $Tv_service->{SCREEN_ID} || $Iptv->{SCREEN_ID} || $attr->{SCREEN_ID},
#             CID        => $Tv_service->{CID},
#             SERIAL     => $Tv_service->{SERIAL} || '',
#             COMMENT    => $Tv_service->{COMMENT} || ''
#           });
#         }
#
#         $result = 0;
#       }
#       else {
#         $result = 1;
#       }
#     }
#     else {
#       $result = 1;
#     }
#
#     ::_error_show($Tv_service, { ID => 833, MESSAGE => ($Tv_service->{DEVICE_ID} ? "ID: " . $Tv_service->{DEVICE_ID} : q{}) });
#   }
#   # elsif ($attr->{ACTIVATE}) {
#     #iptv_account_action({ add => 1 });
#   # }
#   elsif ($attr->{chg}) {
#
#     if ($attr->{add_service}) {
#       my $return = iptv_account_action({
#         %{$attr},
#         chg => undef,
#         ID  => $attr->{chg},
#         add => 1
#       });
#
#       $html->message('info', $lang{ADDED}, $lang{ADDED}) if (!$attr->{SILENT} && !$return);
#
#       return 0;
#     }
#
#     if ($Tv_service && $Tv_service->can('user_info')) {
#       $users->pi({ UID => $uid });
#       $Tv_service->user_info({ %$attr, %$users, %{$Iptv} });
#
#       if ($Tv_service->{errno}) {
#         my $message = '';
#         if ($Tv_service->{errno} == 404) {
#           if (!$user && !$user->{UID}) {
#             $message = $html->br() . $html->button("$lang{ADD} $Tv_service->{SERVICE_NAME}",
#               "index=$index&UID=$uid&chg=$attr->{chg}&add_service=1", { BUTTON => 1 });
#             $Tv_service->{errstr} = "$Tv_service->{SERVICE_NAME} $lang{ERR_NOT_EXISTS}";
#           }
#         }
#
#         ::_error_show($Tv_service, { ID => $Tv_service->{errno}, MESSAGE => $message });
#       }
#       elsif ($Tv_service->{RESULT} && $Tv_service->{RESULT}->{results} && ref $Tv_service->{RESULT}->{results} eq 'ARRAY') {
#         ($Tv_service->{SERVICE_RESULT_FORM}) = result_former({
#           TABLE           => {
#             width      => '100%',
#             HIDE_TABLE => 1,
#             caption    => $Tv_service->{SERVICE_NAME} . ' (' . ($#{$Tv_service->{RESULT}->{results}} + 1) . ')',
#             ID         => 'IPTV_EXTERNAL_LIST',
#           },
#           DATAHASH        => $Tv_service->{RESULT}->{results},
#           SKIP_TOTAL_FORM => 1,
#           TOTAL           => 1,
#           OUTPUT2RETURN   => 1
#         });
#       }
#     }
#   }
#   elsif ($attr->{send_message}) {
#     if ($Tv_service && $Tv_service->can('send_message')) {
#       $Tv_service->send_message($attr);
#       if ($Tv_service->{error}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#     }
#   }
#   elsif ($attr->{del}) {
#     $disable_catv_port = 1;
#     if ($Tv_service && $Tv_service->can('user_del')) {
#       $users->pi({ UID => $uid });
#
#       my $user_screens = $Iptv->users_screens_list({
#         NUM              => '_SHOW',
#         CID              => '_SHOW',
#         SERIAL           => '_SHOW',
#         USERS_SERVICE_ID => $attr->{del},
#         COLS_NAME        => 1,
#         COLS_UPPER       => 1,
#         SHOW_ASSIGN      => 1
#       });
#
#       $Iptv->user_info($attr->{del} || $Iptv->{ID});
#       $Iptv->{STATUS} = 1 if $attr->{FORCE_DEL};
#       $Tv_service->user_del({ %{$users}, %$attr, %{$Iptv}, ID => $attr->{del}, USER_SCREENS => $user_screens });
#       if ($Tv_service->{error} || $Tv_service->{errno}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#     }
#
#     if ($attr->{SUBSCRIBE_ID}) {
#       $Iptv->subscribe_change({
#         ID     => $attr->{SUBSCRIBE_ID},
#         STATUS => 6
#       });
#       $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
#
#       if ($conf{IPTV_SUBSCRIBE_CMD}) {
#         cmd($conf{IPTV_SUBSCRIBE_CMD}, {
#           PARAMS => { %{$Iptv}, ACTION => 'SET' },
#           debug  => $conf{IPTV_CMD_DEBUG}
#         });
#       }
#     }
#
#     _external('', { EXTERNAL_CMD => 'Iptv', %{($users) ? $users : {} }, %{$Iptv}, ACTION => 'down', QUITE => 1 });
#   }
#   elsif ($attr->{hangup}) {
#     if ($Tv_service && $Tv_service->can('hangup')) {
#       $Tv_service->hangup($attr);
#       if ($Tv_service->{error}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#     }
#
#     $html->message('info', $lang{INFO}, $lang{HANGUPED}) if (!$attr->{SILENT});
#   }
#   elsif ($attr->{USER_IMPORT}) {
#     if ($Tv_service && $Tv_service->can('user_import')) {
#       $Tv_service->user_import($attr);
#       if ($Tv_service->{errno}) {
#         $Iptv->{errno} = $Tv_service->{errno};
#         $Iptv->{errstr} = $Tv_service->{errstr};
#         $result = 1;
#       }
#     }
#   }
#
#   if ($conf{IPTV_CHANGE_ONU_CATV_PORT_STATUS} && in_array('Equipment', \@MODULES) && ($disable_catv_port || $enable_catv_port)) {
#     use Equipment;
#     our $Equipment = Equipment->new($db, $admin, \%conf);
#     use Equipment::Pon_mng;
#     equipment_tv_port({
#       UID          => $uid,
#       CATV_PORT_ID => 1, #XXX should disable all ports or only first?
#       DISABLE_PORT => $disable_catv_port,
#       ENABLE_PORT  => $enable_catv_port
#     });
#   }
#
#   return $result;
# }

#*******************************************************************
=head2 iptv_chg_tp($attr) - Change user tarif plan

  Arguments:
    $attr
      USER_INFO


=cut
#*******************************************************************
sub iptv_chg_tp {
  my ($attr) = @_;

  if (!$admin->{permissions}{0}{10}) {
    $html->message('warn', $lang{WARNING}, $lang{ERR_ACCESS_DENY}, { ID => 843 });
    return 1;
  }

  my $_user;

  if (defined($attr->{USER_INFO})) {
    $_user = $attr->{USER_INFO};
    $Iptv = $Iptv->user_info($FORM{ID});
    if ($Iptv->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, {  ID => 844 });
      return 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST});
    return 0;
  }

  my $period = $FORM{period} || 0;

  if ($FORM{set}) {
    my $result = $Iptv_services->user_chg_tp(\%FORM);
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $html->message('info', $lang{CHANGED}, $lang{CHANGED});

      if ($result->{FEES_MESSAGES} && ref $result->{FEES_MESSAGES} eq 'ARRAY') {
        foreach my $message (@{$result->{FEES_MESSAGES}}) {
          $html->message('info', $lang{INFO}, $message);
        }
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del({
      UID => $_user->{UID},
      ID  => $FORM{SHEDULE_ID}
    });
    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  _iptv_show_exist_shedule($period);

  $Tariffs->{DESCRIBE_AID} = ($Iptv->{DESCRIBE_AID}) ? ('['.$Iptv->{DESCRIBE_AID}.']') : '';
  $Tariffs->{UID}     = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID}   = $Iptv->{TP_ID};
  $Tariffs->{TP_NAME} = ($Iptv->{TP_NUM}) ? "$Iptv->{TP_NUM}: $Iptv->{TP_NAME}" : $lang{NOT_EXIST};
  $Tariffs->{ID}      = $Iptv->{ID};

  $html->tpl_show(templates('form_chg_tp'), $Tariffs);

  return 1;
}

#*******************************************************************
=head2 iptv_get_service_tps($attr)

  Arguments:
    $attr

=cut
#*******************************************************************
sub iptv_get_service_tps {
  my ($attr) = @_;

  my $uid = $FORM{UID} || 0;
  my $user_info = $users->pi({ UID => $uid });
  my $tp_gids = ($user_info->{LOCATION_ID}) ? tp_gids_by_geolocation($user_info->{LOCATION_ID}, $Tariffs, $user_info->{GID}) : '';

  $attr->{EX_PARAMS} ||= $FORM{EX_PARAMS};

  my $tp_sel = $html->form_select('TP_ID', {
    SEL_LIST  => $Tariffs->list({
      MODULE       => 'Iptv',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      DOMAIN_ID    => $admin->{DOMAIN_ID} || '_SHOW',
      SERVICE_ID   => $FORM{SERVICE_ID},
      DESCRIBE_AID => '_SHOW',
      STATUS       => '0',
      TP_GID       => $tp_gids || '_SHOW',
    }),
    SEL_KEY   => 'tp_id',
    SEL_VALUE => 'id,name,describe_aid',
    EX_PARAMS => $attr->{EX_PARAMS} ? $attr->{EX_PARAMS} : '',
    SELECTED  => $FORM{TP_ID}
  });

  return $tp_sel if $attr->{RETURN_SELECT};

  print $tp_sel;
}

#**********************************************************
=head2 iptv_form_schedule($attr) - Iptv schedule

=cut
#**********************************************************
sub iptv_form_schedule {

  my $service_id = $FORM{ID} || '';
  if ($FORM{add} && $admin->{permissions}{0}{18} && defined($FORM{ACTION})) {
    my ($Y, $M, $D) = split(/-/, ($FORM{DATE} || $DATE), 3);

    if (date_diff($DATE, "$Y-$M-$D") < 1) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}: $lang{DATE}");
    }
    else {
      $Shedule->add({
        UID    => $FORM{UID},
        TYPE   => $FORM{SCHEDULE} || q{},
        ACTION => "$service_id:$FORM{ACTION}",
        D      => $D,
        M      => $M,
        Y      => $Y,
        MODULE => 'Iptv'
      });
      if (!_error_show($Shedule, { ID => 971 })) {
        $html->message('info', $lang{CHANGED}, "$lang{SHEDULE} $lang{ADDED}");
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $admin->{permissions}{0}{18}) {
    $Shedule->del({ ID => $FORM{del} });
    if (!_error_show($Shedule)) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]");
    }
  }

  if ($FORM{SCHEDULE} && $FORM{SCHEDULE} eq 'status' && $admin->{permissions}{0}{18} && $FORM{ID}) {
    my $service_status = sel_status({ HASH_RESULT => 1 });

    $html->tpl_show(_include('iptv_schedule_add_form', 'Iptv'), { %FORM,
      DATE_PICKER => $html->date_fld2('DATE', {
        NEXT_DAY  => 1,
        MONTHES   => \@MONTHES,
        WEEK_DAYS => \@WEEKDAYS
      }),
      STATUS_SEL  => $html->form_select('ACTION', {
        SELECTED   => $FORM{ACTION},
        SEL_HASH   => $service_status,
        USE_COLORS => 1,
        NO_ID      => 1
      })
    });
  }

  iptv_schedule_list({ UID => $FORM{UID} });
}

#**********************************************************
=head2 iptv_schedule_list($attr) - Iptv schedule list

=cut
#**********************************************************
sub iptv_schedule_list {
  my ($attr) = @_;

  my $service_status = sel_status({ HASH_RESULT => 1 });
  my $module = $attr->{MODULE} || q{Iptv};

  my $list = $Shedule->list({
    %LIST_PARAMS,
    UID       => $attr->{UID},
    MODULE    => $module,
    COLS_NAME => 1
  });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{SHEDULE},
    title   => [ $lang{HOURS}, $lang{DAY}, $lang{MONTH}, $lang{YEAR}, $lang{COUNT}, $lang{USER}, $lang{TYPE},
      $lang{VALUE}, $lang{MODULES}, $lang{ADMINS}, $lang{CREATED}, "-" ],
    qs      => $pages_qs,
    pages   => $Shedule->{TOTAL},
    ID      => uc($module) . '_SCHEDULE'
  });

  foreach my $line (@$list) {
    my $delete = ($admin->{permissions}{0}{4}) ? $html->button($lang{DEL}, "index=$index&del=$line->{id}&UID=$line->{uid}",
      { MESSAGE => "$lang{DEL} [$line->{id}]?", class => 'del', TEXT => $lang{DEL} }) : '-';

    my $action = $line->{action};
    my $service_id = 0;

    if ($action =~ /:/) {
      ($service_id, $action) = split(/:/, $action);
    }

    if ($line->{type} eq 'status') {
      $action = $html->color_mark($service_status->{ $action });
    }
    else {
      $action = sel_tp({ TP_ID => $action }) . (($service_id) ? " ($service_id)" : q{});
    }

    $table->addrow($html->b($line->{h}), $line->{d}, $line->{m}, $line->{y}, $line->{counts},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"), $line->{type}, $action, $line->{module},
      $line->{admin_name}, $line->{date}, $delete
    );
  }

  print $table->show();

  $table = $html->table({
    width => '100%',
    ID    => uc($module) . '_SCHEDULE_TOTAL',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Shedule->{TOTAL}) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _iptv_show_exist_shedule($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_show_exist_shedule {
  my ($period) = @_;

  _iptv_add_shedule_form($period);

  my $shedules = $Shedule->list({
    UID          => $user->{UID},
    TYPE         => 'tp',
    MODULE       => 'Iptv',
    SHEDULE_DATE => ">$DATE",
    COLS_NAME    => 1,
    COLS_UPPER   => 1
  });

  return 0 if $Shedule->{TOTAL} < 1;

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{SHEDULE}",,
    ID      => 'SHEDULE_INFO',
    title   => ["ID", "$lang{NEW} $lang{TARIF_PLAN}", $lang{DATE}, $lang{ADMIN}, $lang{ADDED} ]
  });

  foreach my $shedule (@{$shedules}) {
    my ($service, $action) = split(':', $shedule->{ACTION});

    next if !$service || $FORM{ID} != $service;

    my $del_btn = $html->button($lang{DEL}, "index=$index&del=$shedule->{ID}&SHEDULE_ID=$shedule->{ID}&UID=$FORM{UID}&" .
      "ID=$FORM{ID}", { MESSAGE => "$lang{DEL} $shedule->{y}-$shedule->{m}-$shedule->{d}?", class => 'del' });

    my $tp_info = $Tariffs->info($action);
    next if !$action || $Tariffs->{TOTAL} < 1;

    $table->addrow($shedule->{ID}, $tp_info->{NAME}, "$shedule->{Y}-$shedule->{M}-$shedule->{D}", $shedule->{ADMIN_NAME}, $shedule->{DATE}, $del_btn);
  }

  $Tariffs->{SHEDULE_LIST} = $table->show();

  return 0;
}

#**********************************************************
=head2 _iptv_user_shedules($attr)

  Arguments:
    $attr

  Return:

=cut
#**********************************************************
sub _iptv_user_shedules {
  my ($attr) = @_;

  $attr->{chg} ||= $FORM{chg};

  return 0 if(! $attr->{chg});
  my $uid = $user->{UID} || $attr->{UID} || $FORM{UID};

  my $shedules = $Shedule->list({
    UID          => $uid,
    TYPE         => 'tp',
    MODULE       => 'Iptv',
    SHEDULE_DATE => ">=$DATE",
    SORT         => 's.y, s.m, s.d',
    COLS_NAME    => 1,
    COLS_UPPER   => 1
  });

  return if $Shedule->{TOTAL} < 1;

  foreach (@{$shedules}) {
    next if !$_->{ACTION};
    my ($service, $action) = split(':', $_->{ACTION});

    next if !$service || $attr->{chg} != $service;

    my $tp_info = $Tariffs->info($action);
    next if !$action || $Tariffs->{TOTAL} < 1;

    $html->message('info', $lang{INFO}, "$lang{CHANGE_OF_TP} $action:$tp_info->{NAME}. $_->{Y}-$_->{M}-$_->{D}");

    return 0 if $attr->{SHOW_FIRST};
  }

  return 0;
}

#**********************************************************
=head2 _iptv_add_shedule_form($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_add_shedule_form {
  my ($period) = @_;

  my $uid = $user->{UID} || $FORM{UID} || 0;
  my $user_info = $users->pi({ UID => $uid });
  my $tp_gids = ($user_info->{LOCATION_ID}) ? tp_gids_by_geolocation($user_info->{LOCATION_ID}, $Tariffs, $user_info->{GID}) : '';

  my $tariffs_list = $Tariffs->list({
    MODULE       => 'Iptv',
    SERVICE_ID   => $FORM{SERVICE_ID},
    NEW_MODEL_TP => 1,
    COLS_NAME    => 1,
    STATUS       => '0',
    TP_GID       => $tp_gids || '_SHOW',
    DOMAIN_ID    => $admin->{DOMAIN_ID} || '_SHOW',
    DESCRIBE_AID => '_SHOW',
  });

  foreach my $tp (@{$tariffs_list}) {
    my $describe_for_aid = ($tp->{describe_aid}) ? (' [' . $tp->{describe_aid} . ']') : '';
    $tp->{name} .= $describe_for_aid;
  }

  $Tariffs->{TARIF_PLAN_SEL} = $html->form_select('TP_ID', {
    SELECTED       => $Iptv->{TP_ID},
    SEL_LIST       => $tariffs_list,
    SEL_KEY        => 'tp_id',
    SEL_VALUE      => "id,name",
    NO_ID          => 1,
    MAIN_MENU      => ($admin->{permissions}{0}{10}) ? get_function_index('iptv_tp') : undef,
    MAIN_MENU_ARGV => "TP_ID=$Iptv->{TP_ID}"
  });
  $Tariffs->{PARAMS} .= form_period($period, { ABON_DATE => $Iptv->{ABON_DATE} });
  $Tariffs->{ACTION} = 'set';
  $Tariffs->{LNG_ACTION} = $lang{CHANGE};

  return 0;
}

#**********************************************************
=head2 _iptv_users_import($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _iptv_users_import {
  my ($attr) = @_;

  if (!$FORM{add}) {
    $html->tpl_show(templates('form_import'), {
      IMPORT_FIELDS => 'LOGIN,SERVICE_ID,TP_ID,STATUS,SUBSCRIBE_ID',
      CALLBACK_FUNC => 'iptv_user'
    });

    return 0;
  }

  my $import_accounts = import_former(\%FORM);
  my $total = $#{$import_accounts} + 1;

  foreach my $account (@{$import_accounts}) {
    my $user_info = $users->info(undef, { LOGIN => $account->{LOGIN} });
    if (!$users->{TOTAL} || $users->{TOTAL} < 1) {
      next;
    }

    $account->{UID} = $users->{UID};

    my $result = $Iptv_services->user_add({ %{$account}, USER_IMPORT => 1 });
    _error_show($result);
  }

  $html->message('info', $lang{INFO},
    "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

  return 1
}

1;
