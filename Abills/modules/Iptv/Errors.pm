package Iptv::Errors;

=head1 NAME

  Iptv::Errors - returns errors of module Iptv

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1080001 => 'ERR_IPTV_DEL_ACTIVATED'
  };
}

1;
