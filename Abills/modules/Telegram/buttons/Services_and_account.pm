package Telegram::buttons::Services_and_account;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/int2byte/;

my %icons = (services => "\xF0\x9F\xA7\xA9");

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

  return 1;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;
  
  return "$icons{services} $self->{bot}{lang}{SERVICES}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($user_info) = $self->{api}->fetch_api({ PATH => '/user' });
  my ($user_pi) = $self->{api}->fetch_api({ PATH => '/user/pi' });
  my ($payments) = $self->{api}->fetch_api({ PATH => '/user/payments', });
  my ($credit_info) = $self->{api}->fetch_api({ PATH => '/user/credit' });
  my ($recommended_pay) = $self->{api}->fetch_api({ PATH => '/user/recommendedPay' });
  my ($user_services) = $self->{api}->fetch_api({ PATH => '/user/services' });

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my $total_sum_month = $recommended_pay->{all_services_sum};

  my $can_credit = !$credit_info->{error};

  my $last_payment = ref $payments eq 'ARRAY' ? $payments->[-1] : undef;

  my $message = "$self->{bot}->{lang}->{WELLCOME}, <b>$user_pi->{FIO}</b>";

  $message .= "\n";
  $message .= "\n";

  $message .= sprintf("<b>$self->{bot}->{lang}->{DEPOSIT}:</b> %.2f $money_currency", $user_info->{DEPOSIT});

  $message .= "\n";
  $message .= "\n";

  if ($last_payment) {
    $message .= "<b>$self->{bot}->{lang}->{LAST_PAYMENT}:</b>\n";
    $message .= sprintf("$self->{bot}->{lang}->{SUM}: %.2f $money_currency", $last_payment->{sum});
    $message .= "\n";


    $message .= "$self->{bot}->{lang}->{DATE}: $last_payment->{datetime}\n";
    $message .= "$self->{bot}->{lang}->{DESCRIBE}: $last_payment->{dsc}\n" if ($last_payment->{dsc});
    $message .= "\n";
  }

  my @inline_keyboard = ();
  $message .= "$self->{bot}->{lang}->{YOUR_SERVICE}:\n";

  # TODO: get by API
  my $statuses = ::sel_status({ HASH_RESULT => 1, SKIP_COLORS => 1 });

  my $can_cancel_holdup = 0;

  for my $module (sort keys %$user_services) {
    next if ($module eq 'Triplay');
    my $services = $user_services->{$module};

    my $module_name = $self->{bot}->{lang}->{uc($module)} || $module;
    $message .= "— $module_name: \n";
    if (!scalar(@$services)) {
      $message .= "<i>$self->{bot}->{lang}->{NOT_EXIST}</i>\n";
    }

    foreach my $i (0..$#$services) {
      my $service = $services->[$i];
      my $tp_name = $service->{name} || $service->{tp_name};

      # This is why we need to unify fields name.
      my $possible_status =
        # Normal logic
        $service->{service_status}
        # module Internet
        || $service->{internet_status}
        # module Voip
        || $service->{voip_status}
        # module Abon
        || ($service->{active} && $service->{active} eq 'false' ? 2 : 0);

      my $number = $i + 1;
      $message .= "$number) <b>$tp_name</b>: ". ($statuses->{$possible_status} || "") . "\n";

      if ($service->{holdup} && !$service->{holdup}{errstr} && keys %{$service->{holdup}}) {
        $message .= "<b>$self->{bot}->{lang}->{SERVICE_STOP_DATE} $service->{holdup}->{DATE_TO}</b>\n";
        $can_cancel_holdup ||= ($service->{holdup}->{CAN_CANCEL} && $service->{holdup}->{CAN_CANCEL} eq 'true');
      }

      if ($service->{schedule}) {
        my $future_tp_name = $service->{schedule}->{TP_NAME};
        $message .= "$self->{bot}{lang}{TP_CHANGE_SHEDULED}\n";
        $message .= "$self->{bot}{lang}{TO} <b>$future_tp_name</b> ";
        $message .= "$self->{bot}{lang}{IN} $service->{schedule}->{DATE_FROM}\n";

        if ($service->{schedule}->{CAN_CANCEL} && $service->{schedule}->{CAN_CANCEL} eq 'true') {
          my $inline_button = {
            text          => $self->{bot}->{lang}->{UNDO} . ' ' . $self->{bot}{lang}{SHEDULE},
            callback_data => "Services_and_account&delete_schedule&$module&$service->{schedule}->{SHEDULE_ID}"
          };
          push(@inline_keyboard, [ $inline_button ]);
        }
      }

      # Feature block
      if ($module eq 'Internet') {
        $message .= "$self->{bot}->{lang}->{SPEED}: <b>$service->{in_speed}</b>\n" if ($service->{in_speed});
      }

      # Fee block
      if ($module eq 'Abon') {
        if ($service->{period} eq 'month') {
          $message .= "$self->{bot}{lang}{PRICE_MONTH}: <b>$service->{price}</b> $money_currency\n";
        }
        elsif ($service->{period} eq 'day') {
          $message .= "$self->{bot}{lang}{PRICE_DAY}: <b>$service->{price}</b>$money_currency\n";
        }
      }
      else {
        $message .= "$self->{bot}->{lang}->{PRICE_MONTH}: <b>$service->{month_fee} $money_currency</b>\n" if ($service->{month_fee});
        $message .= "$self->{bot}->{lang}->{PRICE_DAY}: <b>$service->{day_fee} $money_currency</b>\n" if ($service->{day_fee});
      }
    }
    $message .= "\n";
  }

  $message .= "$self->{bot}->{lang}->{SUM_MONTH}: <b>$total_sum_month $money_currency</b>\n";

  if ($can_credit) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{SET_CREDIT_USER}",
      callback_data => "Services_and_account&credit"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  if ($can_cancel_holdup) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{CANCEL_STOP}",
      callback_data => "Services_and_account&stop_holdup"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  if ($self->{conf}->{TELEGRAM_EQUIPMENT_INFO}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      callback_data => "Services_and_account&equipment_info_bot"
    };
    push (@inline_keyboard, [$inline_button]);
  }
  else {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{EQUIPMENT_INFO}",
      callback_data => "Services_and_account&online_info_bot"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  if ($self->{conf}->{TELEGRAM_RESET_MAC}) {
    my $inline_button = {
      text          => "$self->{bot}->{lang}->{INFO_MAC}",
      callback_data => "Services_and_account&mac_info"
    };
    push (@inline_keyboard, [$inline_button]);
  }

  my $chunk_size = 4096;

  for (my $i = 0; $i < length($message); $i += $chunk_size) {
    my $chunk = substr($message, $i, $chunk_size);
    my $props = { text => $chunk };

    # Put inline keyboard to last message
    if ($i + $chunk_size >= length($message)) {
      $props->{reply_markup} = {
        inline_keyboard => \@inline_keyboard
      };
    }

    $self->{bot}->send_message($props);
  }

  return 1;
}

#**********************************************************
=head2 stop_holdup()

=cut
#**********************************************************
sub stop_holdup {
  my $self = shift;
  my ($attr) = @_;

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'DELETE',
    PATH   => '/user/1/holdup/'
  });

  my $message = $res->{errno} ?  $self->{bot}{lang}{ACTIVATION_ERROR} : $self->{bot}{lang}{SERVICE_ACTIVATED};
  $self->{bot}->send_message({ text => $message });

  return 1;
}

#**********************************************************
=head2 delete_schedule($attr)

=cut
#**********************************************************
sub delete_schedule {
  my $self = shift;
  my ($attr) = @_;

  my $module = lc($attr->{argv}[2]);
  my $sheduleId = $attr->{argv}[3];

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'DELETE',
    PATH   => "/user/$module/$sheduleId"
  });

  my $message = $res->{error}
    ? $self->{bot}{lang}{ACTIVATION_ERROR}
    : $self->{bot}{lang}{SHEDULE} . ' ' . $self->{bot}{lang}{DELETED};

  $self->{bot}->send_message({ text => $message });

  return 1;
}

#**********************************************************
=head2 credit()

=cut
#**********************************************************
sub credit {
  my $self = shift;
  my ($attr) = @_;

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH => '/user/credit/'
  });

  my $message = $res->{errno}
    ? ($self->{bot}{lang}{$res->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST})
    : $self->{bot}{lang}{CREDIT_SUCCESS};

  $self->{bot}->send_message({ text => $message });

  return 1
}

#**********************************************************
=head2 equipment_info_bot()

=cut
#**********************************************************
sub equipment_info_bot {
  my $self = shift;
  my ($attr) = @_;

  my ($onus) = $self->fetch_api({ PATH => '/user/equipment' });

  # TODO: migrate statuses to Equipment::Consts?
  our %ONU_STATUS_TEXT_CODES;
  require Equipment::Pon_mng;

  my %status = reverse %ONU_STATUS_TEXT_CODES;

  my $message = '';

  if ($onus->{error} || !keys %$onus) {
    $message = "$self->{bot}->{lang}->{NOT_INFO}";
  }
  else {
    my (undef, $onu_info) = each %$onus;
    my $status_key = $status{$onu_info->{status}} || '';
    my $maybe_langed_status = $self->{bot}->{lang}->{$status_key} || $status_key;
    $message .= "$self->{bot}->{lang}->{STATUS}: <b>$maybe_langed_status</b>\n";
    $message .= "$self->{bot}->{lang}->{ALLOW_MAC}: <b>$onu_info->{cid}</b>\n";
  }

  $self->{bot}->send_message({ text => $message });

  return 1;
}

#**********************************************************
=head2 mac_info()

=cut
#**********************************************************
sub mac_info {
  my $self = shift;
  my ($attr) = @_;


  my $message = '';

  my ($internet_services) = $self->{api}->fetch_api({ PATH => '/user/internet' });

  my $internet_info = ref $internet_services eq 'ARRAY' ? $internet_services->[0] : undef;

  if ($internet_info && $internet_info->{cid}) {
    my $mac = $internet_info->{cid};

    $message = "$self->{bot}->{lang}->{YOUR_MAC}: <b>$mac</b>";
  }
  else {
    $message = "$self->{bot}->{lang}->{NOT_MAC}";
  }

  $self->{bot}->send_message({ text => $message });

  return 1;
}

#**********************************************************
=head2 online_info_bot()

=cut
#**********************************************************
sub online_info_bot {
  my $self = shift;
  my ($attr) = @_;

  my $message = "<b>$self->{bot}->{lang}->{EQUIPMENT_INFO}</b>\n\n";

  my ($sessions) = $self->{api}->fetch_api({ PATH => '/user/internet/session/active' });

  my $session = ref $sessions eq 'ARRAY' ? $sessions->[0] : undef;

  if ($session) {
    my $input_label = int2byte($session->{input});
    my $output_label = int2byte($session->{output});
    $message .= "$self->{bot}{lang}{IP_ADDRESS}: <b>$session->{ip}</b>\n";
    $message .= "$self->{bot}{lang}{CID_ADDRESS}: <b>$session->{cid}</b>\n";
    $message .= "$self->{bot}{lang}{DURATION}: <b>$session->{duration}</b> $self->{bot}{lang}{SECONDS}\n";
    $message .= "$self->{bot}{lang}{RECV}: <b>$input_label</b>\n";
    $message .= "$self->{bot}{lang}{SENT}: <b>$output_label</b>\n";
  }
  else {
    $message .= $self->{bot}{lang}{UNKNOWN};
  }

  $self->{bot}->send_message({ text => $message });

  return 1;
}

1;
