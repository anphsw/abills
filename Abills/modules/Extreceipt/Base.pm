package Extreceipt::Base;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;
my $lang;

use Extreceipt::Init qw(init_extreceipt_service);
use Extreceipt::db::Extreceipt;
my Extreceipt $Extreceipt;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF, $attr) = @_;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {
    db     => $db,
    conf   => $CONF,
    admin  => $admin
  };

  $Extreceipt = Extreceipt->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 extreceipt_payments_maked($attr)

  Arguments:
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub extreceipt_payments_maked {
  my (undef, $attr) = @_;

  return 0 if ($attr->{_EXECUTION_COUNT} && $attr->{_EXECUTION_COUNT} > 1);

  ::load_module('Extreceipt');

  my $list = $Extreceipt->info($attr->{PAYMENT_ID});
  if (scalar @$list > 0) {
    return 0;
  }

  ::_extreceipt_new();
  ::_extreceipt_send($attr->{PAYMENT_ID});

  return 1;
}

#**********************************************************
=head2 extreceipt_payment_del($attr) - Cross module payment deleted

  Arguments:
    $attr
      PAYMENT_ID
      UID

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub extreceipt_payment_del {
  my ($self, $attr) = @_;

  return 0 if (!$attr->{ID});
  return 0 if (!$attr->{PAYMENT_INFO} || !$attr->{PAYMENT_INFO}->{SUM});

  my $payment = $Extreceipt->info($attr->{ID});

  return 0 if ($Extreceipt->{errno} || !$Extreceipt->{TOTAL});

  # take sum from payment info, payment already deleted, data in Extreceipt->info(...) is undef
  $payment->[0]->{sum} = $attr->{PAYMENT_INFO}->{SUM};
  my $api_id = $payment->[0]->{api_id} // 0;

  return 0 if (!$payment->[0]->{status} || $payment->[0]->{status} != 1 || !$api_id);

  ::load_module('Extreceipt');
  ($payment->[0]->{check_header}, $payment->[0]->{check_desc}, $payment->[0]->{check_footer}) = ::_extreceipt_receipt_ext_info($payment->[0]);

  my $Plugin = init_extreceipt_service($self->{db}, $self->{admin}, $self->{conf}, { API_ID => $api_id });

  return 0 if (!$Plugin->{$api_id}->can('payment_cancel'));

  $Plugin->{$api_id}->payment_cancel($payment->[0]);

  return $self;
}

1;
