package Telegram::Tauth;

=head1 NAME

  Telegram auth

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array vars2lang/;

#**********************************************************
=head2 new($attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($bot, $APILayer) = @_;

  my $self = {
    bot    => $bot,
    api    => $APILayer
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 subscribe($message)

=cut
#**********************************************************
sub subscribe {
  my $self = shift;
  my ($message) = @_;

  my ($type, $sid) = $message->{text} =~ m/^\/start ([uae])_([a-zA-Z0-9]+)/;

  if (!$type || !$sid) {
    return 0;
  }

  $self->{api}{for_admins} = 0 if (defined($self->{api}{for_admins}));
  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/bots/subscribe',
    PARAMS => {
      TOKEN => "$type\_$sid"
    }
  });
  $self->{api}{for_admins} = 1 if (defined($self->{api}{for_admins}));

  if ($res && !$res->{errno}) {
    return $res;
  };

  $self->subscribe_info();
  return 0;
}

#**********************************************************
=head2 subscribe_phone($message)

=cut
#**********************************************************
sub subscribe_phone {
  my $self = shift;
  my ($message) = @_;

  # Web client and Android share phone without +, Telegram Desktop with +.
  my $phone = $message->{contact}{phone_number};
  $phone =~ s/\D//g;

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/bots/subscribe/phone',
    PARAMS => {
      PHONE => $phone
    }
  });

  if ($res && !$res->{errno}) {
    return $res;
  };

  if (in_array('Crm', \@main::MODULES)) {
    my $sender = $message->{contact};
    my $fio = $sender->{first_name} . ' ' . ($sender->{last_name} || '');

    $self->{api}->fetch_api({
      METHOD => 'POST',
      PATH   => '/crm/leads/social',
      PARAMS => {
        PHONE  => $phone,
        FIO    => $fio,
      }
    });

    $self->{bot}->send_message({
      text         => $main::lang{GREETINGS_YOUR_QUESTION},
      reply_markup => { remove_keyboard => 'true' },
    });
    exit 0;
  }

  return 0;
}

#**********************************************************
=head2 subscribe_info()
  print HOWTO subscribe text

=cut
#**********************************************************
sub subscribe_info {
  my $self = shift;

  my @keyboard = ();
  my $button = {
    text            => $main::lang{TELEGRAM_VERIFY_PHONE},
    request_contact => 'true',
  };
  push(@keyboard, [ $button ]);

  $self->{bot}->send_message({
    text         => $main::lang{TELEGRAM_SUBSCRIBE_INFO},
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true',
    },
    parse_mode   => 'HTML'
  });

  return 1;
}

#**********************************************************
=head2 auth_success()

=cut
#**********************************************************
sub auth_success {
  my $self = shift;

  my ($user_pi) = $self->{api}->fetch_api({ PATH => '/user/pi' });

  $self->{bot}->send_message({
    text => vars2lang($main::lang{AUTH_SUCCESS}, $user_pi)
  });

  return 1;
}

#**********************************************************
=head2 auth_admin_success($admin_self)

=cut
#**********************************************************
sub auth_admin_success {
  my $self = shift;
  my ($admin_self) = @_;

  $self->{bot}->send_message({
    text         => vars2lang($main::lang{AUTH_SUCCESS}, { FIO => $admin_self->{A_FIO} }),
    reply_markup => { remove_keyboard => 'true' },
  });

  return 1;
}


#**********************************************************
=head2 auth_fail()

=cut
#**********************************************************
sub auth_fail {
  my $self = shift;

  $self->{bot}->send_message({
    text => $main::lang{AUTH_FAIL}
  });

  return 1;
}

1;
