#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
use Abills::Base qw(encode_base64);
use Digest::MD5 qw(md5_hex);

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

my $Payment_plugin;
if (!$conf{PAYSYS_V4}) {
  require Paysys::Plugins::Upay;
  $Payment_plugin = Paysys::Plugins::Upay->new($db, $admin, \%conf);
}
else {
  require Paysys::Plugins::Upay;
  $Payment_plugin = Paysys::Plugins::Upay->new($db, $admin, \%conf);
}

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $secret = $Payment_plugin->{conf}->{PAYSYS_UPAY_SECRET} || '';
my $checksum_pay = Digest::MD5::md5_hex($payment_id . $secret . $payment_sum . $user_id);
my $checksum_check = Digest::MD5::md5_hex($user_id . $secret);

our @requests = (
  {
    name     => '1_CHECK',
    request  => qq/
{
   "personalAccount":"$user_id",
   "accessToken":"$checksum_check"
}
/,
  },
  {
    name     => '2_PAYMENT',
    request  => qq/
{
   "personalAccount":"$user_id",
   "accessToken":"$checksum_pay",
   "upayTransId":"$payment_id",
   "upayPaymentAmount":"$payment_sum"
}
/,
  },
);

test_runner($Payment_plugin, \@requests);

1;
