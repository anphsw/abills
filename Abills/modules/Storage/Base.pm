package Storage::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $Storage;
my @item_status = ();

use Abills::Base qw/days_in_month in_array json_former/;

our %lang;
# require 'Abills/modules/Storage/lng_english.pl';

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
  %lang = (%{$attr->{LANG} ? $attr->{LANG} : {}}, %lang);

  my $self = {};

  require Storage;
  Storage->import();
  $Storage = Storage->new($db, $admin, $CONF);

  @item_status = (
    ($lang{INSTALLED} || q{}),
    ($lang{SOLD} || q{}),
    ($lang{RENT} || q{}),
    ($lang{BY_INSTALLMENTS} || q{}),
    ($lang{RETURNED_STORAGE} || q{}),
    ($lang{STORAGE_NOT_ACTIVATED_INSTALLMENT} || q{}),
    ($lang{STORAGE_NOT_ACTIVATED_RENT} || q{})
  );

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 storage_docs($attr) - get hardware's for invoice

  Arguments:
    UID
  Results:

=cut
#**********************************************************
sub storage_docs {
  shift;
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
    $hardware->{describe} = $lang{MONTH_FEE_SHORT};
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
        $hardware->{describe} = $lang{ABON_DISTRIBUTION};
      }
    }

    $hardware->{sta_name} ||= '';
    $info{service_name} = ($lang{HARDWARE} || q{}) . ':' . ($hardware->{describe} || q{}) . ' ' . ($hardware->{sta_name} || q{}) . ' ' .
      ($item_status[$hardware->{status}] || q{}) . ' (' . ($hardware->{count} || 0) . ' ' . ($lang{UNIT} || q{}) . ")";
    $info{service_name} .= ($lang{STORAGE_MONTHS_LEFT} || q{}) . ' : ' . ($hardware->{monthes} || 0) . ')';
    $info{month} = $hardware->{sum_total};

    if ($attr->{FULL_INFO}) {
      push @hardwares, { %info };
    }
    else {
      $hardware->{sum_total} //= 0;
      push @hardwares, "Hardware: " . ($item_status[$hardware->{status}] || q{}) . " $hardware->{sta_name}: $hardware->{sum_total}";
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
  shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID} || 0;

  $Storage->storage_installation_list({ UID => $uid || 0, COLS_NAME => 1 });

  return ($Storage->{TOTAL} > 0) ? $Storage->{TOTAL} : '';
}

#***************************************************************
=head2 storage_events($attr)

=cut
#***************************************************************
sub storage_events {
  my $self = shift;
  my ($attr) = @_;

  my %LIST_PARAMS;
  my $events_json = [];

  return '' if $attr->{CLIENT_INTERFACE};

  my $installations = $Storage->storage_installation_list({
    DATE            => $main::DATE,
    STA_NAME        => '_SHOW',
    SAT_TYPE        => '_SHOW',
    LOGIN           => '_SHOW',
    UID             => '!',
    DELIVERY_ID     => '!',
    DELIVERY_STATUS => '0',
    SORT            => 'i.id',
    DESC            => 'DESC',
    COLS_NAME       => 1
  });

  foreach my $line (@{$installations}) {
    push @{$events_json}, json_former({
      TYPE        => 'MESSAGE',
      MODULE      => 'Storage',
      TITLE       => $lang{STORAGE_PURCHASED_ITEM},
      TEXT        => "$line->{sat_type}: $line->{sta_name}",
      CREATED     => $line->{date},
      EXTRA       => "?get_index=storage_hardware&UID=$line->{uid}&delivery=$line->{id}&full=1",
      SENDER      => { UID => $line->{uid}, LOGIN => $line->{login} }
    });
  }

  return join(', ', @{$events_json});
}

#**********************************************************
=head2 storage_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO

=cut
#**********************************************************
sub storage_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  my $user;
  $user = $attr->{USER_INFO} if ($attr->{USER_INFO});

  my $deposit = defined($user->{DEPOSIT}) ? $user->{DEPOSIT} + (($user->{CREDIT}) ? $user->{CREDIT} : 0) : 0;
  return if $deposit < 0;

  my $user_installations = $Storage->storage_installation_list({
    UID                   => $user->{UID},
    STATUS                => '5;6',
    MONTHES               => '_SHOW',
    IN_INSTALLMENTS_PRICE => '_SHOW',
    RENT_PRICE            => '_SHOW',
    FEES_METHOD           => '_SHOW',
    COUNT                 => '_SHOW',
    STA_NAME              => '_SHOW',
    ABON_DISTRIBUTION     => '_SHOW',
    AMOUNT_PER_MONTH      => '_SHOW',
    COLS_NAME             => 1
  });

  use Fees;
  my $Fees = Fees->new($db, $admin, $CONF);

  foreach my $installation (@{$user_installations}) {
    $installation->{sta_name} //= '';

    if ($installation->{status} == 5) {
      my $amount_per_month = $installation->{amount_per_month} ? $installation->{amount_per_month} :
        ($installation->{in_installments_price} && $installation->{monthes} ?
          $installation->{in_installments_price} / $installation->{monthes} : 0);
      next if $deposit < $amount_per_month;

      $Fees->take($user, $amount_per_month, {
        DESCRIBE => "$lang{BY_INSTALLMENTS} $installation->{sta_name}",
        METHOD   => $installation->{fees_method} || 0
      });

      if (!$Fees->{errno}) {
        $Storage->storage_installation_change({
          ID               => $installation->{id},
          AMOUNT_PER_MONTH => $amount_per_month,
          MONTHES          => $installation->{monthes} - 1,
          TYPE             => 3
        });
        $deposit -= $amount_per_month;
      }
      next;
    }

    if ($installation->{status} == 6) {
      next if !$installation->{rent_price} || !$installation->{count};

      my $rent_price = $installation->{rent_price} ? $installation->{rent_price} * int($installation->{count}) : 0;
      my $describe = "$lang{PAY_FOR_RENT} $installation->{sta_name}";

      if ($installation->{abon_distribution} && $rent_price > 0) {
        $rent_price = sprintf("%.6f", $rent_price / days_in_month());
        $describe .= " - $lang{ABON_DISTRIBUTION}";
      }
      next if $deposit < $rent_price;

      $Fees->take($user, $rent_price, { DESCRIBE => $describe, METHOD => $installation->{fees_method} || 0 });
      if (!$Fees->{errno}) {
        $Storage->storage_installation_change({
          ID   => $installation->{id},
          TYPE => 2
        });
      }
    }
  }
}

1;
