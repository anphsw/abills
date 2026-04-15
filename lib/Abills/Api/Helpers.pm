package Abills::Api::Helpers;

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Abills::Base qw(encode_base64);

our $VERSION = 0.05;

our @EXPORT = qw(
  static_string_generate
  caesar_cipher
  password_converter
);

our @EXPORT_OK = qw(
  static_string_generate
  caesar_cipher
  password_converter
);

#**********************************************************
=head2 static_string_generate($string, $integer)

=cut
#**********************************************************
sub static_string_generate {
  my ($string, $integer) = @_;

  return length($string) * 21 * $integer;
}

#**********************************************************
=head2 caesar_cipher($string, $integer)

=cut
#**********************************************************
sub caesar_cipher {
  my ($string, $integer) = @_;

  my $MIN = ord '!';

  return join '',
    map {
      my $let = ord($_) - $integer;
      if ($let < $MIN) {
        my $delta = abs($let - $MIN);
        $let = 126 - $delta + 1;
      }
      $_ eq ' ' ? ' ' : chr $let;
    } split '', $string;
}

#**********************************************************
=head2 password_converter($string, $$encode_type)

  Arguments:
    $password: str      - Password string to encode
    $encode_type: str   - Encoding type: 'BASE64', 'HEX_STRING', or 'XOR'
    $key: str           - Encoding key, used for XOR

  Results:
    Encoded password string

=cut
#**********************************************************
sub password_converter {
  my ($password, $encode_type, $key) = @_;

  return $password if (!$password);

  $encode_type = uc($encode_type || '');

  if (!$encode_type || ($encode_type ne 'BASE64' && $encode_type ne 'HEX_STRING' && $encode_type ne 'XOR')) {
    $encode_type = 'BASE64'
  }

  if ($encode_type eq 'BASE64') {
    my $res = encode_base64($password, '');
    $res =~ s/[\r\n]+//xg;
    return $res;
  }
  elsif ($encode_type eq 'HEX_STRING') {
    return unpack('H*', $password);
  }
  elsif ($encode_type eq 'XOR') {
    $key ||= 42;

    my $encoded = '';
    for my $i (0 .. length($password) - 1) {
      $encoded .= chr(ord(substr($password, $i, 1)) ^ hex($key));
    }
    my $res = encode_base64($encoded, '');
    $res =~ s/[\r\n]+//xg;
    return $res;
  }

  return $password;
}

1;
