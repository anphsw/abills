package Api::Controllers::Admin::Finance;

=head1 NAME

  ADMIN API Finance

  Endpoints:
    /finance/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Payments;

my Control::Errors $Errors;
my Payments $Payments;

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
  $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_finance_exchange_rate($path_params, $query_params)

  Endpoint GET /finance/exchange/rate/

=cut
#**********************************************************
sub get_finance_exchange_rate {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Payments->exchange_list({ COLS_NAME => 1 })
}

#**********************************************************
=head2 get_finance_exchange_rate_log($path_params, $query_params)

  Endpoint GET /finance/exchange/rate/log/

=cut
#**********************************************************
sub get_finance_exchange_rate_log {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Payments->exchange_log_list({ COLS_NAME => 1 })
}


1;
