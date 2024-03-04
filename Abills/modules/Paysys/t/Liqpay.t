#!/usr/bin/perl -w

=head1 NAME

 Paysys Liqpay tests

=cut

use strict;
use warnings FATAL => 'all';
use Test::More;

use lib '.';
use lib '../../';

use Paysys::t::Init_t;
use Abills::Base qw(json_former urlencode);
require Paysys::systems::Liqpay;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv,
  %lang
);

$user_id = $argv->{user} || $argv->{UID} || $conf{PAYSYS_TEST_USER} || $user_id || 1;
my $random_number = int(rand(100000));

my $Paysys = Paysys->new($db, $admin, \%conf);
my $Liqpay = Paysys::systems::Liqpay->new($db, $admin, \%conf, {
  CUSTOM_NAME => $argv->{CUSTOM_NAME} || '',
  CUSTOM_ID   => $argv->{CUSTOM_ID} || '',
  lang        => \%lang
});

if ($debug > 3) {
  $Liqpay->{DEBUG}=7;
}

if($argv->{HOTSPOT} && $argv->{HOTSPOT} == 1){
  $user_id = $random_number;
}

$Paysys->add({
  SYSTEM_ID      => 62,
  SUM            => 1.00,
  UID            => $user_id,
  IP             => '127.0.0.1',
  TRANSACTION_ID => "Liqpay:$random_number",
  INFO           => "Test payment",
  PAYSYS_IP      => "127.0.0.1",
  STATUS         => 1,
});

our @requests = (
  {
    name    => 'PAY',
    request => qq/{
  "action":"pay",
	"payment_id": 976121473,
	"status": "success",
	"version": 3,
	"type": "hold",
	"paytype": "privat24",
	"public_key": "i69039701232",
	"acq_id": 414963,
	"order_id": "Liqpay:$random_number",
	"liqpay_order_id": "80QNTUA81552846436143063",
	"description": "PaymentId $random_number, UID $user_id;",
	"sender_phone": "380996506807",
	"sender_card_mask2": "516875*70",
	"sender_card_bank": "pb",
	"sender_card_type": "mc",
	"sender_card_country": 804,
	"amount": 1.00,
	"currency": "UAH",
	"sender_commission": 0.0,
	"receiver_commission": 0.68,
	"agent_commission": 0.0,
	"amount_debit": 24.71,
	"amount_credit": 24.71,
	"commission_debit": 0.0,
	"commission_credit": 0.68,
	"currency_debit": "UAH",
	"currency_credit": "UAH",
	"sender_bonus": 0.0,
	"amount_bonus": 0.0,
	"authcode_debit": "069344",
	"rrn_debit": "001164584057",
	"mpi_eci": "7",
	"is_3ds": false,
	"language": "uk",
	"create_date": 1552846436151,
	"transaction_id": 976121473
}/,
    result  => qq/{
  "result": "ok",
	"action": "pay",
	"payment_id": 976121473,
	"status": "success",
	"version": 3,
	"type": "hold",
	"paytype": "privat24",
	"public_key": "i69039701232",
	"acq_id": 414963,
	"order_id": "Liqpay:$random_number",
	"liqpay_order_id": "80QNTUA81552846436143063",
	"description": "PaymentId $random_number, UID $user_id;",
	"sender_phone": "380996506807",
	"sender_card_mask2": "516875*70",
	"sender_card_bank": "pb",
	"sender_card_type": "mc",
	"sender_card_country": 804,
	"amount": 24.0,
	"currency": "UAH",
	"sender_commission": 0.0,
	"receiver_commission": 0.66,
	"agent_commission": 0.0,
	"amount_debit": 24.0,
	"amount_credit": 24.0,
	"commission_debit": 0.0,
	"commission_credit": 0.66,
	"currency_debit": "UAH",
	"currency_credit": "UAH",
	"sender_bonus": 0.0,
	"amount_bonus": 0.0,
	"authcode_debit": "069344",
	"rrn_debit": "001164584057",
	"mpi_eci": "7",
	"is_3ds": false,
	"language": "uk",
	"create_date": 1552846436151,
	"end_date": 1552846439818,
	"completion_date": 1552846439783,
	"transaction_id": 976121473}
  /
  },
);

my @console_tests = map {{ %$_ }} @requests;
foreach my $request (@console_tests) {
  my $console_request = $request;

  my ($sign, undef, $data) = $Liqpay->cnb_form({}, { JSON => $request->{request} });
  $console_request->{request} = qq{
signature=$sign
data=$data
  };
  $console_request->{get} = 1;
}

test_runner($Liqpay, \@console_tests);

1;
