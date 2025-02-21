package Api::Controllers::User::Fees;

=head1 NAME

  User API Fees

  Endpoints:
    /user/fees/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Fees;

my Control::Errors $Errors;
my Fees $Fees;

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
  $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_user_fees($path_params, $query_params)

  Endpoint GET /user/fees/

=cut
#**********************************************************
sub get_user_fees {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $fees = $Fees->list({
    UID       => $path_params->{uid},
    DSC       => '_SHOW',
    SUM       => '_SHOW',
    DATETIME  => '_SHOW',
    PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
    COLS_NAME => 1
  });

  foreach my $fee (@$fees) {
    delete @{$fee}{qw/inner_describe/};
  }

  return $fees;
}

1;
