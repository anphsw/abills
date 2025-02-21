package Api::Controllers::Admin::Intervals;

=head1 NAME

  ADMIN API Intervals

  Endpoints:
    /intervals/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Tariffs;

my Control::Errors $Errors;
my Tariffs $Tariffs;

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

  $Errors = $self->{attr}->{Errors};
  $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
  return $self;
}

#**********************************************************
=head2 get_intervals_tpId($path_params, $query_params)

  Endpoint GET /intervals/:tpId/

=cut
#**********************************************************
sub get_intervals_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  $Tariffs->ti_info($path_params->{tpId});
}

1;
