=head1 NAME

  PAYSYS test Init functions

=cut

use strict;
use warnings FATAL => 'all';

use FindBin '$Bin';

use parent 'Exporter';
use Test::More;

our (
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

our $VERSION = 0.03;

# useless for not package functions
our (%EXPORT_TAGS);
our @EXPORT = qw(
  test_runner
);
our @EXPORT_OK = qw(
  test_runner
);

do "libexec/config.pl";

our $base_dir = '/usr/abills/';

if ($Bin =~ m/\/abills(\/)/) {
  $base_dir = substr($Bin, 0, $-[1]);
  $base_dir .= '/';
}

use Abills::Base qw/parse_arguments mk_unique_value/;
use Abills::Init qw/$db $admin $users %conf/;
use Abills::Validator qw(xml_compare json_compare);

$conf{language} = 'english';
do "language/$conf{language}.pl";
do "../lng_english.pl";

require Abills::Misc;

our $argv = parse_arguments(\@ARGV);

if (defined($argv->{help})) {
  help();
  exit;
}

our $debug = $argv->{debug} || $argv->{DEBUG} || 0;
our $user_id = $argv->{user_id} || $argv->{user} || $conf{PAYSYS_TEST_USER} || 1;
our $payment_sum = $argv->{payment_sum} || $conf{PAYSYS_TEST_SUM} || 1;
our $payment_id = $argv->{payment_id} || mk_unique_value(4, { SYMBOLS => '123456789' });

our $program_name = $0;
if ($program_name =~ /\/?([a-zA-Z0-9\.\_\-]+)$/xm) {
  $program_name = $1;
}

our @methods = ();
if ($argv->{methods}) {
  @methods = split(/,\s?/x, $argv->{methods});
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

  if ($program_name !~ /.+\.t$/xm) {
    return 0;
  }

  $Payment_plugin->{TEST}=1;

  foreach my $request_block (@$requests) {
    if ($#methods > -1 && !in_array($request_block->{name}, \@methods)) {
      next;
    }

    $ENV{PATH_INFO} = $request_block->{path} if ($request_block->{path});

    my %request = (
      __BUFFER => $request_block->{request} || q{},
    );

    #TODO: remove in future after migration to query_params
    if ($request_block->{get}) {
      $request_block->{request} =~ s/\n/\&/xg;
      $request_block->{request} =~ s/\&\&/\&/xg;
      my @rows = split(/&/x, $request_block->{request});
      foreach my $pairs (sort @rows) {
        my ($key, undef, $value)=split(/(=|\s+=>\s?)(?!\s|$)/xm, $pairs);
        next if (! $key);
        $key =~ s/^\s+|\s+$//xg;
        $request{$key}=$value;
      }
    }
    elsif ($request_block->{query_params}) {
      $request{__BUFFER} = '';
      foreach my $key (keys %{$request_block->{request}}) {
        $request{$key} = $request_block->{request}{$key}{val};
        $request{__BUFFER} .= "$key=$request_block->{request}{$key}{val}\n"
      }
    }

    if ($debug > 1) {
      print "REQUEST: $request_block->{name} ======================\n";
    }

    if ($debug > 2) {
      print(($request{__BUFFER} || q{}) . "\n");
    }

    if ($request_block->{headers}) {
      foreach my $header (@{$request_block->{headers}}) {
        my ($name, $value) = split(':', $header);
        $name =~ s/\-/_/xg;
        $value =~ s/^\s+//x;

        $ENV{'HTTP_' . uc($name)} = $value;
      }
    }

    $Payment_plugin->proccess(\%request);

    if ($debug > 1) {
      print "RESPONSE GET:=====================\n";
    }

    if ($debug > 2) {
      print($Payment_plugin->{RESULT} || q{});
    }

    if ($debug > 3) {
      print "RESPONSE REQUIRED:======================\n";
      print $request_block->{result} . "\n";
    }

    if ($attr->{VALIDATE}) {
      my $validate_function = $attr->{VALIDATE};
      if (defined(&$validate_function)) {
        my $schema = '';
        if ($request_block->{result_schema}) {
          $schema = "$base_dir/Abills/modules/Paysys/t/$request_block->{result_schema}";
        }

        my $validation = &{ \&$validate_function }({
          RESULT => $Payment_plugin->{RESULT},
          SCHEMA => $schema,
          DEBUG  => $debug
        });

        if ($debug)  {
          print "======================\n";
          print "VALIDATION: $validation\n";
        }

        ok($validation == 1, "$request_block->{name}");
      }
      else {
        print "\nERROR: '$validate_function' validate function not exists\n";
      }
    }

    if ($debug > 2) {
      print "======================\n\n\n";
    }
  }

  done_testing( $#{ $requests } + 1 );

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
