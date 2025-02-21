package Viber::buttons::Set_credit;

use strict;
use warnings FATAL => 'all';

my %icons = (credit => "\xF0\x9F\x92\xB5");

#**********************************************************
=head2 new($Botapi)

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
    return 0;
  }

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my @inline_keyboard = ();
  my $sum = $credit_info->{CREDIT_SUM} || 0;
  my $days = $credit_info->{CREDIT_DAYS} || 0;
  my $price = $credit_info->{CREDIT_CHG_PRICE} || 0;
  my $month_changes = $credit_info->{CREDIT_MONTH_CHANGES} || 0;

  my $message = "$self->{bot}{lang}{SET_CREDIT}: *$sum $money_currency*\n";
  $message .= "$self->{bot}{lang}{CREDIT_OPEN}: *$days* $self->{bot}->{lang}->{DAYS}\n";
  $message .= "$self->{bot}{lang}{CREDIT_PRICE}: *$price $money_currency*\n";
  $message .= "$self->{bot}{lang}{SET_CREDIT_ALLOW}: *$month_changes* $self->{bot}->{lang}->{COUNT}\n";

  my $inline_button = {
    Text       => "$self->{bot}->{lang}->{SET_CREDIT_USER}",
    ActionType => 'reply',
    ActionBody => 'fn:Set_credit&credit',
    TextSize   => 'regular'
  };

  push(@inline_keyboard, $inline_button);

  push (@inline_keyboard, {
    ActionType => 'reply',
    ActionBody => 'MENU',
    Text       => $self->{bot}->{lang}->{BACK},
    BgColor    => '#FF0000',
    TextSize   => 'regular'
  });

  $self->{bot}->send_message({
    text     => $message,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@inline_keyboard
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

  return 0;
}

1;