package Control::Recommended_pay;
=head NAME

  Recommended payment sum calculation

=head DESCRIPTION

  This module provides functions for calculating recommended payment sums
  for users based on their services and deposit status.

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(days_in_month);

use Control::Services;

my Control::Services $Services;

#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  bless($self, $class);

  $Services = Control::Services->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 recomended_sum_triplay($user_info, $attr) - Extended recommended sum with Triplay logic

  Arguments:
    $user_info - User information hash
      UID
      DEPOSIT
    $attr - Attributes hash
      DEBUG
      SKIP_MODULES
      SKIP_NEXT_MONTH_SERVICE
      SKIP_ADD_SUM
      SKIP_DEPOSIT_CHECK
    $date - Calculation date (optional, defaults to $main::DATE)

  Results:
    $recomended_sum - Recommended payment sum

=cut
#**********************************************************
sub recomended_sum_triplay {
  my ($self, $user_info, $attr) = @_;

  my $recomended_sum = '-0.00';
  my $date = $attr->{DATE} || $main::DATE;

  my $cur_d = (split('-', $date))[2];
  return 0 if (!$user_info || !defined($user_info->{DEPOSIT}));
  my $service_info = $Services->get_services($user_info, {
    SKIP_MODULES            => 'Sqlcmd',
    MODULES                 => 'Triplay',
    SKIP_NEXT_MONTH_SERVICE => ($cur_d > 25) ? 0 : 22
  });

  my $triplay_status = $service_info->{list}->[0]->{STATUS} // -1;
  my $debug_info = q{};
  my $debug = $attr->{DEBUG} || 0;

  if ($debug > 0) {
    $debug_info = "// Triplay: status: $triplay_status";
  }

  # Not active
  if ($triplay_status == 2) {
    require Triplay;
    Triplay->import();

    my $Triplay = Triplay->new($self->{db}, $self->{admin}, $self->{conf});
    my $sum = $service_info->{list}->[0]->{SUM} || 0;

    # Make alignment for Triplay
    $Triplay->user_info({ UID => $user_info->{UID} });
    if ($Triplay->{TP_PERIOD_ALIGNMENT}) {
      my $days_in_month = days_in_month({ DATE => $date });
      my $calculation_days = ($cur_d < 1) ? 1 - $cur_d : $days_in_month - $cur_d + 1;
      $sum = sprintf("%.2f", ($sum / $days_in_month) * $calculation_days);
    }

    if ($cur_d > 25) {
      $attr->{DATE} = $date;
      $recomended_sum = $sum + $self->recomended_sum_default($user_info, $attr);
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
      $attr->{SKIP_NEXT_MONTH_SERVICE} = 1;
    }

    $attr->{DATE} = $date;
    $recomended_sum = $self->recomended_sum_default($user_info, $attr);

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
      $attr->{DATE} = $date;
      $recomended_sum = $self->recomended_sum_default($user_info, $attr);
    }
  }

  if ($recomended_sum < 0) {
    $recomended_sum = 0;
  }
  elsif ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($self->{conf}->{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum = sprintf('%.2f', $recomended_sum);

  if ($debug_info) {
    $recomended_sum .= "\n$debug_info\n";
  }

  return $recomended_sum;
}

#**********************************************************
=head2 recomended_sum_default($user_info, $attr) - Default recommended sum calculation

  Arguments:
    $user_info - User information hash
      UID
      DEPOSIT
    $attr - Attributes hash
      SKIP_MODULES
      SKIP_NEXT_MONTH_SERVICE
      SKIP_ADD_SUM
      SKIP_DEPOSIT_CHECK
    $date - Calculation date (optional, defaults to $main::DATE)

  Results:
    $recomended_sum - Recommended payment sum

=cut
#**********************************************************
sub recomended_sum_default {
  my ($self, $user_info, $attr) = @_;

  my $recomended_sum = '-0.00';
  return 0 if (!$user_info || !defined($user_info->{DEPOSIT}));

  if ($self->{conf}->{PAYSYS_RECOMMENDED_SUM_AS_DEPOSIT}) {
    return ($user_info->{DEPOSIT} < 0) ? sprintf('%.2f', abs($user_info->{DEPOSIT})) : 0;
  }

  my $service_info;
  if ($attr->{SERVICE_INFO}) {
    $service_info = $attr->{SERVICE_INFO};
  }
  else {
    $service_info = $Services->get_services($user_info, {
      SKIP_MODULES            => $attr->{SKIP_MODULES} || 'Sqlcmd',
      SKIP_NEXT_MONTH_SERVICE => $attr->{SKIP_NEXT_MONTH_SERVICE}
    });
  }

  $recomended_sum = $service_info->{total_sum} || 0;

  return 0 if ($self->{conf}->{PAYSYS_NET_RECOMMENDED_SUM});

  return 0 if (!defined($user_info->{DEPOSIT}));

  if (!$attr->{SKIP_DEPOSIT_CHECK}) {
    $recomended_sum = ($user_info->{DEPOSIT} < 0) ? $recomended_sum + abs($user_info->{DEPOSIT}) : ($user_info->{DEPOSIT} > $recomended_sum) ? 0 : $recomended_sum - $user_info->{DEPOSIT};
  }

  if ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($self->{conf}->{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum += ($self->{conf}->{PAYSYS_ADD_TO_RECOMMENDED_SUMM} || 0);
  $recomended_sum = sprintf('%.2f', $recomended_sum);

  return $recomended_sum;
}

#**********************************************************
=head2 recomended_sum_as_deposit($user_info, $attr) - Recommended sum as deposit calculation

  Arguments:
    $user_info - User information hash
      UID
      DEPOSIT
    $attr - Attributes hash
      CALCULATION_DATE
      SKIP_ADD_SUM
      SKIP_DEPOSIT_CHECK
    $date - Calculation date (optional, defaults to $main::DATE)

  Results:
    $recomended_sum - Recommended payment sum

=cut
#**********************************************************
sub recomended_sum_as_deposit {
  my ($self, $user_info, $attr) = @_;

  my $recomended_sum = '-0.00';
  my $date = $attr->{DATE} || $main::DATE;

  return 0 if (!$user_info || !defined($user_info->{DEPOSIT}));

  my $cur_d = (split('-', $date))[2];
  my $calculation_date = $attr->{CALCULATION_DATE} || 25;

  my $service_info = $Services->get_services($user_info, { SKIP_MODULES => 'Sqlcmd' });
  my $internet_status = 0;
  foreach my $k (@{ $service_info->{list} }) {
    if($k->{MODULE} eq 'Internet') {
      $internet_status=$k->{STATUS};
    }
  }

  if ($cur_d < $calculation_date && ! $internet_status) {
    return ($user_info->{DEPOSIT} < 0) ? sprintf('%.2f', abs($user_info->{DEPOSIT})) : 0;
  }

  $recomended_sum = $service_info->{total_sum} || 0;

  if (!$attr->{SKIP_DEPOSIT_CHECK}) {
    $recomended_sum = ($user_info->{DEPOSIT} < 0) ? $recomended_sum + abs($user_info->{DEPOSIT}) : ($user_info->{DEPOSIT} > $recomended_sum) ? 0 : $recomended_sum - $user_info->{DEPOSIT};
  }

  if ($recomended_sum > int($recomended_sum)) {
    $recomended_sum = sprintf('%.2f', int($recomended_sum));
    $recomended_sum += (($self->{conf}->{PAYSYS_DEBET_RECOMMENDED_SUM} || $attr->{SKIP_ADD_SUM}) && !$recomended_sum) ? 0 : 1;
  }

  $recomended_sum += ($self->{conf}->{PAYSYS_ADD_TO_RECOMMENDED_SUMM} || 0);
  $recomended_sum = sprintf('%.2f', $recomended_sum);
  return $recomended_sum;
}

1;

