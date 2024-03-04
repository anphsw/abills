#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';

use_ok('Crypt::JWT', qw(encode_jwt decode_jwt));
use_ok('Abills::Base', qw/json_former/);
use_ok('Paysys::t::Init_t');

use Paysys::t::Init_t;
use Abills::Base qw(json_former);
require Paysys::systems::Pumb;

my $public_key = Paysys::systems::Pumb::_load_pem_file('public_pumb.pem');
cmp_ok($public_key, 'ne', '', 'Check is present public key public_pumb.pem');

my $private_key = Paysys::systems::Pumb::_load_pem_file('private.pem');
cmp_ok($private_key, 'ne', '', 'Check is present private key private.pem');

use Crypt::JWT qw(encode_jwt);

our (
  %conf,
  $db,
  $admin,
  $debug,
  $user_id,
  $payment_sum,
  $payment_id,
  $argv,
  $base_dir,
  $DATE
);

# for test swap to local public key

my $Payment_plugin = Paysys::systems::Pumb->new($db, $admin, \%conf);
if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$payment_sum = $payment_sum * 100;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';

my @request_bodies = (
  {
    request => 'CHECK',
    body    => {
      fields => [
        {
          alias => 'CLIENT_ID',
          value => "$user_id"
        },
      ],
    },
  },
  {
    request => 'CONFIRM',
    body    => {
      payer_id     => "$user_id",
      amount       => $payment_sum,
      payment_id   => "$payment_id",
      service_code => $conf{PAYSYS_PUMB_SERVICE_CODE},
    },
  },
  {
    request => 'STATUS',
    body    => {},
  },
  {
    request => 'REPORT',
    body    => {
      id           => $payment_id,
      date         => $DATE,
      service_code => $conf{PAYSYS_PUMB_SERVICE_CODE},
      payments     => [
        {
          amount       => $payment_sum,
          payer_id     => "$user_id",
          id           => "$payment_id",
          service_code => $conf{PAYSYS_PUMB_SERVICE_CODE},
        },
      ]
    },
  },
  {
    request => 'CHECK_USER_NOT_EXISTS',
    body    => {
      fields => [
        {
          alias => 'CLIENT_ID',
          value => "1111111111$user_id"
        },
      ],
    },
  },
  {
    request => 'PAY_USER_NOT_EXISTS',
    body    => {
      payer_id     => "1111111111$user_id",
      amount       => $payment_sum,
      payment_id   => "$payment_id",
      service_code => $conf{PAYSYS_PUMB_SERVICE_CODE},
    },
  },
  {
    request => 'STATUS_NO_PAYMENT',
    body    => {
      payer_id     => "$user_id",
      amount       => $payment_sum,
      payment_id   => "$payment_id",
      service_code => $conf{PAYSYS_PUMB_SERVICE_CODE},
    },
  },
);

foreach my $request (@request_bodies) {
  my ($sign, $payload) = $Payment_plugin->mk_sign($request->{body});

  $request->{json} = json_former($request->{body});
  $request->{signature} = $sign;
  $request->{payload} = $payload;
}

our @requests = (
  # check payment
  {
    name      => 'CHECK',
    path      => '/check',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[0]->{signature}"
    ],
    request   => qq/$request_bodies[0]->{payload}/,
    signature => $request_bodies[0]->{signature}
  },
  # make payment
  {
    name      => 'CONFIRM',
    path      => '/confirm',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[1]->{signature}"
    ],
    request   => qq/$request_bodies[1]->{payload}/,
    signature => $request_bodies[1]->{signature}
  },
  # get status of payment
  {
    name    => 'STATUS',
    path    => '/status',
    get     => 1,
    request => qq/payment_id=$payment_id/,
  },
  # check answer on not valid path
  {
    name      => 'NOT_VALID_PATH',
    path      => '/report',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[3]->{signature}"
    ],
    request   => qq/$request_bodies[3]->{payload}/,
    signature => $request_bodies[3]->{signature}
  },
  # check answer on not valid path
  {
    name      => 'NOT_VALID_PATH',
    path      => '/not_valid',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[0]->{signature}"
    ],
    request   => qq/$request_bodies[0]->{payload}/,
    signature => $request_bodies[0]->{signature}
  },
  # check signature verifications
  {
    name    => 'NOT_VALID_SIGNATURE',
    path    => '/check',
    headers => [
      'Content-Type: application/json',
      "x-jws-signature: eyJmaWVsZHMiOlt7ImFsaWFz..IjoiQ0xJRU5UX0lEIiwidmFsdWUiOiJ0ZXN0In1dLCJpYXQiOjE2MDM3MDI5ODF9"
    ],
    request => qq/
{
 "payload": "eyJmaWVsZHMiOlt7ImFsaWFzIjoiQ0xJRU5UX0lEIiwidmFsdWUiOiJ0ZXN0In1dLCJpYXQiOjE2MDM3MDI5ODF9"
}
/,
  },
  # not valid user
  {
    name    => 'CHECK_USER_NOT_EXISTS',
    path    => '/check',
    headers => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[4]->{signature}"
    ],
    request => qq/$request_bodies[4]->{payload}/,
  },
  # not valid user
  {
    name      => 'CONFIRM_USER_NOT_EXISTS',
    path      => '/confirm',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[5]->{signature}"
    ],
    request   => qq/$request_bodies[5]->{payload}/,
    signature => $request_bodies[5]->{signature}
  },
  # not valid payment
  {
    name    => 'STATUS_NO_PAYMENT',
    path    => '/status',
    get     => 1,
    request => qq/payment_id=111111111111$payment_id/,
  },
  # json check payment
  {
    name      => 'CHECK',
    path      => '/check',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[0]->{signature}"
    ],
    request   => qq/$request_bodies[0]->{json}/,
    signature => $request_bodies[0]->{signature},
  },
  # json make payment
  {
    name      => 'CONFIRM',
    path      => '/confirm',
    headers   => [
      'Content-Type: application/json',
      "x-jws-signature: $request_bodies[1]->{signature}"
    ],
    request   => qq/$request_bodies[1]->{json}/,
    signature => $request_bodies[1]->{signature}
  },
);

test_runner($Payment_plugin, \@requests);

done_testing();

1;
