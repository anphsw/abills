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

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $admin = Admins->new($db, \%conf);
my $Internet = Internet->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);
my $Shedule  = Shedule->new($db, $admin, \%conf);
my $Service_control  = Control::Service_control->new($db, $admin, \%conf);

my $user = $Users->list({
  LOGIN     => $conf{API_TEST_USER_LOGIN} || 'test',
  COLS_NAME => 1,
});

my $service = $Internet->user_list({
  UID       => $user->[0]->{uid} || '---',
  TP_ID     => '_SHOW',
  ID        => '_SHOW',
  COLS_NAME => 1,
  PAGE_ROWS => 1
});

my $active_tariffs = $Service_control->services_info({
  UID             => $user->[0]->{uid},
  SERVICE_INFO    => $Internet,
  FUNCTION_PARAMS => {
    GROUP_BY        => 'internet.id',
    INTERNET_STATUS => '_SHOW',
  },
});

my $available_tariffs = $Service_control->available_tariffs({
  UID    => $user->[0]->{uid},
  MODULE => 'Internet'
});

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @tests = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

foreach my $test (@tests) {
  # TODO: move to core
  if ($test->{path} =~ /user\/:id\/holdup\//g) {
    my $id = (scalar(@{$service})) ? $service->[0]->{id} : '';
    $test->{path} =~ s/:id/$id/g;

    if ($test->{method} eq 'POST') {
      my $hold_up_min_period = 1;
      ($hold_up_min_period) = split(/:/, $conf{HOLDUP_ALL}) if ($conf{HOLDUP_ALL});

      $test->{body}->{from_date} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400));
      $test->{body}->{to_date} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * ($hold_up_min_period + 1)));
    }
  }
  elsif ($test->{path} =~ /user\/internet\/:id\/activate/g) {
    my $id = $active_tariffs->[0]->{id};
    $test->{path} =~ s/:id/$id/g;
  }
  elsif ($test->{path} =~ /user\/internet\/:id/g) {
    if ($test->{method} eq 'DELETE') {
      $Shedule->info({ UID => $user->[0]->{uid}, TYPE => 'tp', MODULE => 'Internet' });
      $Shedule->{SHEDULE_ID} //= '';
      $test->{path} =~ s/:id/$Shedule->{SHEDULE_ID}/g;
    }
    elsif ($test->{method} eq 'PUT') {
      $test->{body}->{tpId} = $available_tariffs->[0]->{tp_id};
      my $id = $active_tariffs->[0]->{id};
      $test->{path} =~ s/:id/$id/g;
    }
    else {
      my $id = $active_tariffs->[0]->{id};
      $test->{path} =~ s/:id/$id/g;
    }
  }
  elsif ($test->{path} =~ /internet\/activate\//g) {
    if ($test->{method} eq 'POST') {
      $test->{body}->{tp_id} = $available_tariffs->[1]->{id};
      $test->{body}->{status} = 0;
    }
    elsif ($test->{method} eq 'PUT') {
      $test->{body}->{id} = $active_tariffs->[0]->{id};
      $test->{body}->{status} = int(rand(6));
    }
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@tests);

done_testing();

1;
