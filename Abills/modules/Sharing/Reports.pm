=head1 NAME

  Sharing Reports

=cut

use strict;
use warnings FATAL => 'all';
use Sharing;

our (
  $db,
  $admin,
  %lang,
  %conf,
  @PERIODS,
  @MONTHES,
  %LIST_PARAMS
);

our Abills::HTML $html;
my $Sharing = Sharing->new($db, $admin, \%conf);

#**********************************************************
=head2 sharing_start_page()

=cut
#**********************************************************
sub sharing_start_page {

  my %START_PAGE_F = (
    sharing_info_widget => "$lang{REPORT} $lang{ACCESS_FILES}",
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 callcenter_start_page($attr)

=cut
#**********************************************************
sub sharing_info_widget {
  
  my $index = get_function_index('sharing_user_service');

  my $list = $Sharing->sharing_user_list({
    LOGIN           => '_SHOW',
    DATE            => "<$DATE",
    FILE_NAME       => '_SHOW',
    SHOW_IN_REPORT  => 1,
    PAGE_ROWS       => 20,
    COLS_NAME       => 1
  });

  my $table = $html->table({
    width       => '100%',
    title_plain => [ $lang{LOGIN}, $lang{FILE}, $lang{DATE_TO}],
    caption     => "$lang{REPORT} $lang{ACCESS_FILES}",
    ID          => 'SHARING_INFO_FILES',
  });

  if ($Sharing->{TOTAL}){
    foreach my $line (@$list) {
      $table->addrow(
        $html->button($line->{login}, "index=$index&UID=$line->{uid}"),
        $line->{name},
        $line->{date_to}
      );
    }
  }

  return $table->show();
}

#**********************************************************
=head2 sharing_log_table () -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub sharing_download_log {
  my ($attr) = @_;

  # my $download_list = $Sharing->sharing_log_list({
  #     FILE_ID   => '_SHOW',
  #     DATE      => '_SHOW',
  #     UID       => '_SHOW',
  #     IP        => '_SHOW',
  #     COLS_NAME => 1
  # });

  require Control::Reports;
  reports({
    PERIOD_FORM => 1,
    DATE_RANGE  => 1,
    NO_GROUP    => 1,
    NO_TAGS     => 1,
  });

  $LIST_PARAMS{DATE_START} = $FORM{FROM_DATE} ? $FORM{FROM_DATE} : $DATE;
  $LIST_PARAMS{DATE_END} = $FORM{TO_DATE} ? $FORM{TO_DATE} : $DATE;
  $pages_qs = $pages_qs . "&TO_DATE=$LIST_PARAMS{DATE_END}&FROM_DATE=$LIST_PARAMS{DATE_END}";

  result_former(
    {
      INPUT_DATA      => $Sharing,
      FUNCTION        => 'sharing_log_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'DATE, IP, FILE_NAME, LOGIN',
      #FUNCTION_FIELDS => 'del',
      EXT_TITLES      => {
        # id       => '#',
        login     => $lang{USER},
        date      => $lang{DATE},
        file_name => $lang{FILE},
        ip        => "IP",
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{LOG} $lang{DOWNLOADS}",
        qs      => $pages_qs,
        pages   => $Sharing->{TOTAL},
        ID      => 'SHARING_DOWNLOAD_LOG',
        #MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      TOTAL           => 1,
      SKIP_USER_TITLE => 1
    }
  );

  my ($ys, $ms, $ds) = split(/-/, $LIST_PARAMS{DATE_START});
  my ($ye, $me, $de) = split(/-/, $LIST_PARAMS{DATE_END});
  my $date_param = '';
  my @array = ();
  my $chart_name = '';

  if (($ys == $ye) && ($ms == $me) && ($ds == $de)) {
    $date_param = "'%H'";
    @array = (0 ... 23);
  }
  elsif (($ys == $ye) && ($ms == $me) && ($ds != $de)) {
    $date_param = "'%d'";
    @array = (1 ... Abills::Base::days_in_month({ DATE => $ms }));
    $chart_name = "$lang{GRAPH_DOWNLOAD_DYNAMICS} $PERIODS[3] $MONTHES[$ms - 1]";
  }
  elsif (($ys == $ye) && ($ms != $me)) {
    $date_param = "'%m'";
    @array = (1 ... 12);
    $chart_name = "$lang{GRAPH_DOWNLOAD_DYNAMICS} $lang{PER_MONTH} $ys";
  }
  elsif (($ys != $ye)) {
    $date_param = "'%Y'";
    @array = ($ys ... $ye);
    $chart_name = "$lang{GRAPH_DOWNLOAD_DYNAMICS} $lang{PER_YEAR} $ys - $ye";
  }
  my %result = ();
  my @array_y = ();
  my @array_x = ();

  my $data = $Sharing->sharing_download_dynamic({
    DATE      => "$LIST_PARAMS{DATE_START}/$LIST_PARAMS{DATE_END}",
    PARAM     => $date_param,
    LIST2HASH => 'my_data,count',
  });

  foreach my $item (keys %$data) {
    $data->{int $item} = delete $data->{$item}
  }

  foreach my $item (@array) {
    push @array_x, $item;
    if ($data->{$item}) {
      push @array_y, $data->{$item};
    }
    else {
      push @array_y, 0;
    }
  }

  if (($ys == $ye) && ($ms != $me)) {
    $result{ARRAY_X} = \@main::MONTHES;
  }
  else {
    $result{ARRAY_X} = \@array_x;
  }

  $result{ARRAY_Y} = \@array_y;

  my $chart = $html->chart({
    TYPE       => 'bar',
    DATA_CHART => {
      datasets => [ {
        data            => \@array_y,
        label           => $lang{DOWNLOADS},
        borderColor     => '#e54',
        fill            => 'false',
        backgroundColor => '#e54',
        lineTension     => 0
      }
      ],
      labels   => $result{ARRAY_X}
    },
    OPTIONS    => {
      bezierCurve => 'false',
      scales      => {
        yAxes => [ {
          type  => 'linear',
          ticks => {
            min         => 0,
            beginAtZero => 'true'
          }
        } ]
      }
    }
  });

  $html->tpl_show(_include('sharing_download_filters', 'Sharing'),
    {
      CHART => $chart,
      NAME  => $chart_name,
    },);

  return 1;
}

#**********************************************************
=head2 sharing_report()


=cut
#**********************************************************
sub sharing_report {
  my $bought_files_count = $Sharing->sharing_get_bought_files_count();
  my $downloaded_files_count = $Sharing->sharing_get_downloaded_files_count();
  my $subscriptions_count = $Sharing->sharing_get_subscriptions({ DATE => $DATE });

  if (defined($FORM{SH_FILE})) {
    $LIST_PARAMS{SH_FILE} = $FORM{SH_FILE};

    my ($user_table, undef) = result_former({
      INPUT_DATA      => $Sharing,
      FUNCTION        => 'sharing_user_list',
      BASE_FIELDS     => 1,
      DEFAULT_FIELDS  => 'ID,LOGIN,DATE,DEMO',
      FUNCTION_FIELDS => 'del',
      EXT_TITLES      => {
        uid     => "UID",
        date_to => $lang{DATE},
        login   => $lang{USER},
        demo    => $lang{DEMO}
      },
      SKIP_USER_TITLE => 1,
      TABLE           => {
        width   => '100%',
        caption => "$lang{MODULE} - $lang{USERS}",
        qs      => $pages_qs,
        ID      => 'SHARING_USER_LIST',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      MODULE          => 'Sharing'
    });

    my $user_table_end = $html->table({
      width => '100%',
      rows  => [
        [ "$lang{TOTAL}:", $html->b($Sharing->{TOTAL}), "$lang{SUM}: ", $html->b($Sharing->{TOTAL_SUM} * $Sharing->{TOTAL}) ]
      ]
    });

    print $user_table->show() . $user_table_end->show();
  }

  my %table_info = ();

  my @popular_data = ();
  my @popular_labels = ();
  my @popular_colors = ();

  foreach my $file (@$bought_files_count) {
    my $filename = $file->{name} || q{};
    push @popular_labels, $filename;
    push @popular_data, $file->{count} || 0;
    push @popular_colors, 'rgba(120, 99, 132, 0.6)';
    $table_info{$filename}{bought_info} = $file->{count} || q{};
    $table_info{$filename}{file_id} = $file->{file_id};
  }

  my $popular_chart = $html->chart({
    TYPE       => 'bar',
    DATA_CHART => {
      labels   => \@popular_labels,
      datasets => [ {
        label           => $lang{PURCHASES},
        data            => \@popular_data,
        borderWidth     => 2,
        borderColor     => \@popular_colors,
        backgroundColor => \@popular_colors,
      } ]
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

  my @download_data = ();
  my @download_labels = ();
  my @download_colors = ();

  foreach my $file (@$downloaded_files_count) {
    push @download_labels, $file->{name};
    push @download_data, $file->{count};
    push @download_colors, 'rgba(99, 120, 50, 0.6)';

    $table_info{($file->{name} || $file->{file_id})}{download_info} = $file->{count};
  }

  my $download_chart = $html->chart({
    TYPE       => 'bar',
    DATA_CHART => {
      labels   => \@download_labels,
      datasets => [ {
        label           => $lang{DOWNLOADS},
        data            => \@download_data,
        borderWidth     => 2,
        borderColor     => \@download_colors,
        backgroundColor => \@download_colors,
      } ]
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

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{INFO},
    title      => [ $lang{NAME}, $lang{PURCHASES}, $lang{DOWNLOADS} ],
    ID         => 'SHARING_INFO',
    DATA_TABLE => { "order" => [ [ 1, "desc" ], [ 2, "desc" ] ] },
  });

  $index = get_function_index('sharing_report');

  foreach my $file (keys %table_info) {
    $table->addrow(
      $html->element('a', $file, { href => "index.cgi?index=$index&SH_FILE=" . ($table_info{$file}->{file_id} || q{}) }),
      ($table_info{$file} && $table_info{$file}{bought_info} ? $table_info{$file}{bought_info} : 0),
      ($table_info{$file} && $table_info{$file}{download_info} ? $table_info{$file}{download_info} : 0)
    );
  }

  $html->tpl_show(_include('sharing_reports', 'Sharing'),
    {
      POPULAR_CHART    => $popular_chart,
      DOWNLOAD_CHART   => $download_chart,
      ACTIVE_COUNT     => $subscriptions_count->[0]{active_subscriptions},
      NOT_ACTIVE_COUNT => $subscriptions_count->[0]{not_active_subscriptions},
      TABLE            => $table->show()
    },
  );

  return 1;
}

#**********************************************************
=head2 sharing_demo_report()


=cut
#**********************************************************
sub sharing_demo_report {
  my $demo_files = $Sharing->sharing_get_demo_files();

  my $table = $html->table({
    width   => '100%',
    caption => $lang{FILES_DEMO},
    title   => [ $lang{USER}, $lang{DATE_TO}, $lang{FILE} ],
  });

  foreach my $file (@$demo_files) {
    my $user_button = $html->button($file->{id}, "index=15&UID=$file->{uid}", { BUTTON => 1, ICON => "fa fa-user" });
    $user_button .= $html->button($file->{id}, "index=15&UID=$file->{uid}");
    $table->addrow($user_button, $file->{date_to}, $file->{name});
  }

  print $table->show();

  return 1;
}

1;