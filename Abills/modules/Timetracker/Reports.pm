=head1 NAME

  Reports
  
=cut

use warnings FATAL => 'all';
use strict;
use Abills::Base qw(time2sec sec2time);
use Timetracker::db::Timetracker;

our (%FORM, $db, %conf, $admin, %lang, @WEEKDAYS, $pages_qs);
our Abills::HTML $html;
my $Timetracker = Timetracker->new($db, $admin, \%conf);

#**********************************************************
=head2 all_report_time() - shows a table of repots

=cut
#**********************************************************
sub all_report_time {
  require Timetracker::Redmine;
  Redmine->import();
  my $Redmine = Redmine->new($db, $admin, \%conf);

  reports(
    {
      NO_GROUP    => 1,
      NO_TAGS     => 1,
      DATE_RANGE  => 1,
      DATE        => $FORM{DATE},
      REPORT      => '',
      PERIOD_FORM => 1,
    }
  );

  my $table_support = $html->table(
    {
      width   => "100%",
      caption => $lang{REPORTS_HEADER},
      title   => [ $lang{ADMINS_LIST}, $lang{CLOSE_MOUTH}, $lang{SCHEDULED_HOURS},
        $lang{TIME_COMPLEXITY},
        $lang{ACTUALLY_HOURS},
        $lang{CLOSED_TICKETS}, $lang{TIME_SUPPORT} ],
      qs      => $pages_qs,
      ID      => "TIMETRACKER_REPORT1",
      EXPORT  => 1
    }
  );

  my $admins_list = sel_admins({ HASH=>1, DISABLE => 0 });

  my @admin_aids = ();

  for my $aid (keys %{$admins_list}) {
    push(@admin_aids, $aid);
  }

  if (!$FORM{FROM_DATE} || !$FORM{TO_DATE}) {
    my ($day, $month, $year) = (localtime)[3,4,5];
    $FORM{FROM_DATE} = sprintf("%04d-%02d-%02d", $year+1900, $month+1, 1);
    $FORM{TO_DATE} = sprintf("%04d-%02d-%02d", $year+1900, $month+1, $day);
  }

  my %attr = (
    FROM_DATE => $FORM{FROM_DATE},
    TO_DATE => $FORM{TO_DATE},
    DEBUG => 0,
    ADMIN_AIDS => \@admin_aids,
  );
  
  my $spent_hours = $Redmine->get_spent_hours(\%attr);
  my $closed_tasks = $Redmine->get_closed_tasks(\%attr);
  my $hours_on_complexity = $Redmine->get_scheduled_hours_on_complexity(\%attr);
  my $scheduled_hours = $Redmine->get_scheduled_hours(\%attr);
  my $cloused_support_ticket = get_cloused_support_ticket(\%attr);
  my $run_time_with_support = get_run_time_with_support(\%attr);

  my $total_closed_tasks = 0;
  my $total_points = 0;
  my $total_secs = 0;
  my $total_spent_hours = 0;
  my $total_scheduled_hours = 0;

  for my $aid (keys %{$admins_list}) {
    $table_support->addrow(
      $admins_list->{$aid} || 0, 
      $closed_tasks->{$aid} || 0,
      $scheduled_hours->{$aid} || 0,
      $hours_on_complexity->{$aid} || 0,
      $spent_hours->{$aid} || 0,
      $cloused_support_ticket->{$aid} || 0,
      $run_time_with_support->{$aid} || 0
    );

    $total_closed_tasks += $closed_tasks->{$aid} || 0;
    $total_scheduled_hours += $scheduled_hours->{$aid} || 0;
    $total_spent_hours += $spent_hours->{$aid} || 0;
    $total_points += $hours_on_complexity->{$aid} || 0;
    $total_secs += time2sec($run_time_with_support->{$aid} || 0);
  }

  $table_support->addrow(
    $lang{TOTAL},
    $html->b($total_closed_tasks || 0),
    $html->b($total_scheduled_hours || 0),
    $html->b($total_points || 0),
    $html->b($total_spent_hours || 0),
    0,
    $html->b(sec2time($total_secs, { str => 1 }))
  );

  print $table_support->show();

  return 1;
}

#**********************************************************
=head2 get_cloused_support_ticket($attr) - get count cloused support ticket for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };
  
  Returns:
    $cloused_support_ticket
  
  Example:
    get_cloused_support_ticket($attr)
=cut
#**********************************************************
sub get_cloused_support_ticket {
  my ($attr) = @_;
  my $cloused_support_ticket = {};

  my $size_support = $Timetracker->change_element_work({
    DATA_DAY => $attr->{FROM_DATE},
    TO_DATA_DAY => $attr->{TO_DATE},
  });

  foreach my $admin (@$size_support){
    for my $aid (@{$attr->{ADMIN_AIDS}}) {
      if($aid == $admin->{aid}){
        $cloused_support_ticket->{$aid} = $admin->{admins_count};
      }
    }
  }

  return $cloused_support_ticket;
}

=head2 get_run_time_with_support($attr) - get run time with support ticket for admin
  Arguments:
    $attr = {
      FROM_DATE => '2020-01-01',
      TO_DATE => '2020-02-20',
      DEBUG => 0,
      ADMIN_AIDS => [1, 2, 3],
    };
  
  Returns:
    $time_with_support
  
  Example:
    get_run_time_with_support($attr);
=cut
#**********************************************************
sub get_run_time_with_support {
  my ($attr) = @_;
  my $time_with_support = {};

  my $all_time_with_support = $Timetracker->get_run_time({
    FROM_DATE => $attr->{FROM_DATE}.' 00:00:00',
    TO_DATE => $attr->{TO_DATE}.' 23:59:59',
  });

  for my $times (@{$all_time_with_support}) {
    for my $aid (@{$attr->{ADMIN_AIDS}}) {
      if($times->{aid} == $aid) {
        $time_with_support->{$aid} += $times->{run_time};
        Abills::Base::sec2time($times->{run_time}, {format => 1});
      }
    }
  }

  for my $aid (@{$attr->{ADMIN_AIDS}}) {
    $time_with_support->{$aid} = Abills::Base::sec2time($time_with_support->{$aid}, {format => 1});
  }

  return $time_with_support;
}


return 1;