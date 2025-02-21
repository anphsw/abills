#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../';
use FindBin '$Bin';
use JSON;
use File::Find;

BEGIN {
  our $libpath = $Bin . '/../../../';

  require $libpath . 'libexec/config.pl';
  our %conf;
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

my $TELEGRAM_API_URL = 'https://api.telegram.org';

my $ARGS = parse_arguments(\@ARGV);

my $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);
our $admin = Admins->new($db, \%conf);
# Just init Tokens from Config
my $Conf = Conf->new($db, $admin, \%conf);

my $is_admin = !!$ARGS->{ADMIN};
my $desc_key = $is_admin ? 'TELEGRAM_ADMIN' : 'TELEGRAM';

_start();
sub _start {
  if ($ARGS->{help}) {
    help();
  }
  else {
    integration();
  }
}


#*******************************************************************
=head2 integration() - Start bot integration

=cut
#*******************************************************************
sub integration {
  my $token = $is_admin ? $conf{TELEGRAM_ADMIN_TOKEN} : $conf{TELEGRAM_TOKEN};
  my $billing_url = $conf{BILLING_URL};
  my $cert_path = $is_admin ? $conf{TELEGRAM_ADMIN_CERT_PATH} : $conf{TELEGRAM_CERT_PATH};

  if (!$token) {
    print "There is no Telegram token. Fill \$conf{$desc_key\_TOKEN} and try again.\n";
    return;
  }

  if (!$billing_url) {
    print "There is no billing url. Fill \$conf{BILLING_URL} and try again.\n";
    return;
  }

  if ($billing_url =~ /http:\/\// || $billing_url =~ /:9443/) {
    print << "[END]";
    Your \$conf{BILLING_URL} is not valid for Telegram.
    Change it due to requirements and change web server config.

    Requirements:
    - https
    - port 443 or 8443
[END]
    return;
  }

  my $bot_api_base = "$TELEGRAM_API_URL/bot$token";

  my $bot_info = web_request("$bot_api_base/getMe", { CURL => 1, JSON_RETURN => 1 });
  if (!$bot_info || $bot_info->{error_code}) {
    print "Bot is not exist.\nRecheck your \$conf{$desc_key\_TOKEN} and try again.\n";
    return;
  }

  my $webhook_info = web_request("$bot_api_base/getWebhookInfo", { CURL => 1, JSON_RETURN => 1 });

  if (!$webhook_info || $webhook_info->{error_code}) {
    print "Error with webhook request, try again.\n";
    return;
  }

  if ($webhook_info->{result}->{url}) {
    # when webhook url already exist
  }

  my $cutted_token = substr($token, 0, 10);
  my $script_name = $is_admin ? 'telegram_admin_bot.cgi' : 'telegram_bot.cgi';
  my $executable_path = "$Bin/$script_name";
  my $base_dir = $main::base_dir || '/usr/abills/';
  my $generated_folder = "Telegram$cutted_token";
  my $generated_append = "$generated_folder/$script_name";

  my $folder_path = $base_dir . '/cgi-bin/' . $generated_folder;
  my $symlink_end = $base_dir . '/cgi-bin/' . $generated_append;

  my $create_folder_and_symlink = sub {
    my $folder_res = mkdir($folder_path);

    if ($folder_res) {
      my $ret = `ln -s $executable_path $symlink_end`;
      `chmod +x $symlink_end`;
      # No output = success
      return !$ret;
    }

    return 0;
  };

  if (-f $symlink_end) {
    # print in debug that symlink exist
  }
  elsif (!$create_folder_and_symlink->()) {
    print << "[END]";
ERROR Cannot create folder and symlink.

Create it manually with commands:
  mkdir $folder_path
  ln -s $executable_path $symlink_end
  chmod +x $symlink_end

And start this script again.
[END]
    return;
  }
  else {
    print "Folder and symlink successfully created.\n";
  }

  my $generated_url = $billing_url . '/' . $generated_append;

  my $endpoint_result = web_request($generated_url, { MORE_INFO => 1, CURL => 1, INSECURE => 1 });

  if (!($endpoint_result->{http_code} && $endpoint_result->{http_code} == 200)) {
    print "Telegram endpoint is not working!\n\nTry command:\nchmod +x $symlink_end\n";
    return;
  }

  my $cert = '';
  if ($cert_path && -f $cert_path && open(my $fh, '<', $cert_path)) {
    while(<$fh>) {
      $cert .= $_;
    }
    close($fh);
  };

  my $subscribe_result = web_request("$bot_api_base/setWebhook",
    {
      CURL => 1,
      REQUEST_PARAMS => {
        url  => $generated_url,
        cert => $cert,
      },
      JSON_RETURN => 1
    }
  );

  if (!($subscribe_result && $subscribe_result->{ok})) {
    print "Telegram subscribe failed! Try again or later.\n";
    return;
  }

  my $fresh_webhook_info = web_request("$bot_api_base/getWebhookInfo",
    {
      CURL => 1,
      JSON_RETURN => 1
    }
  );

  if ($fresh_webhook_info && $fresh_webhook_info->{result}->{last_error_message}) {
    print "ERROR I have error from Telegram:\n" . $fresh_webhook_info->{result}->{last_error_message} . "\n";
    if ($fresh_webhook_info->{result}->{last_error_message} =~ /SSL/) {
      print "That means, Telegram recognized your SSL is not good.\n";
      if ($cert_path) {
        print "Regenerate your self-signed certificate with right ip and domain.\n";
      }
      else {
        print << "[END]";
  You need to have a signed certificate like Let's Encrypt
    OR
  You can use \$conf{$desc_key\_CERT_PATH} option - fill path of your public pem self-signed certificate.
[END]
      }
      print "And try again.\n"
    }
  }

  _load_telegram_db();

  my $bot_type = $is_admin ? 'Admin' : 'User';
  print << "[END]";
  Congratulations!
  ABillS $bot_type Telegram bot successfully subscribed.

[END]

  # Fill config variables
  $Conf->config_add({ PARAM => $desc_key . '_BOT_NAME', VALUE => $bot_info->{result}->{username}, REPLACE => 1 });
  $Conf->config_add({ PARAM => $desc_key . '_WEBHOOK_URL', VALUE => $generated_url, REPLACE => 1 });
}

#*******************************************************************
=head2 _load_telegram_db() - load Telegram.sql

=cut
#*******************************************************************
sub _load_telegram_db {
  my $content = '';
  if (open(my $fh, '<', $Bin . '/Telegram.sql')) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  };

  my @commands_to_execute = split('\;', $content);

  foreach my $command (@commands_to_execute) {
    $admin->query(qq{$command}, 'do');

    if ($admin->{errno}) {
      print "$admin->{errno}\n";
    }
  }
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print << "[END]";
ABillS Telegram bot setup in one click

  Required config params:
    1. \$conf{BILLING_URL}

    2. \$conf{TELEGRAM_TOKEN}
        or
       \$conf{TELEGRAM_ADMIN_TOKEN} for ADMIN=1

  Params:
    help - show this message

[END]
}