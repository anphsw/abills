=head1 NAME

  Equipment API test

=cut

use strict;
use warnings;
use FindBin '$Bin';

BEGIN {
  our $libpath = $Bin . '/../../../../';
  do "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Api::Tests::Init qw(test_runner folder_list help db_connect);
use Equipment;

our (
  %conf
);

my ($db, $admin) = db_connect();

my $argv = parse_arguments(\@ARGV);
my @test_list = folder_list($argv, $Bin);

my $Equipment = Equipment->new($db, $admin, \%conf);
my $onu_list = $Equipment->onu_list();

if ($argv->{help}) {
  help();
  exit 0;
}

foreach my $test (@test_list) {
  if ($test->{path} =~ /equipment\/onu\/:id\//xg) {
    my $id = (scalar(@{$onu_list})) ? $onu_list->[0]->{id} : '';
    $test->{path} =~ s/:id/$id/xg;
  }
}

test_runner({
  apiKey => $argv->{KEY} || q{},
  debug  => $argv->{DEBUG} || 0,
  argv   => $argv
}, \@test_list);

done_testing();

1;