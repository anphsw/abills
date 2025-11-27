=head1 API

  Triplay COnfiguration

=cut


use strict;
use warnings FATAL => 'all';
use Tariffs;
use Triplay;

our (
  $db,
  %conf,
  $admin,
  %lang
);

require Control::Selects;
our Abills::HTML $html;
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Triplay = Triplay->new($db, $admin, \%conf);

#**********************************************************
=head2 triplay_tp($attr) - main module function

  Arguments:


  Returns:

=cut
#**********************************************************
sub triplay_tp {

  require Control::Services;

  $Triplay->{ACTION} = 'add';
  $Triplay->{ACTION_LNG} = $lang{ADD};
  $FORM{SMALL_DEPOSIT_ACTION} = -1;

  if ($FORM{add}) {
    if (! $FORM{NAME}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_NAME});
    }
    else {
      $Tariffs->add({ %FORM, MODULE => 'Triplay' });
      if (!$Tariffs->{errno}) {
        $Triplay->tp_add({ %FORM, TP_ID => $Tariffs->{TP_ID} });
      }

      if (!$Triplay->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{TARIF_PLAN} $lang{ADDED}");
      }
    }
  }
  elsif ($FORM{change}) {
    $Triplay->tp_change({ %FORM, ID => $FORM{chg} });

    if (!$Triplay->{errno}) {
      $html->message('info', $lang{SUCCESS}, "$lang{TARIF_PLAN} $lang{CHANGED}");
      $Tariffs->change($Triplay->{TP_ID}, { %FORM, TP_ID => $Triplay->{TP_ID} });
      $Triplay->tp_info({ TP_ID => $Tariffs->{TP_ID} });
    }

    $Triplay->{ACTION} = 'change';
    $Triplay->{ACTION_LNG} = $lang{CHANGE};
  }
  elsif ($FORM{TP_ID} || $FORM{chg}) {
    $Triplay->{ACTION} = 'change';
    $Triplay->{ACTION_LNG} = $lang{CHANGE};
    $Triplay->tp_info({ TP_ID => $FORM{TP_ID} || $FORM{chg} });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Triplay->tp_del({ %FORM, ID => $FORM{del} });

    if (!$Triplay->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Triplay);

  my $iptv_select = sel_tp({
    MODULE  => 'Iptv',
    IPTV_TP => $Triplay->{IPTV_TP},
    SELECT  => 'IPTV_TP',
    USER_INFO => $users,
    EX_PARAMS   => {
      MAIN_MENU => get_function_index('iptv_tp'),
      MAIN_MENU_ARGV => ($Triplay->{IPTV_TP}) ? "TP_ID=$Triplay->{IPTV_TP}" : ''
    }
  });
  my $internet_select = sel_tp({
    MODULE      => 'Internet',
    USER_INFO   => $users,
    INTERNET_TP => $Triplay->{INTERNET_TP},
    SELECT      => 'INTERNET_TP',
    EX_PARAMS   => {
      MAIN_MENU => get_function_index('internet_tp'),
      MAIN_MENU_ARGV => ($Triplay->{INTERNET_TP}) ? "TP_ID=$Triplay->{INTERNET_TP}" : ''
    }
  });
  my $voip_select = sel_tp({
    MODULE    => 'Voip',
    USER_INFO => $users,
    VOIP_TP   => $Triplay->{VOIP_TP},
    SELECT    => 'VOIP_TP',
    EX_PARAMS   => {
      MAIN_MENU => get_function_index('voip_tp'),
      MAIN_MENU_ARGV => ($Triplay->{VOIP_TP}) ? "TP_ID=$Triplay->{VOIP_TP}" : ''
    }
  });

  require Abon;
  Abon->import();
  my $Abon = Abon->new($db, $admin, \%conf);
  my $abon_select = $html->form_select('ABON_TP', {
    SELECTED       => $Triplay->{ABON_TP} || 0,
    SEL_LIST       => $Abon->tariff_list({ TP_NAME=>'_SHOW', COLS_NAME => 1, PAGE_ROWS => 60000 }),
    SEL_VALUE      => 'tp_name',
    NO_ID          => 1,
    SEL_OPTIONS    => { '' => '--' },
    MAIN_MENU      => get_function_index('abon_tariffs'),
    MAIN_MENU_ARGV => ($Triplay->{ABON_TP}) ? "TP_ID=$Triplay->{ABON_TP}" : ''
  });

  $Triplay->{SEL_METHOD} = sel_fees_methods('FEES_METHOD', (defined $Triplay->{FEES_METHOD}) ? $Triplay->{FEES_METHOD} : 1, {
    MAIN_MENU      => get_function_index('form_fees_types'),
    CHECKBOX       => 'create_fees_type',
    CHECKBOX_TITLE => $lang{CREATE}
  });

  my %payment_types = (
    0 => $lang{PREPAID},
    1 => $lang{POSTPAID},
    2 => $lang{GUEST}
  );

  $Triplay->{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
    SELECTED => $Triplay->{PAYMENT_TYPE} || 0,
    SEL_HASH => \%payment_types,
    NO_ID    => 1
  });

  $Triplay->{NEXT_TARIF_PLAN_SEL} = sel_tp({
    SELECT          => 'NEXT_TARIF_PLAN',
    NEXT_TARIF_PLAN => $FORM{NEXT_TARIF_PLAN} || $Triplay->{NEXT_TP_ID},
    MAIN_MENU       => 'triplay_tp',
    MODULE          => 'Triplay'
  });

  my %tp_groups = ();
  my $tp_groups_list = $Tariffs->tp_group_list({ COLS_NAME => 1 });
  foreach my $line (@$tp_groups_list) {
    $tp_groups{$line->{id}}=$line->{name};
  }

  $Triplay->{GROUPS_SEL} = $html->form_select('TP_GID', {
    SELECTED       => $FORM{TP_GID} || $Triplay->{GID},
    SEL_LIST       => $tp_groups_list,
    MAIN_MENU      => get_function_index('form_tp_groups'),
    MAIN_MENU_ARGV => "chg=" . ($Triplay->{GID} || q{}),
    SEL_OPTIONS    => { '' => '' },
  });

  $FORM{REDUCTION_FEE}         = ($FORM{REDUCTION_FEE}) ? 'checked' : '';
  $FORM{STATUS}                = ($FORM{STATUS}) ? 'checked' : '';
  $FORM{PERIOD_ALIGNMENT}      = ($FORM{PERIOD_ALIGNMENT}) ? 'checked' : '';
  $Triplay->{AGE_ALIGNMENT}    = ($Triplay->{AGE_ALIGNMENT}) ? 'checked' : '';
  $Triplay->{REDUCTION_FEE}    = ($Triplay->{REDUCTION_FEE})      ? 'checked' : '';
  $Triplay->{STATUS}           = ($Triplay->{STATUS} || $FORM{STATUS}) ? 'checked' : '';
  $Triplay->{PERIOD_ALIGNMENT} = ($Triplay->{PERIOD_ALIGNMENT} || $FORM{PERIOD_ALIGNMENT}) ? 'checked' : '';

  $html->tpl_show(_include('triplay_tp', 'Triplay'), {
    %FORM,
    %$Triplay,
    INTERNET => $internet_select,
    IPTV     => $iptv_select,
    VOIP     => $voip_select,
    ABON     => $abon_select,
    ID       => $Triplay->{TRIPLAY_TP_ID}
  });

  triplay_tp_list();

  return 1;
}

#**********************************************************
=head2 triplay_tp($attr) - main module function

  Arguments:


  Returns:

=cut
#**********************************************************
sub triplay_tp_list {

  my %tp_groups = ();
  my $tp_groups_list = $Tariffs->tp_group_list({ COLS_NAME => 1 });
  foreach my $line (@$tp_groups_list) {
    $tp_groups{$line->{id}}=$line->{name};
  }

  $LIST_PARAMS{TP_ID} = $FORM{TP_IDS} if ($FORM{TP_IDS});

  my %ext_cols = (
    id               => 'ID',
    inner_tp_id      => 'TP_ID',
    name             => 'NAME',
    internet_name    => 'INTERNET',
    iptv_name        => 'TV',
    voip_name        => 'VOIP',
    month_fee        => 'MONTH_FEE',
    day_fee          => 'DAY_FEE',
    comments         => 'COMMENTS',
    internet_name    => 'INTERNET',
    iptv_name        => 'TV',
    voip_name        => 'VOIP',
    abon_name        => 'ABON',
    age              => 'AGE',
    age_alignment    => "$lang{PERIOD_ALIGNMENT} $lang{AGE}",
    next_tp_id       => "$lang{NEXT_NEXT} $lang{TARIF_PLAN} ID",
    period_alignment => 'MONTH_ALIGNMENT',
    credit           => 'CREDIT',
    activate_price   => 'ACTIVATE',
    describe_aid     => 'DESCRIBE_FOR_ADMIN',
    tp_gid           => 'GROUP',
    status           => 'ARCHIVAL',
    fees_method_name => "$lang{FEES} $lang{TYPE}"
  );

  result_former({
    INPUT_DATA      => $Triplay,
    FUNCTION        => 'tp_list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'ID,NAME,MONTH_FEE,DAY_FEE,INTERNET_NAME,IPTV_NAME,VOIP_NAME,ABON_NAME,COMMENTS,ACTIV_PRICE',
    FUNCTION_FIELDS => ':change:tp_id,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => \%ext_cols,
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      qs      => $pages_qs,
      ID      => 'TRIPLAY_TP',
      EXPORT  => 1,
      SHOW_FULL_LIST  => 1,
      MENU    => "$lang{ADD}:index=" . get_function_index('triplay_tp') . ':add' . ";",
    },
    SELECT_VALUE  => {
      period_alignment => { 0 => $lang{NO}, 1 => $lang{YES} },
      age_alignment => { 0 => $lang{NO}, 1 => $lang{YES} },
      status => { 0 => $lang{NO}, 1 => $lang{YES} },
    },
    FILTER_VALUES => {
      tp_gid           => sub {
        my $tp_gid = shift;
        return $tp_groups{$tp_gid} || '';
      },
      fees_method_name => sub  {
        my $fees_method_name = shift;

        return _translate($fees_method_name);
      }
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Triplay',
    TOTAL           => 1
  });

  return 1;
}

1;