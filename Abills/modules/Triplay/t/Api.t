=head1 NAME

  Internet API test

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
use Triplay;
use Control::Service_control;

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
my $Triplay = Triplay->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my $debug = $ARGS->{DEBUG} || 0;

if ($debug > 6)  {
  $Users->{debug}=1;
  $Triplay->{debug}=1;
}

my $test_user = $conf{API_TEST_USER_LOGIN} || 'test';
my $user = $Users->list({
  LOGIN     => $test_user,
  COLS_NAME => 1,
});

if ($Users->{TOTAL} < 1) {
  _log("test user not exists '$test_user'");
}

my $uid = $user->[0]->{uid};
my $service_list = $Triplay->tp_list({
  TP_ID     => '_SHOW',
  ID        => '_SHOW',
  COLS_NAME => 1,
  PAGE_ROWS => 1,
  DESC      => 'DESC'
});

my $hold_up_min_period = 1;
($hold_up_min_period) = split(/:/, $conf{HOLDUP_ALL}) if ($conf{HOLDUP_ALL});

my %params = (
  tpId => $service_list->[0]->{tp_id},
  uid  => $uid,
);

my @available_tests = folder_list($ARGS, $RealBin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, $run_tests);

done_testing();

1;
