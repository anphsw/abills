=head1 NAME

  Abon API test

=cut

use strict;
use warnings;
use FindBin '$Bin';


BEGIN {
  our $libpath = $Bin . '/../../../../';
  do "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Defs;
use Abills::Api::Tests::Init qw(test_runner folder_list help test_preprocess);
use Users;
use Abon;

our (
  %conf
);

my ($db, $admin) = db_connect();
my $argv = parse_arguments(\@ARGV);

my $Users = Users->new($db, $admin, \%conf);
my $Abon = Abon->new($db, $admin, \%conf);

my $user = $Users->list({
  LOGIN     => $conf{API_TEST_USER_LOGIN} || 'test',
  COLS_NAME => 1,
});

my $abon_tariffs = $Abon->user_tariff_list($user->[0]->{uid} || '---', {
  USER_PORTAL  => '>1',
  SERVICE_LINK => '_SHOW',
  COLS_NAME    => 1
});


my $apiKey = $argv->{KEY};
my $debug = $argv->{DEBUG} || 0;

if (defined($argv->{help})) {
  help();
  exit 0;
}

my $tariff_id = (scalar(@{$abon_tariffs})) ? $abon_tariffs->[0]->{id} : '';
my %params =  (
  id => $tariff_id
);

my @available_tests = folder_list($argv, $Bin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $argv
}, $run_tests);

done_testing();

1;
