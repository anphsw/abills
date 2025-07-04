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
  "operations": [
  {
    "transactionNo": "4$payment_id",
    "counterParty": "AZ72PASX1205000000012345678\\rAZERIQAZ QSC\\r2000123456",
    "counterPartyId": "AZ72PASX1205000000012345678",
    "counterPartyTin": "2000123456",
    "counterPartyName": "AZERIQAZ QSC",
    "amountInAccountCurrency": 98.5,
    "transactionDate": "2025-05-02T00:00:00.000+04:00",
    "transactionType": "CREDIT",
    "sourceSystem": "CURRENT",
    "accountCurrency": "AZN",
    "transactionCurrency": "AZN",
    "amountInTransactionCurrency": 98.5,
    "amountInTransactionCurrencyAzn": 98.5,
    "transactionDescription": "Gas consumption fee for April 2025 as per contract GAZ-APR25",
    "transactionFXRate": 1,
    "afterOperationBalance": 1023.6,
    "afterOperationAvlBalance": 1023.6,
    "openingBalance": 1122.1,
    "openingAvlBalance": 1122.1,
    "closingBalance": 1023.6,
    "closingBalanceAzn": 1023.6,
    "closingAvlBalance": 1023.6,
    "cardNo": null,
    "operationDate": "2025-05-02T08:25:14.000+04:00"
  },
  {
    "transactionNo": "5$payment_id",
    "counterParty": "AZ90UBAZ0000009876543211234\\rKAPITAL BANK ASC\\r1300567890",
    "counterPartyId": "AZ90UBAZ0000009876543211234",
    "counterPartyTin": "1300567890",
    "counterPartyName": "KAPITAL BANK ASC",
    "amountInAccountCurrency": 500,
    "transactionDate": "2025-05-02T00:00:00.000+04:00",
    "transactionType": "DEBIT",
    "sourceSystem": "CURRENT",
    "accountCurrency": "AZN",
    "transactionCurrency": "AZN",
    "amountInTransactionCurrency": 500,
    "amountInTransactionCurrencyAzn": 500,
    "transactionDescription": "Incoming funds transfer from Kapital Bank for salary payment as per April payroll",
    "transactionFXRate": 1,
    "afterOperationBalance": 1523.6,
    "afterOperationAvlBalance": 1523.6,
    "openingBalance": 1023.6,
    "openingAvlBalance": 1023.6,
    "closingBalance": 1523.6,
    "closingBalanceAzn": 1523.6,
    "closingAvlBalance": 1523.6,
    "cardNo": null,
    "operationDate": "2025-05-02T09:42:09.000+04:00"
  },
  {
    "transactionNo": "6$payment_id",
    "counterParty": "AZ50XALX4407000000567890123\\rAZERCELL TELEKOM MMC\\r2100345678",
    "counterPartyId": "AZ50XALX4407000000567890123",
    "counterPartyTin": "2100345678",
    "counterPartyName": "AZERCELL TELEKOM MMC",
    "amountInAccountCurrency": 23.95,
    "transactionDate": "2025-05-02T00:00:00.000+04:00",
    "transactionType": "CREDIT",
    "sourceSystem": "CURRENT",
    "accountCurrency": "AZN",
    "transactionCurrency": "AZN",
    "amountInTransactionCurrency": 23.95,
    "amountInTransactionCurrencyAzn": 23.95,
    "transactionDescription": "Mobile service subscription fee for May 2025 (Invoice AC-555892)",
    "transactionFXRate": 1,
    "afterOperationBalance": 1499.65,
    "afterOperationAvlBalance": 1499.65,
    "openingBalance": 1523.6,
    "openingAvlBalance": 1523.6,
    "closingBalance": 1499.65,
    "closingBalanceAzn": 1499.65,
    "closingAvlBalance": 1499.65,
    "cardNo": null,
    "operationDate": "2025-05-02T10:12:38.000+04:00"
  }
],
  "openingBalance": 1500.5,
  "closingBalance": 1000.1,
  "availableOpeningBalance": 1500.5,
  "availableClosingBalance": 1000.1,
  "closingBalanceAzn": 1500.5,
  "paginationMetaData": {
    "totalPages": 1,
    "currentPage": 1,
    "hasNextPage": false,
    "hasPreviousPage": false
  },
  "message": null
}
|;

1;
