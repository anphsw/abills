=head1 NAME

  User Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base;
use Users;
use Internet;
our(
  $html,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  $db,
  $admin,
);
my $Users   = Users->new( $db, $admin, \%conf );
my $Internet = Internet->new($db, $admin, \%conf);

#**********************************************************
=head2 report_new_all_customers() - show chart for new and all customers

  Arguments:
    
  Returns:
    true
=cut
#**********************************************************
sub report_new_all_customers {
  my ($search_year, undef, undef) = split('-', $DATE);
  if ($FORM{NEXT} || $FORM{PRE}) {
    $search_year = $FORM{NEXT} || $FORM{PRE};
  }
  my $count_new_cust = $Users->info_user_reports({ LIST2HASH => 'reg_month,count',USER_NEW_COUNT => 1, YEAR => $search_year });
  my $all_count = '';
  my @data_hash = ();
  my @data_hash2 = ();
  my $i = 1;
  foreach (@MONTHES) {
    $i = sprintf("%02d", $i);
    $Users->list({ REGISTRATION => "<=$search_year-$i" });
    $all_count = $Users->{TOTAL};
    $count_new_cust->{$i} ? push @data_hash, $count_new_cust->{$i} : push @data_hash, 0;
    $count_new_cust->{$i} ? push @data_hash2, $all_count += $count_new_cust->{$i} : push @data_hash2, $all_count;
    $i++;
  }

  my $max1 = 0;
  my $max2 = 0;
  my $val1 = 0;
  my $val2 = 0;

  for (@data_hash) {
    $max1 = $_ if !$max1 || $_ > $max1
  };
  for (@data_hash2) {
    $max2 = $_ if !$max2 || $_ > $max2
  };

  $val1 = ($max1!=0 && $max1>200 )?($max1/5): 50;
  $val2 = ($max2!=0 && $max2>2000 )?($max2/5): 300;

  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@data_hash,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#5cc',
        fill            => 'false',
        backgroundColor => '#5cc',
      }, {
        data            => \@data_hash2,
        label           => $lang{ALL},
        yAxisID         => 'right-y-axis',
        borderColor     => '#a6f',
        fill            => 'false',
        backgroundColor => '#a6f',
      } ],
      labels   => \@MONTHES
    },
    OPTIONS    => {
      tooltips => {
        mode => 'index',
      },
      scales => {
        yAxes => [ {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => sprintf( "%.f", $val1 ),
            min      => 0
          }
        }, {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right',
          ticks    => {
            stepSize => sprintf( "%.f", $val2 ),
            min => 0
          }
        } ]
      }
    }
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1),
    { class => ' btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} });
  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1),
    { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} });
  print " <div class='col-lg-10' style='padding-left: 0'>
            <div class='box box-theme'>
              <div class='box-header with-border'>$pre_button $search_year $next_button<h4 class='box-title'>$lang{REPORT_NEW_ALL_USERS}</h4></div>
              <div class='box-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}
#**********************************************************
=head2 report_new_arpu() - show chart for new and all customers

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub report_new_arpu {
  my ($search_year, undef, undef) = split('-', $DATE);
  my ($y, $m, undef) = split('-', $DATE);
  if ($FORM{NEXT} || $FORM{PRE}) {
    $search_year = $FORM{NEXT} || $FORM{PRE};
  }
  my $count_new_cust = $Users->info_user_reports({ LIST2HASH => 'reg_month,count',USER_NEW_COUNT => 1, YEAR => $search_year });
  my $summ_for_month = '';
  my $all_count = '';
  my $users_count_act_serv = '';
  my $arpu_val = '';
  my $arpu_chart3 = 0;
  my $info_chart4 = 0;
  my @data_array = ();
  my @data_array2 = ();
  my @data_array3 = ();
  my @data_array4 = ();
  my @data_array5 = ();
  my $i = 1;

  my $min_tariff_amount = $Users->info_user_reports({ MIN_TARIFF_AMOUNT => 1, COLS_NAME => 1 });
  $Users->list({REGISTRATION => "<$y-$m", LOGIN_STATUS => 0, PAGE_ROWS => 9999999, COLS_NAME => 1});
  my $users_without_new = $Users->{TOTAL};

  foreach (@MONTHES) {
    $i = sprintf("%02d", $i);
    #    ARPU for all
    #    Payments sum per month
    $summ_for_month = $Users->info_user_reports({ PAY_SUM => 1, YEAR => $search_year, MONTH => $i, COLS_NAME => 1 });
    #    User count that registered to $i month
    $Users->list({ REGISTRATION => "<=$search_year-$i" });
    $all_count = $Users->{TOTAL} || 0;
    #    ARPU for all users
    $arpu_val = ($summ_for_month->{sum} || 0) / (($all_count + ($count_new_cust->{$i} || 0)) || 1);
    $arpu_val = sprintf("%0.3f", $arpu_val);
    push @data_array2, $arpu_val;

    #    AVR fees per month
    #    Make array for new users
    $count_new_cust->{$i} ? push @data_array, $count_new_cust->{$i} : push @data_array, 0;

    #     Users count for activated services
    $Internet->list({ INTERNET_REGISTRATION => "<" . $search_year . "-" . sprintf("%02d", $i + 1) . "-01" });
    $users_count_act_serv = $Internet->{TOTAL};

    #   Fees sum per month for users with activated services
    my $fees_sum = $Users->info_user_reports({ FEES_PER_MONTH => 1, YEAR => $search_year, MONTH => $i, COLS_NAME => 1 });
    $arpu_chart3 = ($fees_sum->{sum} || 0) / ($users_count_act_serv || 1);
    push @data_array3, sprintf("%0.3f", $arpu_chart3);

    #   The average amount of active services
    my $services_info = $Users->info_user_reports({ SUM_AND_TOTAL_SERVICES => 1, YEAR => $search_year, MONTH => $i, COLS_NAME => 1 });
    $info_chart4 = ($services_info->{month_fee_sum} || 0) / ($services_info->{total_active_services} || 1);
    if ($i ge $m && $search_year eq $y) {
      push @data_array4, sprintf("%0.3f", 0);
    }
    else {
      push @data_array4, sprintf("%0.3f", $info_chart4);
    }

    #   Predicted ARPU
    my $result = ((($services_info->{month_fee_sum} || 0) + (($count_new_cust->{$i} || 0) * ($min_tariff_amount->{min_t} || 0))) / ((($users_without_new || 0) + ($count_new_cust->{$i} || 0)) || 1) );
    if ($i eq ($m) && $search_year eq $y) {
      push @data_array5, sprintf("%0.3f", $result);
    }
    else {
      push @data_array5, sprintf("%0.3f", 0);
    }
    $i++;
  }
  unshift(@data_array5, 0.000);

  my $max1 = 0;
  my $max2 = 0;
  my $val1 = 0;
  my $val2 = 0;

  for (@data_array) {
    $max1 = $_ if !$max1 || $_ > $max1
  };
  for (@data_array2) {
    $max2 = $_ if !$max2 || $_ > $max2
  };
  $val1 = ($max1!=0 && $max1>300 )?($max1/5): 50;
  $val2 = ($max2!=0 && $max2>2000 )?($max2/5): 300;


  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@data_array2,
        label           => 'ARPU',
        yAxisID         => 'right-y-axis',
        borderColor     => '#3af',
        fill            => 'false',
        backgroundColor => '#3af',
      }, {
        data            => \@data_array,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#f68',
        fill            => 'false',
        backgroundColor => '#f68',
      }, {
        data            =>  \@data_array3,
        label           => $lang{AVR_FEES_AUTHORIZED},
        yAxisID         => 'left-y-axis',
        borderColor     => '#0f8',
        fill            => 'false',
        backgroundColor => '#0f8',
      }, {
        data            =>  \@data_array4,
        label           => $lang{AVR_AMOUNT_ACTIVE_SERV},
        yAxisID         => 'left-y-axis',
        borderColor     => '#fa1',
        fill            => 'false',
        backgroundColor => '#fa1',
      }, {
        data            =>  \@data_array5,
        label           => $lang{ARPU_FUTURE},
        yAxisID         => 'left-y-axis',
        borderColor     => '#00d',
        fill            => 'false',
        backgroundColor => '#00d',
      }
      ],
      labels   => \@MONTHES
    },
    OPTIONS    => {
      tooltips => {
        mode => 'index',
      },
      scales   => {
        yAxes => [ {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right',
          ticks    => {
            stepSize => sprintf( "%.2f", $val2 ),
            min => 0
          }
        },
        {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => sprintf( "%.f", $val1 ),
            min      => 0
          }
        }
        ]
      }
    }
  });

  my $pre_button = $html->button(" ", "index=$index&PRE=" . ($search_year - 1),
    { class => ' btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} });
  my $next_button = $html->button(" ", "index=$index&NEXT=" . ($search_year + 1),
    { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} });
  print " <div class='col-lg-10' style='padding-left: 0'>
            <div class='box box-theme'>
              <div class='box-header with-border'>$pre_button $search_year $next_button<h4 class='box-title'>$lang{REPORT_NEW_ARPU_USERS}</h4></div>
              <div class='box-body'>
                $chart3
              </div>
          </div>\n";
  return 1;
}
#**********************************************************
=head2 report_balance_by_status() - Shows table with statuses,users count and sum deposits

  Arguments:

  Returns:

=cut
#**********************************************************
sub report_balance_by_status {
  use Service;
  my $Service = Service->new( $db, $admin, \%conf );
  my $status_list = $Service->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    COLS_NAME => 1,
    SORT      => 'id',
    DESC      => 'ASC'
  });
  my $table = $html->table({
    width       => '100%',
    caption     => $lang{REPORT_BALANCE_BY_STATUS},
    title_plain => [
      $lang{STATUS},
      "$lang{COUNT} $lang{USERS}",
      $lang{BALANCE},
    ],
    qs          => $pages_qs,
    ID          => 'BALANCE_BY_STATUS'
  });
  my $list_index = get_function_index('internet_users_list');
  foreach my $item (@$status_list) {
    my $report_data = $Internet->report_user_statuses({STATUS =>$item->{id}, COLS_NAME => 1});
    $table->addrow(
      $html->color_mark(_translate($item->{name}), $item->{color}),
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status}))?
        $html->button($report_data->{COUNT},
        'index=' . $list_index . '&header=1&search_form=1&search=1&INTERNET_STATUS=' . $item->{id}): 0,
      (defined $report_data->{status} && ($item->{id} eq $report_data->{status}))? format_sum($report_data->{deposit}): 0,
    )
  }
  print $table->show();
  return 1;
}
1;