package Paysys::Constants;
=head1 NAME

  Paysys::Constants - values that have to be equal all over modules using Paysys

=head2 SYNOPSIS

  This package aggregates global values of Paysys module uses

=cut


use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

#TODO migrate to modern Const::Fast or Readonly but its already not the best way
use constant {
  PROCESS_STATUSES => {
    SUCCESS                                 => 0,
    USER_NOT_EXISTS                         => 1,
    DATABASE_ERROR                          => 2,
    DUPLICATE_PAYMENT_NO_TRANSACTION        => 3,
    SUM_NOT_VALID                           => 5,
    SUM_TOO_SMALL                           => 6,
    SUM_TOO_BIG                             => 7,
    PAYMENT_NOT_EXISTS                      => 8,
    PAYMENT_EXISTS                          => 9,
    PAYMENT_NOT_FOUND                       => 10,
    PAYMENTS_NOT_ALLOW_TO_GROUP             => 11,
    DATABASE_DEADLOCK                       => 12,
    DUPLICATE_TRANSACTION                   => 13,
    USER_NO_BILL_ID                         => 14,
    TRANSACTION_CREATED_UNPAID_AND_CANCELED => 15,
    SQL_ERROR                               => 17,
    NO_EXT_ID_AND_PAYSYS_ID                 => 21,
    WRONG_EXCHANGE                          => 28,
    USER_EMPTY_IDENTIFIER                   => 30,
    WRONG_SIGNATURE                         => 35,
    USER_DUPLICATE_IDENTIFIER               => 40,
  }
};

our @EXPORT = qw/PROCESS_STATUSES/;

our @EXPORT_OK = qw/PROCESS_STATUSES/;

1;
