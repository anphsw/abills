package Mobile::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my $Mobile;
my $Services;

use Abills::Base qw/days_in_month in_array next_month/;

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

  use Mobile;
  $Mobile = Mobile->new($db, $admin, $CONF);

  use Mobile::Services;
  $Services = Mobile::Services->new($db, $admin, $CONF, { lang => $lang });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 mobile_docs($attr) - get services for invoice

  Arguments:
    UID
  Results:

=cut
#**********************************************************
sub mobile_docs {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my @services = ();
  my %info = ();
  my $uid = $attr->{UID} || $form->{UID};

  my $user_services = $Mobile->user_list({
    UID           => $uid,
    LOGIN         => '_SHOW',
    REDUCTION     => '_SHOW',
    REDUCTION_FEE => '_SHOW',
    TP_NAME       => '_SHOW',
    MONTH_FEE     => '!',
    TP_DISABLE    => '_SHOW',
    TP_ID         => '_SHOW',
    DISABLE       => 0,
    PAGE_ROWS     => 10000000,
    COLS_UPPER    => 1,
    COLS_NAME     => 1
  });

  foreach my $service (@{$user_services}) {
    next if !$service->{MONTH_FEE} || $service->{MONTH_FEE} eq '0.00';

    my %FEES_DSC = (
      MODULE          => 'Mobile',
      SERVICE_NAME    => $lang->{MOBILE_COMMUNICATION},
      TP_ID           => $service->{TP_ID},
      TP_NAME         => $service->{TP_NAME},
      FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
    );

    $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
    $info{service_desc} = q{};
    $info{tp_name} = $service->{TP_NAME};
    $info{status} = $service->{TP_DISABLE};
    # $info{day} = $service->{DAY_FEE};
    $info{month} = $service->{MONTH_FEE};

    if ($service->{TP_DISABLE} && $service->{TP_DISABLE} != 5 && $attr->{SKIP_DISABLED}) {
      $info{day} = 0;
      $info{month} = 0;
      $info{abon_distribution} = 0;
    }

    if ($attr->{FULL_INFO}) {
      push @services, { %info };
    }
    else {
      push @services, ::fees_dsc_former(\%FEES_DSC) . "||$service->{MONTH_FEE}||$service->{TP_NAME}";
    }
  }

  return \%info if $attr->{FEES_INFO};

  return \@services;
}


#**********************************************************
=head2 mobile_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO

=cut
#**********************************************************
sub mobile_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user;
  $user = $attr->{USER_INFO} if ($attr->{USER_INFO});

  my $list = $Mobile->user_list({
    UID          => $user->{UID},
    LOGIN        => '_SHOW',
    TP_ACTIVATE  => '_SHOW',
    DEPOSIT      => '_SHOW',
    REDUCTION    => '_SHOW',
    BILL_ID      => '_SHOW',
    CREDIT       => '_SHOW',
    MONTH_FEE    => '_SHOW',
    PAYMENT_TYPE => '_SHOW',
    TP_ID        => '!',
    TP_DISABLE   => '5',
    DISABLE      => 0,
    PAGE_ROWS    => 10000000,
    COLS_UPPER   => 1,
    COLS_NAME    => 1
  });
  return 0 if ($Mobile->{TOTAL} < 1);

  my $form = $attr->{FORM} || {};

  foreach my $user_service (@{$list}) {
    next if !defined $user_service->{MONTH_FEE};

    my $month_fee = ($user_service->{REDUCTION} && $user_service->{REDUCTION} > 0) ?
      $user_service->{MONTH_FEE} * (100 - $user_service->{REDUCTION}) / 100 : $user_service->{MONTH_FEE};
    if (($user_service->{PAYMENT_TYPE} && $user_service->{PAYMENT_TYPE} == 1) || $user_service->{DEPOSIT} + $user_service->{CREDIT} > $month_fee) {
      $Services->user_add_tp({ ID => $user_service->{ID}, CONTINUE_SUBSCRIPTION => 1 });
    }
  }

  return 1;
}

#**********************************************************
=head2 mobile_quick_info()

  Arguments:
     $attr
       UID

  Returns:

=cut
#**********************************************************
sub mobile_quick_info {
  shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID} || 0;

  $Mobile->user_list({ UID => $uid || 0, DISABLE => 0, COLS_NAME => 1 });

  return ($Mobile->{TOTAL} > 0) ? $Mobile->{TOTAL} : '';
}

#**********************************************************
=head2 mobile_user_services($attr) - Get user services

=cut
#**********************************************************
sub mobile_user_services {
  my $self = shift;
  my ($attr) = @_;

  return [] if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($db, $admin, $CONF);

  my $tariffs = $Service_control->services_info({
    UID             => $attr->{UID},
    MODULE          => 'Mobile',
    FUNCTION_PARAMS => {
      SERVICE_STATUS => '_SHOW',
      SERVICE_ID     => '_SHOW',
    }
  });

  return $tariffs;
}

1;
