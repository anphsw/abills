package Abills::Api::Helpers;

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  static_string_generate
);

our @EXPORT_OK = qw(
  static_string_generate
);

#**********************************************************
=head2 static_string_generate($string, $integer)

=cut
#**********************************************************
sub static_string_generate {
  my ($string, $integer) = @_;

  return length($string) * 21 * $integer;
}

1;
