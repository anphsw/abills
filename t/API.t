=head1 NAME

  API test

=cut

use strict;
use warnings;

use lib '.';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw( $RealBin );
use HTTP::Request::Common;
use Term::ANSIColor;
use LWP::Simple;
use JSON qw(decode_json encode_json );

require $Bin ."/../libexec/config.pl";

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  eval {require Time::HiRes;};
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::Defs;
use Abills::Base;
use Abills::Fetcher;

our (
  $Bin,
  %FORM,
  %LIST_PARAMS,
  %functions,
  %conf,
  $html
);

my @test_list = ();

my %colors = (
  OK       => 'bold green',
  BAD      => 'bold red',
  CONTRAST => 'bold BRIGHT_WHITE',
  INFO     => 'bold white'
);

opendir (DIR, './Schemas');
my @folder = readdir(DIR);

foreach my $folder (@folder)
{
  next if ($folder =~ /\./);

  my $request_file = "$RealBin/Schemas/$folder/$folder\_request.json";
  my $schema_file = "$RealBin/Schemas/$folder/$folder\_schema.json";

  open (my $request_str, $request_file);
  open (my $schema_str, $schema_file);

  my $request_plain = do { local $/; <$request_str> };
  my $schema = do { local $/; <$schema_str> };

  my $request = decode_json($request_plain);
  my %request_hash = %$request;

  $request_hash{schema} = $schema;

  push(@test_list, \%request_hash);
}

my $test_number = 0;
my $apiKey = $ARGV[$#ARGV];
my $protocol = ("--use-http" ~~ @ARGV) ? "http" : "https";

foreach my $test (@test_list) {
  $test_number++;

  my $url = "$protocol://localhost:9443/api.cgi/$test->{path}";

  my $start_time = gettimeofday();

  my $response;

  my $http_status = 0;
  my $execution_time = 0;

  my $Ua = LWP::UserAgent->new(
    ssl_opts => {
      verify_hostname => 0,
      SSL_verify_mode => 0
    },
  );

  $Ua->protocols_allowed( [ 'http', 'https'] );
  $Ua->default_header( KEY => $apiKey );

  if($test->{method} eq 'POST'){
    my $post_request = HTTP::Request->new( 'POST', $url);

    $post_request->header('Content-Type' => 'application/json');
    $post_request->content(encode_json $test->{body});

    $response = $Ua->request($post_request);

  } elsif($test->{method} eq 'GET') {
    my %params = %{ $test->{params} };

    my $query = '';

    foreach my $key (keys %params) {
      $query .= $key.'='.$params{$key}.'&';
    }

    $response = $Ua->request(GET "$url\?$query");
  }

  $http_status = $response->code();
  $execution_time = sprintf("%d", (gettimeofday() - $start_time) * 1000);

  my $json = $response->content;

  if($http_status == 200) {
    print color($colors{OK});
  } else {
    print color($colors{BAD});
  }

  print "[$test_number]-$test->{name} ($test->{method})    HTTP STATUS CODE: $http_status    RESPONSE TIME: $execution_time ms. \n";

  print color($colors{INFO}), "Checking is json valid: ", color($colors{CONTRAST});

  if(ok_json($json)) {
    print color($colors{INFO}), "Does JSON belong to schema: ", color($colors{CONTRAST});

    if (!ok_json_schema($json, $test->{schema})) {
      print($json);
      print color($colors{BAD}), "JSON SCHEMA IS INCORRECT \n";
    }

  } else {
    print "JSON: $json \n" ;
  }

  print "------------------------------------\n";
}

print "\n", color($colors{OK}), "REPORT: \n", color($colors{CONTRAST});
done_testing();

1;