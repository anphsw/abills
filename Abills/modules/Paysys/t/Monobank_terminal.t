#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

require Paysys::Plugins::Monobank_terminal;

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

my $Payment_plugin = Paysys::Plugins::Monobank_terminal->new($db, $admin, \%conf);
$Payment_plugin->{TEST}=1;
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_sum = int($payment_sum * 100);
$payment_id = int(rand(10000));
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $date = POSIX::strftime('%Y%m%d%H%M%S', localtime());

our @requests = (
  {
    name          => 'CHECK',
    request       => qq{
amount=$payment_sum
account=$user_id},
    get           => 1,
    result        => qq{},
    result_schema => 'Monobank_terminal/check-response.json',
    path    => '/api/v1/debt/search',
  },
  {
    name    => 'PAY',
    request => qq{
{
  "createdAt": "2025-04-30T14:06:18.896788",
  "trackingId": $payment_id,
  "paymentChannel": "MOBILE",
  "account": "$user_id",
  "terminalInfo": {
    "terminalId": "term1"
  },
  "payments": [
    {
      "companyCode": "123446",
      "serviceCode": "123455",
      "paymentId": 1$payment_id,
      "amount": 10.21
    },
    {
      "companyCode": "2132133",
      "serviceCode": "22411",
      "paymentId": 2$payment_id,
      "amount": 18.54
    }
  ]
}
},
    result_schema => 'Monobank_terminal/pay-response.json',
    path    => '/api/v1/debt/payment',
    result_type => 'json',
    result  => q{}
  },
  {
    name          => 'STATUS',
    request       => qq{
trackingId=$payment_id},
    get           => 1,
    result        => qq{},
    path          => '/api/v1/debt/payment/check',
    result_schema => 'Monobank_terminal/status-response.json',
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'json_compare' });

1;

