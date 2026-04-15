=head1 NAME

  Internet API test

=cut
use strict;
use warnings;

use Test::More;
use FindBin '$Bin';

BEGIN {
  my $libpath = $Bin . '/../../../../';
  do "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Api::Tests::Init qw(test_runner folder_list db_connect help);
use Internet;
use Shedule;
use Control::Service_control;

our (
  %conf,
);

my ($db, $admin) = db_connect();
my $argv = parse_arguments(\@ARGV);

if (defined($argv->{help})) {
  help();
  exit 0;
}

my $Internet = Internet->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Service_control  = Control::Service_control->new($db, $admin, \%conf);

my $apiKey = $argv->{KEY} || q{};
my $debug = $argv->{DEBUG} || 0;

if ($debug > 6)  {
  $Users->{debug}=1;
  $Internet->{debug}=1;
}

my $test_user = $conf{API_TEST_USER_LOGIN} || 'test';
my $user = $Users->list({
  LOGIN     => $test_user,
  DEPOSIT   => '_SHOW',
  CREDIT    => '_SHOW',
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
  PAGE_ROWS => 1,
  GROUP_BY  => 'internet.id',
  SORT      => 'internet.id',
  DESC      => 'DESC'
});

if($service_list && ! $service_list->[0]->{tp_id} && $user->[0]->{credit} + $user->[0]->{deposit} < 0 ) {
  _log("$test_user Too small deposit for tarif activation");
  exit;
}

my $available_tariffs = $Service_control->available_tariffs({
  UID               => $uid,
  MODULE            => 'Internet',
  ADD_FIRST_SERVICE => ($service_list->[0]->{tp_id}) ? undef : 1
});

if ($Service_control->{error}) {
  _log("[$Service_control->{error}] $Service_control->{errstr}");
}

$Shedule->info({ UID => $uid, TYPE => 'tp', MODULE => 'Internet' });

my $hold_up_min_period = 1;
($hold_up_min_period) = split(':', $conf{HOLDUP_ALL}) if ($conf{HOLDUP_ALL});

my %params = (
  serviceId => $service_list->[0]->{id},
  uid       => $uid,
  fromDate  => POSIX::strftime('%Y-%m-%d', localtime(time + 86400)),
  toDate    => POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * ($hold_up_min_period + 1))),
  NextTpId  => $argv->{NEXT_TP_ID} || 4,
  cid       => $argv->{CID} || '10:fe:ed:43:8f:37',
);

if($argv->{EXECUTABLE_TESTS}) {
  $params{id}        = $service_list->[0]->{id};
  $params{sheduleId} = $Shedule->{SHEDULE_ID} || 0;
}

if (! $available_tariffs || ref $available_tariffs ne 'ARRAY') {
  _log("No available tarifs for change UID: $uid");
  $params{tpId} = $service_list->[0]->{tp_id};
}
else {
  $params{tpId} = $available_tariffs->[0]->{tp_id};
  $params{nextTpId} = $available_tariffs->[1]->{tp_id};
}

my @available_tests = folder_list($argv, $Bin);
my $run_tests = test_preprocess(\@available_tests, \%params, \%conf, { DEBUG => 2 });

test_runner({
  apiKey => $apiKey,
  argv   => $argv,
  debug  => $debug
}, $run_tests);

done_testing();

1;
