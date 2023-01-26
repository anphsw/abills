package Voip::Constants;
=head1 NAME

  Voip::Constants - values that have to be equal all over modules using Voip

=head2 SYNOPSIS

  This package aggregates global values of Voip module uses

=cut


use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use constant {
  TRUNK_PROTOCOLS => [
    'SIP',
    'IAX2',
    'ZAP',
    'H323',
    'local',
  ],
};

our @EXPORT = qw/
  TRUNK_PROTOCOLS
/;

1;
