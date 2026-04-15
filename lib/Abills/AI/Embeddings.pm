package Abills::AI::Embeddings;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON qw(encode_json decode_json);
use Abills::Base qw(json_former);
use AI;

#**********************************************************
=head2 new($class, $db, $admin, $conf, $attr) - Embeddings manager constructor

  Creates a new embeddings manager instance and initializes
  database connection, configuration, admin context, and
  selects an embedding provider.

  Arguments:
    $class - Class name
    $db    - Database handle
    $admin - Admin object/context
    $conf  - Configuration hash reference
             HASHREF
               AI_EMBEDDING_PROVIDER - Default embedding provider
                                       (e.g. Ollama, Google)
    $attr  - Extra attributes
             HASHREF
               PROVIDER - Override embedding provider name
               DEBUG    - Enable debug mode (default: 0)

  Returns:
    Object instance of embeddings manager

  Notes:
    - Provider name is validated against a strict whitelist
      pattern (alphanumeric only) to prevent code injection.
    - Falls back to 'Ollama' if provider name is invalid.
    - Actual provider driver is loaded later based on the
      resolved provider name.

  Example:

    my $embeddings = Abills::AI::Embeddings->new(
      $db,
      $admin,
      { AI_EMBEDDING_PROVIDER => 'Google' },
      { DEBUG => 1 }
    );

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    db    => $db,
    conf  => $conf,
    admin => $admin,
    debug => $attr->{DEBUG} || 0,
  };

  bless $self, $class;

  my $provider_name = $attr->{PROVIDER} || $conf->{AI_EMBEDDING_PROVIDER} || 'Ollama';

  if ($provider_name !~ /^[a-zA-Z0-9]+$/) {
    warn "Abills::AI::Embeddings: Security Warning - Invalid provider name '$provider_name'. Fallback to Ollama.";
    $provider_name = 'Ollama';
  }

  my $driver_class = "Abills::AI::Driver::$provider_name";

  eval "require $driver_class";
  if ($@) {
    die "Abills::AI::Embeddings: Failed to load driver '$driver_class'. Error: $@";
  }

  $self->{driver} = $driver_class->new($conf, $attr->{DRIVER_CONF} || {});

  my $AI_sql = AI->new($db, $admin, $conf);
  $self->{ai_sql} = $AI_sql;

  return $self;
}

#**********************************************************
=head2 vector($attr) - Get or generate embedding vector

  Returns an embedding vector for the given text. If an
  embedding already exists in the database, it is reused.
  Otherwise, a new embedding is generated via the active
  AI driver and stored for future use.

  Arguments:
    $attr - Extra attributes
            HASHREF
              text - Input text for embedding
                     TEXT

  Returns:
    ARRAYREF - Embedding vector (numeric values)
    undef    - If driver is not initialized, text is empty,
               model is missing, or embedding fails

  Workflow:
    1. Validate driver, text, and embedding model.
    2. Generate SHA-256 hash of the input text.
    3. Try to load an existing embedding from storage.
    4. If not found, call driver->embed().
    5. Store the new embedding in the database.
    6. Return the embedding vector.

  Notes:
    - Embeddings are cached by (HASH + MODEL).
    - VECTOR is stored as JSON in the database.
    - Requires driver to implement embed().

  Example:

    my $vector = $embeddings->vector({
      text => 'Some documentation text'
    });

    return unless $vector;

=cut
#**********************************************************
sub vector {
  my ($self, $attr) = @_;

  return if !$self->{driver};

  my $text = $attr->{text} || '';
  my $model = $self->{driver}->{embed_model};

  return if (!length $text || !$model);

  my $hash = sha256_hex($text);

  my $embedding = $self->{ai_sql}->embedding_get({ HASH => $hash, MODEL => $model });

  if ($embedding->{TOTAL} && $embedding->{TOTAL} > 0 && $embedding->{VECTOR}) {
    return decode_json($embedding->{VECTOR});
  }

  return if (!$self->{driver}->can('embed'));

  my $vector = $self->{driver}->embed($text);
  return if !$vector;

  $self->{ai_sql}->embedding_add({
    HASH   => $hash,
    MODEL  => $model,
    VECTOR => json_former($vector)
  });

  return $vector;
}

1;
