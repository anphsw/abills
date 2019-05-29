#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS,);

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}

require "libexec/config.pl";
$conf{language} = 'english';
do "language/$conf{language}.pl";
do "/usr/abills/Abills/modules/Paysys/lng_$conf{language}.pl";
my $begin_time = Abills::Base::check_time();

Test::More::use_ok('Paysys');
Test::More::use_ok('Paysys::systems::Liqpay');
Test::More::use_ok('Conf');
Test::More::use_ok('Abills::Base', qw/mk_unique_value /);
use Abills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);

my $Paysys = Paysys->new($db, $admin, \%conf);

my $argv = Abills::Base::parse_arguments( \@ARGV );

my $user_id = $argv->{UID} || '1';
my $random_number = int(rand(100000));

my $Liqpay = Paysys::systems::Liqpay->new($db, $admin, \%conf, {
    CUSTOM_NAME => $argv->{CUSTOM_NAME} || '',
    CUSTOM_ID   => $argv->{CUSTOM_ID}   || '',
  });

if($argv->{HOTSPOT} == 1){
  $user_id = $random_number;
}

$Paysys->add(
  {
    SYSTEM_ID      => 62,
    SUM            => 1.00,
    UID            => $user_id,
    IP             => '127.0.0.1',
    TRANSACTION_ID => "Liqpay:$random_number",
    INFO           => "Test payment",
    PAYSYS_IP      => "127.0.0.1",
    STATUS         => 1,
  }
);

my %hold_wait_hash = (data => qq/{
	"action": "hold",
	"payment_id": 976121473,
	"status": "hold_wait",
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
	"language": "ru",
	"create_date": 1552846436151,
	"transaction_id": 976121473
}/);


$hold_wait_hash{TEST_COMPLETE} = qq/{
	"result": "ok",
	"action": "hold",
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
	"language": "ru",
	"create_date": 1552846436151,
	"end_date": 1552846439818,
	"completion_date": 1552846439783,
	"transaction_id": 976121473
}/;

$hold_wait_hash{data} = Abills::Base::encode_base64($hold_wait_hash{data});
$Liqpay->proccess(\%hold_wait_hash);

print "\nTest time: " . Abills::Base::gen_time($begin_time) . "\n\n";