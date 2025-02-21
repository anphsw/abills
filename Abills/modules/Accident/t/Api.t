=head1 NAME

  Docs API test

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
use Users;

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

my $user = $Users->list({
  LOGIN      => $conf{API_TEST_USER_LOGIN} || 'test',
  COLS_NAME  => 1,
  COLS_UPPER => 1
})->[0];

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

# foreach my $test (@test_list) {
#   if ($test->{path} =~ /user\/accident\/users\/:uid/g) {
#     $test->{path} =~ s/:uid/$user->{UID}/g;
#   }
#   if ($test->{path} =~ /user\/accident\/equipment\/users\/:uid/g) {
#     $test->{path} =~ s/:uid/$user->{UID}/g;
#   }
# }

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  args   => $ARGS
}, \@test_list);

done_testing();

1;