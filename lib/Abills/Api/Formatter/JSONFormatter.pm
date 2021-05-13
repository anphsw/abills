package Abills::Api::Formatter::JSONFormatter;

use JSON;

use strict;
use warnings;

use Abills::Api::Camelize;

#**********************************************************
=head2 new($use_camelize)
#   Arguments:
#     $use_camelize - respons keys will be transforemed to camelCase

=cut
#**********************************************************
sub new {
  my ($class, $use_camelize, $excluded_filds) = @_;

  my %excluded_filds_hash = map { $_ => 1 } @{ $excluded_filds };

  my $self = {
    use_camelize   => $use_camelize,
    excluded_filds => \%excluded_filds_hash
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 format($data, $type)

=cut
sub format() {
  my ($self, $data, $type, $errno, $errstr) = @_;

  if($errno && $errstr) {
    return to_json {
      errno => $errno,
      errstr => $errstr
    }
  }

  if(ref $data eq 'ARRAY' || (defined $type && $type eq 'ARRAY')) {
    foreach( @{ $data }) {
      $_ = transform_hash($self, $_);
    }

    return to_json $data;
  } else {
    return to_json transform_hash($self, $data);
  }
}


#**********************************************************
=head2 transform_hash($data)
#   Arguments:
#     $data - ref to hash or scalar which will be transform to json

#   Return:
#     $modified_hash - hash without internal hash and normilized keys
=cut
#**********************************************************
sub transform_hash() {
  my ($self, $data) = @_;

  my %response = ();

  unless(ref $data) {
    my $result_key = $self->{use_camelize} ? 'result' : 'RESULT';

    if ($data == 0 || $data == 1) {
      $response{ $result_key } = $data ? 'OK' : 'BAD';
    }
    else {
      $response{ $result_key } = $data;
    }
  }
  elsif($data) {
    for my $data_key (keys %{ $data }) {
      if (exists($self->{excluded_filds}->{$data_key})) {
        next;
      }

      if((!ref $data->{$data_key} eq '' || $data_key eq '' || !defined $data->{$data_key}) && !(ref $data->{$data_key} eq 'ARRAY')) {
        next;
      }

      $response{
        $self->{use_camelize} ? Abills::Api::Camelize::camelize($data_key) : $data_key
      } = $data->{$data_key};
    }
  }

  return \%response;
}

1;