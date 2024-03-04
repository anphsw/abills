#!/usr/bin/perl

=head1 NAME

  Telegram integration test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
use Test::JSON::More;
use FindBin '$Bin';
use FindBin qw($RealBin);
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

if (($ARGV[0] && lc($ARGV[0]) eq 'help') || defined($ARGS->{help}) || defined($ARGS->{HELP})) {
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

my $token = $conf{TELEGRAM_TOKEN} || $ARGS->{TELEGRAM_TOKEN};

if (!$token) {
  plan skip_all => 'Undefined $conf{TELEGRAM_TOKEN}';
}
if (!$conf{TELEGRAM_BOT_NAME}) {
  plan skip_all => 'Undefined $conf{TELEGRAM_BOT_NAME}';
}

if (!$ARGS->{WEBHOOK_URL}) {
  plan skip_all => 'Undefined WEBHOOK_URL'
}

my $api_base = 'https://api.telegram.org';
my $bot_api_base = "$api_base/bot$token";

CHECK_IF_BOT_EXIST: {
  my $get_me_url = "$bot_api_base/getMe";
  eval {
    my $response = web_request($get_me_url, { CURL => 1 });
    my $decoded = decode_json($response);
    if (!$decoded->{ok}) {
      plan skip_all => 'FAILED: Bot is not exist, recheck your token';
    }
    ok(1, 'Bot exist in Telegram')
  };

  if ($@) {
    plan skip_all => 'FAILED: Error with response or SSL-ca'
  }
}

my @ENABLED_MODULES = ();
my @AVAILABLE_MODULES = ();

SHOW_MODULES: {
  my $enabled_modules_dir = $libpath . 'Abills/modules/Telegram/buttons-enabled';
  my $available_modules_dir = $libpath . 'Abills/modules/Telegram/buttons-avaiable';

  find(\&process_modules, $enabled_modules_dir);
  find(\&process_available_modules, $available_modules_dir);
  ok(scalar(@ENABLED_MODULES), 'Check enabled Telegram modules');
  ok(scalar(@AVAILABLE_MODULES), 'Check avaiable Telegram modules');

  for my $available_module (sort @AVAILABLE_MODULES) {
    if (grep { $_ eq $available_module } @ENABLED_MODULES) {
      print "✅ $available_module\n";
    } else {
      print "❌ $available_module\n"
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
  Telegram integration test
  Run tests with Telegram token
  Curl requests send to api.telegram.org and try to check if your webhook it setup successfully

  Params:
    WEBHOOK_URL=https://HOST:PORT/TELEGRAM_PATH/telegram_bot.cgi  - required
    TELEGRAM_TOKEN=1234567:AFDSFIJDAJFLKDSJFLKDAS                 - optional

[END]
}
1;
