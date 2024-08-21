#!/usr/bin/perl

=head1 NAME

  Telegram integration test

=cut

use strict;
use warnings;

use lib '../';
use Test::More;
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
use Abills::Base qw(parse_arguments show_hash);
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
my $debug = $ARGS->{DEBUG} || 0;
$conf{base_dir} //= '/usr/abills/';
my $telegram_script = q{};
my $webhook = $ARGS->{WEBHOOK_URL};

if (!$token) {
  plan skip_all => 'Undefined $conf{TELEGRAM_TOKEN}';
}
if (!$conf{TELEGRAM_BOT_NAME}) {
  plan skip_all => 'Undefined $conf{TELEGRAM_BOT_NAME}';
}

ok(is_installed(), 'Is telegram installed');


my $api_base = 'https://api.telegram.org';
my $bot_api_base = "$api_base/bot$token";

CHECK_IF_BOT_EXIST: {
  my $get_me_url = "$bot_api_base/getMe";
  eval {
    my $response = web_request($get_me_url, { CURL => 1, DEBUG => $debug > 2 });

    my $telegram_info = decode_json($response);
    if (!$telegram_info->{ok}) {
      plan skip_all => 'FAILED: Bot is not exist, recheck your token';
    }
    ok(1, 'Bot exist in Telegram');

    $response = web_request($bot_api_base .'/getWebhookInfo', { CURL => 1, DEBUG => $debug > 2 });
    $telegram_info = decode_json($response);
    if ($debug > 1) {
      show_hash($telegram_info, { DELIMITER => "\n  " });
    }

    ok(! $telegram_info->{last_error_message}, 'Configuired good');

    $webhook //= $telegram_info->{result}->{url};
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
    }
    else {
      print "❌ $available_module\n"
    }
  }
}

CHECK_ENDPOINT: {
  my $response = web_request($webhook, { MORE_INFO => 1, CURL => 1, DEBUG => $debug > 2 });

  if ($debug > 1) {
    show_hash($response, { DELIMITER => "\n  " });
  }

  ok(defined($response->{ssl_verify_result}) && $response->{ssl_verify_result} == 0, 'SSL Verify');

  if ($response->{http_code}) {
    ok($response->{http_code} && $response->{http_code} == 200, 'WEBHOOK_URL check');
  }
  elsif($response->{status}) {
    ok($response->{status} && $response->{status} == 200, 'WEBHOOK_URL check');
  }
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

#***********************************************************
=head2 is_installed()

  Arguments:

  Returns:

=cut
#***********************************************************
sub is_installed {

  opendir my $fh, "$conf{base_dir}/cgi-bin/" or die "Can't open dir '$conf{base_dir}' $!\n";
    my @contents = grep /^Telegram.+$/, readdir $fh;
  closedir $fh;


  if (! $contents[0] || ! -x "$conf{base_dir}/cgi-bin/"  . $contents[0] .'/telegram_bot.cgi') {
    return 0;
  }

  if ($debug) {
    foreach my $file (@contents) {
      print " $file\n";
    }
  }

  $telegram_script = $contents[0] .'/telegram_bot.cgi';
  print "Telegram path: /$contents[0]/telegram_bot.cgi\n";

  return 1;
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
