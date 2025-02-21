#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Digest::SHA;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::Plugins::Qiwi;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv,
  $program_name
);

my $Payment_plugin = Paysys::Plugins::Qiwi->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_date =~ s/[-: ]//g;

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

my $sign_str = "40aae427-892e-46b8-89d5-12b17fd889d6|2024-09-16T19:33:16+06:00|$payment_sum";
my $sign = Digest::SHA::hmac_sha256_hex($conf{PAYSYS_QIWI_API_KEY}, $sign_str);

if ($program_name =~ /.+\.t$/) {
  $Paysys->add({
    SYSTEM_ID      => 104,
    SUM            => $payment_sum,
    UID            => $user_id,
    IP             => $ENV{REMOTE_ADDR},
    TRANSACTION_ID => "QIWI:$payment_id",
    PAYSYS_IP      => $ENV{REMOTE_ADDR},
    STATUS         => 1,
  });
}

our @requests = (
  {
    name      => 'PAYMENT',
    headers   => [
      'Content-Type: application/json',
      "Signature: $sign"
    ],
    request   => qq/{
  "type": "PAYMENT",
  "version": "1",
  "payment": {
    "type": "PAYMENT",
    "paymentId": "40aae427-892e-46b8-89d5-12b17fd889d6",
    "createdDateTime": "2024-09-16T19:33:16+06:00",
    "status": {
      "value": "SUCCESS",
      "changedDateTime": "2024-09-16T19:33:19+06:00"
    },
    "amount": {
      "currency": "KZT",
      "value": $payment_sum
    },
    "paymentMethod": {
      "maskedPan": "523600******0005",
      "rrn": "5147315884203",
      "type": "CARD"
    },
    "billId": "$payment_id",
    "flags": [
      "AUTH"
    ]
  }
}
/,
  },
  {
    name      => 'REFUND',
    headers   => [
      'Content-Type: application/json',
      "Signature: $sign"
    ],
    request   => qq/{
  "type": "REFUND",
  "version": "1",
  "refund": {
    "type": "REFUND",
    "refundId": "40aae427-892e-46b8-89d5-12b17fd889d6",
    "createdDateTime": "2024-09-16T19:33:16+06:00",
    "status": {
      "value": "SUCCESS",
      "changedDateTime": "2024-09-16T19:34:13+06:00"
    },
    "amount": {
      "currency": "KZT",
      "value": $payment_sum
    },
    "paymentMethod": {
      "maskedPan": "523600******0005",
      "rrn": "5147315884203",
      "type": "CARD"
    },
    "billId": "$payment_id"
  }
}
/,
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
