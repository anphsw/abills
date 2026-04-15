package Abills::AI::Driver::Base;

use strict;
use warnings;

use Abills::Fetcher qw/web_request/;
use Abills::Base qw/load_pmodule/;

=head1 NAME

Abills::AI::Driver::Base - Base class for AI Drivers

=head1 SYNOPSIS

  use base 'Abills::AI::Driver::Base';

  sub chat {
    my ($self, $attr) = @_;
    return $self->request( ... );
  }

=cut

#**********************************************************
=head2 new($class, $conf, $attr) - Constructor

  Creates a new object instance and initializes basic
  configuration, debug options, timeout, and JSON handler.

  Arguments:
    $class  - Class name
    $conf   - Configuration hash reference
    $attr   - Extra attributes
              DEBUG   - Enable debug mode (default: 0)
              TIMEOUT - Timeout in seconds (default: 30)

  Returns:
    Object instance

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    conf    => $conf,
    debug   => $attr->{DEBUG} || 0,
    timeout => $attr->{TIMEOUT} || 30
  };

  bless $self, $class;

  load_pmodule('JSON');
  $self->{json} = JSON->new->allow_nonref->utf8;

  return $self;
}

#**********************************************************
=head2 chat($attr) - Chat request handler

  Abstract method for sending chat/completion requests.
  Must be implemented in a subclass.

  Arguments:
    $attr   - Extra attributes
              HASHREF - Parameters for chat request
                        (model, messages, options, etc.)

  Returns:
    Result of chat request

  Example:

    my $result = $driver->chat({
      MODEL    => 'some-model',
      MESSAGES => [
        { role => 'user', content => 'Hello' }
      ]
    });

=cut
#**********************************************************
sub chat {
  die "Method 'chat' must be implemented in subclass";
}

#**********************************************************
=head2 embed($attr) - Text embedding generator

  Abstract method for generating embeddings from text.
  Must be implemented in a subclass.

  Arguments:
    $attr   - Extra attributes
              HASHREF - Parameters for embedding request
                        (text, model, options, etc.)

  Returns:
    Embedding vector or structure with embeddings

  Example:

    my $vector = $driver->embed({
      MODEL => 'embedding-model',
      TEXT  => 'Some text'
    });

=cut
#**********************************************************
sub embed {
  die "Method 'embed' must be implemented in subclass";
}

#**********************************************************
=head2 request($method, $url, $attr) - HTTP API request wrapper

  Sends an HTTP request to an external API, handles headers,
  JSON encoding/decoding, errors, and debug logging.

  Arguments:
    $method - HTTP method
              TEXT - GET, POST, PUT, DELETE, etc.
    $url    - Request URL
              TEXT - Full API endpoint
    $attr   - Extra attributes
              HASHREF
                HEADERS - Array reference with extra HTTP headers
                BODY    - Hash reference with request body
                          (will be sent as JSON)

  Returns:
    HASHREF - Decoded JSON response from API
    undef   - On error (see errstr)

  Errors:
    Sets $self->{errstr} on:
      - Empty response
      - Connection timeout
      - JSON decode error
      - API error response

  Example:

    my $response = $self->request(
      'POST',
      'https://api.example.com/v1/chat',
      {
        HEADERS => ['Authorization: Bearer TOKEN'],
        BODY    => {
          model => 'some-model',
          input => 'Hello'
        }
      }
    );

=cut
#**********************************************************
sub request {
  my ($self, $method, $url, $attr) = @_;

  $attr //= {};

  $self->{errstr} = undef;

  my @headers = ('Content-Type: application/json');
  if ($attr->{HEADERS}) {
    push @headers, @{$attr->{HEADERS}};
  }

  my $req_attr = {
    CURL          => 1,
    CURL_OPTIONS  => "-X $method",
    HEADERS       => \@headers,
    DEBUG         => $self->{debug},
    SINGLE_QUOTES => 1
  };

  if ($attr->{BODY}) {
    $req_attr->{JSON_BODY} = $attr->{BODY};
    $req_attr->{JSON_FORMER} = { BOOL_VALUES => 1 };
  }

  my $result = web_request($url, $req_attr);

  if (!defined $result || $result eq '') {
    $self->{errstr} = "Empty response from API";
    warn "Abills::AI::Driver::Base: $self->{errstr} ($url)" if $self->{debug};
    return;
  }

  if ($result =~ /Timeout/i) {
    $self->{errstr} = "Connection timeout";
    warn "Abills::AI::Driver::Base: $self->{errstr} ($url)" if $self->{debug};
    return;
  }

  my $decoded;
  eval {
    $decoded = $self->{json}->decode($result);
  };

  if ($@) {
    $self->{errstr} = "JSON Decode Error: $@";
    warn "Abills::AI::Driver::Base: $self->{errstr}. Raw: $result" if $self->{debug};
    return;
  }

  if ($decoded->{error}) {
    warn "Abills::AI::Driver::Base: $self->{errstr}" if $self->{debug};
    return;
  }

  return $decoded;
}

#**********************************************************
=head2 create_driver($conf, $attr) - AI driver factory

  Creates and returns an AI driver instance based on the
  configured AI provider.

  Arguments:
    $conf   - Configuration hash reference
              HASHREF
                AI_PROVIDER - AI provider name
                              (default: 'Google')
    $attr   - Extra attributes
              HASHREF - Passed directly to driver constructor

  Returns:
    Object instance of Abills::AI::Driver::<Provider>

  Dies:
    If the driver module cannot be loaded

  Example:

    my $driver = $ai->create_driver(
      { AI_PROVIDER => 'OpenAI', API_KEY => 'secret' },
      { DEBUG => 1 }
    );

=cut
#**********************************************************
sub create_driver {
  my ($self, $conf, $attr) = @_;

  $attr //= {};
  my $provider = $conf->{AI_PROVIDER} || 'Google';
  my $driver_class = "Abills::AI::Driver::$provider";

  eval "require $driver_class";
  die "Failed to load AI driver '$provider': $@" if $@;

  return $driver_class->new($conf, $attr);
}

1;