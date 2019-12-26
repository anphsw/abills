=head1 NAME

  User Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base;
use Users;
use Internet;
use List::Util qw/max min/;
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

  my $all_data = $Users->all_new_report({ COLS_NAME => 1, YEAR => $search_year });
  my @data_array = ();
  my @data_array2 = ();

  foreach my $line (@$all_data) {
    push @data_array, $line->{count_new_users};
    push @data_array2, $line->{count_all_users};
  }

  my $val1 = max @data_array;
  my $val2 = max @data_array2;
  $val1 = $val1 > 300 ? 150 : 50;
  $val2 = $val2 > 1500 ? 750 : 150;

  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [ {
        data            => \@data_array,
        label           => $lang{NEW_CUST},
        yAxisID         => 'left-y-axis',
        borderColor     => '#5cc',
        fill            => 'false',
        backgroundColor => '#5cc',
      }, {
        data            => \@data_array2,
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
      scales   => {
        yAxes => [ {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => sprintf("%.f", $val1),
            min      => 0
          }
        }, {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right',
          ticks    => {
            stepSize => sprintf("%.f", $val2),
            min      => 0
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

  my $min_tariff_amount = $Users->min_tarif_val({ COLS_NAME => 1 });
  my $data_for_report = $Users->all_data_for_report({
    YEAR      => $search_year,
    COLS_NAME => 1
  });

  my $arpu_val = '';
  my $arpu_chart3 = 0;
  my $info_chart4 = 0;
  my @data_array = ();
  my @data_array2 = ();
  my @data_array3 = ();
  my @data_array4 = ();
  my @data_array5 = ();

  foreach my $data_per_month (@$data_for_report) {
    #    Make array for new users
    push @data_array, $data_per_month->{count_new_users};
    #    ARPU for all
    $arpu_val = ($data_per_month->{payments_for_every_month}) / ($data_per_month->{count_all_users} != '0' ? $data_per_month->{count_all_users} : 1);
    $arpu_val = sprintf("%0.3f", $arpu_val);
    push @data_array2, $arpu_val;
    #    AVR fees per month
    $arpu_chart3 = ($data_per_month->{fees_sum}) / ($data_per_month->{count_activated_users} || 1);
    push @data_array3, sprintf("%0.3f", $arpu_chart3);
    #   The average amount of active services
    $info_chart4 = ($data_per_month->{month_fee_sum} || 0) / ($data_per_month->{total_active_services} || 1);
    if ($data_per_month->{month} gt $m && $search_year eq $y) {
      push @data_array4, sprintf("%0.3f", 0);
    }
    else {
      push @data_array4, sprintf("%0.3f", $info_chart4);
    }

    #   Predicted ARPU
    my $result = ((($data_per_month->{month_fee_sum}) + (($data_per_month->{count_new_users}) * ($min_tariff_amount->{min_t} || 0))) / ($data_per_month->{count_all_users} || 1));
    if ($data_per_month->{month} eq ($m) && $search_year eq $y) {
      push @data_array5, sprintf("%0.3f", $result);
    }
    else {
      push @data_array5, sprintf("%0.3f", 0);
    }
  }

  unshift(@data_array5, 0.000);
  pop(@data_array5);

  my @array_all_data = (@data_array2, @data_array3, @data_array4, @data_array5);
  my $val1 = 0;
  my $val2 = 0;

  $val1 = max @data_array;
  $val2 = max @array_all_data;
  $val1 = $val1 > 300 ? 150 : 50;
  $val2 = $val2 > 1500 ? 750 : 150;

  my $chart3 = $html->chart({
    TYPE       => 'line',
    DATA_CHART => {
      datasets => [
        {
          data            => \@data_array2,
          label           => 'ARPU',
          yAxisID         => 'left-y-axis',
          borderColor     => '#3af',
          fill            => 'false',
          backgroundColor => '#3af',
        },
        {
          data            => \@data_array,
          label           => $lang{NEW_CUST},
          yAxisID         => 'right-y-axis',
          borderColor     => '#f68',
          fill            => 'false',
          backgroundColor => '#f68',
        },
        {
          data            => \@data_array3,
          label           => $lang{AVR_FEES_AUTHORIZED},
          yAxisID         => 'left-y-axis',
          borderColor     => '#0f8',
          fill            => 'false',
          backgroundColor => '#0f8',
        },
        {
          data            => \@data_array4,
          label           => $lang{AVR_AMOUNT_ACTIVE_SERV},
          yAxisID         => 'left-y-axis',
          borderColor     => '#fa1',
          fill            => 'false',
          backgroundColor => '#fa1',
        },
        {
          data            => \@data_array5,
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
            stepSize => sprintf("%.2f", $val1),
            min      => 0
          }
        },
          {
            id       => 'left-y-axis',
            type     => 'linear',
            position => 'left',
            ticks    => {
              stepSize => sprintf("%.f", $val2),
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