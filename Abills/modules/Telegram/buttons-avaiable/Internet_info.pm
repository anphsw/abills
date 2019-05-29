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
  return "Интернет";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};

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
  my $message = "Подключенные сервисы:\n\n";

  foreach my $line (@$list) {
    $message .= "Тарифный план: <b>$line->{tp_name}</b>\n";
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
        $message .= "<b>Внимание: Сервис приостановлен до $holdup_stop_date</b>\n";
        my $inline_button = {
          text          => "Отменть приостановление",
          callback_data => "Internet_info&stop_holdup&$line->{id}&$shedule_list->[0]->{id}"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
      else {
        $message .= "<b>Внимание: Сервис приостановлен.</b>\n";
        my $inline_button = {
          text          => "Отменть приостановление",
          callback_data => "Internet_info&stop_holdup&$line->{id}"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
    }
    elsif ($line->{internet_status} == 5) {
      $message .= "<b>Внимание: Слишком маленький депозит.</b>\n\n";
      if ($self->{conf}{user_credit_change} && $Users->{ALLOW_CREDIT}) {
        my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $self->{conf}{user_credit_change});
        my $days_lit = "день";
        if ($days > 1 && $days < 5) {
          $days_lit = "дня";
        }
        elsif ($days > 4) {
          $days_lit = "дней";
        }
        $message .= "Вы можете взять кредит на $days $days_lit\n";
        $message .= "Стоимость услуги: $price грн.\n" if ($price);

        my $inline_button = {
          text          => "Взять кредит",
          callback_data => "Internet_info&credit"
        };
        $inline_keyboard = [ [$inline_button] ];
      }
    }
    else {
      $message .= "Скорость: <b>$line->{speed}</b>\n" if ($line->{speed});
      $message .= "Стоимость за месяц: <b>$line->{month_fee}</b>\n" if ($line->{month_fee} && $line->{month_fee} > 0);
      $message .= "Стоимость за день: <b>$line->{day_fee}</b>\n" if ($line->{day_fee} && $line->{day_fee} > 0);
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
      text       => "Сервис активирован.",
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

  return 0 unless ($attr->{uid});

  my $credit_avaiable = 1;

  $credit_avaiable = 0 if (!$self->{conf}{user_credit_change});

  require Internet;
  require Users;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($attr->{uid});
  $Users->group_info($Users->{GID});
  $Internet->info($attr->{uid});

  $credit_avaiable = 0 if (!$Users->{ALLOW_CREDIT});
  
  my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $self->{conf}{user_credit_change});
  my $credit_date = POSIX::strftime("%Y-%m-%d", localtime(time + int($days) * 86400));
  
  $sum = $Internet->{USER_CREDIT_LIMIT} if ($sum == 0 && $Internet->{USER_CREDIT_LIMIT} > 0);

  if ($Users->{CREDIT} < sprintf("%.2f", $sum) && $credit_avaiable) {
    $Users->change($attr->{uid}, {
      UID         => $attr->{uid},
      CREDIT      => $sum,
      CREDIT_DATE => $credit_date
    });

    if (!$Users->{errno}) {
      if ($price && $price > 0) {
        require Fees;
        my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
        $Fees->take($Users, $price, { DESCRIBE => "Включение кредита" });
      }

      require Abills::Misc;
      our $DATE = $main::DATE;
      our @MODULES = @main::MODULES;
      our %FORM;
      our %conf = %{$self->{conf}};
      our %lang = %main::lang;
      our $admin = $self->{admin};
      our $db = $self->{db};
      my $res = cross_modules_call('_payments_maked', {
        USER_INFO => $Users,
        SUM       => $sum,
        SILENT    => 1,
        # QUITE     => 1,
        # DEBUG     => 1
      });
      $self->{bot}->send_message({
        text       => "Кредит установлен",
        parse_mode => 'HTML'
      });
    }
  }
  else {
    $self->{bot}->send_message({
      text       => "Кредит недоступен.",
      parse_mode => 'HTML'
    });
  }

  return 1
}

1;
