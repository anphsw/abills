#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use_ok('Digest::HMAC');
use_ok('Digest::MD5');
use_ok('Paysys::t::Init_t');

done_testing();

use Digest::MD5;
use Digest::HMAC;

use Paysys::t::Init_t;
require Paysys::systems::GercPay;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv,
  $base_dir,
  $DATE
);

my $Payment_plugin = Paysys::systems::GercPay->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $merchant_id = $conf{PAYSYS_GERC_MERCHANT_ID} || '';
my $transaction_id = "GERCPAY:$payment_id";

$Paysys->add({
  SYSTEM_ID      => 169,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => $transaction_id,
  INFO           => 'Test payment',
  PAYSYS_IP      => '127.0.0.1',
  STATUS         => 1,
});


my $sign = $Payment_plugin->mk_sign({
  merchantAccount => $merchant_id,
  orderReference  => $transaction_id,
  amount          => $payment_sum,
  currency        => 'UAH',
  operation       => 'Purchase'
});

our @requests = (
  # make success payment
  {
    name      => 'PAY_SUCCESS',
    request   => qq|{
    "merchantAccount": "$merchant_id",
    "orderReference": "$transaction_id",
    "amount": "$payment_sum",
    "operation": "Purchase",
    "currency": "UAH",
    "phone": "+38 (011) 222-33-44",
    "createdDate": "2023-05-30 16:27:21",
    "cardPan": "403021******9287",
    "cardType": "Visa",
    "fee": "0.02",
    "transactionId": $payment_id,
    "type": "payment",
    "recToken": "b8e61cd175c51237cf58342377592ff8d465f25ed50288a5f3ef9a01517c3bc1",
    "add_params": {
        "secure_type": "1",
        "lifetime": "1685539641",
        "AReqDetails.browserAcceptHeader": "q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "AReqDetails.browserColorDepth": "24",
        "AReqDetails.browserIP": "10.253.2.159",
        "AReqDetails.browserLanguage": "ru",
        "AReqDetails.browserScreenHeight": "1080",
        "AReqDetails.browserScreenWidth": "1920",
        "AReqDetails.browserTZ": "-120",
        "AReqDetails.browserUserAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "AReqDetails.browserJavaEnabled": "true",
        "AReqDetails.notificationUrl": "https://gercpay.com.ua/payment/check3ds?payment=0cc44844b30ae8a0273e6c7b010ce34f86e8729fea2b6f7b628c92232ed33eb06475f9b999c03",
        "AReqDetails.deviceChannel": "02",
        "AReqDetails.threeRIInd": "",
        "CReqDetails.WindowWidth": "1024",
        "CReqDetails.WindowHeight": "768",
        "merchantName": "merchant",
        "RRN": "001206018623"
    },
    "transactionStatus": "Approved",
    "reason": "ОПЕРАЦИЯ РАЗРЕШЕНА",
    "reasonCode": "1",
    "pcTransactionID": "1206018623",
    "pcApprovalCode": "7E06C0 A",
    "merchantSignature": "$sign"
}|,
  },
  # make error payment
  {
    name      => 'PAY_ERROR',
    request   => qq/{
    "merchantAccount": "$merchant_id",
    "orderReference": "$transaction_id",
    "amount": "$payment_sum",
    "operation": "Purchase",
    "currency": "UAH",
    "phone": "+38 (011) 222-33-44",
    "createdDate": "2023-05-30 16:54:11",
    "cardPan": "403021******9287",
    "cardType": "Visa",
    "fee": "1.82",
    "transactionId": $payment_id,
    "type": "verify",
    "recToken": "",
    "transactionStatus": "Declined",
    "reason": "НА СЧЕТЕ НЕ ХВАТАЕТ ДЕНЕГ",
    "reasonCode": "76",
    "pcTransactionID": "1206054482",
    "pcApprovalCode": "145036 A",
    "merchantSignature": "$sign"
}/,
  },
);

test_runner($Payment_plugin, \@requests);

1;
