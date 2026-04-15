package Abills::AI::Qdrant;

use strict;
use warnings;

use Abills::Fetcher qw/web_request/;
use Abills::Base qw/load_pmodule/;
use Abills::Backend::Utils qw/json_encode_safe/;

#**********************************************************
=head2 new($conf, $attr) - Object constructor

  Arguments:
    $conf  - Configuration hash
       QDRANT_HOST - Qdrant service URL (default: http://127.0.0.1:6333)

    $attr  - Extra attributes
       DEBUG - Enable debug mode

  Returns:
    Object

  Example:

    my $object = Module->new(
      { QDRANT_HOST => 'http://localhost:6333' },
      { DEBUG => 1 }
    );

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  $conf //= {};
  $attr //= {};

  my $self = {
    host  => $conf->{QDRANT_HOST} || 'http://127.0.0.1:6333',
    debug => $attr->{DEBUG}
  };

  bless $self, $class;

  load_pmodule('JSON');
  $self->{json} = JSON->new->allow_nonref;

  return $self;
}

#**********************************************************
=head2 create_collection($attr) - Create Qdrant collection

  Arguments:
    $attr - Collection attributes
       name         - Collection name
       vector_size  - Vector size (dimensions)
       distance     - Distance metric (default: Cosine)
       shards       - Number of shards (default: 1)
       hnsw         - HNSW configuration hash (optional)

  Returns:
    Result of API request

  Example:

    $object->create_collection({
      name        => 'documents',
      vector_size => 768,
      distance    => 'Cosine',
      shards      => 2,
      hnsw        => {
        m               => 16,
        ef_construct    => 100,
        full_scan_threshold => 10000,
      }
    });

=cut
#**********************************************************
sub create_collection {
  my ($self, $attr) = @_;

  return $self->request("PUT", "/collections/$attr->{name}", {
    BODY => {
      vectors      => {
        size     => $attr->{vector_size},
        distance => $attr->{distance} || 'Cosine',
      },
      shard_number => $attr->{shards} || 1,
      ($attr->{hnsw} ? (hnsw_config => $attr->{hnsw}) : ()),
    }
  });
}

#**********************************************************
=head2 delete_collection($name) - Delete Qdrant collection

  Arguments:
    $name - Collection name

  Returns:
    Result of API request

  Example:

    $object->delete_collection('documents');

=cut
#**********************************************************
sub delete_collection {
  my ($self, $name) = @_;

  return $self->request("DELETE", "/collections/$name");
}

#**********************************************************
=head2 upsert($attr) - Insert or update points in collection

  Arguments:
    $attr - Point attributes
       collection - Collection name
       id         - Point ID (used if points is not provided)
       vector     - Vector data (arrayref of numbers)
       payload    - Payload hash (optional)
       points     - Arrayref of points for batch upsert (optional)

  Notes:
    - If C<points> is provided, fields C<id>, C<vector> and C<payload> are ignored
    - Vector values are cast to numeric values automatically

  Returns:
    Result of API request

  Example:

    $object->upsert({
      collection => 'documents',
      id         => 1,
      vector     => [0.12, 0.98, 0.33],
      payload    => {
        title => 'Test document'
      }
    });

    $object->upsert({
      collection => 'documents',
      points => [
        {
          id     => 1,
          vector => [0.1, 0.2, 0.3],
          payload => { category => 'news' }
        },
        {
          id     => 2,
          vector => [0.4, 0.5, 0.6],
          payload => { category => 'blog' }
        }
      ]
    });

=cut
#**********************************************************
sub upsert {
  my ($self, $attr) = @_;

  if ($attr->{vector}) {
    my $vector = [
      map {0 + $_} @{$attr->{vector}}
    ];

    $attr->{vector} = $vector;
  }

  my $points_data = $attr->{points} ? $attr->{points} : [ {
    id      => $attr->{id},
    vector  => $attr->{vector},
    payload => $attr->{payload} || {},
  } ];

  return $self->request("PUT", "/collections/$attr->{collection}/points", {
    BODY => {
      points => $points_data
    }
  });
}

#**********************************************************
=head2 delete($attr) - Delete point from collection

  Arguments:
    $attr - Delete attributes
       collection - Collection name
       id         - Point ID

  Returns:
    Result of API request

  Example:

    $object->delete({
      collection => 'documents',
      id         => 123
    });

=cut
#**********************************************************
sub delete {
  my ($self, $attr) = @_;

  return $self->request("POST", "/collections/$attr->{collection}/points/delete", {
    BODY => {
      points => [ $attr->{id} ]
    }
  });
}

#**********************************************************
=head2 search($attr) - Search points in collection

  Arguments:
    $attr - Search attributes
       collection - Collection name
       vector     - Query vector (arrayref of numbers)
       limit      - Result limit (default: 10)
       filter     - Search filter (optional)

  Returns:
    Search result from API

  Example:

    my $result = $object->search({
      collection => 'documents',
      vector     => [0.12, 0.98, 0.33],
      limit      => 5,
      filter     => {
        must => [
          {
            key   => 'category',
            match => { value => 'news' }
          }
        ]
      }
    });

=cut
#**********************************************************
sub search {
  my ($self, $attr) = @_;

  return $self->request("POST", "/collections/$attr->{collection}/points/search", {
    BODY => {
      vector       => $attr->{vector},
      limit        => $attr->{limit} || 10,
      ($attr->{filter} ? (filter => $attr->{filter}) : ()),
      with_payload => JSON::true,
    }
  });
}

#**********************************************************
=head2 request($method, $path, $attr) - Perform API request

  Arguments:
    $method - HTTP method (GET, POST, PUT, DELETE)
    $path   - API endpoint path
    $attr   - Request attributes
       BODY    - Request body hash (optional)
       HEADERS - Additional HTTP headers (optional)

  Returns:
    Decoded JSON response hash

  Notes:
    - Automatically encodes request body to JSON
    - Vector values are cast to numeric values
    - Sets C<errstr> on error and returns undef

  Example:

    my $result = $object->request(
      'POST',
      '/collections/documents/points/search',
      {
        BODY => {
          vector => [0.1, 0.2, 0.3],
          limit  => 5
        }
      }
    );

=cut
#**********************************************************
sub request {
  my ($self, $method, $path, $attr) = @_;

  $attr //= {};

  $self->{errstr} = undef;

  my $url = $self->{host} . $path;

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
    if ($attr->{BODY}{vector} && ref $attr->{BODY}{vector} eq 'ARRAY') {
      my $vector = [
        map {0 + $_} @{$attr->{BODY}{vector}}
      ];
      $attr->{BODY}{vector} = $vector;
    }

    my $post = json_encode_safe($attr->{BODY});
    # $post =~ s/\"/\\\"/gx;

    $req_attr->{POST} = $post;
  }

  my $result = web_request($url, $req_attr);

  if (!defined $result || $result eq '') {
    $self->{errstr} = "Empty response from API";
    warn "Abills::AI::Qdrant: $self->{errstr} ($url)" if $self->{debug};
    return;
  }

  if ($result =~ /Timeout/i) {
    $self->{errstr} = "Connection timeout";
    warn "Abills::AI::Qdrant: $self->{errstr} ($url)" if $self->{debug};
    return;
  }

  my $decoded;
  eval {
    $decoded = $self->{json}->decode($result);
  };

  if ($@) {
    $self->{errstr} = "JSON Decode Error: $@";
    warn "Abills::AI::Qdrant: $self->{errstr}. Raw: $result" if $self->{debug};
    return;
  }

  if ($decoded->{error}) {
    $self->{errstr} = "API Error: " . ($decoded->{error}->{message} || 'Unknown error');
    warn "Abills::AI::Qdrant: $self->{errstr}" if $self->{debug};
    return;
  }

  return $decoded;
}

1;
