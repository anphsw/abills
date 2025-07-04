#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
  use FindBin '$Bin';
  our $libpath = $Bin . '/../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}

require_ok( 'Internet::Users' );
require_ok( 'Internet::Base' );
require_ok( 'Internet::Periodic' );
require_ok( 'Internet::User_portal' );
require_ok( 'Internet::Reports');
require_ok( 'Internet::Api' );
require_ok( 'Internet::Errors' );
require_ok( 'Internet::Configure' );
require_ok( 'Internet::Monitoring' );
require_ok( 'Internet::Services' );
require_ok( 'Internet::Service_mng' );
require_ok( 'Internet::Stats' );
require_ok( 'Internet::Ipoe_mng' );




1;