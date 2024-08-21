package Abills::Api::Postman::Api;
use strict;
use warnings FATAL => 'all';

use Abills::Fetcher qw(web_request);

#**********************************************************
=head2 new($db, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $attr) = @_;

  my $self = {
    conf          => $attr->{conf} || $attr->{CONF},
    debug         => $attr->{debug} || $attr->{DEBUG},
    collection_id => $attr->{collection_id} || '',
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 collection_info($attr) - get collection info

  Arguments:
    $attr
      collection_id ?: str - id of collection

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub collection_info {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';

  my $collection = $self->make_request({
    method => 'GET',
    path   => "collections/$id"
  });

  return $collection;
}

#**********************************************************
=head2 collection_update($attr) - update info inside collection

  Arguments:
    $attr
      collection_id ?: str - id of collection

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub collection_update {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';

  my $collection = $self->make_request({
    method => 'PATCH',
    path   => "collections/$id",
    body   => $attr->{request} || {},
  });

  return $collection;
}

#**********************************************************
=head2 folder_info($attr) - folder info

  Arguments:
    $attr
      folder_id: str      - name of folder
      collection_id?: str - id of collection

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub folder_info {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';
  my $folder_id = $attr->{folder_id} || '';

  my $request = $self->make_request({
    method => 'GET',
    path   => "collections/$id/folders/$folder_id?populate=true",
    body   => $attr->{request},
  });

  return $request;
}

#**********************************************************
=head2 folder_create($attr) - create folder

  Arguments:
    $attr
      folder_name: str    - name of folder
      folder_id?: str     - parent folder
      collection_id?: str - id of collection

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub folder_create {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{folder_name}) {
    return {
      error => {
        name    => 'local billing error',
        message => 'No parameter folder_name request did not make'
      }
    };
  }

  my $id = $attr->{collection_id} || $self->{collection_id} || '';

  my $body = {
    name => $attr->{folder_name},
  };

  $body->{folder} = $attr->{folder_id} if ($attr->{folder_id});

  my $folder = $self->make_request({
    method => 'POST',
    path   => "collections/$id/folders",
    body   => $body
  });

  return $folder;
}

#**********************************************************
=head2 request_info($attr) - get info about request

  Arguments:
    $attr
      request_id: str     - name of folder
      collection_id?: str - id of collection

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub request_info {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';
  my $request_id = $attr->{request_id} || '';

  my $request = $self->make_request({
    method => 'GET',
    path   => "collections/$id/requests/$request_id?populate=true",
  });

  return $request;
}

#**********************************************************
=head2 request_add($attr) - add request

  Arguments:
    $attr
      folder_id: str      - id of folder
      collection_id?: str - id of collection
      request: obj        - request hash

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub request_add {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';
  my $folder_id = $attr->{folder_id} || '';

  my $request = $self->make_request({
    method => 'POST',
    path   => "collections/$id/requests?folder=$folder_id",
    body   => $attr->{request},
  });

  return $request;
}

#**********************************************************
=head2 request_change($attr) - update request

  Arguments:
    $attr
      request_id: str     - name of folder
      collection_id?: str - id of collection
      request: obj        - request hash

  Results:
    $self->make_request(...);

=cut
#**********************************************************
sub request_change {
  my $self = shift;
  my ($attr) = @_;

  my $id = $attr->{collection_id} || $self->{collection_id} || '';
  my $request_id = $attr->{request_id} || '';

  my $request = $self->make_request({
    method => 'PUT',
    path   => "collections/$id/requests/$request_id",
    body   => $attr->{request},
  });

  return $request;
}

#**********************************************************
=head2 make_request($attr) - make request

  Arguments:
    $attr
      method    - http methods

        POST
        GET

      path      - API route
      body      - body of request JSON
      headers   - headers of request

    P.S Example of forming URL
        base url - https://api.getpostman.com/
      +
        path param - collections

      In result -   https://api.getpostman.com/collections

  Results:
    $result hash

=cut
#**********************************************************
sub make_request {
  my $self = shift;
  my ($attr) = @_;

  my $req_url = "https://api.getpostman.com/$attr->{path}";
  my @req_headers = ('Content-Type: application/json', "X-API-Key: $self->{conf}->{POSTMAN_API_KEY}");
  my $req_body = '';

  if ($attr->{method} ne 'GET') {
    $req_body = $attr->{body};
  }

  my $result = web_request($req_url, {
    METHOD      => $attr->{method},
    HEADERS     => \@req_headers,
    JSON_BODY   => $attr->{body},
    JSON_RETURN => 1,
    DEBUG       => ($self->{debug}) ? 4 : 0,
  });

  if ($result->{errno}) {
    $result->{error} = $result->{errno};
    $result->{name} = "ABILLS_FETCHER_ERROR";
    $result->{message} = $result->{errstr};
  }

  return $result;
}

1;
