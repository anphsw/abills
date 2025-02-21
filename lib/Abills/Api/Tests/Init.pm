# Can not be a package because need to define globally some packages
# package Abills::Api::Tests::Init;
=head NAME

  Api test Init functions

=cut

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';
use lib '../../../';
use lib '../../../../';

use Test::More;
use Test::JSON::More;
use Term::ANSIColor;
use JSON qw(decode_json encode_json);

use Abills::Init qw/$db %conf $admin @MODULES/;
use Abills::HTML;
use Abills::Base qw(in_array decamelize);
use Abills::Fetcher qw(web_request);
use Abills::Api::Handle;

require Control::Auth;
require Abills::Misc;
require 'language/english.pl';

our %lang;
our $html = Abills::HTML->new({ CONF => \%conf });

$ENV{REMOTE_ADDR} = '127.0.0.7';

my Abills::Api::Handle $Api;

our @EXPORT = qw(
  test_runner
  folder_list
  help
  $db
  %conf
  $admin
  @MODULES
);

our @EXPORT_OK = qw(
  test_runner
  folder_list
  help
);

my %colors = (
  OK       => 'bold green',
  BAD      => 'bold red',
  CONTRAST => 'bold BRIGHT_WHITE',
  BLUE     => 'bold BRIGHT_CYAN',
  INFO     => 'bold white'
);

my $login = $conf{API_TEST_USER_LOGIN} || 'test';
my $password = $conf{API_TEST_USER_PASSWORD} || '123456';

#**********************************************************
=head2 test_runner($attr, $tests)

  Params
    $attr
      apiKey  - admin ApiKey
      debug   - level of debug
      path    - path of test
      argv    - arguments which was passed to test
        USER: bool            - run only user tests or no 1/0
        ADMIN: bool           - run only admin tests or no 1/0
        DEBUG: int            - level of debug
        KEY?: str             - admin API KEY
        EXECUTABLE_TESTS: str - list of tests which need to run

    $tests    - array of tests

  Returns
    prints result of tests
=cut
#**********************************************************
sub test_runner {
  my ($attr, $tests) = @_;

  # define here can be redefined ref of $admin object in test file
  $Api = Abills::Api::Handle->new($db, $admin, \%conf, {
    html        => $html,
    lang        => \%lang,
    direct      => 1,
    debug       => 1,
    return_type => 'json'
  });

  if ($attr->{path}) {
    $tests = folder_list($attr->{argv}, $attr->{path});
  }

  if (ref $tests ne 'ARRAY' || !scalar @{$tests}) {
    print "Skip test runner, no tests for execute\n";
    return 0;
  }

  my $api_key = $attr->{apiKey} || $attr->{argv}->{KEY};
  $ENV{HTTP_KEY} = $api_key if ($api_key);

  my $url = $conf{API_TEST_URL} ? $conf{API_TEST_URL} : 'https://localhost:9443';

  if ($attr->{argv} && $attr->{argv}->{URL}) {
    $url = $attr->{argv}->{URL};
  }

  my $debug = $attr->{debug} || $attr->{argv}->{DEBUG} || 0;

  my ($uid, $sid) = _user_login($url, $debug);

  if ($attr->{argv} && !$attr->{argv}->{USER} && !$api_key) {
    print "Skip. No parameter KEY for running ADMIN PATHS.\n";
    return 0;
  }

  print color($colors{INFO});

  if (!$uid) {
    print "Skip. Can not run because no such test user with login: $login and password $password.\n";
    return 0;
  }

  print $attr->{message} if ($attr->{message});

  run_tests({
    %$attr,
    url    => $url,
    uid    => $uid,
    sid    => $sid,
    debug  => $debug,
    apiKey => $api_key,
    tests  => $tests,
  });

  return 1;
}

#**********************************************************
=head2 run_tests($attr)

  Params
    $attr
      apiKey?: str - admin Api Key
      debug: int   - level of debug
      tests: array - list of test
      sid: string  - session of test user
      uid: int     - if of user
      url: string  - URL of test stand where need to run tests

  Returns
    prints result of tests

=cut
#**********************************************************
sub run_tests {
  my ($attr) = @_;
  my $test_number = 0;
  my $url = $attr->{url};
  my $debug = $attr->{debug} || 0;
  my $sid = $attr->{sid};
  my $tests = $attr->{tests};
  my %variables = ();

  foreach my $test (@{$tests}) {
    $test_number++;

    if ($test->{path} =~ /:uid/m) {
      $test->{path} =~ s/:uid/$attr->{uid}/g;
    }

    my @vars = $test->{path} =~ /(?<=:)\w+/g;
    foreach my $var (@vars) {
      next if (!$variables{$var});
      $test->{path} =~ s/:$var/$variables{$var}/g;
    }

    my $http_status = 0;
    my $execution_time = 0;
    my @req_headers = ('Content-Type: application/json');
    my $req_body = '';
    my $query = '';

    if ($test->{path} =~ /user\//m) {
      push @req_headers, "USERSID: $sid";
    }
    else {
      push @req_headers, "KEY: $attr->{apiKey}";
    }

    if ($test->{body}) {
      $test->{body} = _process_request_body($test->{body}, \%variables);
    }

    if (in_array($test->{method}, ['POST', 'PUT', 'PATCH'])) {
      $req_body = $test->{body};
    }
    elsif (in_array($test->{method}, ['GET', 'DELETE']) && $test->{params} && %{$test->{params}}) {
      my %params = %{$test->{params}};

      $query .= '?';
      foreach my $key (keys %params) {
        $query .= $key . '=' . $params{$key} . '&';
      }
    }

    my ($result, $info);

    if ($debug < 5) {
      ($result, $info) = _run_test_web_request($test, $url . "/api.cgi/$test->{path}" . $query, \@req_headers, ($debug > 2) ? 1 : 0);
    }
    else {
      ($result, $info) = _run_test_directly($test, $test_number);
    }

    $http_status = $info->{status} || $info->{response_code} || $info->{http_code} || 0;
    $execution_time = $info->{time} || $info->{time_total} || 0;

    if ($http_status == 200) {
      print color($colors{OK});
    }
    else {
      print color($colors{BAD});
    }

    print "[$test_number]-$test->{name} ($test->{method})    HTTP STATUS CODE: $http_status    RESPONSE TIME: $execution_time ms. \n";

    if ($debug) {
      print color($colors{INFO}), "\n\n";
      my $req_body_preview = encode_json($test->{body}) || '';
      print "REQUEST PARAMS: \n  METHOD: $test->{method}\n  PATH: $test->{path}\n  BODY:\n  $req_body_preview\n\n";
    }

    print color($colors{INFO}), "Checking is json valid: ", color($colors{CONTRAST});

    if (ok_json($result)) {
      my $res = decode_json($result);

      # save locally needed vars
      if ($test->{'post-response'} && $test->{'post-response'}->{variables}) {
        foreach my $variable (@{$test->{'post-response'}->{variables}}) {
          $variables{$variable->{name}} = $res->{$variable->{value}};
        }
      }

      print color($colors{INFO}), "Check is without error: ", color($colors{CONTRAST});
      if (ok(!(ref $res eq 'HASH' && ($res->{error} || $res->{errno})))) {
        print color($colors{INFO}), "Does JSON belong to schema: ", color($colors{CONTRAST});
        if (!ok_json_schema($result, $test->{schema})) {
          print($result);
          print color($colors{BAD}), "\nJSON SCHEMA IS INCORRECT \n";
        }
      }
      else {
        print color($colors{BAD}), "Error: \n";
        print "RESPONSE $result \n";
        print "ERROR NUMBER: " .
          ($res->{error} || $res->{errno} || q{UNKNOWN}) . "\nERROR STRING: " .
          ($res->{errstr} || q{UNKNOW}) . "\n", color($colors{INFO});
      }
    }
    else {
      print "JSON: $result \n";
    }
    print color($colors{INFO}), "------------------------------------\n";
  }
}

#**********************************************************
=head2 _run_test_directly($test, $url, $headers, $debug)

  Params
    body        - test object
    variables   - url to which need request

  Returns
    $body

=cut
#**********************************************************
sub _process_request_body {
  my ($body, $variables) = @_;

  foreach my $key (keys %{$body}) {
    next if (!$body->{$key});
    if (ref $body->{$key} eq 'HASH') {
      _process_request_body($body->{$key}, $variables);
    }
    elsif (ref $body->{$key} eq 'ARRAY') {
      foreach my $val (@{$body->{$key}}) {
        _process_request_body($val, $variables);
      }
    }
    else {
      my ($var) = $body->{$key} =~ /\{\{(\w+)\}\}/g;
      next if (!$var || !$variables->{$var});
      $body->{$key} = $variables->{$var};
    }
  }

  return $body;
}

#**********************************************************
=head2 _run_test_directly($test, $url, $headers, $debug)

  Params
    $attr
      test    - test object
      url     - url to which need request
      headers - request headers
      debug   - debug level of request

  Returns
    $result
    $info

=cut
#**********************************************************
sub _run_test_web_request {
  my ($test, $url, $headers, $debug) = @_;

  my ($result, $info) = web_request($url, {
    HEADERS     => $headers,
    JSON_BODY   => $test->{body},
    INSECURE    => 1,
    DEBUG       => $debug ? 6 : 0,
    METHOD      => $test->{method},
    MORE_INFO   => 1,
    JSON_RETURN => $test->{json_return} ? 1 : 0
  });

  return $result, $info;
}

#**********************************************************
=head2 _run_test_directly($test, $test_number)

  Params
    $attr
      test          - test object
      test_number   - number of test which is running

  Returns
    $result
    $info
=cut
#**********************************************************
sub _run_test_directly {
  my ($test, $test_number) = @_;

  print color($colors{BLUE}), "[$test_number]\nSQL\n" if ($test_number);

  my ($result, $status) = $Api->api_call({
    PATH   => "/$test->{path}",
    METHOD => $test->{method},
    PARAMS => $test->{body} || {},
  });

  print color($colors{INFO}), '' if ($test_number);

  return $result, {
    status => $status,
  };
}

#**********************************************************
=head2 _user_login($url)

  Params
    $url - billing url

  Returns
    uid - uid of test user for tests
    sid - sid of test user for tests
=cut
#**********************************************************
sub _user_login {
  my ($url, $debug) = @_;

  my $result;
  my $test = {
    path        => 'user/login/',
    method      => 'POST',
    body        => {
      login    => $login,
      password => $password
    },
    json_return => 1,
  };

  if ($debug < 5) {
    ($result) = _run_test_web_request($test, $url . "/api.cgi/$test->{path}", [ 'Content-Type: application/json' ], ($debug > 2) ? 1 : 0);
  }
  else {
    ($result) = _run_test_directly($test);
  }

  if (!$result || ref $result ne 'HASH') {
    print "FATAL ERROR. Received invalid response test process ending\n";
    print "\n----------------------\n". ( $result || q{}) ."\n";
    exit;
    #return 0, '';
  }

  if ($result->{error} || $result->{errno}) {
    my $error = $result->{error} || $result->{errno};
    $result->{errstr} //= '';
    print "FATAL ERROR. DURING AUTH OF TEST USER\n ERROR CODE - [$error]\tERROR MESSAGE $result->{errstr}\n";
    exit;
  }

  return ($result->{uid}, $result->{sid});
}

#**********************************************************
=head2 folder_list($test, $main_dir)

  Params
    $attr     - ARGV in test
      USER: bool            - run only user tests or no 1/0
      ADMIN: bool           - run only admin tests or no 1/0
      DEBUG: int            - level of debug
      KEY?: str             - admin API KEY
      EXECUTABLE_TESTS: str - list of tests which need to run

    $main_dir - place where is folder

  Returns
    @test_list - list of tests
=cut
#**********************************************************
sub folder_list {
  my ($attr, $main_dir) = @_;
  my @folders = ();
  my @test_list = ();

  if ($attr->{ADMIN}) {
    push @folders, _read_dir('admin', $main_dir, ($attr->{PATH} || q{}));
  }
  elsif ($attr->{USER}) {
    push @folders, _read_dir('user', $main_dir, ($attr->{PATH} || q{}));
  }
  else {
    push @folders, _read_dir('admin', $main_dir, ($attr->{PATH} || q{}));
    push @folders, _read_dir('user', $main_dir, ($attr->{PATH} || q{}));
  }

  if (!@folders) {
    print color($colors{BAD}), "NO TESTS - $main_dir\n";
    return [];
  }

  @folders = sort {
    my ($a_type, $a_id) = $a =~ m{/schemas/(admin|user)/(\d+)_};
    my ($b_type, $b_id) = $b =~ m{/schemas/(admin|user)/(\d+)_};

    # can be undefined values need to set default value for correct compare
    ($a_type // '') cmp ($b_type // '') || ($a_id // 0) <=> ($b_id // 0);
  } @folders;

  my @executable_tests = ();
  if ($attr->{EXECUTABLE_TESTS}) {
    @executable_tests = split(',\s?', $attr->{EXECUTABLE_TESTS});
  }

  foreach my $folder (@folders) {
    my $request_file = "$folder/request.json";
    my $schema_file = "$folder/schema.json";

    next if (!-f $schema_file || !-f $request_file);

    open(my $request_str, $request_file);
    open(my $schema_str, $schema_file);

    my $request_plain = do {
      local $/;
      <$request_str>
    };
    my $schema = do {
      local $/;
      <$schema_str>
    };

    my $request = decode_json($request_plain);
    my %request_hash = %$request;

    $request_hash{schema} = $schema;
    next if (scalar @executable_tests && !in_array(lc($request_hash{method}) . "/$request_hash{path}", \@executable_tests));

    push(@test_list, \%request_hash);
  }

  return wantarray ? @test_list : \@test_list;
}

#**********************************************************
=head2 _read_dir($dir, $main_dir)

  Params
    $dir      - dir name admin or user
    $main_dir - place where is folder

  Returns
    @folders - name list of folders of tests
=cut
#**********************************************************
sub _read_dir {
  my ($dir, $main_dir, $path) = @_;

  my @folders = ();
  my @folder_list = ();
  my $tests_path = "$main_dir/schemas/$dir";

  return \@folders if (! -d $tests_path);

  if (opendir(my $dh, $tests_path) ) {
    @folder_list = readdir($dh);
    closedir($dh);
  }

  foreach my $folder (@folder_list) {
    next if ($folder =~ /\./);
    next if ($path && $folder ne $path);
    push @folders, "$tests_path/$folder";
  }

  return @folders;
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
  ABillS API test system
  Runs tests user login \$conf{API_TEST_USER_LOGIN} and password: \$conf{API_TEST_USER_PASSWORD or with login/pass test/123456 if its valid
  Curl requests send to url defined in param \$conf{API_TEST_URL} or default https://localhost:9443 if its valid

  Default runs all available tests in selected module
  ADMIN=1 - run only admin tests
  USER=1  - run only user tests

  DEBUG=[0..5]
    debug > 1 - show request body and url to server
    debug > 2 - show request and response from server (Output is with standard of DEBUG Abills::Fetcher module)
    debug > 4 - run all tests directly with mysql printing requests

  Admin key not defined by default
  KEY={YOUR_KEY}                  - test admin API key,

  EXECUTABLE_TESTS="{method}/{path}" - run only few tests of module.
    EXECUTABLE_TESTS="get/version/,get/user/payments/"

  help
[END]
}

1;
