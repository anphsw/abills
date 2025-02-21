=head1 NAME

  Equipment API test

=cut

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use FindBin qw($RealBin);
use JSON;

BEGIN {
  our $libpath = $Bin . '/../../../../';
  require "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Defs;
use Abills::Api::Tests::Init qw(test_runner folder_list help);
use Abills::Base qw(parse_arguments);
use Admins;

our (
  %conf
);

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $ARGV
}, \@test_list);

done_testing();

1;
