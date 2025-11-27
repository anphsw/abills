#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

require Paysys::Plugins::Kaspi;

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

my $Payment_plugin = Paysys::Plugins::Kaspi->new($db, $admin, \%conf);
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_date = POSIX::strftime('%Y-%m-%d %H:%M:%S', localtime());
$transaction_date =~ s/[-: ]//g;

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

my $date = $main::DATE;
$date =~ s/\d+$|-//g;

our @requests = (
  {
    name          => 'CHECK',
    request       => {
      account => {
        name    => 'account',
        val     => $user_id,
        tooltip => "Идентификатор абонента в зависимости от настроек системы. (По умолчанию вводить UID абонента)",
      },
      command => {
        name      => 'command',
        val       => 'check',
        ex_params => 'readonly="readonly"',
      },
      sum     => {
        name    => 'sum',
        val     => $payment_sum,
        tooltip => 'Сумма платежа',
      },
      txn_id  => {
        name    => 'txn_id',
        val     => $payment_id,
        tooltip => 'Transaction ID(случайный номер)',
      },
    },
    query_params  => 1,
    result_schema => 'Kaspi/check-response.json',
    result_type   => 'json',
  },
  {
    name          => 'PAY',
    request       => {
      command => {
        name      => 'command',
        val       => 'pay',
        ex_params => 'readonly="readonly"',
      },
      account => {
        name    => 'account',
        val     => $user_id,
        tooltip => "Идентификатор абонента в зависимости от настроек системы.(По умолчанию вводить UID абонента)",
      },
      sum     => {
        name    => 'sum',
        val     => $payment_sum,
        tooltip => 'Сумма платежа',
      },
      txn_id  => {
        name    => 'txn_id',
        val     => $payment_id,
        tooltip => 'Transaction ID(случайный номер)',
      },
    },
    query_params  => 1,
    result_schema => 'Kaspi/pay-response.json',
    result_type   => 'json',
  },
  {
    name          => 'USER_LIST',
    request       => {
      date => {
        name => 'date',
        val  => $date,
      },
      page => {
        name    => 'page',
        val     => '1',
        tooltip => "Номер страницы",
      },
      rows => {
        name    => 'rows',
        val     => '100',
        tooltip => 'Количество лицевых счетов на странице',
      },
    },
    query_params  => 1,
    result_schema => 'Kaspi/user-push-list.json',
    result_type   => 'json',
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'json_compare' });

1;

