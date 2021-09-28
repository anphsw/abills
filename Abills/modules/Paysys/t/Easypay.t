#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

require Paysys::systems::Easypay;
my $Payment_plugin = Paysys::systems::Easypay->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}
$user_id = $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || 111111111111;
my $sign = q{};
my $service_id = q{2431};
my $order_id = q{6223372036854775807};

our @requests = (
  {
    name    => 'GET_USER',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Check>
    <ServiceId>$service_id</ServiceId>
    <Account>$user_id</Account>
  </Check>
</Request>
     }
  },
  {
    name    => 'PAY',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Payment>
    <ServiceId>$service_id</ServiceId>
    <OrderId>$order_id</OrderId>
    <Account>$user_id</Account>
    <Amount>$payment_sum</Amount>
  </Payment>
</Request>
     }
  },
  {
    name    => 'CONFIRM',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Confirm>
    <ServiceId>$service_id</ServiceId>
    <PaymentId>210</PaymentId>
  </Confirm>
</Request>
     }
  },
  {
    name    => 'CANCEL',
    request => qq{<Request>
  <DateTime>2021-05-21T16:19:50</DateTime>
  <Sign>$sign</Sign>
  <Cancel>
    <ServiceId>$service_id</ServiceId>
    <PaymentId>210</PaymentId>
  </Cancel>
</Request>
     }
  },
  # {
  #   name    => 'MERCH_PAY',
  # request => qq{{
  #   "action": "payment",
  #   "merchant_id": 5347,
  #   "order_id": "5",
  #   "version": "v3.0",
  #   "date": "2019-06-19T15:38:10.7802613+03:00",
  #   "details": {
  #     "amount": 1.00,
  #     "desc": "Wooden tables x 10",
  #     "payment_id": 724502946,
  #     "recurrent_id": null
  #   },
  #   "additionalitems": {
  #     "BankName": "CB PRIVATBANK",
  #     "Card.Pan": "414962******6660",
  #     "MerchantKey": "easypay.ua",
  #     "Merchant.OrderId": "5"
  #   }
  # }}
  # },
  # {
  #   name    => 'MERCH_REFUND',
  #   request => qq{{
  #   "action": "refund",
  #   "merchant_id": 5347,
  #   "order_id": "5",
  #   "version": "v3.0",
  #   "date": "2019-06-19T15:38:10.7802613+03:00",
  #   "details": {
  #     "amount": 1.00,
  #     "desc": "Wooden tables x 10",
  #     "payment_id": 724502946,
  #     "recurrent_id": null
  #   },
  #   "additionalitems": {
  #     "BankName": "CB PRIVATBANK",
  #     "Card.Pan": "414962******6660",
  #     "MerchantKey": "easypay.ua",
  #     "Merchant.OrderId": "5"
  #   }
  # }}
  # },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

