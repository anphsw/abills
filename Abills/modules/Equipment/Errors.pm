package Equipment::Errors;

=head1 NAME

  Equipment::Errors - returns errors of module Equipment

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1040001 => 'ERR_EQUIPMENT_NAS_NOT_FOUND'
  };
}

1;
