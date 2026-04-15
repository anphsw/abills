#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Test::More;
use Carp qw(croak);

use lib '../../../../lib/';
use lib '../../../../lib/';
use lib '../../../../cgi-bin/';

our (
  %lang,
  $db,
  $admin,
  %conf,
  $DATE,
  $TIME,
  $Paysys_Core,
  $html
);

BEGIN {
  diag("Loading modules for paysys_check gateway tests");

  use_ok('Abills::Init', qw($db $admin %conf $DATE $TIME));

  do '../../../../language/english.pl';
  do '../lng_english.pl';
}

# do not make direct print during loading
capture_output(sub {
  do '../../../../cgi-bin/paysys_check.cgi';
});


subtest 'Browser request, response HTML ' => sub {
  plan tests => 3;

  my $output = call_paysys_payment_gateway(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'text/html'
  );
  ok($output, 'Browser request (Chrome) should return output');
  ok($output !~ /Status:\s*401/ix, 'Browser request should not return 401 status');
  ok($output =~ /Content-Type/ix || $output =~ /<html/ix || $output =~ /<!DOCTYPE/ix, 'Browser request should return HTML content');
};

subtest 'Curl agent, accept json' => sub {
  plan tests => 5;

  my $output = call_paysys_payment_gateway(
    'curl/7.68.0',
    'application/json'
  );
  ok($output, 'Non-browser request should return output');
  my $result = parse_output($output);
  ok(check_status_code($result, 401), 'Non-browser request should return 401 status');
  ok(check_content_type($result, 'application/json'), 'Non-browser request with JSON Accept should return JSON');
  ok(response_contains($result, 'Unauthorized request'), 'Response should contain error message');
  ok(response_contains($result, 'HTML response is disabled'), 'Response should contain explanation message');
};

subtest 'Python agent, accept xml' => sub {
  plan tests => 5;

  my $output = call_paysys_payment_gateway(
    'Python-requests/2.25.1',
    'application/xml'
  );
  ok($output, 'Non-browser request with XML Accept should return output');
  my $result = parse_output($output);

  ok(check_status_code($result, 401), 'Non-browser request should return 401 status');
  ok(check_content_type($result, 'application/xml'), 'Non-browser request with XML Accept should return XML');
  ok(response_contains($result, 'Unauthorized request'), 'XML response should contain error message');
  ok(response_contains($result, '<response>'), 'XML response should contain XML structure');
};

subtest 'Empty User-Agent' => sub {
  plan tests => 4;

  my $output = call_paysys_payment_gateway(
    '',
    'application/json'
  );
  ok($output, 'Empty User-Agent request should return output');
  my $result = parse_output($output);
  ok(check_status_code($result, 401), 'Empty User-Agent should return 401 status');
  ok(check_content_type($result, 'application/json'), 'Empty User-Agent should return JSON');
  ok(response_contains($result, 'HTML response is disabled'), 'Response should contain explanation message');
};

done_testing();

#### TEST HELP FUNCTIONS

#**********************************************************
=head2 capture_output()


=cut
#**********************************************************
sub capture_output {
  my ($code_ref) = @_;

  my $output = '';
  my $old_fh = select;

  open(my $fh, '>', \$output) or croak "Cannot open scalar for writing: $!";
  select $fh;

  eval { &$code_ref; };
  my $error = $@;

  select $old_fh;
  close $fh;

  croak $error if ($error);

  return $output;
}

#**********************************************************
=head2 call_paysys_payment_gateway()


=cut
#**********************************************************
sub call_paysys_payment_gateway {
  my ($user_agent, $accept) = @_;

  $ENV{HTTP_USER_AGENT} = $user_agent if defined $user_agent;
  $ENV{HTTP_ACCEPT} = $accept if defined $accept;

  return capture_output(sub { paysys_payment_gateway(); });
}

#**********************************************************
=head2 parse_output()


=cut
#**********************************************************
sub parse_output {
  my ($output) = @_;

  my %result = (
    headers => {},
    status  => 0,
    body    => '',
  );

  if ($output =~ /^(.*?)\n\n(.*)$/xs) {
    my $headers_str = $1;
    $result{body} = $2;

    foreach my $line (split(/\n/x, $headers_str)) {
      if ($line =~ /^Status:\s*(\d+)/ix) {
        $result{status} = $1;
      }
      elsif ($line =~ /^([^:]+):\s*(.+)$/x) {
        my $key = lc($1);
        my $value = $2;
        $result{headers}{$key} = $value;
      }
    }
  }
  else {
    $result{body} = $output;
  }

  return \%result;
}

#**********************************************************
=head2 check_content_type()


=cut
#**********************************************************
sub check_content_type {
  my ($result, $expected_type) = @_;
  return 0 if (!$result && !$result->{headers});
  my $content_type = $result->{headers}->{'content-type'} || '';
  return $content_type =~ /$expected_type/xi;
}

#**********************************************************
=head2 check_status_code()


=cut
#**********************************************************
sub check_status_code {
  my ($result, $expected_status) = @_;

  return 0 if (!$result);

  return $result->{status} == $expected_status;
}

#**********************************************************
=head2 response_contains()


=cut
#**********************************************************
sub response_contains {
  my ($result, $text) = @_;
  return 0 if (!$result && !$result->{body});

  # please do not make as strict
  return $result->{body} =~ /$text/i;
}
