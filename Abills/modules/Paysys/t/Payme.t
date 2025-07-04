#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;
use Abills::Base qw(encode_base64);

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
  require Paysys::Plugins::Payme;
  $Payment_plugin = Paysys::Plugins::Payme->new($db, $admin, \%conf);
}
else {
  require Paysys::Plugins::Payme;
  $Payment_plugin = Paysys::Plugins::Payme->new($db, $admin, \%conf);
}

if ($debug > 3) {
  $Payment_plugin->{DEBUG} = 7;
}

$payment_id = int(rand(10000)) + 100000;
$payment_sum = $payment_sum * 100;
$user_id = $argv->{user} || $Payment_plugin->{conf}->{PAYSYS_TEST_USER} || '';
my $timestamp = time * 1000;
my $transaction_start_date = (time - 86400 * 3) * 1000;

$ENV{HTTP_CGI_AUTHORIZATION} = "basic " . encode_base64("$conf{PAYSYS_PAYME_LOGIN}:$conf{PAYSYS_PAYME_PASSWD}");

our @requests = (
  {
    name     => 'CHECK_USER',
    request  => qq/
{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "CheckPerformTransaction",
    "params": {
        "amount": $payment_sum,
        "account": {
            "login": "$user_id"
        }
    }
}
/,
    response => qq/
{
  "result": {
    "allow": true
  }
}
/
  },
  {
    name     => 'CREATE_TRANSACTION',
    request  => qq/
{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "CreateTransaction",
    "params": {
        "account": {
            "login": "$user_id"
        },
        "amount": $payment_sum,
        "id": "$payment_id",
        "time": $timestamp
    }
}
/,
    response => qq/
{
  "result": {
    "create_time": 1654711355000,
    "state": 1,
    "transaction": "1914"
  }
}
/,
  },
  {
    name     => 'CONFIRM_TRANSACTION',
    request  => qq/
{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "PerformTransaction",
    "params": {
        "id": "$payment_id"
    }
}
/,
    response => qq/
{
  "result": {
    "perform_time": 1654711355000,
    "state": 1,
    "transaction": "1914"
  }
}
/,
  },
  {
    name     => 'CANCEL_TRANSACTION',
    request  => qq/
{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "CancelTransaction",
    "params": {
        "id": "$payment_id",
        "reason": 5
    }
}
/,
    response => qq/
{
  "result": {
    "cancel_time": 1654711365000,
    "state": -1,
    "transaction": "1914"
  }
}
/,
  },
  {
    name     => 'CHECK_TRANSACTION',
    request  => qq/
{
    "jsonrpc": "2.0",
    "id": 5,
    "method": "CheckTransaction",
    "params": {
        "id": "$payment_id"
    }
}
/,
    response => qq/
{
  "result": {
    "cancel_time": 0,
    "create_time": 1654710241000,
    "perform_time": 0,
    "reason": null,
    "state": 1,
    "transaction": "1909"
  }
}
/,
  },
  {
    name     => 'GET_PAYMENTS',
    request  => qq/
{
    "method" : "GetStatement",
    "params" : {
        "from" : $transaction_start_date,
        "to" : $timestamp
    }
}
/,
    response => qq/
{
  "result": {
    "transaction": [
      {
        "account": {
          "login": "M-201211-067"
        },
        "amount": 10,
        "cancel_time": 1654686769000,
        "create_time": 1654686759000,
        "id": 1900,
        "perform_time": 0,
        "state": 15,
        "time": "2022-06-08 14:12:39",
        "transaction": "Payme:10000"
      },
    ]
  }
}
/,
  }
);

test_runner($Payment_plugin, \@requests);

1;
