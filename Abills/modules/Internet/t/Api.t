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
use Internet;
use Shedule;
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
my $Internet = Internet->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Service_control  = Control::Service_control->new($db, $admin, \%conf);

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my $debug = $ARGS->{DEBUG} || 0;

if ($debug > 6)  {
  $Users->{debug}=1;
  $Internet->{debug}=1;
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
my $service_list = $Internet->user_list({
  UID       => $uid || '---',
  TP_ID     => '_SHOW',
  ID        => '_SHOW',
  COLS_NAME => 1,
  PAGE_ROWS => 1,
  GROUP_BY  => 'internet.id',
  SORT      => 'internet.id',
  DESC      => 'DESC'
});

# my $active_tariffs = $Service_control->services_info({
#   UID             => $user->[0]->{uid},
#   SERVICE_INFO    => $Internet,
#   FUNCTION_PARAMS => {
#     GROUP_BY        => 'internet.id',
#     INTERNET_STATUS => '_SHOW',
#   },
# });

my $available_tariffs = $Service_control->available_tariffs({
  UID    => $uid,
  MODULE => 'Internet'
});

if ($Service_control->{error}) {
  _log("[$Service_control->{error}] $Service_control->{errstr}");
}

$Shedule->info({ UID => $uid, TYPE => 'tp', MODULE => 'Internet' });

my $hold_up_min_period = 1;
($hold_up_min_period) = split(/:/, $conf{HOLDUP_ALL}) if ($conf{HOLDUP_ALL});

my %params = (
  id        => $service_list->[0]->{id},
  serviceId => $service_list->[0]->{id},
  uid       => $uid,
  sheduleId => $Shedule->{SHEDULE_ID} || 0,
  fromDate  => POSIX::strftime('%Y-%m-%d', localtime(time + 86400)),
  toDate    => POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * ($hold_up_min_period + 1)))
);


if (! $available_tariffs || ref $available_tariffs ne 'ARRAY') {
  _log("No available tarifs");
  $params{tpId} = $service_list->[0]->{tp_id};
}
else {
  $params{tpId} = $available_tariffs->[0]->{tp_id};
  $params{nextTpId} = $available_tariffs->[1]->{tp_id};
}

my @available_tests = folder_list($ARGS, $RealBin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });


test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, $run_tests);

done_testing();

1;
