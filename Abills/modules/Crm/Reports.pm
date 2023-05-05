use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Reports - crm reports

=cut

our (
  $Crm,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

require Control::Address_mng;
use Address;
my $Address = Address->new($db, $admin, \%conf);

#**********************************************************
=head2 crm_competitors_tp_report($attr)

=cut
#**********************************************************
sub crm_competitors_tp_report {

  _crm_report_form();

  my $min_tps = $Crm->crm_competitors_tps_list({
    NAME            => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 5,
    SORT            => 'cct.month_fee',
    %FORM
  });

  my $max_tps = $Crm->crm_competitors_tps_list({
    NAME            => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 5,
    SORT            => 'cct.month_fee',
    DESC            => 'desc',
    %FORM
  });

  $html->tpl_show(_include('crm_competitors_tps_report', 'Crm'), {
    MIN_PRICE_CHART => _crm_make_tps_chart($min_tps),
    MAX_PRICE_CHART => _crm_make_tps_chart($max_tps)
  });

  _crm_popular_tariff_plans();
}

#**********************************************************
=head2 crm_competitors_users_report()

=cut
#**********************************************************
sub crm_competitors_users_report {

  _crm_report_form();

  my %sort_array = (
    '2' => 'users',
    '3' => 'avg_assessment',
    '4' => 'total_assessment'
  );

  $FORM{sort} = $sort_array{$FORM{sort}} if $FORM{sort} && $sort_array{$FORM{sort}};

  my $competitors = $Crm->crm_competitors_users_list({
    COMPETITOR_NAME  => '_SHOW',
    COMPETITOR_ID    => '_SHOW',
    USERS            => '_SHOW',
    TOTAL_ASSESSMENT => '_SHOW',
    AVG_ASSESSMENT   => '_SHOW',
    COLS_NAME        => 1,
    %FORM
  });

  my $competitors_users = $html->table({
    width   => '100%',
    caption => "$lang{COMPETITORS}: $lang{LEADS}",
    title   => [ $lang{COMPETITOR}, "$lang{LEADS} ($lang{COUNT})", $lang{AVERAGE_RATING}, $lang{CRM_NUMBER_OF_RATINGS} ],
    ID      => 'CRM_COMPETITORS_USERS'
  });

  foreach my $competitor (@{$competitors}) {
    my $competitor_btn = $html->button($competitor->{competitor_name},
      "get_index=crm_competitors&header=1&full=1&chg=$competitor->{competitor_id}");

    $competitors_users->addrow($competitor_btn, _crm_get_competitor_users_button($index, $competitor->{users}, $competitor->{competitor_id}) || $competitor->{users},
      crm_assessment_stars($competitor->{avg_assessment} || 0), $competitor->{total_assessment});
  }

  print $competitors_users->show();

  _crm_competitor_users_list();
}

#**********************************************************
=head2 crm_competitors_report($attr)

=cut
#**********************************************************
sub crm_competitors_report {

  _crm_report_form({ HIDE_COMPETITOR_SELECT => 1 });

  my $competitors = $Crm->crm_competitor_list({
    NAME            => '_SHOW',
    DESCR           => '_SHOW',
    SITE            => '_SHOW',
    CONNECTION_TYPE => '_SHOW',
    COLS_NAME       => 1,
    %FORM
  });


  my $competitors_table = $html->table({
    width   => '100%',
    caption => $lang{COMPETITORS},
    title   => [ 'Id', $lang{NAME}, $lang{COMPETITOR_SITE}, $lang{CONNECTION_TYPE}, $lang{DESCRIBE} ],
    ID      => 'CRM_COMPETITORS',
    EXPORT  => 1
  });

  my $competitors_index = get_function_index('crm_competitors');
  foreach (@{$competitors}) {
    my $site = $_->{site} ? $html->button('', '', {
      GLOBAL_URL => $_->{site},
      target     => '_blank',
      class      => 'btn btn-sm btn-primary',
      ICON       => 'fa fa-globe',
    }) : '';

    my $competitor_button = $html->button($_->{name}, "index=$competitors_index&chg=$_->{id}", { target => '_blank' });

    $competitors_table->addrow($_->{id}, $competitor_button, $site, $_->{connection_type}, $_->{descr});
  }

  print $competitors_table->show();
}

#**********************************************************
=head2 crm_top_admins()

=cut
#**********************************************************
sub crm_top_admins {

  my $top_admins = $Crm->crm_lead_list({
    LEADS_NUMBER => '_SHOW',
    ADMIN_NAME   => '_SHOW',
    RESPONSIBLE  => '_SHOW',
    GROUP_BY     => 'cl.responsible',
    SORT         => 'leads_number',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    PAGE_ROWS    => 999999
  });

  my $admins_table = $html->table({
    width   => '100%',
    caption => $lang{CRM_TOP_ADMINS},
    title   => [ '#', $lang{ADMIN}, "$lang{LEADS} ($lang{COUNT})" ],
    ID      => 'CRM_TOP_ADMINS'
  });

  foreach my $responsible (@{$top_admins}) {
    $admins_table->addrow($responsible->{responsible} || '',
      $responsible->{responsible} ? ($responsible->{admin_name} || '') : $lang{CRM_WITHOUT_RESPONSIBLE}, $responsible->{leads_number});
  }

  return $admins_table->show();
}

#**********************************************************
=head2 _crm_popularity_tariff_plans($attr)

=cut
#**********************************************************
sub _crm_popular_tariff_plans {

  my $tps = $Crm->crm_competitors_popular_tps_list({
    NAME            => '_SHOW',
    COMPETITOR_NAME => '_SHOW',
    COMPETITOR_ID   => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    SORT            => 'leads_number',
    DESC            => 'desc',
    COLS_NAME       => 1,
    PAGE_ROWS       => 25,
    %FORM
  });

  my $popular_tps = $html->table({
    width   => '100%',
    caption => $lang{CRM_POPULAR_TARIFF_PLANS},
    title   => [ $lang{NAME}, $lang{COMPETITOR}, "$lang{LEADS} ($lang{COUNT})", $lang{MONTH_FEE}, $lang{DAY_FEE} ],
    ID      => 'CRM_POPULAR_TPS'
  });

  foreach my $tp (@{$tps}) {
    my $competitor_btn = $html->button($tp->{competitor_name}, "get_index=crm_competitors&header=1&full=1&chg=$tp->{competitor_id}");
    my $tp_btn = $html->button($tp->{name}, "get_index=crm_competitors_tp&header=1&full=1&chg=$tp->{id}");
    $popular_tps->addrow($tp_btn, $competitor_btn, $tp->{leads_number}, $tp->{month_fee}, $tp->{day_fee});
  }

  print $popular_tps->show();
}

#**********************************************************
=head2 _crm_get_competitor_users_button($attr)

=cut
#**********************************************************
sub _crm_get_competitor_users_button {
  my $index = shift;
  my $users = shift;
  my $competitor = shift;

  return 0 if !$index || !$users || !$competitor;

  my @params = qw/BUILD_ID STREET_ID DISTRICT_ID COMPETITOR_ID/;

  my $url = "index=$index&COMPETITOR_USERS=$competitor";
  map $FORM{$_} ? $url .= "&$_=$FORM{$_}" : (), @params;

  return $html->button($users, $url);
}

#**********************************************************
=head2 _crm_competitor_users_list($attr)

=cut
#**********************************************************
sub _crm_competitor_users_list {

  return 0 if !$FORM{COMPETITOR_USERS};

  my $leads = $Crm->crm_competitors_users_list({
    COMPETITOR_NAME => '_SHOW',
    COMPETITOR_ID   => $FORM{COMPETITOR_USERS},
    LEAD_ID         => '_SHOW',
    FIO             => '_SHOW',
    PHONE           => '_SHOW',
    ASSESSMENT      => '_SHOW',
    COLS_NAME       => 1,
    GROUP_BY        => 'cl.id',
    'sort'          => 1,
    %FORM
  });

  return '' if $Crm->{TOTAL} < 1;

  my $competitor_leads = $html->table({
    width      => '100%',
    caption    => "$leads->[0]{competitor_name}: $lang{LEADS}",
    title      => [ 'Id', $lang{FIO}, $lang{PHONE}, $lang{ASSESSMENT} ],
    ID         => 'CRM_COMPETITOR_USERS',
    DATA_TABLE => 1
  });

  foreach my $lead (@{$leads}) {
    my $lead_id = $html->button($lead->{lead_id},
      "get_index=crm_lead_info&header=2&full=1&LEAD_ID=$lead->{lead_id}");

    $competitor_leads->addrow($lead_id, $lead->{fio}, $lead->{phone}, crm_assessment_stars($lead->{assessment} || 0));
  }

  print $competitor_leads->show();
}

#**********************************************************
=head2 _crm_make_chart($attr)

=cut
#**********************************************************
sub _crm_make_tps_chart {
  my $tps = shift;

  my @data = ();
  my @labels = ();

  foreach my $tp (@{$tps}) {
    push @data, $tp->{month_fee};
    push @labels, $tp->{name};
  }

  return $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@labels,
    DATA              => {
      $lang{PRICE} => \@data
    },
    BACKGROUND_COLORS => {
      $lang{PRICE} => '#337ab7'
    },
    FILL              => 'true',
    OUTPUT2RETURN     => 1,
  });
}

#**********************************************************
=head2 _crm_make_chart($attr)

=cut
#**********************************************************
sub _crm_report_form {
  my ($attr) = @_;

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

  my $EXT_SELECT = {
    DISTRICT => { LABEL => $lang{DISTRICT}, SELECT => sel_districts({ SEL_OPTIONS => { 0 => '--' }, DISTRICT_ID => $FORM{DISTRICT_ID} }) },
    STREET   => { LABEL => $lang{STREET}, SELECT => sel_streets({ SEL_OPTIONS => { 0 => '--' }, STREET_ID => $FORM{STREET_ID} }) },
    _BUILD   => { LABEL => $lang{BUILD}, SELECT => $builds_sel }
  };

  $EXT_SELECT->{COMPETITOR} = {
    LABEL  => $lang{COMPETITOR},
    SELECT => _crm_competitors_select({ %FORM })
  } if !$attr->{HIDE_COMPETITOR_SELECT};

  reports({
    PERIOD_FORM => 1,
    NO_PERIOD   => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
    EXT_SELECT  => $EXT_SELECT
  });

  $html->tpl_show(_include('crm_report_address_script', 'Crm'));
}

1;