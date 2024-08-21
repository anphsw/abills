package Sms::Errors;

=head1 NAME

  Sms::Errors - returns errors of module Sms

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1160001 => 'ERR_PLUGIN',
    1160002 => 'ERR_SERVICE_ID',
  };
}

1;
