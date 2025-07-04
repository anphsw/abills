package Paysys::Errors;

=head1 NAME

  Paysys::Errors - returns errors of module Paysys

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    # Plugin errors
    1170001 => 'ERR_NO_FAST_PAY_LINK',
    1170002 => 'PAYMENT_SYSTEM_NOT_CONFIGURED',
    1170003 => 'ERR_PAYSYS_DOMAIN',
    1170004 => 'ERR_WRONG_CONFIGURATIONS',
    1170005 => 'ERR_WRONG_CONFIGURATIONS',
    1170006 => 'ERR_CREATE_PAY_URL',
    1170007 => 'ERR_NO_CALLBACK_URL',

    # Api
    1170101 => 'ERR_TRANSACTION_NOT_EXISTS',
    1170102 => 'ERR_NO_FIELD',
    1170103 => 'ERR_PAYMENT_SYSTEM_NOT_EXISTS',
    1170104 => 'ERR_NO_FAST_PAY_LINK',
    1170105 => 'NO_ACTIVE_RECURRENT_PAYMENTS',
    1170106 => 'NO_ACTIVE_RECURRENT_PAYMENTS',
    1170107 => 'ERR_PAYMENT_SYSTEM_NOT_EXISTS',
    1170108 => 'ERROR_UNSUBSCRIBE',
    1170109 => 'ERR_NOW_ALLOWED_PAYMENT_SYSTEM',
    1170110 => 'ERR_DUPLICATE_TRANSACTION_ID',
  };
}

1;
