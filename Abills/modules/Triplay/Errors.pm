package Triplay::Errors;

=head1 NAME

  Triplay::Errors - returns errors of module Triplay

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1130001 => 'ERR_TRIPLAY_USER_NOT_ACTIVE',
    1130002 => 'ERR_TRIPLAY_USER_SUBSCRIBE_NOT_FOUND',
  };
}

1;
