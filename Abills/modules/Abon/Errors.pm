package Abon::Errors;

=head1 NAME

  Abon::Errors - returns errors of module Abon

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1020001 => 'ERR_ABON_WRONG_SIGNATURE',
    1020002 => 'ERR_NO_ABON_SERVICE'
  };
}

1;
