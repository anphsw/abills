package Abills::Sender::Whatsapp;

use strict;
use warnings;

use Abills::Fetcher qw/web_request/;
use parent 'Abills::Sender::Plugin';
use Abills::Base qw(_bp json_former);
use JSON qw/decode_json encode_json/;

our $VERSION = '0.01';

my %conf = ();

#**********************************************************
=head2 new($conf)

=cut
#**********************************************************
sub new {
  my ($class, $conf) = @_;

  %conf = %{$conf};

  die 'No WHATSAPP_ACCESS_TOKEN' if !$conf{WHATSAPP_ACCESS_TOKEN};
  die 'No WHATSAPP_PHONE_NUMBER_ID' if !$conf{WHATSAPP_PHONE_NUMBER_ID};

  my $self = {
    token           => $conf{WHATSAPP_ACCESS_TOKEN},
    phone_number_id => $conf{WHATSAPP_PHONE_NUMBER_ID},
    api_url         => "https://graph.facebook.com/v22.0/$conf{WHATSAPP_PHONE_NUMBER_ID}/messages",
  };

  bless $self, $class;
  return $self;
}

#**********************************************************
=head2 send_message()

  Arguments:
    TO_ADDRESS - wa_id
    MESSAGE    - text
    DEBUG

=cut
#**********************************************************
sub send_message {
  my ($self, $attr, $callback) = @_;

  return 0 if !$attr->{TO_ADDRESS};
  return 0 if !$attr->{MESSAGE};

  $self->{debug} = $attr->{DEBUG} if $attr->{DEBUG};

  my $payload = {
    messaging_product => 'whatsapp',
    to   => $attr->{TO_ADDRESS},
    type => 'text',
    text => {
      body => $attr->{MESSAGE}
    }
  };

  my $result = $self->_send_request($payload, $callback);

  _bp('WhatsApp send result', $result, { TO_CONSOLE => 1 }) if $self->{debug};

  return $result->{messages}[0]{id} || 0;
}

#**********************************************************
=head2 _send_request()

=cut
#**********************************************************
sub _send_request {
  my ($self, $params, $callback) = @_;

  my $json = json_former($params, { ESCAPE_DQ => 1, BOOL_VALUES => 1 });

  my @headers = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $self->{token}
  );

  my $result = web_request($self->{api_url}, {
    POST         => $json,
    HEADERS      => \@headers,
    CURL         => 1,
    CURL_OPTIONS => '-s -X POST',
  });

  return eval { decode_json($result) } || {};
}

1;
