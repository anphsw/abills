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

my $VIBER_API_URL = 'https://chatapi.viber.com/pa';

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
my $debug = $ARGS->{DEBUG} || 0;

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
  my $token = $conf{VIBER_TOKEN};
  my $billing_url = $conf{BILLING_URL};

  if (!$token) {
    print "There is no Viber token. Fill \$conf{VIBER_TOKEN} and try again.\n";
    return;
  }

  if (!$billing_url) {
    print "There is no billing url. Fill \$conf{BILLING_URL} and try again.\n";
    return;
  }

  if ($billing_url !~ /https:\/\//) {
    print <<"[END]";
    Your \$conf{BILLING_URL} is not valid for Viber.
    Change it due to requirements and change web server config.

    Requirements:
    - https
[END]
    return;
  }

  my @headers = ('Content-Type: application/json', 'X-Viber-Auth-Token: ' . $conf{VIBER_TOKEN});

  my $bot_info = web_request("$VIBER_API_URL/get_account_info", {
    CURL        => 1,
    HEADERS     => \@headers,
    DEBUG       => $debug,
    JSON_RETURN => 1
  });

  if (!$bot_info || $bot_info->{status} == 2) {
    print "Bot is not exist.\nRecheck your \$conf{VIBER_TOKEN} and try again.\n";
    return;
  }

  if ($bot_info->{webhook}) {
    # when webhook url already exist
  }

  my $cutted_token = substr($token, 0, 10);
  my $script_file_name = 'viber_bot.cgi';
  my $executable_path = $Bin . '/' . $script_file_name;
  my $base_dir = $main::base_dir || '/usr/abills/';
  my $generated_folder = "Viber$cutted_token";
  my $generated_append = $generated_folder . '/' . $script_file_name;

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
    print <<"[END]";
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

  my $endpoint_result = web_request($generated_url, {
    MORE_INFO => 1,
    CURL      => 1,
    DEBUG     => $debug,
    INSECURE  => 1
  });

  if (!($endpoint_result->{http_code} && $endpoint_result->{http_code} == 200)) {
    print "Viber endpoint is not working!\n\nTry command:\nchmod +x $symlink_end\n";
    return;
  }

  my $subscribe_result = web_request("$VIBER_API_URL/set_webhook",
    {
      CURL        => 1,
      HEADERS     => \@headers,
      JSON_BODY   => {
        url         => $generated_url,
        event_types => [
          'delivered',
          'seen',
          'failed',
          'subscribed',
          'unsubscribed',
          'conversation_started'
        ],
        send_photo  => 'false'
      },
      JSON_RETURN => 1,
      DEBUG       => $debug
    }
  );

  if (!($subscribe_result && $subscribe_result->{status} == 0)) {
    print "Viber subscribe failed! Try again or later.\n";
    return;
  }

  my $fresh_bot_info = web_request("$VIBER_API_URL/get_account_info",
    {
      CURL        => 1,
      HEADERS     => \@headers,
      JSON_RETURN => 1,
      DEBUG       => $debug
    }
  );

  if ($fresh_bot_info && $fresh_bot_info->{status}) {
    print "ERROR I have error from Viber:\n" . $fresh_bot_info->{status_message} . "\n";
  }

  _load_viber_db();

  print <<"[END]";
  Congratulations!
  ABillS Viber bot successfully subscribed.

[END]

  # Fill config variables
  $Conf->config_add({ PARAM => 'VIBER_BOT_NAME', VALUE => $bot_info->{uri}, REPLACE => 1 });
  $Conf->config_add({ PARAM => 'VIBER_WEBHOOK_URL', VALUE => $generated_url, REPLACE => 1 });
}

#*******************************************************************
=head2 _load_viber_db() - load Viber.sql

=cut
#*******************************************************************
sub _load_viber_db {
  my $content = '';
  if (open(my $fh, '<', $Bin . '/Viber.sql')) {
    while (<$fh>) {
      $content .= $_;
    }
    close($fh);
  };

  eval {$admin->query($content, 'do', {})};
}

#*******************************************************************
=head2 help() - Help

=cut
#*******************************************************************
sub help {

  print <<"[END]";
ABillS Viber bot setup in one click

  Required config params:
    \$conf{VIBER_TOKEN}
    \$conf{BILLING_URL}

  Params:
    help - show this message

[END]
}
