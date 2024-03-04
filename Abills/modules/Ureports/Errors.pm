package Ureports::Errors;
=head1 NAME

  Ureports::Errors - returns errors of module Ureports

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1210001 => 'ERR_TPID_MISSING',
    1210002 => 'ERR_DEST_MISSING',
    1210003 => 'ERR_DEST_NOT_ARRAY',
    1210004 => 'ERR_USER_INFO_EXISTS',
    1210005 => 'ERR_DEST_NOT_ARRAY',
    1210006 => 'ERR_USER_NOT_FOUND',
    1210007 => 'ERR_NO_REPORT_SERVICE',
    1210008 => 'ERR_REPORTS_MISSING',
    1210009 => 'ERR_REPORTS_NOT_ARRAY',
    1210010 => 'ERR_NO_REPORT_SERVICE',
    1210011 => 'ERR_NO_REPORTS_ADDED',
    1210012 => 'ERR_NO_REPORTS_FOR_USER',
    1210013 => 'ERR_NO_REPORT_WITH_ID',
  };
}

1;
