#!/usr/bin/perl

package Botapi;
use strict;
use warnings FATAL => 'all';

use JSON;

my $debug = 0;
my $curl = '';

#**********************************************************
=head2 new($token)

=cut
#**********************************************************
sub new {
  my ($class, $token, $chat_id, $curl_path) = @_;

  $chat_id //= "";
  $curl = $curl_path;

  my $self = {
    api_url  => "https://api.telegram.org/bot$token/",
    file_url => "https://api.telegram.org/file/bot$token/",
    chat_id  => $chat_id,
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

  my $json_str = $self->perl2json($attr);
  my $params   = qq(-d '$json_str' -H "Content-Type: application/json");
  my $url      = $self->{api_url} . 'sendMessage';
  my $result   = `$curl $params -s -X POST "$url"`;

  if ($debug > 0) {
    `echo 'COMMAND: curl $params -s -X POST "$url"' >> /tmp/telegram.log`;
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

  my $json_str = $self->perl2json($attr);
  my $params   = qq(-d '$json_str' -H "Content-Type: application/json");
  my $url      = $self->{api_url} . 'sendContact';
  my $result   = `$curl $params -s -X POST "$url"`;

  if ($debug > 0) {
    `echo 'COMMAND: curl $params -s -X POST "$url"' >> /tmp/telegram.log`;
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

  my $json_str = qq({\"file_id\":\"$file_id\"});
  my $params   = qq(-d '$json_str' -H "Content-Type: application/json");
  my $url      = $self->{api_url} . 'getFile';
  my $result   = `$curl $params -s -X POST "$url"`;

  # result {"ok":true,"result":{"file_id":"AgADAgADXKoxG4gfmUgruv78JsXopm-4UQ8ABJ5-3HxAVpDBO1EBAAEC","file_size":25011,"file_path":"photos/file_0.jpg"}}
  # or {"ok":false,"error_code":404,"description":"Not Found"}

  if ($debug > 0) {
    `echo 'COMMAND: curl $params -s -X POST "$url"' >> /tmp/telegram.log`;
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }

  my $hash_result = from_json($result);
  return '' unless ($hash_result && ref $hash_result eq 'HASH' && $hash_result->{result});
  my $file_path = $hash_result->{result}->{file_path};
  my $file_size = $hash_result->{result}->{file_size};
  my $file_url = $self->{file_url} . $file_path;
  my $file_content = `$curl -s "$file_url"`;

  return ($file_path, $file_size, $file_content);
}

#**********************************************************
=head2 perl2json()

=cut
#**********************************************************
sub perl2json {
  my $self = shift;
  my ($data) = @_;
  my @json_arr = ();

  if (ref $data eq 'ARRAY') {
    foreach my $key (@{$data}) {
      push @json_arr, $self->perl2json($key);
    }
    return '[' . join(',', @json_arr) . "]";
  }
  elsif (ref $data eq 'HASH') {
    foreach my $key (sort keys %$data) {
      my $val = $self->perl2json($data->{$key});
      push @json_arr, qq{\"$key\":$val};
    }
    return '{' . join(',', @json_arr) . "}";
  }
  else {
    $data //='';
    return "true" if ($data eq "true");
    return qq{\"$data\"};
  }
}


1;

