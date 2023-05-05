package Abon::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
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

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

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
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my @services = ();
  my $uid = $attr->{UID} || $form->{UID};

  my $list = $Abon->user_tariff_list($uid, { PAYMENT_TYPE => $attr->{PAYMENT_TYPE}, COLS_NAME => 1 });

  my %info = ();
  foreach my $line (@{$list}) {
    %info = ();
    next if !$line->{date};

    $line->{price} = $line->{price} * ((100 - $line->{discount}) / 100) if $line->{discount} > 0;
    $line->{price} = $line->{price} * $line->{service_count} if $line->{service_count} > 1;

    $info{service_name} = "$lang->{ABON}: ($line->{id}) " . "$line->{tp_name}";
    $info{module_name} = $lang->{ABON};

    if ($line->{period} == 1) {
      $info{month} += $line->{price};
    }
    elsif ($line->{period} == 0) {
      $info{day} += $line->{price};
    }

    if ($attr->{FULL_INFO}) {
      push @services, { %info };
    }
    else {
      $line->{price} = $line->{price} * 30 if $line->{period} == 0;
      push @services, "$lang->{ABON}: ($line->{id}) " . "$line->{tp_name}" .
        "|$line->{comments} |$line->{price}|$line->{id}|$line->{tp_name}";
    }
  }

  return \%info if $attr->{FEES_INFO};

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
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID};

  if ($attr->{UID}) {
    my $list = $Abon->user_tariff_list($uid, { COLS_NAME => 1, ACTIVE_ONLY => 1 });
    my @result = ();
    foreach my $line (@{$list}) {
      push @result, {
        TP_NAME  => $line->{tp_name},
        COMMENTS => $line->{comments},
        PRICE    => $line->{price}
      };
    }
    return \@result;
  }
  elsif ($attr->{GET_PARAMS}) {
    my %result = (
      HEADER    => $lang->{ABON},
      QUICK_TPL => 'abon_qi_box',
      SLIDES    => [ { TP_NAME => $lang->{TARIF_PLAN} }, { SCOMMENTS => $lang->{COMMENTS} }, { PRICE => $lang->{PRICE} }, ]
    );

    return \%result;
  }

  if ($uid) {
    $Abon->user_tariff_summary({ UID => $uid });
    if ($Abon->{LOST_FEE}) {
      $Abon->{TOTAL_ACTIVE} = '!'.$Abon->{TOTAL_ACTIVE};
    }
  }

  return ($Abon->{TOTAL_ACTIVE}) ? $Abon->{TOTAL_ACTIVE} : '';
}

#**********************************************************
=head2 internet_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub abon_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  require Abon::Services;
  Abon::Services->import();
  my $Services = Abon::Services->new($db, $admin, $CONF, { LANG => $lang });

  my $user = $attr->{USER_INFO};
  $attr->{DATE}=POSIX::strftime("%Y-%m-%d", localtime(time));
  $attr->{USER_INFO}=$user;
  $attr->{SERVICE_RECOVERY}='>0';

  if ($Services->abon_service_activate($attr)) {
    if ($Services->{OPERATION_SUM} ) {
      $html->message('info', $lang->{INFO}, ($Services->{OPERATION_DESCRIBE} || q{}) . " $lang->{SUM}: " . ($Services->{OPERATION_SUM} || 0));
    }
  }

  return $self;
}

1;