#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::Plugins::Kassa24;

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

my $Payment_plugin = Paysys::Plugins::Kassa24->new($db, $admin, \%conf);

$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $transaction_id = 100000 + int(rand(10000));

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

our @requests = (
  {
    name    => 'CHECK',
    request => qq{
action=check
number=$user_id},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAY',
    request => qq{
action=payment
number=$user_id
date=2024-08-03T15:53:00
receipt=$transaction_id
amount=$payment_sum},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;
