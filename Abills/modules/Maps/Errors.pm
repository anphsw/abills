package Maps::Errors;

=head1 NAME

  Maps::Errors - returns errors of module Maps

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1380001 => 'ERR_MAPS_WRONG_COORDINATES'
  };
}

1;
