=head1 NAME

  Mobile Periodic

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(days_in_month in_array sendmail sec2time);
use Mobile;

our (
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  %lang,
);

our Abills::HTML $html;
use Fees;
use Mobile;
use Tariffs;
use Mobile::Services;

my $Mobile = Mobile->new($db, $admin, \%conf);
my $Fees = Fees->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);

my $Services = Mobile::Services->new($db, $admin, \%conf, { lang => \%lang });

#**********************************************************
=head2 mobile_monthly_fees($attr) - monthly fees

=cut
#**********************************************************
sub mobile_monthly_fees {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my @debug_output = ();
  push(@debug_output, "Mobile: Monthly periodic payments") if ($debug > 1);

  $LIST_PARAMS{ID} = $attr->{TP_ID} if $attr->{TP_ID};
  my %MOBILE_LIST_PARAMS = ();
  $MOBILE_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if $attr->{LOGIN};
  $MOBILE_LIST_PARAMS{EXT_BILL} = 1 if $conf{BONUS_EXT_FUNCTIONS};

  $ADMIN_REPORT{DATE} = $DATE if !$ADMIN_REPORT{DATE};
  my ($y, $m, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);

  $Mobile->{debug} = 1 if $debug > 6;

  my $FEES_METHODS = get_fees_types({ SHORT => 1 });
  my $tariff_plans = $Tariffs->list({
    %LIST_PARAMS,
    EXT_BILL_ACCOUNT     => '_SHOW',
    EXT_BILL_FEES_METHOD => '_SHOW',
    MODULE               => 'Mobile',
    COLS_NAME            => 1,
    COLS_UPPER           => 1
  });

  my $date_unixtime = POSIX::mktime(0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0);

  foreach my $tp (@{$tariff_plans}) {
    my $postpaid = $tp->{POSTPAID_MONTHLY_FEE} || $tp->{PAYMENT_TYPE};

    my $users_list = $Mobile->user_list({
      UID                            => '_SHOW',
      LOGIN                          => '_SHOW',
      TP_ACTIVATE                    => '_SHOW',
      DEPOSIT                        => '_SHOW',
      REDUCTION                      => '_SHOW',
      BILL_ID                        => '_SHOW',
      CREDIT                         => '_SHOW',
      USERS_ACTIVE_SINCE_30_DAYS_AGO => $ADMIN_REPORT{DATE},
      TP_ID                          => $tp->{TP_ID},
      TP_DISABLE                     => 0,
      DISABLE                        => 0,
      PAGE_ROWS                      => 10000000,
      COLS_UPPER                     => 1,
      COLS_NAME                      => 1
    });

    foreach my $user (@{$users_list}) {
      next if $user->{EXTERNAL_METHOD};

      push @debug_output, " Login: $user->{LOGIN} ($user->{UID}) REDUCTION: $user->{REDUCTION} " .
        "DEPOSIT: $user->{DEPOSIT} CREDIT $user->{CREDIT} ACTIVE: $user->{TP_ACTIVATE}" if ($debug > 3);

      my %FEES_DSC = (
        MODULE            => 'Mobile',
        SERVICE_NAME      => 'Mobile',
        TP_NUM            => $tp->{ID},
        TP_ID             => $tp->{TP_ID},
        TP_NAME           => $tp->{NAME},
        FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
        ID                => ($user->{ID}) ? ' ' . $user->{ID} : undef,
      );

      my %FEES_PARAMS = (
        DESCRIBE => fees_dsc_former(\%FEES_DSC),
        DATE     => $ADMIN_REPORT{DATE},
        METHOD   => $tp->{FEES_METHOD} || 1
      );

      if (!$user->{BILL_ID} && !defined($user->{DEPOSIT})) {
        $Mobile->user_change({ ID => $user->{ID}, TP_STATUS => 5 });
        print "[ $user->{UID} ] $user->{LOGIN} - Don't have money account\n";
        next;
      }

      my $month_fee = ($user->{REDUCTION} && $user->{REDUCTION} > 0) ? $tp->{MONTH_FEE} * (100 - $user->{REDUCTION}) / 100 : $tp->{MONTH_FEE};
      if ($postpaid == 1 || $user->{DEPOSIT} + $user->{CREDIT} > $month_fee) {
        my $result = $Services->user_add_tp({ ID => $user->{ID}, CONTINUE_SUBSCRIPTION => 1, QUITE => 1 });

        if ($result && $result->{errno}) {
          my $errstr = $result->{errstr} || '';
          push @debug_output, "Error Login: $user->{LOGIN} ($user->{ID}) $errstr";
        }
        else {
          push @debug_output, " $user->{LOGIN} UID: $user->{UID} SUM: $month_fee REDUCTION: $user->{REDUCTION} CHANGE ACTIVATE" if ($debug > 0);
        }
      }
      else {
        $Mobile->user_change({ ID => $user->{ID}, TP_STATUS => 5, TP_ACTIVATE => '0000-00-00' });
        push @debug_output, "Block negative Login: $user->{LOGIN} ($user->{ID}) // $user->{DEPOSIT} + $user->{CREDIT} > 0";
      }
    }
  }

  $DEBUG = join("\n", @debug_output);
  return $DEBUG;
}

1;