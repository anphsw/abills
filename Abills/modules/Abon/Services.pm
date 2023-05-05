package Abon::Services;
use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my %lang;
my $DATE;
my Abon $Abon;

use Fees;
use Abills::Base qw/days_in_month date_diff/;
do 'Abills/Misc.pm';

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  %lang = %{ $attr->{LANG} } if ($attr->{LANG});

  my $self = {};

  require Abon;
  Abon->import();
  $Abon = Abon->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 abon_service_activate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
        UID
        ID
      DEBUG
      DATE
      SERVICE_RECOVERY

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub abon_service_activate {
  my $self = shift;
  my ($attr)=@_;

  my $user_info = $attr->{USER_INFO};
  my $debug = $attr->{DEBUG} || 0;
  my $date = $attr->{DATE} || $DATE;

  my $user_tariff_list = $Abon->user_tariff_list($user_info->{UID}, {
    PERIOD_ALIGNMENT => '_SHOW',
    COLS_NAME        => 1,
    SERVICE_RECOVERY => (defined($attr->{SERVICE_RECOVERY})) ? $attr->{SERVICE_RECOVERY} : '_SHOW',
  });

  foreach my $service ( @$user_tariff_list ) {
    if (! $service->{date}) { # || ! $user->{period}) { #day activate too
      next;
    }
    elsif ($service->{next_abon} && date_diff($service->{next_abon}, $date) < 0) {
      next;
    }

    $service->{TP_INFO}->{PERIOD_ALIGNMENT} = $service->{period_alignment} || 0;
    $service->{TP_INFO}->{TP_ID} = $service->{id};
    $service->{TP_INFO}->{TP_NAME} = $service->{tp_name};
    $service->{TP_INFO}->{PRICE} = $service->{price};
    $service->{UID} = $user_info->{UID};
    $service->{BILL_ID} = $user_info->{BILL_ID};
    $service->{ACTIVATE} = ($service->{service_recovery} && $service->{service_recovery} == 1) ? q{0000-00-00} : $service->{next_abon}; #Last abon fee

    my $message = $self->abon_get_month_fee($service, {
      SHOW_SUM  => $debug,
      USER_INFO => $user_info,
      DATE      => $date
    });

    $Abon->user_tariff_change({
      ACTIVATE  => $service->{TP_INFO}->{TP_ID},
      UID       => $service->{UID},
      ABON_DATE => $date,
    });

    print $message if($debug > 1);
  }

  return 1;
}

#**********************************************************
=head2 abon_service_deactivate($attr)

  Arguments:
    $attr
      TP_INFO
      USER_INFO
      DEBUG
      STATUS - Disable status

=cut
#**********************************************************
sub abon_service_deactivate {
  my $self = shift;
  my ($attr)=@_;

  my $debug_output = q{};
  my $user_info = $attr->{USER_INFO};
  my $debug = $attr->{DEBUG} || 0;
  my $date = $attr->{DATE} || $DATE;
  my (undef, undef, $d)=split(/\-/, $date);
  my $user_tariff_list = $Abon->user_tariff_list($user_info->{UID}, {
    SERVICE_RECOVERY => '_SHOW',
    COLS_NAME        => 1
  });

  foreach my $user ( @$user_tariff_list ) {
    if (! $user->{date} || ! $user->{period}) {
      next;
    }

    my $days_in_month = days_in_month({ DATE => $date });
    my $days = $days_in_month - $d + 1;

    my $sum = $user->{price} / $days_in_month * $days;
    if ($sum > 0) {
      require Payments;
      my $Payments = Payments->new($db, $admin, $CONF);
      $Payments->add({
        BILL_ID  => $user_info->{BILL_ID},
        UID      => $user_info->{UID}
      },
        {
          SUM      => $sum,
          METHOD   => 6,
          DESCRIBE => "$lang{COMPENSATION}. $lang{DAYS}:" .
            "$date/$user->{next_abon} ($days)" . (($attr->{DESCRIBE}) ? ". $attr->{DESCRIBE}" : ''),
          INNER_DESCRIBE => $attr->{INNER_DESCRIBE}
        }
      );
    }
  }

  return $debug_output;
}

#**********************************************************
=head2 abon_get_month_fee($Abon, $attr)

  Arguments:
    $Abon
    $attr
       SHOW_SUM
       USER_INFO
       DATE

=cut
#**********************************************************
sub abon_get_month_fee {
  my $self = shift;
  my Abon $Service = shift;
  my ($attr) = @_;

  my $Fees = Fees->new($db, $admin, $CONF);
  my $TIME = "00:00:00";

  my %FEES_DSC = (
    MODULE            => 'Abon',
    TEMPLATE_KEY_NAME => 'ABON_FEES_DSC',
    TEMPLATE          => $CONF->{ABON_FEES_DSC},
    SERVICE_NAME      => $lang{EXT_SERVICES},
    TP_ID             => $Service->{TP_INFO}->{TP_ID},
    TP_NAME           => $Service->{TP_INFO}->{TP_NAME},
    EXTRA             => '',
  );

  my $message = '';
  # If zero price, should do nothing
  return '' if (! $Service->{TP_INFO}->{PRICE} || $Service->{TP_INFO}->{PRICE} <= 0);

  my $users = $attr->{USER_INFO};

  #Get month fee
  my $sum = $Service->{TP_INFO}->{PRICE};
  my $user = $users->info($Service->{UID});

  if ($Service->{TP_INFO}->{EXT_BILL_ACCOUNT}) {
    $user->{BILL_ID} = $user->{EXT_BILL_ID};
    $user->{DEPOSIT} = $user->{EXT_DEPOSIT};
  }

  #Current Month
  my $cur_date = $attr->{DATE} || $DATE;
  my ($y, $m, $d) = split(/-/, $cur_date, 3);
  my ($active_y, $active_m, $active_d) = split(/-/, $Service->{ACTIVATE} || '0000-00-00', 3);

  if (int("$y$m$d") < int("$active_y$active_m$active_d")) {
    return '';
  }

  if ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) {
    my $days_in_month = days_in_month({ DATE => "$y-$m" });

    if ($Service->{ACTIVATE} && $Service->{ACTIVATE} ne '0000-00-00') {
      $days_in_month = days_in_month({ DATE => "$active_y-$active_m" });
      $d = $active_d;
    }

    $CONF->{START_PERIOD_DAY} = 1 if (!$CONF->{START_PERIOD_DAY});

    if ($d != $CONF->{START_PERIOD_DAY}) {
      $FEES_DSC{EXTRA} .= " $lang{PERIOD_ALIGNMENT}\n";
      $sum = sprintf("%.2f", $sum / $days_in_month * ($days_in_month - $d + $CONF->{START_PERIOD_DAY}));
    }
  }

  return 0 if ($sum == 0);

  my $periods = 0;
  if (int($active_m) > 0 && int($active_m) < int($m) && int($active_y) < ($y)) {
    $periods = $m - $active_m;
    if (int($active_d) > int($d)) {
      $periods--;
    }

    $periods += 12 * ($y - $active_y) - 12 if ($y - $active_y);
  }
  elsif (int($active_m) > 0 && (int($active_m) >= int($m) && int($active_y) < int($y))) {
    $periods = 12 - $active_m + $m;
    if (int($active_d) > int($d)) {
      $periods--;
    }

    $periods += 12 * ($y - $active_y) - 12 if ($y - $active_y);
  }

  for (my $i = 0; $i <= $periods; $i++) {
    if ($active_m > 12) {
      $active_m = 1;
      $active_y = $active_y + 1;
    }

    $active_m = sprintf("%.2d", $active_m);
    #my $days_in_month = days_in_month({ DATE => "$active_y-$active_m" });
    if ($i > 0) {
      $sum  = $Service->{TP_INFO}->{PRICE};
      $DATE = "$active_y-$active_m-01";
      $TIME = "00:00:00";
    }
    elsif ($Service->{ACTIVATE} && $Service->{ACTIVATE} ne '0000-00-00') {
      $DATE = "$active_y-$active_m-$active_d";
      $TIME = "00:00:00";
    }

    if ($Service->{COMMENTS}) {
      $FEES_DSC{EXTRA} .= $Service->{COMMENTS};
    }

    #add period
    $FEES_DSC{PERIOD} = get_period_dates({
      TYPE             => 1,
      START_DATE       => $DATE || $cur_date,
      PERIOD_ALIGNMENT => $Service->{TP_INFO}->{PERIOD_ALIGNMENT},
      ACCOUNT_ACTIVATE => $DATE #$Service->{ACTIVATE}
    });

    $message = fees_dsc_former(\%FEES_DSC);

    my $fees_message = $message;
    $fees_message =~ s/\n//g;

    $Fees->take($users, $sum, {
      DESCRIBE => $fees_message,
      METHOD   => $Service->{TP_INFO}->{FEES_TYPE},
      DATE     => "$cur_date $TIME"
    });

    if ($attr->{SHOW_SUM}) {
      $attr->{FORM}{OPERATION_SUM} = $sum;
      $attr->{FORM}{OPERATION_DESCRIBE} = $fees_message;
    }

    $self->{OPERATION_SUM}=sprintf("%.2f", $sum);
    $self->{OPERATION_DESCRIBE}.=$fees_message ." $self->{OPERATION_SUM} \n";

    if (_error_show($Fees)) {
      $message = '';
    }

    $active_m++;
  }

  return $message;
}

1;