=head1 NAME

  Paysys API test

=cut

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use FindBin qw($RealBin);
use JSON;

BEGIN {
  our $libpath = $Bin . '/../../../../';
  require "$libpath/libexec/config.pl";
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Defs;
use Abills::Api::Tests::Init qw(test_runner folder_list help);
use Abills::Base qw(parse_arguments mk_unique_value);
use Admins;
use Cards;

our (
  %conf
);

my $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
my $admin = Admins->new($db, \%conf);
my $Cards = Cards->new($db, $admin, \%conf);

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $serial = mk_unique_value(10, { SYMBOLS => '1234567890' });

# create cards, yeah a little bit cringe
$Cards->cards_add({
  'PASSWD_SYMBOLS' => '0123456789',
  'PASSWD_LENGTH' => '8',
  'MULTI_ADD' => [
    [
      $serial,
      0,
      '',
      0,
      0,
      '0000-00-00',
      1,
      0,
      0,
      '2.00',
      0,
      0,
      '0.00',
      0
    ],
    [
      $serial,
      1,
      '',
      0,
      0,
      '0000-00-00',
      1,
      0,
      0,
      '2.00',
      0,
      0,
      '0.00',
      0
    ]
  ]
});

# get cards info with new pins
my $cards = $Cards->cards_list({
  SERIAL    => $serial,
  PIN       => '_SHOW',
  NUMBER    => '_SHOW',
  COLS_NAME => 1
});

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;
my @tests = ();

foreach my $test (@test_list) {
  if ($test->{path} =~ /user\/cards\/payment\//g) {
    $test->{body}->{pin} = "$cards->[0]->{pin}";
    $test->{body}->{serial} = "$cards->[0]->{serial}$cards->[0]->{number}";
  }
  elsif ($test->{path} =~ /cards\/:uid\/payments\//g ) {
    $test->{body}->{pin} = "$cards->[1]->{pin}";
    $test->{body}->{serial} = "$cards->[1]->{serial}$cards->[1]->{number}";
  }
  push @tests, $test;
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  argv   => $ARGS
}, \@tests);

# clear no more needed cards
$Cards->cards_del({
  SERIA => $serial,
});

done_testing();

1;
