package Abills::Google;

=head1 NAME

  Abills::Google

=head1 SYNOPSIS

  use Abills::Google;

  my $Google = Abills::Google->new({
    file_path => '/home/user/abillscrm-8fbdeabf4f18.json',
    scope     => [ 'https://www.googleapis.com/auth/cloud-platform', 'https://mail.google.com' ]
  });

  my $url = 'https://dns.googleapis.com/dns/v1/projects/testproject';
  my $result = $Google->request($url);

=cut

use strict;
use warnings;

use Abills::Base qw(in_array load_pmodule);
use Crypt::JWT qw(encode_jwt);
use Abills::Fetcher qw(web_request);

our $VERSION = 1.00;

use constant OAUTH2_TOKEN_ENDPOINT => 'https://www.googleapis.com/oauth2/v4/token';
use constant OAUTH2_CLAIM_AUDIENCE => 'https://www.googleapis.com/oauth2/v4/token';
use constant JWT_GRANT_TYPE => 'urn:ietf:params:oauth:grant-type:jwt-bearer';
use constant JWT_ALGORITHM => 'RS256';
use constant JWT_TYP => 'JWT';
use constant OAUTH2_TOKEN_LIFETIME_SECS => 3600;

my $json;

#**********************************************************
=head2 new($attr) - Constructor for initializing the object

  Arguments:
    $attr         - Attributes for object initialization
       file_path   - Path to a file
       scope       - Array reference containing scopes
       DEBUG       - Debug flag

  Returns:
    Initialized object

  Example:

    my $obj = new({
      file_path => 'path/to/file.json',
      scope     => ['scope1', 'scope2']
    });

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = {
    file_path => $attr->{file_path} || '',
    scope     => $attr->{scope} ? ref $attr->{scope} eq 'ARRAY' ? $attr->{scope} : [ $attr->{scope} ] : []
  };
  bless($self, $class);

  $self->{debug} = $attr->{DEBUG} || 0;

  load_pmodule('JSON');
  $json = JSON->new()->utf8(0);

  $self->_readfile() if $self->{file_path};

  return $self;
}

#**********************************************************
=head2 access_token() - Get or generate an access token

  Returns:
    Object with an access token and expiration time

=cut
#**********************************************************
sub access_token {
  my $self = shift;

  return $self if $self->{access_token} && $self->{expires_in} && $self->{expires_in} > time();
  return $self if !$self->{private_key};

  my $data = {
    iss => $self->{iss} || $self->{client_email},
    scope => join(' ', @{$self->{scope}}),
    aud => OAUTH2_CLAIM_AUDIENCE,
    exp => time() + OAUTH2_TOKEN_LIFETIME_SECS,
    iat => time(),
  };

  delete $self->{expires_in};
  $self->{token} = encode_jwt(payload => $data, alg => JWT_ALGORITHM, key => \$self->{private_key});
  return $self if !$self->{token};

  my $access_token = $self->_send_request(OAUTH2_TOKEN_ENDPOINT, {
    POST    => join('&', ("grant_type=" . JWT_GRANT_TYPE, "assertion=$self->{token}")),
    HEADERS => [ 'Content-Type: application/x-www-form-urlencoded' ]
  });

  if ($access_token->{error}) {
    $self->{errno} = $access_token->{error};
    $self->{errstr} = $access_token->{error_description};
  }

  $self->{access_token} = $access_token->{access_token};
  $self->{expires_in} = $data->{exp};

  return $self;
}

#**********************************************************
=head2 request($url) - Make an authorized HTTP request

  Arguments:
    $url   - URL for the HTTP request

  Returns:
    Hash ref containing the response data

=cut
#**********************************************************
sub request {
  my $self = shift;
  my $url = shift;

  return {} if !$url;

  $self->access_token();
  my @header = ("Authorization: Bearer $self->{access_token}");

  return $self->_send_request($url, { HEADERS => \@header });
}

#**********************************************************
=head2 _send_request($url, $attr) - Send an HTTP request

  Arguments:
    $url    - URL for the HTTP request
    $attr   - Additional attributes for the request
       HEADERS - Array reference containing request headers
       POST    - POST data for the request

  Returns:
    Hash ref containing the response data or result string

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my $url = shift;
  my ($attr) = @_;

  return {} if !$url;

  my $header = $attr->{HEADERS} || [];
  my $result = web_request($url, {
    POST       => $attr->{POST},
    HEADERS    => $header,
    CURL       => 1,
    DEBUG      => $self->{debug},
  });

  return $json->decode($result) if ($result && $result =~ /\{/);
  return { result => $result };
}

#**********************************************************
=head2 _readfile() - Read and load data from a JSON file

  Returns:
    Contents of the loaded JSON file

=cut
#**********************************************************
sub _readfile {
  my $self = shift;

  return '' if !$self->{file_path};

  open my $handler, '<', $self->{file_path} or die "$self->{file_path} not found";
  my $key_contents = join('', <$handler>);
  close $handler;

  my $json_content = $json->decode($key_contents);

  foreach my $key (keys %{$json_content}) {
    $self->{$key} = $json_content->{$key};
  }

  return $key_contents;
}

1;
