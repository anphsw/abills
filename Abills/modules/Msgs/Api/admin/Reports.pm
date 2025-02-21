package Msgs::Api::admin::Reports;

=head1 NAME

  Msgs report

  Endpoints:
    /msgs/report/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Msgs;

my Msgs $Msgs;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Msgs = Msgs->new($db, $admin, $conf);
  $Msgs->{debug} = $self->{debug};
  $self->{permissions} = $Msgs->permissions_list($admin->{AID});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_msgs_report_dynamics($path_params, $query_params)

  Endpoint GET /msgs/report/dynamics

=cut
#**********************************************************
sub get_msgs_report_dynamics {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $messages_and_replies = $Msgs->messages_and_replies_for_two_weeks();

  my $data_by_days = {};
  foreach my $data (@{$messages_and_replies}) {
    if ($data_by_days->{$data->{day}}) {
      $data_by_days->{$data->{day}}{MESSAGES} += $data->{messages} || 0;
      $data_by_days->{$data->{day}}{REPLIES} += $data->{replies} || 0;
      next;
    }
    $data_by_days->{$data->{day}} = {
      MESSAGES => $data->{messages} || 0,
      REPLIES  => $data->{replies} || 0,
      CLOSED   => 0
    };
  }

  my $closed_messages = $Msgs->messages_and_replies_for_two_weeks(join(',', map { "'$_'" } keys %{$data_by_days}));
  foreach my $closed_message (@{$closed_messages}) {
    $data_by_days->{$closed_message->{day}}{CLOSED} = $closed_message->{closed_messages};
  }

  my @result = ();

  foreach my $date (sort keys %{$data_by_days}) {
    push @result, { DATE  => $date, VALUE => $data_by_days->{$date} }
  }

  return {
    list  => \@result,
    total => scalar(@result)
  };
}

1;
