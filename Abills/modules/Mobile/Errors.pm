package Mobile::Errors;

=head1 NAME

  Mobile::Errors - returns errors of module Mobile

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1640001 => 'ERR_MOBILE_SERVICE_ID',
    1640002 => 'ERR_MOBILE_SEVERAL_SERVICES',
    1640003 => 'ERR_MOBILE_UNFILLED_MANDATORY_CATEGORIES',
    1640004 => 'ERR_MOBILE_LIFECELL_API',
    1640005 => 'ERR_MOBILE_EMPTY_BALANCE',
    1640006 => 'ERR_MOBILE_TP_ALREADY_ACTIVATED',
    1640007 => 'ERR_MOBILE_PHONE_NOT_FOUND',
    1640008 => 'ERR_MOBILE_TP_NOT_FOUND',
    1640009 => 'ERR_MOBILE_SERVICES_NOT_FOUND',
    1640010 => 'ERR_MOBILE_PHONE_ALREADY_ACTIVATED',
    1640011 => 'ERR_MOBILE_WAIT_PHONE_NUMBER_ACTIVATION',
    1640012 => 'ERR_MOBILE_WRONG_PARAMETERS',
    1640013 => 'ERR_MOBILE_PHONE_ALREADY_DEACTIVATED',
    1640014 => 'ERR_MOBILE_WAIT_SERVER_RESPONSE',
    1640015 => 'ERR_MOBILE_FUNCTION_NOT_FOUND',
  };
}

1;
