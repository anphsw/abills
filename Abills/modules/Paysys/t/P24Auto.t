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
  $argv,
  $DATE
);

$payment_sum = int($payment_sum * 100);

$DATE =~ /(\d+)-(\d+)-(\d+)/;

our $statements = qq|
{
  "status": "SUCCESS",
  "type": "transactions",
  "exist_next_page": false,
  "next_page_id": "4193435490_online",
  "transactions": [
    {
      "AUT_CNTR_ACC": "UA111152990000011111866100110",
      "AUT_CNTR_CRF": 143605712,
      "AUT_CNTR_MFO": 305299,
      "AUT_CNTR_MFO_NAME": "АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_CNTR_NAM": "ZR_Транз.счет платежи bp 3414657",
      "AUT_MY_ACC": "UA111152990000011111866100110",
      "AUT_MY_CRF": 36105639,
      "AUT_MY_MFO": 311744,
      "AUT_MY_MFO_NAME": "КОСМІЧНЕ АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_MY_NAM": "ABillS, ТОВ",
      "CCY": "UAH",
      "DAT_KL": "$3.$2.$1",
      "DAT_OD": "$3.$2.$1",
      "DOC_TYP": "m",
      "FL_DC": "C",
      "FL_REAL": "r",
      "NUM_DOC": "2PL530039",
      "OSND": "Плата за інтернет, о/р 103078, Петренко Петро Володимирович",
      "PR_PR": "r",
      "REF": "D2P1$payment_id",
      "REFN": "P",
      "SUM": 1,
      "SUM_E": 100,
      "TIM_P": "06:46",
      "DATE_TIME_DAT_OD_TIM_P": "$3.$2.$1 06:46:00",
      "ID": 1377885891,
      "TECHNICAL_TRANSACTION_ID": "1377885891_online",
      "TRANTYPE": "C"
    },
    {
      "AUT_CNTR_ACC": "UA111152990000011111866100110",
      "AUT_CNTR_CRF": 14360572,
      "AUT_CNTR_MFO": 305299,
      "AUT_CNTR_MFO_NAME": "АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_CNTR_NAM": "АТ \\\"А-БАНК\\\"",
      "AUT_MY_ACC": "UA111152990000011111866100110",
      "AUT_MY_CRF": 36105639,
      "AUT_MY_MFO": 311744,
      "AUT_MY_MFO_NAME": "КОСМІЧНЕ АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_MY_NAM": "ABillS, ТОВ",
      "CCY": "UAH",
      "DAT_KL": "$3.$2.$1",
      "DAT_OD": "$3.$2.$1",
      "DOC_TYP": "m",
      "FL_DC": "C",
      "FL_REAL": "r",
      "NUM_DOC": "2PL530039",
      "OSND": "Плата за інтернет, о/р 103079, Петренко Петро Володимирович",
      "PR_PR": "r",
      "REF": "D2P2$payment_id",
      "REFN": "P",
      "SUM": 1,
      "SUM_E": 100,
      "TIM_P": "06:46",
      "DATE_TIME_DAT_OD_TIM_P": "$3.$2.$1 06:46:00",
      "ID": 1377885891,
      "TECHNICAL_TRANSACTION_ID": "1377885891_online",
      "TRANTYPE": "C"
    },
    {
      "AUT_CNTR_ACC": "UA111152990000011111866100110",
      "AUT_CNTR_CRF": 14360573,
      "AUT_CNTR_MFO": 305299,
      "AUT_CNTR_MFO_NAME": "АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_CNTR_NAM": "АТ ABillS",
      "AUT_MY_ACC": "UA111152990000011111866100110",
      "AUT_MY_CRF": 36105639,
      "AUT_MY_MFO": 311744,
      "AUT_MY_MFO_NAME": "КОСМІЧНЕ АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_MY_NAM": "ABillS, ТОВ",
      "CCY": "UAH",
      "DAT_KL": "$3.$2.$1",
      "DAT_OD": "$3.$2.$1",
      "DOC_TYP": "m",
      "FL_DC": "C",
      "FL_REAL": "r",
      "NUM_DOC": "2PL530039",
      "OSND": "LIQPAY ID 2434220672 SOID Liqpay:268661943 PBK i9011111183 DATE 2024-03-06 TYPE acquiring",
      "PR_PR": "r",
      "REF": "D2P3$payment_id",
      "REFN": "P",
      "SUM": 1,
      "SUM_E": 100,
      "TIM_P": "06:46",
      "DATE_TIME_DAT_OD_TIM_P": "$3.$2.$1 06:46:00",
      "ID": 1377885891,
      "TECHNICAL_TRANSACTION_ID": "1377885891_online",
      "TRANTYPE": "C"
    },
    {
      "AUT_CNTR_ACC": "UA111152990000011111866100110",
      "AUT_CNTR_CRF": 1436057411,
      "AUT_CNTR_MFO": 305299,
      "AUT_CNTR_MFO_NAME": "АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_CNTR_NAM": "АТ PUMB",
      "AUT_MY_ACC": "UA111152990000011111866100110",
      "AUT_MY_CRF": 36105639,
      "AUT_MY_MFO": 311744,
      "AUT_MY_MFO_NAME": "КОСМІЧНЕ АТ КБ \\\"ПРИВАТБАНК\\\"",
      "AUT_MY_NAM": "ABillS, ТОВ",
      "CCY": "UAH",
      "DAT_KL": "$3.$2.$1",
      "DAT_OD": "$3.$2.$1",
      "DOC_TYP": "m",
      "FL_DC": "C",
      "FL_REAL": "r",
      "NUM_DOC": "2PL530039",
      "OSND": "Плата за інтернет, о/р 103079, Петренко Петро Володимирович, ID: 1111111",
      "PR_PR": "r",
      "REF": "D2P4$payment_id",
      "REFN": "P",
      "SUM": 1,
      "SUM_E": 100,
      "TIM_P": "06:46",
      "DATE_TIME_DAT_OD_TIM_P": "$3.$2.$1 06:46:00",
      "ID": 1377885891,
      "TECHNICAL_TRANSACTION_ID": "1377885891_online",
      "TRANTYPE": "C"
    }
  ]
}
|;

1;
