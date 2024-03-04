package Mobile::Services;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;

use Control::Errors;
use Mobile;

my Mobile $Mobile;
my Control::Errors $Errors;
my $Lifecell;
my $Tariffs;

use Abills::Base qw/in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  $Mobile = Mobile->new($db, $admin, $conf);
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $attr->{lang}, module => 'Mobile' });

  use Mobile::Lifecell;
  $Lifecell = Mobile::Lifecell->new($db, $admin, $conf);

  use Tariffs;
  $Tariffs = Tariffs->new($db, $conf, $admin);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 phone_activate($attr)

  Arguments:
    $attr
=cut
#**********************************************************
sub phone_activate {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1640012) if !$attr->{ID};

  $Mobile->user_info($attr->{ID});
  return $Errors->throw_error(1640010) if !$Mobile->{DISABLE};

  if ($Mobile->{EXTERNAL_METHOD}) {
    if (in_array($Mobile->{EXTERNAL_METHOD}, ['partnerP2CConfirm', 'partnerActivationStandart'])) {
      return $Errors->throw_error(1640011);
    }
  }
  
  my $result = $Lifecell->phone_activate($Mobile);

  if ($result && $result->{operationResult} && $result->{operationResult}{resultCode}) {
    my $errstr = $result && $result->{operationResult} && $result->{operationResult}{resultDescription} ?
      $result->{operationResult}{resultDescription} : '';
    return $Errors->throw_error(1640004, { errstr => $errstr });
  }
  $result->{EXTERNAL_METHOD} = $Lifecell->{EXTERNAL_METHOD} if $Lifecell->{EXTERNAL_METHOD};

  if ($Lifecell->{TRANSACTION_ID}) {
    $Mobile->user_change({
      ID              => $attr->{ID},
      TRANSACTION_ID  => $Lifecell->{TRANSACTION_ID},
      EXTERNAL_METHOD => $result->{EXTERNAL_METHOD}
    });
  }
  return $result;
}

#**********************************************************
=head2 confirm_pin($attr)

=cut
#**********************************************************
sub confirm_pin {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1640012) if !$attr->{ID} || !$attr->{PIN};

  $Mobile->user_info($attr->{ID});

  if ($Mobile->{EXTERNAL_METHOD}) {
    if (in_array($Mobile->{EXTERNAL_METHOD}, ['partnerP2CConfirm', 'partnerActivationStandart'])) {
      return $Errors->throw_error(1640011);
    }
  }

  $Mobile->{PIN} = $attr->{PIN};
  my $result = $Lifecell->confirm_pin($Mobile);

  if ($result && $result->{operationResult} && $result->{operationResult}{resultCode}) {
    my $errstr = $result && $result->{operationResult} && $result->{operationResult}{resultDescription} ?
      $result->{operationResult}{resultDescription} : '';
    return $Errors->throw_error(1640004, { errstr => $errstr });
  }
  $result->{EXTERNAL_METHOD} = $Lifecell->{EXTERNAL_METHOD} if $Lifecell->{EXTERNAL_METHOD};

  if ($Lifecell->{TRANSACTION_ID}) {
    $Mobile->user_change({
      ID              => $attr->{ID},
      TRANSACTION_ID  => $Lifecell->{TRANSACTION_ID},
      EXTERNAL_METHOD => $result->{EXTERNAL_METHOD}
    });
  }
  return $result;
}

#**********************************************************
=head2 balance()

=cut
#**********************************************************
sub balance {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1640012) if !$attr->{ID};

  $Mobile->user_info($attr->{ID});

  my $result = $Lifecell->balance($Mobile);
  return $result if !$result || !$result->{operationResult};

  if ($result->{operationResult}{resultCode}) {
    my $errstr = $result && $result->{operationResult} && $result->{operationResult}{resultDescription} ?
      $result->{operationResult}{resultDescription} : '';
    return $Errors->throw_error(1640004, { errstr => $errstr });
  }

  return $Errors->throw_error(1640004) if !$result->{operationResult}{balances} || ref $result->{operationResult}{balances} ne 'ARRAY';

  my @skip_codes = ('Line_Main', 'Line_Bonus', 'Line_Debt');
  my @balances = ();
  foreach my $service (@{$result->{operationResult}{balances}}) {
    next if Abills::Base::in_array($service->{code}, \@skip_codes);

    my $amount = $service->{amount} || 0;
    my $measure = $service->{measureEN} || '';

    if ($measure eq 'Bytes') {
      $amount = Abills::Base::int2byte($amount);
    }
    elsif ($measure eq 'Sec.') {
      $amount = Abills::Base::sec2time($amount, { format => 1 });
    }

    my $service_info = {
      name_en    => $service->{nameEN},
      name_ru    => $service->{nameRU},
      name_ua    => $service->{nameUA},
      measure_en => $service->{measureEN},
      measure_ru => $service->{measureRU},
      measure_ua => $service->{measureUA},
      amount     => $amount
    };

    if (in_array($measure, ['Bytes', 'Sec.'])) {
      $service_info->{measure_en} = '';
      $service_info->{measure_ru} = '';
      $service_info->{measure_ua} = '';
    }

    push @balances, $service_info;
  }

  return $Errors->throw_error(1640005) if (!scalar(@balances));

  return { balances => \@balances };
}

#**********************************************************
=head2 user_add_tp()

=cut
#**********************************************************
sub user_add_tp {
  my $self = shift;
  my ($attr) = @_;

  my $user_info = $Mobile->user_info($attr->{ID});
  return $Errors->throw_error(1640007) if !$Mobile->{TOTAL} || $Mobile->{TOTAL} < 1 || !$user_info->{PHONE};
  if ($user_info->{TP_ID} && (!defined($attr->{STATUS}) || $attr->{STATUS} eq $user_info->{TP_STATUS})) {
    return $Errors->throw_error(1640006) if !$attr->{CONTINUE_SUBSCRIPTION};
  }

  $attr->{TP_ID} ||= $user_info->{TP_ID};
  my $tp_info = $Mobile->tariff_info({ ID => $attr->{TP_ID} });
  return $Errors->throw_error(1640008) if (!$Mobile->{TOTAL} || $Mobile->{TOTAL} < 1 || !$tp_info->{SERVICE_ID});

  $tp_info->{SERVICE_ID} =~ s/,/;/g;
  my $services = $Mobile->service_list({ ID => $tp_info->{SERVICE_ID}, NAME => '_SHOW', COLS_NAME => 1 });
  return $Errors->throw_error(1640009) if !$Mobile->{TOTAL} || $Mobile->{TOTAL} < 1;

  my $services_name = [];
  map push(@{$services_name}, $_->{name}), @{$services};
  my $lego_blocks = join(';', @{$services_name});

  if ($attr->{STATUS}) {
    $Mobile->user_change({ ID => $attr->{ID}, TP_ID => $attr->{TP_ID}, TP_STATUS => $attr->{STATUS} });
    return $Mobile;
  }

  my $result = $Lifecell->order_offer({ %{$user_info}, LEGO_BLOCKS => $lego_blocks });

  if ($result && $result->{operationResult} && defined($result->{operationResult}{resultCode})
    && !$result->{operationResult}{resultCode} && $Lifecell->{TRANSACTION_ID}) {
    $Mobile->user_change({
      ID              => $attr->{ID},
      TRANSACTION_ID  => $Lifecell->{TRANSACTION_ID},
      TP_ID           => $attr->{TP_ID},
      TP_STATUS       => $attr->{STATUS} || 0,
      EXTERNAL_METHOD => $Lifecell->{EXTERNAL_METHOD},
      TP_ACTIVATE     => '0000-00-00'
    });

    if (!$Mobile->{errno}) {
      $Mobile->user_info($attr->{ID});
      $Mobile->{TP_INFO} = $Tariffs->info($Mobile->{TP_ID});
      ::service_get_month_fee($Mobile, {
        SERVICE_NAME               => $self->{lang}{MOBILE_COMMUNICATION},
        DO_NOT_USE_GLOBAL_USER_PLS => 1,
        MODULE                     => 'Mobile',
        INNER_DESCRIBE             => $Lifecell->{TRANSACTION_ID},
        QUITE                      => $attr->{QUITE}
      });
    }
  }
  else {
    $Mobile->user_change({
      ID              => $attr->{ID},
      TP_ID           => $attr->{TP_ID},
      TP_STATUS       => 1,
      TP_ACTIVATE     => '0000-00-00'
    });

    my $errstr = $result && $result->{operationResult} && $result->{operationResult}{resultDescription} ?
      $result->{operationResult}{resultDescription} : '';
    return $Errors->throw_error(1640004, { errstr => $errstr });
  }

  return $result;
}
1;