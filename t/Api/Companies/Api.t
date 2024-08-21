=head1 NAME

  Companies API test

=cut

use strict;
use warnings;

BEGIN {
  use FindBin '$Bin';
  my $base_dir = '/usr/abills/';

  if ($Bin =~ m/\/abills(\/)/) {
    $base_dir = substr($Bin, 0, $-[1]);
    $base_dir .= '/';
  }

  unshift(@INC, $base_dir . 'lib/');
}

use Test::More;
use FindBin qw($RealBin);
use JSON;

# This test is example how legacy test will like
use Abills::Api::Tests::Init qw(test_runner folder_list help $db $admin %conf);
use Abills::Base qw(parse_arguments);
use Companies;

my $Companies = Companies->new($db, $admin, \%conf);

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $companies = $Companies->list({
  COLS_NAME => 1,
});

my $company_id = $companies->[-1]->{id} || 0;

foreach my $test (@test_list) {
  if ($test->{path} =~ /:id/g) {
    if ($test->{method} eq 'GET') {
      $test->{path} =~ s/:id/$company_id/g;
    }
    else {
      $test->{path} =~ s/:id/26000/g;
    }
  }
}

test_runner({
  argv   => $ARGS,
  apiKey => $apiKey,
  debug  => $debug
}, \@test_list);

done_testing();

1;
