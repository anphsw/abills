package Viber::Vauth;

=head1 Vauth

  Viber auth

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

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/bots/subscribe',
    PARAMS => {
      TOKEN => $message->{context}
    }
  });

  if (!$res || $res->{errno}) {
    $self->subscribe_info();
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 subscribe_info()

=cut
#**********************************************************
sub subscribe_info {
  my $self = shift;

  my @keyboard = ();
  my $button = {
    Text       => $main::lang{VIBER_VERIFY_PHONE},
    ActionType => 'share-phone',
    ActionBody => 'viber_verify_phone'
  };
  push(@keyboard, $button);

  my $message = {
    text     => $main::lang{VIBER_SUBSCRIBE_INFO},
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'false',
      Buttons       => \@keyboard,
    },
  };

  $self->{bot}->send_message($message);

  return 1;
}

#**********************************************************
=head2 subscribe_phone($hash) - Processes phone number subscription

  Arguments:
    $hash - Hash containing message and contact details with a phone number.

  Returns:
    UID if the phone number is found, or 0 if not found.

  Example:

    my $uid = subscribe_phone({ message => { contact => { phone_number => '+123456789' } }, sender => { id => 1, avatar => 'avatar_url' } });

=cut
#**********************************************************
sub subscribe_phone {
  my $self = shift;
  my ($hash) = @_;

  return if !$hash->{message} || !$hash->{message}{contact} || !$hash->{message}{contact}{phone_number};

  my $phone = $hash->{message}{contact}{phone_number};
  $phone =~ s/\D//g;

  if ($main::conf{VIBER_NUMBER_EXPR}) {
    my ($left, $right) = split '/', $main::conf{VIBER_NUMBER_EXPR};

    $phone =~ s/$left/$right/ge;
  }

  my $success = $self->_check_user_phone($phone);
  return $success if $success;

  $self->_check_crm_dialogue($phone, $hash->{sender});

  return 0;
}

#**********************************************************
=head2 _check_user_phone($phone, $sender_id) - Checks if a user exists by phone number

  Arguments:
    $phone     - The phone number to check
    $sender_id - The ID of the sender (used for contact addition)

  Returns:
    UID if the phone number is found, or 0 if not found.

  Example:

    my $uid = _check_user_phone('+123456789', 1);

=cut
#**********************************************************
sub _check_user_phone {
  my $self = shift;
  my ($phone) = @_;

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/bots/subscribe/phone',
    PARAMS => {
      PHONE => $phone
    }
  });

  my $success = $res && !$res->{errno};

  return $success;
}

#**********************************************************
=head2 _check_crm_dialogue($phone, $sender) - Checks or creates a CRM dialogue for the user

  Arguments:
    $phone     - The phone number of the user (optional)
    $sender    - Sender from Viber (required).
                 Takes "name", "id", "avatar" properties (optional)
  Returns:
    Exits the program after creating or retrieving a CRM dialogue for the user, or sends a message if the dialogue exists.

  Example:

    _check_crm_dialogue('+123456789', 1, 'avatar_url');

=cut
#**********************************************************
sub _check_crm_dialogue {
  my $self = shift;
  my ($phone, $sender) = @_;

  return if !$sender->{id};
  return if !in_array('Crm', \@main::MODULES);

  my $sender_name = $sender->{name} && $sender->{name} ne 'Subscriber'
    ? $sender->{name}
    : $sender->{id};

  $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/social',
    PARAMS => {
      PHONE  => $phone,
      FIO    => $sender_name,
      AVATAR => $sender->{avatar} || ''
    }
  });

  $self->{bot}->send_message({
    text => $main::lang{GREETINGS_YOUR_QUESTION}
  });

  exit 0;
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
