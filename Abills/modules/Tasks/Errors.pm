package Tasks::Errors;

=head1 NAME

  Tasks::Errors - returns errors of module Tasks

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1580001 => 'ERR_TASKS_ACTIVE_SUBTASKS'
  };
}

1;
