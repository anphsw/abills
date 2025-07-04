package Viber::API::Botapi;

=head NAME

  Viber Bot API

=head DOCUMENTATION

  ALL API
    https://developers.viber.com/docs/api/
  REST Bot API
    https://developers.viber.com/docs/api/rest-bot-api/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Fetcher qw(web_request);

#**********************************************************
=head2 new($class, $token, $receiver)

    Arguments:
    $class    -
    $token    - Viber bot token
    $receiver - Receiver of message

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($token, $receiver, $attr) = @_;

  $receiver //= "";
  $attr //= {};

  my $self = {
    token    => $token,
    receiver => $receiver,
    api_url  => 'https://chatapi.viber.com/pa/'
  };

  $self->{name} = $attr->{NAME} || 'ABillS User Bot';

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 send_message() send message to Viber

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $attr->{receiver} ||= $self->{receiver};
  $attr->{min_api_version} = 7;
  $attr->{sender} = { name => $self->{name} };
  $attr->{type} ||= 'text';

  if ($attr->{keyboard}) {
    $attr->{keyboard} = $self->_workaround_buttons($attr->{keyboard});
  }

  my $url = $self->{api_url} . 'send_message';
  my @headers = ('Content-Type: application/json', "X-Viber-Auth-Token: $self->{token}");

  web_request($url, {
    HEADERS   => \@headers,
    JSON_BODY => $attr,
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
    },
    METHOD    => 'POST',
  });

  return 1;
}

#**********************************************************
=head2 get_file($file_id)

=cut
#**********************************************************
sub get_file {
  shift;
  my ($file_id) = @_;

  my ($file_path, $file_name, $file_size) = $file_id =~ /(.*)\|(.*)\|(.*)/;
  my $file_content = web_request($file_path, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  return ($file_name, $file_size, $file_content);
}

#**********************************************************
=head2 _workaround_buttons($keyboard)

  In Viber dark mode only on IOS buttons may bad usability.
  This function will set white background color for all buttons.

=cut
#**********************************************************
sub _workaround_buttons {
  my $self = shift;
  my ($keyboard) = @_;

  for my $i (0..$#{$keyboard->{Buttons}}) {
    $keyboard->{Buttons}->[$i]->{BgColor} //= "#FFFFFF";
  }

  return $keyboard;
}

1;
