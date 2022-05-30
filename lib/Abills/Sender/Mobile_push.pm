package Abills::Sender::Mobile_push;
use strict;
use warnings FATAL => 'all';

use parent 'Abills::Sender::Plugin';

use Abills::Base qw/json_former/;
use Abills::Backend::API;

our $VERSION = 0.01;

my %types = (
  1 => "Payment made"
);

#**********************************************************
=head2 new($CONF)

  Arguments:
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my ($class, $conf) = @_;

  my $self = {
    api  => Abills::Backend::API->new($conf),
    conf => $conf
  };

  bless $self, $class;

  return $self;
}


#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr -
      UID|AID     - string, receiver ( TODO: '*' to send to all of this type)
      MESSAGE     - string, text of message
      TITLE       - string of message
      TYPE_NOTIFY - number type of notify in variable %types
      PARAMS      - hash of extra info params in notification

  Returns:
    1 if sent;

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  delete $attr->{CONTACT};

  my $receiver_type = (exists $attr->{AID}) ? 'ADMIN' : 'USER';
  my $receiver_id = $attr->{AID} || $attr->{UID};

  # Has no one to send message to
  return undef unless ($receiver_id);

  my %req_params = (
    TYPE        => 'PING',
    MESSAGE     => $attr->{MESSAGE},
    TITLE       => $attr->{TITLE},
    TYPE_NOTIFY => $types{$attr->{TYPE}} || 'Unknown',
    PARAMS      => $attr->{PARAMS} || {}
  );

  return $self->{api}->call($receiver_id, json_former(\%req_params), { SEND_TO => $receiver_type });
}

1;
