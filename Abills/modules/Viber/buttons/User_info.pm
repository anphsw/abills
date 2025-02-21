package Viber::buttons::User_info;

use strict;
use warnings FATAL => 'all';

my %icons = (
  user => "\xf0\x9f\x91\xa4"
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

  return "$icons{user} $self->{bot}->{lang}->{ACCOUNT}";
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

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my $message = "$self->{bot}->{lang}->{WELLCOME}, $user_pi->{FIO}\n\n";
  $message .= sprintf("$self->{bot}->{lang}->{DEPOSIT}: %.2f $money_currency\n", $user_info->{DEPOSIT});
  $message .= "\n";
  $message .= "$self->{bot}->{lang}->{LOGIN}: ```$user_info->{LOGIN}```\n";

  if ($user_pi->{CONTRACT_ID}) {
    $message .= "$self->{bot}->{lang}->{CONTRACT_ID}: $user_pi->{CONTRACT_ID}\n";
  }

  for my $cell_phone (@{$user_pi->{CELL_PHONE}}) {
    $message .= "$self->{bot}->{lang}->{YOUR_PHONE_CELL}: $cell_phone\n";
  }

  for my $phone (@{$user_pi->{PHONE}}) {
    $message .= "$self->{bot}->{lang}->{YOUR_PHONE}: $phone\n";
  }

  for my $email (@{$user_pi->{EMAIL}}) {
    $message .= "$self->{bot}->{lang}->{EMAIL}: $email\n";
  }

  $self->{bot}->send_message({ text => $message });

  return 0;
}

1;
