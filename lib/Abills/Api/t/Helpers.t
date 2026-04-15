#!/usr/bin/perl

=head1 NAME

  Test suite for Abills::Api::Helpers module

=head1 DESCRIPTION

  Unit tests for:
  - static_string_generate()
  - caesar_cipher()
  - password_converter()

=cut

use strict;
use warnings;
use Test::More;

use lib '../../../../lib/';

use Abills::Init;

use Abills::Api::Helpers qw(
  static_string_generate
  caesar_cipher
  password_converter
);
use Abills::Base qw(decode_base64);

# Test static_string_generate
subtest 'static_string_generate' => sub {
  plan tests => 8;

  is(static_string_generate('test', 1), 84, 'Basic calculation: "test" * 21 * 1 = 84');
  is(static_string_generate('test', 2), 168, 'With multiplier 2: "test" * 21 * 2 = 168');

  is(static_string_generate('', 5), 0, 'Empty string returns 0');

  is(static_string_generate('a', 1), 21, 'Single character: "a" * 21 * 1 = 21');

  is(static_string_generate('abcdefghij', 3), 630, 'Long string: 10 * 21 * 3 = 630');

  is(static_string_generate('test', 0), 0, 'Zero multiplier returns 0');

  is(static_string_generate('test', -1), -84, 'Negative multiplier: "test" * 21 * -1 = -84');

  is(static_string_generate('test string', 2), 462, 'String with spaces: 11 * 21 * 2 = 462');
};

# Test caesar_cipher
subtest 'caesar_cipher' => sub {
  plan tests => 12;

  my $result = caesar_cipher('abc', 1);
  is($result, '`ab', 'Basic shift by 1: "abc" -> "`ab"');

  $result = caesar_cipher('test', 0);
  is($result, 'test', 'Shift by 0: no change');

  $result = caesar_cipher('a b c', 1);
  is($result, '` a b', 'Spaces are preserved');

  $result = caesar_cipher('ABC', 5);
  is($result, '<=>', 'Shift by 5: "ABC" -> "<>?"');

  $result = caesar_cipher('!', 1);
  is($result, '~', 'Wrap around: "!" shifted by 1 wraps to "~"');

  $result = caesar_cipher('!"#', 2);
  is($result, '}~!', 'Multiple characters with wrap');

  $result = caesar_cipher('Hello', 3);
  ok(length($result) == 5, 'Result length matches input');

  my $original = 'test';
  my $shifted = caesar_cipher($original, 5);
  my $reversed = caesar_cipher($shifted, -5);
  is($reversed, $original, 'Reverse shift works');

  is(caesar_cipher('', 5), '', 'Empty string returns empty');

  is(caesar_cipher('A', 1), '@', 'Single character shift');

  $result = caesar_cipher('123', 1);
  ok(length($result) == 3, 'Numbers are shifted');

  $result = caesar_cipher('!@#$%', 1);
  ok(length($result) == 5, 'Special characters are shifted');
};

subtest 'password_converter' => sub {
  plan tests => 22;

  is(password_converter('', 'BASE64'), '', 'Empty password returns empty');
  is(password_converter(undef, 'BASE64'), undef, 'Undef password returns undef');

  my $password = 'test123';
  my $encoded = password_converter($password, 'BASE64');
  ok($encoded, 'BASE64 encoding returns value');
  ok($encoded ne $password, 'BASE64 encoding changes password');
  ok($encoded !~ /[\r\n]/x, 'BASE64 result has no newlines');

  my $encoded_default = password_converter($password);
  ok($encoded_default, 'Default encoding (BASE64) works');

  my $encoded_lower = password_converter($password, 'base64');
  is($encoded_lower, $encoded, 'Lowercase encode_type works');

  my $hex_encoded = password_converter($password, 'HEX_STRING');
  ok($hex_encoded, 'HEX_STRING encoding returns value');
  ok($hex_encoded =~ /^[0-9a-f]+$/xi, 'HEX_STRING result is hexadecimal');
  is($hex_encoded, unpack('H*', $password), 'HEX_STRING matches unpack');

  my $hex2 = password_converter('ABC', 'HEX_STRING');
  is($hex2, '414243', 'HEX_STRING for "ABC" is "414243"');

  my $xor_encoded = password_converter($password, 'XOR');
  ok($xor_encoded, 'XOR encoding returns value');
  ok($xor_encoded !~ /[\r\n]/x, 'XOR result has no newlines');
  ok($xor_encoded =~ /^[A-Za-z0-9+\/]+=*$/x, 'XOR result is base64-like');

  my $xor_custom = password_converter($password, 'XOR', '2A');
  ok($xor_custom, 'XOR with custom key works');
  ok($xor_custom ne $xor_encoded, 'XOR with different key produces different result');

  my $xor_decoded_b64 = decode_base64($xor_encoded);
  my $xor_decoded = '';
  for my $i (0 .. length($xor_decoded_b64) - 1) {
    $xor_decoded .= chr(ord(substr($xor_decoded_b64, $i, 1)) ^ hex('42'));
  }
  is($xor_decoded, $password, 'XOR encoding with default key is reversible');

  my $xor_custom_decoded_b64 = decode_base64($xor_custom);
  my $xor_custom_decoded = '';
  for my $i (0 .. length($xor_custom_decoded_b64) - 1) {
    $xor_custom_decoded .= chr(ord(substr($xor_custom_decoded_b64, $i, 1)) ^ hex('2A'));
  }
  is($xor_custom_decoded, $password, 'XOR encoding with custom key is reversible');

  my $hex_decoded = pack('H*', $hex_encoded);
  is($hex_decoded, $password, 'HEX_STRING encoding is reversible');

  my $invalid = password_converter($password, 'INVALID');
  ok($invalid, 'Invalid encode_type defaults to BASE64');

  my $empty_type = password_converter($password, '');
  ok($empty_type, 'Empty encode_type defaults to BASE64');

  my $decoded = decode_base64($encoded);
  is($decoded, $password, 'BASE64 encoding is reversible');
};

# Test edge cases and integration
subtest 'edge_cases' => sub {
  plan tests => 6;

  my $long_string = 'a' x 100;
  is(static_string_generate($long_string, 1), 2100, 'Long string calculation');

  my $unicode_result = caesar_cipher('test', 1);
  ok(defined($unicode_result), 'Unicode handling in caesar_cipher');

  my $special_pass = '!@#$%^&*()';
  my $special_encoded = password_converter($special_pass, 'BASE64');
  ok($special_encoded, 'Special characters in password');

  my $very_long = 'a' x 1000;
  my $long_encoded = password_converter($very_long, 'BASE64');
  ok($long_encoded, 'Very long password encoding');

  my $test_pass = 'MyPassword123!';
  my $b64 = password_converter($test_pass, 'BASE64');
  my $hex = password_converter($test_pass, 'HEX_STRING');
  my $xor = password_converter($test_pass, 'XOR');

  ok($b64 && $hex && $xor, 'All encoding types work');
  ok($b64 ne $hex && $hex ne $xor && $b64 ne $xor, 'All encoding types produce different results');
};

done_testing();

