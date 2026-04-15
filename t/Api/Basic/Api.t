=head1 NAME

  Global API test

=cut

use strict;
use warnings;

use lib '../';
use FindBin '$Bin';

BEGIN {
  our $libpath = $Bin . '/../../../';
  do "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Api::Tests::Init qw(test_runner folder_list help);

our (
  %conf
);

my $argv = parse_arguments(\@ARGV);
my $apiKey = $argv->{KEY};
my @test_list = folder_list($argv, $Bin);
my $debug = $argv->{DEBUG} || 0;

my $login = $conf{API_TEST_USER_LOGIN} || 'test';
my $password = $conf{API_TEST_USER_PASSWORD} || '123456';

if (defined($argv->{help})) {
  help();
  exit 0;
}

foreach my $test (@test_list) {
  if ($test->{path} =~ /users\/login\//xg) {
    $test->{body}->{login} = $login;
    $test->{body}->{password} = $password;
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $argv
}, \@test_list);

done_testing();

1;
