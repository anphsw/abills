package Abills::AI::Driver::Google;

use strict;
use warnings;

use Abills::Fetcher qw/web_request/;
use Abills::Base qw/load_pmodule/;

use base 'Abills::AI::Driver::Base';

#**********************************************************
=head2 new($class, $conf, $attr) - Google AI driver constructor

  Creates a new Google AI driver instance and initializes
  connection settings, models, and runtime options.

  Arguments:
    $class - Class name
    $conf  - Configuration hash reference
             HASHREF
               GOOGLE_AI_HOST        - Base API host
                                       (default: https://generativelanguage.googleapis.com/v1beta/models)
               GOOGLE_AI_KEY         - API key for Google AI
               GOOGLE_AI_MODEL       - Default chat model
               GOOGLE_AI_EMBED_MODEL - Default embedding model
    $attr  - Extra attributes
             HASHREF
               MODEL        - Override chat model
               EMBED_MODEL  - Override embedding model
               DEBUG        - Enable debug mode
               TEMPERATURE  - Sampling temperature (default: 0.2)

  Returns:
    Object instance of Google AI driver

  Example:

    my $driver = Abills::AI::Driver::Google->new(
      {
        GOOGLE_AI_KEY   => 'api-key',
        GOOGLE_AI_MODEL => 'gemini-2.5-flash'
      },
      {
        DEBUG       => 1,
        TEMPERATURE => 0.5
      }
    );

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    conf        => $conf,
    host        => $conf->{GOOGLE_AI_HOST} || 'https://generativelanguage.googleapis.com/v1beta/models',
    key         => $conf->{GOOGLE_AI_KEY},
    model       => $conf->{GOOGLE_AI_MODEL} || $attr->{MODEL} || 'gemini-2.5-flash',
    embed_model => $conf->{GOOGLE_AI_EMBED_MODEL} || $attr->{EMBED_MODEL} || 'gemini-embedding-001',
    debug       => $attr->{DEBUG},
    temperature => $attr->{TEMPERATURE} || 0.2,
  };

  bless $self, $class;

  load_pmodule('JSON');
  $self->{json} = JSON->new->allow_nonref;

  return $self;
}

#**********************************************************
=head2 chat($attr) - Send chat request to Google Gemini API

  Sends a chat/completion request to the Google Generative
  Language API using the configured Gemini model.

  Arguments:
    $attr - Extra attributes
            HASHREF
              messages - Array reference with chat messages
                         Each message is a HASHREF:
                           role    - system | user | assistant
                           content - Message text
              model    - Override model name (optional)

  Returns:
    TEXT  - Generated assistant response
    undef - If no messages provided or on error

  Notes:
    - Messages with role 'system' are converted into
      system_instruction.
    - Messages with role 'assistant' are mapped to
      Google role 'model'.
    - Temperature is taken from object configuration.

  Example:

    my $answer = $driver->chat({
      messages => [
        { role => 'system', content => 'You are a helpful assistant' },
        { role => 'user',   content => 'Explain embeddings' }
      ]
    });

=cut
#**********************************************************
sub chat {
  my ($self, $attr) = @_;

  my $messages = $attr->{messages} || [];
  return if scalar(@$messages) < 1;

  my @contents = ();
  my $system_instruction = undef;

  foreach my $msg (@$messages) {
    if ($msg->{role} eq 'system') {
      $system_instruction = {
        parts => [{ text => $msg->{content} }]
      };
    }
    else {
      my $role = ($msg->{role} eq 'assistant') ? 'model' : 'user';

      push @contents, {
        role  => $role,
        parts => [{ text => $msg->{content} }]
      };
    }
  }

  my $body = {
    contents => \@contents,
    generationConfig => {
      temperature => $self->{temperature},
    }
  };

  if ($system_instruction) {
    $body->{system_instruction} = $system_instruction;
  }

  my $model_name = $attr->{model} || $self->{model};

  my $result = $self->request('POST', "$self->{host}/$model_name:generateContent", {
    HEADERS => [ "x-goog-api-key: $self->{key}" ],
    BODY    => $body
  });

  if ($result->{candidates} && $result->{candidates}->[0]->{content}->{parts}) {
    return $result->{candidates}->[0]->{content}->{parts}->[0]->{text};
  }

  return;
}

#**********************************************************
=head2 embed($text) - Generate text embedding via Google Gemini API

  Generates a vector embedding for the given text using
  the configured Google embedding model.

  Arguments:
    $text - Input text for embedding
            TEXT

  Returns:
    ARRAYREF - Embedding vector (list of numeric values)
    undef    - If text or embedding model is not defined,
               or on request error

  Notes:
    - Uses the model defined in embed_model.
    - Sends text as a single content part.
    - Returns raw embedding values suitable for vector
      search or similarity calculations.

  Example:

    my $vector = $driver->embed('Some text to embed');
    return $vector;

=cut
#**********************************************************
sub embed {
  my ($self, $text) = @_;

  return if !$text;

  my $embed_model = $self->{embed_model};
  return if !$embed_model;

  my $result = $self->request('POST', "$self->{host}/$embed_model:embedContent", {
    HEADERS => [ "x-goog-api-key: $self->{key}" ],
    BODY    => {
      model                => "models/$embed_model",
      content              => {
        parts => [ { text => $text } ]
      }
    }
  });

  if ($result && $result->{embedding} && $result->{embedding}->{values}) {
    return $result->{embedding}->{values};
  }

  return;
}

1;