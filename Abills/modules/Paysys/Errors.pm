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
    1170001 => 'ERR_NO_FAST_PAY_LINK',
    1170002 => 'PAYMENT_SYSTEM_NOT_CONFIGURED',
    1170003 => 'ERR_PAYSYS_DOMAIN',
    1170004 => 'ERR_WRONG_CONFIGURATIONS',
    1170005 => 'ERR_WRONG_CONFIGURATIONS',
  };
}

1;
