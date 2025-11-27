package Abon::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $html;
my $lang;
my Abon $Abon;

use Abills::Base qw/days_in_month in_array date_diff/;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

  Arguments:
    $db
    $admin
    $CONF
    $attr
      HTML
      LANG

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if ($attr->{HTML});
  $lang = $attr->{LANG} if ($attr->{LANG});

  my $self = {};
  $CONF->{ABON_FEES_DSC} //= '%SERVICE_NAME%: %PERIOD% %TP_NAME% (%TP_ID%) %EXTRA%';

  require Abon;
  Abon->import();
  $Abon = Abon->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 abon_docs($attr) - get services for invoice

  Arguments:
    $attr
      FULL_INFO
      PAYMENT_TYPE
      FEES_INFO

=cut
#**********************************************************
sub abon_docs {
  my ($self, $attr) = @_;

  my $form = $attr->{FORM} || {};
  my @services = ();
  my $uid = $attr->{UID} || $form->{UID};

  my $abon_list = $Abon->user_tariff_list($uid, {
    PAYMENT_TYPE     => $attr->{PAYMENT_TYPE},
    TP_REDUCTION_FEE => '_SHOW',
    DISCOUNT_ACTIVATE=> '_SHOW',
    DISCOUNT_EXPIRE  => '_SHOW',
    COLS_NAME        => 1
  });

  my %info = ();
  foreach my $service_info (@{$abon_list}) {
    %info = ();
    next if (!$service_info->{date});
    my $discount = $service_info->{discount} || 0;

    if ($discount > 0) {
      if ($service_info->{discount_activate} && date_diff($main::DATE, $service_info->{discount_activate}) > 0) {
        #print " Wrong activate" if ($debug);
      }
      elsif($service_info->{discount_expire} && date_diff($main::DATE, $service_info->{discount_expire}) < 0){
        #print " Wrong expire $DATE_, $attr->{DISCOUNT_EXPIRE}: " . date_diff($DATE_, $attr->{DISCOUNT_EXPIRE}) if ($debug);
      }
      else {
        $service_info->{price} = $service_info->{price} * ((100 - $discount) / 100);
      }
    }

    $service_info->{price} = $service_info->{price} * $service_info->{service_count} if ($service_info->{service_count} > 1);
    $info{id} = $service_info->{id};
    $info{tp_name} = $service_info->{tp_name} || q{};

    my %FEES_DSC = (
      MODULE          => 'Abon',
      SERVICE_NAME    => 'Abon',
      TP_ID           => $service_info->{id},
      TP_NAME         => $service_info->{tp_name},
      FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
      FEES_METHOD     => $service_info->{fees_method} ? $main::FEES_METHODS{$service_info->{fees_method}} : undef,
    );

    $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
    $info{module_name} = $lang->{ABON} || 'Abon';
    $info{module} = 'Abon';
    $info{tp_reduction_fee} = ($discount  > 0) ? 0 : $service_info->{reduction_fee};
    $info{extra}{comments} = $service_info->{comments};
    $info{extra}{personal_description} = $service_info->{personal_description};
    if ($service_info->{period} == 1) {
      $info{month} += $service_info->{price};
    }
    elsif ($service_info->{period} == 0) {
      $info{day} += $service_info->{price};
    }

    if ($attr->{FULL_INFO}) {
      push @services, { %info };
    }
    # else {
    #   $line->{price} = $line->{price} * 30 if ($line->{period} == 0);
    #   push @services, "$lang->{ABON}: ($line->{id}) " . "$line->{tp_name}" .
    #     "|$line->{comments} |$line->{price}|$line->{id}|$line->{tp_name}";
    # }
  }

  return \%info if ($attr->{FEES_INFO});

  $self->{SERVICES}=\@services;

  return \@services;
}

#*******************************************************************
=head2 abon_quick_info($attr) - Abon user quick info

  Arguments:
    $attr
      UID

  Returns:

=cut
#*******************************************************************
sub abon_quick_info {
  my ($self, $attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID};

  if ($uid) {
    $Abon->user_tariff_summary({ UID => $uid });
    if ($Abon->{LOST_FEE}) {
      $Abon->{TOTAL_ACTIVE} = q{!} . $Abon->{TOTAL_ACTIVE};
    }
  }

  return ($Abon->{TOTAL_ACTIVE}) ? $Abon->{TOTAL_ACTIVE} : q{};
}

#**********************************************************
=head2 abon_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM
      DATE
      SERVICE_RECOVERY

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub abon_payments_maked {
  my ($self, $attr) = @_;

  require Abon::Services;
  Abon::Services->import();
  my $Services = Abon::Services->new($db, $admin, $CONF, { LANG => $lang });

  my $user = $attr->{USER_INFO};
  $attr->{DATE} = POSIX::strftime('%Y-%m-%d', localtime(time));
  $attr->{USER_INFO} = $user;
  $attr->{SERVICE_RECOVERY} = '>0';

  if ($Services->abon_service_activate($attr)) {
    if ($Services->{OPERATION_SUM} && $html) {
      $html->message('info', $lang->{INFO}, ($Services->{OPERATION_DESCRIBE} || q{}) . " $lang->{SUM}: " . ($Services->{OPERATION_TOTAL_SUM} || 0));
    }
  }

  return $self;
}

#**********************************************************
=head2 abon_promotional_tp($attr)

  Arguments:
    $attr
      USER

=cut
#**********************************************************
sub abon_promotional_tp {
  my ($self, $attr) = @_;

  my $user_info = $attr->{USER};
  return if !$user_info || !$user_info->{UID} || $user_info->{DISABLE};

  my @PERIODS = ($lang->{DAY}, $lang->{MONTH}, $lang->{QUARTER}, $lang->{SIX_MONTH}, $lang->{YEAR});

  my $promotion_tps = $Abon->tariff_list({
    PROMOTIONAL     => q{!},
    PRICE           => '_SHOW',
    TP_NAME         => '_SHOW',
    PERIOD          => '_SHOW',
    USER_PORTAL     => 2,
    MANUAL_ACTIVATE => 1,
    COLS_NAME       => 1
  });
  my $items = q{};

  my $user_activated_tps = $Abon->user_tariff_list($user_info->{UID}, { ACTIVE_ONLY => 1, COLS_NAME => 1 });
  my @activated_tps = ();
  map push(@activated_tps, $_->{id}), @{$user_activated_tps};

  foreach my $tp (@{$promotion_tps}) {
    next if in_array($tp->{id}, \@activated_tps);

    my $price = $tp->{price} || 0;
    next if (($user_info->{DEPOSIT} + $user_info->{CREDIT}) < ($price * (100 - $user_info->{REDUCTION}) / 100));

    $items .= $html->tpl_show(::_include('abon_promotion_tp_carousel_item', 'Abon'), {
      TP_NAME => $tp->{tp_name},
      ACTIVE  => !$items ? 'active' : q{},
      PRICE   => $price,
      PERIOD  => '/' . ($PERIODS[$tp->{period}] || $PERIODS[0]),
      HREF    => '?index=' . main::get_function_index('abon_client') . "&add=$tp->{id}",
    }, { OUTPUT2RETURN => 1 });
  }

  return if !$items;

  return $html->message('callout', $html->tpl_show(main::_include('abon_promotion_tp_carousel', 'Abon'),
    { ITEMS => $items }, { OUTPUT2RETURN => 1 }), q{}, { class => 'info mb-0 p-0' });
}

#*******************************************************************
=head2 abon_user_del($uid, $attr) - Delete user from module

=cut
#*******************************************************************
sub abon_user_del {
  my ($self, $attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Abon->{UID} = $attr->{USER_INFO}{UID};
  $Abon->del({ UID => $attr->{USER_INFO}{UID}, COMMENTS => $attr->{USER_INFO}{COMMENTS} });

  return 1;
}

#**********************************************************
=head2 abon_user_services($attr) - Get user services

=cut
#**********************************************************
sub abon_user_services {
  my ($self, $attr) = @_;

  return [] if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  my Users $user = $attr->{USER_INFO};

  my $services = $Abon->user_tariff_list($user->{UID}, {
    USER_PORTAL       => '>0',
    SERVICE_LINK      => '_SHOW',
    SERVICE_IMG       => '_SHOW',
    DISCOUNT_ACTIVATE => '_SHOW',
    DISCOUNT_EXPIRE   => '_SHOW',
    GID               => $user->{GID} || 0,
    COLS_NAME         => 1
  });

  my @service_list = ();

  foreach my $service (@{$services}) {
    next if (!$service->{manual_activate} && !$service->{date});
    my $date_if = $service->{next_abon} ? date_diff($main::DATE, $service->{next_abon}) : 0;
    my $is_active = !(!$service->{next_abon} || ($date_if && $date_if <= 0));

    next if ($attr->{ACTIVE_ONLY} && !$is_active);

    my @periods = ('day', 'month', 'quarter', 'six months', 'year');

    my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
    my $base_attach_link = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images/attach/abon" : q{};

    my %tariff = (
      price                => $service->{price} || 0,
      original_price       => $service->{price} || 0, #Price without discount
      tp_name              => $service->{tp_name},
      id                   => $service->{id},
      active               => $is_active ? 'true' : 'false',
      service_status       => $is_active ? 1 : 0,
      status_name          => $is_active ? 'Active' : 'Disable',
      start_date           => $service->{date} || '0000-00-00',
      end_date             => $service->{next_abon} || '0000-00-00',
      #activate_date        => $service->{date} || '0000-00-00',
      description          => $service->{user_description} || q{},
      period               => $periods[$service->{period}],
      period_id            => $service->{period} || 0,
      activate             => ($service->{user_portal} > 1 && $service->{manual_activate}) ? 'true' : 'false',
      service_link         => $service->{service_link},
      service_img          => "$base_attach_link/$service->{service_img}",
      personal_description => $service->{personal_description},
      tp_reduction_fee     => $service->{reduction_fee},
      uid                  => $service->{uid} || 0,
      tp_id                => $service->{tp_id} || 0,
      status_name          => q{},
      month_fee            => 0,
      discount_expire      => $service->{discount_expire} || '0000-00-00',
      discount_activate    => $service->{discount_expire} || '0000-00-00',
      discount             => $service->{discount} || 0,
      service_count        => $service->{service_count} || 1,
    );

    if ($tariff{tp_reduction_fee} && $user->{REDUCTION} && $user->{REDUCTION} > 0) {
      $tariff{original_price} = $tariff{price} || 0;
      $tariff{price} = ($tariff{price}) ? $tariff{price} - (($tariff{price} / 100) * $user->{REDUCTION}) : $tariff{price};
    }

    if ($date_if && $date_if > 0) {
      $tariff{next_abon} = {
        abon_date   => $service->{next_abon},
        days_to_fee => $date_if,
        sum         => $service->{price}
      }
    }

    push @service_list, \%tariff;
  }

  return \@service_list;
}

1;