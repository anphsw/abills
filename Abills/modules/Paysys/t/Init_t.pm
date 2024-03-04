=head1 NAME

  PAYSYS test Init functions

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our (
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  %lang,
  @_COLORS,
  $admin,
);

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}

our $VERSION = 0.02;

our (%EXPORT_TAGS);
our @EXPORT = qw(
  test_runner
);
our @EXPORT_OK = qw(
  test_runner
);

do "libexec/config.pl";

use Abills::Base;
use Abills::Init qw/$db $admin $users %conf/;

$conf{language} = 'english';
do "language/$conf{language}.pl";
do "../lng_english.pl";

require Paysys::Paysys_Base;

our $argv = parse_arguments(\@ARGV);

if (defined($argv->{help})) {
  help();
  exit;
}

our $debug = $argv->{debug} || 0;
our $user_id = $argv->{user_id} || $argv->{user} || $conf{PAYSYS_TEST_USER} || 1;
our $payment_sum = $argv->{payment_sum} || $conf{PAYSYS_TEST_SUM} || 1;
our $payment_id = $argv->{payment_id} || mk_unique_value(6, { SYMBOLS => '0123456789' });

our $html;
if (!defined($ENV{'REQUEST_METHOD'})) {
  $html = Abills::HTML->new({ CONF => \%conf });
}

our @methods = ();
if ($argv->{methods}) {
  @methods = split(/,\s?/, $argv->{methods});
}

#*******************************************************************
=head2 test_runner($Payment_plugin, \@requests) - test maker

  Arguments:
    $Payment_plugin,
    \@requests {
                 name  => q{},
                 request => q{}
                 result =>  q{}
                 get => 1 # Optional for GET REQUESTS
                 }

    $attr
      VALIDATE => [
         xml_validate
         xml_compare
         json_compare
         result_compare (default)
        ]
  Return:
    Results

  Example:
    test_runner($Payment_plugin, \@request, { VALIDATE => 'xml_compare' });

=cut
#*******************************************************************
sub test_runner {
  my ($Payment_plugin, $requests, $attr) = @_;

  if ($0 !~ /.+\.t$/) {
    return 0;
  }

  $Payment_plugin->{TEST}=1;

  foreach my $request_block (@$requests) {
    if ($#methods > -1 && !in_array($request_block->{name}, \@methods)) {
      next;
    }

    $ENV{PATH_INFO} = $request_block->{path} if ($request_block->{path});

    print "REQUEST: $request_block->{name} ======================\n";
    print(($request_block->{request} || q{}) . "\n");
    $FORM{__BUFFER} = $request_block->{request} || q{};

    if ($request_block->{get}) {
      $request_block->{request} =~ s/\n/\&/g;
      $request_block->{request} =~ s/\&\&/\&/g;
      my @rows = split(/&/, $request_block->{request});
      foreach my $pairs (sort @rows) {
        my ($key, undef, $value)=split(/(=|\s+=>\s?)(?!\s|$)/, $pairs);
        next if (! $key);
        $key =~ s/^\s+|\s+$//g;
        $FORM{$key}=$value;
      }
    }

    if ($request_block->{headers}) {
      foreach my $header (@{$request_block->{headers}}) {
        my ($name, $value) = split(':', $header);
        $name =~ s/\-/_/g;
        $value =~ s/^\s+//;

        $ENV{'HTTP_' . uc($name)} = $value;
      }
    }

    $Payment_plugin->proccess(\%FORM);

    print "\nRESPONSE GET:=====================\n";
    print ($Payment_plugin->{RESULT} || q{});
    if ($debug > 1) {
      print "\nRESPONSE REQUIRED:======================\n";
      print $request_block->{result} . "\n";
    }

    if ($attr->{VALIDATE}) {
      my $validate_function = $attr->{VALIDATE};
      if (defined(&$validate_function)) {
        my $validatin = &{ \&$validate_function }($Payment_plugin->{RESULT}, $request_block->{result});

        print "\n======================\n";
        print "\nVALIDATION: $validatin";
      }
      else {
        print "\nERROR: '$validate_function' validate function not exists\n";
      }
    }

    print "\n======================\n\n\n";
  }

  return 1;
}

#*******************************************************************
=head2 xml_compare($result, $compare) - Compare function

  Arguments:
    $result   - Request result
    $compare  - Compare result

  Return:
    TRUE or FALSE

=cut
#*******************************************************************
sub xml_compare {
  my($result, $compare)=@_;

  return 1;
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
  ABillS Paysys test system
  user_id=
  payment_sum=
  payment_id=
  methods="GET_USER,PAY" = payments function
    GET_USER
    PAY
    CANCEL
    CONFIRM
  debug=[0..8]
  help
[END]

  return 1;
}

1;
