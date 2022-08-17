package Internet::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
#my $json;
my Abills::HTML $html;
my $lang;
my $Internet;
our $DATE;

use Abills::Base qw(in_array days_in_month next_month date_diff time2sec);

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

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Internet;
  Internet->import();
  $Internet = Internet->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head iptv_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID
      LOGIN

=cut
#**********************************************************
sub internet_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $result;
  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Internet->user_list({
      UID                => $uid,
      TP_NAME            => '_SHOW',
      MONTH_FEE          => '_SHOW',
      DAY_FEE            => '_SHOW',
      CID                => '_SHOW',
      TP_COMMENTS        => '_SHOW',
      INTERNET_STATUS    => '_SHOW',
      INTERNET_STATUS_ID => '_SHOW',
      IP                 => '_SHOW',
      COLS_NAME          => 1,
      COLS_UPPER         => 1
    });

    $result = $list->[0];
    my $service_status = ::sel_status({ HASH_RESULT => 1 });
    $result->{STATUS} = (defined($result->{INTERNET_STATUS})) ? $service_status->{ $result->{INTERNET_STATUS} } : '';
    ($result->{STATUS}, undef) = split(/:/, $result->{STATUS});
    $result->{PERIOD} = $lang->{MONTH};

    if (!$result->{MONTH_FEE} && $result->{DAY_FEE}) {
      $result->{MONTH_FEE} = $result->{DAY_FEE};
      $result->{PERIOD} = $lang->{DAY};
    }

    return $result;
  }
  elsif ($attr->{GET_PARAMS}) {
    $result = {
      HEADER    => $lang->{INTERNET},
      QUICK_TPL => 'internet_qi_box',
      FIELDS    => {
        TP_NAME            => $lang->{TARIF_PLAN},
        CID                => 'CID',
        IP                 => 'IP',
        STATUS             => $lang->{STATUS},
        INTERNET_STATUS_ID => "$lang->{STATUS} ID",
        MONTH_FEE          => $lang->{MONTH_FEE},
        TP_COMMENTS        => $lang->{COMMENTS},
        PERIOD             => $lang->{MONTH}
      }
    };

    return $result;
  }

  $Internet->user_list({
    UID       => $uid,
    LOGIN     => (!$uid && $attr->{LOGIN}) ? $attr->{LOGIN} : undef,
    COLS_NAME => 1,
  });

  return ($Internet->{TOTAL_SERVICES} && $Internet->{TOTAL_SERVICES} > 0) ? $Internet->{TOTAL_SERVICES} : '';
}

sub internet_docs {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || '';
  my @services = ();
  my %info = ();
  our %FEES_METHODS;

  my $service_list = $Internet->user_list({
    UID               => $uid,
    MONTH_FEE         => '_SHOW',
    DAY_FEE           => '_SHOW',
    PERSONAL_TP       => '_SHOW',
    INTERNET_STATUS   => '_SHOW',
    ABON_DISTRIBUTION => '_SHOW',
    TP_NAME           => '_SHOW',
    FEES_METHOD       => '_SHOW',
    TP_ID             => '_SHOW',
    TP_NUM            => '_SHOW',
    TP_FIXED_FEES_DAY => '_SHOW',
    INTERNET_ACTIVATE => '_SHOW',
    INTERNET_EXPIRE   => '_SHOW',
    TP_REDUCTION_FEE  => '_SHOW',
    CPE_MAC           => '_SHOW',
    CID               => '_SHOW',
    GROUP_BY          => 'internet.id',
    COLS_NAME         => 1
  });

  if ($attr->{FEES_INFO} || $attr->{FULL_INFO}) {
    foreach my $service_info (@{$service_list}) {
      my %FEES_DSC = (
        MODULE          => 'Internet',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
      $info{service_desc} = q{};
      $info{tp_name} = $service_info->{tp_name};
      $info{service_activate} = $service_info->{internet_activate};
      $info{service_expire} = $service_info->{internet_expire};
      $info{tp_fixed_fees_day} = $service_info->{tp_fixed_fees_day} || 0;
      $info{status} = $service_info->{internet_status};
      $info{tp_reduction_fee} = $service_info->{tp_reduction_fee};
      $info{module_name} = $lang->{INTERNET};
      $info{extra}{cpe_mac} = $lang->{CPE_MAC};
      $info{extra}{cid} = $lang->{CID};

      if ($service_info->{internet_status} && $service_info->{internet_status} != 5 && $attr->{SKIP_DISABLED}) {
        $info{day} = 0;
        $info{month} = 0;
        $info{abon_distribution} = 0;
      }
      else {
        if ($service_info->{personal_tp} && $service_info->{personal_tp} > 0) {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{personal_tp};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
        else {
          $info{day} = $service_info->{day_fee};
          $info{month} = $service_info->{month_fee};
          $info{abon_distribution} = $service_info->{abon_distribution};
        }
      }

      return \%info if (!$attr->{FULL_INFO});

      push @services, { %info };
    }
  }

  if ($attr->{FULL_INFO} || $Internet->{TOTAL} < 1) {
    return \@services;
  }

  foreach my $service_info (@$service_list) {
    if ($service_info->{internet_status} && $service_info->{internet_status} != 5 && !$attr->{SHOW_ALL}) {
      next
    }

    if ($service_info->{personal_tp} && $service_info->{personal_tp} > 0) {
      $service_info->{month_fee} = $service_info->{personal_tp};
    }

    if ($service_info->{month_fee} && $service_info->{month_fee} > 0) {
      my %FEES_DSC = (
        MODULE          => 'Internet',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $FEES_METHODS{$service_info->{fees_method}} : undef,
      );

      #Fixme / make hash export
      push @services, ::fees_dsc_former(\%FEES_DSC) . "||$service_info->{month_fee}|$service_info->{tp_num}|$service_info->{tp_name}"
        . "|$service_info->{fees_method}|$service_info->{internet_activate}|$service_info->{internet_status}";
    }

    if ($service_info->{day_fee} && $service_info->{day_fee} > 0) {

      my $days_in_month = days_in_month({ DATE => next_month({ DATE => $main::DATE }) });
      # Describe| days | sum
      push @services, "Internet: $lang->{MONTH_FEE_SHORT}: $service_info->{tp_name} ($service_info->{tp_id})|$days_in_month $lang->{DAY}|"
        . sprintf("%.2f", ($service_info->{day_fee} * $days_in_month)) . "||$service_info->{tp_name}"
        . "|$service_info->{fees_method}|$service_info->{internet_activate}";
    }
  }

  return \@services;
}

#**********************************************************
=head2 internet_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

=cut
#**********************************************************
sub internet_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  $attr->{DO_NOT_USE_GLOBAL_USER_PLS} = 1;
  my $user;

  $user = $attr->{USER_INFO} if ($attr->{USER_INFO});
  # return '' if ($FORM{DISABLE});

  my $service_list = $Internet->user_list({
    UID       => $user->{UID},
    TP_NUM    => '>0',
    GROUP_BY  => 'internet.id',
    COLS_NAME => 1
  });

  foreach my $service (@$service_list) {
    $Internet->user_info($user->{UID}, { ID => $service->{id} });

    if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
      $Internet->{MONTH_ABON} = $Internet->{PERSONAL_TP};
    }

    my $deposit = (defined($user->{DEPOSIT})) ? $user->{DEPOSIT} + (($user->{CREDIT} > 0) ? $user->{CREDIT} : $Internet->{TP_CREDIT}) : 0;

    my $abon_fees = ($user->{REDUCTION} == 0) ? $Internet->{MONTH_ABON} + $Internet->{DAY_ABON} : ($Internet->{MONTH_ABON} + $Internet->{DAY_ABON}) * (100 - $user->{REDUCTION}) / 100;

    if ($CONF->{INTERNET_FULL_MONTH}) {
      $abon_fees = ($user->{REDUCTION} == 0) ? $Internet->{MONTH_ABON} + $Internet->{DAY_ABON} * 30 : ($Internet->{MONTH_ABON} + $Internet->{DAY_ABON} * 30) * (100 - $user->{REDUCTION}) / 100;
    }
    elsif ($Internet->{ABON_DISTRIBUTION}) {
      my $days_in_month = days_in_month({ DATE => $DATE });
      $abon_fees = ($Internet->{MONTH_ABON} / $days_in_month) + $Internet->{DAY_ABON};
    }

    #OLd method. Always change activate period with payments
    #@deprecated
    if ($CONF->{payment_chg_activate} && $Internet->{SERVICE_ACTIVATE} ne '0000-00-00') {
      if ($CONF->{payment_chg_activate} ne 2 || date_diff($Internet->{SERVICE_ACTIVATE}, $main::DATE) > 30) {
        $Internet->user_change({
          ACTIVATE => $main::DATE,
          UID      => $user->{UID},
          ID       => $Internet->{ID},
        });
      }
    }

    if ($user->{REDUCTION} && $user->{REDUCTION} > 0) {
      $abon_fees = $abon_fees * (100 - $user->{REDUCTION}) / 100;
    }

    if (in_array($Internet->{STATUS}, [ 4, 5 ]) && $deposit > $abon_fees) {
      my %params = ();
      if ($CONF->{INTERNET_CUSTOM_PERIOD}) {
        if ($deposit >= $Internet->{TP_CHANGE_PRICE}) {
          if ($Internet->{TP_AGE}) {
            my ($y, $m, $d) = split(/-/, $main::DATE);
            $params{SERVICE_EXPIRE} = POSIX::strftime("%Y-%m-%d",
              localtime(POSIX::mktime(0, 0, 0, $d, ($m - 1), ($y - 1900), 0, 0, 0) + $Internet->{TP_AGE} * 86400));

            my $Fees = Fees->new($db, $admin, $CONF);
            $Fees->take($user, $Internet->{TP_CHANGE_PRICE}, { DESCRIBE => $lang->{ACTIVATE_TARIF_PLAN} });
            $service->{DESCRIBE} = ($Internet->{TP_NAME} || "") . " $lang->{SUM}: $Internet->{TP_CHANGE_PRICE}";
            $html->message('info', "$lang->{ACTIVATE} $lang->{INTERNET}", $service->{DESCRIBE});
          }
        }
        else {
          return 1;
        }
      }

      $Internet->user_change({
        UID    => $user->{UID},
        ID     => $Internet->{ID},
        STATUS => 0,
        %params
      });

      if ($CONF->{INTERNET_FULL_MONTH} && $Internet->{OLD_STATUS} && $Internet->{OLD_STATUS} == 5) {
        $attr->{FULL_MONTH_FEE} = 1;
      }

      #$Internet->{ACCOUNT_ACTIVATE} = $user->{ACTIVATE} || '0000-00-00';
      $CONF->{MONTH_FEE_TIME} = '01:00:00';

      #Skip month fee before month periodic
      if ($CONF->{MONTH_FEE_TIME}) {
        my $start_day = $CONF->{START_PERIOD_DAY} || 1;
        my (undef, undef, $d) = split(/\-/, $main::DATE, 3);
        if ($start_day == $d && time2sec($main::TIME) < time2sec($CONF->{MONTH_FEE_TIME})) {
          $attr->{SHEDULER} = 1;
        }
      }
      ::service_get_month_fee($Internet, $attr);
    }
    elsif ($CONF->{INTERNET_PAY_ACTIVATE}) {
      my $sum = $attr->{SUM} || 0;
      if ($Internet->{SERVICE_ACTIVATE} ne '0000-00-00' && date_diff($Internet->{SERVICE_ACTIVATE}, $main::DATE) > 30
        && $deposit - $sum <= 0 && $deposit > $abon_fees) {
        #&& $deposit - $sum <= 0 && $deposit > 0) {

        my %service_params = (
          UID              => $user->{UID},
          ID               => $Internet->{ID},
          STATUS           => 0,
          SERVICE_ACTIVATE => $main::DATE
        );

        if ($Internet->{STATUS}) {
          $service_params{STATUS} = 0;
        }

        $Internet->user_change(\%service_params);
        ::service_get_month_fee($Internet, $attr);
      }
      #service_get_month_fee($Internet, $attr);
    }
  }

  return 1;
}

1;