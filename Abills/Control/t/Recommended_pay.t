#!/usr/bin/perl

=head1 NAME

  Unit tests for Control::Recommended_pay

  Tests for:
    - recomended_sum_triplay() - Extended service recommended pay with Triplay logic
    - recomended_sum_default() - Default recommended sum calculation
    - recomended_sum_as_deposit() - Recommended sum as deposit calculation

=cut

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::MockModule;
use FindBin '$Bin';

use lib '../../../lib/';

use Abills::Init;

use Abills::Base qw(days_in_month);

our (
  %conf,
  $db,
  $admin,
);

use Control::Services;
my $services_mock = Test::MockModule->new('Control::Services');

$services_mock->redefine(
  new => sub {
    my ($class) = @_;
    my $self = {};
    bless($self, $class);
    return $self;
  },
  get_services => sub {
    # Return mock service info based on test scenario
    my $test_scenario = $main::test_scenario || 'default';

    my %SCENARIOS = (
      triplay_status_2 => {
        list      => [ { STATUS => 2, SUM => 100.00, MODULE => 'Triplay' } ],
        total_sum => 100.00,
      },

      triplay_status_5 => {
        list      => [ { STATUS => 5, SUM => 150.00, MODULE => 'Triplay' } ],
        total_sum => 150.00,
      },

      triplay_status_0 => {
        list      => [ { STATUS => 0, SUM => 50.00, MODULE => 'Triplay' } ],
        total_sum => 50.00,
      },

      no_triplay => {
        list      => [],
        total_sum => 0,
      },

      service_sum_100 => {
        list      => [ { STATUS => 1, SUM => 100.00, MODULE => 'Internet' } ],
        total_sum => 100.00,
      },

      service_sum_250 => {
        list      => [ { STATUS => 1, SUM => 250.00, MODULE => 'Internet' } ],
        total_sum => 250.00,
      },
    );

    return $SCENARIOS{$test_scenario}
      // {
      list      => [ { STATUS => 1, SUM => 100.00, MODULE => 'Internet' } ],
      total_sum => 100.00,
    };
  }
);

my $triplay_mock = Test::MockModule->new('Triplay');

$triplay_mock->redefine(
  new => sub {
    my ($class) = @_;
    my $self = {
      TP_PERIOD_ALIGNMENT => $main::triplay_period_alignment || 0,
    };
    bless($self, $class);
    return $self;
  },
  user_info => sub {
    my ($self, $attr) = @_;
    return $self;
  }
);

# LOADED AFTER MOCKS IMPORTANT
use_ok('Control::Recommended_pay');

require Abills::Misc;

my $Recommended_pay = Control::Recommended_pay->new($db, $admin, \%conf);
isa_ok($Recommended_pay, 'Control::Recommended_pay');

our $DATE = '2024-01-15';

my %test_user = (
  UID     => 1,
  DEPOSIT => 50.00
);

our $test_scenario;
our $triplay_period_alignment;

$conf{PAYSYS_DEBET_RECOMMENDED_SUM} = 0;
$conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} = 0;
$conf{PAYSYS_NET_RECOMMENDED_SUM} = 0;
$conf{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT} = 0;

# ============================================
# Tests for recomended_sum_default()
# ============================================
subtest 'recomended_sum_default - basic cases' => sub {

  # Test 1: Basic calculation with deposit
  $test_scenario = 'service_sum_100';
  my $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '50.00', 'Default: Service > deposit');

  # Test 2: Deposit greater than service sum
  $test_user{DEPOSIT} = 150.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '0.00', 'Default: deposit > service');

  # Test 3: Negative deposit
  $test_user{DEPOSIT} = -30.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '130.00', 'Default: negative deposit adds to sum');

  # Test 4: No deposit defined
  my %user_no_deposit = (UID => 1);
  $result = $Recommended_pay->recomended_sum_default(\%user_no_deposit, { DATE => $DATE });
  is($result, '0', 'Default: no deposit defined = 0');

  # Test 5: SKIP_DEPOSIT_CHECK
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, {
    DATE => $DATE,
    SKIP_DEPOSIT_CHECK => 1
  });
  is($result, '100.00', 'Default: SKIP_DEPOSIT_CHECK ignores deposit');

  # Test 6: Fractional sum rounding
  $test_scenario = 'service_sum_250';
  $test_user{DEPOSIT} = 49.95;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '201.00', 'Default: add plus 1 to pay sum if amount not int');

  # Test 7: PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT config
  $conf{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT} = 1;
  $test_user{DEPOSIT} = -50.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '50.00', 'Default: PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT returns abs(deposit)');

  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '0', 'Default: PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT with positive deposit = 0');

  delete $conf{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT};

  # Test 8: PAYSYS_NET_RECOMMENDED_SUM config
  $conf{PAYSYS_NET_RECOMMENDED_SUM} = 1;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '0', 'Default: PAYSYS_NET_RECOMMENDED_SUM returns 0');
  delete $conf{PAYSYS_NET_RECOMMENDED_SUM};

  # Test 9: PAYSYS_ADD_TO_RECOMMENDED_SUMM config
  $conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} = 10.00;
  $test_user{DEPOSIT} = 50.00;
  $test_scenario = 'service_sum_100';
  $result = $Recommended_pay->recomended_sum_default(\%test_user, { DATE => $DATE });
  is($result, '60.00', 'Default: PAYSYS_ADD_TO_RECOMMENDED_SUMM adds to result');
  delete $conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM};

  # Test 10: SKIP_ADD_SUM
  $test_user{DEPOSIT} = 0.00;
  $test_scenario = 'service_sum_100';
  $result = $Recommended_pay->recomended_sum_default(\%test_user, {
    DATE => $DATE,
    SKIP_ADD_SUM => 1
  });
  is($result, '100.00', 'Default: SKIP_ADD_SUM prevents rounding up');

  # Test 11: SERVICE_INFO provided
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_default(\%test_user, {
    DATE => $DATE,
    SERVICE_INFO => { total_sum => 200.00 }
  });
  is($result, '150.00', 'Default: uses provided SERVICE_INFO');
};

# ============================================
# Tests for recomended_sum_as_deposit()
# ============================================

subtest 'recomended_sum_as_deposit - basic cases' => sub {

  # Test 1: Date before calculation_date (default 25)
  $test_scenario = 'service_sum_100';
  $test_user{DEPOSIT} = -50.00;
  my $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE => '2024-01-15'  # Day 15 < 25
  });
  is($result, '50.00', 'As deposit: date < 25, negative deposit = abs(deposit)');

  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE => '2024-01-15'
  });
  is($result, '0', 'As deposit: date < 25, positive deposit = 0');

  # Test 2: Date after calculation_date
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE => '2024-01-26'  # Day 26 > 25
  });
  is($result, '50.00', 'As deposit: date > 25, calculates normally');

  # Test 3: Custom CALCULATION_DATE
  $test_user{DEPOSIT} = -30.00;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE              => '2024-01-20',
    CALCULATION_DATE  => 15
  });
  is($result, '130.00', 'As deposit: custom CALCULATION_DATE works');

  # Test 4: No deposit defined
  my %user_no_deposit = (UID => 1);
  $result = $Recommended_pay->recomended_sum_as_deposit(\%user_no_deposit, {
    DATE => '2024-01-26'
  });
  is($result, '0', 'As deposit: no deposit defined = 0');

  # Test 5: SKIP_DEPOSIT_CHECK
  $test_user{DEPOSIT} = 49.90;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE               => '2024-01-26',
    SKIP_DEPOSIT_CHECK => 1
  });
  is($result, '100.00', 'As deposit: SKIP_DEPOSIT_CHECK ignores deposit');

  # Test 6: PAYSYS_ADD_TO_RECOMMENDED_SUMM
  $conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} = 5.00;
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE => '2024-01-26'
  });
  is($result, '55.00', 'As deposit: PAYSYS_ADD_TO_RECOMMENDED_SUMM adds to result');
  delete $conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM};

  # Test 7: Fractional sum rounding
  $test_scenario = 'service_sum_250';
  $test_user{DEPOSIT} = 49.90;
  $result = $Recommended_pay->recomended_sum_as_deposit(\%test_user, {
    DATE => '2024-01-26'
  });
  is($result, '201.00', 'As deposit: add plus 1 to pay sum if amount not int');
};

# ============================================
# Tests for recomended_sum_triplay()
# ============================================

subtest 'recomended_sum_triplay - triplay_status = 2 (not active)' => sub {

  $test_scenario = 'triplay_status_2';
  $test_user{DEPOSIT} = 50.00;
  $triplay_period_alignment = 0;

  # Test 1: Date > 25, no period alignment
  my $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26'
  });
  is($result, '150.00', 'Triplay status 2: date > 25, no alignment = sum + default');

  # Test 2: Date <= 25, no period alignment
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });
  is($result, '50.00', 'Triplay status 2: date <= 25, no alignment = sum - deposit');

  # Test 3: Date > 25, with period alignment
  $triplay_period_alignment = 1;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26'  # 31 days in January, day 26 = 6 days remaining
  });
  # Expected: (100/31)*6 = 19.35, then + default (100 - 50) = 69.35 -> 70.00
  is($result, '70.00', 'Triplay status 2: date > 25, with alignment calculates correctly');

  # Test 4: Date <= 25, with period alignment
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'  # 31 days in January, day 15 = 17 days remaining
  });

  # Expected: (100/31)*17 = 54.84, then - deposit (50) = 4.84 -> 5.00
  is($result, '5.00', 'Triplay status 2: date <= 25, with alignment calculates correctly');

  # Test 5: DEBUG mode
  $triplay_period_alignment = 0;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15',
    DEBUG => 1
  });

  like($result, qr/50.00/, 'Triplay status 2: amount 50');
  like($result, qr/Triplay: status: 2/, 'Triplay status 2: DEBUG mode includes debug info');
  like($result, qr/pre 25/, 'Triplay status 2: DEBUG mode includes "pre 25"');
};

subtest 'recomended_sum_triplay - triplay_status = 5 (too small deposit)' => sub {

  $test_scenario = 'triplay_status_5';
  $test_user{DEPOSIT} = 50.00;

  # Test 1: Date > 25
  my $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26'
  });
  # 150 + 150 - 50
  is($result, '250.00', 'Triplay status 5: date > 25 = default + triplay sum');

  # Test 2: Date <= 25 (should skip Abon module)
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });

  is($result, '100.00', 'Triplay status 5: date <= 25 calculates default');

  # Test 3: DEBUG mode
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15',
    DEBUG => 1
  });

  like($result, qr/100.00/, 'Triplay status 5: amount 100');
  like($result, qr/Triplay: status: 5/, 'Triplay status 5: DEBUG mode includes debug info');
  like($result, qr/pre 25/, 'Triplay status 5: DEBUG mode includes "pre 25"');
};

subtest 'recomended_sum_triplay - triplay_status = 0 or other' => sub {

  $test_scenario = 'triplay_status_0';
  $test_user{DEPOSIT} = 50.00;

  # Test 1: Date > 25
  my $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26'
  });

  # Should call recomended_sum_default
  is($result, '0.00', 'Triplay status 0: date > 25 = default calculation');

  # Test 2: Date <= 25
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });

  # Should calculate: deposit adjustment
  is($result, '0.00', 'Triplay status 0: date <= 25 calculates with deposit adjustment');

  # Test 3: Negative deposit, date <= 25
  $test_user{DEPOSIT} = -30.00;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });
  # Should add abs(deposit) to recomended_sum
  is($result, '30.00', 'Triplay status 0: negative deposit adds to sum');

  # Test 4: Deposit > recomended_sum, date <= 25
  $test_user{DEPOSIT} = 100.00;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });
  is($result, '0.00', 'Triplay status 0: deposit > sum results in 0');

  # Test 5: Deposit > recomended_sum, date <= 25
  $test_user{DEPOSIT} = 30.00;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26'
  });
  is($result, '20.00', 'Triplay status 0: date > 25 calculates correctly');

  # Test 6: DEBUG mode
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15',
    DEBUG => 1
  });
  like($result, qr/Triplay: status: 0/, 'Triplay status 0: DEBUG mode includes debug info');
  like($result, qr/pre 25/, 'Triplay status 0: DEBUG mode includes "pre 25"');
};

subtest 'recomended_sum_triplay - edge cases' => sub {

  # Test 1: No deposit defined
  my %user_no_deposit = (UID => 1);
  $test_scenario = 'triplay_status_2';
  my $result = $Recommended_pay->recomended_sum_triplay(\%user_no_deposit, {
    DATE => '2024-01-15'
  });
  is($result, '0', 'Triplay: no deposit defined = 0');

  # Test 2: Negative result (should be set to 0)
  $test_user{DEPOSIT} = 200.00;
  $test_scenario = 'triplay_status_2';
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });
  is($result, '0.00', 'Triplay: negative result set to 0');

  # Test 3: PAYSYS_DEBET_RECOMMENDED_SUM config
  $conf{PAYSYS_DEBET_RECOMMENDED_SUM} = 1;
  $test_user{DEPOSIT} = 4.50;
  $test_scenario = 'triplay_status_0';
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-26',
    SKIP_ADD_SUM => 1
  });
  is($result, '46.00', 'Triplay: PAYSYS_DEBET_RECOMMENDED_SUM with SKIP_ADD_SUM');
  delete $conf{PAYSYS_DEBET_RECOMMENDED_SUM};

  # Test 4: No triplay service
  $test_scenario = 'no_triplay';
  $test_user{DEPOSIT} = 50.00;
  $result = $Recommended_pay->recomended_sum_triplay(\%test_user, {
    DATE => '2024-01-15'
  });

  # Should handle empty list gracefully
  is($result, '0.00', 'Triplay: no triplay service');
};

done_testing();

1;

