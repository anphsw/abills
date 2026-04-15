package AI;

=head NAME

  AI - database layer for AI features (embeddings, cache, stats)

=cut

use strict;
use parent qw(dbcore);

our $VERSION = '0.01';
my $MODULE = 'AI';

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 embedding_get($attr)

  Arguments:
    HASH   - sha256 hash
    MODEL  - model name

  Returns:
    hashref | undef

=cut
#**********************************************************
sub embedding_get {
  my ($self, $attr) = @_;

  return undef if (!$attr->{HASH} || !$attr->{MODEL});

  my $sql = <<'SQL';
    SELECT
      id,
      vector,
      created_at
    FROM ai_embeddings
    WHERE hash = ? AND model = ?
    LIMIT 1;
SQL

  $self->query($sql, undef,
    {
      INFO => 1,
      Bind => [ $attr->{HASH}, $attr->{MODEL} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 embedding_add($attr)

  Arguments:
    HASH
    MODEL
    VECTOR (JSON)
    CREATED_AT (optional)

=cut
#**********************************************************
sub embedding_add {
  my ($self, $attr) = @_;

  return $self->query_add('ai_embeddings', {
    HASH       => $attr->{HASH},
    MODEL      => $attr->{MODEL},
    VECTOR     => $attr->{VECTOR},
    CREATED_AT => $attr->{CREATED_AT} || 'NOW()',
  });
}

#**********************************************************
=head2 embedding_delete_old($attr)

  Arguments:
    DAYS - keep last N days (default 90)

=cut
#**********************************************************
sub embedding_delete_old {
  my ($self, $attr) = @_;

  my $days = $attr->{DAYS} || 90;

  my $sql = qq{
    DELETE FROM ai_embeddings
    WHERE created_at < (NOW() - INTERVAL $days DAY)
  };

  $self->query($sql, 'do');

  return $self;
}

1;
