=head

Abon test Plan

  - Month fee with postpaid and month aligment
    1. Activate cur period
    2. Activate from prevu date
    3. Activate from pre day to END pre day

=cut
use strict;
use warnings;

use lib '../',
  '../../',
  '../../../../lib',
  '../../../../Abills/mysql';

use Test::More tests => 13;
use Abills::Init;
use Abon::Services;
use Abills::Base qw(parse_arguments days_in_month);

do 'language/english.pl';

our (
  %lang,
  %conf,
  $db,
  $admin,
  $users
);

do '../../../language/english.pl';

if (-f '../../../libexec/config.pl') {
  do '../../../libexec/config.pl';
}

my $argv = parse_arguments(\@ARGV);
my $debug = $argv->{DEBUG} || 0;

#**********************************************************
=head2 periods_tests($attr) - periods_test

  Arguments:

  Returns:

=cut
#**********************************************************
sub base_tests {
  my ($tests)=@_;
  use Test::MockModule;

  my $mock_fees = Test::MockModule->new('Fees');
  $mock_fees->redefine('take', sub {
    my ($self, $user, $sum, $opts) = @_;
    return 1;
  });

  my $mock_user = Test::MockModule->new('Users');
  $mock_user->redefine('info', sub {
    return {
      UID         => 1,
      DEPOSIT     => 100,
      REDUCTION   => 0,
      EXT_DEPOSIT => 0,
      EXT_BILL_ID => 0,
    };
  });

  my $services = Abon::Services->new(undef, undef, undef, { LANG => \%lang, HTML => undef });

  my $service = $tests->[0]->{REQUEST};

  my $result = $services->abon_get_month_fee($service, {
    USER_INFO => bless({}, 'Users'),
    #END_DATE  => '2025-06-30',
    TEST      => 1,
  });

  ok($services->{SUM}->[0] > 0, 'Calculated monthly fee');
  ok(!$services->{errno}, 'No error returned');
  #like($result->{PERIOD}, qr/2025-06/x, 'Correct period calculated Return:' . $result->{PERIOD});

  return 1;
}

#**********************************************************
=head2 periods_tests($attr) - periods_test

  Arguments:

  Returns:

=cut
#**********************************************************
sub periods_tests {
  my ($tests)=@_;

  my $Abon_services = Abon::Services->new($db, $admin, \%conf, { LANG => \%lang });

  my $i = 1;
  foreach my $test (@$tests) {
    delete $Abon_services->{SUM};
    delete $Abon_services->{PERIOD};
    delete $Abon_services->{DAYS};

    my $request = $test->{REQUEST};
    my $test_result = $test->{RESULT};
    my $result = $Abon_services->abon_get_month_fee($request, {
      %$request,
      SERVICE_ACTIVATE => $request->{SERVICE_ACTIVATE},
      END_DATE         => $request->{END_DATE},
      USER_INFO        => $users,
      TEST             => 1,
      DEBUG            => $debug
    });

    if ($result->{MESSAGE}) {
      print "Message: $result->{MESSAGE}\n";
    }
    else {
      if (ref $test_result eq 'HASH') {
        _test($i, $test_result, $Abon_services);
      }
      else {
        foreach my $test_ (@{ $test_result }) {
          _test($i, $test_, $Abon_services);
        }
      }
    }
    $i++;
  }

  return 1;
}

my $tests_list = get_tests($argv->{TESTS} || 'Services/01_abon.json');
if (! $argv->{TESTS}) {
  base_tests($tests_list);
}

if ($#{ $tests_list } > -1) {
  periods_tests($tests_list);
}

#**********************************************************
=head2 _test($attr) - periods_test

  Arguments:
    $attr
      NUM
      TEST
      RESULT

  Returns:

=cut
#**********************************************************
sub _test {
  my ($num, $test_result, $Abon_services) = @_;

  my $test_num = $test_result->{NUM} || 0;
  if ($debug) {
    print "\n";
    print "SUM: $Abon_services->{SUM}->[0]\nDAYS: $Abon_services->{DAYS}->[0]\n";
    print "Period: $Abon_services->{PERIOD}->[0]\n";
  }

  foreach my $res (sort keys %{$test_result}) {
    next if ($res eq 'NUM');
    my $test_value = eval " $test_result->{$res} " ;

    if ($debug > 0) {
      print "  $res: $test_value -> $Abon_services->{$res}->[$test_num]\n";
    }

    my $comments = q{}; #$test->{COMMENTS} || q{};
    ok($test_value == $Abon_services->{$res}->[$test_num], "[$num] $res: $Abon_services->{$res}->[$test_num] Period: $Abon_services->{PERIOD}->[$test_num] $comments");
  }

  return 1;
}
1;