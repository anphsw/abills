package Api::Controllers::User::Payments;

=head1 NAME

  User API Payments

  Endpoints:
    /user/payments/*

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
=head2 get_user_payments($path_params, $query_params)

  Endpoint GET /user/payments/

=cut
#**********************************************************
sub get_user_payments {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $payments = $Payments->list({
    UID       => $path_params->{uid},
    DSC       => '_SHOW',
    SUM       => '_SHOW',
    DATETIME  => '_SHOW',
    EXT_ID    => '_SHOW',
    PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
    COLS_NAME => 1
  });

  foreach my $payment (@$payments) {
    delete @{$payment}{qw/inner_describe/};
  }

  return $payments;
}

1;
