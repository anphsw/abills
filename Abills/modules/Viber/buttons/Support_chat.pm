package Viber::buttons::Support_chat;

use strict;
use warnings FATAL => 'all';
use JSON qw(decode_json);

my %icons = (
  admin => "\xF0\x9F\x92\xAC"
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

  return $self->{user_config}{crm_user_leads};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{admin} $self->{bot}{lang}{VIBER_OPERATOR_HELP}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @keyboard = ();

  my $cancel_button = {
    Text => $self->{bot}{lang}{VIBER_RETURN_TO_MAIN_MENU},
    ActionType => 'reply',
    ActionBody => 'fn:Support_chat&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  my $dialogue_info = $self->_get_dialogue_id();

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{VIBER_DESCRIBE_YOUR_ISSUE},
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  my $dialogue_id = $dialogue_info->{NEW_DIALOGUE_ID} || '';
  my $lead_id = $dialogue_info->{NEW_LEAD_ID} || '';
  $self->{bot_db}->add({
    SENDER_ID => $self->{bot}->{receiver},
    FN        => "fn:Support_chat&send_message",
    ARGS      => '{"lead_id":"' . $lead_id . '", "dialogue_id":"' . $dialogue_id  . '"}',
  });

  return 1;
}

#**********************************************************
=head2 send_message($attr)

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{message} || !$attr->{message}{text}) {
    return 0;
  }

  my @keyboard = ();

  my $cancel_button = {
    Text => $self->{bot}{lang}{VIBER_RETURN_TO_MAIN_MENU},
    ActionType => 'reply',
    ActionBody => 'fn:Support_chat&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/dialogue/message/',
    PARAMS => {
      MESSAGE => $attr->{message}{text}
    }
  });

  $self->{bot}->send_message({
    text         => $res->{id} ? $self->{bot}{lang}{VIBER_MESSAGE_SENT} : $self->{bot}{lang}{VIBER_MESSAGE_SEND_ERROR},
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  return 1;
}

#**********************************************************
=head2 cancel()

=cut
#**********************************************************
sub cancel {
  my $self = shift;

  $self->{bot_db}->del($self->{bot}{receiver});

  return 0;
}

#**********************************************************
=head2 _get_dialogue_id()

=cut
#**********************************************************
sub _get_dialogue_id {
  my $self = shift;

  my ($user_pi) = $self->{api}->fetch_api({ PATH => '/user/pi' });
  $user_pi->{PHONE} = $user_pi->{PHONE}[0];
  $user_pi->{EMAIL} = $user_pi->{EMAIL}[0];
  $user_pi->{BUILD_ID} = $user_pi->{LOCATION_ID};

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/social',
    PARAMS => $user_pi
  });

  return $res;
}

1;
