package Viber::buttons::Crm_new_lead;

use strict;
use warnings FATAL => 'all';

my %icons = (
  send_envelope => "\xf0\x9f\x93\xa8"
);

#**********************************************************
=head2 new($db, $admin, $conf, $bot, $bot_db, $APILayer, $user_config)

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

  return "$icons{send_envelope} $self->{bot}{lang}{INVITE_A_FRIEND}";
}

#**********************************************************
=head2 click($attr)

=cut
#**********************************************************
sub click {
  my $self = shift;
  my $label = $self->{bot}{lang}{VIBER_LINK_AND_INVITE};
  my $bot_name = $self->{conf}{VIBER_BOT_NAME};
  my $bot_link = "viber://pa?chatURI=$bot_name";

  my $text = "$label\n\n$bot_link";

  $self->{bot}->send_message({ text => $text });

  return 0;
}

#**********************************************************
=head2 add_request($attr)

=cut
#**********************************************************
sub add_request {
  my $self = shift;
  my ($attr) = @_;

  my $phone = $attr->{argv}[2] || '';
  if (!$phone) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{AN_ERROR_OCCURRED_WHILE_APPLYING} });
    return 1;
  }

  my $fio = $attr->{sender}{name} && $attr->{sender}{name} ne 'Subscriber'
    ? $attr->{sender}{name}
    : $attr->{sender}{id};

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/social',
    PARAMS => {
      PHONE    => $phone,
      FIO      => $fio,
    }
  });

  my $text = $res->{errno} ? $self->{bot}{lang}{AN_ERROR_OCCURRED_WHILE_APPLYING} : $self->{bot}{lang}{APPLICATION_SENT};

  $self->{bot}->send_message({ text => $text });
}

1;
