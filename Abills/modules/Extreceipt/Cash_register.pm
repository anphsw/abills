package Extreceipt::Cash_register;

use strict;
use warnings FATAL => 'all';

use Extreceipt::Init qw(init_extreceipt_service);
use Extreceipt::db::Extreceipt;

my $Extreceipt;
my $Receipt_api;

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  $Extreceipt = Extreceipt->new($db, $admin, $conf);
  $Receipt_api = init_extreceipt_service($db, $admin, $conf);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 cash_collection($id)

  ATTR:
    $id: number  - API ID

  Return
    $service_receipt: obj
=cut
#**********************************************************
sub cash_collection {
  my $self = shift;
  my ($id) = @_;

  my $x_report = $Receipt_api->{$id}->create_x_report();
  return if ($x_report->{ERROR});

  my $sum = $x_report->{current_balance} ? $x_report->{current_balance} / 100 : 0;

  return {
    ERROR => 'No cash in cash register',
  } if ($sum == 0);

  my $service_receipt = $self->service_receipt($id, -$sum);
  $service_receipt->{AMOUNT} = $sum;

  return $service_receipt;
}

#**********************************************************
=head2 service_receipt($id, $sum)

  ATTR:
    $id: number  - API ID
    $sum: number - amount to deposit/withdraw

  Return
    $service_receipt: obj

=cut
#**********************************************************
sub service_receipt {
  my $self = shift;
  my ($id, $sum) = @_;

  my $service_receipt = $Receipt_api->{$id}->create_service_receipt($sum);

  return if ($service_receipt->{ERROR});

  $self->{admin}->{MODULE} = 'Extreceipt';
  my $text = "AMOUNT: " . abs($sum) . "; AID: $self->{admin}->{AID}; API ID: $id";

  if ($sum > 0) {
    $self->{admin}->system_action_add("SERVICE RECEIPT DEPOSIT $text", { TYPE => 1 });
  }
  else {
    $self->{admin}->system_action_add("SERVICE RECEIPT WITHDRAWAL $text", { TYPE => 10 });
  }

  return $service_receipt;
}

1;
