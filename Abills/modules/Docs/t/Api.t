=head1 NAME

  Docs API test

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
use Users;
use Docs;

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
my $Users = Users->new($db, $admin, \%conf);
my $Docs = Docs->new($db, $admin, \%conf);

my $user = $Users->list({
  LOGIN      => $conf{API_TEST_USER_LOGIN} || 'test',
  COLS_NAME  => 1,
  COLS_UPPER => 1
})->[0];

my $invoices = $Docs->invoices_list({
  ID        => '_SHOW',
  UID       => $user->{UID},
  COLS_NAME => 1,
});

my $payments = $Docs->invoices2payments_list({
  INVOICE_ID => '',
  UID        => '_SHOW',
  PAYMENT_ID => '_SHOW',
  COLS_NAME  => 1
});

my $ARGS = parse_arguments(\@ARGV);
my $apiKey = $ARGS->{KEY} || $ARGV[$#ARGV] || q{};
my @test_list = folder_list($ARGS, $RealBin);
my $debug = $ARGS->{DEBUG} || 0;

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
  help();
  exit 0;
}

my $invoice_id = 0;
my $no_payment_invoice = 0;
if (scalar(@{$invoices})) {
  foreach my $invoice (@$invoices) {
    if (!$invoice_id) {
      $invoice_id = $invoice->{id};
      next;
    }

    if (!$invoice->{payment_sum}) {
      $no_payment_invoice = $invoice->{id};
      last;
    }
  }
}

my $payment_info = (scalar(@{$payments})) ? $payments->[0] : '';
foreach my $test (@test_list) {
  if ($test->{path} =~ /user\/docs\/invoices\/:id\//g) {
    $test->{path} =~ s/:id/$invoice_id/g;
  }
  elsif ($test->{path} =~ /docs\/invoices\/payments/g) {
    if ($test->{method} eq 'POST') {
      $test->{body} = {
        ids           => $no_payment_invoice,
        paymentMethod => 1,
      };
    }
    elsif ($test->{method} eq 'PATCH') {
      $test->{body} = {
        paymentId     => $payment_info->{payment_id},
        sum           => 1,
        invoiceCreate => 1,
      };
    }
  }
  elsif ($test->{path} =~ /docs\/invoices/g && $test->{method} eq 'DELETE') {
    $test->{params} = { id => $invoice_id };
  }
}

test_runner({
  apiKey => $apiKey,
  debug  => $debug,
  args   => $ARGS
}, \@test_list);

done_testing();

1;
