use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  %article_actions,
  $SELF_URL,
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
    DOMAIN_ID => ($admin->{DOMAIN_ID} || undef),
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
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
  });

  my $list = $Storage->storage_remnants_list({
    FROM_DATE => $FORM{FROM_DATE} || '_SHOW',
    TO_DATE   => $FORM{TO_DATE} || '_SHOW',
    COLS_NAME => 1
  });

  my $report_table = $html->table({
    title      => [ $lang{NAME}, $lang{MEASURE}, $lang{TOTAL}, $lang{ACCOUNTABILITY}, $lang{DISCARDED},
      $lang{INSTALLED}, $lang{RESERVED}, $lang{INNER_USE}, $lang{REST} ],
    width      => '100%',
    caption    => $lang{REMNANTS},
    qs         => $pages_qs,
    ID         => 'REMNANTS_REPORT',
    DATA_TABLE => 1,
    EXPORT     => 1
  });

  foreach my $item (@$list) {
    my $total_count = ($item->{discard_count} || 0) +  ($item->{installation_count} || 0) +
      ($item->{inner_use_count} || 0) + ($item->{count} || 0);
    $report_table->addrow(
      ($item->{name} || "$lang{NOT_EXIST}"),
      _translate($item->{measure_name}),
      ($total_count),
      ($item->{accountability_count} || 0),
      ($item->{discard_count} || 0),
      ($item->{installation_count} || 0),
      ($item->{reserve_count} || 0),
      ($item->{inner_use_count} || 0),
      ($item->{main_article_id} == 0 ?
        $item->{count} - ($item->{accountability_count} || 0) - ($item->{reserve_count} || 0):
        $item->{count}),
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

  my $admins_select  = sel_admins({NAME => 'INSTALLED_AID'});
  my $storage_select = storage_storage_sel($Storage, {ALL => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef)});
  my $type_select = $html->form_select('TYPE_ID', {
    SELECTED    => $FORM{TYPE_ID} || 0,
    SEL_LIST    => $Storage->storage_types_list({ DOMAIN_ID => ($admin->{DOMAIN_ID} || undef), COLS_NAME => 1 }),
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  reports({
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
    ADMINS_SELECT => 1,
    EXT_SELECT => {
      STORAGE   => { LABEL => $lang{STORAGE}, SELECT => $storage_select },
      REPSOBILE => { LABEL => $lang{RESPOSIBLE}, SELECT => $admins_select },
      TYPE      => { LABEL => $lang{TYPE}, SELECT => $type_select },
    }
  });

  my $installed_items = $Storage->storage_install_stats({
    DATE          => $FORM{FROM_DATE_TO_DATE},
    TYPE_ID       => $FORM{TYPE_ID}       || '_SHOW',
    INSTALLED_AID => $FORM{INSTALLED_AID} || '_SHOW',
    STORAGE_ID    => $FORM{STORAGE_ID}    || '_SHOW',
    DOMAIN_ID     => $admin->{DOMAIN_ID}  || undef,
    STA_NAME      => '_SHOW',
    SAT_NAME      => '_SHOW',
    COUNT         => '_SHOW',
    ARTICLE_ID    => '_SHOW',
    SELL_PRICE    => '_SHOW',
    SUM_PRICE     => '_SHOW',
    ADMIN_PERCENT => '_SHOW',
    GROUP_BY      => 'sta.id',
    SORT          => 'count',
    TYPE          => 1,
    COLS_NAME     => 1
  });

  my $table = $html->table({
    width      => '100%',
    caption    => "$lang{REPORT} $lang{ANALYSIS_ITEMS_SALE}",
    title      => [ $lang{NAME}, $lang{COUNT}, $lang{REVENUE}, $lang{ADMINS_PERCENT}, $lang{PROFIT}, "$lang{NET_PROFIT}" ],
    ID         => 'STORAGE_SELL_PRICE',
    DATA_TABLE => { "order" => [ [ 1, "desc" ] ] },
    EXPORT     => 1,
  });

  my @popular_count   = ();
  my @popular_price   = ();
  my @popular_labels = ();
  my @popular_count_colors = ();
  my @popular_price_colors = ();
  my @popular_bg_count_colors = ();
  my @popular_bg_price_colors = ();

  my $max_price = 0;
  my $max_count = 0;

  my $total_count = 0;
  my $total_sell_price = 0;
  my $total_admin_percent = 0;
  my $total_profit = 0;
  my $total_clear_profit;

  foreach my $item (@$installed_items) {
    push @popular_labels, (($item->{sat_name} || '') . " " . ($item->{sta_name} || ''));
    push @popular_count,   $item->{count};
    push @popular_price,   $item->{sell_price};
    push @popular_bg_count_colors, 'rgba(75, 192, 192, 0.7)';
    push @popular_bg_price_colors, 'rgba(153, 102, 255, 0.7)';
    push @popular_count_colors, 'rgb(75, 192, 192)';
    push @popular_price_colors, 'rgb(153, 102, 255)';

    my $sum_price = $item->{sum_price} || 0;   # incoming sum
    my $sell_price = $item->{sell_price} || 0; # actual sell price
    my $admin_percent = sprintf('%.2f', $item->{admin_percent} || 0); # sum for admin by his percent

    my $profit = sprintf('%.2f', ($sell_price - $sum_price));
    my $clear_profit = sprintf('%.2f', ($profit - $admin_percent));
    $table->addrow(
      (($item->{sat_name} || '') . " " . ($item->{sta_name} || '')),
      ($item->{count} || '---'),
      $sell_price,
      $admin_percent,
      $profit,
      $clear_profit
    );

    if($item->{sell_price} && $max_price < $item->{sell_price}){
      $max_price = $item->{sell_price};
    }

    if($item->{count} && $max_count < $item->{count}){
      $max_count = $item->{count};
    }

    $total_count         += $item->{count} || 0;
    $total_sell_price    += $sell_price;
    $total_admin_percent += $admin_percent;
    $total_profit        += $profit;
    $total_clear_profit  += $clear_profit;
  }


  $table->addfooter($html->b($lang{TOTAL_FOR_PERIOD}), $html->b($total_count), $html->b(format_sum($total_sell_price)), $html->b(format_sum($total_admin_percent)), $html->b(format_sum($total_profit)), $html->b(format_sum($total_clear_profit)));

  my $val_count = ($max_count!=0 && $max_count>50 )?($max_count/5): 10;
  my $val_price = ($max_price!=0 && $max_price>2000 )?($max_price/5): 300;

  my $popular_chart = $html->chart({
    TYPE       => 'bar',
    DATA_CHART => {
      labels => \@popular_labels,
      datasets => [
        {
          label           => "$lang{COUNT}",
          data            => \@popular_count,
          borderWidth     => 2,
          borderColor     => \@popular_count_colors,
          backgroundColor => \@popular_bg_count_colors,
          yAxisID         => 'left-y-axis',
          fill            => 'false',
        },
      {
        label           => "$lang{REVENUE}",
        data            => \@popular_price,
        borderWidth     => 2,
        borderColor     => \@popular_price_colors,
        backgroundColor => \@popular_bg_price_colors,
        fill            => 'false',
        yAxisID         => 'right-y-axis',
        type            => 'bar',
      }
      ]
    },
    OPTIONS    => {
      scales   => {
        yAxes => [ {
            id       => 'right-y-axis',
            type     => 'linear',
            position => 'right',
            ticks    => {
              stepSize => sprintf( "%.2f", $val_price ),
              min => 0
            }
          },
          {
            id       => 'left-y-axis',
            type     => 'linear',
            position => 'left',
            ticks    => {
              stepSize => sprintf( "%.f", $val_count ),
              min      => 0
            }
          }
        ]
      }
    }
  });

  $html->tpl_show(_include('storage_reports_installation', 'Storage'),
    {
      POPULAR_CHART    => $popular_chart,
      TABLE            => $table->show()
    },
  );
}

#**********************************************************
=head2 storage_incoming_report()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_incoming_report {

  reports({
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
    ADMINS_SELECT => 1,
  });

  my $goods_list = $Storage->storage_incoming_report_by_date({
    FROM_DATE   => $FORM{FROM_DATE} || $DATE,
    TO_DATE     => $FORM{TO_DATE}   || $DATE,
    COLS_NAME   => 1
  });

  if(scalar @{$goods_list} == 0){
    print $html->message('warn', "$lang{NO_ITEMS_FOR_CHOSEN_DATE}", "$lang{CHANGE} $lang{DATE}");
    return 1;
  }

  my $report_table = $html->table({
    width      => '100%',
    caption    => $lang{INCOMING_INVOICE_REPORT},
    title      => [ $lang{NAME}, $lang{COUNT}, $lang{STORAGE_INVOICE}, $lang{DATE},],
    ID         => 'STORAGE_INCOMING_REPORT',
    DATA_TABLE => { "order"=> [[1, "desc"]]},
    EXPORT => 1,
  });

  foreach my $item (@$goods_list){
    $report_table->addrow(
      ($item->{type_name}     || '') . ' ' . ($item->{article_name} || ''),
      ($item->{total_count}   || 0)  . ' ' . _translate(($item->{measure_name} || '')),
      $item->{invoice_number} || '',
      $item->{date} || '');
  }

  print $report_table->show();

}

#**********************************************************
=head2 storage_in_installments_statistics()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_in_installments_statistics {

  my $admins_select = sel_admins({ NAME => 'INSTALLED_AID' });
  my $storage_select = storage_storage_sel($Storage, { ALL => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) });
  my $type_select = $html->form_select('TYPE_ID', {
    SELECTED    => $FORM{TYPE_ID} || 0,
    SEL_LIST    => $Storage->storage_types_list({ DOMAIN_ID => ($admin->{DOMAIN_ID} || undef), COLS_NAME => 1 }),
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  reports({
    PERIOD_FORM   => 1,
    DATE_RANGE    => 1,
    NO_GROUP      => 1,
    NO_TAGS       => 1,
    ADMINS_SELECT => 1,
    EXT_SELECT    => {
      STORAGE   => { LABEL => $lang{STORAGE}, SELECT => $storage_select },
      REPSOBILE => { LABEL => $lang{RESPOSIBLE}, SELECT => $admins_select },
      TYPE      => { LABEL => $lang{TYPE}, SELECT => $type_select },
    }
  });

  if($FORM{FROM_DATE} && $FORM{FROM_DATE} gt $DATE){
    $FORM{FROM_DATE} = $DATE;
  }

  if($FORM{TO_DATE} && $FORM{TO_DATE} gt $DATE){
    $FORM{TO_DATE} = $DATE;
  }


  my $in_installments_items = $Storage->storage_in_installments_stats({
    DATE          => ($FORM{TO_DATE} ? "<=$FORM{TO_DATE}" : "<=$DATE"),
    TYPE_ID       => $FORM{TYPE_ID} || '_SHOW',
    INSTALLED_AID => $FORM{INSTALLED_AID} || '_SHOW',
    STORAGE_ID    => $FORM{STORAGE_ID} || '_SHOW',
    DOMAIN_ID     => $admin->{DOMAIN_ID} || undef,
    STA_NAME      => '_SHOW',
    SAT_NAME      => '_SHOW',
    COUNT         => '_SHOW',
    ARTICLE_ID    => '_SHOW',
    SELL_PRICE    => '_SHOW',
    SUM_PRICE     => '_SHOW',
    ADMIN_PERCENT => '_SHOW',
    TOTAL_MONTHS  => '_SHOW',
    SUM           => '_SHOW',
    AMOUNT_PER_MONTH      => '_SHOW',
    MONTHES               => '_SHOW',
    IN_INSTALLMENTS_PRICE => '_SHOW',
    PAYMENTS_COUNT        => '_SHOW',
    LAST_PAYMENT_DATE     => ($FORM{FROM_DATE} ? ">=$FORM{FROM_DATE}" : ">=$DATE"),
    TO_DATE               => $FORM{TO_DATE} || $DATE,
    FROM_DATE             => $FORM{FROM_DATE} || $DATE,
    SORT          => 'count',
    TYPE          => 3,
    COLS_NAME     => 1
  });

  my $table = $html->table({
    width      => '100%',
    caption    => "$lang{REPORT} $lang{ANALYSIS_ITEMS_IN_INSTALLMENTS} " . ($FORM{FROM_DATE} || $DATE) . " - " . ($FORM{TO_DATE} || $DATE),
    title      => [ $lang{NAME}, $lang{COUNT}, "$lang{COUNT} $lang{PAYMENTS}", "$lang{SUM} $lang{FOR_THE_MONTH}", $lang{REVENUE}, $lang{PROFIT}, $lang{ADMINS_PERCENT}, "$lang{NET_PROFIT}" ],
    ID         => 'STORAGE_SELL_PRICE',
    DATA_TABLE => { "order" => [ [ 1, "desc" ] ] },
    EXPORT     => 1,
  });

  foreach my $item (@$in_installments_items){
    my $profit = ($item->{in_installments_price} - $item->{sum_price}) / $item->{total_months} * $item->{payments_count};
    my $admin_sum = $item->{admin_percent} ? $profit / 100 * $item->{admin_percent} : 0;
    $table->addrow(
      "$item->{sat_name} $item->{sta_name}",
      "$item->{count}",
      $item->{payments_count},
      $item->{amount_per_month},
      $item->{amount_per_month} * $item->{payments_count},
      sprintf('%.2f', $profit),
      sprintf('%.2f', $admin_sum),
      sprintf('%.2f', $profit - $admin_sum),
    );
  }

  print $table->show();
}

#**********************************************************
=head2 storage_rent_statistics()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_rent_statistics {

  my $admins_select = sel_admins({ NAME => 'INSTALLED_AID' });
  my $storage_select = storage_storage_sel($Storage, { ALL => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) });
  my $type_select = $html->form_select('TYPE_ID', {
    SELECTED    => $FORM{TYPE_ID} || 0,
    SEL_LIST    => $Storage->storage_types_list({ DOMAIN_ID => ($admin->{DOMAIN_ID} || undef), COLS_NAME => 1 }),
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  reports({
    PERIOD_FORM   => 1,
    DATE_RANGE    => 1,
    NO_GROUP      => 1,
    NO_TAGS       => 1,
    ADMINS_SELECT => 1,
    EXT_SELECT    => {
      STORAGE   => { LABEL => $lang{STORAGE}, SELECT => $storage_select },
      REPSOBILE => { LABEL => $lang{RESPOSIBLE}, SELECT => $admins_select },
      TYPE      => { LABEL => $lang{TYPE}, SELECT => $type_select },
    }
  });

  if($FORM{FROM_DATE} && $FORM{FROM_DATE} gt $DATE){
    $FORM{FROM_DATE} = $DATE;
  }

  if($FORM{TO_DATE} && $FORM{TO_DATE} gt $DATE){
    $FORM{TO_DATE} = $DATE;
  }

  my $items = $Storage->storage_rent_stats({
    DATE             => ($FORM{TO_DATE} ? "<=$FORM{TO_DATE}" : "<=$DATE"),
    TYPE_ID          => $FORM{TYPE_ID} || '_SHOW',
    INSTALLED_AID    => $FORM{INSTALLED_AID} || '_SHOW',
    STORAGE_ID       => $FORM{STORAGE_ID} || '_SHOW',
    DOMAIN_ID        => $admin->{DOMAIN_ID} || undef,
    TO_DATE          => $FORM{TO_DATE} || $DATE,
    FROM_DATE        => $FORM{FROM_DATE} || $DATE,
    STA_NAME         => '_SHOW',
    SAT_NAME         => '_SHOW',
    COUNT            => '_SHOW',
    ARTICLE_ID       => '_SHOW',
    SELL_PRICE       => '_SHOW',
    SUM_PRICE        => '_SHOW',
    ADMIN_PERCENT    => '_SHOW',
    TOTAL_MONTHS     => '_SHOW',
    SUM              => '_SHOW',
    AMOUNT_PER_MONTH => '_SHOW',
    PAYMENTS_COUNT   => '_SHOW',
    SORT             => 'count',
    TYPE             => 2,
    COLS_NAME        => 1,
    PAGE_ROWS        => 99999
  });

  my $table = $html->table({
    width      => '100%',
    caption    => "$lang{REPORT} $lang{ANALYSIS_ITEMS_IN_RENT} " . ($FORM{FROM_DATE} || $DATE) . " - " . ($FORM{TO_DATE} || $DATE),
    title      => [ $lang{NAME}, $lang{COUNT}, "$lang{COUNT} $lang{PAYMENTS}", "$lang{SUM} $lang{FOR_THE_MONTH}", $lang{PROFIT}, $lang{ADMINS_PERCENT}, "$lang{NET_PROFIT}" ],
    ID         => 'STORAGE_SELL_PRICE',
    DATA_TABLE => { "order" => [ [ 1, "desc" ] ] },
    EXPORT     => 1,
  });

  foreach my $item (@$items){
    $item->{amount_per_month} ||= 0;
    $item->{sat_name} ||= '';
    $item->{sta_name} ||= '';

    my $profit = ($item->{amount_per_month} * $item->{payments_count});
    my $admin_sum = $profit / 100 * ($item->{admin_percent} || 0);
    $table->addrow(
      "$item->{sat_name} $item->{sta_name}",
      $item->{count},
      $item->{payments_count},
      $item->{amount_per_month},
      sprintf('%.2f', $profit),
      sprintf('%.2f', $admin_sum),
      sprintf('%.2f', $profit - $admin_sum),
    );
  }

  print $table->show();

}

#**********************************************************
=head2 storage_installation_report()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_installation_report {

  my $admins_select = sel_admins({ NAME => 'INSTALLED_AID' });
  my $storage_select = storage_storage_sel($Storage, { ALL => 1, DOMAIN_ID => ($admin->{DOMAIN_ID} || undef) });
  my $type_select = $html->form_select('TYPE_ID', {
    SELECTED    => $FORM{TYPE_ID} || 0,
    SEL_LIST    => $Storage->storage_types_list({ DOMAIN_ID => ($admin->{DOMAIN_ID} || undef), COLS_NAME => 1 }),
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });

  reports({
    PERIOD_FORM   => 1,
    DATE_RANGE    => 1,
    NO_GROUP      => 1,
    NO_TAGS       => 1,
    ADMINS_SELECT => 1,
    EXT_SELECT    => {
      STORAGE   => { LABEL => $lang{STORAGE}, SELECT => $storage_select },
      REPSOBILE => { LABEL => $lang{RESPOSIBLE}, SELECT => $admins_select },
      TYPE      => { LABEL => $lang{TYPE}, SELECT => $type_select },
    }
  });

  if($FORM{FROM_DATE} && $FORM{FROM_DATE} gt $DATE){
    $FORM{FROM_DATE} = $DATE;
  }

  if($FORM{TO_DATE} && $FORM{TO_DATE} gt $DATE){
    $FORM{TO_DATE} = $DATE;
  }

  my $installations = $Storage->storage_installation_list({
    COUNT        => '_SHOW',
    SUM          => '_SHOW',
    STA_NAME     => '_SHOW',
    DATE         => ($FORM{TO_DATE} ? "<=$FORM{TO_DATE}" : "<=$DATE"),
    SERIAL       => '_SHOW',
    ADMIN_NAME   => '_SHOW',
    STORAGE_NAME => '_SHOW',
    MEASURE_NAME => '_SHOW',
    TO_DATE      => $FORM{TO_DATE} || $DATE,
    FROM_DATE    => $FORM{FROM_DATE} || $DATE,
    AID          => $FORM{INSTALLED_AID} || '_SHOW',
    SAT_ID       => $FORM{TYPE_ID} || '_SHOW',
    STORAGE_ID   => $FORM{STORAGE_ID} || '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 99999
  });

  my $installed_table = $html->table({
    width      => '100%',
    caption    => $lang{INSTALLED_PERIOD} . " (" . ($FORM{FROM_DATE} || $DATE) . " - " . ($FORM{TO_DATE} || $DATE) . " )",
    title      => [ $lang{NAME}, $lang{COUNT}, $lang{PRICE},
      $lang{SERIAL}, $lang{RESPONSIBLE}, $lang{DATE}, $lang{STORAGE} ],
    ID         => 'STORAGE_INSTALLED_TABLE',
    DATA_TABLE => { "order" => [ [ 1, "desc" ] ] },
    EXPORT     => 1,
  });

  foreach my $install (@{$installations}) {
    $installed_table->addrow($install->{sta_name}, $install->{count} . ' ' . _translate($install->{measure_name}), $install->{sum},
      $install->{serial}, $install->{admin_name}, $install->{date}, $install->{storage_name});
  }

  print $installed_table->show();

  return 1;
}

1;