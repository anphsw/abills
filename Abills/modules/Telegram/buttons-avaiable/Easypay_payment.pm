package Easypay_payment;

use strict;
use warnings FATAL => 'all';

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

  return $self->{bot}->{lang}->{EASYPAY_PAYMENT};
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @inline_keyboard = ();
  my $uid = $self->{bot}->{uid};
  my $message = "$self->{bot}->{lang}->{EASYPAY_TELEGRAM}\n";

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);

  use Conf;
  my $Conf = Conf->new($self->{db}, $self->{admin}, $self->{conf});

  my $conf_info = $Conf->config_info({PARAM => "LIKE'%1'"});

  my $users_info = $Users->pi({ UID => $uid });

  my $account_key =  $users_info->{UID};
  my $gid = $users_info->{GID};

  if($conf_info->{conf}{"PAYSYS_EASYPAY_ACCOUNT_KEY" . "_$gid"} eq "CONTRACT_ID"){
    $account_key = $users_info->{CONTRACT_ID};
  }
  elsif($conf_info->{conf}{"PAYSYS_EASYPAY_ACCOUNT_KEY" . "_$gid"} eq "LOGIN"){
    $account_key = $users_info->{LOGIN};
  }

  my $deposit = sprintf("%.2f", $users_info->{DEPOSIT});
  my $amount = abs($deposit);
  my $fast_pay = $conf_info->{conf}{"PAYSYS_EASYPAY_FASTPAY" . "_$gid"};
  my $url_pay = "$fast_pay"  . "?account=" .  "$account_key" . "&amount=" . "$amount";

  if (defined $conf_info->{conf}{"PAYSYS_EASYPAY_ACCOUNT_KEY" . "_$gid"}) {
    $message .= "$self->{bot}->{lang}->{UNIQU_NUMBER}: <b>$account_key</b>\n";
    $message .= "$self->{bot}->{lang}->{PAYMENT_SUM}: <b>$deposit</b>\n";
    $message .= "$self->{bot}->{lang}->{PAY_SUM_CHANGE}\n";
  }
  else{
    $message .= "$self->{bot}->{lang}->{ERRO_PAY}\n";
  }

  my $inline_button = {
    text     => "$self->{bot}->{lang}->{EASYPAY_PAYMENT}",
    url      => "$url_pay"
  };
  push (@inline_keyboard, [$inline_button]);

  $self->{bot}->send_message({
    text         => $message,
    reply_markup => {
      inline_keyboard => \@inline_keyboard
    },
    parse_mode   => 'HTML'
  });

  return 1;
}

1;