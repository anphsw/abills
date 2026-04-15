=head1 NAME

  Storage API test

=cut
use strict;
use warnings;

use Test::More;
use FindBin '$Bin';

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
use Storage;

our (
  %conf,
);

my ($db, $admin) = db_connect();


my $argv = parse_arguments(\@ARGV);

if ($argv->{help}) {
  help();
  exit 0;
}

my $Storage = Storage->new($db, $admin, \%conf);

my $apiKey = $argv->{KEY} || q{};
my $debug = $argv->{DEBUG} || 0;

if ($debug > 6) {
  $Storage->{debug} = 1;
}

my %params = ();

my @available_tests = folder_list($argv, $Bin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $argv
}, $run_tests);

done_testing();

1;
