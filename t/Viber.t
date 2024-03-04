#!/usr/bin/perl

=head1 NAME

  Viber integration test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use JSON;

require $Bin . '/../libexec/config.pl';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use Abills::Defs;
use Abills::Base qw(parse_arguments);
use Admins;
use Users;
use Conf;
use Abills::Fetcher;
use JSON;
use File::Find;

our (
  %conf
);

my $ARGS = parse_arguments(\@ARGV);

if ($ARGS->{help}) {
  help();
  exit 0;
}

my $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);

# Just init Tokens from Config
my $Conf = Conf->new($db, undef, \%conf);

if (!$conf{VIBER_TOKEN}) {
  plan skip_all => 'Undefined $conf{VIBER_TOKEN}';
}
if (!$conf{VIBER_BOT_NAME}) {
  plan skip_all => 'Undefined $conf{VIBER_BOT_NAME}';
}

if (!$ARGS->{WEBHOOK_URL}) {
  plan skip_all => 'Undefined WEBHOOK_URL'
}

my $api_base = 'https://chatapi.viber.com/pa/';
my @header = ('Content-Type: application/json', 'X-Viber-Auth-Token: ' . $conf{VIBER_TOKEN});

CHECK_IF_BOT_EXIST: {
  my $get_me_url = "$api_base/get_account_info";

  my $get_account_info_response = web_request($get_me_url, { CURL => 1, HEADERS => \@header, JSON_RETURN => 1 });
  if (!$get_account_info_response->{name}) {
    plan skip_all => 'FAILED: Bot is not exist, recheck your token';
  }
  ok(1, 'Bot exist in Viber');


  if ($@) {
    plan skip_all => 'FAILED: Error with response or SSL-ca'
  }
}

my @ENABLED_MODULES = ();
my @AVAILABLE_MODULES = ();

SHOW_MODULES: {
  my $enabled_modules_dir = $libpath . 'Abills/modules/Viber/buttons-enabled';
  my $available_modules_dir = $libpath . 'Abills/modules/Viber/buttons-avaiable';

  find(\&process_modules, $enabled_modules_dir);
  find(\&process_available_modules, $available_modules_dir);
  ok(scalar(@ENABLED_MODULES), 'Check enabled Viber modules');
  ok(scalar(@AVAILABLE_MODULES), 'Check avaiable Viber modules');

  for my $available_module (sort @AVAILABLE_MODULES) {
    if (grep { $_ eq $available_module } @ENABLED_MODULES) {
      print " ✅ $available_module\n";
    } else {
      print " ❌ $available_module\n"
    }
  }
}

CHECK_ENDPOINT: {
  my $response = web_request($ARGS->{WEBHOOK_URL}, { MORE_INFO => 1, CURL => 1 });

  ok($response->{http_code} && $response->{http_code} == 200, 'WEBHOOK_URL check');
}
done_testing();

sub process_modules {
  my $name = $File::Find::name;
  if (-d $name) {
    return 1;
  }

  if ($_) {
    push(@ENABLED_MODULES, $_);
  }
}

sub process_available_modules {
  my $name = $File::Find::name;
  if (-d $name) {
    return 1;
  }
  if ($_ && $_ ne '.') {
    push(@AVAILABLE_MODULES, $_);
  }
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
  Viber integration test

  Params:
    WEBHOOK_URL=https://HOST:PORT/VIBER_PATH/viber_bot.cgi  - required
    VIBER_TOKEN=5ccea26459e7df08-a55b3aaa0a371b15-...       - optional

[END]
}
1;
