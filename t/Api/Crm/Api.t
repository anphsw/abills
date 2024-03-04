=head1 NAME

  Crm API test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw($RealBin);
use JSON;

require $Bin . '/../../../libexec/config.pl';

BEGIN {
  our $libpath = '../../../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Defs;
use Init_t qw(test_runner folder_list help);
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
  debug  => $debug
}, \@test_list);

done_testing();

1;
