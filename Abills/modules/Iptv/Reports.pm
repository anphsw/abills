=head2 NAME

  Iptv Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Iptv,
  %lang,
  %conf,
  $admin,
  $db,
  $html,
  $Tv_service
);

my $Tariffs = Tariffs->new($db, \%conf, $admin);

#***********************************************************
=head2 iptv_report($type, $attr)

=cut
#***********************************************************
sub iptv_report{
  my ($attr) = @_;

  my $REPORT = "Module: Iptv\n";
  %LIST_PARAMS = %{ $attr->{LIST_PARAMS} } if (defined( $attr->{LIST_PARAMS} ));

  return $REPORT;
}

#**********************************************************
=head2 iptv_use_allmonthes();

=cut
#**********************************************************
sub iptv_use_allmonthes{

  $FORM{allmonthes} = 1;

  iptv_use();
  return 1;
}

#**********************************************************
=head2 iptv_use() - Iptv Reports

=cut
#**********************************************************
sub iptv_use {

  result_former({
    INPUT_DATA      => $Iptv,
    FUNCTION        => 'services_reports',
    BASE_FIELDS     => 5,
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id         => '#',
      service_id => '#',
      name       => $lang{NAME},
      active     => $lang{ACTIV},
      total      => $lang{SUBSCRIBES},
      users      => $lang{USERS},
    },
    FILTER_COLS     => {
      users => '_iptv_users_link::USERS,SERVICE_ID',
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SERVICES},
      qs      => $pages_qs,
      pages   => $Iptv->{TOTAL},
      ID      => 'IPTV_SERVICES_REPORT',
      EXPORT  => 1
    },
    MAKE_ROWS       => 1,
    TOTAL           => 'TOTAL_USERS:USERS;TOTAL_ACTIVE_USERS:ACTIV;SUBSCRIBES:SUBSCRIBES'
  });

  return 1;
}

#**********************************************************
=head2 _iptv_users_link($users, $attr)

=cut
#**********************************************************
sub _iptv_users_link {
  my ($users, $attr) = @_;

  my $service_id = $attr->{VALUES}{SERVICE_ID} || '';
  return $users if !defined $service_id;

  return $html->button($users, "index=" . get_function_index('iptv_users_list') .
    "&search_form=1&search=1&SERVICE_ID=$service_id");
}

#**********************************************************
=head2 iptv_reports_channels($attr) - Reports: channels use

=cut
#**********************************************************
sub iptv_reports_channels{
  #my ($attr) = @_;

  my $list = $Iptv->reports_channels_use2({ %LIST_PARAMS, COLS_NAME => 1, PAGE_ROWS => 9999 });

  if ( !defined $list || ref $list ne 'ARRAY' ){
    $html->message( 'warn', $lang{ERROR}, $lang{ERR_NOT_EXISTS} );
    return 1;
  };

  my $total_list = ();
  foreach my $line ( @$list) {
    $total_list->{$line->{num}}->{total} //= 0;
    $total_list->{$line->{num}}->{total_debetors} //= 0;
    $total_list->{$line->{num}}->{total_disabled} //= 0;
    $total_list->{$line->{num}}->{name} = $line->{name};
    $total_list->{$line->{num}}->{total}++;
    $total_list->{$line->{num}}->{total_debetors}++ if ($line->{deposit} && $line->{deposit} < 0);
    $total_list->{$line->{num}}->{total_disabled}++ if ($line->{disable});
  }

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{CHANNELS}",
    title   => [ $lang{NUM}, $lang{NAME}, '', $lang{USERS}, '', $lang{DEBETORS}, $lang{DISABLED} ],
    ID      => 'IPTV_CHANNELS',
  });

  foreach my $key (sort keys %$total_list ){
    my $button = '';
    if ($total_list->{$key}->{total} > 10) {
      $button = $html->button($total_list->{$key}->{total}, "index=$index&list=$key", { class => 'label label-primary' });
    }
    elsif ($total_list->{$key}->{total} > 0) {
      $button = $html->button($total_list->{$key}->{total}, "index=$index&list=$key", { class => 'label label-success' });
    }
    else {
      $button = $html->button($total_list->{$key}->{total}, "index=$index", { class => 'label label-default' });
    }
    my $deb_button = $html->button($total_list->{$key}->{total_debetors}, "index=$index&list=$key&deb=1", { class => 'label label-default' });

    $table->addrow( $html->b( $key ), $total_list->{$key}->{name}, '', $button, '', $deb_button);
  }

  print $table->show();

  return 1 unless $FORM{list};
  my $user_table = $html->table({

    width   => '100%',
    caption => "$lang{USERS}",
    title   => [ '', $lang{CHANNEL}, '', $lang{USER}, $lang{DEPOSIT} ],
    ID      => 'CHANNEL_USERS',
    qs      => "&list=$FORM{list}",
  });

  foreach my $line (@$list) {
    next if ($FORM{list} != $line->{num});
    next if ($FORM{deb} && $line->{deposit} >= 0);
    next if ($FORM{dis} && !$line->{disable});

    $line->{deposit} //= 0;
    $line->{user} //= '';
    $line->{uid} //= 0;

    my $user_btn = $html->button($line->{user}, "index=" . get_function_index('iptv_user') . "&UID=$line->{uid}", {});
    $user_table->addrow('', $line->{name}, '', $user_btn, sprintf("%.2f", $line->{deposit}));
  }
  print $user_table->show();

  
  return 1;
}

#**********************************************************
=head iptv_console($attr) - Quick information

  Arguments:
    $attr

=cut
#**********************************************************
sub iptv_console {
  my($attr) = @_;

  my $services = $html->form_main({
    CONTENT => tv_services_sel({ AUTOSUBMIT => 'form'}),
    HIDDEN  => {
      index => $index,
      show  => 1
    },
    class   => 'form-inline ml-auto flex-nowrap',
  });

  func_menu({ $lang{NAME} => $services });

  return 1 unless $FORM{SERVICE_ID};

  $Tv_service = tv_load_service('', { SERVICE_ID => $FORM{SERVICE_ID} });
  return 1 if (!$Tv_service);

  if ($Tv_service->{SERVICE_CONSOLE}) {
    my $fn = $Tv_service->{SERVICE_CONSOLE};
    &{\&$fn}({ %FORM, %{$attr}, %{$Iptv}, SERVICE_ID => $FORM{SERVICE_ID} });
  }
  elsif ($Tv_service->can('reports')) {
    $LIST_PARAMS{TYPE} = $FORM{TYPE} if ($FORM{TYPE});

    $Tv_service->reports({ %FORM, %LIST_PARAMS, SERVICE_ID => $FORM{SERVICE_ID} });
    _error_show($Tv_service);

    return 0 unless $Tv_service->{REPORT};
    result_former({
      FUNCTION_FIELDS => $Tv_service->{FUNCTION_FIELDS},
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id   => 'ID',
        name => $lang{NAME}
      },
      TABLE           => {
        width   => '100%',
        caption => ($Tv_service->{REPORT_NAME} && $lang{$Tv_service->{REPORT_NAME}}) ? $lang{$Tv_service->{REPORT_NAME}} : $Tv_service->{REPORT_NAME},
        qs      => "&list=" . ($FORM{list} || '') . (($FORM{SERVICE_ID}) ? "&SERVICE_ID=$FORM{SERVICE_ID}" : ''),
        EXPORT  => 1,
        ID      => 'TV_REPORTS',
        header  => $Tv_service->{MENU}
      },
      DATAHASH        => $Tv_service->{REPORT},
      SKIPP_UTF_OFF   => ($Tv_service && $Tv_service->{SERVICE_NAME} eq 'Smotreshka') ? undef : 1,
      TOTAL           => 1
    });

    print $Tv_service->{REPORT_SCRIPT} if $Tv_service->{REPORT_SCRIPT};

  }

  return 1;
}

#**********************************************************
=head2 iptv_users_fees($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub iptv_users_fees {
  require Control::Reports;
  reports({
    EXT_SELECT      => tv_services_sel(),
    EXT_SELECT_NAME => $lang{SERVICES},
    PERIOD_FORM     => 1,
    DATE_RANGE      => 1,
    NO_GROUP        => 1,
    NO_TAGS         => 1
  });

  $FORM{show} ||= 1 if ($FORM{FROM_DATE} && $FORM{TO_DATE});

  return 0 unless $FORM{show} || $FORM{EXPORT_CONTENT};

  my $tps = $Tariffs->list({ MODULE => 'Iptv', COLS_NAME => 1, SERVICE_ID => $FORM{SERVICE_ID} || '_SHOW' });
  my $channels_list = $Iptv->iptv_get_channels_by_service({ SERVICE_ID => $FORM{SERVICE_ID} });

  my @tp_names = ();
  map push(@tp_names, $_->{name}), @{$tps};
  map push(@tp_names, $_->{name}), @{$channels_list};

  my $users_fees = $Iptv->iptv_users_fees_by_service({ TP_NAMES => \@tp_names, DESCRIBE => "$lang{TV}:", %FORM });

  my $qs = $FORM{SERVICE_ID} ? "&SERVICE_ID=$FORM{SERVICE_ID}" : '';
  $qs .= "&FROM_DATE=$FORM{FROM_DATE}" if $FORM{FROM_DATE};
  $qs .= "&TO_DATE=$FORM{TO_DATE}" if $FORM{TO_DATE};

  my $table = $html->table({
    width      => '100%',
    caption    => "$lang{TV}: $lang{FEES}",
    title      => [ $lang{LOGIN}, $lang{DATE}, $lang{SUM}, $lang{DESCRIBE} ],
    ID         => 'IPTV_FEES',
    FIELDS_IDS => [ 'LOGIN', 'DATE', 'SUM', 'DESCRIPTION' ],
    qs         => $qs,
    EXPORT     => 1,
  });

  my $total_table = $html->table({
    width   => '100%',
    title   => [ '', '' ],
    ID      => 'IPTV_TOTAL_FEES',
  });

  my $total_sum = 0;
  foreach my $user_fees (@{$users_fees}) {
    my $login_link = $html->button($user_fees->{login}, 'index=' . get_function_index('form_users') . "&UID=$user_fees->{uid}");
    $table->addrow($login_link, $user_fees->{date}, $user_fees->{sum}, $user_fees->{dsc});
    $total_sum += $user_fees->{sum};
  }

  $total_table->addrow($html->b($lang{TOTAL}) . ": $Iptv->{TOTAL}", $html->b($lang{SUM}) . ": $total_sum");

  print $table->show();
  print $total_table->show();

  return 0;
}


#**********************************************************
=head2 iptv_report_tp($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub iptv_report_tp {
  require Control::Reports;

  reports({
    PERIODS           => 1,
    NO_TAGS           => 1,
    NO_PERIOD         => 1,
    NO_MULTI_GROUP    => 1,
    PERIOD_FORM       => 1,
    NO_STANDART_TYPES => 1,
    col_md            => 'col-md-11'
  });

  if ($FORM{DEBUG}) {
    $Iptv->{debug} = 1;
  }

  my $list = $Iptv->report_tp({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      caption     => $lang{TARIF_PLANS},
      width       => '100%',
      title       => [ '#', $lang{NUMBER}, 'ID', $lang{NAME}, $lang{TOTAL}, $lang{ACTIV}, $lang{DISABLE},
        $lang{DEBETORS}, "$lang{REDUCTION} 100%", "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}", $lang{MONTH_FEE}, $lang{DAY_FEE}, $lang{GROUP}, $lang{SERVICE}, ],
      ID          => 'REPORTS_IPTV_TARIF_PLANS',
      EXPORT      => 1,
    }
  );

  my $iptv_users_list_index = get_function_index('iptv_users_list') || 0;

  my ($total_users, $totals_active, $total_disabled, $total_debetors, $total_reduction) = (0,0,0,0,0);
  my $i = 1;

  foreach my $line (@$list) {
    $line->{id} = 0 if (! defined($line->{id}));
    $line->{tp_id} = 0 if (! defined($line->{tp_id}));

    my $main_link = "search=1&index=$iptv_users_list_index&TP_ID=$line->{tp_id}";

    $main_link .= "&GID=$FORM{GID}" if $FORM{GID};

    $table->addrow(
      $i,
      $line->{id},
      $line->{tp_id},
      $html->button($line->{name}, "$main_link"),
      ($line->{counts} > 0 )          ? $html->button($line->{counts}, "$main_link")                        : 0,
      ($line->{active} > 0 )          ? $html->button($line->{active}, "$main_link&SERVICE_STATUS=0")      : 0,
      ($line->{disabled} > 0 )        ? $html->button($line->{disabled}, "$main_link&SERVICE_STATUS=1")    : 0,
      ($line->{debetors} > 0 )        ? $html->button($line->{debetors}, "$main_link&DEPOSIT=<0&search=1")  : 0,
      ($line->{users_reduction} > 0 ) ? $html->button($line->{users_reduction}, "$main_link&REDUCTION=100") : 0,
      sprintf('%.2f', $line->{arppu} || 0),
      sprintf('%.2f', $line->{arpu} || 0),
      $line->{month_fee},
      $line->{day_fee},
      $line->{group_name},
      $line->{service_name},
    );

    $i++;
    $total_users    += $line->{counts};
    $totals_active  += $line->{active};
    $total_disabled += $line->{disabled};
    $total_debetors += $line->{debetors};
    $total_reduction += $line->{users_reduction};
  }

  $table->addrow(
    '', '', '',
    $html->b($lang{TOTAL}),
    $html->b($total_users),
    $html->b($totals_active),
    $html->b($total_disabled),
    $html->b($total_debetors),
    $html->b($total_reduction),
    '', '', '', '', '', '',
  );

  print $table->show();

  return 1;
}
1;