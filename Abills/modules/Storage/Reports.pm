use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  %article_actions,
  $SELF_URL
);

use Storage;
use Abills::Base qw/_bp/;

my $Storage = Storage->new($db, $admin, \%conf);


#**********************************************************
=head2 storage_main_report($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub storage_main_report {
  my ($attr) = @_;

  my $FULL_AMOUNT = _count_full_amount();

  my %STORAGE_STATUS_LINKS = ();

  $STORAGE_STATUS_LINKS{SHOW_IN_STORAGE} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&storage_status=1";
  $STORAGE_STATUS_LINKS{SHOW_ACCOUNTABILITY} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&show_accountability=1";
  $STORAGE_STATUS_LINKS{SHOW_RESERVED} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&show_reserve=1";
  $STORAGE_STATUS_LINKS{SHOW_INSTALLED} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&show_installation=1";
  $STORAGE_STATUS_LINKS{SHOW_DISCARDED} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&storage_status=5";
  $STORAGE_STATUS_LINKS{SHOW_INNER_USE} = $SELF_URL . "?index=" . get_function_index('storage_main') . "&show_inner_use=1";

  my $chart_pie = $html->chart({
    TYPE              => 'pie',
    X_LABELS          =>
    [ $lang{IN_STORAGE}, $lang{INSTALLED}, $lang{INNER_USE}, $lang{DISCARDED}, $lang{RESERVED}, $lang{ACCOUNTABILITY} ],
    DATA              => {
      'STORAGE' =>
      [ $FULL_AMOUNT->{IN_STORAGE}, $FULL_AMOUNT->{INSTALATION}, $FULL_AMOUNT->{INNER_USE}, $FULL_AMOUNT->{DISCARDED},
        $FULL_AMOUNT->{RESERVE}, $FULL_AMOUNT->{ACCOUNTABILITY} ],
    },
    BACKGROUND_COLORS => {
      'STORAGE' => [ '#337ab7', '#dff0d8', '#ff851b', '#dd4b39', '#111', '#00c0ef' ],
    },
    TITLE => "$lang{STORAGE}",
    OUTPUT2RETURN     => 1,
  });

#  my $chart_bar = $html->chart({
#    TYPE        => 'bar',
#    X_LABELS    => [$lang{IN_STORAGE}, $lang{INSTALLED}, $lang{INNER_USE}, $lang{DISCARDED}, $lang{RESERVED}, $lang{ACCOUNTABILITY}],
#    DATA        => {
#      'STORAGE' => [$FULL_AMOUNT->{IN_STORAGE}, $FULL_AMOUNT->{INSTALATION}, $FULL_AMOUNT->{INNER_USE}, $FULL_AMOUNT->{DISCARDED},
#        $FULL_AMOUNT->{RESERVE}, $FULL_AMOUNT->{ACCOUNTABILITY}],
#    },
#    BACKGROUND_COLORS => {
#      'STORAGE' => ['#337ab7', '#dff0d8', '#ff851b', '#dd4b39', '#111', '#00c0ef'],
#    },
#    TITLE => "$lang{STORAGE}",
#    HIDE_LEGEND => 1,
#    OUTPUT2RETURN => 1,
#  });

  my $storage_history = $Storage->storage_log_list({
    DATE         => '_SHOW',
    ARTICLE_NAME => '_SHOW',
    COUNT        => '_SHOW',
    ACTION       => '_SHOW',
    COMMENTS     => '_SHOW',
    ADMIN_NAME   => '_SHOW',

    COLS_NAME    => 1,
    PAGE_ROWS    => 100,
    DESC         => 'desc',
  });

  my $history_table = $html->table({
    title      => [ $lang{DATE}, $lang{ACTION}, $lang{ADMIN}, $lang{NAME}, $lang{COMMENTS} ],
    width      => '100%',
    caption    => $lang{LOG},
    qs         => $pages_qs,
    ID         => 'STORAGE_LOG',
    DATA_TABLE => { 'order' => [ [ 0, 'desc' ] ] },
  });

  foreach my $log (@$storage_history) {
    $history_table->addrow(
      $log->{date} || '',
      $article_actions{$log->{action}} || '',
      $log->{admin_name} || '',
      $log->{article_name} || '',
      $log->{comments} || '',
    );
  }

  my $HISTORY = $history_table->show({ OUTPUT2RETURN => 1 });

  $html->tpl_show(
    _include('storage_main_report', 'Storage'),
    {
      %$FULL_AMOUNT,
      %STORAGE_STATUS_LINKS,
      CHARTS  => $chart_pie,
      HISTORY => $HISTORY
    }
  );

  return 1;
}

#**********************************************************
=head2 _count_full_amount()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _count_full_amount {
  my $incoming_articles_list = $Storage->storage_incoming_articles_list({
    COLS_NAME => 1,
  });

  my %FULL_AMOUNT = (
    IN_STORAGE     => 0,
    DISCARDED      => 0,
    INNER_USE      => 0,
    INSTALATION    => 0,
    ACCOUNTABILITY => 0,
    RESERVE        => 0,
  );
  foreach my $incoming_article (@$incoming_articles_list) {
    if(defined $incoming_article->{measure} && $incoming_article->{measure} =~ /\d+/ && $incoming_article->{measure} == 0) {
      $FULL_AMOUNT{IN_STORAGE} += $incoming_article->{total} || 0;
      $FULL_AMOUNT{DISCARDED} += $incoming_article->{discard_count} || 0;
      $FULL_AMOUNT{INNER_USE} += $incoming_article->{inner_use_count} || 0;
      $FULL_AMOUNT{INSTALATION} += $incoming_article->{instalation_count} || 0;
      $FULL_AMOUNT{ACCOUNTABILITY} += $incoming_article->{accountability_count} || 0;
      $FULL_AMOUNT{RESERVE} += $incoming_article->{reserve_count} || 0;
    }
  }

  return \%FULL_AMOUNT;
}

#**********************************************************
=head2 storage_start_page($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub storage_start_page {
  #my ($attr) = @_;

  my %START_PAGE_F = (
    'storage_main_report_charts' => "$lang{STORAGE}",
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 storage_main_report_charts()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_main_report_charts {
  my $FULL_AMOUNT = _count_full_amount();

  my $chart =  $html->chart({
    TYPE        => 'bar',
    X_LABELS    => [$lang{IN_STORAGE}, $lang{INSTALLED}, $lang{INNER_USE_SHORT}, $lang{DISCARDED}, $lang{RESERVED}, $lang{ACCOUNTABILITY}],
    DATA        => {
      'STORAGE' => [$FULL_AMOUNT->{IN_STORAGE}, $FULL_AMOUNT->{INSTALATION}, $FULL_AMOUNT->{INNER_USE}, $FULL_AMOUNT->{DISCARDED},
        $FULL_AMOUNT->{RESERVE}, $FULL_AMOUNT->{ACCOUNTABILITY}],
    },
    BACKGROUND_COLORS => {
      'STORAGE' => ['#337ab7', '#dff0d8', '#ff851b', '#dd4b39', '#111', '#00c0ef'],
    },
    TITLE => "$lang{STATS}",
    HIDE_LEGEND => 1,
    OUTPUT2RETURN => 1,
  });


  return $html->tpl_show(
    _include('storage_sp_report_chart', 'Storage'),
    {
      CHART  => $chart,
    },
    {OUTPUT2RETURN => 1,}
  );
}


#**********************************************************
=head2 storage_remnants_report()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_remnants_report {
   reports({
     PERIOD_FORM=>1,
     DATE_RANGE=>1,
     NO_GROUP => 1,
    NO_TAGS=>1,
   });

    my $list = $Storage->storage_remnants_list({
      FROM_DATE => $FORM{FROM_DATE} || $DATE,
      TO_DATE   => $FORM{TO_DATE} || $DATE,
      COLS_NAME => 1
    });

  my $report_table = $html->table({
    title      => [ $lang{NAME}, $lang{MEASURE}, $lang{TOTAL}, $lang{ACCOUNTABILITY}, $lang{DISCARDED}, $lang{INSTALLED}, $lang{RESERVED}, $lang{INNER_USE}, $lang{REST} ],
    width      => '100%',
    caption    => $lang{REMNANTS},
    qs         => $pages_qs,
    ID         => 'REMNANTS_REPORT',
    DATA_TABLE => 1,
  });

  foreach my $item (@$list){
    $report_table->addrow(
      ($item->{name} || "$lang{NOT_EXIST}"),
      _translate($item->{measure_name}),
      ($item->{total_count} || 0),
      ($item->{accountability_count} || 0),
      ($item->{discard_count} || 0),
      ($item->{installation_count} || 0),
      ($item->{reserve_count} || 0),
      ($item->{inner_use_count} || 0),
      ($item->{main_article_id} == 0 ? $item->{count}  - ($item->{accountability_count} || 0) : $item->{count} ),
    );
  }
    print $report_table->show();
    return 1;

}

#**********************************************************
=head2 storage_statistics()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_statistics {
  reports({
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
  });

  my $installed_items = $Storage->storage_install_stats({
    DATE        => $FORM{FROM_DATE_TO_DATE},
    STA_NAME    => '_SHOW',
    SAT_NAME    => '_SHOW',
    COUNT       => '_SHOW',
    ARTICLE_ID  => '_SHOW',
    TYPE_ID     => '_SHOW',
    SELL_PRICE  => '_SHOW',
    GROUP_BY    => 'sta.id',
    SORT        => 'sell_price',
    COLS_NAME   => 1
  });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{INFO},
      title      => [ $lang{NAME}, $lang{COUNT}, $lang{MONEY}],
      ID         => 'STORAGE_SELL_PRICE',
      DATA_TABLE => { "order"=> [[ 2, "desc" ], [1, "desc"]]},
    }
  );

  my @popular_count   = ();
  my @popular_price   = ();
  my @popular_labels = ();
  my @popular_colors = ();

  foreach my $item (@$installed_items) {
    push @popular_labels, (($item->{sat_name} || '') . " " . ($item->{sta_name} || ''));
    push @popular_count,   $item->{count};
    push @popular_price,   $item->{sell_price};
    push @popular_colors, 'rgba(120, 99, 132, 0.6)';
    $table->addrow((($item->{sat_name} || '') . " " . ($item->{sta_name} || '')), $item->{count}, $item->{sell_price});
  }


  my $popular_chart = $html->chart({
    TYPE       => 'bar',
    DATA_CHART => {
      labels => \@popular_labels,
      datasets => [
        {
          label           => "$lang{TOTAL}",
          data            => \@popular_price,
          borderWidth     => 2,
          borderColor     => \@popular_colors,
          backgroundColor => \@popular_colors,
        }]
    },
    OPTIONS    => {
      scales => {
        yAxes => [ {
          ticks => {
            beginAtZero => "true",
          }
        }
        ]
      }
    }
  });

  $html->tpl_show(_include('storage_reports_installation', 'Storage'),
    {
      POPULAR_CHART    => $popular_chart,
      TABLE => $table->show()
    },
  );
}

1;