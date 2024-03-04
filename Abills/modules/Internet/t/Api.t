=head1 NAME

  Internet API test

=cut
use strict;
use warnings;

use lib '../../../../lib';

use FindBin qw($RealBin);
use Test::More;
use Abills::Api::Tests::Init qw(test_runner folder_list help);
use Abills::Base qw(parse_arguments);

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @tests = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@tests);

done_testing();

1;
