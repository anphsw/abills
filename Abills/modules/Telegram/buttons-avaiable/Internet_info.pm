package Internet_info;

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}->{lang}->{INTERNET};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};
  my $money_currency = $self->{conf}->{DOCS_MONEY_NAMES} || '';

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  require Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  $Users->group_info($Users->{GID});

  my $list = $Internet->list({
    ID              => '_SHOW',
    TP_NAME         => '_SHOW',
    SPEED           => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    GROUP_BY        => 'internet.id',
    UID             => $uid,
    COLS_NAME       => 1,
  });

  my $inline_keyboard = [];
  my $message = "$self->{bot}->{lang}->{CONNECTED_SERVICE}:\n\n";

  foreach my $line (@$list) {
    $message .= "$self->{bot}->{lang}->{TARIF_PLAN}: <b>$line->{tp_name}</b>\n";
    if ($line->{internet_status} == 3) {
      require Shedule;
      my $Shedule  = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
      my $shedule_list = $Shedule->list({
        UID        => $uid,
        SERVICE_ID => $line->{id},
        MODULE     => 'Internet',
        TYPE       => 'status',
        ACTION     => '*:0',
        COLS_NAME  => 1
      });

      if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0) {
        my $holdup_stop_date = ($shedule_list->[0]->{d} || '*')
                       . '.' . ($shedule_list->[0]->{m} || '*')
                       . '.' . ($shedule_list->[0]->{y} || '*');
        $message .= "<b>$self->{bot}->{lang}->{SERVICE_STOP_DATE} $holdup_stop_date</b>\n";
        my $inline_button = {
          text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          callback_data => "Internet_info&stop_holdup&$line->{id}&$shedule_list->[0]->{id}"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
      else {
        $message .= "<b>$self->{bot}->{lang}->{SERVICE_STOP}</b>\n";
        my $inline_button = {
          text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
          callback_data => "Internet_info&stop_holdup&$line->{id}"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
    }
    elsif ($line->{internet_status} == 5) {
      $message .= "<b>$self->{bot}->{lang}->{SMALL_DEPOSIT}</b>\n\n";
      if ($self->{conf}{user_credit_change} && $Users->{ALLOW_CREDIT}) {
        my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $self->{conf}{user_credit_change});
        my $days_lit = "$self->{bot}->{lang}->{DAY}";
        if ($days > 1 && $days < 5) {
          $days_lit = "$self->{bot}->{lang}->{DAY}";
        }
        elsif ($days > 4) {
          $days_lit = "$self->{bot}->{lang}->{DAYS}";
        }
        $message .= "$self->{bot}->{lang}->{SET_CREDIT} $days $days_lit";
        $message .= " $money_currency\n";
        $message .= "$self->{bot}->{lang}->{SERVICE_PRICE}: $price" if ($price);
        $message .= " $money_currency\n";

        my $inline_button = {
          text          => "$self->{bot}->{lang}->{CREDIT_SET}",
          callback_data => "Internet_info&credit"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
    }
    else {
      $message .= "$self->{bot}->{lang}->{SPEED}: <b>$line->{speed}</b>\n" if ($line->{speed});
      $message .= "$self->{bot}->{lang}->{PRICE_MONTH}: <b>$line->{month_fee}</b>" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= " $money_currency\n";
      $message .= "$self->{bot}->{lang}->{PRICE_DAY}: <b>$line->{day_fee}</b>\n" if ($line->{day_fee} && $line->{day_fee} > 0);
    }
    $message .= "\n";
  }

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => $inline_keyboard
    },
    parse_mode   => 'HTML'
  }); 

  return 1;
}

#**********************************************************
=head2 stop_holdup()

=cut
#**********************************************************
sub stop_holdup {
  my $self = shift;
  my ($attr) = @_;

  require Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  $Internet->info($attr->{uid}, {
    ID => $attr->{argv}[2]
  });

  if ( $Internet->{STATUS} == 3) {
    if ($attr->{argv}[3]) {
      require Shedule;
      my $Shedule  = Shedule->new($self->{db}, $self->{admin}, $self->{conf});
      $Shedule->del({
        UID => $attr->{uid},
        IDS => $attr->{argv}[3],
      });
    }

    $Internet->change({
      UID    => $attr->{uid},
      ID     => $attr->{argv}[2],
      STATUS => 0,
    });

    $self->{bot}->send_message({
      text       => "$self->{bot}->{lang}->{SERVICE_ACTIVETED}",
      parse_mode => 'HTML'
    });

    require Abills::Misc;
    service_get_month_fee($Internet, { QUITE => 1, DATE => $main::DATE });
  }
  return 1;
}

#**********************************************************
=head2 credit()

=cut
#**********************************************************
sub credit {
  my $self = shift;
  my ($attr) = @_;

  require Control::Service_control;
  my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

  my $credit_info = $Service_control->user_set_credit({ UID => $attr->{uid}, change_credit => 1 });

  $self->{bot}->send_message({
    text       => $credit_info->{error} ? "$self->{bot}{lang}{CREDIT_NOT_EXIST}" : $self->{bot}{lang}{CREDIT_SUCCESS},
    parse_mode => 'HTML'
  });

  return 1
}

1;
