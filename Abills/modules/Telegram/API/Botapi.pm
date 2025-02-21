package Telegram::API::Botapi;

use strict;
use warnings FATAL => 'all';

use Abills::Fetcher qw/web_request/;

my $debug = 0;

my $JSON_FORMER_PRESET = {
  CONTROL_CHARACTERS => 1,
  FORCE_STRING       => 1,
  BOOL_VALUES        => 1,
};

my @headers = ( 'Content-Type: application/json' );

#**********************************************************
=head2 new($token)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($token, $chat_id, $parse_mode) = @_;

  $chat_id //= "";

  my $self = {
    api_url    => "https://api.telegram.org/bot$token/",
    file_url   => "https://api.telegram.org/file/bot$token/",
    chat_id    => $chat_id,
    parse_mode => $parse_mode || 'HTML'
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 send_message()

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $attr->{chat_id} ||= $self->{chat_id};
  $attr->{parse_mode} ||= $self->{parse_mode};

  my $url      = $self->{api_url} . 'sendMessage';

  my $result = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $attr,
    JSON_FORMER => $JSON_FORMER_PRESET,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }

  return 1;
}

#**********************************************************
=head2 edit_message_text()

=cut
#**********************************************************
sub edit_message_text {
  my $self = shift;
  my ($attr) = @_;

  $attr->{chat_id} ||= $self->{chat_id};
  $attr->{parse_mode} ||= $self->{parse_mode};

  my $url      = $self->{api_url} . 'editMessageText';

  my $result = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $attr,
    JSON_FORMER => $JSON_FORMER_PRESET,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }

  return 1;
}

#**********************************************************
=head2 send_contact()
  
=cut
#**********************************************************
sub send_contact {
  my $self = shift;
  my ($attr) = @_;

  $attr->{chat_id} ||= $self->{chat_id};

  my $url      = $self->{api_url} . 'sendContact';

  my $result = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $attr,
    JSON_FORMER => $JSON_FORMER_PRESET,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }
  
  return 1;
}

#**********************************************************
=head2 get_file($file_id)
  
=cut
#**********************************************************
sub get_file {
  my $self = shift;
  my ($file_id) = @_;

  my $body = { file_id => $file_id };
  my $url      = $self->{api_url} . 'getFile';

  my $file_res = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $body,
    JSON_FORMER => $JSON_FORMER_PRESET,
    JSON_RETURN => 1,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $file_res' >> /tmp/telegram.log`;
  }

  return '' unless ($file_res && ref $file_res eq 'HASH' && $file_res->{result});
  my $file_path = $file_res->{result}{file_path};
  my $file_size = $file_res->{result}{file_size};
  my $file_url = $self->{file_url} . $file_path;

  my $file_content = web_request($file_url, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  return ($file_path, $file_size, $file_content);
}

#**********************************************************
=head2 send_photo($attr)

=cut
#**********************************************************
sub send_photo {
  my $self = shift;
  my ($attr) = @_;

  $attr->{chat_id} ||= $self->{chat_id};
  $attr->{parse_mode} ||= $self->{parse_mode};

  my $url      = $self->{api_url} . 'sendPhoto';

  my $result = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $attr,
    JSON_FORMER => $JSON_FORMER_PRESET,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }

  return 1;
}

#**********************************************************
=head2 answer_callback_query($attr)

=cut
#**********************************************************
sub answer_callback_query {
  my $self = shift;
  my ($attr) = @_;

  my $url      = $self->{api_url} . 'answerCallbackQuery';

  my $result = web_request($url, {
    HEADERS     => \@headers,
    JSON_BODY   => $attr,
    JSON_FORMER => $JSON_FORMER_PRESET,
    METHOD      => 'POST',
  });

  if ($debug > 0) {
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }

  return 1;
}

1;

