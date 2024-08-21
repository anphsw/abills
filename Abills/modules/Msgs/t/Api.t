=head1 NAME

  Msgs API test

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
use Abills::Base qw(parse_arguments);
use Admins;
use Msgs;

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
my $Msgs = Msgs->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

my $user = $Users->list({
  LOGIN     => $conf{API_TEST_USER_LOGIN} || 'test',
  COLS_NAME => 1,
});

my $chapters = $Msgs->chapters_list({
  INNER_CHAPTER => 0,
  COLS_NAME     => 1,
});

my $msgs_list = $Msgs->messages_list({
  UID       => $user->[0]->{uid} || '---',
  COLS_NAME => 1,
});

my $ARGS = parse_arguments(\@ARGV);

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

foreach my $test (@test_list) {
  if ($test->{path} =~ /user\/msgs\/:id\//g) {
    my $id = (scalar(@{$msgs_list})) ? $msgs_list->[0]->{id} : '';
    $test->{path} =~ s/:id/$id/g;

    if ($test->{method} eq 'POST') {
      $test->{body}->{reply_text} = 'Reply message from test';
    }
  }
  elsif ($test->{path} =~ /user\/msgs\/:id\/reply\//g) {
    my $id = (scalar(@{$msgs_list})) ? $msgs_list->[0]->{id} : '';
    $test->{path} =~ s/:id/$id/g;
  }
  elsif ($test->{path} =~ /user\/msgs\//g && $test->{method} eq 'POST') {
    $test->{body}->{chapter} = $chapters->[0]->{id};
    $test->{body}->{message} = 'Test message from test';
    $test->{body}->{subject} = 'Test subject from test';
    $test->{body}->{priority} = 1;
  }
}
test_runner({
  apiKey => $apiKey,
  debug  => $debug
}, \@test_list);

done_testing();

1;
