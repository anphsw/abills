package Abon_info;

use strict;
use warnings FATAL => 'all';

my %icons = (tariff => "\xF0\x9F\x93\x88");

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

  return "$icons{tariff}" . ($self->{bot}{lang}{ABON} || 'Abon');
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};
  my $money_currency = $self->{conf}->{MONEY_UNIT_NAMES} || '';

  my $abon_services = $self->fetch_api({
    method => 'GET',
    path   => '/user/abon/'
  });

  my $total_sum_month = 0;
  my $total_sum_day = 0;
  my $message = "$self->{bot}->{lang}->{YOUR_SERVICE}:\n\n";

  foreach my $service (@{$abon_services}) {
    next if !$service->{next_abon};

    $message .= "$self->{bot}{lang}{TARIF_PLAN}: <b>" . ($service->{tp_name} || q{}) . "</b>\n";
    if ($service->{period} && $service->{period} eq 'month' && defined($service->{price})) {
      $message .= "$self->{bot}{lang}{PRICE_MONTH}: <b>$service->{price}</b>";
      $message .= " $money_currency\n";
      $total_sum_month += $service->{price} || 0;
    }
    if ($service->{period} && $service->{period} eq 'day' && defined($service->{price})) {
      $message .= "$self->{bot}{lang}{PRICE_DAY}: <b>$service->{price}</b>";
      $message .= " $money_currency\n";
      $total_sum_day += $service->{price} || 0;
    }
    $message .= "\n";
  }

  $message .= "$self->{bot}->{lang}->{SUM_MONTH}: <b>$total_sum_month</b>";
  $message .= " <b>$money_currency</b>\n";
  $message .= "$self->{bot}->{lang}->{SUM_DAY}: <b>$total_sum_day</b>";
  $message .= " <b>$money_currency</b>\n";

  $self->{bot}->send_message({
    text       => $message,
    parse_mode => 'HTML'
  });

  return 1;
}

#**********************************************************
=head2 fetch_api($attr)

=cut
#**********************************************************
sub fetch_api {
  my $self = shift;
  my ($attr) = @_;

  return {} if !$self->{bot} || !$self->{bot}{chat_id};

  $ENV{HTTP_USERBOT} = 'TELEGRAM';
  $ENV{HTTP_USERID} = $self->{bot}{chat_id};
  use Abills::Api::Handle;
  my $handle = Abills::Api::Handle->new($self->{db}, $self->{admin}, $self->{conf}, { direct => 1 });

  my ($result) = $handle->api_call({
    METHOD => $attr->{method},
    PATH   => $attr->{path},
  });

  return $result;
}

1;
