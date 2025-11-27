#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use lib '.';
use lib '../../';
use Paysys::t::Init_t;

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

$payment_sum = int($payment_sum * 100);

our $statements = qq|
{
  "data": [
    {
      "date": "2025-10-02T00:00:00",
      "sum": 90000,
      "payer": {
        "name": "TRK MMM",
        "iin": "222222222222",
        "guid": "f6e3ffd5-abb4-11ef-81a2-0050568154cc"
      },
      "contract": {
        "guid": "055a612e-b91a-11ef-81a2-0050568154cc",
        "name": "Договор 16/157 от 08.11.2024"
      },
      "payment_doc": {
        "guid": "807e0d0c-2fb6-11f0-81a8-0050568154cc",
        "num": "00000003862",
        "date": "2025-10-02T00:00:00",
        "name": "Платежное поручение (входящее) 00000003862 от 12.05.2025 0:00:00"
      }
    },
    {
      "date": "2025-10-02T00:00:00",
      "sum": 30000,
      "payer": {
        "name": "MAX MIN MAR TOP GROUP AIR",
        "iin": "111111111111",
        "guid": "0adcb928-c60c-11ef-81a2-0050568154cc"
      },
      "contract": {
        "guid": "3277e945-c60c-11ef-81a2-0050568154cc",
        "name": "Договор 01/02-405 от 06.12.2024"
      },
      "payment_doc": {
        "guid": "807e0d43-2fb6-11f0-81a8-0050568154cc",
        "num": "00000003863",
        "date": "2025-10-02T00:00:00",
        "name": "Платежное поручение (входящее) 00000003863 от 12.05.2025 0:00:00"
      }
    },
    {
      "date": "2025-10-02T00:00:00",
      "sum": 70000,
      "payer": {
        "name": "Red Cool Stars ТОО",
        "iin": "222222222222",
        "guid": "0fa68111-c284-11ef-81a2-0050568154cc"
      },
      "contract": {
        "guid": "8db0afc8-c284-11ef-81a2-0050568154cc",
        "name": "Договор 17/01/353 от 11.12.2024"
      },
      "payment_doc": {
        "guid": "807e0d8c-2fb6-11f0-81a8-0050568154cc",
        "num": "00000003864",
        "date": "2025-10-02T00:00:00",
        "name": "Платежное поручение (входящее) 00000003864 от 12.05.2025 0:00:00"
      }
    }
    ]
}
|;

1;
