#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Paymasterru;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Paymasterru->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}
$user_id = $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || 5;

my %FORM = (
  LMI_MERCHANT_ID      => '085415af-10dd-4654-9a56-1f98836dfc30',
  LMI_PAYMENT_NO       => '357314291',
  LMI_SYS_PAYMENT_ID   => '3214845261',
  LMI_PAYMENT_AMOUNT   => '50.00',
  LMI_PAID_AMOUNT      => '50.00',
  LMI_PAYMENT_SYSTEM   => '165',
  LMI_SYS_PAYMENT_DATE => '2021-09-01T05:57:51',
  LMI_PAID_CURRENCY    => 'RUB',
  LMI_CURRENCY         => 'RUB',
  LMI_HASH             => ''
);

my $signature = $Payment_plugin->mk_sign(\%FORM);

#FmyK8EaEj6KfyRptz8UDgg==

our @requests = (
  {
    name    => 'PAY',
    get     => 1,
    request => qq{LMI_PAYMENT_NO=357314291
LMI_SYS_PAYMENT_ID=3214845261
LMI_PAYMENT_AMOUNT=50.00
LMI_PAYMENT_DESC=Internet
LMI_PAID_CURRENCY=RUB
LMI_CURRENCY=RUB
LMI_PAID_AMOUNT=50.00
LMI_SYS_PAYMENT_DATE=2021-09-01T05:57:51
LMI_PAYMENT_METHOD=BankCard
LMI_HASH=$signature
LMI_PAYER_IDENTIFIER=521324XXXXXX7147
LMI_SHOP_ID=200000000025260/200038961/503655
LMI_PAYER_IP_ADDRESS=95.153.135.20
LMI_MERCHANT_ID=085415af-10dd-4654-9a56-1f98836dfc30
LMI_PAYMENT_SYSTEM=165
USER=$user_id
},
    result  => q{},
  }
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });


1;