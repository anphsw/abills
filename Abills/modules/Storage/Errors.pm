package Storage::Errors;

=head1 NAME

  Storage::Errors - returns errors of module Storage

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1180001 => 'ERR_STORAGE_QUANTITY_OF_GOODS_IS_INCORRECT',
    1180002 => 'ERR_STORAGE_NO_PERMISSIONS_TO_MANAGE_STORAGE',
  };
}

1;
