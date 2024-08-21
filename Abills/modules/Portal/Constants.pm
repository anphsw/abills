package Portal::Constants;
=head1 NAME

  Docs::Constants - values that have to be equal all over modules using Docs

=head2 SYNOPSIS

  This package aggregates global values of Docs module uses

=cut

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use constant {
  ALLOWED_METHODS => [5, 6, 10]
};

our @EXPORT = qw/
  ALLOWED_METHODS
/;

1;
