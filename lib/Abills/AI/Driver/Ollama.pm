package Abills::AI::Driver::Ollama;

use strict;
use warnings;

use Abills::Fetcher qw/web_request/;
use Abills::Base qw(in_array load_pmodule);

use base 'Abills::AI::Driver::Base';

#**********************************************************
=head2 new($class, $conf, $attr) - Ollama driver constructor

  Creates a new Ollama AI driver instance and initializes
  connection parameters and embedding configuration.

  Arguments:
    $class - Class name
    $conf  - Configuration hash reference
             HASHREF
               OLLAMA_HOST - Ollama API host
                             (default: http://127.0.0.1:11434)
    $attr  - Extra attributes
             HASHREF
               EMBED_MODEL - Embedding model name
                             (default: nomic-embed-text)
               DEBUG       - Enable debug mode

  Returns:
    Object instance of Ollama AI driver

  Example:

    my $driver = Abills::AI::Driver::Ollama->new(
      { OLLAMA_HOST => 'http://localhost:11434' },
      { EMBED_MODEL => 'nomic-embed-text', DEBUG => 1 }
    );

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    conf        => $conf,
    host        => $conf->{OLLAMA_HOST} || 'http://127.0.0.1:11434',
    embed_model => $attr->{EMBED_MODEL} || 'nomic-embed-text',
    debug       => $attr->{DEBUG}
  };

  bless $self, $class;

  load_pmodule('JSON');
  $self->{json} = JSON->new->allow_nonref;

  return $self;
}

#**********************************************************
=head2 embed($text, $attr) - Generate text embedding via Ollama API

  Generates a vector embedding for the given text using
  the configured Ollama embedding model.

  Arguments:
    $text - Input text for embedding
            TEXT
    $attr - Extra attributes
            HASHREF - Reserved for future options

  Returns:
    ARRAYREF - Embedding vector (list of numeric values)
    undef    - If text or embedding model is not defined,
               or on request error

  Notes:
    - Uses the Ollama `/api/embeddings` endpoint.
    - The prompt is sent as raw text.
    - Returns raw embedding values suitable for vector
      search or similarity calculations.

  Example:

    my $vector = $driver->embed('Text for embedding');
    return unless $vector;

=cut
#**********************************************************
sub embed {
  my ($self, $text, $attr) = @_;

  return if !$text;

  my $embed_model = $self->{embed_model};
  return if !$embed_model;

  $attr //= {};

  my $result = $self->request('POST', "$self->{host}/api/embeddings", {
    BODY    => {
      model  => $embed_model,
      prompt => $text,
    }
  });

  if ($result && $result->{embedding}) {
    return $result->{embedding};
  }

  return;
}

#**********************************************************
=head2 chat($attr) - Chat method stub

  Stub (placeholder) method for chat/completion requests.
  Currently not implemented for this driver.

  Arguments:
    $attr - Extra attributes
            HASHREF - Reserved for future chat options

  Returns:
    undef

  Notes:
    - This method is intentionally left empty.
    - Should be implemented if chat functionality
      is required for this driver.

  Example:

    # Chat is not supported by this driver yet
    my $result = $driver->chat({});

=cut
#**********************************************************
sub chat {
  my ($self, $attr) = @_;

  return;
}

1;
