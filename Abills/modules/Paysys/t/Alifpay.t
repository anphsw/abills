#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::Plugins::Alifpay;

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

my $Payment_plugin = Paysys::Plugins::Alifpay->new($db, $admin, \%conf);

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_id = 100000 + int(rand(10000));
my $transaction_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_date =~ s/[-: ]//g;

$conf{PAYSYS_ALIFPAY_LOGIN} //= '';
$conf{PAYSYS_ALIFPAY_PASSWD} //= '';

my $auth = "basic " . encode_base64("$conf{PAYSYS_ALIFPAY_LOGIN}:$conf{PAYSYS_ALIFPAY_PASSWD}");

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

our @requests = (
  {
    name    => 'CHECK',
    request => qq/
{
  "id": $transaction_id,
  "action": "check",
  "account": "$user_id"
}/,
    headers   => [
      'Content-Type: application/json',
      "Authorization: $auth"
    ],
  },
  {
    name    => 'PAY',
    request => qq/
{
  "id": $transaction_id,
  "action": "pay",
  "account": "$user_id",
  "amount": $payment_sum,
  "time": "2024-08-06T15:04:05Z"
}/,
    headers   => [
      'Content-Type: application/json',
      "Authorization: $auth"
    ],
  },
  {
    name    => 'STATUS',
    request => qq/
{
  "id": $transaction_id,
  "action": "status"
}/,
    headers   => [
      'Content-Type: application/json',
      "Authorization: $auth"
    ],
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

