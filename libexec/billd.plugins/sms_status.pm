=head1 NAME

  billd plugin

=head2  DESCRIBE

  Get sms status from remote server

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Sms::Misc;

BEGIN {
  unshift(@INC, '/usr/abills/Abills/modules');
}

our (
  $debug,
  %conf,
  $Admin,
  $db
);

my $Sms_misc = Sms::Misc->new($db, $Admin, \%conf);
$Sms_misc->sms_status({DEBUG => $debug});

1;
