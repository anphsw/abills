package Viber::buttons::Card_payment;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/vars2lang/;

my %icons = (
  coin => "\xf0\x9f\xaa\x99"
);

#**********************************************************
=head2 new($db, $admin, $conf, $bot, $bot_db, $APILayer, $user_config)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  my $self = shift;

  return $self->{user_config}{cards_user_payment}
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{coin} $self->{bot}{lang}{ICARDS}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @keyboard = ();

  my $cancel_button = {
    Text => $self->{bot}{lang}{CANCEL_TEXT},
    ActionType => 'reply',
    ActionBody => 'fn:Card_payment&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  my $message = $self->{conf}{VIBER_CARDS_MESSAGE};
  $message //= !$self->{user_config}{cards_user_payment}{serial}
    ? $self->{bot}{lang}{ENTER_CARD_DATA_ONLY_PIN}
    : $self->{bot}{lang}{ENTER_CARD_DATA};

  $self->{bot}->send_message({
    text         => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  $self->{bot_db}->add({
    SENDER_ID => $self->{bot}->{receiver},
    FN        => "fn:Card_payment&check_serial",
    ARGS      => '{"serial":"", "pin":""}',
  });

  return 1;
}


#**********************************************************
=head2 click()

=cut
#**********************************************************
sub check_serial {
  my $self = shift;
  my ($attr) = @_;

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my $message = $self->{conf}{TELEGRAM_CARDS_MESSAGE};
  $message //= !$self->{user_config}{cards_user_payment}{serial}
    ? $self->{bot}{lang}{ENTER_CARD_DATA_ONLY_PIN}
    : $self->{bot}{lang}{ENTER_CARD_DATA};

  if (!$attr->{message}->{text}) {
    $self->{bot}->send_message({ text => $message });
    return 1;
  }

  my $text = encode_utf8($attr->{message}->{text});

  my ($serial, $pin);

  if (!$self->{user_config}{cards_user_payment}{serial}) {
    $pin = $text if ($self->{conf}{CARDS_PIN_ONLY});
  }
  else {
    ($serial, $pin) = split '/', $text;
  }

  my ($card_pay_res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/user/cards/payment',
    PARAMS => {
      serial => $serial,
      pin    => $pin
    }
  });

  $message = '';

  if ($card_pay_res->{errmsg} || $card_pay_res->{errstr}) {
    my $err = $card_pay_res->{errmsg} || $card_pay_res->{errstr};
    $message = "*$self->{bot}{lang}{ERROR}*:\n";
    $message .= "\n";
    $message .= $err;

    $self->{bot_db}->del($self->{bot}->{receiver});
    $self->{bot}->send_message({ text => $message });
    return 0;
  }

  my ($user_info) = $self->{api}->fetch_api({ PATH => '/user' });

  $message = vars2lang($self->{bot}{lang}{CARD_PAY_SUCCESS}, {
    SUM     => $card_pay_res->{amount},
    DEPOSIT => "$user_info->{DEPOSIT} $money_currency"
  });

  if ($card_pay_res->{commission}) {
    $message .= "$self->{bot}{lang}{COMMISSION} $card_pay_res->{commission} $money_currency";
  }

  $self->{bot}->send_message({ text => $message });

  $self->{bot_db}->del($self->{bot}->{receiver});
  return 0;
}

#**********************************************************
=head2 cancel()

=cut
#**********************************************************
sub cancel {
  my $self = shift;

  $self->{bot_db}->del($self->{bot}{receiver});
  $self->{bot}->send_message({ text => $self->{bot}{lang}{SEND_CANCEL} });

  return 0;
}

1;
