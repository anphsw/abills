package Storage::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my $json;
my Abills::HTML $html;
my $lang;
my $Storage;
my @item_status = ();

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

  require Storage;
  Storage->import();
  $Storage = Storage->new($db, $admin, $CONF);

  @item_status = ($lang->{INSTALLED}, $lang->{SOLD}, $lang->{RENT}, $lang->{BY_INSTALLMENTS}, $lang->{RETURNED_STORAGE});

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 storage_docs($attr) - get hardwares for invoice

  Arguments:
    UID
  Results:

=cut
#**********************************************************
sub storage_docs {
  my $self = shift;
  my ($attr) = @_;

  return [] if !$attr->{UID};

  my @hardwares = ();
  my %info = ();

  my $list = $Storage->storage_installation_list({
    UID                          => $attr->{UID},
    STORAGE_INCOMING_ARTICLES_ID => '_SHOW',
    COUNT                        => '_SHOW',
    SUM                          => '_SHOW',
    STA_NAME                     => '_SHOW',
    STREET                       => '_SHOW',
    STATUS                       => '>1,<4',
    MONTHES                      => '_SHOW',
    ACTUAL_SELL_PRICE            => '_SHOW',
    RENT_PRICE                   => '_SHOW',
    ABON_DISTRIBUTION            => '_SHOW',
    AMOUNT_PER_MONTH             => '_SHOW',
    COLS_NAME                    => 1
  });

  foreach my $hardware (@{$list}) {
    $hardware->{describe} = $lang->{MONTH_FEE_SHORT};
    if ($hardware->{status} eq '3') {
      $hardware->{sum_total} = $hardware->{amount_per_month} if ($hardware->{amount_per_month});

      next if $hardware->{monthes} < 1;
    }
    else {
      $hardware->{sum_total} = $hardware->{rent_price} * $hardware->{count} if ($hardware->{rent_price});

      if ($hardware->{actual_sell_price} != 0) {
        $hardware->{sum_total} = $hardware->{actual_sell_price} * $hardware->{count};
      }

      if ($hardware->{abon_distribution}) {
        $hardware->{sum_total} = sprintf("%.6f", $hardware->{sum_total} / days_in_month());
        $hardware->{describe} = $lang->{ABON_DISTRIBUTION};
      }
    }

    $hardware->{sta_name} ||= '';
    $info{service_name} = qq{$lang->{HARDWARE}:$hardware->{describe} $hardware->{sta_name} $item_status[$hardware->{status}] ($hardware->{count} $lang->{UNIT})};
    $info{service_name} .= qq{ ($lang->{STORAGE_MONTHS_LEFT}: $hardware->{monthes})};
    $info{month} = $hardware->{sum_total};

    if ($attr->{FULL_INFO}) {
      push @hardwares, { %info };
    }
    else {
      $hardware->{sum_total} //= 0;
      push @hardwares, "Hardware: $item_status[$hardware->{status}] $hardware->{sta_name}: $hardware->{sum_total}";
    }
  }

  return \%info if $attr->{FEES_INFO};

  return \@hardwares;
}

#**********************************************************
=head2 storage_quick_info()

  Arguments:
     $attr
       UID

  Returns:

=cut
#**********************************************************
sub storage_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $attr->{UID} || $form->{UID} || 0;

  if ($attr->{UID}) {
    my @result = ();

    my $list = $Storage->storage_installation_list({
      UID                => $uid,
      STA_NAME           => '_SHOW',
      SAT_TYPE           => '_SHOW',
      ACTUAL_SELL_PRICE  => '_SHOW',
      MAC                => '_SHOW',
      IP                 => '_SHOW',
      STATUS             => '_SHOW',
      DATE               => '_SHOW',
      INSTALLED_AID_NAME => '_SHOW',
      COLS_NAME          => 1
    });

    foreach my $storage_element (@{$list}) {
      $storage_element->{status} = $item_status[$storage_element->{status}];
      $storage_element->{sta_name} =~ s/\"/\\"/g;
      $storage_element->{sta_name} =~ s/\t//g;

      push @result, $storage_element;
    }

    return \@result;
  }
  elsif ($attr->{GET_PARAMS}) {
    my %result = (
      HEADER    => $lang->{STORAGE},
      QUICK_TPL => 'storage_qi_box',
      SLIDES    => [{
        sat_type           => $lang->{TYPE},
        actual_sell_price  => $lang->{PRICE},
        mac                => 'MAC',
        ip                 => 'IP',
        sta_name           => $lang->{NAME},
        status             => $lang->{STATUS},
        date               => $lang->{DATE},
        installed_aid_name => $lang->{ADMIN}
      }]
    );

    return \%result;
  }

  $Storage->storage_installation_list({ UID => $uid || 0, COLS_NAME => 1 });

  return ($Storage->{TOTAL} > 0) ? $Storage->{TOTAL} : '';
}


1;