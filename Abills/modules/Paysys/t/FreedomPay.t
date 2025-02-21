#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::Plugins::FreedomPay;

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

my $Payment_plugin = Paysys::Plugins::FreedomPay->new($db, $admin, \%conf);
my $Paysys = Paysys->new($db, $admin, \%conf);

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_id = int(rand(10000));
my $transaction_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_date =~ s/[-: ]//g;

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$Paysys->add({
  SYSTEM_ID      => 103,
  SUM            => $payment_sum,
  UID            => $user_id,
  IP             => $ENV{REMOTE_ADDR},
  TRANSACTION_ID => "FRDMPAY:$transaction_id",
  PAYSYS_IP      => $ENV{REMOTE_ADDR},
  STATUS         => 1,
});

my $sig = $Payment_plugin->mk_sign({
  path => 'paysys_check.cgi',
  body => {
    pg_currency                => "KZT",
    pg_reference               => "240821084011",
    pg_need_phone_notification => "1",
    pg_user_contact_email      => "test\@gmail.com",
    pg_card_brand              => "VI",
    pg_card_pan                => "4400-44XX-XXXX-4440",
    pg_result                  => "1",
    pg_description             => "test desc",
    pg_order_id                => "FRDMPAY:$transaction_id",
    pg_payment_id              => "1354120115",
    pg_salt                    => "LVdqpRuWBSUn1YD1",
    pg_card_owner              => "TEST USER",
    pg_need_email_notification => "1",
    pg_testing_mode            => "1",
    pg_net_amount              => "9.71",
    pg_amount                  => "10",
    pg_payment_method          => "bankcard",
    pg_ps_full_amount          => "10",
    pg_ps_amount               => "10",
    pg_ps_currency             => "KZT",
    pg_card_exp                => "12/30",
    pg_can_reject              => "1",
    pg_user_phone              => "380509152725",
    pg_captured                => "1",
    pg_auth_code               => "947724",
    pg_payment_date            => "2024-08-21 13:40:11",
  },
});

our @requests = (
  {
    name    => 'PAY',
    request => qq{
pg_currency=KZT
pg_reference=240821084011
pg_need_phone_notification=1
pg_user_contact_email=test\@gmail.com
pg_card_brand=VI
pg_card_pan=4400-44XX-XXXX-4440
pg_result=1
pg_description=test desc
pg_order_id=FRDMPAY:$transaction_id
pg_payment_id=1354120115
pg_salt=LVdqpRuWBSUn1YD1
pg_card_owner=TEST USER
pg_need_email_notification=1
pg_testing_mode=1
pg_net_amount=9.71
pg_amount=10
pg_payment_method=bankcard
pg_ps_full_amount=10
pg_ps_amount=10
pg_ps_currency=KZT
pg_card_exp=12/30
pg_can_reject=1
pg_user_phone=380509152725
pg_captured=1
pg_auth_code=947724
pg_payment_date=2024-08-21 13:40:11
pg_sig=$sig
},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
