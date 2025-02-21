=head2 NAME

  Mobile Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  %lang,
  %conf,
  $admin,
  $db,
  $html,
  @MONTHES,
  $Tv_service
);

use Mobile;
my $Mobile = Mobile->new($db, $admin, \%conf);

#**********************************************************
=head2 mobile_tp_report($attr)

=cut
#**********************************************************
sub mobile_tp_report {
  # require Control::Reports;

  # reports({
  #   PERIODS           => 1,
  #   NO_TAGS           => 1,
  #   NO_PERIOD         => 1,
  #   NO_MULTI_GROUP    => 1,
  #   PERIOD_FORM       => 1,
  #   NO_STANDART_TYPES => 1,
  #   col_md            => 'col-md-11'
  # });

  if ($FORM{DEBUG}) {
    $Mobile->{debug} = 1;
  }

  my $list = $Mobile->mobile_tp_report({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table({
    caption => $lang{TARIF_PLANS},
    width   => '100%',
    title   => [ '#', $lang{NUMBER}, 'ID', $lang{NAME}, $lang{TOTAL}, $lang{ACTIV}, $lang{DISABLE},
      $lang{DEBETORS}, "$lang{REDUCTION} 100%", "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}", $lang{MONTH_FEE}, $lang{DAY_FEE}, $lang{GROUP}, $lang{SERVICE}, ],
    ID      => 'REPORTS_MOBILE_TARIF_PLANS',
    EXPORT  => 1,
  });

  my $mobile_users_list_index = get_function_index('mobile_users_list') || 0;

  my ($total_users, $totals_active, $total_disabled, $total_debetors, $total_reduction) = (0,0,0,0,0);
  my $i = 1;

  foreach my $line (@$list) {
    $line->{id} = 0 if (! defined($line->{id}));
    $line->{tp_id} = 0 if (! defined($line->{tp_id}));

    my $main_link = "search=1&index=$mobile_users_list_index&TP_ID=$line->{tp_id}&search_form=1";

    $main_link .= "&GID=$FORM{GID}" if $FORM{GID};

    $table->addrow(
      $i,
      $line->{id},
      $line->{tp_id},
      $html->button($line->{name}, "$main_link"),
      ($line->{counts} > 0 )          ? $html->button($line->{counts}, "$main_link")                        : 0,
      ($line->{active} > 0 )          ? $html->button($line->{active}, "$main_link&TP_DISABLE=0")       : 0,
      ($line->{disabled} > 0 )        ? $html->button($line->{disabled}, "$main_link&TP_DISABLE=!0")    : 0,
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

#**********************************************************
=head2 mobile_log_list()

=cut
#**********************************************************
sub mobile_log_list {

  my ($table, undef) = result_former({
    INPUT_DATA      => $Mobile,
    FUNCTION        => 'log_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,UID,TRANSACTION_ID,DATE,RESPONSE,CALLBACK,CALLBACK_DATE,EXTERNAL_METHOD',
    EXT_TITLES => {
      ID              => '#',
      UID             => 'UID',
      TRANSACTION_ID  => $lang{MOBILE_TRANSACTION_ID},
      RESPONSE        => $lang{MOBILE_RESPONSE},
      DATE            => $lang{DATE},
      CALLBACK        => $lang{MOBILE_CALLBACK},
      CALLBACK_DATE   => $lang{MOBILE_CALLBACK_DATE},
      EXTERNAL_METHOD => $lang{MOBILE_METHOD}
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{MOBILE_LOGS},
      qs      => $pages_qs,
      ID      => 'MOBILE_LOG',
      pages   => $Mobile->{TOTAL},
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search;",
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Mobile'
  });

  return print $table->show();
}

1;