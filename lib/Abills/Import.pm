package Abills::Import;

=head1 NAME

Abills::Import - Import functions

=head1 SYNOPSIS

    use Abills::Import;

    pop3_import();

=cut

use feature 'state';
use strict;
our (%EXPORT_TAGS);

use POSIX qw(locale_h strftime mktime);
use Abills::Base qw/decode_base64 load_pmodule urldecode decode_quoted_printable/;
use parent 'Exporter';
use utf8;

our $VERSION = 1.00;

our @EXPORT = qw(
  pop3_import
);

our @EXPORT_OK = qw(
  pop3_import
);

# As said in perldoc, should be called once on a program
srand();

#**********************************************************
=head2 pop3_import($text, $attr) - Imports emails using the POP3 protocol.

   Attributes:
     $host     - The hostname of the mail server
     $username - The username to use when logging into the mail server
     $password - The password to use when logging into the mail server
     $attr     - A hash reference containing optional parameters
       TIMEOUT - The maximum number of seconds to wait for a response from the server (default is 30)
       SSL - Whether or not to use SSL/TLS encryption (default is 0)

  Returns:

    A hash reference containing the imported email messages, keyed by message number.
    {
      msg_number => {
        header => { header information }
        body => { body information }
      }
    }

  Examples:
     pop3_import('pop3.gmail.com', 'test@gmail.com', 'password', { SSL => 1 });
     pop3_import('pop3.example.com', 'test@gmail.com', 'password', { TIMEOUT => 60 });

=cut
#**********************************************************
sub pop3_import {
  my ($host, $username, $password, $attr) = @_;

  load_pmodule('Net::POP3');

  my $pop3 = Net::POP3->new($host, Timeout => $attr->{TIMEOUT} || 30, SSL => $attr->{SSL} || 0);
  return { errno => '1001', errstr => "POP3 Error: Can't connect '$host' $!" } if !$pop3;

  return { errno => '1002', errstr => 'Authentication failed' } if !$pop3->login($username, $password);

  my $result = {};
  my $msg_nums = $pop3->list;

  foreach my $msg_num (keys %{$msg_nums}) {
    my $message = $pop3->get($msg_num);
    my $full_message = join('', @{$message});
    my ($header, $body) = split(/\r?\n\r?\n/, $full_message, 2);
    my @lines = split(/\r?\n/, $header);
    $result->{$msg_num} = {};

    my %header_fields = ();
    foreach my $line (@lines) {
      next if ($line !~ /^(.*?):\s*(.*?)\s*$/);

      my $field = lc $1;
      my $value = $2;
      $header_fields{$field} = $value;
    }

    $header_fields{boundary} = [];
    push @{$header_fields{boundary}}, "--$1" if ($header =~ /boundary=\"?([^\"]+)\"?/);
    push @{$header_fields{boundary}}, "--$1" if ($body =~ /boundary=\"?([^\"]+)\"?/);
    $result->{$msg_num}{header} = \%header_fields;

    my @parts = $header_fields{boundary}[0] ? split(join('|', @{$header_fields{boundary}}), $body, ) : ($body);

    foreach my $part (@parts) {
      my ($part_header, $part_body) = $part =~ /Content-Type:/ ? split(/\r?\n\r?\n/, $part, 2) : ('', $part);

      next if !defined $part_header || !$part_body;

      if ($part_header =~ /Content-Transfer-Encoding: ([\w]+)/i) {
        my $encoding = $1;
        $encoding =~ s/[^\w-]//g;
        if ($encoding eq 'base64') {
          $part_body = decode_base64($part_body)
        }
      }

      if ($part_header =~ /filename=(\w+)/i) {
        my $filename = $1;
        my $content_type = $part_header =~ /Content-Type:\s?(.+);/i ? $1 : '';

        push @{$result->{$msg_num}{body}{files}}, {
          filename       => $filename,
          Contents       => $part_body,
          'Content-Type' => $content_type
        };
        next;
      }

      # if ($part_header =~ /Content-Type: text\/plain/) {
      #   $result->{$msg_num}{body}{text} = $part_body;
      #   next;
      # }
      if ($part_header =~ /Content-Type: text\/html/) {
        $result->{$msg_num}{body}{html} = $part_body;
        next;
      }
      $result->{$msg_num}{body}{text} = decode_quoted_printable($part_body) if !$result->{$msg_num}{body}{text};
    }
  }

  $pop3->quit();
  return $result;
}

#**********************************************************
=head2 decode_quoted_printable($text) - Decode quoted printable text

   Attributes:
     $text - Text to decode

  Returns:
    Decoded text

  Examples:
     convert('=D0=9F=D1=80=D0=B8=D0=B2=D1=96=D1=82')
     # Returns 'Привіт'

=cut
#**********************************************************
sub decode_quoted_printable {
  my $text = shift;

  $text =~ s/\r\n/\n/g;
  $text =~ s/[ \t]+\n/\n/g;
  $text =~ s/=\n//g;

  if (ord('A') == 193) { # EBCDIC style machine
    if (ord('[') == 173) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('cp1047',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
    elsif (ord('[') == 187) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('posix-bc',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
    elsif (ord('[') == 186) {
      $text =~ s/=([\da-fA-F]{2})/Encode::encode('cp37',Encode::decode('iso-8859-1',pack("C", hex($1))))/ge;
    }
  }
  else { # ASCII style machine
    $text =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
  }
  $text;
}


1;