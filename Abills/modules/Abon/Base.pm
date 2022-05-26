package Abon::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my Abills::HTML $html;
my $lang;
my $Abon;

use Abills::Base qw/days_in_month in_array/;

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

    $info{service_name} = "$lang->{ABON}: ($line->{id}) " . "$line->{name}";
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
      push @services, "$lang->{ABON}: ($line->{id}) " . "$line->{name}" .
        "|$line->{comments} |$line->{price}|$line->{id}|$line->{name}";
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
        TP_NAME  => $line->{name},
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

  $Abon->user_tariff_summary({ UID => $uid }) if $uid;

  return ($Abon->{TOTAL_ACTIVE} && $Abon->{TOTAL_ACTIVE} > 0) ? $Abon->{TOTAL_ACTIVE} : '';
}


1;