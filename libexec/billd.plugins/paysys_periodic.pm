#**********************************************************
=head1 NAME

  Standart execute
    /usr/abills/libexec/billd paysys_periodic

=head1 HELP

  DATE
  DATE_FROM
  DATE_TO
  DEBUG

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

push @INC, $Bin.'/../', $Bin.'/../Abills/';

our (
  $db,
  $Admin,
  %conf,
  %lang,
  $argv,
  $base_dir,
  $debug
);

require Abills::Misc;
our $html = Abills::HTML->new( { CONF => \%conf } );
our $admin = $Admin;
do $base_dir . "/language/$conf{default_language}.pl";

load_module('Paysys', $html, { LANG_ONLY => 1 });
require Paysys::Periodic;

_log('LOG_DEBUG', "Billd plugin for paysys periodic starting");

paysys_periodic_new({
  DEBUG => $debug,
  DATE  => $DATE,
  %$argv
});

_log('LOG_DEBUG', "Billd plugin for paysys periodic stopped");

1;