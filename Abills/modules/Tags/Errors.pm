package Tags::Errors;

=head1 NAME

  Tags::Errors - returns errors of module Tags

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1570001 => 'ERR_DELETE_TAG_NOT_EXISTS',
    1570002 => 'ERR_DELETE_USER_TAG_NOT_EXISTS',
  };
}

1;
