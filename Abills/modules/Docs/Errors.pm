package Docs::Errors;

=head1 NAME

  Docs::Errors - returns errors of module Docs

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1054013 => 'ERR_NO_ID_OR_IDS',
    1054014 => 'ERR_NO_PAYMENT',
    1054015 => 'ERR_WRONG_SUM',
    1054016 => 'ERR_INVOICE_ID_AND_CREATE_INVOICE',
    1054017 => 'ERR_NO_INVOICE_ID_AND_CREATE_INVOICE',
    1054018 => 'ERR_NO_NEW_INVOICES_FOR_THIS_PERIOD',
    1054019 => 'ERR_NO_NEW_INVOICES_FOR_THIS_PERIOD',
    1054020 => 'ERR_WRONG_SUM',
    1054021 => 'ERR_NO_UID',
    1054022 => 'ERR_ADD_INVOICE',
  };
}

1;
