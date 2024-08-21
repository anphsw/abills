=head2 NAME

  Mobile User portal

=cut

use warnings;
use strict;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @WEEKDAYS,
  @MONTHES
);

my %status = (0 => $lang{ENABLE}, 1 => $lang{DISABLE});
my @service_status_colors = ("#000000", "#FF0000", '#808080', '#0000FF', '#FF8000', '#009999');
my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
  "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT}, $lang{VIRUS_ALERT});

our Users $user;
our Abills::HTML $html;

use Mobile;
my $Mobile = Mobile->new($db, $admin, \%conf);

use Mobile::Services;
my $Services = Mobile::Services->new($db, $admin, \%conf, { lang => \%lang });

#**********************************************************
=head2 mobile_user_info()

=cut
#**********************************************************
sub mobile_user_info {
  
  if ($FORM{ID}) {
    $Mobile->user_info($FORM{ID});
    
    if (!$Mobile->{UID} || $Mobile->{UID} ne $user->{UID}) {
      user_mobile_services();
      return;
    }

    my $service_status = sel_status({ HASH_RESULT => 1 });
    my ($status, $color) = split(/:/, $service_status->{ $Mobile->{TP_DISABLE} });
    $Mobile->{STATUS} = $html->color_mark($status, $color);

    my $currency = '';
    if ($conf{MONEY_UNIT_NAMES}) {
      if (ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY') {
        $currency = $conf{MONEY_UNIT_NAMES}->[0] || '';
      }
      else {
        $currency = (split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
      }
    }

    my $balance = $Services->balance(\%FORM);

    if ($balance && !$balance->{errno} && $balance->{balances}) {
      my $html_language = $html->{language} || 'english';
      my $column_lang = $html_language eq 'russian' ? 'ru' : $html_language eq 'ukrainian' ? 'ua' : 'en';

      my @extra_fields = ();
      foreach my $column (@{$balance->{balances}}) {
        my $column_name = $column->{"name_$column_lang"} || $column->{name_en};
        my $measure = $column->{"measure_$column_lang"} || $column->{measure_en};
        my $amount = $column->{amount} || 0;

        push @extra_fields, $html->tpl_show(templates('form_row_client'), {
          NAME  => $column_name,
          VALUE => join(' ', ($amount, $measure)),
        }, { OUTPUT2RETURN => 1 });
      }
      $Mobile->{EXTRA_FIELDS} = join('', @extra_fields);
    }

    $html->tpl_show(_include('mobile_user_info', 'Mobile'), { %{$Mobile}, CURRENCY => $currency },
      {  ID => 'mobile_user_info' });
  }
  
  user_mobile_services();
}

#**********************************************************
=head2 users_list_table()

=cut
#**********************************************************
sub user_mobile_services {

  return if !$user->{UID};

  my $users = $Mobile->user_list({
    ID             => '_SHOW',
    UID            => $user->{UID},
    DESCRIPTION    => '_SHOW',
    PHONE          => '_SHOW',
    DATE           => '_SHOW',
    TP_NAME        => '_SHOW',
    TP_DISABLE     => '_SHOW',
    TP_ACTIVATE    => '_SHOW',
    DISABLE        => '_SHOW',
    TP_DISABLE     => '_SHOW',
    TRANSACTION_ID => '_SHOW',
    COLS_NAME      => 1
  });

  my @title = ('#', 'UID', $lang{PHONE}, $lang{DATE}, $lang{MOBILE_STATUS_NUMBER}, $lang{TARIF_PLAN},
    $lang{MOBILE_STATUS_TARIFF_PLAN}, $lang{MOBILE_ACTIVATION_DATE}, $lang{DESCRIBE}, '-');

  my $table = $html->table({
    width   => '100%',
    caption => $lang{MOBILE_COMMUNICATION},
    title   => \@title,
    ID      => 'MOBILE_USERS_LIST',
    qs      => $pages_qs
  });

  foreach my $line (@{$users}) {
    my @buttons = ();

    my $info_btn = $html->button("", "index=$index&ID=$line->{id}", { ICON => 'fa fa-pencil-alt' });

    my $phone_status = $status{defined $line->{disable} ? $line->{disable} : 1};
    # my $tp_status = $status{defined $line->{tp_disable} ? $line->{tp_disable} : 1};
    my $tp_status = $html->color_mark($service_status[ $line->{tp_disable} ], $service_status_colors[ $line->{tp_disable} ]);
    my @row = ($line->{id}, $line->{uid}, $line->{phone}, $line->{date}, $phone_status,
      $line->{tp_name}, $tp_status, $line->{tp_activate}, $line->{description}, $info_btn);

    $table->addrow(@row);
  }

  print $table->show();
}

1;