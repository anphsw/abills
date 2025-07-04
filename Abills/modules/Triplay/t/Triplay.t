#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 7;

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


require_ok( 'Triplay::Users' );
require_ok( 'Triplay::Base' );
require_ok( 'Triplay::Periodic' );
require_ok( 'Triplay::User_portal' );
require_ok( 'Triplay::Api' );
require_ok( 'Triplay::Errors' );
require_ok( 'Triplay::Services' );

1;