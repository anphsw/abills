#!/usr/bin/perl
use strict;
use warnings;

use lib '../../../../../';
use lib '../../../../../lib/';

use Test::More;

use_ok('Abills::Api::Postman::Api');
use_ok('Abills::Api::Postman::Import');
use_ok('JSON');
use_ok('Data::Compare');

use Abills::Base qw(parse_arguments);
use Abills::Api::Postman::Import;
use JSON qw(decode_json);

#define conf
our %conf;
require 'libexec/config.pl';

my $argv = parse_arguments(\@ARGV);

my $Postman_import = Abills::Api::Postman::Import->new({
  conf   => \%conf,
  debug  => $argv->{debug},
  type   => 'user',
  import => 1,
});

my $mock = _read_mock();

$Postman_import->process($mock);

#**********************************************************
=head2 _read_mock($attr) - read mock file for import

  Return:
    content: obj

=cut
#**********************************************************
sub _read_mock {
  my $content = '';
  if (open(my $fh, '<', './import_mock.json')) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);

    $content = decode_json($content);
  }
  else {
    print "Error to read ./import_mock.json $!\n";
  }

  return $content;
}

done_testing();

1;
