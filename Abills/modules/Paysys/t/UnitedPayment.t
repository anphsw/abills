#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use Paysys::t::Init_t;
use Paysys::Plugins::UnitedPayment;

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

my $Payment_plugin = Paysys::Plugins::UnitedPayment->new($db, $admin, \%conf);

# for test swap to local public key

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$payment_sum = $payment_sum * 100;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

our %request_params = (
  toProcessId => $payment_id,
  amount      => $payment_sum,
  memberId    => $user_id,
  description => 'TEST DESC FROM TEST',
  requestId   => $payment_id + 500,
);

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
memberId=$request_params{memberId}
requestId=$request_params{requestId}
description=$request_params{description}},
    get     => 1,
    path    => '/api/kiosk/merchant/member-info',
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
memberId=$request_params{memberId}
toProcessId=$request_params{toProcessId}
description=$request_params{description}
amount=$request_params{amount}},
    get     => 1,
    path    => '/api/kiosk/merchant/insert-payment',
    result  => qq{}
  },
  {
    name    => 'STATUS',
    request => qq{
toProcessId=$request_params{toProcessId}},
    get     => 1,
    path    => '/api/kiosk/merchant/payment-status',
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, {});

1;
