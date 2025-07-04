=head1 NAME

  Storage API test

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
use Storage;

our (
  %conf,
);

my $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $admin = Admins->new($db, \%conf);
my $Storage = Storage->new($db, $admin, \%conf);

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my $debug = $ARGS->{DEBUG} || 0;

if ($debug > 6) {
  $Storage->{debug} = 1;
}

my %params = ();

my @available_tests = folder_list($ARGS, $RealBin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, $run_tests);

done_testing();

1;
