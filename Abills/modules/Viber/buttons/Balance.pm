package Viber::buttons::Balance;

use strict;
use warnings FATAL => 'all';

my %icons = (
  not_active => "\xE2\x9D\x8C",
  active     => "\xE2\x9C\x85",
  balance    => "\xF0\x9F\x92\xB0"
);

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

  return 1;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{balance} $self->{bot}{lang}{BALANCE}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($user_info) = $self->{api}->fetch_api({ PATH => '/user' });
  my ($recommended_pay) = $self->{api}->fetch_api({ PATH => '/user/recommendedPay' });

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';
  my $message = '';

  $message .= sprintf("$icons{active} $self->{bot}{lang}{YOUR_DEPOSIT}: *%.2f $money_currency* \n", $user_info->{DEPOSIT});
  $message .= "\n";

  if ($recommended_pay->{all_services_sum}) {
    $message .= sprintf("$self->{bot}{lang}{MONTH_PAID_SUM}: *%.2f $money_currency* \n", $recommended_pay->{all_services_sum});
  }

  $self->{bot}->send_message({ text => $message });

  return 0;
}

1;