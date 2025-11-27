=head1 NAME

  Paysys API test

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
use Paysys;
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

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;
my @tests = ();

my $Paysys = Paysys->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

if ($debug > 6)  {
  $Users->{debug}=1;
  $Paysys->{debug}=1;
}

my $CHECK_FIELD = $conf{PAYSYS_GATEWAY_IDENTIFIER} || 'UID';
my $test_user = $conf{API_TEST_USER_LOGIN} || 'test';

my $user = $Users->list({
  $CHECK_FIELD => '_SHOW',
  LOGIN        => $test_user,
  COLS_NAME    => 1,
  COLS_UPPER   => 1,
});

if ($Users->{TOTAL} < 1) {
  _log("test user not exists '$test_user'");
}

foreach my $test (@test_list) {
  if ($test->{path} =~ /\/transaction\/status\/:id/g) {
    my $list = $Paysys->list({
      TRANSACTION_ID => '_SHOW',
      LOGIN          => ($conf{API_TEST_USER_LOGIN} || 'test'),
      COLS_NAME      => 1
    });

    $test->{path} =~ s/:id/$list->[0]->{transaction_id}/g;
  }
  elsif ($test->{path} =~ /\/user\/paysys\/gateway\/search\//g) {
    $test->{body}{userIdentifier} = $user->[0]->{$CHECK_FIELD};
  }
  elsif ($test->{path} =~ /\/pay\//g && ($test->{name} eq 'USER_PAYSYS_PAY' || $test->{name} eq 'PAYSYS_GATEWAY_PAY')) {
    my $list = $Paysys->paysys_connect_system_list({
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    foreach my $paysys_module (@{$list}) {
      my %_test = %{$test};
      my ($paysys_name) = $paysys_module->{module} =~ /(.+)\.pm/;
      my $module = "Paysys::systems::$paysys_name";
      my $module_path = $module . '.pm';
      $module_path =~ s{::}{/}g;
      eval { require $module_path };

      $test->{body}{userIdentifier} = $user->[0]->{$CHECK_FIELD} if ($test->{name} eq 'PAYSYS_GATEWAY_PAY');

      if ($module->can('fast_pay_link')) {
        $_test{name} = "USER_PAYSYS_PAY_$paysys_name";
        $_test{body}->{systemId} = $paysys_module->{id};
        $_test{body}->{operationId} = int(rand(1000000));
        $_test{body}->{sum} = 1;
        push @tests, \%_test;
      }
    }
  }
  push @tests, $test;
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $ARGV
}, \@tests);

done_testing();

1;
