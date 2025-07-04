package Api::Errors::User_core;
use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1001501 => 'ERR_ACCEPT_RULES_DISABLED',
  };
}

1;
