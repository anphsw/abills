=head1 NAME

  Abon API test

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
use Abills::Api::Tests::Init qw(test_runner folder_list help test_preprocess);
use Abills::Base qw(parse_arguments);
use Admins;
use Users;
use Abon;

our (
  %conf
);

my $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);

my $admin = Admins->new($db, \%conf);
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

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $tariff_id = (scalar(@{$abon_tariffs})) ? $abon_tariffs->[0]->{id} : '';
my %params =  (
  id => $tariff_id
);

my $run_test = test_preprocess(\@test_list, \%params);

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  args   => $ARGS
}, $run_test);

done_testing();

1;
