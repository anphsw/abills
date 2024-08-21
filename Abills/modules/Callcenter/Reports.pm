=head1 NAME

  Callcenter Reports

=cut

use strict;
use warnings FATAL => 'all';
use Callcenter::db::Callcenter;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @MONTHES,
  %permissions,
  %LIST_PARAMS
);

our Abills::HTML $html;

my $Callcenter = Callcenter->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
my $Admins = Admins->new($db, $admin, \%conf);

my ($year, $month, $day) = split(/-/, $DATE, 3);
my $date_from = "$year-$month-01";

#**********************************************************
=head2 callcenter_calls_handler() - all the calls show here

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub callcenter_calls_handler {

  # from dashbord
  if($FORM{sip_chg}){
    print "Content-Type: text/html\n\n";
    $html->tpl_show(_include('callcenter_calls_sip_change', 'Callcenter'), {
      SIP_NUMBER => $FORM{OPERATOR_PHONE} || q{},
      AID        => $admin->{AID},
    });
    return 1;
  }

  my @STATUSES = ('', $lang{RINGING}, $lang{IN_PROCESSING}, $lang{PROCESSED}, $lang{NOT_PROCESSED}, $lang{PROCESSED}.' in');

  my @status_bar = (
    "$lang{ALL}:index=$index&STATUS=0",
    "$lang{RINGING}:index=$index&STATUS=1",
    "$lang{IN_PROCESSING}:index=$index&STATUS=2",
    "$lang{PROCESSED}:index=$index&STATUS=3",
    "$lang{NOT_PROCESSED}:index=$index&STATUS=4",
  );

  my $STATUS_SELECT = $html->form_select('STATUS', {
    SELECTED     => $FORM{STATUS} || q{},
    SEL_OPTIONS  => { '' => $lang{ALL} },
    SEL_ARRAY    => [ @STATUSES[1..4] ],
    ARRAY_NUM_ID => 1,
  });

  my $ADMINS_SELECT = $html->form_select('OPERATOR_PHONE', {
    SELECTED     => $FORM{OPERATOR_PHONE} || q{},
    SEL_LIST     => $Admins->list({ COLS_NAME => 1, WITH_SIP_NUMBER => 1, SIP_NUMBER => '_SHOW' }),
    SEL_KEY      => 'sip_number',
    SEL_VALUE    => 'login',
    ARRAY_NUM_ID => 1,
    NO_ID        => 1
  });

  if ($FORM{call_status} && $FORM{call_status} == 1) {
    $Callcenter->callcenter_add_cals({
      USER_PHONE     => $FORM{user_phone},
      OPERATOR_PHONE => $FORM{operator_phone},
      STATUS         => $FORM{call_status},
      UID            => $FORM{uid} || 0,
      ID             => $FORM{call_id}
    });

    print !$Callcenter->{errno} ? 'Call successfully added' : 'Error';

    return 1;
  }
  elsif ($FORM{call_status} && $FORM{call_status} == 2) {
    $Callcenter->callcenter_change_calls({
      STATUS => $FORM{call_status},
      ID     => $FORM{call_id}
    });

    print !$Callcenter->{errno} ? 'Status changed to 2' : 'Error';

    return 1;
  }
  elsif ($FORM{call_status} && $FORM{call_status} == 3) {
    $Callcenter->callcenter_change_calls({
      STATUS => $FORM{call_status},
      ID     => $FORM{call_id}
    });

    print !$Callcenter->{errno} ? 'Status changed to 3' : 'Error';

    return 1;
  }
  elsif ($FORM{call_status} && $FORM{call_status} == 4) {
    $Callcenter->callcenter_change_calls({
      STATUS => $FORM{call_status},
      ID     => $FORM{call_id}
    });

    print !$Callcenter->{errno} ? 'Status changed to 4' : 'Error';

    return 1;
  }

  if ($FORM{chg}) {
    my $info_calls = $Callcenter->callcenter_info_calls({ ID => $FORM{chg} });
    my $result_cmd = Abills::Base::cmd("ls /usr/abills/Abills/templates/asterisk/");

    my $audio_date = $info_calls->{DATE} || '';
    $audio_date =~ s/[-\s:]//g;
    $audio_date = substr($audio_date, 0, -2);
    my $user_phone = $info_calls->{USER_PHONE} || '';
    my $operator_phone = $info_calls->{OPERATOR_PHONE} || '';
    my $file = "$audio_date-$user_phone-$operator_phone.wav";

    if ($result_cmd =~ /$file/i) {
      $info_calls->{FILE_PATH} = "/images/asterisk/$file";
    }

    $STATUS_SELECT = $html->form_select('STATUS', {
      SELECTED     => $Callcenter->{STATUS} || q{},
      SEL_ARRAY    => \@STATUSES,
      ARRAY_NUM_ID => 1,
    });

    $html->tpl_show(_include('callcenter_calls_change', 'Callcenter'), {
      STATUS_SELECT => $STATUS_SELECT,
      %{$info_calls},
      %$Callcenter,
    });

    return 1;
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Callcenter->callcenter_delete_calls({ ID => $FORM{del} });
    $html->message('info', $lang{SUCCESS}, $lang{DELETED}) if !$Callcenter->{errno};
  }
  elsif ($FORM{change}) {
    $Callcenter->callcenter_change_calls({
      STATUS => $FORM{STATUS},
      ID     => $FORM{change}
    });

    $html->message('info', $lang{SUCCESS}, $lang{CHANGED}) if !$Callcenter->{errno};
  }

  _error_show($Callcenter);

  if ($FORM{refresh} && $FORM{refresh} == 1) {
    my $not_found_users = 0;
    my $unrecognized_users_list = $Callcenter->callcenter_list_calls({
      COLS_NAME    => 1,
      UNRECOGNIZED => 1,
      USER_PHONE   => '_SHOW'
    });

    foreach my $unrecognized_user (@$unrecognized_users_list) {
      my $unrecognized_user_phone = $unrecognized_user->{user_phone};
      if ($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}) {
        $unrecognized_user_phone =~ s/$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
      }

      my $admins_for_number_list = $Admins->list({ SIP_NUMBER => $unrecognized_user_phone, AID => '_SHOW', COLS_NAME => 1 });
      if ($admins_for_number_list && ref $admins_for_number_list eq 'ARRAY' && scalar @{$admins_for_number_list} > 0) {
        next;
      }

      my $u_info = $Users->list({ COLS_NAME => 1, PHONE => "*$unrecognized_user_phone" })->[0];

      if ($Users->{errno}) {
        $not_found_users++;
        next;
      }

      $Callcenter->callcenter_change_calls({
        ID  => $unrecognized_user->{id},
        UID => $u_info->{uid}
      });
    }

    if ($not_found_users > 0) {
      $html->message('success', "$lang{NOT_FOUND} $not_found_users $lang{USERS}");
    }
  }

  if ($FORM{search_form}) {
    $FORM{STATUS} += 1 if (defined($FORM{STATUS}) && $FORM{STATUS} ne '');
    my $search_form = $html->tpl_show(_include('callcenter_calls_filter', 'Callcenter'), {
      STATUS_SELECT      => $STATUS_SELECT,
      STATUS_VISIBILITY  => 1,
      ADMINS_SELECT      => $ADMINS_SELECT,
      REFRESH_VISIBILITY => 1,
      %FORM
    },
      { OUTPUT2RETURN => 1 });

    form_search({
      TPL  => $search_form,
    });
  }

  $Callcenter->{debug} = 1 if $FORM{DEBUG};

  $LIST_PARAMS{STATUS} = $FORM{STATUS} if $FORM{STATUS};
  $LIST_PARAMS{SORT} = ($FORM{sort}) ? $FORM{sort} : 'date';
  $LIST_PARAMS{DESC} = $FORM{desc} if $FORM{desc};
  $LIST_PARAMS{CALL_PHONE} = $FORM{CALL_PHONE} if $FORM{CALL_PHONE};
  $LIST_PARAMS{OPERATOR_PHONE} = $FORM{OPERATOR_PHONE} if $FORM{OPERATOR_PHONE};

  result_former({
    INPUT_DATA      => $Callcenter,
    FUNCTION        => 'callcenter_list_calls',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => "ID, UID, USER_PHONE, ADMIN, OPERATOR_PHONE, STATUS, DATE, LOGIN",
    FUNCTION_FIELDS => 'change, del',
    STATUS_VALS     => \@STATUSES,
    EXT_TITLES      => {
      id             => "ID",
      user_phone     => $lang{CALL_FROM},
      admin          => $lang{ADMIN},
      status         => $lang{STATUS},
      date           => $lang{DATE},
      operator_phone => $lang{CALL_TO},
      fio            => $lang{FIO},
      login          => $lang{USER},
      address_full   => $lang{ADDRESS},
      city           => $lang{CITY},
      stop           => $lang{END},
      duration       => $lang{DURATION}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{CALL_CENTER},
      qs      => $pages_qs,
      ID      => 'CALLCENTER_CALLS_HANDLER',
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search",
      header  => $html->table_header(\@status_bar),
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    FUNCTION_INDEX  => $index,
    MODULE          => 'Callcenter',
    TOTAL           => 1,
    SKIP_USER_TITLE => 1
  });

  return 1;
}

#**********************************************************
=head2 callcenter_admins_report() - graphic admin report


=cut
#**********************************************************
sub callcenter_admins_report {
  $FORM{DATE_START} ||= $date_from;
  $FORM{DATE_END} ||= $DATE;

  my $ADMINS_SELECT = $html->form_select('ADMIN_SELECT', {
    SELECTED     => $FORM{ADMIN_SELECT} || q{},
    SEL_LIST     => $Admins->list({ COLS_NAME => 1, WITH_SIP_NUMBER => 1, SIP_NUMBER => '_SHOW' }),
    SEL_KEY      => 'sip_number',
    SEL_VALUE    => 'login',
    ARRAY_NUM_ID => 1,
    NO_ID        => 1,
    MULTIPLE     => 1
  });

  my $datepicker = $html->form_daterangepicker({
    NAME      => 'DATE_START/DATE_END',
    FORM_NAME => 'search_form',
    VALUE     => $FORM{'DATE_START_DATE_END'},
  });

  form_search({ TPL => $html->tpl_show(_include('callcenter_report_search', 'Callcenter'), {
    DATEPICKER    => $datepicker,
    ADMINS_SELECT => $ADMINS_SELECT,
    DATE_START    => $FORM{DATE_START},
    DATE_END      => $FORM{DATE_END}
  }, { OUTPUT2RETURN => 1 })
  });

  $FORM{ADMIN_SELECT} =~ s/,/;/g if $FORM{ADMIN_SELECT};
  $FORM{ADMIN_SELECT} =~ s/ //g  if $FORM{ADMIN_SELECT};
  $Callcenter->{debug} = 1 if $FORM{DEBUG};

  my $calls_list = $Callcenter->callcenter_list_calls({
    DATE_START     => $FORM{DATE_START},
    DATE_END       => $FORM{DATE_END}. '23:59:59',
    OPERATOR_PHONE => $FORM{ADMIN_SELECT},
    DATE           => '_SHOW',
    STATUS         => '_SHOW',
    ADMIN          => '_SHOW',
    COLS_NAME      => 1
  });

  if (!$calls_list) {
    $html->message('err', $lang{NO_CALLS_FOR_DATE_OR_OPERATOR});
    return 1;
  }

  my (@assigned, @processed, @not_processed) = ();
  my %admin_statuses =();

  foreach my $call (@$calls_list) {
    $admin_statuses{$call->{admin}}{processed} += 1     if ($call->{status} == 3);
    $admin_statuses{$call->{admin}}{not_processed} += 1 if ($call->{status} == 4);
  }

  foreach my $admin_ (keys %admin_statuses) {
    push @assigned, $admin_;
    push @processed, $admin_statuses{$admin_}->{processed};
    push @not_processed, $admin_statuses{$admin_}->{not_processed};
  }


  print $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@assigned,
    DATA              => {
      $lang{PROCESSED}     => \@processed,
      $lang{NOT_PROCESSED} => \@not_processed,
    },
    BACKGROUND_COLORS => {
      $lang{PROCESSED}     => 'rgba(5, 99, 132, 0.7)',
      $lang{NOT_PROCESSED} => 'rgba(220, 53, 69, 0.7)',
    },
    OUTPUT2RETURN     => 1,
    FILL              => 'false',
    IN_CONTAINER      => 1
  });

  return 1;
}


#**********************************************************
=head2 callcenter_start_page($attr)

=cut
#**********************************************************
sub callcenter_start_page {

  my %START_PAGE_F = (
    callcenter_personal_call_statistics => $lang{PERSONAL_CALL_STATISTICS},
    callcenter_total_call_statistics    => $lang{TOTAL_CALL_STATISTICS},
    callcenter_last_proceeded_calls    => $lang{CALLS_HANDLER},
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 callcenter_personal_call_statistics() - dashboard report

=cut
#**********************************************************
sub callcenter_personal_call_statistics {

  my $avatar_logo = $admin->{AVATAR_LINK} ? "/images/$admin->{AVATAR_LINK}" : '/styles/default/img/admin/avatar5.png';

  $Callcenter->log_list({ AID => $admin->{AID} });

  return $html->tpl_show(_include('callcenter_call_statistics', 'Callcenter'), {
    ADMIN_AVATAR => $avatar_logo,
    ADMIN        => $admin->{ADMIN},
    DATE         => $DATE,
    TITLE        => $lang{PERSONAL_CALL_STATISTICS},
    TOTAL        => $Callcenter->{TOTAL} || 0,
    INCOMING     => $Callcenter->{INCOMING} || 0,
    OUTGOING     => $Callcenter->{OUTGOING} || 0
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 callcenter_total_call_statistics() - dashboard report

=cut
#**********************************************************
sub callcenter_total_call_statistics {

  $Callcenter->log_list();

  return $html->tpl_show(_include('callcenter_call_statistics', 'Callcenter'), {
    ADMIN_AVATAR => '/styles/default/img/modules/callcenter/support-team.png',
    DATE         => $DATE,
    TITLE        => $lang{TOTAL_CALL_STATISTICS},
    TOTAL        => $Callcenter->{TOTAL} || 0,
    INCOMING     => $Callcenter->{INCOMING} || 0,
    OUTGOING     => $Callcenter->{OUTGOING} || 0
  }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 callcenter_last_proceeded_calls() - dashboard report

=cut
#**********************************************************
sub callcenter_last_proceeded_calls {

  my $index_handler = get_function_index('callcenter_calls_handler');
  my $admin_info = $Admins->info($admin->{AID});
  my $admin_sip = $admin_info->{SIP_NUMBER};

  if(!$admin_sip){
    $html->message('err', "$lang{REPORT} $lang{CALLS_HANDLER}: $lang{MISSING_ADMIN_SIP_NUMBER}");
    return 1;
  }

  my %STATUSES = ( 3 => $lang{PROCESSED}, 4 => $lang{NOT_PROCESSED});

  my $calls_list = $Callcenter->callcenter_list_calls({
    OPERATOR_PHONE => $admin_info->{SIP_NUMBER},
    STATUS         => 3,
    USER_PHONE     => '_SHOW',
    DATE           => '_SHOW',
    ADMIN          => '_SHOW',
    PAGE_ROWS      => 20,
    COLS_NAME      => 1
  });

  my $sip = $html->button( "SIP: $admin_sip", "index=$index_handler&STATUS=3&OPERATOR_PHONE=$admin_sip" );
  my $sip_change = $html->button('', undef, {
    class       => "change",
    title       => $lang{CHANGE},
    ex_params   => qq/onclick=loadToModal('?qindex=$index_handler&sip_chg=1&OPERATOR_PHONE=$admin_sip')/,
    NO_LINK_FORMER => 1,
    SKIP_HREF      => 1,
  });

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{CALL_FROM}, $lang{CALL_TO}, $lang{STATUS}, $lang{DATE} ],
    caption     => $sip . $sip_change,
    ID          => 'CALLCENTER_PROCCEDED_CALLS',
  });

  if ($Callcenter->{TOTAL}){
    foreach my $line (@$calls_list) {
      $table->addrow(
        $line->{user_phone},
        $line->{operator_phone},
        $STATUSES{$line->{status}},
        substr($line->{date}, 0, 16)
      );
    }
  }

  return $table->show();
}

#**********************************************************
=head2 callcenter_calls_handler_statistic() - calls statistics

  Arguments:
    $attr -

  Examples:

=cut
#**********************************************************
sub callcenter_calls_handler_statistic {
  $FORM{DATE_START} ||= $date_from .' 00:00:00';
  $FORM{DATE_END} ||= $DATE .' 24:00:00';

  my $ADMINS_SELECT = $html->form_select('ADMIN_SELECT', {
    SELECTED     => $FORM{ADMIN_SELECT} || q{},
    SEL_LIST     => $Admins->list({ COLS_NAME => 1, WITH_SIP_NUMBER => 1, SIP_NUMBER => '_SHOW' }),
    SEL_KEY      => 'sip_number',
    SEL_VALUE    => 'login',
    ARRAY_NUM_ID => 1,
    NO_ID        => 1,
    MULTIPLE     => 1
  });
  my $datepicker = $html->form_daterangepicker({
    NAME      => 'DATE_START/DATE_END',
    FORM_NAME => 'search_form',
    VALUE     => $FORM{'DATE_START_DATE_END'},
  });

  form_search({ TPL => $html->tpl_show(_include('callcenter_report_search', 'Callcenter'), {
    DATEPICKER    => $datepicker,
    ADMINS_SELECT => $ADMINS_SELECT,
    DATE_START    => $FORM{DATE_START},
    DATE_END      => $FORM{DATE_END}
  }, { OUTPUT2RETURN => 1 })
  });

  $FORM{ADMIN_SELECT} =~ s/,/;/g if $FORM{ADMIN_SELECT};
  $FORM{ADMIN_SELECT} =~ s/ //g  if $FORM{ADMIN_SELECT};

  $Callcenter->{debug} = 1 if $FORM{DEBUG};

  my $calls_list = $Callcenter->callcenter_handler_statistic({
    DATE_START     => $FORM{DATE_START},
    DATE_END       => $FORM{DATE_END},
    ADMINS         => $FORM{ADMIN_SELECT},
    SORT           => $FORM{sort},
    DESC           => $FORM{desc},
    PAGE_ROWS      => 50,
    COLS_NAME      => 1
  });

  my $table = $html->table({
    width       => '100%',
    title       => [ $lang{ADMIN}, 'SIP', $lang{INCOMING}, $lang{OUTCOMING}, $lang{INCOMING_DURATION}, $lang{OUTCOMING_DURATION}],
    caption     => $lang{CALL_HANDLER_STATISTICS},
    ID          => 'CALLCENTER_HANDLER_STATISTICS',
    qs          => $pages_qs,
    pages       => $Callcenter->{TOTAL},
    EXPORT      => 1,
  });

  if ($Callcenter->{TOTAL}){
    foreach my $line (@$calls_list) {
      $table->addrow(
        $line->{admin},
        $line->{operator_phone},
        $line->{incoming},
        $line->{outcoming},
        $line->{incoming_duration} =~ /(\d{2}:\d{2}:\d{2})/,
        $line->{outcoming_duration} =~ /(\d{2}:\d{2}:\d{2})/,
      );
    }
  }

  print $table->show();
  return 1;
}

1;