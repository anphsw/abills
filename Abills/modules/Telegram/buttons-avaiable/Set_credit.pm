package Set_credit;

use strict;
use warnings FATAL => 'all';

require Control::Service_control;
my $Service_control;

my %icons = (credit => "\xF0\x9F\x92\xB5");

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

  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});
  
  return $self;
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

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($self->{bot}{uid});

  my $credit_info = $Service_control->user_set_credit({ UID => $self->{bot}{uid}, REDUCTION => $Users->{REDUCTION} });

  if ($credit_info->{errstr}) {
    $self->{bot}->send_message({
      text       => $self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST},
      parse_mode => 'HTML'
    });
    return;
  }

  my @inline_keyboard = ();
  my $currency = $self->{conf}{MONEY_UNIT_NAMES} || '';
  my $sum = $credit_info->{CREDIT_SUM} || 0;
  my $days = $credit_info->{CREDIT_DAYS} || 0;
  my $price = $credit_info->{CREDIT_CHG_PRICE} || 0;
  my $month_changes = $credit_info->{CREDIT_MONTH_CHANGES} || 0;

  my $message = "$self->{bot}{lang}{SET_CREDIT}: <b>$sum $currency</b>\n";
  $message .= "$self->{bot}{lang}{CREDIT_OPEN}: <b>$days</b> $self->{bot}->{lang}->{DAYS}\n";
  $message .= "$self->{bot}{lang}{CREDIT_PRICE}: <b>$price $currency</b>\n";
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
    parse_mode   => 'HTML'
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

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($attr->{uid});

  my $credit_info = $Service_control->user_set_credit({ UID => $attr->{uid}, REDUCTION => $Users->{REDUCTION}, change_credit => 1 });

  $self->{bot}->send_message({
    text       => $credit_info->{errstr} ? ($self->{bot}{lang}{$credit_info->{errstr}} || $self->{bot}{lang}{CREDIT_NOT_EXIST}) : $self->{bot}{lang}{CREDIT_SUCCESS},
    parse_mode => 'HTML'
  });

  return 1
}

1;