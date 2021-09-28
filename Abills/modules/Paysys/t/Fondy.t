#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
require Paysys::systems::Fondy;

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id
);

my $Payment_plugin = Paysys::systems::Fondy->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG}=7;
}

$payment_sum *= 100;
my $sign_string = '';

$sign_string .= $payment_sum . '|' . 'UAH' .  '|' . $user_id . '|' . '25478' . '|' . $payment_id . '|' . 'approved' . '|' . '21.12.2014 11:21:30' . '|';
my $signature = ''; #$Payment_plugin->mk_sign($sign_string);

our @requests = ({
    name    => 'PAY',
    request => qq{amount=$payment_sum
currency=UAH
merchant_id=25478
order_id=$payment_id
signature=$signature
merchant_data=$user_id
order_status=approved
order_time=21.12.2014 11:21:30
},
    get     => 1,
    result  => qq{}
});

#rectoken=da39a3ee5e6b4b0d3255bfef95601890afd80709 use if need

test_runner($Payment_plugin, \@requests, { VALIDATE => 'xml_compare' });

1;

