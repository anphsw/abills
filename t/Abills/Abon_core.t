=head

Abon test Plan

  - Month fee with postpaid and month aligment
    1. Activate cur period
    2. Activate from prevu date
    3. Activate from pre day to END pre day

=cut
use strict;
use warnings;

use lib
  '../../',
  '../../lib',
  '../../Abills/mysql';

use Abills::Init;
use Abon::Services;
use Abills::Base qw(parse_arguments);

our (
  %lang,
  %conf,
  $db,
  $admin,
  $users,
);

use Test::More;
use Test::MockModule;

do 'language/english.pl';
require_ok('Abills::Misc');

# our $html = Abills::HTML->new({
#   CONF     => \%conf,
#   CHARSET  => $conf{default_charset},
# });

my $mock_fees = Test::MockModule->new('Fees');
$mock_fees->redefine('take', sub {
  my ($self, $user, $sum, $opts) = @_;
  return 1;
});

# Mock Users module
my $users_mock = Test::MockModule->new('Users');
$users_mock->redefine('new', sub {
  return bless { BILL_ID => 1, ACTIVATE => '2023-01-01' }, 'Users';
});
$users_mock->redefine('info', sub {
  return { UID => 1, BILL_ID => 1, ACTIVATE => '2023-01-01' };
});

my $service = {
  UID => 1,
  TP_INFO => {
    ACTIV_PRICE => 10
  }
};

my $result = service_get_month_fee($service, { SERVICE_NAME => 'Internet', MODULE => 'Internet' });

ok($result->{MONTH_FEE} >= 0, 'Returned MONTH_FEE');

done_testing();





1;