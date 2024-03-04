package Balance;

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
  
  return "$icons{balance} $self->{bot}{lang}{BALANCE}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}{uid};
  my $money_currency = $self->{conf}{MONEY_UNIT_NAMES} || '';
  my @messages = ();
  my @inline_keyboard = ();

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid, { SHOW_PASSWORD => 1 });

  require Control::Services;
  my $service_info = get_services($Users, {});
  my $total_sum = $service_info->{total_sum} || 0;
  my $user_deposit = $Users->{DEPOSIT} || 0;

  if ($total_sum > $user_deposit || $user_deposit < 0) {
    push @messages, sprintf("$icons{not_active} $self->{bot}{lang}{YOUR_DEPOSIT}: %.2f $money_currency\n", $user_deposit);

    if ($self->{conf}{TELEGRAM_BALANCE_URL}) {
      my $inline_button = {
        text => $self->{bot}{lang}{MAKE_PAYMENT},
        url  => "$self->{conf}{TELEGRAM_BALANCE_URL}?get_index=paysys_payment&user=$Users->{LOGIN}&passwd=$Users->{PASSWORD}"
      };
      push @inline_keyboard, [$inline_button];
    }
  }
  else {
    push @messages, sprintf("$icons{active} $self->{bot}{lang}{YOUR_DEPOSIT}: %.2f $money_currency\n", $user_deposit);
  }

  if ($service_info->{list}) {
    push @messages, "$self->{bot}{lang}{TELEGRAM_SCHEDULED_FEES}:";

    foreach my $fee (@{$service_info->{list}}) {
      next if !$fee->{SERVICE_NAME} || !defined($fee->{SUM});

      push @messages, sprintf("$fee->{SERVICE_NAME} - %.2f $money_currency", $fee->{SUM});
    }
  }

  $self->{bot}->send_message({
    text         => join("\n", @messages),
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
  }); 

  return 1;
}

1;