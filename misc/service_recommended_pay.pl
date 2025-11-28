#!/usr/bin/perl
=head1

  Extended service recomended pay

=cut

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

our $VERSION = 0.71;
BEGIN {
  our %conf;
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../Abills/modules/',
    $Bin . "/../Abills/$conf{dbtype}");
}

use Abills::SQL;
use Admins;
use Users;
use Abills::Base qw(parse_arguments days_in_month);
use Abills::Init;

require Control::Services;

our (
  %conf,
  $db,
  $admin,
  $DATE
);

$db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $argv = parse_arguments(\@ARGV);
my $user = get_test_user($argv);
my $result = 0;
my $debug = $argv->{DEBUG} || 0;
if ($argv->{DATE}) {
  $DATE = $argv->{DATE};
}

if ($argv->{MODEL}) {
  $result = recomended_sum($user, $argv);
}
else {
  $result = recomended_sum_default($user, $argv);
}

print $result;

#**********************************************************
=head1 recomended_sum($sum, $attr) - Format sum

  Arguments:
    $user_info
    $attr

  Results:
    $recomended_sum

=cut
#**********************************************************
sub recomended_sum {
  my ($user_info, $attr) = @_;

  my $recomended_sum = '-0.00';

  my $cur_d = (split('-', $DATE))[2];
  return 0 if (!defined($user_info->{DEPOSIT}));

  my $service_info = get_services($user_info, {
    SKIP_MODULES            => 'Sqlcmd',
    MODULES                 => 'Triplay',
    SKIP_NEXT_MONTH_SERVICE => ($cur_d > 25) ? 0 : 22
  });

  my $triplay_status = $service_info->{list}->[0]->{STATUS} // -1;
  my $debug_info = q{};

  if ($debug > 0) {
    $debug_info = "// Triplay: status: $triplay_status";
  }

  # Not active
  if ($triplay_status == 2) {
    require Triplay;
    Triplay->import();

    my $Triplay = Triplay->new($db, $admin, \%conf);
    my $sum = $service_info->{list}->[0]->{SUM} || 0;

    # Make alignment for Triplay
    $Triplay->user_info({ UID => $user_info->{UID} });
    if ($Triplay->{TP_PERIOD_ALIGNMENT}) {
      my $days_in_month = days_in_month({ DATE => $DATE });
      my $calculation_days = ($cur_d < 1) ? 1 - $cur_d : $days_in_month - $cur_d + 1;
      $sum = sprintf("%.2f", ($sum / $days_in_month) * $calculation_days);
    }

    if ($cur_d > 25) {
      $recomended_sum = $sum + recomended_sum_default($user_info, $attr);
    }
    else {
      $recomended_sum = $sum - $user_info->{DEPOSIT};
      if ($debug > 0) {
        $debug_info .= ' pre 25';
      }
    }
  }
  #To smaall deposit
  elsif ($triplay_status == 5) {
    #Abon fees maked on period begin
    if ($cur_d < 25) {
      $attr->{SKIP_MODULES} = 'Abon';
      $attr->{SKIP_NEXT_MONTH_SERVICE}=1;
    }

    $recomended_sum = recomended_sum_default($user_info, $attr);

    if ($cur_d > 25) {
      $recomended_sum += $service_info->{list}->[0]->{SUM} || 0;
    }
    else {
      if ($debug > 0) {
        $debug_info .= ' pre 25';
      }
    }
  }
  #elsif ($triplay_status == 0) {
  else {
    if ($cur_d < 25) {
      $recomended_sum = ($user_info->{DEPOSIT} < 0) ? $recomended_sum + abs($user_info->{DEPOSIT}) : ($user_info->{DEPOSIT} > $recomended_sum) ? 0 : $recomended_sum - $user_info->{DEPOSIT};
      if ($debug > 0) {
        $debug_info .= ' pre 25';
      }
    }
    else {
      $recomended_sum = recomended_sum_default($user_info, $attr);
    }
  }

  if ($recomended_sum < 0) {
    $recomended_sum = 0;
  }
  elsif ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($conf{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum = sprintf('%.2f', $recomended_sum);

  ($debug_info)
    ? return $recomended_sum . "\n$debug_info\n"
    : return $recomended_sum;
}

#**********************************************************
=head1 recomended_sum($sum, $attr) - Format sum

  Arguments:
    $user_info
    $attr
      SKIP_MODULES

  Results:
    $recomended_sum

=cut
#**********************************************************
sub recomended_sum_default {
  my ($user_info, $attr) = @_;

  my $recomended_sum = '-0.00';

  if ($conf{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT}) {
    return 0 if (!defined($user_info->{DEPOSIT}));
    return ($user_info->{DEPOSIT} < 0) ? abs($user_info->{DEPOSIT}) : 0;
  }

  require Control::Services;
  my $service_info = get_services($user_info, {
    SKIP_MODULES            => $attr->{SKIP_MODULES} || 'Sqlcmd',
    SKIP_NEXT_MONTH_SERVICE => $attr->{SKIP_NEXT_MONTH_SERVICE}
  });

  $recomended_sum = $service_info->{total_sum} || 0;

  return 0 if ($conf{PAYSYS_NET_RECOMMENDED_SUM});

  return 0 if (!defined($user_info->{DEPOSIT}));

  if (!$attr->{SKIP_DEPOSIT_CHECK}) {
    $recomended_sum = ($user_info->{DEPOSIT} < 0) ? $recomended_sum + abs($user_info->{DEPOSIT}) : ($user_info->{DEPOSIT} > $recomended_sum) ? 0 : $recomended_sum - $user_info->{DEPOSIT};
  }

  if ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($conf{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum += ($conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} || 0);
  $recomended_sum = sprintf('%.2f', $recomended_sum);

  return $recomended_sum;
}

#**********************************************************
=head1 recomended_sum2($sum, $attr) - Format sum

  Arguments:
    $user_info
    $attr

  Results:
    well formated number

=cut
#**********************************************************
sub recomended_sum2 {
  my ($user_info, $attr) = @_;

  my $recomended_sum = '-0.00';

  if ($conf{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT}) {
    return 0 if (!defined($user_info->{DEPOSIT}));
    return ($user_info->{DEPOSIT} < 0) ? abs($user_info->{DEPOSIT}) : 0;
  }

  require Control::Services;
  my $service_info = get_services($user_info, { SKIP_MODULES => 'Sqlcmd' });

  $recomended_sum = $service_info->{total_sum} || 0;

  return 0 if ($conf{PAYSYS_NET_RECOMMENDED_SUM});

  return 0 if (!defined($user_info->{DEPOSIT}));

  if (!$attr->{SKIP_DEPOSIT_CHECK}) {
    $recomended_sum = ($user_info->{DEPOSIT} < 0) ? $recomended_sum + abs($user_info->{DEPOSIT}) : ($user_info->{DEPOSIT} > $recomended_sum) ? 0 : $recomended_sum - $user_info->{DEPOSIT};
  }

  if ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($conf{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum += ($conf{PAYSYS_ADD_TO_RECOMMENDED_SUMM} || 0);
  $recomended_sum = sprintf('%.2f', $recomended_sum);
  return $recomended_sum;
}

1;
