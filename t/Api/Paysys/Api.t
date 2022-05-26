=head1 NAME

  Paysys API test

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
use Init_t qw(test_runner folder_list);
use Abills::Base qw(parse_arguments);
use Admins;
use Paysys;

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
my $Paysys = Paysys->new($db, $admin, \%conf);

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

foreach my $test (@test_list) {
  if ($test->{path} =~ /\/transaction\/status\//g) {
    my $list = $Paysys->list({
      TRANSACTION_ID => '_SHOW',
      LOGIN          => ($conf{API_TEST_USER_LOGIN} || 'test'),
      COLS_NAME      => 1
    });

    $test->{body}->{transactionId} = $list->[0]->{transaction_id};
  }
  elsif ($test->{path} =~ /\/pay\//g && $test->{name} eq 'USER_PAYSYS_PAY') {
    my $list = $Paysys->paysys_connect_system_list({
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    #FIXME multiple fast_pay_link tests
    foreach my $paysys_module (@{$list}) {
      my ($paysys_name) = $paysys_module->{module} =~ /(.+)\.pm/;
      my $module = "Paysys::systems::$paysys_name";
      eval "use $module";

      if ($module->can('fast_pay_link')) {
        $test->{name} = "USER_PAYSYS_PAY_$paysys_name";
        $test->{body}->{systemId} = $paysys_module->{id};
        $test->{body}->{operationId} = int(rand(1000000));
        $test->{body}->{sum} = 1;
      }
    }
  }
  else {
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@test_list);

done_testing();

1;