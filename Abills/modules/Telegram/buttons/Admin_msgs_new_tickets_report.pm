package Telegram::buttons::Admin_msgs_new_tickets_report;

use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);

my %icons = (
  report => "\xF0\x9F\x93\x8A",
  open   => "\xF0\x9F\x94\x93",
  closed => "\xF0\x9F\x94\x92",
  line   => "\xE2\x9E\x96",
);

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $admin_config)

=cut
#**********************************************************
sub new {
  my ($class, $conf, $bot, $bot_db, $APILayer, $admin_config) = @_;

  my $self = {
    conf         => $conf,
    bot          => $bot,
    bot_db       => $bot_db,
    api          => $APILayer,
    admin_config => $admin_config,
    for_admins   => 1,
    last_page    => 1,
  };

  return bless $self, $class;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {1}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;
  return $self->{bot}{lang}{TELEGRAM_REPORT_ON_REQUESTS};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my ($self, $attr) = @_;

  my $weeks_range = _get_weeks_range();

  my $total_opened_this_week = $self->_fetch_total($weeks_range->{this_week});
  my $total_opened_last_week = $self->_fetch_total($weeks_range->{last_week});
  my $total_closed_this_week = $self->_fetch_total($weeks_range->{this_week}, 1);
  my $total_closed_last_week = $self->_fetch_total($weeks_range->{last_week}, 1);

  my $report_text = <<"END";
$icons{report} $self->{bot}{lang}{TELEGRAM_REPORT_ON_REQUESTS}

$icons{open} $self->{bot}{lang}{TELEGRAM_OPEN}:
$icons{line} $self->{bot}{lang}{TELEGRAM_THIS_WEEK}: $total_opened_this_week
$icons{line} $self->{bot}{lang}{TELEGRAM_LAST_WEEK}: $total_opened_last_week

$icons{closed} $self->{bot}{lang}{CLOSED}:
$icons{line} $self->{bot}{lang}{TELEGRAM_THIS_WEEK}: $total_closed_this_week
$icons{line} $self->{bot}{lang}{TELEGRAM_LAST_WEEK}: $total_closed_last_week
END

  $self->{bot}->send_message({ text => $report_text });
}

#**********************************************************
=head2 _fetch_total($self, $range, $closed)

=cut
#**********************************************************
sub _fetch_total {
  my ($self, $range, $closed) = @_;

  my %params = $closed
    ? (CLOSED_FROM_DATE => $range->{start}, CLOSED_TO_DATE => $range->{end})
    : (FROM_DATE => $range->{start}, TO_DATE => $range->{end});

  if ($self->{admin_config}{AID}) {
    $params{RESPOSIBLE} = $self->{admin_config}{AID};
  }

  my ($res) = $self->{api}->fetch_api({
    PATH   => '/msgs/list/',
    PARAMS => \%params,
  });

  return $res->{total} || 0;
}

#**********************************************************
=head2 _get_weeks_range()

=cut
#**********************************************************
sub _get_weeks_range {
  my $now = time;
  my @lt = localtime($now);

  my $wday = $lt[6] || 7;

  my $start_this_week = $now - ($wday - 1) * 24 * 3600;
  my $end_this_week = $start_this_week + 6 * 24 * 3600;

  my $start_last_week = $start_this_week - 7 * 24 * 3600;
  my $end_last_week = $start_last_week + 6 * 24 * 3600;

  return {
    this_week => {
      start => strftime("%Y-%m-%d", localtime($start_this_week)),
      end   => strftime("%Y-%m-%d", localtime($end_this_week)),
    },
    last_week => {
      start => strftime("%Y-%m-%d", localtime($start_last_week)),
      end   => strftime("%Y-%m-%d", localtime($end_last_week)),
    },
  };
}

1;
