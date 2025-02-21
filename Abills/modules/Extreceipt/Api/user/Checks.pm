package Extreceipt::Api::user::Checks;

=head1 NAME

  Equipment Onu

  Endpoints:
    /user/equipment/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Extreceipt::db::Extreceipt;
use Extreceipt::Init qw(init_extreceipt_service);

my Extreceipt $Receipt;
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

  $Receipt = Extreceipt->new($self->{db}, $self->{admin}, $self->{conf});
  my $Receipt_api = init_extreceipt_service($db, $admin, $conf);
  $Receipt->{API} = $Receipt_api;
  $Receipt->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_extreceipt_checks($path_params, $query_params)

  Endpoint GET /user/extreceipt/checks/

=cut
#**********************************************************
sub get_user_extreceipt_checks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $list = $Receipt->list({
    UID => $path_params->{uid},
  });

  my @return = ();

  foreach my $check (@{$list}) {
    my %params = (
      date       => $check->{date},
      payment_id => $check->{payments_id},
    );
    next if (!$check->{api_id});
    if ($Receipt->{API}->{$check->{api_id}}->can('get_receipt')) {
      $params{check_url} = ($check->{command_id} =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/gm) ?
        $Receipt->{API}->{$check->{api_id}}->get_receipt($check) : "";

      if ($check->{cancel_id} =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/gm) {
        $check->{command_id} = $check->{cancel_id};
        $params{check_cancel_url} = $Receipt->{API}->{$check->{api_id}}->get_receipt($check);
      }
    }
    push @return, \%params;
  }

  return \@return;
}

1;
