package Telegram::buttons::Paysys_pay;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/vars2lang is_number mk_unique_value/;
use JSON;

my %icons = (
  top_up => "\xf0\x9f\x92\xb3"
);

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $user_config)

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

  return $self->{user_config}{paysys_payment};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{top_up} $self->{bot}{lang}{PAYMENT}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($systems) = $self->{api}->fetch_api({
    PATH   => '/user/paysys/systems',
    PARAMS => {
      REQUEST_METHOD => 'GET'
    }
  });


  if (!$systems || ref $systems eq 'HASH' || !scalar(@{$systems})) {
    $self->{bot}->send_message({ text => $self->{bot}->{lang}->{NO_PAYMENT_SYSTEMS} });
    return 0;
  }

  my @keyboard = ();

  for my $i (0..$#$systems) {
    my $system = $systems->[$i];
    my $row_index = int($i / 2);
    $keyboard[$row_index] //= [];
    my $button = { text => $system->{name} };
    push(@{$keyboard[$row_index]}, $button);
  }

  my $cancel_button = { text => $self->{bot}{lang}{CANCEL_TEXT} };

  push(@keyboard, [$cancel_button]);

  $self->{bot_db}->add({
    USER_ID    => $self->{bot}->{chat_id},
    BUTTON => "Paysys_pay",
    FN     => "choose_paysystem",
    ARGS   => '{"paysys":{"system":{}}}',
  });

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{CHOOSE_PAYMENT_SYSTEM},
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true'
    }
  });

  return 0;
}

#**********************************************************
=head2 choose_paysystem($attr)

=cut
#**********************************************************
sub choose_paysystem {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{message}->{text}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CHOOSE_PAYMENT_SYSTEM} });
  }

  my $text = $attr->{message}->{text};

  if ($text && encode_utf8($text) eq $self->{bot}{lang}{CANCEL_TEXT}) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CANCELED} });
    return 0;
  }

  my ($systems) = $self->{api}->fetch_api({
    PATH   => '/user/paysys/systems',
    PARAMS => {
      REQUEST_METHOD => 'GET'
    }
  });

  if (!$systems || ref $systems eq 'HASH' || !scalar(@{$systems})) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}->{lang}->{NO_PAYMENT_SYSTEMS} });
    return 0;
  }

  my ($matched) = grep { $_->{name} eq $text } @$systems;
  if (!$matched) {
    $self->{bot}->send_message({ text => $self->{bot}->{lang}->{THERE_IS_NO_PAYMENT_SYSTEM} });
    return 1;
  }

  my ($rcmd_pay) = $self->{api}->fetch_api({ PATH => '/user/recommendedPay' });

  my $currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my $message = '';

  $message .= $self->{bot}{lang}{ENTER_PAYMENT_SUM} . "\n";

  if ($rcmd_pay->{max_sum}) {
    $message .= vars2lang($self->{bot}{lang}{PAY_MAX_SUM},
      { SUM => sprintf('%.2f', $rcmd_pay->{max_sum}), CURRENCY => $currency }
    )
  }

  if ($rcmd_pay->{min_sum}) {
    $message .= vars2lang($self->{bot}{lang}{PAY_MIN_SUM},
      { SUM => sprintf('%.2f', $rcmd_pay->{min_sum}), CURRENCY => $currency }
    )
  }

  if ($rcmd_pay->{sum}) {
    $message .= sprintf("$self->{bot}{lang}{RECOMMENDED_PAYMENT}: %.2f $currency", $rcmd_pay->{sum})
  }

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});
  $args->{paysys}->{system} = $matched;
  $info->{ARGS} = encode_json($args);
  $info->{FN} = 'paysys_pay';
  $self->{bot_db}->change($info);

  my @keyboard = ();
  my $cancel_button = { text => $self->{bot}{lang}{CANCEL_TEXT} };
  push(@keyboard, [$cancel_button]);

  $self->{bot}->send_message({
    text => $message,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true'
    }
  });

  return 1;
}

#**********************************************************
=head2 paysys_pay($attr)

=cut
#**********************************************************
sub paysys_pay {
  my $self = shift;
  my ($attr) = @_;

  my $info = $attr->{step_info};
  my $args = decode_json($info->{args});

  if (!$attr->{message}->{text}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{UNKNOWN_SUM} });
    return 1;
  }

  my $text = $attr->{message}->{text};

  if (encode_utf8($text) eq $self->{bot}{lang}{CANCEL_TEXT}) {
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CANCELED} });
    return 0;
  }

  my $sum = $text;

  my ($rcmd_pay) = $self->{api}->fetch_api({ PATH => '/user/recommendedPay' });

  if (!is_number($attr->{message}->{text}, 0, 1) || !$self->_check_sum($rcmd_pay, $sum)) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{UNKNOWN_SUM}});
    return 1;
  }

  # T - Mark as a payment link generated from Telegram
  my $operation_id = 'T' . mk_unique_value(10, { SYMBOLS => '0123456789' });

  my ($response) = $self->{api}->fetch_api({
    METHOD  => 'POST',
    PATH    => '/user/paysys/pay/',
    PARAMS  => {
      SYSTEM_ID    => $args->{paysys}{system}{id},
      OPERATION_ID => $operation_id,
      SUM          => $sum,
    }
  });

  if ($response && $response->{errno}) {
    my $error = $response->{errno} || '999';
    $self->{bot_db}->del($self->{bot}->{chat_id});
    $self->{bot}->send_message({ text => "ERROR $error" });
    return 0;
  }

  my $currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my $message = vars2lang($self->{bot}{lang}{CLICK_BUTTON_TO_PAY},
    {
      PAY_SYSTEM => $args->{paysys}{system}{name},
      SUM        => $sum,
      CURRENCY   => $currency
    }
  );

  my @keyboard = ();

  my $pay_button = {
    text => "$icons{top_up} $self->{bot}{lang}{PROCEED_TO_PAYMENT}",
    url  => $response->{url} || $response->{URL}
  };

  push (@keyboard, [$pay_button]);

  $self->{bot_db}->del($self->{bot}->{chat_id});

  $self->{bot}->send_message({
    text => $message,
    reply_markup => {
      inline_keyboard => \@keyboard
    }
  });

  return 0;
}

#**********************************************************
=head2 _check_sum($rcmd_pay, $sum)

=cut
#**********************************************************
sub _check_sum {
  my $self = shift;
  my ($rcmd_pay, $sum) = @_;

  if ($rcmd_pay->{errno}) {
    return 0;
  }

  if ($rcmd_pay->{min_sum} && $rcmd_pay->{min_sum} > $sum) {
    return 0;
  }

  if ($rcmd_pay->{max_sum} && $rcmd_pay->{max_sum} < $sum) {
    return 0;
  }

  return !!$sum;
}

1;
