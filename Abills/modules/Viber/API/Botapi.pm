#!/usr/bin/perl

package Botapi;
use strict;
use warnings FATAL => 'all';
use JSON;

use Abills::Fetcher qw/web_request/;

my $debug = 0;
my $curl = '';

#**********************************************************
=head2 new($token)

=cut
#**********************************************************
sub new {
  my ($class, $token, $receiver, $curl_path, $SELF_URL) = @_;

  $receiver //= "";
  $curl = $curl_path;

  my $self = {
    token  => $token,
    receiver  => $receiver,
    SELF_URL => "https://$SELF_URL:9443",
    api_url => 'https://chatapi.viber.com/pa/'
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

  $attr->{receiver} ||= $self->{receiver};

  $attr->{min_api_version} = 7;

  my $json_str = $self->perl2json($attr);
  my $url      = $self->{api_url} . 'send_message';

  my @header = ( 'Content-Type: application/json', 'X-Viber-Auth-Token: '.$self->{token} );
  $json_str =~ s/\"/\\\"/g;


  web_request($url, {
    POST         => $json_str,
    HEADERS      => \@header,
    CURL         => 1,
    CURL_OPTIONS => '-XPOST',
  });

  return 1;
}

#**********************************************************
=head2 get_file($file_id)

=cut
#**********************************************************
sub get_file {
  my $self = shift;
  my ($file_id) = @_;

  my ($file_path, $file_name, $file_size) = $file_id =~ /(.*)\|(.*)\|(.*)/;
  my $file_content = web_request($file_path, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  return ($file_name, $file_size, $file_content);
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

