#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Internet_Plategka;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Internet_Plategka->new($db, $admin, \%conf);
$user_id    = $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || 'test';

if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

our @requests = (
 {
    name    => 'CHECK',
    request => qq{
md5=12eb47e964c95003c7364f88f5dc12e6
time_p=1591588711
acc=1173},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'PAYMENT',
    request => qq{
sum=1000.00
acc=1161
time_p=1630058923
md5=9f47ff71ae92836e1a9a83b631ff974c
id_p=106},
    get     => 1,
    result  => qq{}
  },
  {
    name    => 'COMMIT_PAY',
    request => qq{
id_v=115
md5=9f47ff71ae92836e1a9a83b631ff974c
time_p=1630059104},
    get     => 1,
    result  => qq{}
  },
);

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

