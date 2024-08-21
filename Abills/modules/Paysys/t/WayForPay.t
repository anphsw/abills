#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::WayForPay;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv
);

my $Payment_plugin = Paysys::systems::WayForPay->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

my $merchant_id = $conf{PAYSYS_WFP_ID} || '';

$Paysys->add({
  SYSTEM_ID      => 156,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "WFP:$payment_id",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

my $sign = $Payment_plugin->mk_sign({
  merchantAccount   => $merchant_id,
  orderReference    => "WFP:$payment_id",
  amount            => $payment_sum,
  currency          => 'UAH',
  authCode          => '767147',
  cardPan           => '471***8181',
  transactionStatus => 'Approved',
  reasonCode        => 1100
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/
{
  "merchantAccount": "$merchant_id",
  "orderReference": "WFP:$payment_id",
  "merchantSignature": "$sign",
  "amount": $payment_sum,
  "currency": "UAH",
  "authCode": "767147",
  "email": "test\@gmail.com",
  "phone": "09999999999",
  "createdDate": 1711666540,
  "processingDate": 1711666679,
  "cardPan": "471***8181",
  "cardType": "Visa",
  "issuerBankCountry": "Ukraine",
  "issuerBankName": "JSC CB PRIVATBANK",
  "recToken": "",
  "transactionStatus": "Approved",
  "reason": "Ok",
  "reasonCode": 1100,
  "fee": 0.02,
  "paymentSystem": "googlePay",
  "acquirerBankName": "WayForPay",
  "cardProduct": "debit",
  "clientName": "Test user",
  "products": [
    {
      "name": "\u0422\u0440\u0430\u043d\u0437\u0430\u043a\u0446\u0456\u044f: WFP:35957656 \u041f\u0406\u0411: Test user UID: 1",
      "price": $payment_sum,
      "count": 1
    }
  ],
  "rrn": "411900577159",
  "terminal": "P0137340",
  "acquirer": "Test"
}
   /,
    result  => q{}
  },
);

test_runner($Payment_plugin, \@requests);

1;
