=head1 NAME

 Periodic scripts

=cut

use strict;
use warnings FATAL => 'all';
use Bonus;

our(
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $DEBUG,
  $DATE,
  $TIME,
  %LIST_PARAMS,
  $users,
  %err_strs
);

my $Bonus = Bonus->new($db, $admin, \%conf);

#**********************************************************
=head2 bonus_periodic_daily($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub bonus_periodic_daily {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Bonus - Daily periodic\n" if ($debug > 1);

  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  my $periodic_date = $attr->{DATE} || $DATE;

  if ($conf{BONUS_RESET_PERIOD}) {
    $debug_output .= "Bonus - BONUS_RESET_PERIOD\n" if ($debug > 1);
    $Bonus->{debug} = 1 if ($debug > 6);
    my $reset_list = $Bonus->accomulation_reset_list({
      RESET_PERIOD => $conf{BONUS_RESET_PERIOD},
      COLS_NAME    => 1
    });

    foreach my $u (@$reset_list) {
      $Bonus->accomulation_scores_change({
        UID   => $u->{uid},
        SCORE => 0
      });
    }
  }

  if ($conf{BONUS_PAYMENTS}) {
    return $debug_output
  }
  # Accomulation reset
  elsif ($conf{BONUS_ACCOMULATION}) {
    $debug_output .= "Bonus - BONUS_ACCOMULATION\n" if ($debug > 1);
    my $reset_list = $users->list({
      DEPOSIT        => '<0',
      DISABLE        => '1',
      _MULTI_HIT     => 1,
      COLS_NAME      => 1,
      SKIP_DEL_CHECK => 1,
      PAGE_ROWS      => 1000000,
    });

    foreach my $u (@$reset_list) {
      if ($u && $u->{uid}) {
        $Bonus->accomulation_scores_change({
          UID   => $u->{uid},
          SCORE => 0
        });
      }
    }
  }

  #del expired bonus list expire
  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});

  $Bonus->{debug} = 1 if ($debug > 6);

  my $bonus_operation_list = $Bonus->bonus_operation_list({
    EXPIRE      => $periodic_date,
    DEPOSIT     => '>0',
    SUM         => '_SHOW',
    BILL_ID     => '_SHOW',
    EXT_BILL_ID => '_SHOW',
    EXPIRE      => '_SHOW',
    PAGE_ROWS   => 1000000,
    COLS_NAME   => 1,
    %LIST_PARAMS
  });

  my %last_deposits = ();
  foreach my $line (@{$bonus_operation_list}) {
    if ($line->{login}) {
      my $sum = $line->{sum};
      my %user = (
        EXT_BILL_ID => $line->{ext_bill_id} || $line->{bill_id},
        UID         => $line->{uid},
        DEPOSIT     => $line->{deposit},
        BILL_ID     => $line->{bill_id}
      );

      my $deposit = ($last_deposits{ $user{UID} }) ? $last_deposits{ $user{UID} } : $user{DEPOSIT};
      $debug_output .= "LOGIN: $line->{login} [$user{UID}] DEPOSIT: $deposit SUM: $sum EXPIRE: $line->{expire} BILL_ID: $line->{bill_id} ADD DATE: $line->{date}\n" if ($debug > 1);

      if ($sum > $deposit) {
        $sum = $deposit;
      }

      next if ($sum <= 0);

      $Bonus->bonus_operation(
        \%user,
        {
          ACTION_TYPE => 1,
          SUM         => $sum,
          DESCRIBE    => "$lang{EXPIRE} ID: $line->{id}",
        }
      );

      if ($Bonus->{errno}) {
        print "LOGIN: $line->{login} [$user{UID}] [$Bonus->{errno}] $err_strs{$Bonus->{errno}}\n";
      }
      else {
        $last_deposits{ $user{UID} } = ($last_deposits{ $user{UID} }) ? $last_deposits{ $user{UID} } -= $sum : $user{DEPOSIT} -= $sum;
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 bonus_periodic_monthly($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub bonus_periodic_monthly {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Bonus - Monthly periodic\n" if ($debug > 1);

  if ($conf{BONUS_PAYMENTS}) {
    $debug_output .= "BONUS_PAYMENTS: \$conf{BONUS_PAYMENTS}\n";
    return $debug_output;
  }

  if ($conf{BONUS_ACCOMULATION}) {
    $debug_output .= bonus_periodic_accomulation($attr)
  }

  $DEBUG .= $debug_output;

  return $debug_output;
}


#**********************************************************
=head2 bonus_periodic_accomulation($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub bonus_periodic_accomulation {
  my ($attr) = @_;
  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  $debug_output .= "Bonus - Accoumulation\n" if ($debug > 1);

  my $date = $DATE;

  if ($attr->{DATE}) {
    $date = $attr->{DATE};
  }

  my $D = (split(/-/x, $date))[2];

  if ($D != 1) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});

  $Bonus->{debug} = 1 if ($debug > 6);
  my $tp_list = $Bonus->accomulation_rule_list({
    COST      => '>0',
    COLS_NAME => 1
  });

  foreach my $tp (@{$tp_list}) {
    $debug_output .= "TP ID: $tp->{tp_id} DV TP: $tp->{dv_tp_id} COST: $tp->{cost}\n" if ($debug > 1);
    my $list = $Bonus->user_list({
      LOGIN     => '_SHOW',
      DV_TP_ID  => $tp->{dv_tp_id},
      TP_ID     => $tp->{tp_id},
      COLS_NAME => 1,
      DEPOSIT   => '>=0',
      %LIST_PARAMS,
      PAGE_ROWS => 1000000,
    });

    foreach my $user (@{$list}) {
      $user->{cost} = 0 if (!$user->{cost});
      $debug_output .= "$user->{login}:$user->{uid} SCORE: $user->{cost}  \n" if ($debug > 1);
      if ($debug < 5) {
        $Bonus->accomulation_scores_change({
          UID      => $user->{uid},
          SCORE    => $user->{cost} + $tp->{cost},
          DV_TP_ID => 0
        });
      }
    }
  }

  return $debug_output;
}


1;