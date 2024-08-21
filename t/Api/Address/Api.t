=head1 NAME

  Address API test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw($RealBin);
use JSON;

BEGIN {
  our $libpath = $Bin . '/../../../';
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
use Users;
use Address;

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
my $Address = Address->new($db, $admin, \%conf);

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $districts = $Address->district_list({
  ID        => '_SHOW',
  COLS_NAME => 1
});

my $streets = $Address->street_list({
  ID        => '_SHOW',
  COLS_NAME => 1
});

my $builds = $Address->build_list({
  ID        => '_SHOW',
  COLS_NAME => 1
});

my $district_id = $districts->[-1]->{id} || 0;
my $street_id = $streets->[-1]->{id} || 0;
my $build_id = $builds->[-1]->{id} || 0;

foreach my $test (@test_list) {
  if ($test->{method} eq 'GET' && $test->{path} =~ /:id/g) {
    $test->{path} =~ /streets\/:id/g;

    if ($test->{path} =~ /districts\/:id/g) {
      $test->{path} =~ s/:id/$district_id/g;
    }
    elsif ($test->{path} =~ /streets\/:id/g) {
      $test->{path} =~ s/:id/$street_id/g;
    }
    elsif ($test->{path} =~ /builds\/:id/g) {
      $test->{path} =~ s/:id/$build_id/g;
    }
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@test_list);

done_testing();

1;
