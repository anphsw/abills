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
      "fullName": "Іваненко Іван Іванович",
      "fullAddress": "м. Київ, вул. Шевченка, буд. 10, корп. 2, кв. 45",
      "city": "Київ",
      "street": "Шевченка",
      "house": "10",
      "building": "2",
      "apartment": "45",
      "account": "$user_id",
      "monthDebt": 500.75,
      "fullDebt": 1500.50,
      "paymentAmount": 500.75,
      "metr": {}
    },
    {
      "fullName": "Петренко Марія Петрівна",
      "fullAddress": "м. Львів, вул. Франка, буд. 15, кв. 12",
      "city": "Львів",
      "street": "Франка",
      "house": "15",
      "building": "",
      "apartment": "12",
      "account": "0987654321",
      "monthDebt": 300.50,
      "fullDebt": 1200.75,
      "paymentAmount": 300.50,
      "metr": {}
    },
    {
      "fullName": "Сидоренко Олександр Михайлович",
      "fullAddress": "м. Одеса, вул. Дерибасівська, буд. 20, кв. 5",
      "city": "Одеса",
      "street": "Дерибасівська",
      "house": "20",
      "building": "",
      "apartment": "5",
      "account": "1111111",
      "monthDebt": 450.00,
      "fullDebt": 900.00,
      "paymentAmount": 450.00,
      "metr": {}
    }
  ]
}
|;

1;
