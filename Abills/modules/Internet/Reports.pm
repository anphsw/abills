=head1 NAME

  Internet Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2byte time2sec sec2time _bp in_array);

our(
  %lang,
  $db,
  $admin,
  %conf,
  $pages_qs
);

our Abills::HTML $html;
my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

if($conf{INTERNET_TRAFFIC_DETAIL}) {
  require Internet::Traffic_detail;
}

require Internet::Ipoe_reports;

#**********************************************************
=head2 internet_use_all_monthes()

=cut
#**********************************************************
sub internet_use_allmonthes {

  $FORM{allmonthes} = 1;
  internet_report_use();

  return 1;
}

#**********************************************************
=head2 internet_report_use();

=cut
#**********************************************************
sub internet_report_use {

  my %HIDDEN = ();
  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});
  $HIDDEN{sid} = $sid if ($FORM{sid});

  my %ext_fields = (
    arpu         => $lang{ARPU},
    arpuu        => $lang{ARPPU},
    date         => $lang{DATE},
    month        => $lang{MONTH},
    login        => $lang{USER},
    fio          => $lang{FIO},
    hour         => $lang{HOURS},
    build        => $lang{ADDRESS_BUILD},
    district_name=> $lang{DISTRICT},
    street_name  => $lang{ADDRESS_STREET},
    login_count  => $lang{USERS},
    count        => $lang{COUNT},
    sum          => $lang{SUM},
    terminate_cause => "$lang{HANGUP} $lang{STATUS}",
    gid             => $lang{GROUPS},
    duration_sec    => $lang{DURATION},
    users_count     => $lang{USERS},
    sessions_count  => $lang{SESSIONS},
    traffic_recv    => $lang{SENT},
    traffic_sent    => $lang{RECV},
    traffic_sum     => $lang{TRAFFIC},
    traffic_2_sum   => "$lang{TRAFFIC} 2",
    company_name    => $lang{COMPANY}
  );

  reports(
    {
      DATE        => $FORM{DATE},
      HIDDEN      => \%HIDDEN,
      REPORT      => '',
      PERIOD_FORM => 1,
      EXT_TYPE    => {
        PER_MONTH       => $lang{PER_MONTH},
        DISTRICT        => $lang{DISTRICT},
        STREET          => $lang{STREET},
        BUILD           => $lang{BUILD},
        TP              => $lang{TARIF_PLANS},
        GID             => $lang{GROUPS},
        TERMINATE_CAUSE => 'TERMINATE_CAUSE',
        COMPANIES       => $lang{COMPANIES}
      },
    }
  );

  %CHARTS    = (
    TYPES => {
      login_count    => 'column',
      users_count    => 'column',
      sessions_count => 'column',
      traffic_recv   => 'column',
      traffic_sent   => 'column',
      duration_sec   => 'column'
    },
    PERIOD        => (! $FORM{TYPE} && ! $FORM{DATE}) ? 'month_stats' : ''
  );

  my $TP_NAMES = sel_tp();
  # my $list = $Tariffs->list({
  #   MODULE       => 'Dv;Internet',
  #   NEW_MODEL_TP => 1,
  #   COLS_NAME    => 1
  # });
  # foreach my $line (@$list) {
  #   $TP_NAMES{ $line->{id} } = $line->{name};
  # }

  if ($FORM{TERMINATE_CAUSE}) {
    $LIST_PARAMS{TERMINATE_CAUSE} = $FORM{TERMINATE_CAUSE};
  }
  elsif ($FORM{TP_ID}) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
  }

  if ($admin->{MAKE_ROWS}) {
    $LIST_PARAMS{PAGE_ROWS} = $admin->{MAKE_ROWS};
  }
  $Sessions->{debug}=1 if ($FORM{DEBUG});
  my Abills::HTML $table;
  my $list;
  our %DATA_HASH;

  if ($LIST_PARAMS{MONTH}) {
    delete($LIST_PARAMS{MONTH});
  }

  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'reports2',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'USERS_COUNT,SESSIONS_COUNT,TRAFFIC_RECV,TRAFFIC_SENT,DURATION_SEC,SUM',
    SKIP_USER_TITLE => (! $FORM{TYPE} || $FORM{TYPE} ne 'USER') ? 1 : undef,
    SELECT_VALUE    => {
      terminate_cause => internet_terminate_causes({ REVERSE => 1 }),
      gid             => sel_groups({ HASH_RESULT => 1 }),
      tp_id           => $TP_NAMES
    },
    CHARTS       => 'users_count,sessions_count,traffic_recv,traffic_sent,duration_sec',
    CHARTS_XTEXT => 'auto',
    EXT_TITLES   => \%ext_fields,
    FILTER_COLS  => {
      duration_sec    => '_sec2time_str',
      traffic_recv    => 'int2byte',
      traffic_sent    => 'int2byte',
      traffic_sum     => 'int2byte',
      terminate_cause => "search_link:internet_report_use:TERMINATE_CAUSE,$pages_qs",
      company_name    => "search_link:internet_report_use:COMPANY_NAME,$pages_qs",
      tp_id           => "search_link:internet_report_use:TP_ID,$pages_qs",
      month           => "search_link:internet_report_use:MONTH,$pages_qs",
      gid             => "search_link:internet_report_use:GID,$pages_qs",
      date            => "search_link:internet_report_use:DATE,DATE",
      login           => "search_link:from_users:UID,type=1,$pages_qs",
      build           => "search_link:internet_report_use:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
      district_name   => "search_link:internet_report_use:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
      street_name     => "search_link:internet_report_use:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
    },
    TABLE   => {
      width            => '100%',
      caption          => $lang{REPORTS},
      qs               => $pages_qs,
      pages            => $#{ $Sessions->{list} },
      ID               => 'REPORTS_DV_USE',
      EXPORT           => 1,
      SHOW_COLS_HIDDEN => {
        TYPE        => $FORM{TYPE},
        show        => 1,
        FROM_DATE   => $FORM{FROM_DATE},
        TO_DATE     => $FORM{TO_DATE},
      },
    },
    MAKE_ROWS     => 1,
    SEARCH_FORMER => 1,
  });

  print $html->make_charts({
    DATA          => \%DATA_HASH,
    TITLE         => 'Internet',
    TRANSITION    => 1,
    OUTPUT2RETURN => 1,
    %CHARTS
  });

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [
        [
          "$lang{USERS}: " . $html->b($Sessions->{USERS}),
          "$lang{SESSIONS}: " . $html->b($Sessions->{SESSIONS}),
          "$lang{TRAFFIC}: "
            . $html->b(int2byte($Sessions->{TRAFFIC}))
            . $html->br()
            . "$lang{TRAFFIC} IN: "
            . $html->b(int2byte($Sessions->{TRAFFIC_IN}))
            . $html->br()
            . "$lang{TRAFFIC} OUT: "
            . $html->b(int2byte($Sessions->{TRAFFIC_OUT}))
          ,

          "$lang{TRAFFIC} 2: " . $html->b(int2byte($Sessions->{TRAFFIC_2})) . $html->br() . "$lang{TRAFFIC} 2 IN: " . $html->b(int2byte($Sessions->{TRAFFIC_2_IN})) . $html->br() . "$lang{TRAFFIC} 2 OUT: " . $html->b(int2byte($Sessions->{TRAFFIC_2_OUT})),

          "$lang{DURATION}: " . $html->b(sec2time($Sessions->{DURATION_SEC}, { str => 1 })),
          "$lang{SUM}: " . $html->b($Sessions->{SUM})
        ]
      ],
      rowcolor => 'even'
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_report_debetors($attr)

=cut
#**********************************************************
sub internet_report_debetors {

  result_former({
    INPUT_DATA      => $Internet,
    FUNCTION        => 'report_debetors',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,FIO,PHONE,TP_NAME,DEPOSIT,CREDIT,DV_STATUS',
    FUNCTION_FIELDS => '',
    EXT_TITLES      => {
      'ip'          => 'IP',
      'netmask'     => 'NETMASK',
      'speed'       => $lang{SPEED},
      'port'        => $lang{PORT},
      'cid'         => 'CID',
      'filter_id'   => 'Filter ID',
      'tp_name'     => "$lang{TARIF_PLAN}",
      'internet_status'   => "Internet $lang{STATUS}",
      'internet_status_date' => "$lang{STATUS} $lang{DATE}",
      'online'      => 'Online',
      'internet_expire'   => "Internet $lang{EXPIRE}",
      'internet_login'    => "$lang{SERVICE} $lang{LOGIN}",
      'internet_password' => "$lang{SERVICE} $lang{PASSWD}"
    },
    TABLE           => {
      width      => '100%',
      caption    => "$lang{DEBETORS} - $lang{ONE_MONTH_DEBS}",
      qs         => $pages_qs,
      ID         => 'REPORT_DEBETORS',
      EXPORT     => 1,
    },
    MAKE_ROWS    => 1,
    MODULE       => 'Internet',
    TOTAL        => "TOTAL:$lang{TOTAL};TOTAL_DEBETORS_SUM:$lang{SUM}"
  });

  return 1;
}

#**********************************************************
=head2 internet_report_tp()

=cut
#**********************************************************
sub internet_report_tp {
  reports({
    PERIODS           => 1,
    NO_TAGS           => 1,
    NO_PERIOD         => 1,
    NO_MULTI_GROUP    => 1,
    PERIOD_FORM       => 1,
    NO_STANDART_TYPES => 1,
    col_md            => 'col-md-11'
  });

  my $list = $Internet->report_tp({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      caption     => $lang{TARIF_PLANS},
      width       => '100%',
      title       => [ "#", $lang{NAME}, $lang{TOTAL}, $lang{ACTIV}, $lang{DISABLE},
        $lang{DEBETORS}, "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}" ],
      ID          => 'REPORTS_TARIF_PLANS'
    }
  );

  my $internet_users_list_index = get_function_index('internet_users_list') || 0;

  my ($total_users, $totals_active, $total_disabled, $total_debetors)=(0,0,0,0);

  foreach my $line (@$list) {
    $line->{id} = 0 if (! defined($line->{id}));
    $line->{tp_id} = 0 if (! defined($line->{tp_id}));

    my $main_link = "search=1&index=$internet_users_list_index&TP_ID=$line->{tp_id}";

    $main_link .= "&GID=$FORM{GID}" if $FORM{GID};

    $table->addrow(
      $line->{id},
      $html->button($line->{name}, "$main_link"),
      $html->button($line->{counts}, "$main_link"),
      $html->button($line->{active}, "$main_link&INTERNET_STATUS=0"),
      $html->button($line->{disabled}, "$main_link&INTERNET_STATUS=1"),
      $html->button($line->{debetors}, "$main_link&DEPOSIT=<0&search=1"),
      sprintf('%.2f', $line->{arppu} || 0),
      sprintf('%.2f', $line->{arpu} || 0)
    );

    $total_users    += $line->{counts};
    $totals_active  += $line->{active};
    $total_disabled += $line->{disabled};
    $total_debetors += $line->{debetors};
  }

  $table->addrow(
    '',
    $lang{TOTAL},
    $total_users,
    $totals_active,
    $total_disabled,
    $total_debetors
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_pools_report()

=cut
#**********************************************************
sub internet_pools_report {
  my ($attr) = @_;
  $attr //= \%FORM;

  my $DDebug = 0;

  require Nas;
  Nas->import();
  my Nas $Nas = Nas->new($db, \%conf, $admin);

  # Get dv static ips
  my $static_assigned_list = $Internet->list({
    IP_NUM    => '>0.0.0.0',
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    GROUP_BY  => 'internet.id'
  });
  _error_show($Internet);

  my @static_ips = map {$_->{ip_num}} @{$static_assigned_list};

  # Get online ips
  my $active_assigned_list = $Sessions->online({
    CLIENT_IP_NUM => '_SHOW',
    NAS_ID        => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 100000
  });
  _error_show($Sessions);

  my @online_ips = map {$_->{client_ip_num}} @{$active_assigned_list};

  # Get pools
  my $pools_list = $Nas->nas_ip_pools_list({
    COLS_NAME        => 1,
    INTERNET         => in_array('Internet', \@MODULES),
    SHOW_ALL_COLUMNS => 1,
    PG               => $FORM{pg}
  });
  _error_show($Nas);

  my %pools_by_id = map {$_->{id} => $_} @{$pools_list};

  # Assign ips to pools
  my %ips_for_pool = ();

  my $find_pool_for_address = sub {
    my $ip_addr_num = shift;
    foreach my $pool ( @{$pools_list} ) {
      return $pool->{id} if ( $ip_addr_num >= $pool->{ip} && $ip_addr_num < $pool->{last_ip_num} );
    }

    return 0;
  };

  my @static_without_pool = ();
  foreach my $static_addr ( @static_ips ) {
    my $pool_id = $find_pool_for_address->($static_addr);

    if ( !$pool_id ) {
      push (@static_without_pool, $static_addr);
      next;
    }

    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;

    if ( !$pools_by_id{$pool_id}->{static} ) {
      # Showing errornous assigning static ip from dynamic pool
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 2;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 1;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }

    $ips_for_pool{$pool_id}->{count} += 1;
  }

  my @dynamic_without_pool = ();
  foreach my $online_addr ( @online_ips ) {
    # Skip if found static ip in online
    next if ( grep {$_ == $online_addr} @static_ips );

    my $pool_id = $find_pool_for_address->($online_addr);

    if ( !$pool_id ) {
      push (@dynamic_without_pool, $online_addr);
      next;
    }

    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;

    # Showing errornous assigning static ip from dynamic pool
    if ( $pools_by_id{$pool_id}->{static} ) {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 1;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 0;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }

    $ips_for_pool{$pool_id}->{count} += 1;

  }

  # Check pool sizes and build fillness data
  foreach my $pool_id ( sort keys %ips_for_pool ) {

    my $dynamic = $ips_for_pool{$pool_id}->{dynamic_count} / $pools_by_id{$pool_id}->{ip_count};
    my $static = $ips_for_pool{$pool_id}->{static_count} / $pools_by_id{$pool_id}->{ip_count};
    my $free = 1 - ($dynamic + $static);

    $ips_for_pool{$pool_id}->{usage}->{dynamic} = sprintf("%.2f", $dynamic * 100);
    $ips_for_pool{$pool_id}->{usage}->{static} = sprintf("%.2f", $static * 100);
    $ips_for_pool{$pool_id}->{usage}->{free} = sprintf("%.2f", $free * 100);
  }

  _bp('Pool using with percents', \%ips_for_pool) if ( $DDebug );
  return \%ips_for_pool if ( $attr->{RETURN_USAGE} );

  my %charts = ();

  foreach my $pool_id ( sort keys %pools_by_id ) {

    my $normal_fill = ($pools_by_id{$pool_id}->{static}) ? 'static' : 'dynamic';
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';

    if ( !$ips_for_pool{$pool_id} || !$ips_for_pool{$pool_id}->{usage} ) {
      $charts{$pool_id} = $html->chart({
        TYPE              => 'pie',
        X_LABELS          => [ $lang{FREE} ],
        DATA              => {
          'USAGE' => [ 100 ],
        },
        HIDE_LEGEND       => 1,
        BACKGROUND_COLORS => {
          'USAGE' => [ '#4CAF50' ],
        },
        OUTPUT2RETURN     => 1,
      });
      next;
    }

    my @usage = (
      $ips_for_pool{$pool_id}->{usage}->{free},
      $ips_for_pool{$pool_id}->{usage}->{$normal_fill},
    );
    push (@usage,
      $ips_for_pool{$pool_id}->{usage}->{$errornous_fill}) if ( $ips_for_pool{$pool_id}->{usage}->{$errornous_fill} > 0 );

    $charts{$pool_id} = $html->chart({
      TYPE              => 'pie',
      X_LABELS          => [ $lang{FREE}, $lang{USED}, $lang{ERROR} ],
      DATA              => {
        'USAGE' => \@usage,
      },
      HIDE_LEGEND       => 1,
      BACKGROUND_COLORS => {
        'USAGE' => [ '#4CAF50', '#FF9800', '#F44336' ],
      },
      OUTPUT2RETURN     => 1,
    });
  }

  my $pools_index = get_function_index('form_ip_pools');

  my @rows = ();
  my $result = '';
  my $wrap_size = ($attr->{WRAP_SIZE} || '3');
  my $charts_in_row = 12 / $wrap_size;
  my $current_charts_in_row = 0;

  foreach my $pool_id ( sort keys %pools_by_id ) {
    my $pool = $pools_by_id{$pool_id};
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';


    my $internet_users_index = get_function_index('internet_users_list');
    my $users_button = $html->button($ips_for_pool{$pool_id}->{count} // 0,
      "index=$internet_users_index&IP_POOL=$pool_id&search=1&search_form=1");

    $result .= $html->tpl_show(_include('internet_pool_report_single', 'Internet'),
      {
        NAME        => $html->button($pool->{pool_name}, "index=$pools_index&chg=$pool->{id}"),
        NAS_NAME    => $pool->{static} ? $lang{STATIC} : ($pool->{nas_name} || $lang{NO}),
        IP_RANGE    => $pool->{first_ip} . '-' . $pool->{last_ip},

        USED        => $pool->{static} ? $users_button : $ips_for_pool{$pool_id}->{count} // 0,
        FREE        => $ips_for_pool{$pool_id}->{usage}{free} // 100,
        ERROR       => $ips_for_pool{$pool_id}->{usage}{$errornous_fill} // 0,

        USAGE_CHART => $charts{$pool_id},
      },
      { OUTPUT2RETURN => 1 }
    );

    $current_charts_in_row += 1;
    if ( $current_charts_in_row >= $charts_in_row ) {
      push (@rows, $html->element('div', $result, { class => 'row' }));
      $result = '';
      $current_charts_in_row = 0;
    }
  }

  my $ip_pools_page = '';
  my $next_page = '';
  my $back_page = $SELF_URL . '?index=' . get_function_index('internet_pools_report') . '&pg=0';

  for (my $iterations = 0; $iterations <= $Nas->{TOTAL}; $iterations++) {
    if (($iterations != 0) && ($iterations % 25) == 0) {
      $next_page = $SELF_URL . '?index=' . get_function_index('internet_pools_report') . '&pg=' . $iterations;

      $ip_pools_page .= $html->element('a', $iterations, {
        href => $next_page,
        id   => 'btn_page_' . $iterations,
        class => 'btn btn-secondary'
      });
    }
  }

  $html->tpl_show(_include('internet_page_ippools', 'Internet'), {
    PAGE_IP_POOLS   => $ip_pools_page,
    PG_INDEX        => $FORM{pg},
    FIRST_PAGE      => $back_page,
    FAST_FIST_PAGE  => $back_page,
    FAST_END_PAGE   => $next_page,
  });

  # Wrap last row
  push (@rows, $html->element('div', $result, { class => 'row' })) if ( $result );

  my $return_html = ($attr->{RETURN_HTML} || $attr->{OUTPUT2RETURN});
  $result = $html->element('div', join('', @rows), {
      OUTPUT2RETURN => $return_html
    }
  );
  return $result if ( $attr->{RETURN_HTML} );

  if ( !$attr->{OUTPUT2RETURN} ) {
    print $result;
  }

  return \%charts;
}

#**********************************************************
=head2 internet_user_outflow()

=cut
#**********************************************************
sub internet_user_outflow {

  use Address;
  my $Address = Address->new($db, $admin, \%conf);

  my $builds_sel = $html->form_select('BUILD_ID', {
    SELECTED    => $FORM{BUILD_ID} || 0,
    NO_ID       => 1,
    SEL_LIST    => $Address->build_list({
      STREET_ID => $FORM{STREET_ID} || '_SHOW',
      NUMBER    => '_SHOW',
      COLS_NAME => 1,
      SORT      => 'b.number+0',
      PAGE_ROWS => 999999
    }),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'number',
    SEL_OPTIONS => { 0 => '--' },
  });

  reports({
    PERIOD_FORM => 1,
    NO_PERIOD   => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
    EXT_SELECT  => {
      DISTRICT   => { LABEL => $lang{DISTRICT}, SELECT => sel_districts({ SEL_OPTIONS => { 0 => '--' }, DISTRICT_ID => $FORM{DISTRICT_ID} }) },
      STREET     => { LABEL => $lang{STREET}, SELECT => sel_streets({ SEL_OPTIONS => { 0 => '--' }, STREET_ID => $FORM{STREET_ID} }) },
      _BUILD     => { LABEL => $lang{BUILD}, SELECT => $builds_sel },
    }
  });

  my $outflow_users = $Internet->users_outflow_report({
    LOGIN     => '_SHOW',
    LAST_FEE  => '_SHOW',
    TP_NAME   => '_SHOW',
    DEPOSIT   => '_SHOW',
    COLS_NAME => 1,
    %FORM
  });

  my @uids = ();
  map push(@uids, $_->{uid}), @{$outflow_users};
  my $uids_str = $Internet->{TOTAL} > 0 ? join(';', @uids) : '';

  my $outflow_users_table = $html->table({
    width      => '100%',
    caption    => $lang{USERS_OUTFLOW},
    title      => [ 'UID', $lang{LOGIN}, $lang{TARIF_PLAN}, "Последнее списание", $lang{DEPOSIT} ],
    ID         => 'INTERNET_OUTFLOW_USERS',
    DATA_TABLE => 1
  });

  foreach my $user (@{$outflow_users}) {
    my $user_btn = $html->button($user->{login}, "get_index=form_user&header=1&full=1&UID=$user->{uid}");
    $outflow_users_table->addrow($user->{uid}, $user_btn, $user->{tp_name}, $user->{last_fee}, $user->{deposit});
  }

  print $outflow_users_table->show();

  $html->tpl_show(_include('internet_user_outflow_report', 'Internet'), {
    BUILDS_OUTFLOW  => _internet_get_builds_outflow_charts($uids_str),
    STREETS_OUTFLOW => _internet_get_streets_outflow_charts($uids_str)
  });

}

#**********************************************************
=head2 _internet_get_builds_outflow_charts()

=cut
#**********************************************************
sub _internet_get_builds_outflow_charts {
  my ($uids) = @_;

  return '' if !$uids;

  my @builds_outflow = ();
  my @builds_total = ();
  my @builds_labels = ();

  my $users_by_build = $Internet->users_outflow_by_address({
    USERS_COUNT  => '_SHOW',
    LOCATION_ID  => '<>0',
    BUILD_NUMBER => '_SHOW',
    STREET_NAME  => '_SHOW',
    UID          => $uids,
    SORT         => 'users_count',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    PAGE_ROWS    => 5
  });

  my @builds_id = ();
  foreach my $build (sort { $a->{location_id} <=> $b->{location_id} } @{$users_by_build}) {
    push(@builds_outflow, $build->{users_count});
    push(@builds_labels, join(', ', ($build->{street_name}, $build->{build_number})));
    push(@builds_id, $build->{location_id});
  }

  my $builds_total_users = $Internet->users_outflow_by_address({
    USERS_COUNT  => '_SHOW',
    LOCATION_ID  => join(';', @builds_id),
    BUILD_NUMBER => '_SHOW',
    STREET_NAME  => '_SHOW',
    COLS_NAME    => 1,
  });

  foreach my $build (sort { $a->{location_id} <=> $b->{location_id} } @{$builds_total_users}) {
    push(@builds_total, $build->{users_count});
  }

  return $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@builds_labels,
    DATA              => {
      $lang{USERS_OUTFLOW} => \@builds_outflow,
      $lang{TOTAL_USERS}   => \@builds_total,
    },
    BACKGROUND_COLORS => {
      $lang{USERS_OUTFLOW} => 'rgba(204, 22, 22, 0.5)',
      $lang{TOTAL_USERS}   => 'rgba(2, 99, 2, 0.5)',
    },
    OUTPUT2RETURN     => 1,
  });
}

#**********************************************************
=head2 _internet_get_streets_outflow_charts()

=cut
#**********************************************************
sub _internet_get_streets_outflow_charts {
  my ($uids) = @_;

  return '' if !$uids;

  my @streets_outflow = ();
  my @streets_total = ();
  my @streets_labels = ();

  my $users_by_street = $Internet->users_outflow_by_address({
    USERS_COUNT => '_SHOW',
    LOCATION_ID => '<>0',
    STREET_ID   => '_SHOW',
    STREET_NAME => '_SHOW',
    UID         => $uids,
    SORT        => 'users_count',
    DESC        => 'DESC',
    GROUP_BY    => 'GROUP BY s.id',
    COLS_NAME   => 1,
    PAGE_ROWS   => 5
  });

  my @streets_id = ();
  foreach my $street (sort { $a->{street_id} <=> $b->{street_id} } @{$users_by_street}) {
    push(@streets_outflow, $street->{users_count});
    push(@streets_labels, $street->{street_name});
    push(@streets_id, $street->{street_id});
  }

  my $streets_total_users = $Internet->users_outflow_by_address({
    USERS_COUNT => '_SHOW',
    STREET_ID   => join(';', @streets_id),
    COLS_NAME   => 1,
  });

  foreach my $street (sort { $a->{street_id} <=> $b->{street_id} } @{$streets_total_users}) {
    push(@streets_total, $street->{users_count});
  }

  return $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@streets_labels,
    DATA              => {
      $lang{USERS_OUTFLOW} => \@streets_outflow,
      $lang{TOTAL_USERS}   => \@streets_total,
    },
    BACKGROUND_COLORS => {
      $lang{USERS_OUTFLOW} => 'rgba(204, 22, 22, 0.5)',
      $lang{TOTAL_USERS}   => 'rgba(2, 99, 2, 0.5)',
    },
    OUTPUT2RETURN     => 1,
  });
}

1;
