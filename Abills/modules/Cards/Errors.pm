package Cards::Errors;
use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1060001 => 'ERR_OPERATION_NOT_ALLOWED',
    1060002 => 'ERR_NO_FIELD',
    1060003 => 'ERR_NO_FIELD',
    1060004 => 'ERR_PIN_BRUTE_LIMIT',
    1060005 => 'ERR_UNKNOWN_CARD',
    1060006 => 'ERR_UNKNOWN_ERROR',
    1060007 => 'ERR_CARD_EXPIRE',
    1060008 => 'ERR_UNKNOWN_CARD',
    1060009 => 'ERR_OPERATION_NOT_ALLOWED',
    1060010 => 'ERR_CARD_SUM',
    1060011 => 'ERR_CARD_USED_BEFORE',
    1060012 => 'ERR_CARD_STATUS',
    1060013 => 'ERR_CARD_USED',
    1060014 => 'ERR_UNKNOWN_ERROR',
    1060015 => 'ERR_CARD_USED',
    1060016 => 'ERR_CARD_PAYMENT',
  };
}

1;
