package Internet::Errors;

=head1 NAME

  Internet::Errors - returns errors of module Internet

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1360001 => 'ERR_NO_FIELD', # uid
    1360002 => 'ERR_NO_FIELD', # id
    1360003 => 'ERR_NO_FIELD', # tpId
    1360004 => 'ERR_ACCESS_DENY',
    1360005 => 'ERR_ACCESS_DENY',
    1360006 => 'USER_NOT_EXIST',
    1360007 => 'USER_NOT_EXIST',
    1360007 => 'USER_NOT_EXIST',
    1360008 => 'ERR_TARIFF_EXISTS',
    1360009 => 'ERR_NO_FIELD', # date
    1360010 => 'ERR_WRONG_DATE',
    1360011 => 'ERR_WRONG_DATE',
    1360012 => 'ERR_WRONG_DATE',
    1360013 => 'ERR_FAILED_SET_SCHEDULE',
    1360014 => 'ERR_CHANGE_TP',
    1360015 => 'ERR_NO_TARIFF',
  };
}

1;
