package Telegram::buttons::Set_credit;

use strict;
use warnings FATAL => 'all';

my %icons = (credit => "\xF0\x9F\x92\xB5");

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

  return $self->{user_config}{user_credit};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;
  
  return "$icons{credit} $self->{bot}{lang}{CREDIT}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($credit_info) = $self->{api}->fetch_api({ PATH => '/user/credit' });

  if ($credit_info->{errstr}) {
    my $err_msg = $self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST};
    $self->{bot}->send_message({ text => $err_msg });
    return;
  }

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my @inline_keyboard = ();
  my $sum = $credit_info->{CREDIT_SUM} || 0;
  my $days = $credit_info->{CREDIT_DAYS} || 0;
  my $price = $credit_info->{CREDIT_CHG_PRICE} || 0;
  my $month_changes = $credit_info->{CREDIT_MONTH_CHANGES} || 0;

  my $message = "$self->{bot}{lang}{SET_CREDIT}: <b>$sum $money_currency</b>\n";
  $message .= "$self->{bot}{lang}{CREDIT_OPEN}: <b>$days</b> $self->{bot}->{lang}->{DAYS}\n";
  $message .= "$self->{bot}{lang}{CREDIT_PRICE}: <b>$price $money_currency</b>\n";
  $message .= "$self->{bot}{lang}{SET_CREDIT_ALLOW}: <b>$month_changes</b> $self->{bot}->{lang}->{COUNT}\n";

  my $inline_button = {
    text          => "$self->{bot}->{lang}->{SET_CREDIT_USER}",
    callback_data => "Set_credit&credit"
  };

  push(@inline_keyboard, [ $inline_button ]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
  });

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

1;