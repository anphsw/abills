=head2 NAME

  Voip User portal

=cut

use warnings;
use strict;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @WEEKDAYS,
  @MONTHES,
  @PERIODS,
  @status
);

our Abills::HTML $html;

my $Voip = Voip->new($db, $admin, \%conf);
my $Sessions = Voip_Sessions->new($db, $admin, \%conf);

#**********************************************************
=head2 voip_user_info();

=cut
#**********************************************************
sub voip_user_info {
  my $user = $Voip->user_info($user->{UID});

  if ($user->{TOTAL} < 1) {
    $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE});
    return 0;
  }

  $html->tpl_show(_include('voip_user_info', 'Voip'), $Voip);

  voip_user_phone_aliases($Voip);

  return 1;
}

#**********************************************************
=head2 voip_user_stats()

=cut
#**********************************************************
sub voip_user_stats {

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $uid = $FORM{UID} || 0;

  if ($FORM{SESSION_ID}) {
    $pages_qs .= "&SESSION_ID=$FORM{SESSION_ID}";
    voip_session_detail({ USER_INFO => $user });
    return 0;
  }

  if ($FORM{rows}) {
    $LIST_PARAMS{PAGE_ROWS} = $FORM{rows};
    $conf{list_max_recs} = $FORM{rows};
    $pages_qs .= "&rows=$conf{list_max_recs}";
  }

  #Periods totals
  my $list = $Sessions->periods_totals({ %LIST_PARAMS });
  my $table = $html->table({
    width       => '100%',
    caption     => $lang{PERIOD},
    title_plain => [ $lang{PERIOD}, $lang{DURATION}, $lang{SUM} ],
    ID          => 'PERIODS'
  });

  if (!defined($Sessions->{sum_4})) {
    $html->message('info', $lang{INFO}, $lang{NO_RECORD});
    return 1;
  }

  for (my $i = 0; $i < 5; $i++) {
    $table->addrow($html->button("$PERIODS[$i]", "index=$index&period=$i$pages_qs"), "$Sessions->{'duration_'. $i}",
      $Sessions->{ 'sum_' . $i });
  }
  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [
      [
        "$lang{FROM}: ", $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES }),
        "$lang{TO}: ", $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES }),
        "$lang{ROWS}: ",
        $html->form_input('rows', int($conf{list_max_recs}), { SIZE => 4, OUTPUT2RETURN => 1 }),
        $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 })
      ]
    ],
  });

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      sid   => $sid,
      index => $index,
      UID   => $uid
    }
  });

  voip_stats_calculation($Sessions);

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
  }
  elsif (defined($FORM{period})) {
    $LIST_PARAMS{PERIOD} = int($FORM{period});
    $pages_qs .= "&period=$FORM{period}";
  }

  #Session List
  $list = $Sessions->list({ %LIST_PARAMS, FROM_DATE => $FORM{FROM_DATE}, TO_DATE => $FORM{TO_DATE} });
  $table = $html->table({
    width       => '640',
    caption     => $lang{TOTAL},
    title_plain => [ $lang{SESSIONS}, $lang{DURATION}, $lang{SUM} ],
    rows        => [ [ $Sessions->{TOTAL}, $Sessions->{DURATION}, $Sessions->{SUM} ] ],
    ID          => 'VOIP_TOTALS'
  });

  print $table->show();

  voip_sessions($list) if ($Sessions->{TOTAL} > 0);

  return 1;
}

#**********************************************************
=head2 voip_user_routes()

=cut
#**********************************************************
sub voip_user_routes {

  my $user = $Voip->user_info($user->{UID});

  require Tariffs;
  Tariffs->import();
  my $Voip_tp = Tariffs->new($db, \%conf, $admin);
  $WEEKDAYS[0] = $lang{ALL};
  my $list = $Voip_tp->ti_list({ TP_ID => $user->{TP_ID} });
  my @caption = ($lang{PREFIX}, $lang{ROUTES}, "$lang{STATUS}");
  my @aligns = ('left', 'left', 'center');
  my @interval_ids = ();
  my $intervals = 0;

  foreach my $line (@{$list}) {
    push @caption,
      $html->b($WEEKDAYS[ $line->[1] ]) . $html->br() . sec2time($line->[2], { format => 1 }) . '-' . sec2time(
        $line->[3], { format => 1 });
    push @aligns, 'center';
    push @interval_ids, $line->[0];
  }
  $intervals = $Voip_tp->{TOTAL};

  $list = $Voip->rp_list({ %LIST_PARAMS, COLS_NAME => 1 });
  my %prices = ();
  foreach my $line (@{$list}) {
    $prices{$line->{interval_id}}{$line->{route_id}} = $line->{price};
  }

  $pages_qs .= "&routes=$FORM{routes}" if ($FORM{routes});
  $list = $Voip->routes_list({ %LIST_PARAMS });

  my $table = $html->table({
    width   => '100%',
    caption => $lang{ROUTES},
    title   => \@caption,
    qs      => $pages_qs,
    pages   => $Voip->{TOTAL},
    ID      => 'VOIP_ROUTES_PRICES',
  });

  my $price = 0;
  foreach my $line (@{$list}) {
    my @l = ();
    for (my $i = 0; $i < $intervals; $i++) {
      if (defined($prices{"$interval_ids[$i]"}{"$line->[4]"})) {
        $price = $prices{ $interval_ids[$i] }{ $line->[4] };
      }
      else {
        $price = "0.00";
      }
      push @l, $price;
    }
    $table->addrow("$line->[0]", "$line->[1]", $status[ $line->[2] ], @l);
  }

  print $table->show();

  return 1;
}

#*******************************************************************
=head2 voip_user_phone_aliases($attr) - Info about extra phone numbers

=cut
#*******************************************************************
sub voip_user_phone_aliases {

  my $alias_list = $Voip->phone_aliases_list({
    %LIST_PARAMS,
    NUMBER     => '_SHOW',
    DISABLE    => '_SHOW',
    CHANGED    => '_SHOW',
    COLS_NAME  => 1,
    UID        => $user->{UID},
  });

  my $table = $html->table({
    caption => $lang{EXTRA_NUMBERS} . ': ' . ($Voip->{TOTAL} || q{}),
    width   => '400',
    title   => [ $lang{PHONE}, $lang{STATUS}, $lang{CHANGED} ],
    qs      => $pages_qs,
    ID      => 'VOIP_PHONE_ALIASES'
  });

  foreach my $alias (@$alias_list) {
    $table->addrow($alias->{number}, $status[$alias->{disable}], $alias->{changed});
  }

  $table->show(),

  return  1;
}

1;
